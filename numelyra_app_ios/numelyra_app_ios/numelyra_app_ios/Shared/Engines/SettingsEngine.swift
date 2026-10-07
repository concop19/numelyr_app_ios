import Foundation

public nonisolated enum SettingsEngine {
    public static let reminderStorageKey = "numelyra:daily-reminder:v1"
    public static let dailyNotificationIdentifier = "numelyra.daily-reminder"
    public static let presetReminderHours: [Int] = [18, 20, 21]
    public static let defaultReminderSettings = DailyReminderSettings(
        enabled: false,
        hour: 20,
        minute: 0
    )

    public static let notificationPayload = NotificationPayload(
        title: "Thử thách hôm nay đã sẵn sàng ✦",
        body: "Giữ chuỗi chơi của bạn cùng NUMELYRA.",
        url: AppConfig.dailyChallengeDeepLinkURL
    )

    // MARK: - Daily Reminder Settings Normalization & Formatting

    private struct PartialReminderPayload: Decodable {
        var enabled: Bool?
        var hour: Int?
        var minute: Int?
    }

    public static func normalizeReminderSettings(
        enabled: Bool?,
        hour: Int?,
        minute: Int?
    ) -> DailyReminderSettings {
        let resolvedEnabled = (enabled == true)
        let resolvedHour: Int
        if let hour, (0 ... 23).contains(hour) {
            resolvedHour = hour
        } else {
            resolvedHour = 20
        }

        let resolvedMinute: Int
        if let minute, (0 ... 59).contains(minute) {
            resolvedMinute = minute
        } else {
            resolvedMinute = 0
        }

        return DailyReminderSettings(
            enabled: resolvedEnabled,
            hour: resolvedHour,
            minute: resolvedMinute
        )
    }

    public static func decodeReminderSettings(from data: Data?) -> DailyReminderSettings {
        guard let data,
              let decoded = try? JSONDecoder().decode(PartialReminderPayload.self, from: data)
        else {
            return defaultReminderSettings
        }
        return normalizeReminderSettings(
            enabled: decoded.enabled,
            hour: decoded.hour,
            minute: decoded.minute
        )
    }

    public static func formatTime(hour: Int, minute: Int = 0) -> String {
        String(format: "%02d:%02d", hour, minute)
    }

    public static func reminderHint(
        settings: DailyReminderSettings,
        canUseNativeNotifications: Bool
    ) -> String {
        guard canUseNativeNotifications else {
            return "Khả dụng trên bản phát hành của ứng dụng"
        }
        return "Lúc \(formatTime(hour: settings.hour, minute: settings.minute)) theo giờ thiết bị"
    }

    // MARK: - Account Copy

    public static func accountTitle(session: AuthSession?) -> String {
        guard let session else {
            return "Tài khoản khách"
        }
        return session.userEmail ?? ""
    }

    public static func accountHint(isAuthenticated: Bool, isConfigured: Bool) -> String {
        if isAuthenticated {
            return "Hồ sơ trên thiết bị có thể đồng bộ"
        }
        return isConfigured
            ? "Đăng nhập để lưu hành trình trên mọi thiết bị"
            : "Dữ liệu hiện được lưu trên thiết bị này"
    }

    public static func guestActionTitle(isConfigured: Bool) -> String {
        isConfigured ? "Đăng nhập hoặc tạo tài khoản" : "Xem hướng dẫn cấu hình"
    }

    // MARK: - Pro Billing Copy & Helpers

    public static func parsePeriodEndDate(_ raw: String?) -> Date? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty
        else {
            return nil
        }

        let isoWithFractional = ISO8601DateFormatter()
        isoWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoWithFractional.date(from: trimmed) {
            return date
        }

        let isoStandard = ISO8601DateFormatter()
        isoStandard.formatOptions = [.withInternetDateTime]
        if let date = isoStandard.date(from: trimmed) {
            return date
        }

        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.calendar = Calendar(identifier: .gregorian)
        dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateOnlyFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        return dateOnlyFormatter.date(from: trimmed)
    }

    public static func formatActiveUntil(
        _ rawDateString: String?,
        timeZone: TimeZone = .current
    ) -> String? {
        guard let date = parsePeriodEndDate(rawDateString) else {
            return nil
        }
        let formatter = DateFormatter()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.timeZone = timeZone
        formatter.dateFormat = "d/M/yyyy"
        return formatter.string(from: date)
    }

    public static func proSubscriptionSummary(
        billing: BillingStatus?,
        timeZone: TimeZone = .current
    ) -> String {
        let providerLabel = (billing?.subscription?.provider == .payos)
            ? "Pro qua VietQR / PayOS"
            : "Pro qua PayPal"
        if let activeUntil = formatActiveUntil(
            billing?.subscription?.currentPeriodEnd,
            timeZone: timeZone
        ) {
            return "\(providerLabel) · hiệu lực đến \(activeUntil)"
        }
        return providerLabel
    }

    public static func upgradeButtonTitle(
        isAuthenticated: Bool,
        paymentMethod: BillingProvider
    ) -> String {
        guard isAuthenticated else {
            return "ĐĂNG NHẬP ĐỂ NÂNG CẤP"
        }
        return paymentMethod == .payos ? "THANH TOÁN VIETQR" : "ĐĂNG KÝ QUA PAYPAL"
    }

    public static func isAuthenticationRequiredError(_ message: String) -> Bool {
        let range = NSRange(message.startIndex ..< message.endIndex, in: message)
        guard let regex = try? NSRegularExpression(
            pattern: "sign in|đăng nhập|not_authenticated",
            options: [.caseInsensitive]
        ) else {
            return false
        }
        return regex.firstMatch(in: message, options: [], range: range) != nil
    }

    public static func resolveCheckoutURL(
        from response: CheckoutResponse,
        provider: BillingProvider
    ) -> URL? {
        let raw = (provider == .payos ? response.checkoutUrl : response.approvalUrl)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let raw,
              !raw.isEmpty,
              let url = URL(string: raw),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http"
        else {
            return nil
        }
        return url
    }
}
