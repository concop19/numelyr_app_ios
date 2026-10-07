import ComposableArchitecture
import Foundation
import XCTest
@testable import numelyra_app_ios

@MainActor
final class SettingsFeatureTests: XCTestCase {
    func testOnAppearRestoresSessionLoadsReminderAndFetchesBillingStatus() async {
        let restoredSession = AuthSession(
            accessToken: "jwt-token-1",
            refreshToken: "refresh-token-1",
            userId: "user-1",
            userEmail: "an.nguyen@numelyra.online"
        )
        let loadedReminder = DailyReminderSettings(enabled: true, hour: 21, minute: 0)
        let proStatus = BillingStatus(
            authenticated: true,
            plan: .pro,
            canManageBilling: true,
            checkoutPending: false,
            subscription: SubscriptionDetail(
                provider: .payos,
                status: "active",
                currentPeriodEnd: "2026-11-06T00:00:00.000Z",
                cancelAtPeriodEnd: false
            )
        )

        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.supabaseClient.isConfigured = { true }
            $0.supabaseClient.currentSession = { restoredSession }
            $0.dailyNotificationClient.canUseNativeNotifications = { true }
            $0.dailyNotificationClient.loadSettings = { loadedReminder }
            $0.billingClient.getBillingStatus = { proStatus }
            $0.hapticClient = .testValue
        }

        await store.send(.onAppear)
        await store.receive(.dailyReminderLoaded(loadedReminder)) {
            $0.dailyReminder = loadedReminder
        }
        await store.receive(.sessionLoaded(restoredSession)) {
            $0.session = restoredSession
        }
        await store.receive(.billingResponse(.success(proStatus))) {
            $0.billing = proStatus
        }

