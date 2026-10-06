import Foundation

nonisolated enum AppConfig {
    static let appName = "Numelyra"
    static let appVersion = "1.0.0"

    // Supabase configuration placeholders (actual values loaded from environment or keychain)
    static let defaultSupabaseURL = URL(string: "https://your-project.supabase.co")!
    static let defaultSupabaseAnonKey = "ANON_KEY_PLACEHOLDER"

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

}
