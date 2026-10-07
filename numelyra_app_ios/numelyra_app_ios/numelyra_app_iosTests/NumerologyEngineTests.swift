import Foundation
import XCTest
@testable import numelyra_app_ios

final class NumerologyEngineTests: XCTestCase {
    private var vietnamCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "vi_VN")
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        return calendar
    }

    private func referenceDate(
        year: Int = 2026,
        month: Int = 10,
        day: Int = 7,
        hour: Int = 12
    ) -> Date {
        vietnamCalendar.date(
            from: DateComponents(year: year, month: month, day: day, hour: hour)
        )!
    }

    func testCardsV1CalculatesAllTwentyFourIndicatorsInStableOrder() throws {
        let snapshot = NumerologyEngine.calculate24(
            fullName: "Nguyễn Văn An",
            birthDate: "1998-10-20",
            referenceDate: referenceDate(),
            calendar: vietnamCalendar
        )

        XCTAssertEqual(snapshot.rulesetVersion, .reactNativeCardsV1)
        XCTAssertEqual(snapshot.normalizedName, "NGUYEN VAN AN")
        XCTAssertEqual(snapshot.indicators.count, 24)
        XCTAssertEqual(snapshot.indicators.map(\.key), NumerologyIndicatorKey.allCases)

        XCTAssertEqual(snapshot[.walksOfLife]?.value, .number(3))
        XCTAssertEqual(snapshot[.mission]?.value, .number(3))
        XCTAssertEqual(snapshot[.soul]?.value, .number(1))
        XCTAssertEqual(snapshot[.personality]?.value, .number(11))
        XCTAssertEqual(snapshot[.personality]?.isMaster, true)
        XCTAssertEqual(snapshot[.dateOfBirth]?.value, .number(2))
        XCTAssertEqual(snapshot[.mature]?.value, .number(6))
        XCTAssertEqual(snapshot[.balance]?.value, .number(1))
        XCTAssertEqual(snapshot[.rationalThinking]?.value, .number(8))
        XCTAssertEqual(snapshot[.subconsciousPower]?.value, .number(5))
        XCTAssertEqual(snapshot[.passion]?.value, .text("5"))
        XCTAssertEqual(snapshot[.attitude]?.value, .number(3))
        XCTAssertEqual(snapshot[.karmicDebts]?.value, .text("Không có nợ nghiệp"))
        XCTAssertEqual(snapshot[.missingNumbers]?.value, .text("2, 6, 8, 9"))
        XCTAssertEqual(snapshot[.bridgeLifeMission]?.value, .number(0))
        XCTAssertEqual(snapshot[.bridgeSoulPersonality]?.value, .number(1))
        XCTAssertEqual(snapshot[.bridgeMaturityPassion]?.value, .number(6))
        XCTAssertEqual(snapshot[.yearIndividual]?.value, .number(4))
        XCTAssertEqual(snapshot[.monthIndividual]?.value, .number(5))
        XCTAssertEqual(snapshot[.dayIndividual]?.value, .number(3))
        XCTAssertEqual(snapshot[.way]?.value, .text("3 - 2 - 5 - 10"))
        XCTAssertEqual(snapshot[.challenges]?.value, .text("1 - 7 - 6 - 8"))
        XCTAssertEqual(snapshot[.arrows]?.value, .text("4-5-6 (Trống); 3-5-7 (Trống)"))
        XCTAssertEqual(snapshot[.nameChart]?.value, .text("Tổng 11 chữ cái"))
        XCTAssertEqual(snapshot[.birthChart]?.value, .text("Tổng 8 chữ số ngày sinh"))

        XCTAssertEqual(snapshot.nameFrequencies[5], 5)
        XCTAssertEqual(snapshot.birthFrequencies[1], 2)
        XCTAssertEqual(snapshot.missingNumbers, [2, 6, 8, 9])
        XCTAssertEqual(snapshot.hiddenPassions, [5])
        XCTAssertEqual(snapshot.pinnacles, [3, 2, 5, 10])
        XCTAssertEqual(snapshot.challenges, [1, 7, 6, 8])
        XCTAssertEqual(
            snapshot.arrows,
            [
                NumerologyArrow(digits: [4, 5, 6], kind: .empty),
                NumerologyArrow(digits: [3, 5, 7], kind: .empty),
            ]
        )
    }

    func testCardsAndAgentRulesetsPreserveLegacyLifePathDifferences() {
        let cardsMaster = NumerologyEngine.calculate24(
            fullName: "A",
            birthDate: "1991-01-01",
            referenceDate: referenceDate(),
            calendar: vietnamCalendar
        )
        let agentMaster = NumerologyEngine.requestedIndicators(
            fullName: "A",
            birthDate: "1991-01-01",
            keys: ["walksOfLife"],
            referenceDate: referenceDate(),
            calendar: vietnamCalendar
        )

        XCTAssertEqual(cardsMaster[.walksOfLife]?.value, .number(22))
        XCTAssertEqual(cardsMaster[.walksOfLife]?.isMaster, true)
        XCTAssertEqual(agentMaster.first?.value, .number(4))

        let cardsTen = NumerologyEngine.calculate24(
            fullName: "A",
            birthDate: "2000-01-07",
            referenceDate: referenceDate(),
            calendar: vietnamCalendar
        )
        let agentTen = NumerologyEngine.requestedIndicators(
            fullName: "A",
            birthDate: "2000-01-07",
            keys: ["walksOfLife"],
            referenceDate: referenceDate(),
            calendar: vietnamCalendar
        )
        XCTAssertEqual(cardsTen[.walksOfLife]?.value, .number(10))
        XCTAssertEqual(cardsTen[.walksOfLife]?.isMaster, false)
        XCTAssertEqual(agentTen.first?.value, .number(1))
    }

    func testVietnameseNormalizationAndYVowelRuleMatchReactNative() {
        XCTAssertEqual(NumerologyEngine.normalizeName("  Đặng  Mỹ-Linh  "), "DANG MY LINH")
        XCTAssertTrue(NumerologyEngine.isVowel("Y", in: "MY"))
        XCTAssertFalse(NumerologyEngine.isVowel("Y", in: "NGUYEN"))
        XCTAssertTrue(NumerologyEngine.isVowel("U", in: "NGUYEN"))
    }

    func testAgentSubsetPreservesRequestedOrderAndDropsUnknownKeys() {
        let indicators = NumerologyEngine.requestedIndicators(
            fullName: "Nguyễn Văn An",
            birthDate: "1998-10-20",
            keys: ["mission", "unknown", "rationalThinking", "walksOfLife"],
            referenceDate: referenceDate(),
            calendar: vietnamCalendar
        )

        XCTAssertEqual(indicators.map(\.key), ["mission", "rationalThinking", "walksOfLife"])
        XCTAssertEqual(indicators.map(\.value), [.number(3), .number(8), .number(3)])
    }

    func testReferenceDateAndCalendarMakePersonalCyclesDeterministic() {
        let beforeMidnight = NumerologyEngine.calculate24(
            fullName: "Nguyễn Văn An",
            birthDate: "1998-10-20",
            referenceDate: referenceDate(day: 7, hour: 23),
            calendar: vietnamCalendar
        )
        let nextDay = NumerologyEngine.calculate24(
            fullName: "Nguyễn Văn An",
            birthDate: "1998-10-20",
            referenceDate: referenceDate(day: 8, hour: 0),
            calendar: vietnamCalendar
        )

        XCTAssertEqual(beforeMidnight[.dayIndividual]?.value, .number(3))
        XCTAssertEqual(nextDay[.dayIndividual]?.value, .number(4))
        XCTAssertEqual(beforeMidnight[.yearIndividual]?.value, nextDay[.yearIndividual]?.value)
        XCTAssertEqual(beforeMidnight[.monthIndividual]?.value, nextDay[.monthIndividual]?.value)
    }

    func testLegacyBirthDateFallbacksRemainExplicit() {
        let cards = NumerologyEngine.calculate24(
            fullName: "A",
            birthDate: "",
            referenceDate: referenceDate(),
            calendar: vietnamCalendar
        )
        XCTAssertEqual(cards.birthDate, NumerologyBirthDate(day: 7, month: 10, year: 2026))

        let agent = NumerologyEngine.requestedIndicators(
            fullName: "A",
            birthDate: "not-a-date",
            keys: ["dateOfBirth"],
            referenceDate: referenceDate(),
            calendar: vietnamCalendar
        )
        XCTAssertEqual(agent.first?.value, .number(1))
    }
}
