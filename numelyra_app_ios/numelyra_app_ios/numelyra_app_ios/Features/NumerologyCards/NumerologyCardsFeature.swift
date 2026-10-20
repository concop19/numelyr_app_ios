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
        /// Hồ sơ dùng để tính 24 chỉ số; nếu chưa được truyền vào, feature lấy hồ sơ active khi xuất hiện.
        var activeProfile: UserProfile?
        /// Tab nhóm chỉ số đang được chọn để lọc danh sách thẻ.
        var selectedCategory: CategoryFilter
        /// Kết quả tính đầy đủ 24 chỉ số cho hồ sơ hiện tại.
        var indicators: [CalculatedNumerologyIndicator]
        /// Vị trí lá bài đang nằm ở giữa carousel, tính trên danh sách sau lọc.
        var activeIndex: Int
        /// Quy định giao diện có hiển thị nút đóng khi feature được mở dạng modal hay không.
        var showsCloseButton: Bool

        /// State của sheet luận giải một chỉ số; có giá trị khi người dùng mở một thẻ.
        @Presents var detail: IndicatorDetailFeature.State?
        /// Màn toàn màn hình hiển thị nhân vật có cùng bộ ba chỉ số cốt lõi.
        @Presents var historicalFigure: HistoricalFigureFeature.State?

        init(
            activeProfile: UserProfile? = nil,
            selectedCategory: CategoryFilter = .all,
            indicators: [CalculatedNumerologyIndicator] = [],
            activeIndex: Int = 0,
            showsCloseButton: Bool = true
        ) {
            self.activeProfile = activeProfile
            self.selectedCategory = selectedCategory
            self.indicators = indicators
            self.activeIndex = activeIndex
            self.showsCloseButton = showsCloseButton
        }

        /// Danh sách chỉ số sau khi áp dụng tab nhóm đang chọn.
        var filteredIndicators: [CalculatedNumerologyIndicator] {
            switch selectedCategory {
            case .all:
                return indicators
            case let .category(category):
                return indicators.filter { $0.definition.category == category }
            }
        }

        var currentIndicator: CalculatedNumerologyIndicator? {
            guard !filteredIndicators.isEmpty else { return nil }
            return filteredIndicators[min(max(activeIndex, 0), filteredIndicators.count - 1)]
        }

        var currentSummary: String {
            currentIndicator.map { NumerologySummaryService.summary(for: $0) } ?? ""
        }

        var representativeTriple: RepresentativeTriple? {
            func value(_ key: NumerologyIndicatorKey) -> Int? {
                indicators.first(where: { $0.definition.key == key.rawValue })?.value.numberValue
            }
            guard let lifePath = value(.walksOfLife),
                  let expression = value(.mission),
                  let soulUrge = value(.soul)
            else { return nil }
            return RepresentativeTriple(
                lifePath: lifePath,
                expression: expression,
                soulUrge: soulUrge
            )
        }

        /// Họ tên an toàn để hiển thị, có fallback khi hồ sơ thiếu hoặc chỉ chứa khoảng trắng.
        var displayFullName: String {
            guard let name = activeProfile?.fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty
            else {
                return "Người Dùng"
            }
            return name
        }

        /// Ngày sinh an toàn để hiển thị, có fallback khi hồ sơ chưa cung cấp ngày sinh.
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
        case activeIndexChanged(Int)
        case cardTapped(index: Int, indicator: CalculatedNumerologyIndicator)
        case exploreCurrentTapped
        case findFigureTapped
        case closeTapped
        case detail(PresentationAction<IndicatorDetailFeature.Action>)
        case historicalFigure(PresentationAction<HistoricalFigureFeature.Action>)
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
                state.activeIndex = 0
                guard didChange else { return .none }
                return .run { _ in
                    await hapticClient.selection()
                }

            case let .activeIndexChanged(index):
                guard !state.filteredIndicators.isEmpty else {
                    state.activeIndex = 0
                    return .none
                }
                let clamped = min(max(index, 0), state.filteredIndicators.count - 1)
                guard state.activeIndex != clamped else { return .none }
                state.activeIndex = clamped
                return .run { _ in await hapticClient.selection() }

            case let .cardTapped(index, indicator):
                guard index == state.activeIndex else {
                    state.activeIndex = min(max(index, 0), max(state.filteredIndicators.count - 1, 0))
                    return .run { _ in await hapticClient.selection() }
                }
                state.detail = IndicatorDetailFeature.State(indicator: indicator)
                return .run { _ in
                    await hapticClient.lightImpact()
                }

            case .exploreCurrentTapped:
                guard let indicator = state.currentIndicator else { return .none }
                state.detail = IndicatorDetailFeature.State(indicator: indicator)
                return .run { _ in await hapticClient.lightImpact() }

            case .findFigureTapped:
                guard let triple = state.representativeTriple else { return .none }
                state.historicalFigure = HistoricalFigureFeature.State(triple: triple)
                return .run { _ in await hapticClient.mediumImpact() }

            case .closeTapped:
                return .merge(
                    .send(.delegate(.didClose)),
                    .run { _ in await dismiss() }
                )

            case .detail, .historicalFigure:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            IndicatorDetailFeature()
        }
        .ifLet(\.$historicalFigure, action: \.historicalFigure) {
            HistoricalFigureFeature()
        }
    }

    private func recalculateIndicators(_ state: inout State) {
        guard let profile = state.activeProfile else {
            state.indicators = []
            state.activeIndex = 0
            return
        }
        state.indicators = numerologyClient.calculate24Cards(profile.fullName, profile.birthDate, now)
        state.activeIndex = min(state.activeIndex, max(state.filteredIndicators.count - 1, 0))
    }
}
