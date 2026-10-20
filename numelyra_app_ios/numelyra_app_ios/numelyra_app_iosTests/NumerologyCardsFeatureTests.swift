import ComposableArchitecture
import Foundation
import XCTest
@testable import numelyra_app_ios

@MainActor
final class NumerologyCardsFeatureTests: XCTestCase {
    private var referenceDate: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        return calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 12))!
    }

    func testOnAppearWithActiveProfileCalculatesAll24Cards() async {
        let profile = UserProfile(
            id: "active-1",
            fullName: "Nguyễn Văn An",
            birthDate: "1998-10-20",
            gender: .male,
            isDefault: true
        )
        let expectedCards = NumerologyEngine.calculate24Cards(
            fullName: profile.fullName,
            birthDate: profile.birthDate,
            referenceDate: referenceDate
        )

        let store = TestStore(
            initialState: NumerologyCardsFeature.State(activeProfile: profile)
        ) {
            NumerologyCardsFeature()
        } withDependencies: {
            $0.date.now = referenceDate
            $0.numerologyClient = .liveValue
            $0.hapticClient = .testValue
        }

        await store.send(.onAppear) {
            $0.indicators = expectedCards
        }

        XCTAssertEqual(store.state.indicators.count, 24)
        XCTAssertEqual(store.state.filteredIndicators.count, 24)
        XCTAssertEqual(store.state.displayFullName, "Nguyễn Văn An")
        XCTAssertEqual(store.state.displayBirthDate, "1998-10-20")
        XCTAssertEqual(store.state.indicators.first?.definition.number, "01")
        XCTAssertEqual(store.state.indicators.last?.definition.number, "24")
    }

    func testOnAppearWithoutInputProfileLoadsActiveProfileFromClient() async {
        let storedProfile = UserProfile(
            id: "stored-active",
            fullName: "Trần Thị Minh Châu",
            birthDate: "1995-05-15",
            gender: .female,
            isDefault: true
        )
        let expectedCards = NumerologyEngine.calculate24Cards(
            fullName: storedProfile.fullName,
            birthDate: storedProfile.birthDate,
            referenceDate: referenceDate
        )

        let store = TestStore(
            initialState: NumerologyCardsFeature.State(activeProfile: nil)
        ) {
            NumerologyCardsFeature()
        } withDependencies: {
            $0.date.now = referenceDate
            $0.userProfileClient.activeProfile = { storedProfile }
            $0.numerologyClient = .liveValue
            $0.hapticClient = .testValue
        }

        await store.send(.onAppear) {
            $0.activeProfile = storedProfile
            $0.indicators = expectedCards
        }
    }

    func testOnAppearWithoutAnyProfileShowsEmptyStateInsteadOfCalculatingFallbackCards() async {
        let store = TestStore(initialState: NumerologyCardsFeature.State()) {
            NumerologyCardsFeature()
        } withDependencies: {
            $0.userProfileClient.activeProfile = { nil }
            $0.hapticClient = .testValue
        }

        await store.send(.onAppear)
        XCTAssertTrue(store.state.indicators.isEmpty)
        XCTAssertNil(store.state.currentIndicator)
        XCTAssertNil(store.state.representativeTriple)
    }

    func testActiveProfileChangeRecalculatesCardsAndClearsWhenProfileIsRemoved() async {
        let firstProfile = UserProfile(fullName: "Nguyễn Văn An", birthDate: "1998-10-20")
        let changedProfile = UserProfile(fullName: "Trần Minh Châu", birthDate: "1995-05-15")
        let firstCards = NumerologyEngine.calculate24Cards(
            fullName: firstProfile.fullName,
            birthDate: firstProfile.birthDate,
            referenceDate: referenceDate
        )
        let changedCards = NumerologyEngine.calculate24Cards(
            fullName: changedProfile.fullName,
            birthDate: changedProfile.birthDate,
            referenceDate: referenceDate
        )
        let store = TestStore(
            initialState: NumerologyCardsFeature.State(
                activeProfile: firstProfile,
                indicators: firstCards,
                activeIndex: 23
            )
        ) {
            NumerologyCardsFeature()
        } withDependencies: {
            $0.date.now = referenceDate
            $0.numerologyClient = .liveValue
        }

        await store.send(.activeProfileUpdated(changedProfile)) {
            $0.activeProfile = changedProfile
            $0.indicators = changedCards
        }
        XCTAssertNotEqual(firstCards, store.state.indicators)
        XCTAssertEqual(store.state.activeIndex, 23)

        await store.send(.activeProfileUpdated(nil)) {
            $0.activeProfile = nil
            $0.indicators = []
            $0.activeIndex = 0
        }
        XCTAssertNil(store.state.representativeTriple)
    }

    func testCategorySelectionFiltersCardsAndFiresSelectionHapticOnlyOnChange() async {
        let profile = UserProfile(fullName: "Nguyễn Văn An", birthDate: "1998-10-20")
        let cards = NumerologyEngine.calculate24Cards(
            fullName: profile.fullName,
            birthDate: profile.birthDate,
            referenceDate: referenceDate
        )
        let selectionHapticCount = LockIsolated(0)

        let store = TestStore(
            initialState: NumerologyCardsFeature.State(
                activeProfile: profile,
                indicators: cards,
                activeIndex: 4
            )
        ) {
            NumerologyCardsFeature()
        } withDependencies: {
            $0.hapticClient.selection = {
                selectionHapticCount.withValue { $0 += 1 }
            }
        }

        await store.send(.categorySelected(.category(.core))) {
            $0.selectedCategory = .category(.core)
            $0.activeIndex = 0
        }
        XCTAssertEqual(store.state.filteredIndicators.count, 5)
        XCTAssertEqual(selectionHapticCount.value, 1)

        // Selecting the same category again does not fire selection haptic
        await store.send(.categorySelected(.category(.core)))
        XCTAssertEqual(selectionHapticCount.value, 1)

        await store.send(.categorySelected(.category(.potential))) {
            $0.selectedCategory = .category(.potential)
        }
        XCTAssertEqual(store.state.filteredIndicators.count, 6)
        XCTAssertEqual(selectionHapticCount.value, 2)

        await store.send(.categorySelected(.category(.karmic))) {
            $0.selectedCategory = .category(.karmic)
        }
        XCTAssertEqual(store.state.filteredIndicators.count, 2)

        await store.send(.categorySelected(.category(.bridge))) {
            $0.selectedCategory = .category(.bridge)
        }
        XCTAssertEqual(store.state.filteredIndicators.count, 3)

        await store.send(.categorySelected(.category(.cycle))) {
            $0.selectedCategory = .category(.cycle)
        }
        XCTAssertEqual(store.state.filteredIndicators.count, 5)

        await store.send(.categorySelected(.category(.chart))) {
            $0.selectedCategory = .category(.chart)
        }
        XCTAssertEqual(store.state.filteredIndicators.count, 3)

        await store.send(.categorySelected(.all)) {
            $0.selectedCategory = .all
        }
        XCTAssertEqual(store.state.filteredIndicators.count, 24)
    }

    func testCardTapPresentsDetailAndLoadsReading() async {
        let profile = UserProfile(fullName: "Nguyễn Văn An", birthDate: "1998-10-20")
        let cards = NumerologyEngine.calculate24Cards(
            fullName: profile.fullName,
            birthDate: profile.birthDate,
            referenceDate: referenceDate
        )
        let firstCard = cards[0]
        let lightImpactCount = LockIsolated(0)
        let sampleReading = KnowledgeReading(
            title: "Số Đường Đời 3",
            source: .supabase,
            overview: "Tổng quan năng lượng số 3.",
            strengths: ["Sáng tạo", "Lạc quan"],
            challenges: ["Phân tán"],
            advice: "Tập trung kỷ luật.",
            fullContent: String(repeating: "Nội dung chi tiết ", count: 25)
        )

        let store = TestStore(
            initialState: NumerologyCardsFeature.State(
                activeProfile: profile,
                indicators: cards
            )
        ) {
            NumerologyCardsFeature()
        } withDependencies: {
            $0.hapticClient.lightImpact = {
                lightImpactCount.withValue { $0 += 1 }
            }
            $0.hapticClient.selection = {}
            $0.numerologyClient.indicatorReading = { _, _, _ in sampleReading }
        }

        await store.send(.cardTapped(index: 0, indicator: firstCard)) {
            $0.detail = IndicatorDetailFeature.State(indicator: firstCard)
        }
        XCTAssertEqual(lightImpactCount.value, 1)

        await store.send(.detail(.presented(.onAppear))) {
            $0.detail?.isLoading = true
        }
        await store.receive(.detail(.presented(.readingLoaded(sampleReading)))) {
            $0.detail?.isLoading = false
            $0.detail?.reading = sampleReading
        }

        XCTAssertEqual(store.state.detail?.canExpandFullArticle, true)

        await store.send(.detail(.presented(.toggleFullArticleTapped))) {
            $0.detail?.isFullArticleExpanded = true
        }
        await store.send(.detail(.presented(.toggleFullArticleTapped))) {
            $0.detail?.isFullArticleExpanded = false
        }
    }

    func testInactiveCardCentersBeforeSecondTapOpensDetail() async {
        let cards = NumerologyEngine.calculate24Cards(
            fullName: "Nguyễn Văn An",
            birthDate: "1998-10-20",
            referenceDate: referenceDate
        )
        let selectionCount = LockIsolated(0)
        let impactCount = LockIsolated(0)
        let store = TestStore(
            initialState: NumerologyCardsFeature.State(indicators: cards)
        ) {
            NumerologyCardsFeature()
        } withDependencies: {
            $0.hapticClient.selection = { selectionCount.withValue { $0 += 1 } }
            $0.hapticClient.lightImpact = { impactCount.withValue { $0 += 1 } }
        }

        await store.send(.cardTapped(index: 2, indicator: cards[2])) {
            $0.activeIndex = 2
        }
        XCTAssertNil(store.state.detail)
        XCTAssertEqual(selectionCount.value, 1)

        await store.send(.cardTapped(index: 2, indicator: cards[2])) {
            $0.detail = IndicatorDetailFeature.State(indicator: cards[2])
        }
        XCTAssertEqual(impactCount.value, 1)
    }

    func testSwipeUpdatesCurrentCardAndSummary() async {
        let cards = NumerologyEngine.calculate24Cards(
            fullName: "Nguyễn Văn An",
            birthDate: "1998-10-20",
            referenceDate: referenceDate
        )
        let store = TestStore(
            initialState: NumerologyCardsFeature.State(indicators: cards)
        ) {
            NumerologyCardsFeature()
        } withDependencies: {
            $0.hapticClient.selection = {}
        }

        await store.send(.activeIndexChanged(1)) { $0.activeIndex = 1 }
        XCTAssertEqual(store.state.currentIndicator?.definition.key, NumerologyIndicatorKey.mission.rawValue)
        XCTAssertFalse(store.state.currentSummary.isEmpty)
    }

    func testFindFigurePresentsCoreTripleFromCalculatedCards() async {
        let cards = NumerologyEngine.calculate24Cards(
            fullName: "Nguyễn Văn An",
            birthDate: "1998-10-20",
            referenceDate: referenceDate
        )
        let expectedTriple = RepresentativeTriple(
            lifePath: cards.first { $0.definition.key == NumerologyIndicatorKey.walksOfLife.rawValue }!.value.numberValue!,
            expression: cards.first { $0.definition.key == NumerologyIndicatorKey.mission.rawValue }!.value.numberValue!,
            soulUrge: cards.first { $0.definition.key == NumerologyIndicatorKey.soul.rawValue }!.value.numberValue!
        )
        let store = TestStore(
            initialState: NumerologyCardsFeature.State(indicators: cards)
        ) {
            NumerologyCardsFeature()
        } withDependencies: {
            $0.hapticClient.mediumImpact = {}
        }

        await store.send(.findFigureTapped) {
            $0.historicalFigure = HistoricalFigureFeature.State(triple: expectedTriple)
        }
    }
}
