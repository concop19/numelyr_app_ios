import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var isInitialized: Bool = false
    }

    enum Action: Equatable {
        case onAppear
        case initializeApp
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.initializeApp)
            case .initializeApp:
                state.isInitialized = true
                return .none
            }
        }
    }
}
