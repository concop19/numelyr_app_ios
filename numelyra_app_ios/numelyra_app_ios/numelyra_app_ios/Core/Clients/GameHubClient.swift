import ComposableArchitecture
import Foundation

public nonisolated enum GameHubStorage {
    public static let storageKey = "numelyra:game-hub:v1"

    public static func loadProgress(defaults: UserDefaults = .standard) -> GameHubProgress {
        guard let data = defaults.data(forKey: storageKey) ?? defaults.string(forKey: storageKey)?.data(using: .utf8),
              let progress = try? JSONDecoder().decode(GameHubProgress.self, from: data)
        else {
            return GameHubProgress(version: 1, streak: 0, lastDailyDate: nil, games: [:])
        }
        return progress
    }

    public static func saveProgress(_ progress: GameHubProgress, defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(progress),
           let jsonString = String(data: data, encoding: .utf8)
        {
            defaults.set(jsonString, forKey: storageKey)
        }
    }

    public static func recordGameActivity(
        _ gameId: GameId,
        update: PartialGameProgress = .init(),
        defaults: UserDefaults = .standard,
        now: Date = Date()
    ) -> GameHubProgress {
        var current = loadProgress(defaults: defaults)
        let key = gameId.rawValue
        var prev = current.games[key] ?? GameProgressSummary(playedAt: nil, completed: 0, total: nil, bestScore: nil)
        
        let formatter = ISO8601DateFormatter()
        prev.playedAt = formatter.string(from: now)
        if let completed = update.completed { prev.completed = completed }
        if let total = update.total { prev.total = total }
        if let bestScore = update.bestScore { prev.bestScore = bestScore }

        current.games[key] = prev
        saveProgress(current, defaults: defaults)
        return current
    }

    public static func completeDailyChallenge(
        dateKey: String,
        gameId: GameId,
        defaults: UserDefaults = .standard,
        now: Date = Date()
    ) -> GameHubProgress {
        var current = loadProgress(defaults: defaults)
        let alreadyDone = current.lastDailyDate == dateKey
        let key = gameId.rawValue
        var game = current.games[key] ?? GameProgressSummary(playedAt: nil, completed: 0, total: nil, bestScore: nil)
        
        let formatter = ISO8601DateFormatter()
        let nowString = formatter.string(from: now)
        game.playedAt = nowString
        if !alreadyDone {
            game.completed += 1
            if current.lastDailyDate == getYesterdayKey(dateKey) {
                current.streak += 1
            } else {
                current.streak = 1
            }
            current.lastDailyDate = dateKey
        }
        current.games[key] = game
        saveProgress(current, defaults: defaults)
        return current
    }

    public static func getLocalDateKey(date: Date = Date()) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    public static func getYesterdayKey(_ dateKey: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateKey),
              let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date)
        else { return "" }
        return formatter.string(from: yesterday)
    }

    public static func getDailyChallenge(date: Date = Date()) -> DailyChallenge {
        let dateKey = getLocalDateKey(date: date)
        let dailyGames: [GameId] = [.zip, .mindRules, .sudoku, .game2048, .arrowEscape]
        let ordinal = Int(floor(date.timeIntervalSince1970 / 86400.0))
        let index = ((ordinal % dailyGames.count) + dailyGames.count) % dailyGames.count
        let gameId = dailyGames[index]

        let title: String
        let subtitle: String
        switch gameId {
        case .zip:
            title = "Zip Daily"
            subtitle = "Nối toàn bộ ô trong một đường đi."
        case .mindRules:
            title = "Mind Rules Daily"
            subtitle = "Khám phá quy luật số của hôm nay."
        case .sudoku:
            title = "Sudoku Daily"
            subtitle = "Một ván Sudoku mới cho hành trình hôm nay."
        case .game2048:
            title = "2048 Daily"
            subtitle = "Chạm mốc 128 để hoàn thành thử thách."
        case .arrowEscape:
            title = "Arrow Escape Daily"
            subtitle = "Thoát khỏi bàn mũi tên của ngày hôm nay."
        default:
            title = "Thử thách hằng ngày"
            subtitle = "Rèn luyện trí tuệ cùng Numelyra."
        }

        return DailyChallenge(
            id: "\(gameId.rawValue):\(dateKey)",
            dateKey: dateKey,
            gameId: gameId,
            title: title,
            subtitle: subtitle
        )
    }
}

public struct PartialGameProgress: Sendable {
    public var completed: Int?
    public var total: Int?
    public var bestScore: Int?
    public init(completed: Int? = nil, total: Int? = nil, bestScore: Int? = nil) {
        self.completed = completed
        self.total = total
        self.bestScore = bestScore
    }
}

@DependencyClient
public struct GameHubClient: Sendable {
    public var loadProgress: @Sendable () async -> GameHubProgress = {
        GameHubStorage.loadProgress()
    }
    public var recordActivity: @Sendable (_ gameId: GameId) async -> GameHubProgress = { gameId in
        GameHubStorage.recordGameActivity(gameId)
    }
    public var completeDaily: @Sendable (_ dateKey: String, _ gameId: GameId) async -> GameHubProgress = { dateKey, gameId in
        GameHubStorage.completeDailyChallenge(dateKey: dateKey, gameId: gameId)
    }
    public var dailyChallenge: @Sendable (_ date: Date) -> DailyChallenge = { date in
        GameHubStorage.getDailyChallenge(date: date)
    }
}

extension GameHubClient: DependencyKey {
    public static let liveValue = Self(
        loadProgress: { GameHubStorage.loadProgress() },
        recordActivity: { GameHubStorage.recordGameActivity($0) },
        completeDaily: { GameHubStorage.completeDailyChallenge(dateKey: $0, gameId: $1) },
        dailyChallenge: { GameHubStorage.getDailyChallenge(date: $0) }
    )

    public static let previewValue = Self(
        loadProgress: {
            GameHubProgress(
                version: 1,
                streak: 3,
                lastDailyDate: GameHubStorage.getLocalDateKey(),
                games: [
                    "sudoku": GameProgressSummary(playedAt: "2026-10-12T00:00:00Z", completed: 5, total: 10, bestScore: 920)
                ]
            )
        },
        recordActivity: { _ in GameHubProgress(version: 1, streak: 3, lastDailyDate: nil, games: [:]) },
        completeDaily: { _, _ in GameHubProgress(version: 1, streak: 4, lastDailyDate: GameHubStorage.getLocalDateKey(), games: [:]) },
        dailyChallenge: { GameHubStorage.getDailyChallenge(date: $0) }
    )

    public static let testValue = Self()
}

public extension DependencyValues {
    var gameHubClient: GameHubClient {
        get { self[GameHubClient.self] }
        set { self[GameHubClient.self] = newValue }
    }
}
