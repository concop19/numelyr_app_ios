import ComposableArchitecture
import Foundation

@Reducer
struct AstrologyFeature {
    struct SharePayload: Identifiable, Equatable, Sendable {
        var id: String { "\(title)|\(message)" }
        var title: String
        var message: String

        init(title: String, message: String) {
            self.title = title
            self.message = message
        }
    }
    @ObservableState
    struct State: Equatable {
        /// Ngày địa phương đang được dùng để lấy quẻ và chọn biểu tượng chòm sao hằng ngày.
        var currentDate: Date
        /// Hồ sơ đang được dùng để cá nhân hóa phép tính và khóa cache; `nil` dùng ngữ cảnh khách.
        var profile: UserProfile?
        /// Quẻ chiêm tinh của ngày hiện tại sau khi đọc cache hoặc tải từ dịch vụ.
        var fortune: AstroFortuneSlip?
        /// Cho biết request lấy quẻ đang chạy.
        var isLoading: Bool
        /// Thông báo lỗi lấy quẻ cần hiển thị; được xóa khi bắt đầu thử lại hoặc tải thành công.
        var errorMessage: String?
        /// Mẫu biểu tượng được chọn ổn định từ ngày hiện tại và khóa hồ sơ.
        var symbol: ConstellationSymbolPreset
        /// Hình học đã dựng từ `symbol` để canvas vẽ các điểm sao và đường nối.
        var geometry: ConstellationGeometry?
        /// Lỗi dựng hình học biểu tượng; dùng để chuyển UI sang trạng thái fallback.
        var geometryErrorMessage: String?
        /// Cho biết tab Chiêm tinh đang thực sự hiển thị trên màn hình.
        var isScreenVisible: Bool
        /// Cho biết scene của ứng dụng đang active, dùng để tạm dừng video khi app vào nền.
        var isAppActive: Bool
        /// Giá trị Reduce Motion của hệ thống; khi bật, video nền bị vô hiệu hóa.
        var reduceMotion: Bool
        /// Cho biết player đã có frame video sẵn sàng để thay ảnh nền fallback.
        var isVideoReady: Bool
        /// Ghi nhận video đã phát lỗi để không tiếp tục thử hiển thị video trong phiên hiện tại.
        var hasVideoFailed: Bool
        /// Ghi nhận feature đã chạy `onAppear` ít nhất một lần để tránh tải lại không cần thiết.
        var hasAppeared: Bool
        /// Dirty flag yêu cầu tải lại quẻ khi hồ sơ đổi trong lúc màn hình không hiển thị.
        var needsRefresh: Bool
        /// Nội dung đang được đưa sang share sheet; `nil` nghĩa là share sheet đóng.
        var sharePayload: SharePayload?

        /// State của sheet giải mã chi tiết; có giá trị khi sheet đang được trình bày.
        @Presents
        var insight: AstrologyInsightFeature.State?

        init(
            currentDate: Date = Date(),
            profile: UserProfile? = nil,
            fortune: AstroFortuneSlip? = nil,
            isLoading: Bool = false,
            errorMessage: String? = nil,
            isScreenVisible: Bool = false,
            isAppActive: Bool = true,
            reduceMotion: Bool = false,
            isVideoReady: Bool = false,
            hasVideoFailed: Bool = false,
            hasAppeared: Bool = false,
            needsRefresh: Bool = false,
            sharePayload: SharePayload? = nil,
            insight: AstrologyInsightFeature.State? = nil,
            calendar: Calendar = .current
        ) {
            self.currentDate = currentDate
            self.profile = profile
            self.fortune = fortune
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.isScreenVisible = isScreenVisible
            self.isAppActive = isAppActive
            self.reduceMotion = reduceMotion
            self.isVideoReady = isVideoReady
            self.hasVideoFailed = hasVideoFailed
            self.hasAppeared = hasAppeared
            self.needsRefresh = needsRefresh
            self.sharePayload = sharePayload
            self.insight = insight

            let profileKey = AstrologyCacheKey.profileKey(profile)
            let initialSymbol = ConstellationEngine.dailySymbol(
                date: currentDate,
                profileKey: profileKey,
                calendar: calendar
            )
            self.symbol = initialSymbol
            do {
                self.geometry = try ConstellationEngine.buildGeometry(for: initialSymbol)
                self.geometryErrorMessage = nil
            } catch {
                self.geometry = nil
                self.geometryErrorMessage = error.localizedDescription
            }
        }

