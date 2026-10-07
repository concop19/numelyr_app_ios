import Foundation

public nonisolated enum TarotDeckError: Error, Equatable, Sendable {
    case resourceNotFound
    case unreadableResource
    case malformedJSON
    case invalidCardCount(expected: Int, actual: Int)
    case duplicateCardIDs([String])
    case invalidCardField(cardID: String, field: String)
}

extension TarotDeckError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .resourceNotFound:
            return "Không tìm thấy TarotDeck.json trong app bundle."
        case .unreadableResource:
            return "Không thể đọc TarotDeck.json."
        case .malformedJSON:
            return "TarotDeck.json không đúng schema TarotCard."
        case let .invalidCardCount(expected, actual):
            return "Bộ Tarot phải có đúng \(expected) lá, hiện có \(actual) lá."
        case let .duplicateCardIDs(ids):
            return "Bộ Tarot có ID trùng: \(ids.joined(separator: ", "))."
        case let .invalidCardField(cardID, field):
            return "Lá Tarot '\(cardID)' có trường '\(field)' không hợp lệ."
        }
    }
}

/// Bộ máy Tarot thuần dữ liệu. Engine chỉ hoạt động sau khi deck 78 lá đã được
/// decode và validate, đồng thời nhận RNG từ bên ngoài để test deterministic.
public nonisolated struct TarotEngine: Sendable {
    public static let expectedCardCount = 78
    public static let reversedThreshold: Double = 0.65

    public let deck: [TarotCard]
    private let cardsByID: [String: TarotCard]

    public init(cards: [TarotCard]) throws {
        try Self.validate(cards)
        deck = cards
        cardsByID = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })
    }

    public init(data: Data, decoder: JSONDecoder = JSONDecoder()) throws {
        let cards: [TarotCard]
        do {
            cards = try decoder.decode([TarotCard].self, from: data)
        } catch {
            throw TarotDeckError.malformedJSON
        }
        try self.init(cards: cards)
    }

    /// Load resource được Xcode copy vào bundle. Thử cả đường dẫn phẳng và
    /// đường dẫn giữ nguyên hierarchy để tương thích build-system configuration.
    public static func bundled(in bundle: Bundle = .main) throws -> Self {
        let url = bundle.url(forResource: "TarotDeck", withExtension: "json")
            ?? bundle.url(forResource: "TarotDeck", withExtension: "json", subdirectory: "Resources")
            ?? bundle.url(forResource: "TarotDeck", withExtension: "json", subdirectory: "Shared/Resources")

        guard let url else {
            throw TarotDeckError.resourceNotFound
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw TarotDeckError.unreadableResource
        }
        return try Self(data: data)
    }

    public func card(id: String) -> TarotCard? {
        cardsByID[Self.normalizedID(id)]
    }

    public func drawCardsForSpread(_ spreadId: TarotSpreadID?) -> [DrawnTarotCard] {
        var generator = SystemRandomNumberGenerator()
        return drawCardsForSpread(spreadId, using: &generator)
    }

    public func drawCardsForSpread(rawSpreadId: String?) -> [DrawnTarotCard] {
        var generator = SystemRandomNumberGenerator()
        let spreadId = rawSpreadId.flatMap(TarotSpreadID.init(rawValue:))
        return drawCardsForSpread(spreadId, using: &generator)
    }

    public func drawCardsForSpread<G: RandomNumberGenerator>(
        _ spreadId: TarotSpreadID?,
        using generator: inout G
    ) -> [DrawnTarotCard] {
        let spread = TarotCatalog.spread(for: spreadId)
        var shuffled = deck

        // Fisher–Yates: sau shuffle, lấy N lá đầu nên không thể trùng lá.
        for index in stride(from: shuffled.count - 1, through: 1, by: -1) {
            let swapIndex = Int.random(in: 0...index, using: &generator)
            if index != swapIndex {
                shuffled.swapAt(index, swapIndex)
            }
        }

        return spread.positions.enumerated().map { index, position in
            DrawnTarotCard(
                card: shuffled[index],
                isReversed: Double.random(in: 0.0..<1.0, using: &generator) > Self.reversedThreshold,
                position: position
            )
        }
    }

    public static func validate(_ cards: [TarotCard]) throws {
        guard cards.count == expectedCardCount else {
            throw TarotDeckError.invalidCardCount(expected: expectedCardCount, actual: cards.count)
        }

        let normalizedIDs = cards.map { normalizedID($0.id) }
        let duplicates = Dictionary(grouping: normalizedIDs, by: { $0 })
            .filter { !$0.key.isEmpty && $0.value.count > 1 }
            .map(\.key)
            .sorted()
        guard duplicates.isEmpty else {
            throw TarotDeckError.duplicateCardIDs(duplicates)
        }

        for card in cards {
            let normalizedID = normalizedID(card.id)
            try require(!normalizedID.isEmpty && normalizedID == card.id, cardID: card.id, field: "id")
            try require(!trimmed(card.nameVi).isEmpty, cardID: card.id, field: "nameVi")
            try require(!trimmed(card.nameEn).isEmpty, cardID: card.id, field: "nameEn")
            try require(!trimmed(card.emoji).isEmpty, cardID: card.id, field: "emoji")
            try require(!card.keywordsUpright.isEmpty, cardID: card.id, field: "keywordsUpright")
            try require(!card.keywordsReversed.isEmpty, cardID: card.id, field: "keywordsReversed")
            try require(!trimmed(card.meaningUpright).isEmpty, cardID: card.id, field: "meaningUpright")
            try require(!trimmed(card.meaningReversed).isEmpty, cardID: card.id, field: "meaningReversed")
        }
    }

    private static func require(_ condition: Bool, cardID: String, field: String) throws {
        guard condition else {
            throw TarotDeckError.invalidCardField(cardID: cardID, field: field)
        }
    }

    private static func normalizedID(_ id: String) -> String {
        trimmed(id).lowercased()
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
