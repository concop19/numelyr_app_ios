import Foundation

public nonisolated enum IndicatorCategory: String, Codable, CaseIterable, Equatable, Sendable {
    case core
    case potential
    case karmic
    case bridge
    case cycle
    case chart

    public var titleVi: String {
        switch self {
        case .core: return "Cốt Lõi"
        case .potential: return "Tiềm Năng"
        case .karmic: return "Nghiệp & Bài Học"
        case .bridge: return "Cầu Nối"
        case .cycle: return "Chu Kỳ"
        case .chart: return "Biểu Đồ"
        }
    }

    public var tabTitleVi: String {
        switch self {
        case .core: return "Cốt Lõi"
        case .potential: return "Tiềm Năng"
        case .karmic: return "Nợ Nghiệp"
        case .bridge: return "Cầu Nối"
        case .cycle: return "Vận Hạn"
        case .chart: return "Biểu Đồ"
        }
    }
}

/// Static metadata corresponding to `NumerologyCardMeta` in the React Native source.
public nonisolated struct NumerologyCardDefinition: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var number: String
    public var key: String
    public var nameVi: String
    public var nameEn: String
    public var category: IndicatorCategory
    public var categoryNameVi: String
    public var assetName: String
    public var description: String

    public init(
        id: String,
        number: String,
        key: String,
        nameVi: String,
        nameEn: String,
        category: IndicatorCategory,
        categoryNameVi: String,
        assetName: String,
        description: String
    ) {
        self.id = id
        self.number = number
        self.key = key
        self.nameVi = nameVi
        self.nameEn = nameEn
        self.category = category
        self.categoryNameVi = categoryNameVi
        self.assetName = assetName
        self.description = description
    }
}

/// Preserves the `number | string` union used by both numerology engines.
public nonisolated enum NumerologyValue: Codable, Equatable, Sendable {
    case number(Int)
    case text(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Int.self) {
            self = .number(number)
        } else {
            self = .text(try container.decode(String.self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .number(value): try container.encode(value)
        case let .text(value): try container.encode(value)
        }
    }

    public var displayValue: String {
        switch self {
        case let .number(value): return String(value)
        case let .text(value): return value
        }
    }

    public var numberValue: Int? {
        guard case let .number(value) = self else { return nil }
        return value
    }
}

/// Stable keys shared with the React Native client and backend payloads.
public nonisolated enum NumerologyIndicatorKey: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case walksOfLife
    case mission
    case soul
    case personality
    case dateOfBirth
    case mature
    case balance
    case rationalThinking
    case subconsciousPower
    case passion
    case attitude
    case karmicDebts
    case missingNumbers
    case bridgeLifeMission
    case bridgeSoulPersonality
    case bridgeMaturityPassion
    case yearIndividual
    case monthIndividual
    case dayIndividual
    case way
    case challenges
    case arrows
    case nameChart
    case birthChart
}

/// The two active React Native calculators intentionally have different rules.
/// Keeping their versions explicit prevents a future formula change from silently
/// changing persisted or backend-visible results.
public nonisolated enum NumerologyRulesetVersion: String, Codable, Equatable, Sendable {
    case reactNativeCardsV1 = "react-native-cards-v1"
    case reactNativeAgentV1 = "react-native-agent-v1"
}

public nonisolated struct NumerologyBirthDate: Codable, Equatable, Sendable {
    public var day: Int
    public var month: Int
    public var year: Int

    public init(day: Int, month: Int, year: Int) {
        self.day = day
        self.month = month
        self.year = year
    }
}

public nonisolated enum NumerologyArrowKind: String, Codable, Equatable, Sendable {
    case strong
    case empty
}

public nonisolated struct NumerologyArrow: Codable, Equatable, Sendable {
    public var digits: [Int]
    public var kind: NumerologyArrowKind

    public init(digits: [Int], kind: NumerologyArrowKind) {
        self.digits = digits
        self.kind = kind
    }

    public var displayValue: String {
        let suffix = kind == .strong ? "Mạnh" : "Trống"
        return "\(digits.map(String.init).joined(separator: "-")) (\(suffix))"
    }
}