        /// Khóa ổn định đại diện cho hồ sơ, dùng cho cache và lựa chọn biểu tượng theo ngày.
        var profileKey: String {
            AstrologyCacheKey.profileKey(profile)
        }

        /// Ngày hiện tại được định dạng `DD.MM` cho phần tiêu đề.
        var formattedShortDate: String {
            AstrologyFeature.formatShortDate(currentDate)
        }

        /// Chuỗi tiêu đề ngày hoàn chỉnh hiển thị ở đầu màn hình.
        var dateHeaderText: String {
            "Hôm nay • \(formattedShortDate)"
        }

        /// Nhãn viết hoa của biểu tượng chòm sao được chọn cho hôm nay.
        var symbolLabelText: String {
            "BIỂU TƯỢNG HÔM NAY · \(symbol.title.uppercased())"
        }

        /// Tiêu đề quẻ đã chuẩn hóa, có fallback khi backend không trả tiêu đề hợp lệ.
        var fortuneTitleText: String {
            AstrologyInsightFeature.normalizedTitle(fortune?.title)
        }

        /// Metadata chiêm tinh đính kèm quẻ, dùng để hiển thị dữ liệu cá nhân hóa trong sheet chi tiết.
        var metadata: AstroFeatureMetadata? {
            fortune?.astroMetadata
        }

        /// Cho biết video nền có được gắn vào view hay phải bỏ hẳn vì Reduce Motion hoặc lỗi phát.
        var showVideoLayer: Bool {
            !reduceMotion && !hasVideoFailed
        }

        /// Cho biết video nền nên phát ở thời điểm hiện tại dựa trên visibility và trạng thái app.
        var shouldPlayVideo: Bool {
            isScreenVisible && isAppActive && !reduceMotion && !hasVideoFailed
        }

        /// Cho biết ảnh nền tĩnh phải hiển thị trong lúc video bị tắt hoặc chưa sẵn sàng.
        var shouldShowFallbackImage: Bool {
            !showVideoLayer || !isVideoReady
        }
    }

    enum Action: Equatable {
        case onAppear
        case onDisappear
        case scenePhaseChanged(isActive: Bool)
        case reduceMotionChanged(Bool)
        case videoReadyChanged(Bool)
        case videoPlaybackFailed
        case midnightTick
        case profileUpdated(UserProfile?)
        case retryTapped
        case openInsightTapped
        case shareTapped
        case shareSheetDismissed
        case fortuneLoaded(AstroFortuneSlip, fromCache: Bool)
        case fortuneFailed(String)
        case insight(PresentationAction<AstrologyInsightFeature.Action>)
    }

    @Dependency(\.astrologyClient) var astrologyClient
    @Dependency(\.caDaoClient) var caDaoClient
    @Dependency(\.userProfileClient) var userProfileClient
    @Dependency(\.hapticClient) var hapticClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar

