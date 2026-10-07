import XCTest
@testable import numelyra_app_ios

final class TuViEngineTests: XCTestCase {
    private func goldenInput() -> ZiWeiBirthInput {
        ZiWeiBirthInput(
            year: 2023,
            month: 3,
            day: 6,
            hour: 8,
            gender: .female
        )
    }

    private func replacingSpouseStars(
        in source: ZiWeiChart,
        with stars: [ZiWeiStar]
    ) -> ZiWeiChart {
        var chart = source
        guard let index = chart.palaces.firstIndex(where: { $0.name == .spouse }) else {
            XCTFail("Lá số phải có cung Phu Thê")
            return chart
        }
        chart.palaces[index].stars = stars
        return chart
    }

    func testGoldenMajorStarsMatchesPinnedIztroFixture() throws {
        let chart = try TuViEngine.generateChart(goldenInput())

        XCTAssertEqual(chart.ruleset.version, 2)
        XCTAssertEqual(chart.ruleset.calendarTimeZoneOffsetHours, 7.0)
        XCTAssertEqual(chart.ruleset.oracleRevision, "2c7ef9be669df7b19d1799f4dce335fed3794f78")
        XCTAssertEqual(chart.lunarDate, LunarDate(day: 15, month: 2, year: 2023))
        XCTAssertEqual(chart.lifePalaceBranch, .hoi)
        XCTAssertEqual(chart.bodyPalaceBranch, .mui)
        XCTAssertEqual(chart.fiveElementClass, .water)

        let expected: [ZiWeiEarthlyBranch: [ZiWeiStarName]] = [
            .dan: [.qiSha],
            .mao: [.tianTong],
            .thin: [.wuQu],
            .ti: [.taiYang],
            .ngo: [.poJun],
            .mui: [.tianJi],
            .than: [.ziWei, .tianFu],
            .dau: [.taiYin],
            .tuat: [.tanLang],
            .hoi: [.juMen],
            .ty: [.lianZhen, .tianXiang],
            .suu: [.tianLiang],
        ]

        for palace in chart.palaces {
            let actual = palace.stars.filter { $0.category == .major }.map(\.name)
            XCTAssertEqual(actual, expected[palace.branch] ?? [], "Sai chính tinh tại \(palace.branch.titleVi)")
        }
    }

    func testEveryMajorStarAppearsExactlyOnceAndPalacesAreComplete() throws {
        let chart = try TuViEngine.generateChart(goldenInput())
        let majorNames = chart.palaces.flatMap(\.stars).filter { $0.category == .major }.map(\.name)
        let expected: Set<ZiWeiStarName> = [
            .ziWei, .tianJi, .taiYang, .wuQu, .tianTong, .lianZhen,
            .tianFu, .taiYin, .tanLang, .juMen, .tianXiang, .tianLiang,
            .qiSha, .poJun,
        ]

        XCTAssertEqual(chart.palaces.count, 12)
        XCTAssertEqual(Set(chart.palaces.map(\.name)).count, 12)
        XCTAssertEqual(Set(chart.palaces.map(\.branch)).count, 12)
        XCTAssertEqual(majorNames.count, 14)
        XCTAssertEqual(Set(majorNames), expected)
        for name in expected {
            XCTAssertEqual(majorNames.filter { $0 == name }.count, 1, "\(name.rawValue) phải xuất hiện đúng một lần")
        }
    }

