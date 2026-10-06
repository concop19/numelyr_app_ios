import Foundation

public struct LunarDate: Codable, Equatable, Hashable, Sendable {
    public var day: Int
    public var month: Int
    public var year: Int
    public var leap: Bool // Tháng nhuận

    public init(day: Int, month: Int, year: Int, leap: Bool = false) {
        self.day = day
        self.month = month
        self.year = year
        self.leap = leap
    }
}

public struct LunarHourInfo: Identifiable, Codable, Equatable, Sendable {
    public var id: String { name }
    public var name: String // Tý, Sửu, Dần...
    public var canChi: String // Giáp Tý, Ất Sửu...
    public var range: String // "23h-01h"
    public var startHour: Int
    public var isHoangDao: Bool
    public var isClash: Bool // Xung tuổi người dùng
    public var isDayClash: Bool // Xung Địa Chi của ngày (Nhật Phá)
    public var label: String // "Thanh Long", "Minh Đường"...
    public var lyThuanPhong: String // "Đại An", "Tốc Hỷ", "Tiểu Cát"...
    public var isLyThuanPhongGood: Bool

    public init(
        name: String,
        canChi: String = "",
        range: String,
        startHour: Int,
        isHoangDao: Bool,
        isClash: Bool = false,
        isDayClash: Bool = false,
        label: String,
        lyThuanPhong: String = "",
        isLyThuanPhongGood: Bool = false
    ) {
        self.name = name
        self.canChi = canChi
        self.range = range
        self.startHour = startHour
        self.isHoangDao = isHoangDao
        self.isClash = isClash
        self.isDayClash = isDayClash
        self.label = label
        self.lyThuanPhong = lyThuanPhong
        self.isLyThuanPhongGood = isLyThuanPhongGood
    }
}

public struct DayHoangDaoStatus: Codable, Equatable, Sendable {
    public var isHoangDao: Bool
    public var label: String

    public init(isHoangDao: Bool, label: String) {
        self.isHoangDao = isHoangDao
        self.label = label
    }
}

public struct CalendarDayItem: Identifiable, Equatable, Sendable {
    public var id: Date { date }
    public var date: Date
    public var dayNumber: Int
    public var dayOfWeekVi: String
    public var dayOfWeekShort: String
    public var isCurrentDay: Bool

    public init(
        date: Date,
        dayNumber: Int,
        dayOfWeekVi: String,
        dayOfWeekShort: String,
        isCurrentDay: Bool
    ) {
        self.date = date
        self.dayNumber = dayNumber
        self.dayOfWeekVi = dayOfWeekVi
        self.dayOfWeekShort = dayOfWeekShort
        self.isCurrentDay = isCurrentDay
    }
}

public struct CalendarWeekInfo: Equatable, Sendable {
    public var weekNumber: Int
    public var days: [CalendarDayItem]

    public init(weekNumber: Int, days: [CalendarDayItem]) {
        self.weekNumber = weekNumber
        self.days = days
    }
}

public struct CaDaoRecord: Identifiable, Codable, Equatable, Sendable {
    public var id: Int
    public var title: String
    public var content: String
    public var category: String
    public var url: String

    public init(id: Int, title: String, content: String, category: String, url: String) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.url = url
    }
}

public struct DayDirection: Codable, Equatable, Hashable, Sendable {
    public var huong: String
    public var than: String
    public var hyThan: String
    public var taiThan: String
    public var hacThan: String?

    public init(
        huong: String,
        than: String,
        hyThan: String? = nil,
        taiThan: String? = nil,
        hacThan: String? = nil
    ) {
        self.huong = huong
        self.than = than
        self.hyThan = hyThan ?? huong
        self.taiThan = taiThan ?? huong
        self.hacThan = hacThan
    }
}

public struct DayActivities: Codable, Equatable, Hashable, Sendable {
    public var trucName: String
    public var trucQuality: String
    public var yi: [String]
    public var ji: [String]

    public init(
        trucName: String = "",
        trucQuality: String = "",
        yi: [String],
        ji: [String]
    ) {
        self.trucName = trucName
        self.trucQuality = trucQuality
        self.yi = yi
        self.ji = ji
    }
}

public enum CalendarDateUnit: String, Codable, CaseIterable, Equatable, Sendable {
    case day
    case month
}

public struct LunarDaySnapshot: Equatable, Sendable {
    public var solarDate: Date
    public var day: Int
    public var month: Int
    public var year: Int
    public var weekdayVi: String
    public var weekdayEn: String
    public var monthVi: String
    public var monthEn: String

    public var lunarDate: LunarDate
    public var lunarMonthNameVi: String
    public var heroLunarText: String
    public var formattedLunarDate: String
    public var isLunarMonthFull: Bool

    public var canChiDay: String
    public var canChiMonth: String
    public var canChiYear: String

    public var dayHoangDaoStatus: DayHoangDaoStatus
    public var solarTerm: String
    public var hours: [LunarHourInfo]
    public var bestDepartureHour: LunarHourInfo?
    public var direction: DayDirection
    public var activities: DayActivities
    public var warning: String?
    public var weekInfo: CalendarWeekInfo

    public var userBirthYear: Int
    public var userZodiac: String
    public var userZodiacEmoji: String
    public var userNguHanh: String
    public var userNapAm: String
    public var userNguHanhEmoji: String

    public init(
        solarDate: Date,
        day: Int,
        month: Int,
        year: Int,
        weekdayVi: String,
        weekdayEn: String,
        monthVi: String,
        monthEn: String,
        lunarDate: LunarDate,
        lunarMonthNameVi: String,
        heroLunarText: String,
        formattedLunarDate: String,
        isLunarMonthFull: Bool,
        canChiDay: String,
        canChiMonth: String,
        canChiYear: String,
        dayHoangDaoStatus: DayHoangDaoStatus,
        solarTerm: String,
        hours: [LunarHourInfo],
        bestDepartureHour: LunarHourInfo?,
        direction: DayDirection,
        activities: DayActivities,
        warning: String?,
        weekInfo: CalendarWeekInfo,
        userBirthYear: Int,
        userZodiac: String,
        userZodiacEmoji: String,
        userNguHanh: String,
        userNapAm: String = "",
        userNguHanhEmoji: String
    ) {
        self.solarDate = solarDate
        self.day = day
        self.month = month
        self.year = year
        self.weekdayVi = weekdayVi
        self.weekdayEn = weekdayEn
        self.monthVi = monthVi
        self.monthEn = monthEn
        self.lunarDate = lunarDate
        self.lunarMonthNameVi = lunarMonthNameVi
        self.heroLunarText = heroLunarText
        self.formattedLunarDate = formattedLunarDate
        self.isLunarMonthFull = isLunarMonthFull
        self.canChiDay = canChiDay
        self.canChiMonth = canChiMonth
        self.canChiYear = canChiYear
        self.dayHoangDaoStatus = dayHoangDaoStatus
        self.solarTerm = solarTerm
        self.hours = hours
        self.bestDepartureHour = bestDepartureHour
        self.direction = direction
        self.activities = activities
        self.warning = warning
        self.weekInfo = weekInfo
        self.userBirthYear = userBirthYear
        self.userZodiac = userZodiac
        self.userZodiacEmoji = userZodiacEmoji
        self.userNguHanh = userNguHanh
        self.userNapAm = userNapAm
        self.userNguHanhEmoji = userNguHanhEmoji
    }
}

