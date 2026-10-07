import Foundation

public nonisolated enum ZiWeiHeavenlyStem: Int, Codable, CaseIterable, Equatable, Sendable {
    case giap, at, binh, dinh, mau, ky, canh, tan, nham, quy

    public var titleVi: String {
        ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"][rawValue]
    }
}

public nonisolated enum ZiWeiEarthlyBranch: Int, Codable, CaseIterable, Equatable, Sendable {
    case ty, suu, dan, mao, thin, ti, ngo, mui, than, dau, tuat, hoi

    public var titleVi: String {
        ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"][rawValue]
    }
}

public nonisolated enum ZiWeiPalaceName: String, Codable, CaseIterable, Equatable, Sendable {
    case life = "Mệnh"
    case parents = "Phụ Mẫu"
    case fortune = "Phúc Đức"
    case property = "Điền Trạch"
    case career = "Quan Lộc"
    case friends = "Nô Bộc"
    case travel = "Thiên Di"
    case health = "Tật Ách"
    case wealth = "Tài Bạch"
    case children = "Tử Tức"
    case spouse = "Phu Thê"
    case siblings = "Huynh Đệ"
}

public nonisolated enum ZiWeiFiveElementClass: Int, Codable, CaseIterable, Equatable, Sendable {
    case water = 2
    case wood = 3
    case metal = 4
    case earth = 5
    case fire = 6

    public var titleVi: String {
        switch self {
        case .water: return "Thủy Nhị Cục"
        case .wood: return "Mộc Tam Cục"
        case .metal: return "Kim Tứ Cục"
        case .earth: return "Thổ Ngũ Cục"
        case .fire: return "Hỏa Lục Cục"
        }
    }
}

public nonisolated enum ZiWeiStarCategory: String, Codable, Equatable, Sendable {
    case major
    case benefic
    case malefic
    case romance
    case isolation
}

public nonisolated enum ZiWeiStarName: String, Codable, CaseIterable, Equatable, Sendable {
    case ziWei = "Tử Vi"
    case tianJi = "Thiên Cơ"
    case taiYang = "Thái Dương"
    case wuQu = "Vũ Khúc"
    case tianTong = "Thiên Đồng"
    case lianZhen = "Liêm Trinh"
    case tianFu = "Thiên Phủ"
    case taiYin = "Thái Âm"
    case tanLang = "Tham Lang"
    case juMen = "Cự Môn"
    case tianXiang = "Thiên Tướng"
    case tianLiang = "Thiên Lương"
    case qiSha = "Thất Sát"
    case poJun = "Phá Quân"

    case zuoFu = "Tả Phù"
    case youBi = "Hữu Bật"
    case wenChang = "Văn Xương"
    case wenQu = "Văn Khúc"
    case tianKui = "Thiên Khôi"
    case tianYue = "Thiên Việt"
    case luCun = "Lộc Tồn"
    case tianMa = "Thiên Mã"
    case diKong = "Địa Không"
    case diJie = "Địa Kiếp"
    case huoXing = "Hỏa Tinh"
    case lingXing = "Linh Tinh"
    case qingYang = "Kình Dương"
    case tuoLuo = "Đà La"

    case daoHoa = "Đào Hoa"
    case hongLoan = "Hồng Loan"
    case tianXi = "Thiên Hỷ"
    case guChen = "Cô Thần"
    case guaSu = "Quả Tú"
    case tianYao = "Thiên Diêu"
}

public nonisolated enum ZiWeiTransformation: String, Codable, CaseIterable, Equatable, Sendable {
    case fortune = "Hóa Lộc"
    case power = "Hóa Quyền"
    case reputation = "Hóa Khoa"
    case obstacle = "Hóa Kỵ"
}

public nonisolated enum ZiWeiDignity: String, Codable, CaseIterable, Equatable, Sendable {
    case temple = "Miếu"
    case prosperous = "Vượng"
    case favorable = "Đắc"
    case advantageous = "Lợi"
    case neutral = "Bình"
    case unfavorable = "Bất"
    case fallen = "Hãm"
}

public nonisolated struct ZiWeiStar: Codable, Equatable, Sendable {
    public var name: ZiWeiStarName
    public var category: ZiWeiStarCategory
    public var dignity: ZiWeiDignity?
    public var transformation: ZiWeiTransformation?

    public init(
        name: ZiWeiStarName,
        category: ZiWeiStarCategory,
        dignity: ZiWeiDignity? = nil,
        transformation: ZiWeiTransformation? = nil
    ) {
        self.name = name
        self.category = category
        self.dignity = dignity
        self.transformation = transformation
    }
}