        XCTAssertEqual(store.state.isPro, true)
        XCTAssertEqual(store.state.accountTitle, "an.nguyen@numelyra.online")
        XCTAssertEqual(store.state.reminderHint, "Lúc 21:00 theo giờ thiết bị")
    }

    func testDailyReminderPermissionDeniedPresentsAlertAndHourSelectionUpdatesTime() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.dailyNotificationClient.saveSettings = { requested in
                // Simulate OS permission denied when trying to enable
                if requested.enabled && requested.hour == 20 {
                    return DailyReminderSettings(enabled: false, hour: requested.hour, minute: requested.minute)
                }
                return requested
            }
        }

        // 1. Permission denied when enabling at 20:00 -> shows alert
        await store.send(.dailyReminderToggled(true))
        await store.receive(
            .dailyReminderSaved(
                requestedEnabled: true,
                saved: DailyReminderSettings(enabled: false, hour: 20, minute: 0)
            )
        ) {
            $0.alert = .notificationPermissionDenied
        }

        await store.send(.alert(.dismiss)) {
            $0.alert = nil
        }

        // 2. Selecting 18:00 updates hour
        await store.send(.dailyReminderHourSelected(18))
        await store.receive(
            .dailyReminderSaved(
                requestedEnabled: false,
                saved: DailyReminderSettings(enabled: false, hour: 18, minute: 0)
            )
        ) {
            $0.dailyReminder = DailyReminderSettings(enabled: false, hour: 18, minute: 0)
        }

        XCTAssertEqual(store.state.reminderHint, "Lúc 18:00 theo giờ thiết bị")
    }

    func testSyncProfilesAndSignOutFlows() async {
        let syncCount = LockIsolated(0)
        let successHapticCount = LockIsolated(0)
        let lightHapticCount = LockIsolated(0)
        let shouldFailSignOut = LockIsolated(true)

        let session = AuthSession(
            accessToken: "jwt-1",
            refreshToken: "ref-1",
            userId: "user-1",
            userEmail: "an.nguyen@numelyra.online"
        )
        let initialBilling = BillingStatus(authenticated: true, plan: .pro)

        let store = TestStore(
            initialState: SettingsFeature.State(
                session: session,
                billing: initialBilling
            )
        ) {
            SettingsFeature()
        } withDependencies: {
            $0.supabaseClient.syncLocalProfiles = {
                syncCount.withValue { $0 += 1 }
            }
            $0.supabaseClient.signOut = {
                if shouldFailSignOut.value {
                    throw AuthError(message: "Mất kết nối máy chủ.")
                }
            }
            $0.hapticClient.success = {
                successHapticCount.withValue { $0 += 1 }
            }
            $0.hapticClient.lightImpact = {
                lightHapticCount.withValue { $0 += 1 }
            }
        }

        // 1. Sync profiles
        await store.send(.syncProfilesTapped) {
            $0.isBusy = true
        }
        await store.receive(.syncProfilesCompleted) {
            $0.isBusy = false
            $0.alert = .syncSucceeded
        }
        await store.receive(.delegate(.didSyncProfiles))
        XCTAssertEqual(syncCount.value, 1)
        XCTAssertEqual(successHapticCount.value, 1)

        await store.send(.alert(.dismiss)) {
            $0.alert = nil
        }

        // 2. Sign-out failure -> alert
        await store.send(.signOutTapped) {
            $0.isBusy = true
        }
        await store.receive(.signOutFailed("Mất kết nối máy chủ.")) {
            $0.isBusy = false
            $0.alert = .signOutFailed("Mất kết nối máy chủ.")
        }
        XCTAssertEqual(lightHapticCount.value, 1)

        await store.send(.alert(.dismiss)) {
            $0.alert = nil
        }

        // 3. Sign-out success -> clears session & billing and emits delegate
        shouldFailSignOut.setValue(false)
        await store.send(.signOutTapped) {
            $0.isBusy = true
        }
        await store.receive(.signOutSucceeded) {
            $0.isBusy = false
            $0.session = nil
            $0.billing = nil
            $0.billingError = nil
        }
        await store.receive(.delegate(.didSignOut))
        XCTAssertEqual(lightHapticCount.value, 2)
    }

    func testGuestUpgradeAndAccountButtonRequestLogin() async {
        let mediumHapticCount = LockIsolated(0)

        let store = TestStore(initialState: SettingsFeature.State(session: nil)) {
            SettingsFeature()
        } withDependencies: {
            $0.hapticClient.mediumImpact = {
                mediumHapticCount.withValue { $0 += 1 }
            }
        }

        XCTAssertEqual(store.state.upgradeButtonTitle, "ĐĂNG NHẬP ĐỂ NÂNG CẤP")

        await store.send(.upgradeTapped)
        await store.receive(.delegate(.didRequestLogin))
        XCTAssertEqual(mediumHapticCount.value, 1)

        await store.send(.requestLoginTapped)
        await store.receive(.delegate(.didRequestLogin))
    }

    func testAuthenticatedCheckoutSuccessAndAuthErrorHandling() async {
        let capturedProvider = LockIsolated<BillingProvider?>(nil)
        let checkoutError = LockIsolated<String?>(nil)
        let session = AuthSession(
            accessToken: "jwt-1",
            refreshToken: "ref-1",
            userId: "user-1",
            userEmail: "an.nguyen@numelyra.online"
        )
        let updatedBilling = BillingStatus(
            authenticated: true,
            plan: .pro,
            subscription: SubscriptionDetail(
                provider: .paypal,
                status: "active",
                currentPeriodEnd: "2026-12-01T00:00:00.000Z"
            )
        )

        let store = TestStore(initialState: SettingsFeature.State(session: session)) {
            SettingsFeature()
        } withDependencies: {
            $0.hapticClient = .testValue
            $0.billingClient.beginCheckout = { provider in
                capturedProvider.setValue(provider)
                if let message = checkoutError.value {
                    throw BillingError(message: message)
                }
            }
            $0.billingClient.getBillingStatus = {
                updatedBilling
            }
        }

        // 1. Select PayPal
        await store.send(.paymentMethodSelected(.paypal)) {
            $0.paymentMethod = .paypal
        }
        XCTAssertEqual(store.state.upgradeButtonTitle, "ĐĂNG KÝ QUA PAYPAL")

        // 2. Checkout fails with auth error -> emits didRequestLogin instead of billingError
        checkoutError.setValue("not_authenticated: Vui lòng đăng nhập lại")
        await store.send(.upgradeTapped) {
            $0.isBusy = true
        }
        await store.receive(.checkoutFailed("not_authenticated: Vui lòng đăng nhập lại")) {
            $0.isBusy = false
        }
        await store.receive(.delegate(.didRequestLogin))
        XCTAssertNil(store.state.billingError)

        // 3. Checkout fails with generic error -> sets billingError
        checkoutError.setValue("Cổng thanh toán đang bảo trì.")
        await store.send(.upgradeTapped) {
            $0.isBusy = true
        }
        await store.receive(.checkoutFailed("Cổng thanh toán đang bảo trì.")) {
            $0.isBusy = false
            $0.billingError = "Cổng thanh toán đang bảo trì."
        }

        // 4. Checkout succeeds -> refreshes billing status
        checkoutError.setValue(nil)
        await store.send(.upgradeTapped) {
            $0.isBusy = true
            $0.billingError = nil
        }
        await store.receive(.checkoutSucceeded) {
            $0.isBusy = false
        }
        await store.receive(.billingResponse(.success(updatedBilling))) {
            $0.billing = updatedBilling
        }
        XCTAssertEqual(capturedProvider.value, .paypal)
    }

    func testSettingsEnginePureRules() {
        // 1. Partial/invalid reminder JSON normalization
        let invalidJSON = #"{"enabled":true,"hour":99,"minute":-5}"#.data(using: .utf8)
        let normalized = SettingsEngine.decodeReminderSettings(from: invalidJSON)
        XCTAssertEqual(normalized, DailyReminderSettings(enabled: true, hour: 20, minute: 0))

        // 2. Vietnamese date formatting & Pro summary
        let vnTimeZone = TimeZone(secondsFromGMT: 7 * 3600)!
        let proBilling = BillingStatus(
            authenticated: true,
            plan: .pro,
            subscription: SubscriptionDetail(
                provider: .payos,
                status: "active",
                currentPeriodEnd: "2026-11-06T00:00:00.000Z"
            )
        )
        XCTAssertEqual(
            SettingsEngine.proSubscriptionSummary(billing: proBilling, timeZone: vnTimeZone),
            "Pro qua VietQR / PayOS · hiệu lực đến 6/11/2026"
        )

        // 3. Auth-required error regex
        XCTAssertTrue(SettingsEngine.isAuthenticationRequiredError("Please sign in to continue"))
        XCTAssertTrue(SettingsEngine.isAuthenticationRequiredError("Vui lòng đăng nhập"))
        XCTAssertTrue(SettingsEngine.isAuthenticationRequiredError("error: NOT_AUTHENTICATED"))
        XCTAssertFalse(SettingsEngine.isAuthenticationRequiredError("Không thể mở trang thanh toán."))

        // 4. Checkout URL resolution
        let payosResponse = CheckoutResponse(checkoutUrl: "https://pay.payos.vn/web/123")
        let paypalResponse = CheckoutResponse(approvalUrl: "https://www.paypal.com/checkoutnow?token=abc")
        XCTAssertEqual(
            SettingsEngine.resolveCheckoutURL(from: payosResponse, provider: .payos)?.absoluteString,
            "https://pay.payos.vn/web/123"
        )
        XCTAssertNil(SettingsEngine.resolveCheckoutURL(from: payosResponse, provider: .paypal))
        XCTAssertEqual(
            SettingsEngine.resolveCheckoutURL(from: paypalResponse, provider: .paypal)?.absoluteString,
            "https://www.paypal.com/checkoutnow?token=abc"
        )
    }
}
