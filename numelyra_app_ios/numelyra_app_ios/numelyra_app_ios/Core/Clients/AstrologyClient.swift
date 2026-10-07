import ComposableArchitecture
import Foundation

@DependencyClient
nonisolated struct AstrologyClient {
    var generateVector: @Sendable (_ input: AstroBirthInput, _ currentDate: Date) throws -> AstroVectorResult
    // từ astrobirthinput + ngày hiện tại chúng ta sẽ có dc result
    // tương đương 32 chiều đó tính từ hiện tại và quá khứ
    
    // vector 32 chiều để thể hiện feature ai dánhd giá
    var natalContext: @Sendable (_ input: AstroBirthInput) async throws -> AstroNatalContext?
    var cachedDailyFortune: @Sendable (_ query: AstroDailyFortuneQuery) async -> AstroFortuneSlip? = { _ in nil }
    var dailyFortune: @Sendable (
        // dữ liệu lúc sinh của người dùng
        _ query: AstroDailyFortuneQuery,
        _ cachePolicy: AstroFortuneCachePolicy
    ) async throws -> AstroFortuneSlip
    // gọi AI để nhận phản hồi
    
}

extension AstrologyClient: DependencyKey {
    static var liveValue: Self {
        @Dependency(\.supabaseClient) var supabaseClient
        @Dependency(\.birthLocationClient) var birthLocationClient
        @Dependency(\.caDaoClient) var caDaoClient
        let cache = AstrologyFortuneCache()

        @Sendable func resolveCachedFortune(_ query: AstroDailyFortuneQuery) async -> AstroFortuneSlip? {
            guard var cached = await cache.load(date: query.date, profile: query.profile) else {
                return nil
            }
            if cached.astroMetadata == nil {
                var resolvedLocation: ResolvedBirthLocation?
                if query.profile?.effectiveBirthTimeAccuracy == .exact,
                   let placeID = query.profile?.birthLocation?.placeID
                {
                    resolvedLocation = try? await birthLocationClient.refresh(placeID)
                }
                let input = AstroBirthInput(
                    birthDate: query.profile?.birthDate ?? "1998-10-20",
                    birthTime: query.profile?.birthTime,
                    fullName: query.profile?.fullName ?? "Đương số",
                    birthTimeAccuracy: query.profile?.effectiveBirthTimeAccuracy ?? .unknown,
                    resolvedBirthLocation: resolvedLocation
                )
                if let metadata = try? AstrologyEngine.generateVector(
                    input: input,
                    currentDate: query.date
                ).metadata {
                    cached.astroMetadata = metadata
                    try? await cache.save(cached, date: query.date, profile: query.profile)
                }
            }
            return cached
        }

        return Self(
            generateVector: { input, currentDate in
                try AstrologyEngine.generateVector(input: input, currentDate: currentDate)
            },
            natalContext: { input in
                try AstrologyEngine.makeNatalSnapshot(input: input, fingerprint: "direct").context
            },
            cachedDailyFortune: { query in
                await resolveCachedFortune(query)
            },
            dailyFortune: { query, cachePolicy in
                if cachePolicy == .useCache,
                   let cached = await resolveCachedFortune(query)
                {
                    return cached
                }

                var resolvedLocation: ResolvedBirthLocation?
                if query.profile?.effectiveBirthTimeAccuracy == .exact,
                   let placeID = query.profile?.birthLocation?.placeID
                {
                    resolvedLocation = try? await birthLocationClient.refresh(placeID)
                    // ? đánh dấu là nếu mất mạng hay ko chạy dc tiếp tục code tiếp ko break
                }
                let input = AstroBirthInput(
                    birthDate: query.profile?.birthDate ?? "1998-10-20",
                    birthTime: query.profile?.birthTime,
                    fullName: query.profile?.fullName ?? "Đương số",
                    birthTimeAccuracy: query.profile?.effectiveBirthTimeAccuracy ?? .unknown,
                    resolvedBirthLocation: resolvedLocation
                )

                let fingerprint = AstrologyCacheKey.profileFingerprint(query.profile)
                let natalSnapshot: AstroNatalSnapshot
                if let cachedNatal = await cache.loadNatal(profile: query.profile),
                   cachedNatal.fingerprint == fingerprint,
                   cachedNatal.engineVersion == AstrologyEngine.engineVersion
                {
                    natalSnapshot = cachedNatal
                } else {
                    natalSnapshot = try AstrologyEngine.makeNatalSnapshot(
                        input: input,
                        fingerprint: fingerprint
                    )
                    if query.profile?.birthLocation == nil || resolvedLocation != nil {
                        try? await cache.saveNatal(natalSnapshot, profile: query.profile)
                    }
                }
                let metadata = try AstrologyEngine.generateVector(
                    input: input,
                    currentDate: query.date,
                    natalSnapshot: natalSnapshot
                ).metadata
                let recentAdvice = await cache.recentAdvice(
                    date: query.date,
                    profile: query.profile
                )
                let anchor = Self.resolveAnchorCaDao(
                    explicit: query.anchorCaDao,
                    dailyRecord: caDaoClient.dailyCaDao(query.date)
                )
                let payload = Self.makeRequest(
                    metadata: metadata,
                    anchor: anchor,
                    recentAdvice: recentAdvice,
                    userContext: query.userContext
                )
                let accessToken = await supabaseClient.accessToken()
                var fortune = try await Self.requestFortune(payload, accessToken: accessToken)
                fortune.anchorCaDao = anchor
                fortune.astroMetadata = metadata
                try? await cache.save(fortune, date: query.date, profile: query.profile)
                // có nên chạy 1 luồng khác ko
                return fortune
            }
        )
    }