    func testRomanceAndAuxiliaryStarGoldenPositions() throws {
        let chart = try TuViEngine.generateChart(goldenInput())

        XCTAssertEqual(chart.location(of: .hongLoan), .ty)
        XCTAssertEqual(chart.location(of: .tianXi), .ngo)
        XCTAssertEqual(chart.location(of: .daoHoa), .ty)
        XCTAssertEqual(chart.location(of: .guChen), .ti)
        XCTAssertEqual(chart.location(of: .guaSu), .suu)
        XCTAssertEqual(chart.location(of: .tianYao), .dan)

        let starsByName = Dictionary(uniqueKeysWithValues: chart.palaces.flatMap(\.stars).map { ($0.name, $0) })
        XCTAssertEqual(starsByName[.guChen]?.category, .isolation)
        XCTAssertEqual(starsByName[.guaSu]?.category, .isolation)
        XCTAssertEqual(starsByName[.tianYao]?.category, .romance)

        let expectedAuxiliary: [ZiWeiStarName: ZiWeiEarthlyBranch] = [
            .zuoFu: .ti,
            .youBi: .dau,
            .wenChang: .ngo,
            .wenQu: .than,
            .tianKui: .mao,
            .tianYue: .ti,
            .luCun: .ty,
            .qingYang: .suu,
            .tuoLuo: .hoi,
            .tianMa: .ti,
            .diKong: .mui,
            .diJie: .mao,
            .huoXing: .suu,
            .lingXing: .dan,
        ]
        for (star, branch) in expectedAuxiliary {
            XCTAssertEqual(chart.location(of: star), branch, "Sai phụ tinh \(star.rawValue)")
        }

        let allStars = chart.palaces.flatMap(\.stars)
        XCTAssertEqual(allStars.count, 34)
        XCTAssertEqual(Set(allStars.map(\.name)).count, 34)
    }

    func testFourTransformationsUseLunarYearStem() throws {
        let chart = try TuViEngine.generateChart(goldenInput()) // Quý Mão
        let transformed = Dictionary(uniqueKeysWithValues: chart.palaces.flatMap(\.stars).compactMap { star in
            star.transformation.map { (star.name, $0) }
        })

        XCTAssertEqual(transformed[.poJun], .fortune)
        XCTAssertEqual(transformed[.juMen], .power)
        XCTAssertEqual(transformed[.taiYin], .reputation)
        XCTAssertEqual(transformed[.tanLang], .obstacle)
        XCTAssertEqual(transformed.count, 4)
    }

    func testLateRatHourMovesToNextCivilDayUnderDefaultRuleset() throws {
        let chart = try TuViEngine.generateChart(
            ZiWeiBirthInput(
                year: 2024,
                month: 2,
                day: 9,
                hour: 23,
                minute: 30,
                gender: .male
            )
        )

        XCTAssertEqual(chart.effectiveSolarDate, ZiWeiSolarDate(year: 2024, month: 2, day: 10))
        XCTAssertEqual(chart.lunarDate, LunarDate(day: 1, month: 1, year: 2024))
        XCTAssertEqual(chart.fourPillars.hour.branch, .ty)
    }

    func testVietnameseCalendarTimeZoneDoesNotFollowBirthPlaceOffset() throws {
        let vietnam = try TuViEngine.generateChart(
            ZiWeiBirthInput(
                year: 2024,
                month: 2,
                day: 9,
                hour: 12,
                gender: .female,
                timeZoneOffsetHours: 7
            )
        )
        let newYork = try TuViEngine.generateChart(
            ZiWeiBirthInput(
                year: 2024,
                month: 2,
                day: 9,
                hour: 12,
                gender: .female,
                timeZoneOffsetHours: -5
            )
        )

        XCTAssertEqual(vietnam.lunarDate, newYork.lunarDate)
        XCTAssertEqual(
            newYork.lunarDate,
            LunarService.solarToLunar(day: 9, month: 2, year: 2024, timeZone: 7)
        )
        XCTAssertNotEqual(
            newYork.lunarDate,
            LunarService.solarToLunar(day: 9, month: 2, year: 2024, timeZone: -5)
        )
    }

    func testLegacyV1StillReproducesBirthPlaceCalendarTimeZone() throws {
        let chart = try TuViEngine.generateChart(
            ZiWeiBirthInput(
                year: 2024,
                month: 2,
                day: 9,
                hour: 12,
                gender: .female,
                timeZoneOffsetHours: -5,
                ruleset: .vietnameseDefaultV1
            )
        )

        XCTAssertEqual(
            chart.lunarDate,
            LunarService.solarToLunar(day: 9, month: 2, year: 2024, timeZone: -5)
        )
        let starsByName = Dictionary(uniqueKeysWithValues: chart.palaces.flatMap(\.stars).map { ($0.name, $0) })
        XCTAssertEqual(starsByName[.guChen]?.category, .romance)
        XCTAssertEqual(starsByName[.guaSu]?.category, .romance)
    }

