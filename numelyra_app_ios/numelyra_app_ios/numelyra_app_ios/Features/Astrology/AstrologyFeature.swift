import ComposableArchitecture
import Foundation

@Reducer
struct AstrologyFeature {
    @Reducer
    enum Path {
        case natal(AstrologyNatalFeature)
        case detail(AstrologyDetailFeature)
    }

    @Reducer
    enum Destination {
        case profilePicker(AstrologyProfilePickerFeature)
        case birthData(AstrologyBirthDataFeature)
    }

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
        /// Ngày địa phương đang được dùng để lấy quẻ hằng ngày.
        var currentDate: Date
        /// Hồ sơ đang được dùng để cá nhân hóa phép tính và khóa cache.
        var profile: UserProfile?
        /// Quẻ chiêm tinh của ngày hiện tại sau khi đọc cache hoặc tải từ dịch vụ.
        var fortune: AstroFortuneSlip?
        /// Metadata tính cục bộ, không phụ thuộc fortune API nên Today/Natal vẫn hoạt động offline.
        var localMetadata: AstroFeatureMetadata?
        /// Lỗi tính metadata cục bộ; tách biệt với lỗi tải luận giải trực tuyến.
        var calculationErrorMessage: String?
        /// Cho biết request lấy quẻ đang chạy.
        var isLoading: Bool
        /// Thông báo lỗi lấy quẻ cần hiển thị; được xóa khi bắt đầu thử lại hoặc tải thành công.
        var errorMessage: String?
        /// Cho biết tab Chiêm tinh đang thực sự hiển thị trên màn hình.
        var isScreenVisible: Bool
        /// Ghi nhận feature đã chạy `onAppear` ít nhất một lần để tránh tải lại không cần thiết.
        var hasAppeared: Bool
        /// Dirty flag yêu cầu tải lại quẻ khi hồ sơ đổi trong lúc màn hình không hiển thị.
        var needsRefresh: Bool
        /// Nội dung đang được đưa sang share sheet; `nil` nghĩa là share sheet đóng.
        var sharePayload: SharePayload?

        /// Stack Today → Natal Chart → detail được điều khiển hoàn toàn bằng TCA state.
        var path = StackState<Path.State>()

        /// Profile picker hoặc birth-data sheet đang được trình bày.
        @Presents
        var destination: Destination.State?

        /// State của sheet giải mã chi tiết; có giá trị khi sheet đang được trình bày.
        @Presents
        var insight: AstrologyInsightFeature.State?

        init(
            currentDate: Date = Date(),
            profile: UserProfile? = nil,
            fortune: AstroFortuneSlip? = nil,
            localMetadata: AstroFeatureMetadata? = nil,
            calculationErrorMessage: String? = nil,
            isLoading: Bool = false,
            errorMessage: String? = nil,
            isScreenVisible: Bool = false,
            hasAppeared: Bool = false,
            needsRefresh: Bool = false,
            sharePayload: SharePayload? = nil,
            path: StackState<Path.State> = StackState<Path.State>(),
            destination: Destination.State? = nil,
            insight: AstrologyInsightFeature.State? = nil
        ) {
            self.currentDate = currentDate
            self.profile = profile
            self.fortune = fortune
            self.localMetadata = localMetadata
            self.calculationErrorMessage = calculationErrorMessage
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.isScreenVisible = isScreenVisible
            self.hasAppeared = hasAppeared
            self.needsRefresh = needsRefresh
            self.sharePayload = sharePayload
            self.path = path
            self.destination = destination
            self.insight = insight
        }

        /// Ngày hiện tại được định dạng `DD.MM` cho phần tiêu đề.
        var formattedShortDate: String {
            AstrologyFeature.formatShortDate(currentDate)
        }

        /// Chuỗi tiêu đề ngày hoàn chỉnh hiển thị ở đầu màn hình.
        var dateHeaderText: String {
            "Hôm nay • \(formattedShortDate)"
        }

