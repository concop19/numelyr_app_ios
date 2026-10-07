import ComposableArchitecture
import Foundation

@Reducer
struct NumerologyCardsFeature {
    enum CategoryFilter: Hashable, Equatable, Sendable {
        case all
        case category(IndicatorCategory)

        static let allTabs: [CategoryFilter] = [
            .all,
            .category(.core),
            .category(.potential),
            .category(.karmic),
            .category(.bridge),
            .category(.cycle),
            .category(.chart)
        ]

        var id: String {
            switch self {
            case .all: return "all"
            case let .category(cat): return cat.rawValue
            }
        }

        var label: String {
            switch self {
            case .all: return "Tất Cả"
            case let .category(cat): return cat.tabTitleVi
            }
        }
    }

    @ObservableState
    struct State: Equatable {
        var activeProfile: UserProfile?
        var selectedCategory: CategoryFilter
        var indicators: [CalculatedNumerologyIndicator]
        var showsCloseButton: Bool

        @Presents var detail: IndicatorDetailFeature.State?

        init(
            activeProfile: UserProfile? = nil,
            selectedCategory: CategoryFilter = .all,
            indicators: [CalculatedNumerologyIndicator] = [],
            showsCloseButton: Bool = true
        ) {
            self.activeProfile = activeProfile
            self.selectedCategory = selectedCategory
            self.indicators = indicators
            self.showsCloseButton = showsCloseButton
        }

        var filteredIndicators: [CalculatedNumerologyIndicator] {
            switch selectedCategory {
            case .all:
                return indicators
            case let .category(category):
                return indicators.filter { $0.definition.category == category }
            }
        }

        var displayFullName: String {
            guard let name = activeProfile?.fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty
            else {
                return "Người Dùng"
            }
            return name
        }

        var displayBirthDate: String {
            guard let date = activeProfile?.birthDate.trimmingCharacters(in: .whitespacesAndNewlines),
                  !date.isEmpty
            else {
                return "Chưa cập nhật"
            }
            return date
        }
    }

    enum Action: Equatable {
        case onAppear
        case activeProfileUpdated(UserProfile?)
        case categorySelected(CategoryFilter)
        case cardTapped(CalculatedNumerologyIndicator)
        case closeTapped
        case detail(PresentationAction<IndicatorDetailFeature.Action>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case didClose
        }
    }

    @Dependency(\.numerologyClient) var numerologyClient
    @Dependency(\.userProfileClient) var userProfileClient
    @Dependency(\.hapticClient) var hapticClient
    @Dependency(\.date.now) var now
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                if state.activeProfile == nil {
                    state.activeProfile = userProfileClient.activeProfile()
                }
                recalculateIndicators(&state)
                return .none

            case let .activeProfileUpdated(profile):
                state.activeProfile = profile
                recalculateIndicators(&state)
                return .none

            case let .categorySelected(category):
                let didChange = state.selectedCategory != category
                state.selectedCategory = category
                guard didChange else { return .none }
                return .run { _ in
                    await hapticClient.selection()
                }

            case let .cardTapped(indicator):
                state.detail = IndicatorDetailFeature.State(indicator: indicator)
                return .run { _ in
                    await hapticClient.lightImpact()
                }

            case .closeTapped:
                return .merge(
                    .send(.delegate(.didClose)),
                    .run { _ in await dismiss() }
                )

            case .detail:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            IndicatorDetailFeature()
        }
    }

    private func recalculateIndicators(_ state: inout State) {
        let fullName = state.activeProfile?.fullName ?? ""
        let birthDate = state.activeProfile?.birthDate ?? ""
        state.indicators = numerologyClient.calculate24Cards(fullName, birthDate, now)
    }
}
