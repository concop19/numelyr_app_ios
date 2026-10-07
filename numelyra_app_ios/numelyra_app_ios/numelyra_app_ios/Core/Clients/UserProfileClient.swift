import ComposableArchitecture
import Foundation

/// Quản lý hồ sơ người dùng đang được kích hoạt (Active Profile),
/// tương ứng với `src/store/userProfile.ts` trong dự án React Native.
public nonisolated enum UserProfileStorage {
    public static let legacyProfileKey = "@tieu_linh_mieu_profile"
    public static let profilesListKey = "@numelyra_profiles_list"
    public static let activeProfileIDKey = "@numelyra_active_profile_id"

    private struct StoredProfilePayload: Codable {
        var id: String?
        var fullName: String
        var birthDate: String
        var gender: Gender?
        var isDefault: Bool?
        var birthTime: String?
        var birthPlace: String?
        var birthLocation: BirthLocationReference?
        var birthTimeAccuracy: BirthTimeAccuracy?

        func toUserProfile(fallbackID: String = "default-profile", defaultFlag: Bool = false) -> UserProfile {
            UserProfile(
                id: id ?? fallbackID,
                fullName: fullName,
                birthDate: birthDate,
                gender: gender,
                isDefault: isDefault ?? defaultFlag,
                birthTime: birthTime,
                birthPlace: birthPlace,
                birthLocation: birthLocation,
                birthTimeAccuracy: birthTimeAccuracy
            )
        }
    }

    public static func loadAllProfiles(defaults: UserDefaults = .standard) -> [UserProfile] {
        if let rawList = defaults.string(forKey: profilesListKey),
           let data = rawList.data(using: .utf8),
           let payloads = try? JSONDecoder().decode([StoredProfilePayload].self, from: data),
           !payloads.isEmpty
        {
            return payloads.enumerated().map { idx, item in
                item.toUserProfile(fallbackID: "profile-\(idx)")
            }
        }

        if let rawData = defaults.data(forKey: profilesListKey),
           let payloads = try? JSONDecoder().decode([StoredProfilePayload].self, from: rawData),
           !payloads.isEmpty
        {
            return payloads.enumerated().map { idx, item in
                item.toUserProfile(fallbackID: "profile-\(idx)")
            }
        }

        if let legacy = loadLegacyProfile(defaults: defaults),
           !legacy.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            let migrated = UserProfile(
                id: "default-profile",
                fullName: legacy.fullName,
                birthDate: legacy.birthDate,
                gender: legacy.gender,
                isDefault: true,
                birthTime: legacy.birthTime,
                birthPlace: legacy.birthPlace,
                birthLocation: legacy.birthLocation,
                birthTimeAccuracy: legacy.birthTimeAccuracy
            )
            saveAllProfiles([migrated], defaults: defaults)
            defaults.set(migrated.id, forKey: activeProfileIDKey)
            return [migrated]
        }

        return []
    }

    public static func loadLegacyProfile(defaults: UserDefaults = .standard) -> UserProfile? {
        if let raw = defaults.string(forKey: legacyProfileKey),
           let data = raw.data(using: .utf8),
           let payload = try? JSONDecoder().decode(StoredProfilePayload.self, from: data)
        {
            return payload.toUserProfile(fallbackID: "default-profile", defaultFlag: true)
        }
        if let data = defaults.data(forKey: legacyProfileKey),
           let payload = try? JSONDecoder().decode(StoredProfilePayload.self, from: data)
        {
            return payload.toUserProfile(fallbackID: "default-profile", defaultFlag: true)
        }
        return nil
    }

    public static func activeProfileID(defaults: UserDefaults = .standard) -> String? {
        defaults.string(forKey: activeProfileIDKey)
    }

    public static func activeProfile(defaults: UserDefaults = .standard) -> UserProfile? {
        let all = loadAllProfiles(defaults: defaults)
        guard !all.isEmpty else { return nil }
        let activeID = defaults.string(forKey: activeProfileIDKey)
        if let activeID, let found = all.first(where: { $0.id == activeID }) {
            return found
        }
        return all.first
    }

    public static func hasProfile(defaults: UserDefaults = .standard) -> Bool {
        guard let profile = activeProfile(defaults: defaults) ?? loadLegacyProfile(defaults: defaults) else {
            return false
        }
        return !profile.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !profile.birthDate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public static func saveAllProfiles(_ profiles: [UserProfile], defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(profiles),
              let json = String(data: data, encoding: .utf8)
        else { return }
        defaults.set(json, forKey: profilesListKey)
    }

    public static func setActiveProfileID(_ id: String, defaults: UserDefaults = .standard) {
        defaults.set(id, forKey: activeProfileIDKey)
        let all = loadAllProfiles(defaults: defaults)
        if let found = all.first(where: { $0.id == id }),
           let data = try? JSONEncoder().encode(found),
           let json = String(data: data, encoding: .utf8)
        {
            defaults.set(json, forKey: legacyProfileKey)
        }
    }

    public static func addProfile(_ profile: UserProfile, defaults: UserDefaults = .standard) throws -> UserProfile {
        let name = profile.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty,
              let date = ISO8601DateFormatter.chatDate.date(from: profile.birthDate)
        else { throw ChatError.invalidProfile }
        if let birthTime = profile.birthTime, !birthTime.isEmpty {
            let values = birthTime.split(separator: ":").compactMap { Int($0) }
            guard values.count == 2, (0...23).contains(values[0]), (0...59).contains(values[1]) else { throw ChatError.invalidProfile }
        }
        var value = profile
        value.fullName = name
        value.birthDate = ISO8601DateFormatter.chatDate.string(from: date)
        var profiles = loadAllProfiles(defaults: defaults)
        profiles.append(value)
        saveAllProfiles(profiles, defaults: defaults)
        if profiles.count == 1 { setActiveProfileID(value.id, defaults: defaults) }
        return value
    }

    public static func deleteProfile(_ id: String, defaults: UserDefaults = .standard) -> [UserProfile] {
        var profiles = loadAllProfiles(defaults: defaults)
        guard profiles.count > 1 else { return profiles }
        profiles.removeAll { $0.id == id }
        saveAllProfiles(profiles, defaults: defaults)
        if activeProfileID(defaults: defaults) == id, let first = profiles.first {
            setActiveProfileID(first.id, defaults: defaults)
        }
        return profiles
    }
}