public nonisolated struct NumerologyComputedIndicator: Identifiable, Codable, Equatable, Sendable {
    public var id: NumerologyIndicatorKey { key }
    public var key: NumerologyIndicatorKey
    public var value: NumerologyValue
    public var isMaster: Bool

    public init(key: NumerologyIndicatorKey, value: NumerologyValue, isMaster: Bool = false) {
        self.key = key
        self.value = value
        self.isMaster = isMaster
    }
}

/// Pure calculation output. Structured diagnostic fields avoid reparsing the
/// display strings when chart UI or other clients are implemented later.
public nonisolated struct NumerologySnapshot: Codable, Equatable, Sendable {
    public var rulesetVersion: NumerologyRulesetVersion
    public var normalizedName: String
    public var birthDate: NumerologyBirthDate
    public var referenceDate: Date
    public var indicators: [NumerologyComputedIndicator]
    public var nameFrequencies: [Int: Int]
    public var birthFrequencies: [Int: Int]
    public var missingNumbers: [Int]
    public var hiddenPassions: [Int]
    public var karmicDebts: [String]
    public var pinnacles: [Int]
    public var challenges: [Int]
    public var arrows: [NumerologyArrow]

    public init(
        rulesetVersion: NumerologyRulesetVersion,
        normalizedName: String,
        birthDate: NumerologyBirthDate,
        referenceDate: Date,
        indicators: [NumerologyComputedIndicator],
        nameFrequencies: [Int: Int],
        birthFrequencies: [Int: Int],
        missingNumbers: [Int],
        hiddenPassions: [Int],
        karmicDebts: [String],
        pinnacles: [Int],
        challenges: [Int],
        arrows: [NumerologyArrow]
    ) {
        self.rulesetVersion = rulesetVersion
        self.normalizedName = normalizedName
        self.birthDate = birthDate
        self.referenceDate = referenceDate
        self.indicators = indicators
        self.nameFrequencies = nameFrequencies
        self.birthFrequencies = birthFrequencies
        self.missingNumbers = missingNumbers
        self.hiddenPassions = hiddenPassions
        self.karmicDebts = karmicDebts
        self.pinnacles = pinnacles
        self.challenges = challenges
        self.arrows = arrows
    }

    public subscript(key: NumerologyIndicatorKey) -> NumerologyComputedIndicator? {
        indicators.first { $0.key == key }
    }
}

/// Compact value sent in the chat agent payload (`IndicatorInfo`).
public nonisolated struct NumerologyIndicator: Identifiable, Codable, Equatable, Sendable {
    public var id: String { key }
    public var key: String
    public var name: String
    public var value: NumerologyValue
    public var meaning: String

    public init(key: String, name: String, value: NumerologyValue, meaning: String) {
        self.key = key
        self.name = name
        self.value = value
        self.meaning = meaning
    }
}

/// UI-ready value corresponding to `CalculatedIndicator`.
public nonisolated struct CalculatedNumerologyIndicator: Identifiable, Codable, Equatable, Sendable {
    public var definition: NumerologyCardDefinition
    public var value: NumerologyValue
    public var displayValue: String
    public var isMaster: Bool

    public var id: String { definition.id }

    public init(
        definition: NumerologyCardDefinition,
        value: NumerologyValue,
        displayValue: String,
        isMaster: Bool = false
    ) {
        self.definition = definition
        self.value = value
        self.displayValue = displayValue
        self.isMaster = isMaster
    }
}

public nonisolated enum KnowledgeSource: String, Codable, Equatable, Sendable {
    case supabase = "supabase-knowledge"
    case offlineArchetype = "offline-archetype"
}

public nonisolated struct KnowledgeReading: Codable, Equatable, Sendable {
    public var title: String
    public var source: KnowledgeSource
    public var overview: String
    public var strengths: [String]
    public var challenges: [String]
    public var advice: String
    public var fullContent: String?

    public init(
        title: String,
        source: KnowledgeSource,
        overview: String,
        strengths: [String] = [],
        challenges: [String] = [],
        advice: String,
        fullContent: String? = nil
    ) {
        self.title = title
        self.source = source
        self.overview = overview
        self.strengths = strengths
        self.challenges = challenges
        self.advice = advice
        self.fullContent = fullContent
    }
}
