import Foundation

nonisolated enum AppConfig {
    static let appName = "Numelyra"
    static let appVersion = "1.0.0"

    // Supabase configuration placeholders (actual values loaded from environment or Info.plist)
    static let defaultSupabaseURL = URL(string: "https://your-project.supabase.co")!
    static let defaultSupabaseAnonKey = "ANON_KEY_PLACEHOLDER"
    static let authCallbackURL = URL(string: "numelyra://auth-callback")!
    static let authCallbackScheme = "numelyra"

    static var supabaseURL: URL? {
        let candidateKeys = ["SUPABASE_URL", "EXPO_PUBLIC_SUPABASE_URL"]
        for key in candidateKeys {
            if let raw = configString(forKey: key),
               raw != defaultSupabaseURL.absoluteString,
               let url = URL(string: raw),
               let scheme = url.scheme?.lowercased(),
               (scheme == "https" || scheme == "http"),
               url.host != nil
            {
                return url
            }
        }
        return nil
    }

    static var supabaseAnonKey: String? {
        let candidateKeys = [
            "SUPABASE_PUBLISHABLE_KEY",
            "SUPABASE_ANON_KEY",
            "EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY",
            "EXPO_PUBLIC_SUPABASE_ANON_KEY"
        ]
        for key in candidateKeys {
            if let raw = configString(forKey: key),
               raw != defaultSupabaseAnonKey
            {
                return raw
            }
        }
        return nil
    }

    static var isSupabaseConfigured: Bool {
        supabaseURL != nil && supabaseAnonKey != nil
    }

    private static func configString(forKey key: String) -> String? {
        if let env = ProcessInfo.processInfo.environment[key]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !env.isEmpty
        {
            return env
        }
        if let plistValue = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmed = plistValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !trimmed.hasPrefix("$(") {
                return trimmed
            }
        }
        return nil
    }

    static var apiBaseURL: URL {
        if let configured = ProcessInfo.processInfo.environment["NUMELYRA_API_URL"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !configured.isEmpty,
           let url = URL(string: configured)
        {
            return url
        }
#if DEBUG
        return URL(string: "http://localhost:3200")!
#else
        return URL(string: "https://numelyra.online")!
#endif
    }

    static var astroFortuneURL: URL {
        apiBaseURL.appending(path: "api/astro/fortune")
    }

    static var chatClassifyURL: URL { apiBaseURL.appending(path: "api/chat/classify") }
    static var chatAgentURL: URL { apiBaseURL.appending(path: "api/chat/agent") }

    static var luckyWallpaperURL: URL {
        apiBaseURL.appending(path: "api/lucky-wallpaper/generate")
    }

    static var billingSubscriptionURL: URL {
        apiBaseURL.appending(path: "api/billing/subscription")
    }

    static var payosCheckoutURL: URL {
        apiBaseURL.appending(path: "api/billing/payos/checkout")
    }

    static var paypalCheckoutURL: URL {
        apiBaseURL.appending(path: "api/billing/paypal/checkout")
    }

    static let dailyChallengeDeepLinkURL = "numelyra://games/daily"

    static var calendarAssetBaseURL: URL {
        if let configured = ProcessInfo.processInfo.environment["NUMELYRA_CALENDAR_ASSET_BASE_URL"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !configured.isEmpty,
           let url = URL(string: configured)
        {
            return url
        }
        return CalendarArtEngine.defaultBaseURL
    }

}
