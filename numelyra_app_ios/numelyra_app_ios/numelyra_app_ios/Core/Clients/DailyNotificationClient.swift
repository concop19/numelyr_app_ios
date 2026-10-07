import ComposableArchitecture
import Foundation
import UserNotifications

// MARK: - UserDefaults Daily Reminder Storage

public nonisolated enum DailyReminderStorage {
    public static func load(
        defaults: UserDefaults = .standard,
        key: String = SettingsEngine.reminderStorageKey
    ) -> DailyReminderSettings {
        if let data = defaults.data(forKey: key) {
            return SettingsEngine.decodeReminderSettings(from: data)
        }
        if let rawString = defaults.string(forKey: key),
           let data = rawString.data(using: .utf8)
        {
            return SettingsEngine.decodeReminderSettings(from: data)
        }
        return SettingsEngine.defaultReminderSettings
    }

    public static func save(
        _ settings: DailyReminderSettings,
        defaults: UserDefaults = .standard,
        key: String = SettingsEngine.reminderStorageKey
    ) -> DailyReminderSettings {
        let normalized = SettingsEngine.normalizeReminderSettings(
            enabled: settings.enabled,
            hour: settings.hour,
            minute: settings.minute
        )
        if let data = try? JSONEncoder().encode(normalized),
           let jsonString = String(data: data, encoding: .utf8)
        {
            defaults.set(jsonString, forKey: key)
        }
        return normalized
    }
}

// MARK: - Native Notification Scheduler (`dailyNotifications.ts`)

public nonisolated enum DailyNotificationService {
    public static func saveAndSchedule(
        _ settings: DailyReminderSettings,
        canUseNativeNotifications: Bool = true
    ) async -> DailyReminderSettings {
        let normalizedInput = SettingsEngine.normalizeReminderSettings(
            enabled: settings.enabled,
            hour: settings.hour,
            minute: settings.minute
        )

        guard canUseNativeNotifications else {
            let disabled = DailyReminderSettings(
                enabled: false,
                hour: normalizedInput.hour,
                minute: normalizedInput.minute
            )
            return DailyReminderStorage.save(disabled)
        }

        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        var isEnabled = normalizedInput.enabled
        if isEnabled {
            let currentSettings = await center.notificationSettings()
            let isAlreadyAuthorized: Bool = {
                switch currentSettings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    return true
                case .notDetermined, .denied:
                    return false
                @unknown default:
                    return false
                }
            }()

            if isAlreadyAuthorized {
                isEnabled = true
            } else {
                isEnabled = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            }

            if isEnabled {
                let content = UNMutableNotificationContent()
                content.title = SettingsEngine.notificationPayload.title
                content.body = SettingsEngine.notificationPayload.body
                content.userInfo = ["url": SettingsEngine.notificationPayload.url]

                var dateComponents = DateComponents()
                dateComponents.hour = normalizedInput.hour
                dateComponents.minute = normalizedInput.minute

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents,
                    repeats: true
                )
                let request = UNNotificationRequest(
                    identifier: SettingsEngine.dailyNotificationIdentifier,
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        }

        let stored = DailyReminderSettings(
            enabled: isEnabled,
            hour: normalizedInput.hour,
            minute: normalizedInput.minute
        )
        return DailyReminderStorage.save(stored)
    }
}

// MARK: - TCA DependencyClient

@DependencyClient
nonisolated struct DailyNotificationClient: Sendable {
    var canUseNativeNotifications: @Sendable () -> Bool = { true }
    var loadSettings: @Sendable () async -> DailyReminderSettings = {
        SettingsEngine.defaultReminderSettings
    }
    var saveSettings: @Sendable (_ settings: DailyReminderSettings) async -> DailyReminderSettings = { settings in
        settings
    }
}

extension DailyNotificationClient: DependencyKey {
    static let liveValue = Self(
        canUseNativeNotifications: { true },
        loadSettings: {
            DailyReminderStorage.load()
        },
        saveSettings: { settings in
            await DailyNotificationService.saveAndSchedule(settings)
        }
    )

    static let testValue = Self()

    static let previewValue = Self(
        canUseNativeNotifications: { true },
        loadSettings: {
            DailyReminderSettings(enabled: true, hour: 20, minute: 0)
        },
        saveSettings: { settings in
            settings
        }
    )
}

extension DependencyValues {
    var dailyNotificationClient: DailyNotificationClient {
        get { self[DailyNotificationClient.self] }
        set { self[DailyNotificationClient.self] = newValue }
    }
}
