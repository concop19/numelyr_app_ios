import ComposableArchitecture
import Foundation
import XCTest
@testable import numelyra_app_ios

@MainActor
final class SettingsFeatureTests: XCTestCase {
    func testOnAppearRestoresSessionAndFetchesBillingStatus() async {
        let restoredSession = AuthSession(
            accessToken: "jwt-token-1",
            refreshToken: "refresh-token-1",
            userId: "user-1",
            userEmail: "an.nguyen@numelyra.online"
        )
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
            $0.billingClient.getBillingStatus = { proStatus }
            $0.hapticClient = .testValue
        }

        await store.send(.onAppear)
        await store.receive(.sessionLoaded(restoredSession)) {
            $0.session = restoredSession
        }
        await store.receive(.billingResponse(.success(proStatus))) {
            $0.billing = proStatus
        }

        XCTAssertEqual(store.state.isPro, true)
        XCTAssertEqual(store.state.accountTitle, "an.nguyen@numelyra.online")
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

    func testUnconfiguredGuestStateUsesConfigurationGuidanceWithoutBillingRequest() async {
        let billingRequestCount = LockIsolated(0)
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.supabaseClient.isConfigured = { false }
            $0.supabaseClient.currentSession = { nil }
            $0.billingClient.getBillingStatus = {
                billingRequestCount.withValue { $0 += 1 }
                return BillingStatus(authenticated: false, plan: .free)
            }
        }

        await store.send(.onAppear) {
            $0.isConfigured = false
        }
        await store.receive(.sessionLoaded(nil))

        XCTAssertEqual(store.state.accountHint, "Dữ liệu hiện được lưu trên thiết bị này")
        XCTAssertEqual(store.state.guestActionTitle, "Xem hướng dẫn cấu hình")
        XCTAssertEqual(billingRequestCount.value, 0)
    }

    func testBillingFailureAndPendingStatusArePresentedInState() async {
        let session = AuthSession(
            accessToken: "",
            refreshToken: "",
            userId: "settings-test-user",
            userEmail: "reader@example.test"
        )
        let pendingStatus = BillingStatus(
            authenticated: true,
            plan: .free,
            checkoutPending: true
        )
        let store = TestStore(initialState: SettingsFeature.State(session: session)) {
            SettingsFeature()
        } withDependencies: {
            $0.supabaseClient.isConfigured = { true }
            $0.billingClient.getBillingStatus = {
                throw BillingError(message: "Không thể tải trạng thái gói Pro.")
            }
        }

        await store.send(.onAppear)
        await store.receive(.billingResponse(.failure(BillingError(message: "Không thể tải trạng thái gói Pro.")))) {
            $0.billingError = "Không thể tải trạng thái gói Pro."
        }

        await store.send(.billingResponse(.success(pendingStatus))) {
            $0.billing = pendingStatus
            $0.billingError = "Không thể tải trạng thái gói Pro."
        }
        XCTAssertTrue(store.state.isCheckoutPending)
    }

    func testInformationRowsUseRNAlertCopy() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }

        let cases: [(SettingsFeature.Action.InformationItem, String, String)] = [
            (.language, "Ngôn ngữ", "Ứng dụng hiện đang sử dụng Tiếng Việt."),
            (.activity, "Hoạt động của bạn", "12 lượt xem tarot tháng này\n8 lần xem chiêm tinh\n5 ngày mở lịch liên tiếp"),
            (.privacy, "Quyền riêng tư", "Dữ liệu cá nhân của bạn được lưu và đồng bộ theo trạng thái tài khoản."),
            (.help, "Trợ giúp", "Nếu bạn cần hỗ trợ, hãy gửi phản hồi từ trang NUMELYRA.")
        ]

        for (item, title, message) in cases {
            await store.send(.informationItemTapped(item)) {
                $0.alert = .information(title, message)
            }
            await store.send(.alert(.dismiss)) {
                $0.alert = nil
            }
        }
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
        let handleState = SettingsFeature.State(
            session: AuthSession(
                accessToken: "",
                refreshToken: "",
                userId: "settings-test-user",
                userEmail: "an.nguyen@example.test"
            )
        )
        XCTAssertEqual(handleState.accountHandle, "@an.nguyen")
        XCTAssertEqual(SettingsFeature.State().accountHandle, "@numelyra")

        // 1. Vietnamese date formatting & Pro summary
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

        // 2. Auth-required error regex
        XCTAssertTrue(SettingsEngine.isAuthenticationRequiredError("Please sign in to continue"))
        XCTAssertTrue(SettingsEngine.isAuthenticationRequiredError("Vui lòng đăng nhập"))
        XCTAssertTrue(SettingsEngine.isAuthenticationRequiredError("error: NOT_AUTHENTICATED"))
        XCTAssertFalse(SettingsEngine.isAuthenticationRequiredError("Không thể mở trang thanh toán."))

        // 3. Checkout URL resolution
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