    private nonisolated enum CancelID: Hashable, Sendable {
        case fortune
        case midnightTimer
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isScreenVisible = true
                if state.profile == nil {
                    state.profile = userProfileClient.activeProfile()
                }

                let currentNow = now
                let isNewDay = AstrologyCacheKey.localDateKey(currentNow, calendar: calendar)
                    != AstrologyCacheKey.localDateKey(state.currentDate, calendar: calendar)

                let shouldReload = !state.hasAppeared || state.needsRefresh || isNewDay || (state.fortune == nil && !state.isLoading && state.errorMessage == nil)
                state.hasAppeared = true
                state.needsRefresh = false

                if isNewDay {
                    state.currentDate = currentNow
                }
                refreshConstellation(&state)

                let midnightEffect = scheduleMidnightTimer(from: state.currentDate)
                guard shouldReload else {
                    return midnightEffect
                }
                return .merge(
                    midnightEffect,
                    fetchFortune(&state, allowCache: true, clearExisting: true)
                )

            case .onDisappear:
                state.isScreenVisible = false
                return .cancel(id: CancelID.midnightTimer)

            case let .scenePhaseChanged(isActive):
                state.isAppActive = isActive
                guard isActive else { return .none }
                let currentNow = now
                let isNewDay = AstrologyCacheKey.localDateKey(currentNow, calendar: calendar)
                    != AstrologyCacheKey.localDateKey(state.currentDate, calendar: calendar)
                guard isNewDay else { return .none }
                state.currentDate = currentNow
                refreshConstellation(&state)
                return .merge(
                    scheduleMidnightTimer(from: currentNow),
                    fetchFortune(&state, allowCache: true, clearExisting: true)
                )

            case let .reduceMotionChanged(enabled):
                state.reduceMotion = enabled
                if enabled {
                    state.isVideoReady = false
                }
                return .none

            case let .videoReadyChanged(ready):
                if state.showVideoLayer {
                    state.isVideoReady = ready
                } else {
                    state.isVideoReady = false
                }
                return .none

            case .videoPlaybackFailed:
                state.hasVideoFailed = true
                state.isVideoReady = false
                return .none

            case .midnightTick:
                let currentNow = now
                state.currentDate = currentNow
                refreshConstellation(&state)
                return .merge(
                    scheduleMidnightTimer(from: currentNow),
                    fetchFortune(&state, allowCache: true, clearExisting: true)
                )

            case let .profileUpdated(newProfile):
                let oldFingerprint = AstrologyCacheKey.profileFingerprint(state.profile)
                let newFingerprint = AstrologyCacheKey.profileFingerprint(newProfile)
                let oldKey = AstrologyCacheKey.profileKey(state.profile)
                let newKey = AstrologyCacheKey.profileKey(newProfile)
                state.profile = newProfile
                guard oldFingerprint != newFingerprint || oldKey != newKey else {
                    return .none
                }
                if state.isScreenVisible {
                    refreshConstellation(&state)
                    return fetchFortune(&state, allowCache: true, clearExisting: true)
                } else {
                    state.needsRefresh = true
                    return .none
                }

            case .retryTapped:
                return .merge(
                    .run { _ in await hapticClient.mediumImpact() },
                    fetchFortune(&state, allowCache: false, clearExisting: false)
                )

            case .openInsightTapped:
                guard let fortune = state.fortune else { return .none }
                state.insight = AstrologyInsightFeature.State(
                    fortune: fortune,
                    metadata: fortune.astroMetadata
                )
                return .run { _ in await hapticClient.lightImpact() }

            case .shareTapped:
                guard let fortune = state.fortune else { return .none }
                state.sharePayload = Self.makeSharePayload(for: fortune)
                return .run { _ in await hapticClient.lightImpact() }

            case .shareSheetDismissed:
                state.sharePayload = nil
                return .none

            case let .fortuneLoaded(fortune, fromCache):
                state.fortune = fortune
                state.isLoading = false
                state.errorMessage = nil
                if let insight = state.insight {
                    state.insight = AstrologyInsightFeature.State(
                        fortune: fortune,
                        metadata: fortune.astroMetadata ?? insight.metadata
                    )
                }
                guard !fromCache else { return .none }
                return .run { _ in await hapticClient.success() }

            case let .fortuneFailed(message):
                state.fortune = nil
                state.insight = nil
                state.isLoading = false
                let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
                state.errorMessage = trimmed.isEmpty
                    ? "Không thể kết nối máy chủ chiêm tinh. Vui lòng thử lại."
                    : trimmed
                return .none

            case .insight:
                return .none
            }
        }
        .ifLet(\.$insight, action: \.insight) {
            AstrologyInsightFeature()
        }
    }

    // MARK: - Private Helpers

    private func refreshConstellation(_ state: inout State) {
        let symbol = ConstellationEngine.dailySymbol(
            date: state.currentDate,
            profileKey: state.profileKey,
            calendar: calendar
        )
        state.symbol = symbol
        do {
            state.geometry = try ConstellationEngine.buildGeometry(for: symbol)
            state.geometryErrorMessage = nil
        } catch {
            state.geometry = nil
            state.geometryErrorMessage = error.localizedDescription
        }
    }

    private func fetchFortune(
        _ state: inout State,
        allowCache: Bool,
        clearExisting: Bool
    ) -> Effect<Action> {
        if clearExisting {
            state.fortune = nil
            state.insight = nil
        }
        state.isLoading = true
        state.errorMessage = nil

        let targetDate = state.currentDate
        let targetProfile = state.profile

        return .run { send in
            let dailyCaDao = await caDaoClient.dailyCaDao(targetDate)
            let anchor = AstrologyClient.resolveAnchorCaDao(
                explicit: nil,
                dailyRecord: dailyCaDao
            )
            let query = AstroDailyFortuneQuery(
                date: targetDate,
                profile: targetProfile,
                anchorCaDao: anchor
            )

            do {
                if allowCache,
                   let cached = await astrologyClient.cachedDailyFortune(query)
                {
                    await send(.fortuneLoaded(cached, fromCache: true))
                    return
                }

                let cachePolicy: AstroFortuneCachePolicy = allowCache ? .useCache : .reloadIgnoringCache
                let fortune = try await astrologyClient.dailyFortune(query, cachePolicy)
                await send(.fortuneLoaded(fortune, fromCache: false))
            } catch is CancellationError {
                return
            } catch {
                await send(.fortuneFailed(error.localizedDescription))
            }
        }
        .cancellable(id: CancelID.fortune, cancelInFlight: true)
    }

    private func scheduleMidnightTimer(from date: Date) -> Effect<Action> {
        let delayMs = Self.millisecondsUntilNextLocalDay(from: date, calendar: calendar)
        return .run { send in
            do {
                try await clock.sleep(for: .milliseconds(delayMs))
                await send(.midnightTick)
            } catch {
                return
            }
        }
        .cancellable(id: CancelID.midnightTimer, cancelInFlight: true)
    }

    // MARK: - Pure Static Helpers (Parity with AstrologyScreen.tsx & useDailyAstroFortune.ts)

    nonisolated static func formatShortDate(_ date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.day, .month], from: date)
        return String(
            format: "%02d.%02d",
            components.day ?? 1,
            components.month ?? 1
        )
    }

    nonisolated static func makeSharePayload(for fortune: AstroFortuneSlip) -> SharePayload {
        let trimmedTitle = fortune.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let shareTitle = (trimmedTitle?.isEmpty == false) ? trimmedTitle! : "Lá Thăm Chiêm Tinh"
        let headerTitle = (trimmedTitle?.isEmpty == false) ? trimmedTitle! : "Quẻ Xăm Dân Gian"
        let message = """
        📜 LÁ THĂM CHIÊM TINH HÔM NAY: \(headerTitle)

        \(fortune.verse)

        🪞 Gương soi: \(fortune.mirror)
        🎒 Kế sách: \(fortune.advice)

        ✨ Bốc quẻ chiêm tinh dân gian trên Numelyra.
        """
        return SharePayload(title: shareTitle, message: message)
    }

    nonisolated static func millisecondsUntilNextLocalDay(
        from date: Date,
        calendar: Calendar = .current
    ) -> Int {
        let startOfToday = calendar.startOfDay(for: date)
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
            return 60_000
        }
        let intervalMs = Int((nextDay.timeIntervalSince(date) * 1_000).rounded()) + 250
        return max(1_000, intervalMs)
    }
}
