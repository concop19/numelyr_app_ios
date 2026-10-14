import ComposableArchitecture
import Foundation

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {
        var session: AuthSession?
        var isConfigured: Bool
        var isBusy: Bool
        var paymentMethod: BillingProvider
        var billing: BillingStatus?
        var billingError: String?

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

        var isAuthenticated: Bool {
            session != nil
        }

        var isPro: Bool {
            billing?.plan == .pro
        }

        var isCheckoutPending: Bool {
            billing?.checkoutPending == true
        }

        var accountTitle: String {
            SettingsEngine.accountTitle(session: session)
        }

        var accountHint: String {
            SettingsEngine.accountHint(
                isAuthenticated: isAuthenticated,
                isConfigured: isConfigured
            )
        }

        var guestActionTitle: String {
            SettingsEngine.guestActionTitle(isConfigured: isConfigured)
        }

        var proHeadlineTitle: String {
            isPro ? "Bạn đang dùng Pro ✦" : "Mở khóa hành trình đầy đủ"
        }

        var planBadgeTitle: String {
            isPro ? "PRO" : "FREE"
        }

        var proSubscriptionSummary: String {
            SettingsEngine.proSubscriptionSummary(billing: billing)
        }

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
