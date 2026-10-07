import XCTest
@testable import numelyra_app_ios

final class ConstellationEngineTests: XCTestCase {
    func testCatalogHasThirtyUniqueSymbolsAndPreservesReactNativePrefix() {
        XCTAssertEqual(ConstellationSymbolCatalog.all.count, 30)
        XCTAssertEqual(Set(ConstellationSymbolCatalog.all.map(\.id)).count, 30)
        XCTAssertEqual(
            Array(ConstellationSymbolCatalog.all.prefix(8).map(\.id)),
            ["heart", "home", "pig", "cat", "flower", "crown", "star", "pine"]
        )
    }

    func testEveryBundledSymbolBuildsWithinStarLimit() throws {
        for symbol in ConstellationSymbolCatalog.all {
            let geometry = try ConstellationEngine.buildGeometry(for: symbol)
            XCTAssertGreaterThan(geometry.starCount, 1, symbol.id)
            XCTAssertLessThanOrEqual(geometry.starCount, 300, symbol.id)
            XCTAssertTrue(geometry.contours.allSatisfy(\.isClosed), symbol.id)
        }
    }

    func testStarOutlineKeepsItsTwoClosedContours() throws {
        let geometry = try ConstellationEngine.buildGeometry(
            for: ConstellationSymbolCatalog.symbol(id: "star")
        )
        XCTAssertEqual(geometry.contours.count, 2)
        XCTAssertTrue(geometry.contours.allSatisfy(\.isClosed))
    }

    func testDailySymbolIsStableForLocalDayAndChangesNextDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Ho_Chi_Minh"))
        let morning = try XCTUnwrap(calendar.date(from: .init(
            year: 2026, month: 10, day: 7, hour: 8
        )))
        let evening = try XCTUnwrap(calendar.date(from: .init(
            year: 2026, month: 10, day: 7, hour: 23, minute: 59
        )))
        let tomorrow = try XCTUnwrap(calendar.date(from: .init(
            year: 2026, month: 10, day: 8, hour: 0
        )))
        let profileKey = "an nguyen|1998-10-20"

        let first = ConstellationEngine.dailySymbol(
            date: morning,
            profileKey: profileKey,
            calendar: calendar
        )
        XCTAssertEqual(
            first.id,
            ConstellationEngine.dailySymbol(
                date: evening,
                profileKey: profileKey,
                calendar: calendar
            ).id
        )
        XCTAssertNotEqual(
            first.id,
            ConstellationEngine.dailySymbol(
                date: tomorrow,
                profileKey: profileKey,
                calendar: calendar
            ).id
        )
    }

    func testFitUsesAspectFitAndCentersNonZeroViewBox() {
        let source = ConstellationGeometry(
            viewBox: .init(minX: 10, minY: 20, width: 100, height: 50),
            contours: [.init(
                points: [.init(x: 10, y: 20), .init(x: 110, y: 70)],
                isClosed: false
            )]
        )
        let fitted = ConstellationEngine.fit(
            source,
            inside: .init(x: 0, y: 0, width: 200, height: 200)
        )
        XCTAssertEqual(fitted.contours[0].points[0], .init(x: 0, y: 50))
        XCTAssertEqual(fitted.contours[0].points[1], .init(x: 200, y: 150))
    }

    func testAmbientStarsAreDeterministic() {
        XCTAssertEqual(
            ConstellationEngine.ambientStars(seed: 42, count: 5),
            ConstellationEngine.ambientStars(seed: 42, count: 5)
        )
        XCTAssertNotEqual(
            ConstellationEngine.ambientStars(seed: 42, count: 5),
            ConstellationEngine.ambientStars(seed: 43, count: 5)
        )
    }

    func testInvalidPathIsRejected() {
        let symbol = ConstellationSymbolPreset(
            id: "invalid",
            title: "Invalid",
            pathData: "not-svg-path"
        )
        XCTAssertThrowsError(try ConstellationEngine.buildGeometry(for: symbol)) { error in
            XCTAssertEqual(error as? ConstellationError, .invalidPath)
        }
    }
}
