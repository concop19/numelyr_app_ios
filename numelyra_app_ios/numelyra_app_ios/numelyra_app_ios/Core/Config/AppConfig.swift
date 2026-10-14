import Foundation

nonisolated enum AppConfig {
    static let appName = "Numelyra"
    static let appVersion = "1.0.0"

    // Supabase configuration (actual project values matching React Native baseline)
    static let defaultSupabaseURL = URL(string: "https://irtppxiappokjazczdai.supabase.co")!
    static let defaultSupabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlydHBweGlhcHBva2phemN6ZGFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODczNTk2MjYsImV4cCI6MjEwMjkzNTYyNn0.NF2n5Dpd9ldG9rko09gpPmGotaaikC_waQqUNPB8BzE"
    static let authCallbackURL = URL(string: "numelyra://auth-callback")!
    static let authCallbackScheme = "numelyra"

    static var supabaseURL: URL? {
        let candidateKeys = ["SUPABASE_URL", "EXPO_PUBLIC_SUPABASE_URL"]
        for key in candidateKeys {
            if let raw = configString(forKey: key),
               let url = URL(string: raw),
               let scheme = url.scheme?.lowercased(),
               (scheme == "https" || scheme == "http"),
               url.host != nil
            {
                return url
            }
        }
        return defaultSupabaseURL
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
               !raw.isEmpty
            {
                return raw
            }
        }
        return defaultSupabaseAnonKey
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
        if let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let val = dict[key] as? String {
            let trimmed = val.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
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
        return URL(string: "https://numelyra.online")!
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
