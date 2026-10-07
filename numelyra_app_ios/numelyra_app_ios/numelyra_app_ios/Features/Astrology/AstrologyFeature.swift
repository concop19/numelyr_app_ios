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
        var currentDate: Date
        var profile: UserProfile?
        var fortune: AstroFortuneSlip?
        var isLoading: Bool
        var errorMessage: String?
        var symbol: ConstellationSymbolPreset
        var geometry: ConstellationGeometry?
        var geometryErrorMessage: String?
        var isScreenVisible: Bool
        var isAppActive: Bool
        var reduceMotion: Bool
        var isVideoReady: Bool
        var hasVideoFailed: Bool
        var hasAppeared: Bool
        var sharePayload: SharePayload?

        @Presents var insight: AstrologyInsightFeature.State?

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

        var profileKey: String {
            AstrologyCacheKey.profileKey(profile)
        }

        var formattedShortDate: String {
            AstrologyFeature.formatShortDate(currentDate)
        }

        var dateHeaderText: String {
            "Hôm nay • \(formattedShortDate)"
        }

        var symbolLabelText: String {
            "BIỂU TƯỢNG HÔM NAY · \(symbol.title.uppercased())"
        }

        var fortuneTitleText: String {
            AstrologyInsightFeature.normalizedTitle(fortune?.title)
        }

        var metadata: AstroFeatureMetadata? {
            fortune?.astroMetadata
        }

        var showVideoLayer: Bool {
            !reduceMotion && !hasVideoFailed
        }

        var shouldPlayVideo: Bool {
            isScreenVisible && isAppActive && !reduceMotion && !hasVideoFailed
        }

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

                let shouldReload = !state.hasAppeared || isNewDay || (state.fortune == nil && !state.isLoading && state.errorMessage == nil)
                state.hasAppeared = true

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
                refreshConstellation(&state)
                guard state.hasAppeared else { return .none }
                return fetchFortune(&state, allowCache: true, clearExisting: true)

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
