import Foundation
import XCTest
@testable import numelyra_app_ios

final class TarotCatalogTests: XCTestCase {

    func testBundledJSONContainsExactly78CardsAndMatchesBreakdown() throws {
        let engine = try TarotEngine.bundled()
        let majorArcana = engine.deck.filter { !$0.id.contains("-") || $0.id.first?.isNumber == true }
        let minorArcana = engine.deck.filter { $0.id.hasPrefix("wands-")
            || $0.id.hasPrefix("cups-")
            || $0.id.hasPrefix("swords-")
            || $0.id.hasPrefix("pentacles-") }

        XCTAssertEqual(majorArcana.count, 22, "Major Arcana must have 22 cards (0...21).")
        XCTAssertEqual(minorArcana.count, 56, "Minor Arcana must have 56 cards (4 suits × 14).")
        XCTAssertEqual(engine.deck.count, 78, "Full Tarot deck must have 78 cards.")

        let uniqueIDs = Set(engine.deck.map(\.id))
        XCTAssertEqual(uniqueIDs.count, 78, "All 78 card IDs must be unique.")

        // Check Major Arcana numbering 0...21
        let majorNumbers = majorArcana.map(\.number)
        XCTAssertEqual(majorNumbers, Array(0...21))

        // Check Minor Arcana suits (14 each)
        let wands = minorArcana.filter { $0.id.hasPrefix("wands-") }
        let cups = minorArcana.filter { $0.id.hasPrefix("cups-") }
        let swords = minorArcana.filter { $0.id.hasPrefix("swords-") }
        let pentacles = minorArcana.filter { $0.id.hasPrefix("pentacles-") }

        XCTAssertEqual(wands.count, 14)
        XCTAssertEqual(cups.count, 14)
        XCTAssertEqual(swords.count, 14)
        XCTAssertEqual(pentacles.count, 14)
    }

    func testEveryCardHasCompleteMetadataAndMapsToDedicatedAsset() throws {
        let engine = try TarotEngine.bundled()

        for card in engine.deck {
            XCTAssertFalse(card.id.isEmpty)
            XCTAssertFalse(card.nameVi.isEmpty, "Missing nameVi for \(card.id)")
            XCTAssertFalse(card.nameEn.isEmpty, "Missing nameEn for \(card.id)")
            XCTAssertFalse(card.emoji.isEmpty, "Missing emoji for \(card.id)")
            XCTAssertFalse(card.keywordsUpright.isEmpty, "Missing upright keywords for \(card.id)")
            XCTAssertFalse(card.keywordsReversed.isEmpty, "Missing reversed keywords for \(card.id)")
            XCTAssertFalse(card.meaningUpright.isEmpty, "Missing upright meaning for \(card.id)")
            XCTAssertFalse(card.meaningReversed.isEmpty, "Missing reversed meaning for \(card.id)")

            let asset = AppAsset.tarotCard(id: card.id)
            XCTAssertNotEqual(
                asset,
                .tarotCardBack,
                "Card '\(card.id)' fell back to tarotCardBack instead of its dedicated asset!"
            )

            XCTAssertEqual(engine.card(id: card.id), card)
            XCTAssertEqual(engine.card(id: "  \(card.id.uppercased())  "), card)
        }
    }

    func testFourSpreadsMatchReactNativeConfiguration() {
        XCTAssertEqual(TarotCatalog.allSpreads.count, 4)
        XCTAssertEqual(TarotCatalog.spreads.count, 4)

        let single = TarotCatalog.spread(for: .single)
        XCTAssertEqual(single.positions.count, 1)
        XCTAssertEqual(single.positions.map(\.id), ["single-1"])

        let threeCard = TarotCatalog.spread(for: .threeCard)
        XCTAssertEqual(threeCard.positions.count, 3)
        XCTAssertEqual(threeCard.positions.map(\.id), ["pos-1", "pos-2", "pos-3"])

        let twoOptions = TarotCatalog.spread(for: .twoOptions)
        XCTAssertEqual(twoOptions.positions.count, 5)
        XCTAssertEqual(twoOptions.positions.map(\.id), ["opt-1", "opt-2", "opt-3", "opt-4", "opt-5"])

        let relationship = TarotCatalog.spread(for: .relationship)
        XCTAssertEqual(relationship.positions.count, 5)
        XCTAssertEqual(relationship.positions.map(\.id), ["rel-1", "rel-2", "rel-3", "rel-4", "rel-5"])

        // Fallback when nil or unknown rawId
        XCTAssertEqual(TarotCatalog.spread(for: nil), single)
        XCTAssertEqual(TarotCatalog.spread(rawId: "unknown-spread"), single)
    }

    func testDrawCardsForSpreadReturnsDistinctCardsForEachPosition() throws {
        let engine = try TarotEngine.bundled()

        for spreadId in TarotSpreadID.allCases {
            let expectedSpread = TarotCatalog.spread(for: spreadId)
            let drawn = engine.drawCardsForSpread(spreadId)

            XCTAssertEqual(drawn.count, expectedSpread.positions.count)
            XCTAssertEqual(drawn.map(\.position), expectedSpread.positions)

            let drawnCardIDs = Set(drawn.map(\.card.id))
            XCTAssertEqual(
                drawnCardIDs.count,
                drawn.count,
                "Drawn cards within a single spread must not contain duplicates."
            )
        }
    }

    func testInjectedRNGMakesDrawDeterministic() throws {
        let engine = try TarotEngine.bundled()
        var firstGenerator = SeededGenerator(seed: 0xCAFE_BABE)
        var secondGenerator = SeededGenerator(seed: 0xCAFE_BABE)

        let first = engine.drawCardsForSpread(.relationship, using: &firstGenerator)
        let second = engine.drawCardsForSpread(.relationship, using: &secondGenerator)

        XCTAssertEqual(first, second)
    }

    func testRejectsWrongCardCountAndDuplicateNormalizedIDs() throws {
        let validEngine = try TarotEngine.bundled()

        XCTAssertThrowsError(try TarotEngine(cards: Array(validEngine.deck.dropLast()))) { error in
            XCTAssertEqual(
                error as? TarotDeckError,
                .invalidCardCount(expected: 78, actual: 77)
            )
        }

        var duplicated = validEngine.deck
        duplicated[77].id = duplicated[0].id.uppercased()
        XCTAssertThrowsError(try TarotEngine(cards: duplicated)) { error in
            XCTAssertEqual(error as? TarotDeckError, .duplicateCardIDs([validEngine.deck[0].id]))
        }
    }

    func testRejectsMalformedJSONAndIncompleteMetadata() throws {
        XCTAssertThrowsError(try TarotEngine(data: Data("{}".utf8))) { error in
            XCTAssertEqual(error as? TarotDeckError, .malformedJSON)
        }

        let validEngine = try TarotEngine.bundled()
        var invalidCards = validEngine.deck
        invalidCards[0].meaningUpright = "   "
        XCTAssertThrowsError(try TarotEngine(cards: invalidCards)) { error in
            XCTAssertEqual(
                error as? TarotDeckError,
                .invalidCardField(cardID: validEngine.deck[0].id, field: "meaningUpright")
            )
        }
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}
