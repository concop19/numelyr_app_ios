import ComposableArchitecture
import Foundation

@DependencyClient
public struct LunarClient: Sendable {
    public var solarToLunar: @Sendable (_ day: Int, _ month: Int, _ year: Int) -> LunarDate = { day, month, year in
        LunarService.solarToLunar(day: day, month: month, year: year)
    }

    public var daySnapshot: @Sendable (
        _ date: Date,
        _ birthDateString: String?,
        _ currentHour: Int?
    ) -> LunarDaySnapshot = { date, birthDateString, currentHour in
        LunarService.makeDaySnapshot(
            for: date,
            birthDateString: birthDateString,
            currentHour: currentHour
        )
    }

    public var moveDate: @Sendable (
        _ date: Date,
        _ amount: Int,
        _ unit: CalendarDateUnit
    ) -> Date = { date, amount, unit in
        LunarService.moveDate(date, amount: amount, unit: unit)
    }

    public var monthPickerDays: @Sendable (_ pickerDate: Date) -> [Date] = { pickerDate in
        LunarService.getMonthPickerDays(for: pickerDate)
    }

    public var weekInfo: @Sendable (_ date: Date) -> CalendarWeekInfo = { date in
        LunarService.getWeekInfo(for: date)
    }

    public var hoangDaoHours: @Sendable (
        _ day: Int,
        _ month: Int,
        _ year: Int,
        _ zodiac: String?
    ) -> [LunarHourInfo] = { day, month, year, zodiac in
        LunarService.getHoangDaoHours(day: day, month: month, year: year, zodiac: zodiac)
    }

    public var bestDepartureHour: @Sendable (
        _ day: Int,
        _ month: Int,
        _ year: Int,
        _ zodiac: String,
        _ currentHour: Int
    ) -> LunarHourInfo? = { day, month, year, zodiac, currentHour in
        LunarService.getBestDepartureHour(
            day: day,
            month: month,
            year: year,
            zodiac: zodiac,
            currentHour: currentHour
        )
    }
}

extension LunarClient: DependencyKey {
    public static let liveValue = Self(
        solarToLunar: { day, month, year in
            LunarService.solarToLunar(day: day, month: month, year: year)
        },
        daySnapshot: { date, birthDateString, currentHour in
            let now = Date()
            let nowComponents = LunarService.defaultCalendar.dateComponents([.hour, .minute], from: now)
            let resolvedHour = currentHour ?? (nowComponents.hour ?? 0)
            let resolvedMinute = currentHour == nil ? (nowComponents.minute ?? 0) : 0
            return LunarService.makeDaySnapshot(
                for: date,
                birthDateString: birthDateString,
                currentHour: resolvedHour,
                currentMinute: resolvedMinute,
                referenceDate: now
            )
        },
        moveDate: { date, amount, unit in
            LunarService.moveDate(date, amount: amount, unit: unit)
        },
        monthPickerDays: { pickerDate in
            LunarService.getMonthPickerDays(for: pickerDate)
        },
        weekInfo: { date in
            LunarService.getWeekInfo(for: date)
        },
        hoangDaoHours: { day, month, year, zodiac in
            LunarService.getHoangDaoHours(day: day, month: month, year: year, zodiac: zodiac)
        },
        bestDepartureHour: { day, month, year, zodiac, currentHour in
            LunarService.getBestDepartureHour(
                day: day,
                month: month,
                year: year,
                zodiac: zodiac,
                currentHour: currentHour
            )
        }
    )

    public static let previewValue = liveValue
    public static let testValue = Self()
}

public extension DependencyValues {
    var lunarClient: LunarClient {
        get { self[LunarClient.self] }
        set { self[LunarClient.self] = newValue }
    }
}
