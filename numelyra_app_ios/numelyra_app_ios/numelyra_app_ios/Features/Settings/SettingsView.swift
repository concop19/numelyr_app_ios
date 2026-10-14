import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.Colors.Settings.safeAreaBackground
                .ignoresSafeArea()

            AppTheme.Gradients.Settings.screenGradient
                .ignoresSafeArea()
                .allowsHitTesting(false)

            skyDecorations
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroHeader

                    sectionGroupTitle("TÀI KHOẢN")
                    accountCard

                    sectionGroupTitle("NUMELYRA PRO")
                    proCard
                }
                .padding(.horizontal, 17)
                .padding(.top, 12)
                .padding(.bottom, 34)
                .frame(maxWidth: AppTheme.Size.contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            store.send(.onAppear)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.send(.appDidBecomeActive)
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    // MARK: - Sky Decorative Layer (`SettingsScreen.tsx:121-127, 299-305`)

    private var skyDecorations: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Ellipse()
                    .stroke(AppTheme.Colors.Settings.orbitBorder, lineWidth: 1)
                    .frame(width: 330, height: 250)
                    .rotationEffect(.degrees(25))
                    .position(
                        x: proxy.size.width + 92 - 165,
                        y: -105 + 125
                    )

                Text("☾")
                    .font(.system(size: 86))
                    .foregroundStyle(AppTheme.Colors.Settings.moonColor)
                    .rotationEffect(.degrees(-18))
                    .opacity(0.95)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 12)
                    .padding(.trailing, 22)

                Text("✦")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.Colors.Settings.starOneColor)
                    .padding(.top, 112)
                    .padding(.leading, 26)

                Text("✧")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.Colors.Settings.starTwoColor)
                    .padding(.top, 76)
                    .padding(.leading, 164)

                Text("✦")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.Colors.Settings.starThreeColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 188)
                    .padding(.trailing, 52)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .clipped()
        }
    }

    // MARK: - Hero Header (`SettingsScreen.tsx:129-132`)

    private var heroHeader: some View {
        VStack(spacing: 5) {
            Text("Cài đặt")
                .font(.system(size: 35, weight: .black))
                .kerning(0.2)
                .foregroundStyle(AppTheme.Colors.Settings.titleText)
                .multilineTextAlignment(.center)

            Text("Tùy chỉnh hành trình NUMELYRA theo cách của bạn")
                .font(.system(size: 14))
                .lineSpacing(3)
                .foregroundStyle(AppTheme.Colors.Settings.subtitleText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 22)
        .padding(.top, 9)
        .padding(.bottom, 26)
    }

    private func sectionGroupTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .black))
            .kerning(1.05)
            .foregroundStyle(AppTheme.Colors.Settings.groupTitleText)
            .padding(.leading, 5)
            .padding(.bottom, 9)
    }

    // MARK: - Account Card (`SettingsScreen.tsx:161-183`)

    private var accountCard: some View {
        SettingsCardContainer {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    settingIconBadge(
                        systemName: store.isAuthenticated ? "person" : "person.badge.plus",
                        iconColor: AppTheme.Colors.Settings.profileIconTint,
                        backgroundColor: AppTheme.Colors.Settings.profileIconBackground,
                        borderColor: AppTheme.Colors.Settings.profileIconBorder
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.accountTitle)
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(AppTheme.Colors.Settings.titleText)
                            .lineLimit(1)

                        Text(store.accountHint)
                            .font(.system(size: 12))
                            .lineSpacing(2)
                            .foregroundStyle(AppTheme.Colors.Settings.hintText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 58)

                rowDivider

                if store.isAuthenticated {
                    VStack(spacing: 0) {
                        accountActionButton(
                            label: "Đồng bộ hồ sơ",
                            danger: false,
                            disabled: store.isBusy
                        ) {
                            store.send(.syncProfilesTapped)
                        }

                        accountActionButton(
                            label: "Đăng xuất",
                            danger: true,
                            disabled: store.isBusy
                        ) {
                            store.send(.signOutTapped)
                        }
                    }
                    .padding(.top, -2)
                } else {
                    Button {
                        store.send(.requestLoginTapped)
                    } label: {
                        HStack {
                            Text(store.guestActionTitle)
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(AppTheme.Colors.Settings.actionText)

                            Spacer(minLength: 8)

                            Image(systemName: "chevron.forward")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AppTheme.Colors.Settings.crownSymbolColor)
                        }
                        .padding(.horizontal, 15)
                        .frame(maxWidth: .infinity, minHeight: 49)
                        .background(AppTheme.Colors.Settings.inlineActionBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AppTheme.Colors.Settings.inlineActionBorder, lineWidth: 1)
                        }
                        .shadow(
                            color: AppTheme.Colors.Settings.inlineActionShadow,
                            radius: 9,
                            x: 0,
                            y: 5
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(store.guestActionTitle)
                }

                if store.isBusy {
                    ProgressView()
                        .tint(AppTheme.Colors.Settings.switchActiveTrack)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 13)
                }
            }
        }
    }

    // MARK: - Pro Membership Card (`SettingsScreen.tsx:185-243`)

    private var proCard: some View {
        SettingsCardContainer(isPro: true) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.Settings.crownBackground)
                                .frame(width: 48, height: 48)
                                .overlay {
                                    Circle()
                                        .stroke(AppTheme.Colors.Settings.crownBorder, lineWidth: 1)
                                }

                            Text("♛")
                                .font(.system(size: 26))
                                .foregroundStyle(AppTheme.Colors.Settings.crownSymbolColor)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("GÓI THÀNH VIÊN")
                                .font(.system(size: 15, weight: .black))
                                .kerning(0.8)
                                .foregroundStyle(AppTheme.Colors.Settings.cardTitleGold)

                            Text(store.proHeadlineTitle)
                                .font(.system(size: 21, weight: .black))
                                .lineSpacing(2)
                                .foregroundStyle(AppTheme.Colors.Settings.titleText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(store.planBadgeTitle)
                        .font(.system(size: 11, weight: .black))
                        .kerning(0.6)
                        .foregroundStyle(
                            store.isPro
                                ? AppTheme.Colors.Settings.planBadgeActiveText
                                : AppTheme.Colors.Settings.planBadgeInactiveText
                        )
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(
                            store.isPro
                                ? AppTheme.Colors.Settings.switchActiveTrack
                                : AppTheme.Colors.Settings.planBadgeInactiveBackground
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    store.isPro
                                        ? AppTheme.Colors.Settings.planBadgeActiveBorder
                                        : AppTheme.Colors.Settings.planBadgeInactiveBorder,
                                    lineWidth: 1
                                )
                        }
                }

                if store.isPro {
                    Text(store.proSubscriptionSummary)
                        .font(.system(size: 14))
                        .lineSpacing(3)
                        .foregroundStyle(AppTheme.Colors.Settings.hintText)
                        .padding(.top, 10)
                } else {
                    Text("Tăng lượt luận giải AI, tạo nhiều hình nền hơn và mở khóa các trải bài chuyên sâu.")
                        .font(.system(size: 14))
                        .lineSpacing(3)
                        .foregroundStyle(AppTheme.Colors.Settings.hintText)
                        .padding(.top, 10)

                    Text("CHỌN PHƯƠNG THỨC THANH TOÁN")
                        .font(.system(size: 13, weight: .black))
                        .kerning(0.7)
                        .foregroundStyle(AppTheme.Colors.Settings.paymentSectionLabel)
                        .padding(.top, 19)
                        .padding(.bottom, 10)

                    HStack(spacing: 9) {
                        paymentMethodCard(
                            provider: .payos,
                            selected: store.paymentMethod == .payos,
                            title: "VietQR / PayOS",
                            detail: "79.000đ · 30 ngày",
                            icon: "▣"
                        )

                        paymentMethodCard(
                            provider: .paypal,
                            selected: store.paymentMethod == .paypal,
                            title: "PayPal",
                            detail: "$3.99 · mỗi tháng",
                            icon: "P"
                        )
                    }

                    Button {
                        store.send(.upgradeTapped)
                    } label: {
                        Group {
                            if store.isBusy {
                                ProgressView()
                                    .tint(AppTheme.Colors.Settings.planBadgeActiveText)
                            } else {
                                HStack(spacing: 8) {
                                    Text(store.upgradeButtonTitle)
                                        .font(.system(size: 14, weight: .black))
                                        .kerning(0.2)
                                        .foregroundStyle(AppTheme.Colors.Settings.upgradeButtonText)

                                    Image(systemName: "arrow.forward")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(AppTheme.Colors.Settings.upgradeButtonText)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(AppTheme.Gradients.Settings.upgradeButtonGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(AppTheme.Colors.Settings.upgradeButtonBorder, lineWidth: 1)
                        }
                        .shadow(
                            color: AppTheme.Colors.Settings.upgradeButtonShadow,
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(store.isBusy)
                    .opacity(store.isBusy ? 0.55 : 1.0)
                    .padding(.top, 14)
                    .accessibilityLabel(store.upgradeButtonTitle)
                }

                if store.isCheckoutPending {
                    Text("Bạn có một yêu cầu PayPal chưa hoàn tất. Hãy xác nhận hoặc quay lại website để hủy yêu cầu đó trước khi thử lại.")
                        .font(.system(size: 12))
                        .lineSpacing(3)
                        .foregroundStyle(AppTheme.Colors.Settings.warningText)
                        .padding(.top, 12)
                }

                if let billingError = store.billingError, !billingError.isEmpty {
                    Text(billingError)
                        .font(.system(size: 12))
                        .lineSpacing(3)
                        .foregroundStyle(AppTheme.Colors.Settings.errorText)
                        .padding(.top, 12)
                        .accessibilityAddTraits(.isStaticText)
                }

                if store.isAuthenticated {
                    Button {
                        store.send(.refreshBillingTapped)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.Settings.refreshText)

                            Text("Cập nhật trạng thái Pro")
                                .font(.system(size: 12))
                                .underline()
                                .foregroundStyle(AppTheme.Colors.Settings.refreshText)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .disabled(store.isBusy)
                    .padding(.top, 5)
                    .accessibilityLabel("Cập nhật trạng thái Pro")
                }
            }
        }
    }

    // MARK: - Subcomponents

    private var rowDivider: some View {
        Rectangle()
            .fill(AppTheme.Colors.Settings.rowDivider)
            .frame(height: 1)
            .padding(.vertical, 14)
    }

    private func settingIconBadge(
        systemName: String,
        iconColor: Color,
        backgroundColor: Color,
        borderColor: Color
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(backgroundColor)
                .frame(width: 45, height: 45)
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                }

            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconColor)
        }
    }

    private func accountActionButton(
        label: String,
        danger: Bool,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(danger ? AppTheme.Colors.Settings.errorText : AppTheme.Colors.Settings.actionText)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 55)
                .background(
                    danger
                        ? AppTheme.Gradients.Settings.dangerActionGradient
                        : AppTheme.Gradients.Settings.primaryActionGradient
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppTheme.Colors.Settings.actionBorder, lineWidth: 1.5)
                }
                .shadow(
                    color: danger
                        ? AppTheme.Colors.Settings.dangerActionShadow
                        : AppTheme.Colors.Settings.primaryActionShadow,
                    radius: 10,
                    x: 0,
                    y: 5
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.55 : 1.0)
        .padding(.top, 15)
        .accessibilityLabel(label)
    }

    private func paymentMethodCard(
        provider: BillingProvider,
        selected: Bool,
        title: String,
        detail: String,
        icon: String
    ) -> some View {
        Button {
            store.send(.paymentMethodSelected(provider))
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(icon)
                        .font(.system(size: 25, weight: .black))
                        .foregroundStyle(
                            selected
                                ? AppTheme.Colors.Settings.paymentSelectedText
                                : AppTheme.Colors.Settings.paymentUnselectedIcon
                        )

                    Spacer(minLength: 4)

                    ZStack {
                        Circle()
                            .stroke(
                                selected
                                    ? AppTheme.Colors.Settings.paymentSelectedBorder
                                    : AppTheme.Colors.Settings.radioBorder,
                                lineWidth: 2
                            )
                            .background(
                                Circle()
                                    .fill(
                                        selected
                                            ? AppTheme.Colors.Settings.paymentSelectedBorder
                                            : Color.clear
                                    )
                            )
                            .frame(width: 24, height: 24)

                        if selected {
                            Circle()
                                .fill(AppTheme.Colors.Settings.radioInnerDot)
                                .frame(width: 8, height: 8)
                        }
                    }
                }

                Text(title)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(
                        selected
                            ? AppTheme.Colors.Settings.paymentSelectedText
                            : AppTheme.Colors.Settings.paymentTitleText
                    )
                    .padding(.top, 14)

                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.Colors.Settings.paymentDetailText)
                    .padding(.top, 5)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
            .background {
                ZStack {
                    (selected
                        ? AppTheme.Colors.Settings.paymentSelectedBackground
                        : AppTheme.Colors.Settings.paymentUnselectedBackground)
                    (selected
                        ? AppTheme.Gradients.Settings.paymentSelectedOverlay
                        : AppTheme.Gradients.Settings.paymentUnselectedOverlay)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        selected
                            ? AppTheme.Colors.Settings.paymentSelectedBorder
                            : AppTheme.Colors.Settings.paymentUnselectedBorder,
                        lineWidth: 1
                    )
            }
            .shadow(
                color: selected
                    ? AppTheme.Colors.Settings.paymentSelectedShadow
                    : AppTheme.Colors.Settings.paymentUnselectedShadow,
                radius: 9,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(detail)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - Settings Card Container (`SettingsScreen.tsx:249-263`)

private struct SettingsCardContainer<Content: View>: View {
    var isPro: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    (isPro ? AppTheme.Gradients.Settings.proCardGradient : AppTheme.Gradients.Settings.standardCardGradient)
                    AppTheme.Gradients.Settings.cardOverlayGradient
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        isPro ? AppTheme.Colors.Settings.proCardBorder : AppTheme.Colors.Settings.standardCardBorder,
                        lineWidth: 1
                    )
            }
            .shadow(
                color: isPro ? AppTheme.Colors.Settings.proCardShadow : AppTheme.Colors.Settings.standardCardShadow,
                radius: isPro ? 21 : 19,
                x: 0,
                y: 10
            )
            .padding(.bottom, 16)
    }
}

#Preview("Tài khoản khách (Free)") {
    SettingsView(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.supabaseClient.isConfigured = { true }
            $0.supabaseClient.currentSession = { nil }
            $0.billingClient = .previewValue
            $0.hapticClient = .testValue
        }
    )
}

#Preview("Đã đăng nhập (Pro)") {
    let previewSession = AuthSession(
        accessToken: "preview-jwt",
        refreshToken: "preview-refresh",
        userId: "user-1",
        userEmail: "an.nguyen@numelyra.online"
    )
    SettingsView(
        store: Store(
            initialState: SettingsFeature.State(
                session: previewSession,
                billing: BillingStatus(
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
            )
        ) {
            SettingsFeature()
        } withDependencies: {
            $0.supabaseClient = .previewValue
            $0.billingClient = .previewValue
            $0.hapticClient = .testValue
        }
    )
}
