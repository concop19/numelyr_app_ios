import ComposableArchitecture
import Foundation

@Reducer
struct WallpaperFeature {
    enum Step: Equatable, Sendable {
        case input
        case generating
        case result
    }

    struct NumerologySummary: Equatable, Sendable {
        var lifePath: Int
        var destiny: Int
        var personalYear: Int
        var personalDay: Int
    }

    @ObservableState
    struct State: Equatable {
        var step: Step = .input
        var prompt = ""
        var history: [WallpaperItem]
        var selectedIndex = 0
        var profile: UserProfile?
        var isSaving = false
        var toastMessage: String?

        @Presents
        var detail: WallpaperDetailFeature.State?
        @Presents
        var menu: WallpaperMenuFeature.State?
        @Presents
        var profilePicker: WallpaperProfileFeature.State?
        @Presents
        var numerologyCards: NumerologyCardsFeature.State?

        init(
            profile: UserProfile? = nil,
            history: [WallpaperItem] = WallpaperFeature.presetItems
        ) {
            self.profile = profile
            self.history = history
        }

        var activeItem: WallpaperItem? {
            guard history.indices.contains(selectedIndex) else { return history.first }
            return history[selectedIndex]
        }
    }

    enum Action: Equatable {
        case promptChanged(String)
        case generateTapped
        case generationSucceeded([WallpaperItem])
        case generationFailed(String)
        case backTapped
        case menuTapped
        case profileTapped
        case itemSelected(Int)
        case itemTapped(WallpaperItem)
        case tryAnotherTapped
        case saveTapped(WallpaperItem)
        case saveSucceeded(WallpaperSaveResult)
        case saveFailed(String)
        case toastDismissed(String)
        case detail(PresentationAction<WallpaperDetailFeature.Action>)
        case menu(PresentationAction<WallpaperMenuFeature.Action>)
        case profilePicker(PresentationAction<WallpaperProfileFeature.Action>)
        case numerologyCards(PresentationAction<NumerologyCardsFeature.Action>)
    }

    @Dependency(\.wallpaperClient) var wallpaperClient
    @Dependency(\.hapticClient) var hapticClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now

