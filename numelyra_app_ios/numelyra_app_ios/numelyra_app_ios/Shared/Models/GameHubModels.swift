import Foundation

public enum GameId: String, Codable, CaseIterable, Equatable, Sendable {
    case arrowEscape = "arrow-escape"
    case mindRules = "mind-rules"
    case oAnQuan = "o-an-quan"
    case dotsBoxes = "dots-boxes"
    case sudoku = "sudoku"
    case game2048 = "game-2048"
    case zip = "zip"

    public var titleVi: String {
        switch self {
        case .arrowEscape: return "Arrow Escape"
        case .mindRules: return "Mind Rules"
        case .oAnQuan: return "Ô Ăn Quan"
        case .dotsBoxes: return "Nối Ô (DotBox)"
        case .sudoku: return "Sudoku"
        case .game2048: return "2048"
        case .zip: return "Zip"
        }
    }
}

public struct GameProgressSummary: Codable, Equatable, Sendable {
    public var playedAt: String? // ISO date string
    public var completed: Int
    public var total: Int?
    public var bestScore: Int?

    public init(
        playedAt: String? = nil,
        completed: Int = 0,
        total: Int? = nil,
        bestScore: Int? = nil
    ) {
        self.playedAt = playedAt
        self.completed = completed
        self.total = total
        self.bestScore = bestScore
    }
}

public struct DailyChallenge: Identifiable, Codable, Equatable, Sendable {
    public var id: String // e.g. "zip:2026-10-06"
    public var dateKey: String // YYYY-MM-DD
    public var gameId: GameId
    public var title: String
    public var subtitle: String

    public init(
        id: String,
        dateKey: String,
        gameId: GameId,
        title: String,
        subtitle: String
    ) {
        self.id = id
        self.dateKey = dateKey
        self.gameId = gameId
        self.title = title
        self.subtitle = subtitle
    }
}

public struct GameHubProgress: Codable, Equatable, Sendable {
    public var version: Int
    public var streak: Int
    public var lastDailyDate: String?
    public var games: [String: GameProgressSummary]

    public init(
        version: Int = 1,
        streak: Int = 0,
        lastDailyDate: String? = nil,
        games: [String: GameProgressSummary] = [:]
    ) {
        self.version = version
        self.streak = streak
        self.lastDailyDate = lastDailyDate
        self.games = games
    }
}
