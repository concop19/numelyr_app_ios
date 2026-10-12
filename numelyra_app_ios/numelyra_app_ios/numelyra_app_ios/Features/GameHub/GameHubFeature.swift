import ComposableArchitecture
import Foundation

@Reducer
struct GameHubFeature {
    @ObservableState
    struct State: Equatable {
        var selectedGame: GameId?
        var isDailyMode: Bool = false
        var progress: GameHubProgress?
        var dailyChallenge: DailyChallenge
        var isPlaying: Bool { selectedGame != nil }

        var isDailyCompleted: Bool {
            progress?.lastDailyDate == dailyChallenge.dateKey
        }

        var streak: Int {
            progress?.streak ?? 0
        }

        init(
            selectedGame: GameId? = nil,
            isDailyMode: Bool = false,
            progress: GameHubProgress? = nil,
            date: Date = Date()
        ) {
            self.selectedGame = selectedGame
            self.isDailyMode = isDailyMode
            self.progress = progress
            self.dailyChallenge = GameHubStorage.getDailyChallenge(date: date)
        }
    }

    enum Action: Equatable {
        case onAppear
        case progressLoaded(GameHubProgress)
        case dailyChallengeTapped
        case gameSelected(GameId)
        case closeGameTapped
        case completeDailyTapped
        case closeTapped
        case delegate(Delegate)

        enum Delegate: Equatable, Sendable {
            case close
        }
    }

    @Dependency(\.gameHubClient) var gameHubClient
    @Dependency(\.hapticClient) var hapticClient
    @Dependency(\.date.now) var now

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.dailyChallenge = gameHubClient.dailyChallenge(now)
                return .run { send in
                    let progress = await gameHubClient.loadProgress()
                    await send(.progressLoaded(progress))
                }

            case let .progressLoaded(progress):
                state.progress = progress
                return .none

            case .dailyChallengeTapped:
                state.selectedGame = state.dailyChallenge.gameId
                state.isDailyMode = true
                let gameId = state.dailyChallenge.gameId
                return .merge(
                    .run { _ in await hapticClient.mediumImpact() },
                    .run { send in
                        let updated = await gameHubClient.recordActivity(gameId)
                        await send(.progressLoaded(updated))
                    }
                )

            case let .gameSelected(gameId):
                state.selectedGame = gameId
                state.isDailyMode = false
                return .merge(
                    .run { _ in await hapticClient.selection() },
                    .run { send in
                        let updated = await gameHubClient.recordActivity(gameId)
                        await send(.progressLoaded(updated))
                    }
                )

            case .closeGameTapped:
                state.selectedGame = nil
                state.isDailyMode = false
                return .run { _ in await hapticClient.lightImpact() }

            case .completeDailyTapped:
                let dateKey = state.dailyChallenge.dateKey
                let gameId = state.dailyChallenge.gameId
                return .merge(
                    .run { _ in await hapticClient.mediumImpact() },
                    .run { send in
                        let updated = await gameHubClient.completeDaily(dateKey, gameId)
                        await send(.progressLoaded(updated))
                    }
                )

            case .closeTapped:
                return .send(.delegate(.close))

            case .delegate:
                return .none
            }
        }
    }
}