    private nonisolated enum CancelID: Hashable, Sendable {
        case generation
        case save
        case toast
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .promptChanged(prompt):
                state.prompt = prompt
                return .none

            case .generateTapped:
                let prompt = state.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                let effectivePrompt = prompt.isEmpty ? "Falling asleep..." : prompt
                let profile = state.profile ?? Self.fallbackProfile
                let summary = numerologySummary(profile: profile, date: now)
                let style = wallpaperClient.randomStyle()
                let intention = wallpaperClient.randomIntention()
                let request = LuckyWallpaperRequest(
                    fullName: profile.fullName,
                    birthDate: profile.birthDate,
                    lifePathNumber: summary.lifePath,
                    destinyNumber: summary.destiny,
                    personalYear: summary.personalYear,
                    personalDay: summary.personalDay,
                    intentionId: intention.id,
                    styleId: style.id,
                    customWish: effectivePrompt
                )
                state.step = .generating
                state.toastMessage = nil
                return .merge(
                    .run { send in
                        async let items = wallpaperClient.generate(request)
                        do {
                            try await clock.sleep(for: .milliseconds(2_500))
                            await send(.generationSucceeded(try await items))
                        } catch is CancellationError {
                            return
                        } catch {
                            await send(.generationFailed(error.localizedDescription))
                        }
                    }
                    .cancellable(id: CancelID.generation, cancelInFlight: true),
                    .run { _ in await hapticClient.mediumImpact() }
                )

            case let .generationSucceeded(items):
                guard !items.isEmpty else {
                    state.step = .input
                    return showToast("⚠️ Không thể tạo hình nền: Máy chủ chưa trả về ảnh.", state: &state)
                }
                let previousAI = state.history.filter { $0.bundledAssetName == nil }
                state.history = Array((items + previousAI).prefix(20))
                state.selectedIndex = 0
                state.step = .result
                return .merge(
                    showToast("✨ Đã tạo xong \(items.count) phiên bản hình nền may mắn!", state: &state),
                    .run { _ in await hapticClient.success() }
                )

            case let .generationFailed(message):
                state.step = .input
                return showToast("⚠️ Không thể tạo hình nền: \(message)", state: &state)

            case .backTapped:
                let wasGenerating = state.step == .generating
                if state.step == .input {
                    if !state.history.isEmpty { state.step = .result }
                } else {
                    state.step = .input
                }
                let cancel: Effect<Action> = wasGenerating ? .cancel(id: CancelID.generation) : .none
                return .merge(cancel, .run { _ in await hapticClient.lightImpact() })

            case .menuTapped:
                let profile = state.profile ?? Self.fallbackProfile
                let summary = numerologySummary(profile: profile, date: now)
                state.menu = WallpaperMenuFeature.State(
                    lifePath: summary.lifePath,
                    personalDay: summary.personalDay,
                    historyCount: state.history.count
                )
                return .run { _ in await hapticClient.lightImpact() }

            case .profileTapped:
                state.profilePicker = WallpaperProfileFeature.State(
                    profile: state.profile ?? Self.fallbackProfile,
                    isUsingFallback: state.profile == nil
                )
                return .run { _ in await hapticClient.lightImpact() }

            case let .itemSelected(index):
                guard state.history.indices.contains(index), index != state.selectedIndex else {
                    return .none
                }
                state.selectedIndex = index
                return .run { _ in await hapticClient.selection() }

            case let .itemTapped(item):
                state.detail = WallpaperDetailFeature.State(item: item, isSaving: state.isSaving)
                return .none

            case .tryAnotherTapped:
                state.prompt = ""
                state.step = .input
                return .run { _ in await hapticClient.lightImpact() }

            case let .saveTapped(item):
                guard !state.isSaving else { return .none }
                state.isSaving = true
                state.detail?.isSaving = true
                return .merge(
                    .run { send in
                        do {
                            await send(.saveSucceeded(try await wallpaperClient.save(item)))
                        } catch is CancellationError {
                            return
                        } catch {
                            await send(.saveFailed(error.localizedDescription))
                        }
                    }
                    .cancellable(id: CancelID.save, cancelInFlight: true),
                    .run { _ in await hapticClient.lightImpact() }
                )

            case let .saveSucceeded(result):
                state.isSaving = false
                state.detail?.isSaving = false
                return .merge(
                    showToast(result.message, state: &state),
                    .run { _ in await hapticClient.success() }
                )

            case let .saveFailed(message):
                state.isSaving = false
                state.detail?.isSaving = false
                return showToast(message, state: &state)

            case let .toastDismissed(message):
                if state.toastMessage == message { state.toastMessage = nil }
                return .none

            case .detail(.presented(.closeTapped)):
                state.detail = nil
                return .none

            case let .detail(.presented(.saveTapped(item))):
                return .send(.saveTapped(item))

            case .menu(.presented(.delegate(.showLibrary))):
                state.menu = nil
                state.step = .result
                state.selectedIndex = min(state.selectedIndex, max(0, state.history.count - 1))
                return .none

            case .menu(.presented(.delegate(.createNew))):
                state.menu = nil
                state.prompt = ""
                state.step = .input
                return .none

            case .menu(.presented(.delegate(.showNumerologyCards))):
                state.menu = nil
                state.numerologyCards = NumerologyCardsFeature.State(
                    activeProfile: state.profile ?? Self.fallbackProfile
                )
                return .none

            case .menu(.presented(.delegate(.close))):
                state.menu = nil
                return .none

            case let .profilePicker(.presented(.delegate(.selected(profile)))):
                state.profile = profile
                state.profilePicker = nil
                return showToast("Đã dùng hồ sơ \(profile.fullName) cho hình nền.", state: &state)

            case .profilePicker(.presented(.delegate(.close))):
                state.profilePicker = nil
                return .none

            case .numerologyCards(.presented(.delegate(.didClose))),
                 .numerologyCards(.presented(.closeTapped)):
                state.numerologyCards = nil
                return .none

            case .detail, .menu, .profilePicker, .numerologyCards:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) { WallpaperDetailFeature() }
        .ifLet(\.$menu, action: \.menu) { WallpaperMenuFeature() }
        .ifLet(\.$profilePicker, action: \.profilePicker) { WallpaperProfileFeature() }
        .ifLet(\.$numerologyCards, action: \.numerologyCards) { NumerologyCardsFeature() }
    }

    private func showToast(_ message: String, state: inout State) -> Effect<Action> {
        state.toastMessage = message
        return .run { send in
            try await clock.sleep(for: .milliseconds(2_650))
            await send(.toastDismissed(message))
        }
        .cancellable(id: CancelID.toast, cancelInFlight: true)
    }

    private func numerologySummary(profile: UserProfile, date: Date) -> NumerologySummary {
        let values = NumerologyEngine.requestedIndicators(
            fullName: profile.fullName,
            birthDate: profile.birthDate,
            keys: ["walksOfLife", "mission", "yearIndividual"],
            referenceDate: date
        )
        let mapped = Dictionary(uniqueKeysWithValues: values.compactMap { item in
            item.value.numberValue.map { (item.key, $0) }
        })
        let calendar = Calendar.current
        let personalYear = mapped["yearIndividual"] ?? 1
        let personalMonth = NumerologyEngine.reduceNumber(
            personalYear + NumerologyEngine.reduceNumber(calendar.component(.month, from: date), keepMaster: false),
            keepMaster: false
        )
        let personalDay = NumerologyEngine.reduceNumber(
            personalMonth + NumerologyEngine.reduceNumber(calendar.component(.day, from: date), keepMaster: false),
            keepMaster: false
        )
        return NumerologySummary(
            lifePath: mapped["walksOfLife"] ?? 8,
            destiny: mapped["mission"] ?? 1,
            personalYear: personalYear,
            personalDay: personalDay
        )
    }

    static let fallbackProfile = UserProfile(
        id: "wallpaper-fallback",
        fullName: "Numelyra Seeker",
        birthDate: "2000-01-01",
        gender: .female,
        isDefault: true
    )

    static let presetItems: [WallpaperItem] = [
        preset(1, .wallpaperMockCard1, "Hồ Đêm & Dãy Núi Thiêng", "Bảo hộ năng lượng"),
        preset(2, .wallpaperMockCard2, "Cung Trăng Ánh Hồng", "Tình duyên & Bình yên"),
        preset(3, .wallpaperMockCard3, "Hồ Hoàng Hôn & Nai Thần", "An lạc & Chữa lành"),
        preset(4, .wallpaperMockCard4, "Chuyến Tàu Đêm Hy Vọng", "Thịnh vượng & Tài lộc"),
        preset(5, .wallpaperMockCard1, "Hồ Đêm Huyền Bí", "Thịnh vượng & Tài lộc")
    ]

    private static func preset(
        _ index: Int,
        _ asset: AppAsset,
        _ title: String,
        _ intention: String
    ) -> WallpaperItem {
        WallpaperItem(
            id: "preset-\(index)",
            imageUrl: "asset://\(asset.rawValue)",
            title: title,
            affirmationVi: "Vũ trụ ban tặng sự bình yên tuyệt đối và may mắn vĩnh cửu.",
            explanationVi: "Biểu tượng ánh trăng và sắc tím đánh thức trực giác, sự an định và vận may.",
            luckyColorsVi: ["Tím hoàng hôn", "Vàng ánh trăng", "Hồng dạ yến"],
            styleName: "Thiên nhiên mộng mơ",
            intentionName: intention
        )
    }
}

