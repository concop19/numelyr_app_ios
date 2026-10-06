import Foundation

public enum IndicatorCategory: String, Codable, CaseIterable, Equatable, Sendable {
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
}

/// Static metadata corresponding to `NumerologyCardMeta` in the React Native source.
public struct NumerologyCardDefinition: Identifiable, Codable, Equatable, Sendable {
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
public enum NumerologyValue: Codable, Equatable, Sendable {
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
}

/// Compact value sent in the chat agent payload (`IndicatorInfo`).
public struct NumerologyIndicator: Identifiable, Codable, Equatable, Sendable {
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
public struct CalculatedNumerologyIndicator: Identifiable, Codable, Equatable, Sendable {
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

public enum KnowledgeSource: String, Codable, Equatable, Sendable {
    case supabase = "supabase-knowledge"
    case offlineArchetype = "offline-archetype"
}

public struct KnowledgeReading: Codable, Equatable, Sendable {
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
