import Foundation

public enum FengShuiElement: String, Codable, CaseIterable, Equatable, Sendable {
    case kim = "Kim"
    case moc = "Mộc"
    case thuy = "Thủy"
    case hoa = "Hỏa"
    case tho = "Thổ"
}

public enum TarotElement: String, Codable, CaseIterable, Equatable, Sendable {
    case fire
    case water
    case air
    case earth
}

public enum FengShuiColorID: String, Codable, CaseIterable, Equatable, Sendable {
    case white, gray, silver, yellow, beige
    case black, navy, purple, green, blue
    case moss, red, orange, pink, coral, brown
}

public struct FengShuiColor: Identifiable, Codable, Equatable, Sendable {
    public var id: FengShuiColorID
    public var name: String
    public var hex: String

    public init(id: FengShuiColorID, name: String, hex: String) {
        self.id = id
        self.name = name
        self.hex = hex
    }
}

public struct SelectedColorPair: Codable, Equatable, Sendable {
    public var first: FengShuiColorID
    public var second: FengShuiColorID

    public init(first: FengShuiColorID, second: FengShuiColorID) {
        self.first = first
        self.second = second
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        first = try container.decode(FengShuiColorID.self)
        second = try container.decode(FengShuiColorID.self)
        guard container.isAtEnd else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "selectedColorIds must contain exactly two values"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(first)
        try container.encode(second)
    }
}

public struct ColorGuidanceContext: Codable, Equatable, Sendable {
    public var ruleVersion: String
    public var sourceUrl: String
    public var lunarYear: Int
    public var element: FengShuiElement
    public var palette: [FengShuiColor]
    public var selectedColorIds: SelectedColorPair
    public var tarotElement: TarotElement
    public var cardId: String
    public var isReversed: Bool

    public init(
        ruleVersion: String = "v1",
        sourceUrl: String = "",
        lunarYear: Int,
        element: FengShuiElement,
        palette: [FengShuiColor] = [],
        selectedColorIds: SelectedColorPair,
        tarotElement: TarotElement,
        cardId: String,
        isReversed: Bool
    ) {
        self.ruleVersion = ruleVersion
        self.sourceUrl = sourceUrl
        self.lunarYear = lunarYear
        self.element = element
        self.palette = palette
        self.selectedColorIds = selectedColorIds
        self.tarotElement = tarotElement
        self.cardId = cardId
        self.isReversed = isReversed
    }
}