@Reducer
struct WallpaperDetailFeature {
    @ObservableState
    struct State: Equatable {
        var item: WallpaperItem
        var isSaving = false
    }

    enum Action: Equatable {
        case closeTapped
        case saveTapped(WallpaperItem)
    }

    var body: some Reducer<State, Action> {
        Reduce { _, _ in .none }
    }
}

@Reducer
struct WallpaperMenuFeature {
    @ObservableState
    struct State: Equatable {
        var lifePath: Int
        var personalDay: Int
        var historyCount: Int
    }

    enum Action: Equatable {
        case numerologyCardsTapped
        case libraryTapped
        case createNewTapped
        case closeTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case showNumerologyCards
            case showLibrary
            case createNew
            case close
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .numerologyCardsTapped: return .send(.delegate(.showNumerologyCards))
            case .libraryTapped: return .send(.delegate(.showLibrary))
            case .createNewTapped: return .send(.delegate(.createNew))
            case .closeTapped: return .send(.delegate(.close))
            case .delegate: return .none
            }
        }
    }
}

@Reducer
struct WallpaperProfileFeature {
    @ObservableState
    struct State: Equatable {
        var fullName: String
        var birthDate: String
        var gender: Gender
        var originalID: String
        var isUsingFallback: Bool
        var validationMessage: String?

        init(profile: UserProfile, isUsingFallback: Bool) {
            fullName = profile.fullName
            birthDate = profile.birthDate
            gender = profile.gender ?? .female
            originalID = profile.id
            self.isUsingFallback = isUsingFallback
        }
    }

    enum Action: Equatable {
        case fullNameChanged(String)
        case birthDateChanged(String)
        case genderChanged(Gender)
        case applyTapped
        case closeTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case selected(UserProfile)
            case close
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .fullNameChanged(value):
                state.fullName = value
                state.validationMessage = nil
                return .none
            case let .birthDateChanged(value):
                state.birthDate = value
                state.validationMessage = nil
                return .none
            case let .genderChanged(value):
                state.gender = value
                return .none
            case .applyTapped:
                let name = state.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else {
                    state.validationMessage = "Vui lòng nhập họ và tên."
                    return .none
                }
                guard state.birthDate.range(
                    of: #"^\d{4}-\d{2}-\d{2}$"#,
                    options: .regularExpression
                ) != nil else {
                    state.validationMessage = "Ngày sinh cần đúng định dạng YYYY-MM-DD."
                    return .none
                }
                return .send(.delegate(.selected(UserProfile(
                    id: state.isUsingFallback ? UUID().uuidString : state.originalID,
                    fullName: name,
                    birthDate: state.birthDate,
                    gender: state.gender
                ))))
            case .closeTapped:
                return .send(.delegate(.close))
            case .delegate:
                return .none
            }
        }
    }
}
