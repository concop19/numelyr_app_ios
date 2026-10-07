import Foundation

public nonisolated enum AgentMode: String, Codable, Equatable, Sendable {
    case single
    case compatibility
}

public nonisolated enum AgentIntent: String, Codable, Equatable, Sendable {
    case loveMatch = "love_match"
    case twoChoices = "two_choices"
    case timingTrajectory = "timing_trajectory"
    case dailyGuidance = "daily_guidance"
    case colorGuidance = "color_guidance"
    case whereToGo = "where_to_go"
    case corePersonality = "core_personality"
    case trash = "trash"
    case general = "general"
}

public nonisolated enum TarotSpreadID: String, Codable, CaseIterable, Equatable, Sendable {
    case single
    case threeCard = "three-card"
    case twoOptions = "two-options"
    case relationship
}

public nonisolated struct AgentDecision: Codable, Equatable, Sendable {
    public var mode: AgentMode
    public var intent: AgentIntent
    public var needsTarot: Bool
    public var spreadId: TarotSpreadID?
    public var cardCount: Int
    public var targetIndicators: [String]
    public var thoughtProcess: String
    public var replyText: String?

    public init(
        mode: AgentMode,
        intent: AgentIntent,
        needsTarot: Bool,
        spreadId: TarotSpreadID? = nil,
        cardCount: Int = 0,
        targetIndicators: [String] = [],
        thoughtProcess: String = "",
        replyText: String? = nil
    ) {
        self.mode = mode
        self.intent = intent
        self.needsTarot = needsTarot
        self.spreadId = spreadId
        self.cardCount = cardCount
        self.targetIndicators = targetIndicators
        self.thoughtProcess = thoughtProcess
        self.replyText = replyText
    }
}
