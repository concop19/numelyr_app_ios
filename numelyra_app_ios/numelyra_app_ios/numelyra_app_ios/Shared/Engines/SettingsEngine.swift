import Foundation

public nonisolated enum SettingsEngine {
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

        if let date = ISO8601DateFormatter.appDate(from: trimmed) {
            return date
        }

        return DateFormatter.appStorageDate.date(from: trimmed)
    }

    public static func formatActiveUntil(
        _ rawDateString: String?,
        timeZone: TimeZone = .current
    ) -> String? {
        guard let date = parsePeriodEndDate(rawDateString) else {
            return nil
        }
        return DateFormatter.appVietnameseShortDate(timeZone: timeZone).string(from: date)
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
