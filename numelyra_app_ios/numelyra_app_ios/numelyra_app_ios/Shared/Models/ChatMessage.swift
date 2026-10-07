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

public struct ChatZiWeiCompatibilityPayload: Codable, Equatable, Sendable {
    public var chart1: ZiWeiChart
    public var chart2: ZiWeiChart
    public var analysis: ZiWeiLoveAnalysis

    public init(chart1: ZiWeiChart, chart2: ZiWeiChart, analysis: ZiWeiLoveAnalysis) {
        self.chart1 = chart1
        self.chart2 = chart2
        self.analysis = analysis
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
    public var ziWeiCompatibility: ChatZiWeiCompatibilityPayload?
    public var colorGuidance: ColorGuidanceContext?
    public var optionSplit: OptionSplit?
    public var compatibilityScore: Int?
    public var questionText: String?
    public var placeSuggestions: PlaceSuggestionsPayload?

    public init(
        type: String = "agent_synthesis",
        decision: AgentDecision,
        profiles: [UserProfile] = [],
        drawnCards: [DrawnTarotCard] = [],
        indicators1: [NumerologyIndicator]? = nil,
        indicators2: [NumerologyIndicator]? = nil,
        tuViBazi: TuViBaziSynastry? = nil,
        ziWeiCompatibility: ChatZiWeiCompatibilityPayload? = nil,
        colorGuidance: ColorGuidanceContext? = nil,
        optionSplit: OptionSplit? = nil,
        compatibilityScore: Int? = nil,
        questionText: String? = nil,
        placeSuggestions: PlaceSuggestionsPayload? = nil
    ) {
        self.type = type
        self.decision = decision
        self.profiles = profiles
        self.drawnCards = drawnCards
        self.indicators1 = indicators1
        self.indicators2 = indicators2
        self.tuViBazi = tuViBazi
        self.ziWeiCompatibility = ziWeiCompatibility
        self.colorGuidance = colorGuidance
        self.optionSplit = optionSplit
        self.compatibilityScore = compatibilityScore
        self.questionText = questionText
        self.placeSuggestions = placeSuggestions
    }
}

public struct PlaceSuggestion: Identifiable, Codable, Equatable, Sendable {
    public var placeId: String?
    public var name: String
    public var mapsUrl: String
    public var address: String?
    public var distanceKm: Double?
    public var primaryType: String?
    public var priceLevel: String?
    public var openNow: Bool?
    public var whySelected: String?

    public var id: String { placeId ?? "\(name)|\(mapsUrl)" }
}

public struct PlaceSuggestionsPayload: Codable, Equatable, Sendable {
    public var areaLabel: String
    public var attribution: String
    public var places: [PlaceSuggestion]

    public init(areaLabel: String, attribution: String = "Google Maps", places: [PlaceSuggestion]) {
        self.areaLabel = areaLabel
        self.attribution = attribution
        self.places = places
    }
}

public struct LegacyTarotPayload: Codable, Equatable, Sendable {
    public var type: String
    public var cards: [DrawnTarotCard]
}

public struct LegacyLunarGuidancePayload: Codable, Equatable, Sendable {
    public var type: String
    public var suggestedDepartureTime: String?
    public var yi: [String]?
}

public enum ChatCardPayload: Codable, Equatable, Sendable {
    case agentSynthesis(AgentSynthesisPayload)
    case placeSuggestions(PlaceSuggestionsPayload)
    case tarot(LegacyTarotPayload)
    case lunarGuidance(LegacyLunarGuidancePayload)
    case unsupported(JSONValue)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(JSONValue.self)
        let data = try JSONEncoder().encode(raw)
        if let synthesis = try? JSONDecoder().decode(AgentSynthesisPayload.self, from: data),
           synthesis.type == "agent_synthesis"
        {
            self = .agentSynthesis(synthesis)
            return
        }
        if let wrapper = try? JSONDecoder().decode(PlaceSuggestionsEnvelope.self, from: data),
           !wrapper.resolved.places.isEmpty
        {
            self = .placeSuggestions(wrapper.resolved)
            return
        }
        if let tarot = try? JSONDecoder().decode(LegacyTarotPayload.self, from: data), tarot.type == "tarot" {
            self = .tarot(tarot)
            return
        }
        if let lunar = try? JSONDecoder().decode(LegacyLunarGuidancePayload.self, from: data), lunar.type == "lunar_guidance" {
            self = .lunarGuidance(lunar)
            return
        }
        self = .unsupported(raw)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .agentSynthesis(payload):
            try container.encode(payload)
        case let .placeSuggestions(payload):
            try container.encode(payload)
        case let .tarot(payload):
            try container.encode(payload)
        case let .lunarGuidance(payload):
            try container.encode(payload)
        case let .unsupported(payload):
            try container.encode(payload)
        }
    }

    private struct PlaceSuggestionsEnvelope: Decodable {
        var areaLabel: String?
        var attribution: String?
        var places: [PlaceSuggestion]?
        var placeSuggestions: PlaceSuggestionsPayload?

        var resolved: PlaceSuggestionsPayload {
            placeSuggestions ?? PlaceSuggestionsPayload(
                areaLabel: areaLabel ?? "",
                attribution: attribution ?? "Google Maps",
                places: places ?? []
            )
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
