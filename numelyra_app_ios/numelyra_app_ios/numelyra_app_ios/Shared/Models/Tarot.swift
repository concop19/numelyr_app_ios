import Foundation

public nonisolated struct TarotCard: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var nameVi: String
    public var nameEn: String
    public var number: Int
    public var emoji: String
    public var keywordsUpright: [String]
    public var keywordsReversed: [String]
    public var meaningUpright: String
    public var meaningReversed: String

    public init(
        id: String,
        nameVi: String,
        nameEn: String,
        number: Int,
        emoji: String,
        keywordsUpright: [String] = [],
        keywordsReversed: [String] = [],
        meaningUpright: String,
        meaningReversed: String
    ) {
        self.id = id
        self.nameVi = nameVi
        self.nameEn = nameEn
        self.number = number
        self.emoji = emoji
        self.keywordsUpright = keywordsUpright
        self.keywordsReversed = keywordsReversed
        self.meaningUpright = meaningUpright
        self.meaningReversed = meaningReversed
    }
}

public nonisolated struct TarotPosition: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var nameVi: String
    public var descVi: String

    public init(id: String, nameVi: String, descVi: String) {
        self.id = id
        self.nameVi = nameVi
        self.descVi = descVi
    }
}

public nonisolated struct DrawnTarotCard: Identifiable, Codable, Equatable, Sendable {
    /// ID ổn định của slot trong một trải bài. Mỗi `TarotPosition.id` là duy nhất
    /// trong catalog bốn spread, nên không phụ thuộc vào lá được rút ngẫu nhiên.
    public var id: String { position.id }

    public var card: TarotCard
    public var isReversed: Bool
    public var position: TarotPosition

    public init(card: TarotCard, isReversed: Bool, position: TarotPosition) {
        self.card = card
        self.isReversed = isReversed
        self.position = position
    }
}

public nonisolated struct TarotSpread: Identifiable, Codable, Equatable, Sendable {
    public var id: TarotSpreadID
    public var nameVi: String
    public var descVi: String
    public var positions: [TarotPosition]

    public init(id: TarotSpreadID, nameVi: String, descVi: String, positions: [TarotPosition]) {
        self.id = id
        self.nameVi = nameVi
        self.descVi = descVi
        self.positions = positions
    }
}