public nonisolated struct ZiWeiPalace: Codable, Equatable, Sendable {
    public var name: ZiWeiPalaceName
    public var branch: ZiWeiEarthlyBranch
    public var heavenlyStem: ZiWeiHeavenlyStem
    public var isBodyPalace: Bool
    public var stars: [ZiWeiStar]

    public init(
        name: ZiWeiPalaceName,
        branch: ZiWeiEarthlyBranch,
        heavenlyStem: ZiWeiHeavenlyStem,
        isBodyPalace: Bool,
        stars: [ZiWeiStar]
    ) {
        self.name = name
        self.branch = branch
        self.heavenlyStem = heavenlyStem
        self.isBodyPalace = isBodyPalace
        self.stars = stars
    }
}

public nonisolated struct ZiWeiPillar: Codable, Equatable, Sendable {
    public var stem: ZiWeiHeavenlyStem
    public var branch: ZiWeiEarthlyBranch

    public init(stem: ZiWeiHeavenlyStem, branch: ZiWeiEarthlyBranch) {
        self.stem = stem
        self.branch = branch
    }

    public var titleVi: String { "\(stem.titleVi) \(branch.titleVi)" }
}

public nonisolated struct ZiWeiFourPillars: Codable, Equatable, Sendable {
    public var year: ZiWeiPillar
    public var month: ZiWeiPillar
    public var day: ZiWeiPillar
    public var hour: ZiWeiPillar

    public init(year: ZiWeiPillar, month: ZiWeiPillar, day: ZiWeiPillar, hour: ZiWeiPillar) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
    }
}

public nonisolated enum ZiWeiLeapMonthPolicy: String, Codable, Equatable, Sendable {
    /// Giữ nguyên số tháng nhuận.
    case keepMonth
    /// Ngày 1...15 dùng tháng hiện tại; từ ngày 16 dùng tháng kế tiếp.
    case splitAfterFifteenth
}

public nonisolated enum ZiWeiLateRatHourPolicy: String, Codable, Equatable, Sendable {
    case currentDay
    case nextDay
}

public nonisolated struct ZiWeiRuleset: Codable, Equatable, Sendable {
    public var id: String
    public var version: Int
    public var leapMonthPolicy: ZiWeiLeapMonthPolicy
    public var lateRatHourPolicy: ZiWeiLateRatHourPolicy
    /// Múi giờ quy ước dùng để xác định ngày Sóc và tháng âm.
    /// `nil` chỉ tồn tại để tái lập ruleset v1 cũ, vốn dùng múi giờ nơi sinh.
    public var calendarTimeZoneOffsetHours: Double?
    public var oracleName: String
    public var oracleRevision: String

    public init(
        id: String,
        version: Int,
        leapMonthPolicy: ZiWeiLeapMonthPolicy,
        lateRatHourPolicy: ZiWeiLateRatHourPolicy,
        calendarTimeZoneOffsetHours: Double? = nil,
        oracleName: String,
        oracleRevision: String
    ) {
        self.id = id
        self.version = version
        self.leapMonthPolicy = leapMonthPolicy
        self.lateRatHourPolicy = lateRatHourPolicy
        self.calendarTimeZoneOffsetHours = calendarTimeZoneOffsetHours
        self.oracleName = oracleName
        self.oracleRevision = oracleRevision
    }

    public static let vietnameseDefaultV1 = Self(
        id: "vn-thai-thu-lang-iztro-default",
        version: 1,
        leapMonthPolicy: .splitAfterFifteenth,
        lateRatHourPolicy: .nextDay,
        oracleName: "SylarLong/iztro 2.6.1",
        oracleRevision: "2c7ef9be669df7b19d1799f4dce335fed3794f78"
    )

    /// Ruleset mặc định mới: ngày Dương lịch vẫn là ngày dân dụng tại nơi sinh,
    /// nhưng lịch âm Việt Nam luôn dùng múi giờ quy ước UTC+7.
    public static let vietnameseDefaultV2 = Self(
        id: "vn-thai-thu-lang-iztro-default",
        version: 2,
        leapMonthPolicy: .splitAfterFifteenth,
        lateRatHourPolicy: .nextDay,
        calendarTimeZoneOffsetHours: 7.0,
        oracleName: "Lịch Việt UTC+7; SylarLong/iztro 2.6.1 cho phép an sao",
        oracleRevision: "2c7ef9be669df7b19d1799f4dce335fed3794f78"
    )
}