private extension ISO8601DateFormatter {
    static let chatDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter
    }()
}

@DependencyClient
public struct UserProfileClient: Sendable {
    public var activeProfile: @Sendable () -> UserProfile? = {
        UserProfileStorage.activeProfile()
    }

    public var hasProfile: @Sendable () -> Bool = {
        UserProfileStorage.hasProfile()
    }

    public var loadAllProfiles: @Sendable () -> [UserProfile] = {
        UserProfileStorage.loadAllProfiles()
    }

    public var saveAllProfiles: @Sendable (_ profiles: [UserProfile]) -> Void = { profiles in
        UserProfileStorage.saveAllProfiles(profiles)
    }

    public var setActiveProfileID: @Sendable (_ id: String) -> Void = { id in
        UserProfileStorage.setActiveProfileID(id)
    }
    public var addProfile: @Sendable (_ profile: UserProfile) throws -> UserProfile
    public var deleteProfile: @Sendable (_ id: String) -> [UserProfile] = { _ in [] }
}

extension UserProfileClient: DependencyKey {
    public static let liveValue = Self(
        activeProfile: {
            UserProfileStorage.activeProfile()
        },
        hasProfile: {
            UserProfileStorage.hasProfile()
        },
        loadAllProfiles: {
            UserProfileStorage.loadAllProfiles()
        },
        saveAllProfiles: { profiles in
            UserProfileStorage.saveAllProfiles(profiles)
        },
        setActiveProfileID: { id in
            UserProfileStorage.setActiveProfileID(id)
        },
        addProfile: { try UserProfileStorage.addProfile($0) },
        deleteProfile: { UserProfileStorage.deleteProfile($0) }
    )

    public static let previewValue = Self(
        activeProfile: {
            UserProfile(
                id: "preview-active-profile",
                fullName: "Nguyễn Văn An",
                birthDate: "1998-10-20",
                gender: .male,
                isDefault: true
            )
        },
        hasProfile: { true },
        loadAllProfiles: {
            [
                UserProfile(
                    id: "preview-active-profile",
                    fullName: "Nguyễn Văn An",
                    birthDate: "1998-10-20",
                    gender: .male,
                    isDefault: true
                )
            ]
        },
        saveAllProfiles: { _ in },
        setActiveProfileID: { _ in },
        addProfile: { $0 },
        deleteProfile: { _ in [] }
    )

    public static let testValue = Self()
}

public extension DependencyValues {
    var userProfileClient: UserProfileClient {
        get { self[UserProfileClient.self] }
        set { self[UserProfileClient.self] = newValue }
    }
}
