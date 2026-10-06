import ComposableArchitecture
import Foundation

@Reducer
struct BirthPlacePickerFeature {
    @ObservableState
    struct State: Equatable {
        var query = ""
        var suggestions: [BirthPlaceSuggestion] = []
        var isSearching = false
        var isResolving = false
        var errorMessage: String?
        var session: BirthPlaceSearchSession?
        var lastFailedQuery: String?
    }

    enum Action: Equatable {
        case onAppear
        case sessionCreated(BirthPlaceSearchSession)
        case queryChanged(String)
        case searchSucceeded([BirthPlaceSuggestion])
        case searchFailed(query: String, message: String)
        case suggestionTapped(BirthPlaceSuggestion)
        case resolveSucceeded(ResolvedBirthLocation)
        case resolveFailed(String)
        case retryTapped
        case skipTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case selected(reference: BirthLocationReference, resolved: ResolvedBirthLocation)
            case skipped
        }
    }

    @Dependency(\.birthLocationClient) var birthLocationClient
    @Dependency(\.continuousClock) var clock

    private nonisolated enum CancelID: Hashable, Sendable { case search }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.session == nil else { return .none }
                return .run { send in
                    await send(.sessionCreated(birthLocationClient.makeSession()))
                }

            case let .sessionCreated(session):
                state.session = session
                return .none

            case let .queryChanged(query):
                state.query = query
                state.errorMessage = nil
                state.lastFailedQuery = nil
                let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard normalized.count >= 3, let session = state.session else {
                    state.isSearching = false
                    state.suggestions = []
                    return .cancel(id: CancelID.search)
                }
                state.isSearching = true
                return searchEffect(query: normalized, session: session)

            case let .searchSucceeded(suggestions):
                state.isSearching = false
                state.suggestions = suggestions
                if suggestions.isEmpty {
                    state.errorMessage = BirthLocationClientError.noResults.localizedDescription
                }
                return .none

            case let .searchFailed(query, message):
                state.isSearching = false
                state.errorMessage = message
                state.lastFailedQuery = query
                return .none

            case let .suggestionTapped(suggestion):
                guard let session = state.session else { return .none }
                state.isResolving = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let location = try await birthLocationClient.resolve(suggestion, session)
                        await send(.resolveSucceeded(location))
                    } catch is CancellationError {
                        return
                    } catch {
                        await send(.resolveFailed(error.localizedDescription))
                    }
                }

            case let .resolveSucceeded(location):
                state.isResolving = false
                let reference = BirthLocationReference(
                    placeID: location.placeID,
                    userLabel: location.userLabel
                )
                return .send(.delegate(.selected(reference: reference, resolved: location)))

            case let .resolveFailed(message):
                state.isResolving = false
                state.errorMessage = message
                return .none

            case .retryTapped:
                guard let session = state.session else { return .send(.onAppear) }
                let query = state.lastFailedQuery ?? state.query
                guard query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else {
                    return .none
                }
                state.isSearching = true
                state.errorMessage = nil
                return searchEffect(query: query, session: session)

            case .skipTapped:
                return .send(.delegate(.skipped))

            case .delegate:
                return .none
            }
        }
    }

    private func searchEffect(
        query: String,
        session: BirthPlaceSearchSession
    ) -> Effect<Action> {
        .run { send in
            do {
                try await clock.sleep(for: .milliseconds(300))
                let suggestions = try await birthLocationClient.suggestions(query, session)
                await send(.searchSucceeded(Array(suggestions.prefix(5))))
            } catch is CancellationError {
                return
            } catch {
                await send(.searchFailed(query: query, message: error.localizedDescription))
            }
        }
        .cancellable(id: CancelID.search, cancelInFlight: true)
    }
}
