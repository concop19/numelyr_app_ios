import ComposableArchitecture
import Foundation
import XCTest
@testable import numelyra_app_ios

@MainActor
final class AstrologyFeatureTests: XCTestCase {
    func testOnAppearLoadsActiveProfileBuildsConstellationAndUsesCachedFortuneWithoutSuccessHaptic() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Ho_Chi_Minh"))
        let fixedDate = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 14, minute: 30))
        )
        let activeProfile = UserProfile(
            id: "profile-1",
            fullName: "Nguyễn Văn An",
            birthDate: "1998-10-20"
        )
        let cachedSlip = AstroFortuneSlip(
            title: "Quẻ Thanh Minh",
            verse: "Gió thu lay động cành mai\nChân đi vững bước đường dài bình yên",
            mirror: "Nội tâm đang tìm được điểm tựa vững vàng.",
            advice: "Hoàn tất việc còn dang dở trước buổi chiều.",
            anchorCaDao: AnchorCaDao(
                content: "Trăm năm bia đá thì mòn\nNgàn năm bia miệng vẫn còn trơ trơ",
                category: "Thế sự"
            )
        )
        let successHapticCount = LockIsolated(0)
        let clock = TestClock()

        let store = TestStore(
            initialState: AstrologyFeature.State(
                currentDate: fixedDate,
                calendar: calendar
            )
        ) {
            AstrologyFeature()
        } withDependencies: {
            $0.date.now = fixedDate
            $0.calendar = calendar
            $0.continuousClock = clock
            $0.userProfileClient.activeProfile = { activeProfile }
            $0.caDaoClient.dailyCaDao = { _ in
                CaDaoRecord(
                    id: 10,
                    title: "Thế sự",
                    content: "Trăm năm bia đá thì mòn\nNgàn năm bia miệng vẫn còn trơ trơ",
                    category: "Thế sự",
                    url: ""
                )
            }
            $0.astrologyClient.cachedDailyFortune = { _ in cachedSlip }
            $0.hapticClient = HapticClient(
                selection: {},
                lightImpact: {},
                mediumImpact: {},
                success: { successHapticCount.withValue { $0 += 1 } }
            )
        }

        let expectedSymbol = ConstellationEngine.dailySymbol(
            date: fixedDate,
            profileKey: AstrologyCacheKey.profileKey(activeProfile),
            calendar: calendar
        )
        let expectedGeometry = try ConstellationEngine.buildGeometry(for: expectedSymbol)

        await store.send(.onAppear) {
            $0.isScreenVisible = true
            $0.hasAppeared = true
            $0.profile = activeProfile
            $0.symbol = expectedSymbol
            $0.geometry = expectedGeometry
            $0.geometryErrorMessage = nil
            $0.isLoading = true
        }

        await store.receive(.fortuneLoaded(cachedSlip, fromCache: true)) {
            $0.isLoading = false
            $0.fortune = cachedSlip
            $0.errorMessage = nil
        }

        XCTAssertEqual(successHapticCount.value, 0)
        XCTAssertEqual(store.state.fortuneTitleText, "Quẻ Thanh Minh")

        await store.send(.onDisappear) {
            $0.isScreenVisible = false
        }
    }

    func testNetworkFortuneLoadResolvesDailyCaDaoAndFiresSuccessHaptic() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Ho_Chi_Minh"))
        let fixedDate = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 9, minute: 0))
        )
        let profile = UserProfile(
            id: "profile-1",
            fullName: "An Nguyễn",
            birthDate: "1998-10-20"
        )
        let dailyCaDao = CaDaoRecord(
            id: 42,
            title: "Lao động",
            content: "Có công mài sắt\nCó ngày nên kim",
            category: "Lao động",
            url: ""
        )
        let networkSlip = AstroFortuneSlip(
            title: nil,
            verse: "Sắt kia mài mãi nên kim\nLòng bền chí vững đi tìm lối thông",
            mirror: "Sự kiên nhẫn hôm nay mở ra bước ngoặt.",
            advice: "Tập trung vào một mục tiêu cốt lõi.",
            anchorCaDao: AnchorCaDao(content: dailyCaDao.content, category: dailyCaDao.category)
        )
        let capturedQuery = LockIsolated<AstroDailyFortuneQuery?>(nil)
        let capturedPolicy = LockIsolated<AstroFortuneCachePolicy?>(nil)
        let successHapticCount = LockIsolated(0)
        let clock = TestClock()

        let store = TestStore(
            initialState: AstrologyFeature.State(
                currentDate: fixedDate,
                profile: profile,
                calendar: calendar
            )
        ) {
            AstrologyFeature()
        } withDependencies: {
            $0.date.now = fixedDate
            $0.calendar = calendar
            $0.continuousClock = clock
            $0.caDaoClient.dailyCaDao = { _ in dailyCaDao }
            $0.astrologyClient.cachedDailyFortune = { _ in nil }
            $0.astrologyClient.dailyFortune = { query, policy in
                capturedQuery.setValue(query)
                capturedPolicy.setValue(policy)
                return networkSlip
            }
            $0.hapticClient = HapticClient(
                selection: {},
                lightImpact: {},
                mediumImpact: {},
                success: { successHapticCount.withValue { $0 += 1 } }
            )
        }

        await store.send(.onAppear) {
            $0.isScreenVisible = true
            $0.hasAppeared = true
            $0.isLoading = true
        }

        await store.receive(.fortuneLoaded(networkSlip, fromCache: false)) {
            $0.isLoading = false
            $0.fortune = networkSlip
        }

        XCTAssertEqual(successHapticCount.value, 1)
        XCTAssertEqual(capturedPolicy.value, .useCache)
        XCTAssertEqual(capturedQuery.value?.anchorCaDao?.content, dailyCaDao.content)
        XCTAssertEqual(capturedQuery.value?.anchorCaDao?.category, "Lao động")
        XCTAssertEqual(store.state.fortuneTitleText, "Quẻ hôm nay")

        await store.send(.onDisappear) {
            $0.isScreenVisible = false
        }
    }

    func testFailureAndRetryFlowFiresMediumHapticAndReloadsIgnoringCache() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Ho_Chi_Minh"))
        let fixedDate = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 10, minute: 0))
        )
        let profile = UserProfile(id: "p1", fullName: "An", birthDate: "1998-10-20")
        let shouldFail = LockIsolated(true)
        let mediumHapticCount = LockIsolated(0)
        let successHapticCount = LockIsolated(0)
        let lastPolicy = LockIsolated<AstroFortuneCachePolicy?>(nil)
        let clock = TestClock()

        let recoveredSlip = AstroFortuneSlip(
            title: "Quẻ Khai Mở",
            verse: "Mây tan trăng sáng giữa trời\nBước qua thử thách đón lời tin vui",
            mirror: "Tâm trí đã sẵn sàng đón nhận góc nhìn mới.",
            advice: "Chủ động bắt đầu cuộc trò chuyện quan trọng.",
            anchorCaDao: AstrologyClient.fallbackAnchor
        )

        let store = TestStore(
            initialState: AstrologyFeature.State(
                currentDate: fixedDate,
                profile: profile,
                calendar: calendar
            )
        ) {
            AstrologyFeature()
        } withDependencies: {
            $0.date.now = fixedDate
            $0.calendar = calendar
            $0.continuousClock = clock
            $0.caDaoClient = .previewValue
            $0.astrologyClient.cachedDailyFortune = { _ in nil }
            $0.astrologyClient.dailyFortune = { _, policy in
                lastPolicy.setValue(policy)
                if shouldFail.value {
                    throw AstrologyClient.ClientError.server(statusCode: 503, message: "Máy chủ đang bận.")
                }
                return recoveredSlip
            }
            $0.hapticClient = HapticClient(
                selection: {},
                lightImpact: {},
                mediumImpact: { mediumHapticCount.withValue { $0 += 1 } },
                success: { successHapticCount.withValue { $0 += 1 } }
            )
        }

        await store.send(.onAppear) {
            $0.isScreenVisible = true
            $0.hasAppeared = true
            $0.isLoading = true
        }

        await store.receive(.fortuneFailed("Máy chủ đang bận.")) {
            $0.isLoading = false
            $0.errorMessage = "Máy chủ đang bận."
            $0.fortune = nil
        }

        shouldFail.setValue(false)

        await store.send(.retryTapped) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(.fortuneLoaded(recoveredSlip, fromCache: false)) {
            $0.isLoading = false
            $0.fortune = recoveredSlip
        }

        XCTAssertEqual(mediumHapticCount.value, 1)
        XCTAssertEqual(successHapticCount.value, 1)
        XCTAssertEqual(lastPolicy.value, .reloadIgnoringCache)

        await store.send(.onDisappear) {
            $0.isScreenVisible = false
        }
    }

    func testInsightSheetAndSharePayloadMatchReactNativeFormat() async throws {
        let metadata = try AstrologyEngine.generateVector(
            input: AstroBirthInput(birthDate: "1998-10-20", birthTime: "14:30", fullName: "An"),
            currentDate: Date(timeIntervalSince1970: 1_791_331_200)
        ).metadata
        let slip = AstroFortuneSlip(
            title: "Quẻ Minh Triết",
            verse: "Trăng thanh gió mát hiên nhà\nLòng an trí sáng nhìn xa dặm trường",
            mirror: "Bạn đang nhạy bén với các tín hiệu xung quanh.",
            advice: "Ghi chép lại ý tưởng vừa nảy ra.",
            anchorCaDao: AnchorCaDao(content: "Uống nước nhớ nguồn", category: "Đạo lý"),
            astroMetadata: metadata
        )
        let lightHapticCount = LockIsolated(0)

        let store = TestStore(
            initialState: AstrologyFeature.State(
                fortune: slip,
                hasAppeared: true
            )
        ) {
            AstrologyFeature()
        } withDependencies: {
            $0.hapticClient = HapticClient(
                selection: {},
                lightImpact: { lightHapticCount.withValue { $0 += 1 } },
                mediumImpact: {},
                success: {}
            )
        }

        await store.send(.openInsightTapped) {
            $0.insight = AstrologyInsightFeature.State(fortune: slip, metadata: metadata)
        }
        XCTAssertEqual(lightHapticCount.value, 1)

        await store.send(.insight(.presented(.closeTapped)))
        await store.receive(.insight(.dismiss)) {
            $0.insight = nil
        }

        await store.send(.shareTapped) {
            $0.sharePayload = AstrologyFeature.SharePayload(
                title: "Quẻ Minh Triết",
                message: "📜 LÁ THĂM CHIÊM TINH HÔM NAY: Quẻ Minh Triết\n\nTrăng thanh gió mát hiên nhà\nLòng an trí sáng nhìn xa dặm trường\n\n🪞 Gương soi: Bạn đang nhạy bén với các tín hiệu xung quanh.\n🎒 Kế sách: Ghi chép lại ý tưởng vừa nảy ra.\n\n✨ Bốc quẻ chiêm tinh dân gian trên Numelyra."
            )
        }
        XCTAssertEqual(lightHapticCount.value, 2)

        await store.send(.shareSheetDismissed) {
            $0.sharePayload = nil
        }
    }

    func testMidnightRolloverUpdatesDateSymbolAndFetchesNewFortune() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Ho_Chi_Minh"))
        let day1 = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 23, minute: 59, second: 58))
        )
        let day2 = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 10, day: 8, hour: 0, minute: 0, second: 1))
        )
        let profile = UserProfile(id: "p1", fullName: "An Nguyễn", birthDate: "1998-10-20")
        let currentNow = LockIsolated(day1)
        let clock = TestClock()

        let slipDay1 = AstroFortuneSlip(
            title: "Quẻ Ngày 7",
            verse: "Thơ ngày 7",
            mirror: "Gương ngày 7",
            advice: "Kế sách ngày 7",
            anchorCaDao: AstrologyClient.fallbackAnchor
        )
        let slipDay2 = AstroFortuneSlip(
            title: "Quẻ Ngày 8",
            verse: "Thơ ngày 8",
            mirror: "Gương ngày 8",
            advice: "Kế sách ngày 8",
            anchorCaDao: AstrologyClient.fallbackAnchor
        )

        let store = TestStore(
            initialState: AstrologyFeature.State(
                currentDate: day1,
                profile: profile,
                calendar: calendar
            )
        ) {
            AstrologyFeature()
        } withDependencies: {
            $0.date = .init { currentNow.value }
            $0.calendar = calendar
            $0.continuousClock = clock
            $0.caDaoClient = .previewValue
            $0.astrologyClient.cachedDailyFortune = { query in
                let key = AstrologyCacheKey.localDateKey(query.date, calendar: calendar)
                return key == "2026-10-07" ? slipDay1 : slipDay2
            }
            $0.hapticClient = .testValue
        }

        await store.send(.onAppear) {
            $0.isScreenVisible = true
            $0.hasAppeared = true
            $0.isLoading = true
        }
        await store.receive(.fortuneLoaded(slipDay1, fromCache: true)) {
            $0.isLoading = false
            $0.fortune = slipDay1
        }

        currentNow.setValue(day2)
        let expectedSymbolDay2 = ConstellationEngine.dailySymbol(
            date: day2,
            profileKey: AstrologyCacheKey.profileKey(profile),
            calendar: calendar
        )
        let expectedGeometryDay2 = try ConstellationEngine.buildGeometry(for: expectedSymbolDay2)

        await clock.advance(by: .milliseconds(2_250))

        await store.receive(.midnightTick) {
            $0.currentDate = day2
            $0.symbol = expectedSymbolDay2
            $0.geometry = expectedGeometryDay2
            $0.fortune = nil
            $0.isLoading = true
        }

        await store.receive(.fortuneLoaded(slipDay2, fromCache: true)) {
            $0.isLoading = false
            $0.fortune = slipDay2
        }

        await store.send(.onDisappear) {
            $0.isScreenVisible = false
        }
    }

    func testVideoPlaybackAndFallbackImageRules() async {
        let store = TestStore(
            initialState: AstrologyFeature.State(
                isScreenVisible: true,
                isAppActive: true,
                reduceMotion: false,
                isVideoReady: false,
                hasVideoFailed: false,
                hasAppeared: true
            )
        ) {
            AstrologyFeature()
        }

        XCTAssertTrue(store.state.showVideoLayer)
        XCTAssertTrue(store.state.shouldPlayVideo)
        XCTAssertTrue(store.state.shouldShowFallbackImage)

        await store.send(.videoReadyChanged(true)) {
            $0.isVideoReady = true
        }
        XCTAssertFalse(store.state.shouldShowFallbackImage)

        await store.send(.reduceMotionChanged(true)) {
            $0.reduceMotion = true
            $0.isVideoReady = false
        }
        XCTAssertFalse(store.state.showVideoLayer)
        XCTAssertFalse(store.state.shouldPlayVideo)
        XCTAssertTrue(store.state.shouldShowFallbackImage)

        await store.send(.reduceMotionChanged(false)) {
            $0.reduceMotion = false
        }
        await store.send(.videoReadyChanged(true)) {
            $0.isVideoReady = true
        }
        await store.send(.videoPlaybackFailed) {
            $0.hasVideoFailed = true
            $0.isVideoReady = false
        }
        XCTAssertFalse(store.state.showVideoLayer)
        XCTAssertTrue(store.state.shouldShowFallbackImage)
    }

    func testInsightLocalizationHelpersCoverZodiacPlanetsAndScores() {
        XCTAssertEqual(AstrologyInsightFeature.zodiacVi("Libra"), "Thiên Bình ♎")
        XCTAssertEqual(AstrologyInsightFeature.zodiacVi("Scorpio"), "Bọ Cạp ♏")
        XCTAssertEqual(AstrologyInsightFeature.planetVi("Mercury"), "Sao Thủy")
        XCTAssertEqual(AstrologyInsightFeature.planetVi("Pluto"), "Sao Diêm Vương")
        XCTAssertEqual(AstrologyInsightFeature.scorePercent(0.684), 68)
        XCTAssertEqual(AstrologyInsightFeature.scorePercent(1.4), 100)
        XCTAssertEqual(AstrologyInsightFeature.scorePercent(-0.2), 0)
    }
}
