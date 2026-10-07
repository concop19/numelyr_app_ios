import Foundation

/// Pure, deterministic Zi Wei Dou Shu engine.
///
/// Star placement follows the pinned iztro 2.6.1 oracle. Calendar and boundary policies
/// are versioned separately so a future ruleset change never silently changes persisted results.
public nonisolated enum TuViEngine {
    public enum EngineError: LocalizedError, Equatable {
        case unsupportedRuleset(String, Int)
        case unsupportedBirthYear(Int)
        case invalidGregorianDate
        case invalidBirthTime
        case invalidTimeZone
        case incompatibleRulesets
        case invalidChartRulesetProvenance

        public var errorDescription: String? {
            switch self {
            case let .unsupportedRuleset(id, version):
                return "Ruleset Tử Vi chưa được hỗ trợ: \(id) v\(version)."
            case let .unsupportedBirthYear(year):
                return "Năm sinh \(year) nằm ngoài phạm vi hỗ trợ 1800–2199."
            case .invalidGregorianDate:
                return "Ngày sinh Dương lịch không hợp lệ."
            case .invalidBirthTime:
                return "Giờ sinh phải nằm trong 00:00–23:59."
            case .invalidTimeZone:
                return "Múi giờ sinh không hợp lệ."
            case .incompatibleRulesets:
                return "Không thể so sánh hai lá số được lập bằng ruleset khác nhau."
            case .invalidChartRulesetProvenance:
                return "Lá số có metadata ruleset không nhất quán với đầu vào đã lưu."
            }
        }
    }

    private static let supportedRulesets: [ZiWeiRuleset] = [
        .vietnameseDefaultV1,
        .vietnameseDefaultV2,
    ]

    private static let palaceCycle: [ZiWeiPalaceName] = [
        .life, .parents, .fortune, .property, .career, .friends,
        .travel, .health, .wealth, .children, .spouse, .siblings,
    ]

    private static let majorZiWeiGroup: [(ZiWeiStarName, Int)] = [
        (.ziWei, 0), (.tianJi, -1), (.taiYang, -3), (.wuQu, -4),
        (.tianTong, -5), (.lianZhen, -8),
    ]

    private static let majorTianFuGroup: [(ZiWeiStarName, Int)] = [
        (.tianFu, 0), (.taiYin, 1), (.tanLang, 2), (.juMen, 3),
        (.tianXiang, 4), (.tianLiang, 5), (.qiSha, 6), (.poJun, 10),
    ]

    /// Dignity tables are ordered Dần...Sửu, matching the pinned v1 oracle.
    private static let dignityCodes: [ZiWeiStarName: [String]] = [
        .ziWei: ["wang", "wang", "de", "wang", "miao", "miao", "wang", "wang", "de", "wang", "ping", "miao"],
        .tianJi: ["de", "wang", "li", "ping", "miao", "xian", "de", "wang", "li", "ping", "miao", "xian"],
        .taiYang: ["wang", "miao", "wang", "wang", "wang", "de", "de", "ping", "bu", "xian", "xian", "bu"],
        .wuQu: ["de", "li", "miao", "ping", "wang", "miao", "de", "li", "miao", "ping", "wang", "miao"],
        .tianTong: ["li", "ping", "ping", "miao", "xian", "bu", "wang", "ping", "ping", "miao", "wang", "bu"],
        .lianZhen: ["miao", "ping", "li", "xian", "ping", "li", "miao", "ping", "li", "xian", "ping", "li"],
        .tianFu: ["miao", "de", "miao", "de", "wang", "miao", "de", "wang", "miao", "de", "miao", "miao"],
        .taiYin: ["wang", "xian", "xian", "xian", "bu", "bu", "li", "wang", "wang", "miao", "miao", "miao"],
        .tanLang: ["ping", "li", "miao", "xian", "wang", "miao", "ping", "li", "miao", "xian", "wang", "miao"],
        .juMen: ["miao", "miao", "xian", "wang", "wang", "bu", "miao", "miao", "xian", "wang", "wang", "bu"],
        .tianXiang: ["miao", "xian", "de", "de", "miao", "de", "miao", "xian", "de", "de", "miao", "miao"],
        .tianLiang: ["miao", "miao", "miao", "xian", "miao", "wang", "xian", "de", "miao", "xian", "miao", "wang"],
        .qiSha: ["miao", "wang", "miao", "ping", "wang", "miao", "miao", "wang", "miao", "ping", "wang", "miao"],
        .poJun: ["de", "xian", "wang", "ping", "miao", "wang", "de", "xian", "wang", "ping", "miao", "wang"],
        .wenChang: ["xian", "li", "de", "miao", "xian", "li", "de", "miao", "xian", "li", "de", "miao"],
        .wenQu: ["ping", "wang", "de", "miao", "xian", "wang", "de", "miao", "xian", "wang", "de", "miao"],
        .huoXing: ["miao", "li", "xian", "de", "miao", "li", "xian", "de", "miao", "li", "xian", "de"],
        .lingXing: ["miao", "li", "xian", "de", "miao", "li", "xian", "de", "miao", "li", "xian", "de"],
        .qingYang: ["", "xian", "miao", "", "xian", "miao", "", "xian", "miao", "", "xian", "miao"],
        .tuoLuo: ["xian", "", "miao", "xian", "", "miao", "xian", "", "miao", "xian", "", "miao"],
    ]

    private static let transformationsByYearStem: [[ZiWeiStarName]] = [
        [.lianZhen, .poJun, .wuQu, .taiYang],
        [.tianJi, .tianLiang, .ziWei, .taiYin],
        [.tianTong, .tianJi, .wenChang, .lianZhen],
        [.taiYin, .tianTong, .tianJi, .juMen],
        [.tanLang, .taiYin, .youBi, .tianJi],
        [.wuQu, .tanLang, .tianLiang, .wenQu],
        [.taiYang, .wuQu, .taiYin, .tianTong],
        [.juMen, .taiYang, .wenQu, .wenChang],
        [.tianLiang, .ziWei, .zuoFu, .wuQu],
        [.poJun, .juMen, .taiYin, .tanLang],
    ]

    public static func generateChart(_ input: ZiWeiBirthInput) throws -> ZiWeiChart {
        guard supportedRulesets.contains(input.ruleset) else {
            throw EngineError.unsupportedRuleset(input.ruleset.id, input.ruleset.version)
        }
        guard (1800..<2200).contains(input.year) else {
            throw EngineError.unsupportedBirthYear(input.year)
        }
        guard (0...23).contains(input.hour), (0...59).contains(input.minute) else {
            throw EngineError.invalidBirthTime
        }
        guard input.timeZoneOffsetHours.isFinite,
              (-14.0...14.0).contains(input.timeZoneOffsetHours),
              let timeZone = TimeZone(secondsFromGMT: Int(input.timeZoneOffsetHours * 3600.0)) else {
            throw EngineError.invalidTimeZone
        }
        let calendarTimeZoneOffset = input.ruleset.calendarTimeZoneOffsetHours ?? input.timeZoneOffsetHours
        guard calendarTimeZoneOffset.isFinite,
              (-14.0...14.0).contains(calendarTimeZoneOffset) else {
            throw EngineError.invalidTimeZone
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = timeZone
        components.year = input.year
        components.month = input.month
        components.day = input.day
        components.hour = 12
        guard var effectiveDate = calendar.date(from: components) else {
            throw EngineError.invalidGregorianDate
        }
        let resolved = calendar.dateComponents([.year, .month, .day], from: effectiveDate)
        guard resolved.year == input.year, resolved.month == input.month, resolved.day == input.day else {
            throw EngineError.invalidGregorianDate
        }

        if input.hour == 23, input.ruleset.lateRatHourPolicy == .nextDay {
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: effectiveDate) else {
                throw EngineError.invalidGregorianDate
            }
            effectiveDate = nextDate
        }

        let effectiveComponents = calendar.dateComponents([.year, .month, .day], from: effectiveDate)
        guard let solarYear = effectiveComponents.year,
              let solarMonth = effectiveComponents.month,
              let solarDay = effectiveComponents.day else {
            throw EngineError.invalidGregorianDate
        }

        let lunarDate = LunarService.solarToLunar(
            day: solarDay,
            month: solarMonth,
            year: solarYear,
            timeZone: calendarTimeZoneOffset
        )
        let adjustedLunar = adjustedLunarMonth(lunarDate, policy: input.ruleset.leapMonthPolicy)
        let hourBranch = branch(at: (input.hour + 1) / 2)
        let yearPillar = pillarForYear(adjustedLunar.year)
        let monthPillar = pillarForMonth(adjustedLunar.month, lunarYear: adjustedLunar.year)
        let dayPillar = ZiWeiPillar(
            stem: stem(at: LunarService.getDayThienCan(day: solarDay, month: solarMonth, year: solarYear)),
            branch: branch(at: LunarService.getDayDiaChi(day: solarDay, month: solarMonth, year: solarYear))
        )
        let hourPillar = ZiWeiPillar(
            stem: stem(at: (dayPillar.stem.rawValue % 5) * 2 + hourBranch.rawValue),
            branch: hourBranch
        )

        let lunarMonthOffset = adjustedLunar.month - 1
        let lifeBranch = branch(at: 2 + lunarMonthOffset - hourBranch.rawValue)
        let bodyBranch = branch(at: 2 + lunarMonthOffset + hourBranch.rawValue)
        let yinStem = stem(at: (yearPillar.stem.rawValue % 5) * 2 + 2)
        let lifeStem = stem(at: yinStem.rawValue + positiveMod(lifeBranch.rawValue - 2, 12))
        let fiveElementClass = fiveElementClass(stem: lifeStem, branch: lifeBranch)

        var starsByBranch = Array(repeating: [ZiWeiStar](), count: 12)
        let transformationMap = transformations(for: yearPillar.stem)

        func place(_ name: ZiWeiStarName, category: ZiWeiStarCategory, at branch: ZiWeiEarthlyBranch) {
            starsByBranch[branch.rawValue].append(
                ZiWeiStar(
                    name: name,
                    category: category,
                    dignity: dignity(of: name, at: branch),
                    transformation: transformationMap[name]
                )
            )
        }

        let majorStart = majorStarStart(lunarDay: lunarDate.day, elementClass: fiveElementClass)
        for (name, offset) in majorZiWeiGroup {
            place(name, category: .major, at: branch(at: majorStart.ziWei.rawValue + offset))
        }
        for (name, offset) in majorTianFuGroup {
            place(name, category: .major, at: branch(at: majorStart.tianFu.rawValue + offset))
        }

        placeAuxiliaryStars(
            lunarMonth: adjustedLunar.month,
            hourBranch: hourBranch,
            yearStem: yearPillar.stem,
            yearBranch: yearPillar.branch,
            isolationCategory: input.ruleset.version >= 2 ? .isolation : .romance,
            place: place
        )

        let order = Dictionary(uniqueKeysWithValues: ZiWeiStarName.allCases.enumerated().map { ($1, $0) })
        let palaces = ZiWeiEarthlyBranch.allCases.map { fixedBranch in
            let palaceOffset = positiveMod(fixedBranch.rawValue - lifeBranch.rawValue, 12)
            let palaceStem = stem(at: yinStem.rawValue + positiveMod(fixedBranch.rawValue - 2, 12))
            return ZiWeiPalace(
                name: palaceCycle[palaceOffset],
                branch: fixedBranch,
                heavenlyStem: palaceStem,
                isBodyPalace: fixedBranch == bodyBranch,
                stars: starsByBranch[fixedBranch.rawValue].sorted {
                    (order[$0.name] ?? 0) < (order[$1.name] ?? 0)
                }
            )
        }

        return ZiWeiChart(
            ruleset: input.ruleset,
            birthInput: input,
            effectiveSolarDate: ZiWeiSolarDate(year: solarYear, month: solarMonth, day: solarDay),
            lunarDate: lunarDate,
            effectiveLunarMonth: adjustedLunar.month,
            fourPillars: ZiWeiFourPillars(
                year: yearPillar,
                month: monthPillar,
                day: dayPillar,
                hour: hourPillar
            ),
            lifePalaceBranch: lifeBranch,
            bodyPalaceBranch: bodyBranch,
            fiveElementClass: fiveElementClass,
            palaces: palaces
        )
    }

    public static func evaluateLoveCompatibility(
        chartA: ZiWeiChart,
        chartB: ZiWeiChart
    ) throws -> ZiWeiLoveAnalysis {
        guard chartA.ruleset == chartA.birthInput.ruleset,
              chartB.ruleset == chartB.birthInput.ruleset else {
            throw EngineError.invalidChartRulesetProvenance
        }
        guard chartA.ruleset == chartB.ruleset else {
            throw EngineError.incompatibleRulesets
        }

        var contributions: [ZiWeiCompatibilityContribution] = []

        func add(_ signal: ZiWeiCompatibilitySignal, _ points: Int, _ title: String, _ detail: String) {
            contributions.append(.init(signal: signal, points: points, titleVi: title, detailVi: detail))
        }

        func inspectSpousePalace(_ chart: ZiWeiChart, label: String) {
            guard let palace = chart.palace(named: .spouse) else { return }
            let supportive: Set<ZiWeiStarName> = [.ziWei, .tianFu, .tianXiang, .tianLiang, .taiYin, .tianTong]
            let challenging: Set<ZiWeiStarName> = [.lianZhen, .tanLang, .juMen, .qiSha, .poJun]
            let supportiveRomance: Set<ZiWeiStarName> = [.daoHoa, .hongLoan, .tianXi]

            for star in palace.stars {
                if supportive.contains(star.name) {
                    add(.supportive, 3, "Cát tinh tại Phu Thê \(label)", "\(star.name.rawValue) tăng tính nâng đỡ và ổn định.")
                } else if challenging.contains(star.name) {
                    add(.challenging, -2, "Chính tinh cần cân bằng \(label)", "\(star.name.rawValue) làm quan hệ mạnh nhưng cần giao tiếp rõ ràng.")
                }

                if supportiveRomance.contains(star.name) {
                    add(.supportive, 2, "Duyên tinh \(label)", "\(star.name.rawValue) tăng sức hút và khả năng biểu đạt tình cảm.")
                } else if star.name == .tianYao {
                    add(.neutral, 0, "Thiên Diêu tại Phu Thê \(label)", "Thiên Diêu tăng sức hút nhưng cần xét cùng tổ hợp sao, không mặc định cộng điểm.")
                } else if star.name == .guChen || star.name == .guaSu || star.category == .isolation {
                    add(.challenging, -2, "Cô độc tinh tại Phu Thê \(label)", "\(star.name.rawValue) nhấn mạnh khuynh hướng cô quạnh hoặc kết duyên muộn.")
                } else if star.category == .malefic {
                    add(.challenging, -3, "Sát tinh tại Phu Thê \(label)", "\(star.name.rawValue) báo hiệu áp lực cần được quản trị chủ động.")
                }

                switch star.dignity {
                case .temple, .prosperous, .favorable:
                    add(.supportive, 1, "Sao sáng tại Phu Thê \(label)", "\(star.name.rawValue) ở thế \(star.dignity?.rawValue ?? "").")
                case .fallen:
                    add(.challenging, -1, "Sao hãm tại Phu Thê \(label)", "\(star.name.rawValue) ở thế Hãm.")
                default:
                    break
                }

                switch star.transformation {
                case .fortune, .power, .reputation:
                    add(.supportive, 2, "Tứ Hóa thuận \(label)", "\(star.name.rawValue) mang \(star.transformation?.rawValue ?? "").")
                case .obstacle:
                    add(.challenging, -3, "Hóa Kỵ tại Phu Thê \(label)", "\(star.name.rawValue) Hóa Kỵ cần minh bạch kỳ vọng và cảm xúc.")
                case nil:
                    break
                }
            }
        }

        inspectSpousePalace(chartA, label: "A")
        inspectSpousePalace(chartB, label: "B")

        addBranchRelationship(
            chartA.lifePalaceBranch,
            chartB.lifePalaceBranch,
            label: "Mệnh A ↔ Mệnh B",
            add: add
        )
        if let spouseA = chartA.palace(named: .spouse)?.branch,
           let spouseB = chartB.palace(named: .spouse)?.branch {
            addBranchRelationship(spouseA, spouseB, label: "Phu Thê A ↔ Phu Thê B", add: add)
            addBranchRelationship(chartA.lifePalaceBranch, spouseB, label: "Mệnh A ↔ Phu Thê B", add: add)
            addBranchRelationship(chartB.lifePalaceBranch, spouseA, label: "Mệnh B ↔ Phu Thê A", add: add)
        }

        let score = min(100, max(0, 50 + contributions.reduce(0) { $0 + $1.points }))
        let summary: String
        switch score {
        case 75...:
            summary = "Hai lá số có nhiều tín hiệu hỗ trợ; nên duy trì giao tiếp và cùng thống nhất kỳ vọng dài hạn."
        case 50..<75:
            summary = "Hai lá số có cả thuận lợi lẫn thử thách; chất lượng quan hệ phụ thuộc nhiều vào cách hai người phối hợp."
        default:
            summary = "Hai lá số có nhiều điểm cần chủ động cân bằng; nên xem đây là gợi ý phản tư, không phải kết luận định mệnh."
        }

        return ZiWeiLoveAnalysis(
            rulesetID: "\(chartA.ruleset.id)-v\(chartA.ruleset.version)-compatibility-v2",
            score: score,
            contributions: contributions,
            summaryVi: summary,
            disclaimerVi: "Điểm số là quy tắc diễn giải truyền thống có thể kiểm tra từng thành phần, không phải xác suất khoa học hay dự đoán chắc chắn."
        )
    }

    // MARK: - Calendar and placement helpers

    private static func adjustedLunarMonth(
        _ lunarDate: LunarDate,
        policy: ZiWeiLeapMonthPolicy
    ) -> (month: Int, year: Int) {
        var month = lunarDate.month
        var year = lunarDate.year
        if lunarDate.leap, policy == .splitAfterFifteenth, lunarDate.day > 15 {
            month += 1
            if month > 12 {
                month = 1
                year += 1
            }
        }
        return (month, year)
    }

    private static func pillarForYear(_ lunarYear: Int) -> ZiWeiPillar {
        ZiWeiPillar(stem: stem(at: lunarYear - 4), branch: branch(at: lunarYear - 4))
    }

    private static func pillarForMonth(_ lunarMonth: Int, lunarYear: Int) -> ZiWeiPillar {
        let yearStemIndex = positiveMod(lunarYear - 4, 10)
        let monthStem = stem(at: (yearStemIndex % 5) * 2 + 2 + lunarMonth - 1)
        return ZiWeiPillar(stem: monthStem, branch: branch(at: lunarMonth + 1))
    }

    private static func fiveElementClass(
        stem: ZiWeiHeavenlyStem,
        branch: ZiWeiEarthlyBranch
    ) -> ZiWeiFiveElementClass {
        let stemNumber = stem.rawValue / 2 + 1
        let branchNumber = positiveMod(branch.rawValue, 6) / 2 + 1
        var value = stemNumber + branchNumber
        while value > 5 { value -= 5 }
        switch value {
        case 1: return .wood
        case 2: return .metal
        case 3: return .water
        case 4: return .fire
        default: return .earth
        }
    }

    private static func majorStarStart(
        lunarDay: Int,
        elementClass: ZiWeiFiveElementClass
    ) -> (ziWei: ZiWeiEarthlyBranch, tianFu: ZiWeiEarthlyBranch) {
        var offset = 0
        while (lunarDay + offset) % elementClass.rawValue != 0 {
            offset += 1
        }
        let quotient = ((lunarDay + offset) / elementClass.rawValue) % 12
        var ziWeiYinIndex = quotient - 1
        ziWeiYinIndex += offset.isMultiple(of: 2) ? offset : -offset
        ziWeiYinIndex = positiveMod(ziWeiYinIndex, 12)
        let tianFuYinIndex = positiveMod(12 - ziWeiYinIndex, 12)
        return (branch(at: ziWeiYinIndex + 2), branch(at: tianFuYinIndex + 2))
    }

    private static func placeAuxiliaryStars(
        lunarMonth: Int,
        hourBranch: ZiWeiEarthlyBranch,
        yearStem: ZiWeiHeavenlyStem,
        yearBranch: ZiWeiEarthlyBranch,
        isolationCategory: ZiWeiStarCategory,
        place: (ZiWeiStarName, ZiWeiStarCategory, ZiWeiEarthlyBranch) -> Void
    ) {
        place(.zuoFu, .benefic, branch(at: 4 + lunarMonth - 1))
        place(.youBi, .benefic, branch(at: 10 - (lunarMonth - 1)))
        place(.wenChang, .benefic, branch(at: 10 - hourBranch.rawValue))
        place(.wenQu, .benefic, branch(at: 4 + hourBranch.rawValue))

        let kuiYue: (Int, Int) = switch yearStem {
        case .giap, .mau, .canh: (1, 7)
        case .at, .ky: (0, 8)
        case .tan: (6, 2)
        case .binh, .dinh: (11, 9)
        case .nham, .quy: (3, 5)
        }
        place(.tianKui, .benefic, branch(at: kuiYue.0))
        place(.tianYue, .benefic, branch(at: kuiYue.1))

        let luBranch: Int = switch yearStem {
        case .giap: 2
        case .at: 3
        case .binh, .mau: 5
        case .dinh, .ky: 6
        case .canh: 8
        case .tan: 9
        case .nham: 11
        case .quy: 0
        }
        place(.luCun, .benefic, branch(at: luBranch))
        place(.qingYang, .malefic, branch(at: luBranch + 1))
        place(.tuoLuo, .malefic, branch(at: luBranch - 1))

        let tianMaBranch: Int
        if [2, 6, 10].contains(yearBranch.rawValue) {
            tianMaBranch = 8
        } else if [8, 0, 4].contains(yearBranch.rawValue) {
            tianMaBranch = 2
        } else if [5, 9, 1].contains(yearBranch.rawValue) {
            tianMaBranch = 11
        } else {
            tianMaBranch = 5
        }
        place(.tianMa, .benefic, branch(at: tianMaBranch))

        place(.diKong, .malefic, branch(at: 11 - hourBranch.rawValue))
        place(.diJie, .malefic, branch(at: 11 + hourBranch.rawValue))

        let fireBellStart: (Int, Int)
        if [2, 6, 10].contains(yearBranch.rawValue) {
            fireBellStart = (1, 3)
        } else if [8, 0, 4].contains(yearBranch.rawValue) {
            fireBellStart = (2, 10)
        } else if [5, 9, 1].contains(yearBranch.rawValue) {
            fireBellStart = (3, 10)
        } else {
            fireBellStart = (9, 10)
        }
        place(.huoXing, .malefic, branch(at: fireBellStart.0 + hourBranch.rawValue))
        place(.lingXing, .malefic, branch(at: fireBellStart.1 + hourBranch.rawValue))

        let hongLoan = branch(at: 3 - yearBranch.rawValue)
        place(.hongLoan, .romance, hongLoan)
        place(.tianXi, .romance, branch(at: hongLoan.rawValue + 6))

        let daoHoaBranch: Int
        if [2, 6, 10].contains(yearBranch.rawValue) {
            daoHoaBranch = 3
        } else if [8, 0, 4].contains(yearBranch.rawValue) {
            daoHoaBranch = 9
        } else if [5, 9, 1].contains(yearBranch.rawValue) {
            daoHoaBranch = 6
        } else {
            daoHoaBranch = 0
        }
        place(.daoHoa, .romance, branch(at: daoHoaBranch))

        let lonelyPair: (Int, Int)
        switch yearBranch.rawValue {
        case 2...4: lonelyPair = (5, 1)
        case 5...7: lonelyPair = (8, 4)
        case 8...10: lonelyPair = (11, 7)
        default: lonelyPair = (2, 10)
        }
        place(.guChen, isolationCategory, branch(at: lonelyPair.0))
        place(.guaSu, isolationCategory, branch(at: lonelyPair.1))
        place(.tianYao, .romance, branch(at: 1 + lunarMonth - 1))
    }

    private static func transformations(
        for yearStem: ZiWeiHeavenlyStem
    ) -> [ZiWeiStarName: ZiWeiTransformation] {
        let targets = transformationsByYearStem[yearStem.rawValue]
        return Dictionary(uniqueKeysWithValues: zip(targets, ZiWeiTransformation.allCases))
    }

    private static func dignity(
        of star: ZiWeiStarName,
        at branch: ZiWeiEarthlyBranch
    ) -> ZiWeiDignity? {
        guard let values = dignityCodes[star] else { return nil }
        let yinOrderedIndex = positiveMod(branch.rawValue - 2, 12)
        switch values[yinOrderedIndex] {
        case "miao": return .temple
        case "wang": return .prosperous
        case "de": return .favorable
        case "li": return .advantageous
        case "ping": return .neutral
        case "bu": return .unfavorable
        case "xian": return .fallen
        default: return nil
        }
    }

    private static func addBranchRelationship(
        _ lhs: ZiWeiEarthlyBranch,
        _ rhs: ZiWeiEarthlyBranch,
        label: String,
        add: (ZiWeiCompatibilitySignal, Int, String, String) -> Void
    ) {
        let liuHePartner = [1, 0, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2]
        let sanHeGroups = [[8, 0, 4], [11, 3, 7], [2, 6, 10], [5, 9, 1]]
        if lhs == rhs {
            add(.neutral, 1, "Đồng cung \(label)", "Hai cung cùng đóng tại \(lhs.titleVi).")
        } else if liuHePartner[lhs.rawValue] == rhs.rawValue {
            add(.supportive, 6, "Lục Hợp \(label)", "\(lhs.titleVi) và \(rhs.titleVi) tạo thế Lục Hợp.")
        } else if sanHeGroups.contains(where: { $0.contains(lhs.rawValue) && $0.contains(rhs.rawValue) }) {
            add(.supportive, 4, "Tam Hợp \(label)", "\(lhs.titleVi) và \(rhs.titleVi) cùng một Tam Hợp Cục.")
        } else if positiveMod(lhs.rawValue - rhs.rawValue, 12) == 6 {
            add(.challenging, -5, "Lục Xung \(label)", "\(lhs.titleVi) và \(rhs.titleVi) ở thế trực xung.")
        }
    }

    @inline(__always)
    private static func positiveMod(_ value: Int, _ modulus: Int) -> Int {
        ((value % modulus) + modulus) % modulus
    }

    private static func stem(at index: Int) -> ZiWeiHeavenlyStem {
        ZiWeiHeavenlyStem(rawValue: positiveMod(index, 10)) ?? .giap
    }

    private static func branch(at index: Int) -> ZiWeiEarthlyBranch {
        ZiWeiEarthlyBranch(rawValue: positiveMod(index, 12)) ?? .ty
    }
}