    func testLeapMonthPolicySplitsAfterFifteenth() throws {
        let firstHalf = try TuViEngine.generateChart(
            ZiWeiBirthInput(year: 2023, month: 3, day: 22, hour: 12, gender: .female)
        )
        let secondHalf = try TuViEngine.generateChart(
            ZiWeiBirthInput(year: 2023, month: 4, day: 7, hour: 12, gender: .female)
        )

        XCTAssertTrue(firstHalf.lunarDate.leap)
        XCTAssertEqual(firstHalf.lunarDate.month, 2)
        XCTAssertEqual(firstHalf.effectiveLunarMonth, 2)
        XCTAssertTrue(secondHalf.lunarDate.leap)
        XCTAssertEqual(secondHalf.lunarDate.month, 2)
        XCTAssertGreaterThan(secondHalf.lunarDate.day, 15)
        XCTAssertEqual(secondHalf.effectiveLunarMonth, 3)
    }

    func testInvalidInputIsRejectedInsteadOfFallingBack() {
        XCTAssertThrowsError(
            try TuViEngine.generateChart(
                ZiWeiBirthInput(year: 2024, month: 2, day: 30, hour: 12, gender: .female)
            )
        ) { error in
            XCTAssertEqual(error as? TuViEngine.EngineError, .invalidGregorianDate)
        }

        XCTAssertThrowsError(
            try TuViEngine.generateChart(
                ZiWeiBirthInput(year: 2024, month: 2, day: 10, hour: 24, gender: .female)
            )
        ) { error in
            XCTAssertEqual(error as? TuViEngine.EngineError, .invalidBirthTime)
        }

        XCTAssertThrowsError(
            try TuViEngine.generateChart(
                ZiWeiBirthInput(year: 1799, month: 12, day: 31, hour: 12, gender: .female)
            )
        ) { error in
            XCTAssertEqual(error as? TuViEngine.EngineError, .unsupportedBirthYear(1799))
        }

        var spoofedRuleset = ZiWeiRuleset.vietnameseDefaultV2
        spoofedRuleset.lateRatHourPolicy = .currentDay
        XCTAssertThrowsError(
            try TuViEngine.generateChart(
                ZiWeiBirthInput(
                    year: 2024,
                    month: 2,
                    day: 10,
                    hour: 12,
                    gender: .female,
                    ruleset: spoofedRuleset
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? TuViEngine.EngineError,
                .unsupportedRuleset(spoofedRuleset.id, spoofedRuleset.version)
            )
        }
    }

    func testCompatibilityIsExplainableAndOrderIndependent() throws {
        let chartA = try TuViEngine.generateChart(goldenInput())
        let chartB = try TuViEngine.generateChart(
            ZiWeiBirthInput(year: 1998, month: 10, day: 20, hour: 14, minute: 30, gender: .male)
        )

        let forward = try TuViEngine.evaluateLoveCompatibility(chartA: chartA, chartB: chartB)
        let reverse = try TuViEngine.evaluateLoveCompatibility(chartA: chartB, chartB: chartA)

        XCTAssertEqual(forward.score, reverse.score)
        XCTAssertEqual(forward.rulesetID, "vn-thai-thu-lang-iztro-default-v2-compatibility-v2")
        XCTAssertTrue((0...100).contains(forward.score))
        XCTAssertFalse(forward.contributions.isEmpty)
        XCTAssertTrue(forward.contributions.allSatisfy { !$0.titleVi.isEmpty && !$0.detailVi.isEmpty })
        XCTAssertTrue(forward.disclaimerVi.contains("không phải xác suất khoa học"))
    }

    func testSameBranchIsSamePalaceInsteadOfTripleHarmony() throws {
        let chart = try TuViEngine.generateChart(goldenInput())
        let analysis = try TuViEngine.evaluateLoveCompatibility(chartA: chart, chartB: chart)

        XCTAssertTrue(analysis.contributions.contains { $0.titleVi == "Đồng cung Mệnh A ↔ Mệnh B" })
        XCTAssertTrue(analysis.contributions.contains { $0.titleVi == "Đồng cung Phu Thê A ↔ Phu Thê B" })
        XCTAssertFalse(analysis.contributions.contains {
            $0.titleVi == "Tam Hợp Mệnh A ↔ Mệnh B"
                || $0.titleVi == "Tam Hợp Phu Thê A ↔ Phu Thê B"
        })
        XCTAssertFalse(analysis.contributions.contains {
            $0.titleVi.contains("Mệnh A ↔ Phu Thê A")
                || $0.titleVi.contains("Mệnh B ↔ Phu Thê B")
        })
    }

    func testIsolationStarsPenalizeInsteadOfReceivingRomanceBonus() throws {
        let source = try TuViEngine.generateChart(goldenInput())
        let chart = replacingSpouseStars(
            in: source,
            with: [ZiWeiStar(name: .guChen, category: .isolation)]
        )
        let analysis = try TuViEngine.evaluateLoveCompatibility(chartA: chart, chartB: chart)

        let guChenContributions = analysis.contributions.filter { $0.detailVi.contains("Cô Thần") }
        XCTAssertEqual(guChenContributions.count, 2)
        XCTAssertTrue(guChenContributions.allSatisfy {
            $0.signal == .challenging && $0.points == -2
        })
        XCTAssertFalse(analysis.contributions.contains {
            $0.titleVi.hasPrefix("Duyên tinh") && $0.detailVi.contains("Cô Thần")
        })

        let legacyEncodedChart = replacingSpouseStars(
            in: source,
            with: [ZiWeiStar(name: .guaSu, category: .romance)]
        )
        let legacyAnalysis = try TuViEngine.evaluateLoveCompatibility(
            chartA: legacyEncodedChart,
            chartB: legacyEncodedChart
        )
        let guaSuContributions = legacyAnalysis.contributions.filter { $0.detailVi.contains("Quả Tú") }
        XCTAssertEqual(guaSuContributions.count, 2)
        XCTAssertTrue(guaSuContributions.allSatisfy {
            $0.signal == .challenging && $0.points == -2
        })
    }

    func testTianYaoIsExplainedWithoutAutomaticBonus() throws {
        let source = try TuViEngine.generateChart(goldenInput())
        let chart = replacingSpouseStars(
            in: source,
            with: [ZiWeiStar(name: .tianYao, category: .romance)]
        )
        let analysis = try TuViEngine.evaluateLoveCompatibility(chartA: chart, chartB: chart)
        let tianYaoContributions = analysis.contributions.filter { $0.titleVi.hasPrefix("Thiên Diêu") }

        XCTAssertEqual(tianYaoContributions.count, 2)
        XCTAssertTrue(tianYaoContributions.allSatisfy {
            $0.signal == .neutral && $0.points == 0
        })
    }

    func testCompatibilityRejectsDifferentRulesets() throws {
        let current = try TuViEngine.generateChart(goldenInput())
        let legacy = try TuViEngine.generateChart(
            ZiWeiBirthInput(
                year: 1998,
                month: 10,
                day: 20,
                hour: 14,
                gender: .male,
                ruleset: .vietnameseDefaultV1
            )
        )

        XCTAssertThrowsError(
            try TuViEngine.evaluateLoveCompatibility(chartA: current, chartB: legacy)
        ) { error in
            XCTAssertEqual(error as? TuViEngine.EngineError, .incompatibleRulesets)
        }
    }

    func testRawValuesRequiredByPlacementTablesArePinned() {
        XCTAssertEqual(ZiWeiFiveElementClass.allCases.map(\.rawValue), [2, 3, 4, 5, 6])
        XCTAssertEqual(
            ZiWeiTransformation.allCases,
            [.fortune, .power, .reputation, .obstacle]
        )
    }
}