public nonisolated struct ZiWeiBirthInput: Codable, Equatable, Sendable {
    public var year: Int
    public var month: Int
    public var day: Int
    public var hour: Int
    public var minute: Int
    public var gender: Gender
    public var timeZoneOffsetHours: Double
    public var ruleset: ZiWeiRuleset

    public init(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int = 0,
        gender: Gender,
        timeZoneOffsetHours: Double = 7.0,
        ruleset: ZiWeiRuleset = .vietnameseDefaultV2
    ) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.gender = gender
        self.timeZoneOffsetHours = timeZoneOffsetHours
        self.ruleset = ruleset
    }
}

public nonisolated struct ZiWeiSolarDate: Codable, Equatable, Sendable {
    public var year: Int
    public var month: Int
    public var day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }
}

public nonisolated struct ZiWeiChart: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var ruleset: ZiWeiRuleset
    public var birthInput: ZiWeiBirthInput
    public var effectiveSolarDate: ZiWeiSolarDate
    public var lunarDate: LunarDate
    public var effectiveLunarMonth: Int
    public var fourPillars: ZiWeiFourPillars
    public var lifePalaceBranch: ZiWeiEarthlyBranch
    public var bodyPalaceBranch: ZiWeiEarthlyBranch
    public var fiveElementClass: ZiWeiFiveElementClass
    public var palaces: [ZiWeiPalace]

    public init(
        schemaVersion: Int = 1,
        ruleset: ZiWeiRuleset,
        birthInput: ZiWeiBirthInput,
        effectiveSolarDate: ZiWeiSolarDate,
        lunarDate: LunarDate,
        effectiveLunarMonth: Int,
        fourPillars: ZiWeiFourPillars,
        lifePalaceBranch: ZiWeiEarthlyBranch,
        bodyPalaceBranch: ZiWeiEarthlyBranch,
        fiveElementClass: ZiWeiFiveElementClass,
        palaces: [ZiWeiPalace]
    ) {
        self.schemaVersion = schemaVersion
        self.ruleset = ruleset
        self.birthInput = birthInput
        self.effectiveSolarDate = effectiveSolarDate
        self.lunarDate = lunarDate
        self.effectiveLunarMonth = effectiveLunarMonth
        self.fourPillars = fourPillars
        self.lifePalaceBranch = lifePalaceBranch
        self.bodyPalaceBranch = bodyPalaceBranch
        self.fiveElementClass = fiveElementClass
        self.palaces = palaces
    }

    public func palace(named name: ZiWeiPalaceName) -> ZiWeiPalace? {
        palaces.first { $0.name == name }
    }

    public func location(of star: ZiWeiStarName) -> ZiWeiEarthlyBranch? {
        palaces.first { palace in palace.stars.contains { $0.name == star } }?.branch
    }
}

public nonisolated enum ZiWeiCompatibilitySignal: String, Codable, Equatable, Sendable {
    case supportive
    case challenging
    case neutral
}

public nonisolated struct ZiWeiCompatibilityContribution: Codable, Equatable, Sendable {
    public var signal: ZiWeiCompatibilitySignal
    public var points: Int
    public var titleVi: String
    public var detailVi: String

    public init(signal: ZiWeiCompatibilitySignal, points: Int, titleVi: String, detailVi: String) {
        self.signal = signal
        self.points = points
        self.titleVi = titleVi
        self.detailVi = detailVi
    }
}

public nonisolated struct ZiWeiLoveAnalysis: Codable, Equatable, Sendable {
    public var rulesetID: String
    public var score: Int
    public var contributions: [ZiWeiCompatibilityContribution]
    public var summaryVi: String
    public var disclaimerVi: String

    public init(
        rulesetID: String,
        score: Int,
        contributions: [ZiWeiCompatibilityContribution],
        summaryVi: String,
        disclaimerVi: String
    ) {
        self.rulesetID = rulesetID
        self.score = score
        self.contributions = contributions
        self.summaryVi = summaryVi
        self.disclaimerVi = disclaimerVi
    }
}