    static let testValue = Self()
    static let previewValue = Self(
        generateVector: { input, date in
            try AstrologyEngine.generateVector(input: input, currentDate: date)
        },
        natalContext: { input in
            try AstrologyEngine.makeNatalSnapshot(input: input, fingerprint: "preview").context
        },
        cachedDailyFortune: { _ in nil },
        dailyFortune: { query, _ in
            let input = AstroBirthInput(
                birthDate: query.profile?.birthDate ?? "1998-10-20",
                birthTime: query.profile?.birthTime,
                fullName: query.profile?.fullName ?? "Đương số"
            )
            let metadata = try? AstrologyEngine.generateVector(
                input: input,
                currentDate: query.date
            ).metadata
            return AstroFortuneSlip(
                title: "Quẻ bình an",
                verse: "Trăng lên soi bóng mặt hồ\nGiữ tâm trong sáng, cơ đồ hanh thông",
                mirror: "Nhịp ngày phù hợp để quan sát trước khi quyết định.",
                advice: "Chọn một việc quan trọng và hoàn thành thật gọn.",
                anchorCaDao: query.anchorCaDao ?? fallbackAnchor,
                astroMetadata: metadata
            )
        }
    )
}

extension DependencyValues {
    var astrologyClient: AstrologyClient {
        get { self[AstrologyClient.self] }
        set { self[AstrologyClient.self] = newValue }
    }
}

