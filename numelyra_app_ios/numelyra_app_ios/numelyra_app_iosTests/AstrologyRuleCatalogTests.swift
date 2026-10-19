import XCTest
@testable import numelyra_app_ios

final class AstrologyRuleCatalogTests: XCTestCase {
    func testBundledCatalogHasExpectedCoverageAndValidReferences() throws {
        let catalog = try AstrologyRuleCatalog.bundled()

        XCTAssertEqual(catalog.rules.count, AstrologyRuleCatalog.expectedRuleCount)
        XCTAssertEqual(catalog.validationFailures(), [])
        XCTAssertEqual(
            Dictionary(grouping: catalog.rules, by: \.kind).mapValues(\.count),
            AstrologyRuleCatalog.expectedCountsByKind
        )
    }

    func testHousePlacementRulesRequireReliableNatalContext() throws {
        let catalog = try AstrologyRuleCatalog.bundled()
        let houseRules = catalog.rules.filter { $0.kind == .planetHouse || $0.kind == .transitHouse }

        XCTAssertEqual(houseRules.count, 240)
        XCTAssertTrue(houseRules.allSatisfy(\.requiresNatalContext))
        XCTAssertTrue(
            catalog.rules
                .filter { $0.kind != .planetHouse && $0.kind != .transitHouse }
                .allSatisfy { !$0.requiresNatalContext }
        )
    }

    func testValidatorRejectsMissingContentReference() throws {
        var catalog = try AstrologyRuleCatalog.bundled()
        catalog.rules[0].contentRefs[0] = "content.reference.missing"

        XCTAssertTrue(catalog.validationFailures().contains { $0.contains("contentRefs") })
    }

    func testValidatorRejectsMissingTemplateBinding() throws {
        var catalog = try AstrologyRuleCatalog.bundled()
        catalog.rules[0].templateBindings.removeAll()

        XCTAssertTrue(catalog.validationFailures().contains { $0.contains("templateBindings") })
    }

    func testValidatorRejectsThresholdThatDoesNotMatchTemperamentState() throws {
        var catalog = try AstrologyRuleCatalog.bundled()
        let index = try XCTUnwrap(catalog.rules.firstIndex { $0.ruleId == "temperament.element.fire.high" })
        catalog.rules[index].conditions["threshold"] = .number(0.1)

        XCTAssertTrue(catalog.validationFailures().contains { $0.contains("domain, kind hoặc conditions") })
    }

    func testValidatorTracksProvenanceForEveryContentFragment() throws {
        var catalog = try AstrologyRuleCatalog.bundled()
        catalog.contentProvenance.removeValue(forKey: "planet.Sun.core")

        XCTAssertTrue(catalog.validationFailures().contains { $0.contains("contentProvenance") })
    }

    func testValidatorReportsDuplicateSourceWithoutCrashing() throws {
        var catalog = try AstrologyRuleCatalog.bundled()
        catalog.sourceReferences.append(try XCTUnwrap(catalog.sourceReferences.first))

        XCTAssertTrue(catalog.validationFailures().contains { $0.contains("sourceId bị trùng") })
    }

    func testValidatorRejectsOutOfRangeHouseWithoutIntegerOverflow() throws {
        var catalog = try AstrologyRuleCatalog.bundled()
        let index = try XCTUnwrap(catalog.rules.firstIndex { $0.ruleId == "placement.planet.Sun.house.1" })
        catalog.rules[index].conditions["house"] = .number(1e100)

        XCTAssertTrue(catalog.validationFailures().contains { $0.contains("domain, kind hoặc conditions") })
    }

    func testEvaluatorCombinesNatalSignAndHouseIntoOnePlanetTopic() throws {
        let catalog = try AstrologyRuleCatalog.bundled()
        let evaluator = try AstrologyRuleEvaluator(catalog: catalog)
        let withoutReliableContext = evaluator.evaluate(
            AstrologyRuleFacts(natalSigns: ["Sun": "Aries"], natalHouses: ["Sun": 5])
        )
        XCTAssertEqual(withoutReliableContext.matches.map(\.ruleIds), [["placement.planet.Sun.sign.Aries"]])

        let withReliableContext = evaluator.evaluate(
            AstrologyRuleFacts(
                natalSigns: ["Sun": "Aries"],
                natalHouses: ["Sun": 5],
                hasReliableNatalContext: true
            )
        )
        let topic = try XCTUnwrap(withReliableContext.topTopics.first)
        XCTAssertEqual(withReliableContext.topTopics.count, 1)
        XCTAssertEqual(topic.id, "natal.planet.Sun")
        XCTAssertEqual(Set(topic.matchedRuleIds), ["placement.planet.Sun.sign.Aries", "placement.planet.Sun.house.5"])
        XCTAssertTrue(topic.payload.experience.contains("sắc thái"))
        XCTAssertTrue(topic.payload.experience.contains("lĩnh vực"))
    }

    func testEvaluatorCombinesTransitNatalPairWithAspectModifierAndOrbWeight() throws {
        let catalog = try AstrologyRuleCatalog.bundled()
        let evaluator = try AstrologyRuleEvaluator(catalog: catalog)
        let aspect = DetectedAstroAspect(
            transitPlanet: "Mars",
            natalPlanet: "Moon",
            type: .square,
            symbol: "□",
            nameVi: "Vuông góc",
            targetAngle: 90,
            actualAngle: 93,
            orb: 3,
            weight: 0.63,
            nature: .tension
        )

        let result = evaluator.evaluate(AstrologyRuleFacts(aspects: [aspect]))
        let match = try XCTUnwrap(result.matches.first)
        XCTAssertEqual(match.ruleIds, ["aspect.pair.transit.Mars.natal.Moon", "aspect.modifier.square"])
        XCTAssertEqual(match.score, 0.63, accuracy: 0.000_001)
        XCTAssertTrue(match.payload.experience.contains("ma sát cần điều chỉnh"))
        XCTAssertTrue(match.payload.advice.contains("chia vấn đề"))
        XCTAssertEqual(result.topTopics.first?.id, "transit_natal.Mars.Moon")
    }

    func testEvaluatorReturnsAtMostThreeDistinctTopics() throws {
        let catalog = try AstrologyRuleCatalog.bundled()
        let evaluator = try AstrologyRuleEvaluator(catalog: catalog)
        let result = evaluator.evaluate(AstrologyRuleFacts(natalSigns: [
            "Sun": "Aries", "Moon": "Taurus", "Mercury": "Gemini", "Venus": "Cancer",
        ]))

        XCTAssertEqual(result.topTopics.count, 3)
        XCTAssertEqual(Set(result.topTopics.map(\.id)).count, 3)
    }

    func testMalformedCatalogJSONIsRejected() {
        XCTAssertThrowsError(try AstrologyRuleCatalog(data: Data("{}".utf8))) { error in
            XCTAssertEqual(error as? AstrologyRuleCatalogError, .malformedJSON)
        }
    }
}
