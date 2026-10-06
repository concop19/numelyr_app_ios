import Foundation

nonisolated enum AstroFortuneCachePolicy: Equatable, Sendable {
    case useCache
    case reloadIgnoringCache
}

nonisolated enum AstrologyCacheKey {
    static func localDateKey(_ date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    static func legacyProfileKey(_ profile: UserProfile?) -> String {
        let locale = Locale(identifier: "vi_VN")
        let name = profile?.fullName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(with: locale)
        let birthDate = profile?.birthDate.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(name?.isEmpty == false ? name! : "guest")|\(birthDate?.isEmpty == false ? birthDate! : "unknown-date")"
    }

    static func profileKey(_ profile: UserProfile?) -> String {
        legacyProfileKey(profile)
    }

    static func profileFingerprint(_ profile: UserProfile?) -> String {
        guard let profile else {
            return fnv1a("guest|unknown-date|unknown-time|unknown-place|unknown|porphyry|\(AstrologyEngine.engineVersion)")
        }
        let values = [
            profile.id,
            profile.birthDate.trimmingCharacters(in: .whitespacesAndNewlines),
            profile.birthTime?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown-time",
            profile.birthLocation?.placeID ?? "unknown-place",
            profile.effectiveBirthTimeAccuracy.rawValue,
            AstroHouseSystem.porphyry.rawValue,
            AstrologyEngine.engineVersion,
        ]
        return fnv1a(values.joined(separator: "|"))
    }

    static func current(_ date: Date, profile: UserProfile?, calendar: Calendar = .current) -> String {
        "@astro_fortune_v4_\(localDateKey(date, calendar: calendar))_\(profileFingerprint(profile))"
    }

    static func version3(_ date: Date, profile: UserProfile?, calendar: Calendar = .current) -> String {
        "@astro_fortune_v3_\(localDateKey(date, calendar: calendar))_\(fnv1a(legacyProfileKey(profile)))"
    }

    static func version2(_ date: Date, profile: UserProfile?, calendar: Calendar = .current) -> String {
        "@astro_fortune_v2_\(localDateKey(date, calendar: calendar))_\(fnv1a(legacyProfileKey(profile)))"
    }

    static func natal(_ profile: UserProfile?) -> String {
        "@astro_natal_v1_\(profileFingerprint(profile))"
    }

    /// JavaScript baseline hashes UTF-16 code units (`charCodeAt`), not UTF-8 bytes.
    private static func fnv1a(_ value: String) -> String {
        var hash: UInt32 = 2_166_136_261
        for codeUnit in value.utf16 {
            hash ^= UInt32(codeUnit)
            hash = hash &* 16_777_619
        }
        return String(format: "%08x", hash)
    }
}

actor AstrologyFortuneCache {
    private let defaults: UserDefaults
    private var calendar: Calendar
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
    }

    func load(date: Date, profile: UserProfile?) -> AstroFortuneSlip? {
        let key = AstrologyCacheKey.current(date, profile: profile, calendar: calendar)
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(AstroFortuneSlip.self, from: data)
    }

    func save(_ fortune: AstroFortuneSlip, date: Date, profile: UserProfile?) throws {
        let key = AstrologyCacheKey.current(date, profile: profile, calendar: calendar)
        defaults.set(try encoder.encode(fortune), forKey: key)
    }

    func loadNatal(profile: UserProfile?) -> AstroNatalSnapshot? {
        guard let data = defaults.data(forKey: AstrologyCacheKey.natal(profile)) else { return nil }
        return try? decoder.decode(AstroNatalSnapshot.self, from: data)
    }

    func saveNatal(_ snapshot: AstroNatalSnapshot, profile: UserProfile?) throws {
        defaults.set(try encoder.encode(snapshot), forKey: AstrologyCacheKey.natal(profile))
    }

    func recentAdvice(date: Date, profile: UserProfile?, limit: Int = 7) -> [String] {
        guard limit > 0 else { return [] }
        var results: [String] = []
        var seen: Set<String> = []
        let locale = Locale(identifier: "vi_VN")

        for offset in 1 ... limit {
            guard let previousDate = calendar.date(byAdding: .day, value: -offset, to: date) else { continue }
            let keys = [
                AstrologyCacheKey.current(previousDate, profile: profile, calendar: calendar),
                AstrologyCacheKey.version3(previousDate, profile: profile, calendar: calendar),
                AstrologyCacheKey.version2(previousDate, profile: profile, calendar: calendar),
            ]
            for key in keys {
                guard let data = defaults.data(forKey: key),
                      let fortune = try? decoder.decode(AstroFortuneSlip.self, from: data)
                else { continue }
                let advice = String(fortune.advice.trimmingCharacters(in: .whitespacesAndNewlines).prefix(500))
                let normalized = advice.lowercased(with: locale)
                if !normalized.isEmpty, seen.insert(normalized).inserted {
                    results.append(advice)
                }
                break
            }
        }
        return Array(results.prefix(limit))
    }
}
