import Foundation

nonisolated enum AppDateFormat: String, Sendable {
    case storageDate = "yyyy-MM-dd"
    case hourMinute = "HH:mm"
    case vietnameseShortDate = "d/M/yyyy"
}

nonisolated enum AppISO8601Format: Sendable {
    case standard
    case fractionalSeconds
}

extension Locale {
    nonisolated static let appPOSIX = Locale(identifier: "en_US_POSIX")
    nonisolated static let appVietnamese = Locale(identifier: "vi_VN")
}

extension DateFormatter {
    nonisolated static var appStorageDate: DateFormatter {
        appFormatter(
            format: .storageDate,
            locale: .appPOSIX,
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
    }

    nonisolated static func appLocalDateKey(
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> DateFormatter {
        appFormatter(
            format: .storageDate,
            locale: .appPOSIX,
            timeZone: timeZone
        )
    }

    nonisolated static func appBirthTime(
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> DateFormatter {
        appFormatter(
            format: .hourMinute,
            locale: .appPOSIX,
            timeZone: timeZone
        )
    }

    nonisolated static func appMessageTime(
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> DateFormatter {
        appFormatter(
            format: .hourMinute,
            locale: .appVietnamese,
            timeZone: timeZone
        )
    }

    nonisolated static func appVietnameseShortDate(
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> DateFormatter {
        appFormatter(
            format: .vietnameseShortDate,
            locale: .appVietnamese,
            timeZone: timeZone
        )
    }

    nonisolated static func appStorageDateString(
        year: Int,
        month: Int,
        day: Int
    ) -> String? {
        let formatter = appStorageDate
        let components = DateComponents(
            calendar: formatter.calendar,
            timeZone: formatter.timeZone,
            year: year,
            month: month,
            day: day
        )
        guard let date = formatter.calendar.date(from: components) else {
            return nil
        }
        let resolved = formatter.calendar.dateComponents([.year, .month, .day], from: date)
        guard resolved.year == year,
              resolved.month == month,
              resolved.day == day
        else {
            return nil
        }
        return formatter.string(from: date)
    }

    private nonisolated static func appFormatter(
        format: AppDateFormat,
        locale: Locale,
        timeZone: TimeZone
    ) -> DateFormatter {
        let formatter = DateFormatter()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = format.rawValue
        formatter.isLenient = false
        return formatter
    }
}

extension ISO8601DateFormatter {
    nonisolated static func appFormatter(
        _ format: AppISO8601Format = .standard
    ) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        switch format {
        case .standard:
            formatter.formatOptions = [.withInternetDateTime]
        case .fractionalSeconds:
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        }
        return formatter
    }

    nonisolated static func appDate(from value: String) -> Date? {
        appFormatter(.fractionalSeconds).date(from: value)
            ?? appFormatter(.standard).date(from: value)
    }
}
