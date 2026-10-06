import Foundation

public enum MessageSender: String, Codable, Equatable, Sendable {
    case user
    case mascot
}

public struct OptionSplit: Codable, Equatable, Sendable {
    public var optionA: Int
    public var optionB: Int

    public init(optionA: Int, optionB: Int) {
        self.optionA = optionA
        self.optionB = optionB
    }
}

public struct AgentSynthesisPayload: Codable, Equatable, Sendable {
    public var type: String
    public var decision: AgentDecision
    public var profiles: [UserProfile]
    public var drawnCards: [DrawnTarotCard]
    public var indicators1: [NumerologyIndicator]?
    public var indicators2: [NumerologyIndicator]?
    public var tuViBazi: TuViBaziSynastry?
    public var colorGuidance: ColorGuidanceContext?
    public var optionSplit: OptionSplit?
    public var compatibilityScore: Int?
    public var questionText: String?

    public init(
        type: String = "agent_synthesis",
        decision: AgentDecision,
        profiles: [UserProfile] = [],
        drawnCards: [DrawnTarotCard] = [],
        indicators1: [NumerologyIndicator]? = nil,
        indicators2: [NumerologyIndicator]? = nil,
        tuViBazi: TuViBaziSynastry? = nil,
        colorGuidance: ColorGuidanceContext? = nil,
        optionSplit: OptionSplit? = nil,
        compatibilityScore: Int? = nil,
        questionText: String? = nil
    ) {
        self.type = type
        self.decision = decision
        self.profiles = profiles
        self.drawnCards = drawnCards
        self.indicators1 = indicators1
        self.indicators2 = indicators2
        self.tuViBazi = tuViBazi
        self.colorGuidance = colorGuidance
        self.optionSplit = optionSplit
        self.compatibilityScore = compatibilityScore
        self.questionText = questionText
    }
}

public enum ChatCardPayload: Codable, Equatable, Sendable {
    case agentSynthesis(AgentSynthesisPayload)
    case unsupported(JSONValue)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let synthesis = try? container.decode(AgentSynthesisPayload.self) {
            self = .agentSynthesis(synthesis)
            return
        }
        self = .unsupported(try container.decode(JSONValue.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .agentSynthesis(payload):
            try container.encode(payload)
        case let .unsupported(payload):
            try container.encode(payload)
        }
    }
}

public struct ChatMessage: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var sender: MessageSender
    public var text: String
    public var time: String
    public var card: ChatCardPayload?
    public var isTypingCompleted: Bool

    public init(
        id: String = UUID().uuidString,
        sender: MessageSender,
        text: String,
        time: String = "",
        card: ChatCardPayload? = nil,
        isTypingCompleted: Bool = true
    ) {
        self.id = id
        self.sender = sender
        self.text = text
        self.time = time
        self.card = card
        self.isTypingCompleted = isTypingCompleted
    }
}
