import ComposableArchitecture
import Foundation

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {
        /// Phiên xác thực hiện tại; `nil` nghĩa là người dùng đang dùng chế độ khách.
        var session: AuthSession?
        /// Phản ánh Supabase đã được cấu hình để các thao tác tài khoản có thể hoạt động hay chưa.
        var isConfigured: Bool
        /// Trạng thái bận dùng chung cho đồng bộ hồ sơ, đăng xuất và bắt đầu thanh toán.
        var isBusy: Bool
        /// Nhà cung cấp thanh toán người dùng đang chọn cho thao tác nâng cấp Pro.
        var paymentMethod: BillingProvider
        /// Trạng thái gói thuê bao gần nhất tải từ backend; `nil` khi chưa tải hoặc chưa đăng nhập.
        var billing: BillingStatus?
        /// Thông báo lỗi gần nhất khi tải trạng thái gói hoặc bắt đầu checkout.
        var billingError: String?

        /// Alert TCA đang được trình bày cho kết quả đồng bộ hoặc lỗi đăng xuất.
        @Presents var alert: AlertState<Action.Alert>?

        init(
            session: AuthSession? = nil,
            isConfigured: Bool = true,
            isBusy: Bool = false,
            paymentMethod: BillingProvider = .payos,
            billing: BillingStatus? = nil,
            billingError: String? = nil,
            alert: AlertState<Action.Alert>? = nil
        ) {
            self.session = session
            self.isConfigured = isConfigured
            self.isBusy = isBusy
            self.paymentMethod = paymentMethod
            self.billing = billing
            self.billingError = billingError
            self.alert = alert
        }

        /// Cho biết có phiên đăng nhập để bật các thao tác tài khoản và billing.
        var isAuthenticated: Bool {
            session != nil
        }

        /// Cho biết gói hiện tại là Pro dựa trên trạng thái billing đã tải.
        var isPro: Bool {
            billing?.plan == .pro
        }

        /// Cho biết backend đang ghi nhận một checkout chưa hoàn tất.
        var isCheckoutPending: Bool {
            billing?.checkoutPending == true
        }

        /// Tiêu đề tài khoản đã được định dạng từ phiên đăng nhập hiện tại.
        var accountTitle: String {
            SettingsEngine.accountTitle(session: session)
        }

        /// Handle shown below the Settings hero title, matching the account email prefix in RN.
        var accountHandle: String {
            guard let email = session?.userEmail, !email.isEmpty else { return "@numelyra" }
            let prefix = email.split(separator: "@", maxSplits: 1).first ?? Substring("numelyra")
            return "@\(String(prefix))"
        }

        /// Detail shown in the personal-information row, matching the RN account/email copy.
        var accountRowDetail: String {
            session?.userEmail ?? (isConfigured ? "Đăng nhập để đồng bộ hồ sơ" : "Tài khoản khách")
        }

        /// Dòng mô tả trạng thái tài khoản, có xét cả đăng nhập và cấu hình Supabase.
        var accountHint: String {
            SettingsEngine.accountHint(
                isAuthenticated: isAuthenticated,
                isConfigured: isConfigured
            )
        }

        /// Nhãn hành động dành cho người dùng khách, phụ thuộc khả năng kết nối Supabase.
        var guestActionTitle: String {
            SettingsEngine.guestActionTitle(isConfigured: isConfigured)
        }

        /// Tiêu đề khối giới thiệu Pro thay đổi theo gói hiện tại.
        var proHeadlineTitle: String {
            isPro ? "Bạn đang dùng Pro ✦" : "Mở khóa hành trình đầy đủ"
        }

        /// Nhãn ngắn `PRO` hoặc `FREE` dùng trong badge của gói.
        var planBadgeTitle: String {
            isPro ? "PRO" : "FREE"
        }

        /// Mô tả thời hạn và trạng thái thuê bao đã được định dạng để hiển thị.
        var proSubscriptionSummary: String {
            SettingsEngine.proSubscriptionSummary(billing: billing)
        }

        /// Tiêu đề nút nâng cấp, phụ thuộc đăng nhập và phương thức thanh toán đang chọn.
        var upgradeButtonTitle: String {
            SettingsEngine.upgradeButtonTitle(
                isAuthenticated: isAuthenticated,
                paymentMethod: paymentMethod
            )
        }
    }

    enum Action: Equatable {
        case onAppear
        case appDidBecomeActive
        case sessionLoaded(AuthSession?)
        case requestLoginTapped
        case informationItemTapped(InformationItem)
        case syncProfilesTapped
        case syncProfilesCompleted
        case signOutTapped
        case signOutSucceeded
        case signOutFailed(String)
        case paymentMethodSelected(BillingProvider)
        case upgradeTapped
        case checkoutSucceeded
        case checkoutFailed(String)
        case refreshBillingTapped
        case billingResponse(Result<BillingStatus, BillingError>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert: Equatable, Sendable {
            case dismiss
        }

        enum InformationItem: Equatable, Sendable {
            case language
            case activity
            case privacy
            case help

            var title: String {
                switch self {
                case .language: "Ngôn ngữ"
                case .activity: "Hoạt động của bạn"
                case .privacy: "Quyền riêng tư"
                case .help: "Trợ giúp"
                }
            }

            var message: String {
                switch self {
                case .language:
                    "Ứng dụng hiện đang sử dụng Tiếng Việt."
                case .activity:
                    "12 lượt xem tarot tháng này\n8 lần xem chiêm tinh\n5 ngày mở lịch liên tiếp"
                case .privacy:
                    "Dữ liệu cá nhân của bạn được lưu và đồng bộ theo trạng thái tài khoản."
                case .help:
                    "Nếu bạn cần hỗ trợ, hãy gửi phản hồi từ trang NUMELYRA."
                }
            }
        }

        enum Delegate: Equatable, Sendable {
            case didRequestLogin
            case didSignOut
            case didSyncProfiles
        }
    }

    @Dependency(\.supabaseClient) var supabaseClient
    @Dependency(\.billingClient) var billingClient
    @Dependency(\.hapticClient) var hapticClient

    private nonisolated enum CancelID: Hashable, Sendable {
        case billingStatus
        case checkout
        case signOut
        case syncProfiles
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isConfigured = supabaseClient.isConfigured()

                let sessionAndBillingEffect: Effect<Action>
                if state.session != nil {
                    sessionAndBillingEffect = refreshBilling(&state)
                } else {
                    sessionAndBillingEffect = .run { send in
                        let restored = await supabaseClient.currentSession()
                        await send(.sessionLoaded(restored))
                    }
                }

                return sessionAndBillingEffect

            case .appDidBecomeActive:
                return refreshBilling(&state)

            case let .sessionLoaded(session):
                state.session = session
                return refreshBilling(&state)

            case .requestLoginTapped:
                return .send(.delegate(.didRequestLogin))

            case let .informationItemTapped(item):
                state.alert = .information(item.title, item.message)
                return .none

            case .syncProfilesTapped:
                guard state.isAuthenticated, !state.isBusy else { return .none }
                state.isBusy = true
                return .run { send in
                    await supabaseClient.syncLocalProfiles()
                    await send(.syncProfilesCompleted)
                }
                .cancellable(id: CancelID.syncProfiles, cancelInFlight: true)

            case .syncProfilesCompleted:
                state.isBusy = false
                state.alert = .syncSucceeded
                return .merge(
                    .send(.delegate(.didSyncProfiles)),
                    .run { _ in
                        await hapticClient.success()
                    }
                )

            case .signOutTapped:
                guard state.isAuthenticated, !state.isBusy else { return .none }
                state.isBusy = true
                return .merge(
                    .run { _ in
                        await hapticClient.lightImpact()
                    },
                    .run { send in
                        do {
                            try await supabaseClient.signOut()
                            await send(.signOutSucceeded)
                        } catch is CancellationError {
                            return
                        } catch {
                            let message = AuthError.from(
                                error,
                                fallback: "Vui lòng thử lại."
                            ).message
                            await send(.signOutFailed(message))
                        }
                    }
                    .cancellable(id: CancelID.signOut, cancelInFlight: true)
                )

            case .signOutSucceeded:
                state.isBusy = false
                state.session = nil
                state.billing = nil
                state.billingError = nil
                return .merge(
                    .cancel(id: CancelID.billingStatus),
                    .send(.delegate(.didSignOut))
                )

            case let .signOutFailed(message):
                state.isBusy = false
                state.alert = .signOutFailed(message)
                return .none

            case let .paymentMethodSelected(provider):
                state.paymentMethod = provider
                return .run { _ in
                    await hapticClient.selection()
                }

            case .upgradeTapped:
                guard !state.isBusy else { return .none }
                guard state.isAuthenticated else {
                    return .merge(
                        .send(.delegate(.didRequestLogin)),
                        .run { _ in
                            await hapticClient.mediumImpact()
                        }
                    )
                }

                let provider = state.paymentMethod
                state.isBusy = true
                state.billingError = nil
                return .merge(
                    .run { _ in
                        await hapticClient.mediumImpact()
                    },
                    .run { send in
                        do {
                            try await billingClient.beginCheckout(provider)
                            await send(.checkoutSucceeded)
                        } catch is CancellationError {
                            return
                        } catch {
                            let billingError = BillingError.from(
                                error,
                                fallback: BillingError.checkoutFallback.message
                            )
                            await send(.checkoutFailed(billingError.message))
                        }
                    }
                    .cancellable(id: CancelID.checkout, cancelInFlight: true)
                )

            case .checkoutSucceeded:
                state.isBusy = false
                return refreshBilling(&state)

            case let .checkoutFailed(message):
                state.isBusy = false
                if SettingsEngine.isAuthenticationRequiredError(message) {
                    return .send(.delegate(.didRequestLogin))
                }
                state.billingError = message
                return .none

            case .refreshBillingTapped:
                guard state.isAuthenticated, !state.isBusy else { return .none }
                return .merge(
                    refreshBilling(&state),
                    .run { _ in
                        await hapticClient.selection()
                    }
                )

            case let .billingResponse(.success(status)):
                guard state.isAuthenticated else { return .none }
                state.billing = status
                return .none

            case let .billingResponse(.failure(error)):
                guard state.isAuthenticated else { return .none }
                state.billingError = error.message
                return .none

            case .alert:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    // MARK: - Internal Effect Builders

    private func refreshBilling(_ state: inout State) -> Effect<Action> {
        guard state.isAuthenticated else {
            state.billing = nil
            state.billingError = nil
            return .cancel(id: CancelID.billingStatus)
        }
        state.billingError = nil
        return .run { send in
            do {
                let status = try await billingClient.getBillingStatus()
                await send(.billingResponse(.success(status)))
            } catch is CancellationError {
                return
            } catch {
                let billingError = BillingError.from(
                    error,
                    fallback: BillingError.statusFallback.message
                )
                await send(.billingResponse(.failure(billingError)))
            }
        }
        .cancellable(id: CancelID.billingStatus, cancelInFlight: true)
    }

}

// MARK: - AlertState Factories (`SettingsScreen.tsx:62, 73, 109`)

extension AlertState where Action == SettingsFeature.Action.Alert {
    static func information(_ title: String, _ message: String) -> Self {
        AlertState {
            TextState(title)
        } actions: {
            ButtonState(action: .dismiss) {
                TextState("Đóng")
            }
        } message: {
            TextState(message)
        }
    }

    static func signOutFailed(_ message: String) -> Self {
        AlertState {
            TextState("Không thể đăng xuất")
        } actions: {
            ButtonState(action: .dismiss) {
                TextState("OK")
            }
        } message: {
            TextState(message.isEmpty ? "Vui lòng thử lại." : message)
        }
    }

    static var syncSucceeded: Self {
        AlertState {
            TextState("Đã đồng bộ")
        } actions: {
            ButtonState(action: .dismiss) {
                TextState("OK")
            }
        } message: {
            TextState("Hồ sơ trên thiết bị đã được liên kết với tài khoản của bạn.")
        }
    }

}