        /// Tiêu đề quẻ đã chuẩn hóa, có fallback khi backend không trả tiêu đề hợp lệ.
        var fortuneTitleText: String {
            AstrologyInsightFeature.normalizedTitle(fortune?.title)
        }

        /// Metadata chiêm tinh đính kèm quẻ, dùng để hiển thị dữ liệu cá nhân hóa trong sheet chi tiết.
        var metadata: AstroFeatureMetadata? {
            localMetadata ?? fortune?.astroMetadata
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.currentDate == rhs.currentDate
                && lhs.profile == rhs.profile
                && lhs.fortune == rhs.fortune
                && lhs.localMetadata == rhs.localMetadata
                && lhs.calculationErrorMessage == rhs.calculationErrorMessage
                && lhs.isLoading == rhs.isLoading
                && lhs.errorMessage == rhs.errorMessage
                && lhs.isScreenVisible == rhs.isScreenVisible
                && lhs.hasAppeared == rhs.hasAppeared
                && lhs.needsRefresh == rhs.needsRefresh
                && lhs.sharePayload == rhs.sharePayload
                // TCA's navigation and presentation wrappers intentionally do not conform to Equatable.
                && String(reflecting: lhs.path) == String(reflecting: rhs.path)
                && String(reflecting: lhs.destination) == String(reflecting: rhs.destination)
                && String(reflecting: lhs.insight) == String(reflecting: rhs.insight)
        }

    }

    enum Action: Equatable {
        case onAppear
        case onDisappear
        case scenePhaseChanged(isActive: Bool)
        case midnightTick
        case profileUpdated(UserProfile?)
        case profileTapped
        case birthDataTapped
        case natalTapped
        case detailTapped(AstrologyDetailTarget, mode: AstrologyPlanetDetailMode)
        case retryTapped
        case openInsightTapped
        case shareTapped
        case shareSheetDismissed
        case fortuneLoaded(AstroFortuneSlip, fromCache: Bool)
        case fortuneFailed(String)
        case metadataLoaded(AstroFeatureMetadata)
        case metadataFailed(String)
        case path(StackActionOf<Path>)
        case destination(PresentationAction<Destination.Action>)
        case insight(PresentationAction<AstrologyInsightFeature.Action>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case profileChanged(UserProfile)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            // StackAction and PresentationAction are not Equatable in TCA. Their reflected values
            // include the action case and payload, preserving useful TestStore comparisons.
            String(reflecting: lhs) == String(reflecting: rhs)
        }
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
        case metadata
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
                guard isActive else { return .none }
                let currentNow = now
                let isNewDay = AstrologyCacheKey.localDateKey(currentNow, calendar: calendar)
                    != AstrologyCacheKey.localDateKey(state.currentDate, calendar: calendar)
                guard isNewDay else { return .none }
                state.currentDate = currentNow
                return .merge(
                    scheduleMidnightTimer(from: currentNow),
                    fetchFortune(&state, allowCache: true, clearExisting: true)
                )

            case .midnightTick:
                let currentNow = now
                state.currentDate = currentNow
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
                    return fetchFortune(&state, allowCache: true, clearExisting: true)
                } else {
                    state.needsRefresh = true
                    return .none
                }

            case .profileTapped:
                state.destination = .profilePicker(
                    AstrologyProfilePickerFeature.State(
                        profiles: userProfileClient.loadAllProfiles(),
                        selectedID: state.profile?.id
                    )
                )
                return .run { _ in await hapticClient.lightImpact() }

            case .birthDataTapped:
                guard let profile = state.profile else { return .none }
                state.destination = .birthData(AstrologyBirthDataFeature.State(profile: profile))
                return .run { _ in await hapticClient.lightImpact() }

            case .natalTapped:
                state.path.append(.natal(AstrologyNatalFeature.State()))
                return .run { _ in await hapticClient.lightImpact() }

            case let .detailTapped(target, mode):
                state.path.append(.detail(AstrologyDetailFeature.State(target: target, mode: mode)))
                return .run { _ in await hapticClient.lightImpact() }

            case .retryTapped:
                return .merge(
                    .run { _ in await hapticClient.mediumImpact() },
                    fetchFortune(&state, allowCache: false, clearExisting: false)
                )

            case .openInsightTapped:
                guard let fortune = state.fortune else { return .none }
                state.insight = AstrologyInsightFeature.State(
                    fortune: fortune,
                    metadata: state.metadata
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
                        metadata: state.metadata ?? insight.metadata
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

            case let .metadataLoaded(metadata):
                state.localMetadata = metadata
                state.calculationErrorMessage = nil
                return .none

            case let .metadataFailed(message):
                state.localMetadata = nil
                let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
                state.calculationErrorMessage = trimmed.isEmpty
                    ? "Không thể dựng dữ liệu lá số."
                    : trimmed
                return .none

            case .path(.element(id: _, action: .natal(.backTapped))):
                state.path.removeLast()
                return .none

            case .path(.element(id: _, action: .natal(.editBirthDataTapped))),
                 .path(.element(id: _, action: .detail(.editBirthDataTapped))):
                guard let profile = state.profile else { return .none }
                state.destination = .birthData(AstrologyBirthDataFeature.State(profile: profile))
                return .none

            case let .path(.element(id: _, action: .natal(.detailTapped(target)))):
                state.path.append(.detail(AstrologyDetailFeature.State(target: target, mode: .natal)))
                return .none

            case .path(.element(id: _, action: .detail(.backTapped))):
                state.path.removeLast()
                return .none

            case let .destination(.presented(.profilePicker(.delegate(.selected(profile))))):
                userProfileClient.setActiveProfileID(profile.id)
                state.destination = nil
                return .merge(
                    .send(.profileUpdated(profile)),
                    .send(.delegate(.profileChanged(profile)))
                )

            case .destination(.presented(.profilePicker(.delegate(.close)))):
                state.destination = nil
                return .none

            case let .destination(.presented(.birthData(.delegate(.saved(profile))))):
                var profiles = userProfileClient.loadAllProfiles()
                if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
                    profiles[index] = profile
                } else {
                    profiles.append(profile)
                }
                userProfileClient.saveAllProfiles(profiles)
                userProfileClient.setActiveProfileID(profile.id)
                state.destination = nil
                state.insight = nil
                return .merge(
                    .send(.profileUpdated(profile)),
                    .send(.delegate(.profileChanged(profile)))
                )

            case .destination(.presented(.birthData(.delegate(.close)))):
                state.destination = nil
                return .none

            case .path, .destination, .delegate:
                return .none

            case .insight:
                return .none
            }
        }
        .ifLet(\.$insight, action: \.insight) {
            AstrologyInsightFeature()
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.path, action: \.path)
    }

    // MARK: - Private Helpers

    private func fetchFortune(
        _ state: inout State,
        allowCache: Bool,
        clearExisting: Bool
    ) -> Effect<Action> {
        if clearExisting {
            state.fortune = nil
            state.insight = nil
            state.localMetadata = nil
            state.calculationErrorMessage = nil
        }
        state.isLoading = true
        state.errorMessage = nil

        let targetDate = state.currentDate
        let targetProfile = state.profile
        guard let targetProfile,
              !targetProfile.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !targetProfile.birthDate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            state.isLoading = false
            state.localMetadata = nil
            state.calculationErrorMessage = "Chưa có hồ sơ hợp lệ để dựng dữ liệu chiêm tinh."
            return .merge(
                .cancel(id: CancelID.metadata),
                .cancel(id: CancelID.fortune)
            )
        }

        let metadataEffect = Effect<Action>.run { send in
            let query = AstroDailyFortuneQuery(date: targetDate, profile: targetProfile)
            do {
                await send(.metadataLoaded(try await astrologyClient.localMetadata(query)))
            } catch is CancellationError {
                return
            } catch {
                await send(.metadataFailed(error.localizedDescription))
            }
        }
        .cancellable(id: CancelID.metadata, cancelInFlight: true)

        let fortuneEffect = Effect<Action>.run { send in
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
        return .merge(metadataEffect, fortuneEffect)
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
