import ComposableArchitecture
import Foundation
import XCTest
@testable import numelyra_app_ios

final class NumerologyRepresentativeServiceTests: XCTestCase {
    private var databasePath: String {
        let sourceURL = URL(fileURLWithPath: #filePath)
        let repoRoot = sourceURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return repoRoot
            .appendingPathComponent("numelyra_app_ios/numelyra_app_ios/numelyra_app_ios/Resources/cadao.db")
            .path
    }

    func testBundledDatabaseContainsRepresentativeCatalog() throws {
        XCTAssertEqual(try NumerologyRepresentativeService.count(customDBPath: databasePath), 1_636)
    }

    func testLookupPrefersExactThreeThenFallsBackToCoreTwoAndLifePath() throws {
        let exact = try NumerologyRepresentativeService.representative(
            matching: .init(lifePath: 6, expression: 5, soulUrge: 4),
            customDBPath: databasePath
        )
        XCTAssertEqual(exact?.displayName, "XXXTentacion")
        XCTAssertEqual(exact?.matchType, .exactThree)

        let core = try NumerologyRepresentativeService.representative(
            matching: .init(lifePath: 6, expression: 5, soulUrge: 99),
            customDBPath: databasePath
        )
        XCTAssertEqual(core?.matchType, .coreTwo)

        let lifePath = try NumerologyRepresentativeService.representative(
            matching: .init(lifePath: 10, expression: 99, soulUrge: 99),
            customDBPath: databasePath
        )
        XCTAssertEqual(lifePath?.lifePath, 1)
        XCTAssertEqual(lifePath?.matchType, .lifePathOne)
    }

    func testSummaryMatchesReactNativeSpecialAndMasterFallbacks() throws {
        let karmicDefinition = try XCTUnwrap(NumerologyCardCatalog.definition(for: .karmicDebts))
        let karmic = CalculatedNumerologyIndicator(
            definition: karmicDefinition,
            value: .text("13/4"),
            displayValue: "13/4"
        )
        XCTAssertTrue(NumerologySummaryService.summary(for: karmic).contains("Nợ nghiệp 13/4"))

        let lifeDefinition = try XCTUnwrap(NumerologyCardCatalog.definition(for: .walksOfLife))
        let master = CalculatedNumerologyIndicator(
            definition: lifeDefinition,
            value: .number(11),
            displayValue: "11/2",
            isMaster: true
        )
        XCTAssertTrue(NumerologySummaryService.summary(for: master).contains("Bậc thầy trực giác tâm linh"))
    }

    func testKnowledgeLookupFallsBackToOfflineArchetypeWhenNoCatalogRowMatches() {
        let reading = NumerologyKnowledgeService.getIndicatorReading(
            indicatorKey: "unknown-indicator",
            indicatorValue: "7",
            cardNameVi: "Chỉ số thử nghiệm",
            customDBPath: databasePath
        )

        XCTAssertEqual(reading.source, .offlineArchetype)
        XCTAssertFalse(reading.overview.isEmpty)
        XCTAssertFalse(reading.advice.isEmpty)
    }
}

@MainActor
final class HistoricalFigureFeatureTests: XCTestCase {
    private let triple = RepresentativeTriple(lifePath: 6, expression: 5, soulUrge: 4)

    private var sample: NumerologyRepresentative {
        NumerologyRepresentative(
            id: 1,
            lifePath: 6,
            expression: 5,
            soulUrge: 4,
            nameUsed: "XXXTENTACION",
            displayName: "XXXTentacion",
            displayNameVi: "XXXTentacion",
            birthDate: "1998-01-23",
            deathDate: "2018-06-18",
            wikidataURL: "https://www.wikidata.org/wiki/Q27513309",
            wikipediaURL: "https://en.wikipedia.org/wiki/XXXTentacion",
            sitelinks: 80,
            biographyVi: String(repeating: "Tiểu sử ", count: 50),
            biographyEn: "English biography",
            matchType: .exactThree
        )
    }

    func testLookupSuccessLanguageBiographyAndShareState() async {
        let sample = sample
        let store = TestStore(initialState: HistoricalFigureFeature.State(triple: triple)) {
            HistoricalFigureFeature()
        } withDependencies: {
            $0.numerologyRepresentativeClient.findByTriple = { _ in sample }
            $0.hapticClient = .testValue
        }

        await store.send(.onAppear)
        await store.receive(.lookupResponse(.success(sample))) {
            $0.figure = sample
            $0.phase = .loaded
        }
        await store.send(.languageSelected(.english)) {
            $0.language = .english
            $0.isBiographyExpanded = false
        }
        XCTAssertEqual(store.state.biography, "English biography")

        await store.send(.toggleBiographyTapped) { $0.isBiographyExpanded = true }
        await store.send(.shareTapped) {
            $0.shareText = """
            ✦ Nhân vật đồng điệu Thần số học với tôi: XXXTentacion (1998 – 2018)
            Bộ 3 số cốt lõi: Đường đời 6 · Sứ mệnh 5 · Linh hồn 4.
            Khám phá hành trình cùng Numelyra!
            """
        }
        await store.send(.shareDismissed) { $0.shareText = nil }
    }

    func testLookupEmptyAndFailureStates() async {
        let emptyStore = TestStore(initialState: HistoricalFigureFeature.State(triple: triple)) {
            HistoricalFigureFeature()
        } withDependencies: {
            $0.numerologyRepresentativeClient.findByTriple = { _ in nil }
        }
        await emptyStore.send(.onAppear)
        await emptyStore.receive(.lookupResponse(.success(nil))) { $0.phase = .empty }

        let failedStore = TestStore(initialState: HistoricalFigureFeature.State(triple: triple)) {
            HistoricalFigureFeature()
        } withDependencies: {
            $0.numerologyRepresentativeClient.findByTriple = { _ in
                throw RepresentativeLookupError.databaseUnavailable
            }
        }
        await failedStore.send(.onAppear)
        await failedStore.receive(.lookupResponse(.failure(.databaseUnavailable))) {
            $0.phase = .failed(RepresentativeLookupError.databaseUnavailable.messageVi)
        }
    }

    func testImageFailureKeepsLoadedFigureAndUsesPlaceholderState() async {
        var figure = sample
        figure.imageURL = "https://example.com/portrait.jpg"
        let expectedFigure = figure
        let store = TestStore(initialState: HistoricalFigureFeature.State(triple: triple)) {
            HistoricalFigureFeature()
        } withDependencies: {
            $0.numerologyRepresentativeClient.findByTriple = { _ in expectedFigure }
            $0.numerologyRepresentativeClient.loadImage = { _ in
                throw RepresentativeLookupError.invalidImageResponse
            }
        }

        await store.send(.onAppear)
        await store.receive(.lookupResponse(.success(expectedFigure))) {
            $0.figure = expectedFigure
            $0.phase = .loaded
            $0.isImageLoading = true
        }
        await store.receive(.imageResponse(.failure(.invalidImageResponse))) {
            $0.isImageLoading = false
        }
        XCTAssertEqual(store.state.phase, .loaded)
        XCTAssertNil(store.state.imageData)
    }
}
