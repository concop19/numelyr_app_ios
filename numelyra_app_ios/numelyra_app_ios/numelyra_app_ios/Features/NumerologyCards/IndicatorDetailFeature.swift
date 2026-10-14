import ComposableArchitecture
import Foundation

@Reducer
struct IndicatorDetailFeature {
    @ObservableState
    struct State: Equatable {
        /// Chỉ số đã tính mà sheet đang trình bày.
        var indicator: CalculatedNumerologyIndicator
        /// Nội dung luận giải lấy từ kho kiến thức cho khóa và giá trị của chỉ số.
        var reading: KnowledgeReading?
        /// Cho biết nội dung luận giải đang được nạp.
        var isLoading: Bool = false
        /// Điều khiển việc hiển thị toàn bộ bài viết dài thay vì phần tóm tắt.
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

        /// Cho biết bài viết đầy đủ đủ dài để giao diện hiển thị nút mở rộng/thu gọn.
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
