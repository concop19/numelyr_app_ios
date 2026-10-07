import ComposableArchitecture
import Foundation

@Reducer
struct IndicatorDetailFeature {
    @ObservableState
    struct State: Equatable {
        var indicator: CalculatedNumerologyIndicator
        var reading: KnowledgeReading?
        var isLoading: Bool = false
        var isFullArticleExpanded: Bool = false

        init(
            indicator: CalculatedNumerologyIndicator,
            reading: KnowledgeReading? = nil,
            isLoading: Bool = false,
            isFullArticleExpanded: Bool = false
        ) {
            self.indicator = indicator
            self.reading = reading
            self.isLoading = isLoading
            self.isFullArticleExpanded = isFullArticleExpanded
        }

        var canExpandFullArticle: Bool {
            guard let fullContent = reading?.fullContent else { return false }
            return fullContent.count > 300
        }
    }

    enum Action: Equatable {
        case onAppear
        case readingLoaded(KnowledgeReading)
        case toggleFullArticleTapped
        case closeTapped
        case confirmCloseTapped
    }

    @Dependency(\.numerologyClient) var numerologyClient
    @Dependency(\.hapticClient) var hapticClient
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.reading == nil else { return .none }
                state.isLoading = true
                state.isFullArticleExpanded = false
                let key = state.indicator.definition.key
                let value = state.indicator.displayValue
                let nameVi = state.indicator.definition.nameVi
                return .run { send in
                    let reading = numerologyClient.indicatorReading(key, value, nameVi)
                    await send(.readingLoaded(reading))
                }

            case let .readingLoaded(reading):
                state.reading = reading
                state.isLoading = false
                return .none

            case .toggleFullArticleTapped:
                state.isFullArticleExpanded.toggle()
                return .run { _ in
                    await hapticClient.selection()
                }

            case .closeTapped:
                return .run { _ in
                    await dismiss()
                }

            case .confirmCloseTapped:
                return .run { _ in
                    await hapticClient.success()
                    await dismiss()
                }
            }
        }
    }
}
