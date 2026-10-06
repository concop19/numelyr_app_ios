import Foundation

public enum ArrowEscapeModels {
    public enum Direction: String, Codable, CaseIterable, Equatable, Sendable {
        case up = "UP"
        case down = "DOWN"
        case left = "LEFT"
        case right = "RIGHT"
    }

    public enum Difficulty: String, Codable, CaseIterable, Equatable, Sendable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        case expert = "Expert"
    }

    public struct GridPosition: Codable, Equatable, Hashable, Sendable {
        public var x: Int
        public var y: Int
    }

    public struct Arrow: Identifiable, Codable, Equatable, Sendable {
        public var id: String
        public var path: [GridPosition]
        public var fullPath: [GridPosition]
    }

    public struct GridSize: Codable, Equatable, Sendable {
        public var columns: Int
        public var rows: Int
    }

    public struct Level: Identifiable, Codable, Equatable, Sendable {
        public var id: Int
        public var title: String
        public var difficulty: Difficulty
        public var gridSize: GridSize
        public var arrows: [Arrow]
    }

    public struct Board: Codable, Equatable, Sendable {
        public var level: Level
        public var arrows: [Arrow]
        public var livesLeft: Int
        public var removedIds: [String]
    }

    public enum TapResult: Codable, Equatable, Sendable {
        case removed(arrowId: String, board: Board)
        case blocked(arrowId: String, livesLeft: Int, board: Board)
    }

    public struct Progress: Codable, Equatable, Sendable {
        public var currentLevelId: Int
        public var highestUnlockedLevel: Int
        public var hasSeenTutorial: Bool
        public var soundEnabled: Bool
        public var hapticsEnabled: Bool
        public var musicEnabled: Bool
    }
}

public enum SpaceGameModels {
    public enum AmmoType: String, Codable, CaseIterable, Equatable, Sendable {
        case normal = "NORMAL"
        case scatter = "SCATTER"
        case missile = "MISSILE"
        case shield = "SHIELD"
    }

    public struct AmmoConfig: Codable, Equatable, Sendable {
        public var name: String
        public var color: String
        public var label: String
        public var icon: String
    }

    public struct GridPoint: Codable, Equatable, Hashable, Sendable {
        public var x: Double
        public var y: Double
    }

    public struct MiniArrow: Identifiable, Codable, Equatable, Sendable {
        public var id: String
        public var fullPath: [GridPoint]
        public var ammoType: AmmoType
        public var color: String
    }

    public struct MiniBoard: Codable, Equatable, Sendable {
        public var columns: Int
        public var rows: Int
        public var arrows: [MiniArrow]
    }

    public enum Status: String, Codable, Equatable, Sendable {
        case playing = "PLAYING"
        case gameOver = "GAMEOVER"
    }

    public struct State: Codable, Equatable, Sendable {
        public var score: Int
        public var wave: Int
        public var ammo: Int
        public var maxAmmo: Int
        public var health: Int
        public var maxHealth: Int
        public var overdriveTimer: Double
        public var shieldTimer: Double
        public var chickensDefeated: Int
        public var status: Status
    }
}

public enum MindRulesModels {
    public struct Equation: Codable, Equatable, Sendable {
        public var input: Int
        public var output: Int
    }

    public struct Puzzle: Identifiable, Codable, Equatable, Sendable {
        public var id: Int
        public var title: String
        public var equations: [Equation]
        public var question: Int
        public var answer: Int
        public var hint: String
        public var explanation: String?
    }

    /// AsyncStorage stores this value as a scalar string in the RN implementation.
    public struct Progress: Codable, Equatable, Sendable {
        public var activeLevel: Int
    }
}

public enum OAnQuanModels {
    public enum CellType: String, Codable, Equatable, Sendable {
        case citizen
        case quan
    }

    public struct Cell: Codable, Equatable, Sendable {
        public var type: CellType
        public var citizens: Int
        public var mandarins: Int
    }

    public struct Score: Codable, Equatable, Sendable {
        public var citizens: Int
        public var mandarins: Int
    }