extension AstrologyClient {
    enum ClientError: LocalizedError {
        case invalidResponse
        case server(statusCode: Int, message: String?)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Dữ liệu lá thăm từ máy chủ không hợp lệ."
            case let .server(statusCode, message):
                return message ?? "Gọi API Lá Thăm Chiêm Tinh thất bại (\(statusCode))"
            }
        }
    }

    nonisolated static let fallbackAnchor = AnchorCaDao(
        content: "Cái cò cái vạc cái nông\nBa con cùng béo vặt lông con nào\nVặt lông con cốc cho tao\nTao nấu tao nướng tao xào tao ăn",
        category: "Dân gian"
    )

    nonisolated static func resolveAnchorCaDao(
        explicit: AnchorCaDao?,
        dailyRecord: CaDaoRecord?
    ) -> AnchorCaDao {
        if let explicit,
           !explicit.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return AnchorCaDao(
                content: explicit.content,
                category: explicit.category?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                    ? explicit.category
                    : "Dân gian"
            )
        }
        if let dailyRecord {
            let trimmedContent = dailyRecord.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedContent.isEmpty {
                let trimmedCategory = dailyRecord.category.trimmingCharacters(in: .whitespacesAndNewlines)
                return AnchorCaDao(
                    content: dailyRecord.content,
                    category: trimmedCategory.isEmpty ? "Dân gian" : dailyRecord.category
                )
            }
        }
        return fallbackAnchor
    }

    nonisolated static func makeRequest(
        metadata: AstroFeatureMetadata,
        anchor: AnchorCaDao,
        recentAdvice: [String],
        userContext: String?
    ) -> AstroFortuneRequest {
        var highlights: [String] = []
        if let aspect = metadata.topAspect {
            highlights.append(
                String(
                    format: "%@ %@ %@ (%.0f°, orb %.1f°)",
                    locale: Locale(identifier: "en_US_POSIX"),
                    aspect.natalPlanet,
                    aspect.nameVi,
                    aspect.transitPlanet,
                    aspect.actualAngle,
                    aspect.orb
                )
            )
        }
        highlights.append(
            "Mặt Trời bản mệnh: \(metadata.natalSunSign), Mặt Trăng quá cảnh: \(metadata.transitMoonSign)"
        )
        if let house = metadata.dailyContext?.activatedHouses.first {
            highlights.append("Nhà \(house.house) – \(house.topicVi) đang được kích hoạt")
        }
        let angleHighlights = metadata.dailyContext?.angleAspects.prefix(3).map {
            "\($0.transitPlanet) \($0.nameVi) \($0.angle), orb \($0.orb)°"
        }
        let ascendantSign = metadata.natalContext.map {
            AstrologyEngine.longitudeToZodiac($0.angles.ascendant).sign
        }
        let midheavenSign = metadata.natalContext.map {
            AstrologyEngine.longitudeToZodiac($0.angles.midheaven).sign
        }
        return AstroFortuneRequest(
            caDaoSample: anchor.content,
            caDaoCategory: anchor.category ?? "Dân gian",
            astroSummary: metadata.vibeSummary,
            metadata: AstroFortuneRequestMetadata(
                tensionScore: metadata.scores.tension,
                harmonyScore: metadata.scores.harmony,
                conjunctionScore: metadata.scores.conjunction,
                dominantSignal: metadata.dominantSignal,
                dominantElements: [
                    metadata.temperament.dominantElement,
                    metadata.temperament.dominantModality,
                ],
                highlights: highlights,
                birthDataPrecision: metadata.birthDataPrecision,
                houseSystem: metadata.natalContext?.houseSystem,
                ascendantSign: ascendantSign,
                midheavenSign: midheavenSign,
                planetHouses: metadata.natalContext?.planetHouses,
                activatedHouses: metadata.dailyContext?.activatedHouses,
                angleHighlights: angleHighlights
            ),
            recentAdvice: recentAdvice.isEmpty ? nil : Array(recentAdvice.prefix(7)),
            userContext: userContext
        )
    }

    nonisolated static func requestFortune(
        _ payload: AstroFortuneRequest,
        accessToken: String?
    ) async throws -> AstroFortuneSlip {
        var request = URLRequest(url: AppConfig.astroFortuneURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accessToken, !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }
        let decoded = try? JSONDecoder().decode(AstroFortuneResponse.self, from: data)
        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw ClientError.server(statusCode: httpResponse.statusCode, message: decoded?.error)
        }
        guard let decoded, decoded.success, let content = decoded.fortune else {
            throw ClientError.invalidResponse
        }
        return AstroFortuneSlip(
            title: content.title,
            verse: content.verse,
            mirror: content.mirror,
            advice: content.advice,
            anchorCaDao: fallbackAnchor
        )
    }
}
