import ComposableArchitecture
import Foundation
import XCTest
@testable import numelyra_app_ios

final class AstrologyServiceTests: XCTestCase {
    func testResolveBirthDateUsesNoonUTCWhenTimeIsMissing() throws {
        let resolved = try AstrologyEngine.resolveBirthDate("1998-10-20")
        let components = utcCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: resolved.date
        )

        XCTAssertTrue(resolved.isTimeEstimated)
        XCTAssertEqual(components.year, 1998)
        XCTAssertEqual(components.month, 10)
        XCTAssertEqual(components.day, 20)
        XCTAssertEqual(components.hour, 12)
        XCTAssertEqual(components.minute, 0)
    }

    func testResolveBirthDateUsesExactTime() throws {
        let resolved = try AstrologyEngine.resolveBirthDate("20/10/1998", birthTime: "14:35")
        let components = utcCalendar.dateComponents([.hour, .minute], from: resolved.date)

        XCTAssertFalse(resolved.isTimeEstimated)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 35)
        XCTAssertEqual(resolved.precision, .timeWithoutLocation)
    }

    func testVectorMatchesBaselineInvariants() throws {
        let currentDate = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-04T12:00:00Z"))
        let first = try AstrologyEngine.generateVector(
            input: AstroBirthInput(birthDate: "1995-03-21"),
            currentDate: currentDate
        )
        let second = try AstrologyEngine.generateVector(
            input: AstroBirthInput(birthDate: "1995-03-21"),
            currentDate: currentDate
        )

        XCTAssertEqual(first.vector.count, 32)
        XCTAssertTrue(first.vector.allSatisfy { $0.isFinite && (0 ... 1).contains($0) })
        XCTAssertEqual(first.vector[0], 0.7)
        XCTAssertFalse(first.metadata.hasExactTime)
        XCTAssertEqual(first.metadata.natalSunSign, "Aries")
        XCTAssertEqual(first, second)
    }

    func testAspectScoresUseTransitPlanetActivity() {
        let slowTransit = AstrologyEngine.calculateAspectScores([
            aspect(transit: "Uranus", natal: "Moon", nature: .tension, type: .square),
        ])
        let fastTransit = AstrologyEngine.calculateAspectScores([
            aspect(transit: "Moon", natal: "Uranus", nature: .tension, type: .square),
        ])

        XCTAssertEqual(slowTransit.fastPlanetActivity, 0)
        XCTAssertEqual(fastTransit.fastPlanetActivity, 1)
        XCTAssertEqual(AstrologyEngine.shortestAngleDifference(10, 350), 20)
        XCTAssertEqual(AstrologyEngine.shortestAngleDifference(0, 180), 180)
    }

    func testDominantSignalCoversAllBranches() {
        XCTAssertEqual(AstrologyEngine.dominantSignal(tension: 0.7, harmony: 0.3, conjunction: 0.1), .tension)
        XCTAssertEqual(AstrologyEngine.dominantSignal(tension: 0.3, harmony: 0.7, conjunction: 0.1), .harmony)
        XCTAssertEqual(AstrologyEngine.dominantSignal(tension: 0.6, harmony: 0.4, conjunction: 0.3), .conjunction)
        XCTAssertEqual(AstrologyEngine.dominantSignal(tension: 0.55, harmony: 0.45, conjunction: 0.1), .balanced)
    }

    func testCacheKeyPreservesReactNativeUTF16HashContract() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Ho_Chi_Minh"))
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-05T16:45:00Z"))
        let profile = UserProfile(
            fullName: "  An Nguyễn  ",
            birthDate: "1998-10-20"
        )

        XCTAssertEqual(AstrologyCacheKey.profileKey(profile), "an nguyễn|1998-10-20")
        XCTAssertEqual(
            AstrologyCacheKey.version3(date, profile: profile, calendar: calendar),
            "@astro_fortune_v3_2026-10-05_81eba188"
        )
        XCTAssertTrue(
            AstrologyCacheKey.current(date, profile: profile, calendar: calendar)
                .hasPrefix("@astro_fortune_v4_2026-10-05_")
        )
    }

    func testCorruptCacheIsIgnored() async throws {
        let suiteName = "AstrologyServiceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let date = Date(timeIntervalSince1970: 1_780_000_000)
        let profile = UserProfile(fullName: "An", birthDate: "1998-10-20")
        let key = AstrologyCacheKey.current(date, profile: profile)
        defaults.set(Data("{not-json".utf8), forKey: key)
        let cache = AstrologyFortuneCache(defaults: defaults)

        let cached = await cache.load(date: date, profile: profile)
        XCTAssertNil(cached)
    }

    func testLocalBirthTimeConvertsToUTCAndUnknownTimeSkipsHouses() throws {
        let location = birthLocation(
            placeID: "hanoi",
            latitude: 21.0278,
            longitude: 105.8342,
            timeZone: "Asia/Ho_Chi_Minh"
        )
        let exact = try AstrologyEngine.resolveBirthDate(
            "2000-01-01",
            birthTime: "12:00",
            accuracy: .exact,
            location: location
        )
        let exactComponents = utcCalendar.dateComponents([.hour, .minute], from: exact.date)
        XCTAssertEqual(exactComponents.hour, 5)
        XCTAssertEqual(exactComponents.minute, 0)
        XCTAssertEqual(exact.precision, .complete)

        let unknownInput = AstroBirthInput(
            birthDate: "2000-01-01",
            birthTime: nil,
            birthTimeAccuracy: .unknown,
            resolvedBirthLocation: location
        )
        let snapshot = try AstrologyEngine.makeNatalSnapshot(input: unknownInput, fingerprint: "unknown")
        XCTAssertTrue(snapshot.chart.isTimeEstimated)
        XCTAssertNil(snapshot.context)
    }

    func testDSTNonexistentTimeFailsAndRepeatedTimeIsMarkedAmbiguous() throws {
        let newYork = birthLocation(
            placeID: "new-york",
            latitude: 40.7128,
            longitude: -74.006,
            timeZone: "America/New_York"
        )
        XCTAssertThrowsError(
            try AstrologyEngine.resolveBirthDate(
                "2024-03-10",
                birthTime: "02:30",
                accuracy: .exact,
                location: newYork
            )
        ) { error in
            guard case AstrologyEngine.EngineError.nonexistentLocalTime = error else {
                return XCTFail("Expected nonexistentLocalTime, got \(error)")
            }
        }

        let repeated = try AstrologyEngine.resolveBirthDate(
            "2024-11-03",
            birthTime: "01:30",
            accuracy: .exact,
            location: newYork
        )
        XCTAssertTrue(repeated.isLocalTimeAmbiguous)
    }

    func testPorphyryGoldenFixturesMatchSwissEphemeris() throws {
        let fixtures: [(String, String, Double, Double, Double, Double, [Double])] = [
            ("Hanoi", "2000-01-01T05:00:00Z", 21.0278, 105.8342, 14.320311, 280.115466,
             [14.320311, 42.918696, 71.517081, 100.115466, 131.517081, 162.918696, 194.320311, 222.918696, 251.517081, 280.115466, 311.517081, 342.918696]),
            ("New York", "2000-01-01T17:00:00Z", 40.7128, -74.006, 19.960596, 280.717924,
             [19.960596, 46.879705, 73.798815, 100.717924, 133.798815, 166.879705, 199.960596, 226.879705, 253.798815, 280.717924, 313.798815, 346.879705]),
            ("London", "2000-01-01T12:00:00Z", 51.5074, -0.1278, 24.014590, 279.493225,
             [24.014590, 49.174135, 74.333680, 99.493225, 134.333680, 169.174135, 204.014590, 229.174135, 254.333680, 279.493225, 314.333680, 349.174135]),
            ("Reykjavik", "2000-01-01T12:00:00Z", 64.1466, -21.9426, 291.462632, 259.439869,
             [291.462632, 340.788378, 30.114124, 79.439869, 90.114124, 100.788378, 111.462632, 160.788378, 210.114124, 259.439869, 270.114124, 280.788378]),
        ]

        for fixture in fixtures {
            let date = try XCTUnwrap(ISO8601DateFormatter().date(from: fixture.1), fixture.0)
            let angles = AstrologyEngine.calculateAngles(
                date: date,
                latitude: fixture.2,
                longitude: fixture.3
            )
            XCTAssertEqual(angles.ascendant, fixture.4, accuracy: 0.1, fixture.0)
            XCTAssertEqual(angles.midheaven, fixture.5, accuracy: 0.1, fixture.0)
            let cusps = AstrologyEngine.calculatePorphyryCusps(angles: angles)
            XCTAssertEqual(cusps.count, 12)
            for (actual, expected) in zip(cusps.map(\.longitude), fixture.6) {
                XCTAssertEqual(actual, expected, accuracy: 0.1, fixture.0)
            }
        }
    }

    func testHouseAssignmentWrapsAtZeroAndDailyContextReturnsAtMostThree() throws {
        let cusps = (0 ..< 12).map {
            AstroHouseCusp(house: $0 + 1, longitude: Double($0 * 30))
        }
        XCTAssertEqual(AstrologyEngine.house(for: 0, cusps: cusps), 1)
        XCTAssertEqual(AstrologyEngine.house(for: 29.999, cusps: cusps), 1)
        XCTAssertEqual(AstrologyEngine.house(for: 359.999, cusps: cusps), 12)

        let location = birthLocation(
            placeID: "hanoi",
            latitude: 21.0278,
            longitude: 105.8342,
            timeZone: "Asia/Ho_Chi_Minh"
        )
        let input = AstroBirthInput(
            birthDate: "2000-01-01",
            birthTime: "12:00",
            birthTimeAccuracy: .exact,
            resolvedBirthLocation: location
        )
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-06T12:00:00Z"))
        let result = try AstrologyEngine.generateVector(input: input, currentDate: date)
        XCTAssertEqual(result.vector.count, 32)
        XCTAssertEqual(result.metadata.natalContext?.houseCusps.count, 12)
        XCTAssertLessThanOrEqual(result.metadata.dailyContext?.activatedHouses.count ?? 0, 3)
    }

    func testCacheV4FingerprintChangesForTimeAndPlaceAndV3IsNotCurrent() async throws {
        let date = Date(timeIntervalSince1970: 1_780_000_000)
        let first = UserProfile(
            id: "profile",
            fullName: "An",
            birthDate: "1998-10-20",
            birthTime: "14:00",
            birthLocation: .init(placeID: "hanoi", userLabel: "Hà Nội"),
            birthTimeAccuracy: .exact
        )
        var second = first
        second.birthTime = "14:01"
        var third = first
        third.birthLocation = .init(placeID: "london", userLabel: "London")
        XCTAssertNotEqual(AstrologyCacheKey.current(date, profile: first), AstrologyCacheKey.current(date, profile: second))
        XCTAssertNotEqual(AstrologyCacheKey.current(date, profile: first), AstrologyCacheKey.current(date, profile: third))

        let suiteName = "AstrologyCacheV4Tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let legacy = AstroFortuneSlip(
            verse: "legacy",
            mirror: "legacy",
            advice: "legacy",
            anchorCaDao: .init(content: "legacy")
        )
        defaults.set(
            try JSONEncoder().encode(legacy),
            forKey: AstrologyCacheKey.version3(date, profile: first)
        )
        let cache = AstrologyFortuneCache(defaults: defaults)
        let current = await cache.load(date: date, profile: first)
        XCTAssertNil(current)
    }

    func testAdvancedRequestContainsSemanticContextButNoLocationData() throws {
        let input = AstroBirthInput(
            birthDate: "2000-01-01",
            birthTime: "12:00",
            birthTimeAccuracy: .exact,
            resolvedBirthLocation: birthLocation(
                placeID: "private-place-id",
                latitude: 21.0278,
                longitude: 105.8342,
                timeZone: "Asia/Ho_Chi_Minh"
            )
        )
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-06T12:00:00Z"))
        let metadata = try AstrologyEngine.generateVector(input: input, currentDate: date).metadata
        let request = AstrologyClient.makeRequest(
            metadata: metadata,
            anchor: .init(content: "Ca dao"),
            recentAdvice: [],
            userContext: nil
        )
        let json = try XCTUnwrap(String(data: JSONEncoder().encode(request), encoding: .utf8))
        XCTAssertTrue(json.contains("ascendantSign"))
        for forbidden in ["private-place-id", "placeID", "latitude", "longitude", "timeZone"] {
            XCTAssertFalse(json.contains(forbidden), forbidden)
        }
    }

    func testBirthPlacePickerDebouncesCancelsAndResolvesSelection() async {
        let clock = TestClock()
        let session = BirthPlaceSearchSession(id: "session")
        let hanoi = BirthPlaceSuggestion(
            placeID: "hanoi",
            primaryText: "Hà Nội",
            secondaryText: "Việt Nam"
        )
        let resolved = birthLocation(
            placeID: "hanoi",
            latitude: 21.0278,
            longitude: 105.8342,
            timeZone: "Asia/Ho_Chi_Minh"
        )
        let store = TestStore(initialState: BirthPlacePickerFeature.State()) {
            BirthPlacePickerFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.birthLocationClient = BirthLocationClient(
                makeSession: { session },
                suggestions: { query, _ in query == "Hanoi" ? [hanoi] : [] },
                resolve: { _, _ in resolved },
                refresh: { _ in resolved }
            )
        }

        await store.send(.onAppear)
        await store.receive(\.sessionCreated) { $0.session = session }
        await store.send(.queryChanged("Han")) { $0.query = "Han"; $0.isSearching = true }
        await store.send(.queryChanged("Hanoi")) { $0.query = "Hanoi" }
        await clock.advance(by: .milliseconds(300))
        await store.receive(.searchSucceeded([hanoi])) {
            $0.isSearching = false
            $0.suggestions = [hanoi]
        }
        await store.send(.suggestionTapped(hanoi)) { $0.isResolving = true }
        await store.receive(.resolveSucceeded(resolved)) { $0.isResolving = false }
        await store.receive(
            .delegate(
                .selected(
                    reference: .init(placeID: "hanoi", userLabel: "hanoi"),
                    resolved: resolved
                )
            )
        )
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func aspect(
        transit: String,
        natal: String,
        nature: AstroAspectNature,
        type: AstroAspectType,
        weight: Double = 1
    ) -> DetectedAstroAspect {
        DetectedAstroAspect(
            transitPlanet: transit,
            natalPlanet: natal,
            type: type,
            symbol: "",
            nameVi: "",
            targetAngle: 0,
            actualAngle: 0,
            orb: 0,
            weight: weight,
            nature: nature
        )
    }

    private func birthLocation(
        placeID: String,
        latitude: Double,
        longitude: Double,
        timeZone: String
    ) -> ResolvedBirthLocation {
        ResolvedBirthLocation(
            placeID: placeID,
            userLabel: placeID,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZone,
            resolvedAt: Date(timeIntervalSince1970: 0),
            expiresAt: Date.distantFuture
        )
    }
}