    public struct LastMove: Codable, Equatable, Sendable {
        public var player: Int
        public var selectedIndex: Int
        public var direction: Int
        public var visited: [Int]
    }

    public enum Winner: Codable, Equatable, Sendable {
        case player(Int)
        case draw
    }

    public struct State: Codable, Equatable, Sendable {
        public var cells: [Cell]
        public var currentPlayer: Int
        public var scores: [Score]
        public var winner: Winner?
        public var log: [String]
        public var lastMove: LastMove?
    }
}

public enum DotBoxModels {
    public struct Point: Codable, Equatable, Hashable, Sendable {
        public var x: Int
        public var y: Int
    }

    public enum Orientation: String, Codable, Equatable, Sendable {
        case horizontal = "H"
        case vertical = "V"
    }

    public struct Line: Identifiable, Codable, Equatable, Sendable {
        public var id: String
        public var d1: Point
        public var d2: Point
        public var orientation: Orientation
        public var owner: Int?
    }

    public struct Box: Identifiable, Codable, Equatable, Sendable {
        public var id: Int { index }
        public var index: Int
        public var x: Int
        public var y: Int
        public var lineIds: [String]
        public var owner: Int?
    }

    public enum Winner: Codable, Equatable, Sendable {
        case player(Int)
        case draw
    }

    public struct State: Codable, Equatable, Sendable {
        public var boardSize: Int
        public var dotCount: Int
        public var lines: [String: Line]
        public var boxes: [Box]
        public var currentPlayer: Int
        public var scores: [Int]
        public var isGameOver: Bool
        public var winner: Winner?
        public var extraTurn: Bool
        public var lastClaimedBoxes: [Int]
        public var lastLineId: String?
        public var moveCount: Int
    }
}

public enum SudokuModels {
    public enum Difficulty: String, Codable, CaseIterable, Equatable, Sendable {
        case easy, medium, hard, expert
    }

    public struct Cell: Codable, Equatable, Sendable {
        public var value: Int
        public var isClue: Bool
        public var notes: [Int]
    }

    public struct Board: Codable, Equatable, Sendable {
        public var rows: [[Cell]]

        public var isNineByNine: Bool {
            rows.count == 9 && rows.allSatisfy { $0.count == 9 }
        }
    }
}

public enum Game2048Models {
    public enum Direction: String, Codable, CaseIterable, Equatable, Sendable {
        case up, down, left, right
    }

    public struct Cell: Identifiable, Codable, Equatable, Sendable {
        public var id: String
        public var value: Int
        public var x: Int
        public var y: Int
    }

    public struct BestTileProgress: Codable, Equatable, Sendable {
        public var bestTile: Int
    }
}

public enum ZipModels {
    public enum Difficulty: String, Codable, CaseIterable, Equatable, Sendable {
        case easy, medium, hard
    }

    public struct CellPosition: Codable, Equatable, Hashable, Sendable {
        public var row: Int
        public var column: Int
    }

    public struct Wall: Codable, Equatable, Sendable {
        public var a: CellPosition
        public var b: CellPosition
    }

    public struct Checkpoint: Codable, Equatable, Sendable {
        public var position: CellPosition
        public var value: Int
    }

    public struct Puzzle: Identifiable, Codable, Equatable, Sendable {
        public var id: String
        public var name: String
        public var difficulty: Difficulty
        public var size: Int
        public var checkpoints: [Checkpoint]
        public var walls: [Wall]?
        public var solution: [CellPosition]
    }

    public struct GameStats: Codable, Equatable, Sendable {
        public var visited: Int
        public var total: Int
        public var moves: Int
        public var backtracks: Int
        public var elapsedSec: Int
        public var nextCheckpoint: Int?
    }

    public struct BestResult: Codable, Equatable, Sendable {
        public var bestTimeSec: Int
        public var bestMoves: Int
        public var bestBacktracks: Int
    }

    public struct Progress: Codable, Equatable, Sendable {
        public var completed: [String: BestResult]
        public var streak: Int
        public var lastDailyDate: String?
        public var hasSeenTutorial: Bool
    }
}
