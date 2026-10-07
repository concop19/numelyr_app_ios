import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .top) {
            SettingsPalette.safeAreaBackground
                .ignoresSafeArea()

            SettingsPalette.screenGradient
                .ignoresSafeArea()
                .allowsHitTesting(false)

            skyDecorations
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroHeader

                    sectionGroupTitle("NHẮC NHỞ HẰNG NGÀY")
                    dailyReminderCard

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
                    .stroke(SettingsPalette.orbitBorder, lineWidth: 1)
                    .frame(width: 330, height: 250)
                    .rotationEffect(.degrees(25))
                    .position(
                        x: proxy.size.width + 92 - 165,
                        y: -105 + 125
                    )

                Text("☾")
                    .font(.system(size: 86))
                    .foregroundStyle(SettingsPalette.moonColor)
                    .rotationEffect(.degrees(-18))
                    .opacity(0.95)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 12)
                    .padding(.trailing, 22)

                Text("✦")
                    .font(.system(size: 16))
                    .foregroundStyle(SettingsPalette.starOneColor)
                    .padding(.top, 112)
                    .padding(.leading, 26)

                Text("✧")
                    .font(.system(size: 12))
                    .foregroundStyle(SettingsPalette.starTwoColor)
                    .padding(.top, 76)
                    .padding(.leading, 164)

                Text("✦")
                    .font(.system(size: 20))
                    .foregroundStyle(SettingsPalette.starThreeColor)
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
                .foregroundStyle(SettingsPalette.titleText)
                .multilineTextAlignment(.center)

            Text("Tùy chỉnh hành trình NUMELYRA theo cách của bạn")
                .font(.system(size: 14))
                .lineSpacing(3)
                .foregroundStyle(SettingsPalette.subtitleText)
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
            .foregroundStyle(SettingsPalette.groupTitleText)
            .padding(.leading, 5)
            .padding(.bottom, 9)
    }

    // MARK: - Daily Reminder Card (`SettingsScreen.tsx:135-159`)

    private var dailyReminderCard: some View {
        SettingsCardContainer {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    settingIconBadge(
                        systemName: "bell",
                        iconColor: SettingsPalette.reminderIconTint,
                        backgroundColor: SettingsPalette.reminderIconBackground,
                        borderColor: SettingsPalette.reminderIconBorder
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nhắc chơi mỗi ngày")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(SettingsPalette.titleText)

                        Text(store.reminderHint)
                            .font(.system(size: 12))
                            .lineSpacing(2)
                            .foregroundStyle(SettingsPalette.hintText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Toggle(
                        "Nhắc chơi mỗi ngày",
                        isOn: Binding(
                            get: { store.dailyReminder.enabled },
                            set: { store.send(.dailyReminderToggled($0)) }
                        )
                    )
                    .labelsHidden()
                    .tint(SettingsPalette.switchActiveTrack)
                    .disabled(!store.canUseNativeNotifications)
                }
                .frame(minHeight: 58)

                rowDivider

                HStack(spacing: 12) {
                    settingIconBadge(
                        systemName: "clock",
                        iconColor: SettingsPalette.timeIconTint,
                        backgroundColor: SettingsPalette.timeIconBackground,
                        borderColor: SettingsPalette.timeIconBorder
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Giờ nhắc")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(SettingsPalette.titleText)

                        Text("Chọn thời điểm phù hợp với bạn")
                            .font(.system(size: 12))
                            .lineSpacing(2)
                            .foregroundStyle(SettingsPalette.hintText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 58)

                HStack(spacing: 8) {
                    ForEach(SettingsEngine.presetReminderHours, id: \.self) { hour in
                        let isSelected = store.dailyReminder.hour == hour
                        let timeLabel = SettingsEngine.formatTime(hour: hour, minute: 0)
                        Button {
                            store.send(.dailyReminderHourSelected(hour))
                        } label: {
                            Text(timeLabel)
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundStyle(
                                    isSelected
                                        ? SettingsPalette.timeTextActive
                                        : SettingsPalette.timeTextInactive
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(
                                    isSelected
                                        ? SettingsPalette.switchActiveTrack
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(
                                            isSelected
                                                ? SettingsPalette.switchActiveTrack
                                                : SettingsPalette.timeButtonBorder,
                                            lineWidth: 1
                                        )
                                }
                        }
                        .buttonStyle(.plain)
                        .disabled(!store.canUseNativeNotifications)
                        .opacity(store.canUseNativeNotifications ? 1.0 : 0.55)
                        .accessibilityLabel("Giờ nhắc \(timeLabel)")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
                .padding(.top, 12)
            }
        }
    }

    // MARK: - Account Card (`SettingsScreen.tsx:161-183`)

    private var accountCard: some View {
        SettingsCardContainer {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    settingIconBadge(
                        systemName: store.isAuthenticated ? "person" : "person.badge.plus",
                        iconColor: SettingsPalette.profileIconTint,
                        backgroundColor: SettingsPalette.profileIconBackground,
                        borderColor: SettingsPalette.profileIconBorder
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.accountTitle)
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(SettingsPalette.titleText)
                            .lineLimit(1)

                        Text(store.accountHint)
                            .font(.system(size: 12))
                            .lineSpacing(2)
                            .foregroundStyle(SettingsPalette.hintText)
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
                                .foregroundStyle(SettingsPalette.actionText)

                            Spacer(minLength: 8)

                            Image(systemName: "chevron.forward")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(SettingsPalette.crownSymbolColor)
                        }
                        .padding(.horizontal, 15)
                        .frame(maxWidth: .infinity, minHeight: 49)
                        .background(SettingsPalette.inlineActionBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(SettingsPalette.inlineActionBorder, lineWidth: 1)
                        }
                        .shadow(
                            color: SettingsPalette.inlineActionShadow,
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
                        .tint(SettingsPalette.switchActiveTrack)
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
                                .fill(SettingsPalette.crownBackground)
                                .frame(width: 48, height: 48)
                                .overlay {
                                    Circle()
                                        .stroke(SettingsPalette.crownBorder, lineWidth: 1)
                                }

                            Text("♛")
                                .font(.system(size: 26))
                                .foregroundStyle(SettingsPalette.crownSymbolColor)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("GÓI THÀNH VIÊN")
                                .font(.system(size: 15, weight: .black))
                                .kerning(0.8)
                                .foregroundStyle(SettingsPalette.cardTitleGold)

                            Text(store.proHeadlineTitle)
                                .font(.system(size: 21, weight: .black))
                                .lineSpacing(2)
                                .foregroundStyle(SettingsPalette.titleText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(store.planBadgeTitle)
                        .font(.system(size: 11, weight: .black))
                        .kerning(0.6)
                        .foregroundStyle(
                            store.isPro
                                ? SettingsPalette.planBadgeActiveText
                                : SettingsPalette.planBadgeInactiveText
                        )
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(
                            store.isPro
                                ? SettingsPalette.switchActiveTrack
                                : SettingsPalette.planBadgeInactiveBackground
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    store.isPro
                                        ? SettingsPalette.planBadgeActiveBorder
                                        : SettingsPalette.planBadgeInactiveBorder,
                                    lineWidth: 1
                                )
                        }
                }

                if store.isPro {
                    Text(store.proSubscriptionSummary)
                        .font(.system(size: 14))
                        .lineSpacing(3)
                        .foregroundStyle(SettingsPalette.hintText)
                        .padding(.top, 10)
                } else {
                    Text("Tăng lượt luận giải AI, tạo nhiều hình nền hơn và mở khóa các trải bài chuyên sâu.")
                        .font(.system(size: 14))
                        .lineSpacing(3)
                        .foregroundStyle(SettingsPalette.hintText)
                        .padding(.top, 10)

                    Text("CHỌN PHƯƠNG THỨC THANH TOÁN")
                        .font(.system(size: 13, weight: .black))
                        .kerning(0.7)
                        .foregroundStyle(SettingsPalette.paymentSectionLabel)
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
                                    .tint(SettingsPalette.planBadgeActiveText)
                            } else {
                                HStack(spacing: 8) {
                                    Text(store.upgradeButtonTitle)
                                        .font(.system(size: 14, weight: .black))
                                        .kerning(0.2)
                                        .foregroundStyle(SettingsPalette.upgradeButtonText)

                                    Image(systemName: "arrow.forward")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(SettingsPalette.upgradeButtonText)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(SettingsPalette.upgradeButtonGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(SettingsPalette.upgradeButtonBorder, lineWidth: 1)
                        }
                        .shadow(
                            color: SettingsPalette.upgradeButtonShadow,
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
                        .foregroundStyle(SettingsPalette.warningText)
                        .padding(.top, 12)
                }

                if let billingError = store.billingError, !billingError.isEmpty {
                    Text(billingError)
                        .font(.system(size: 12))
                        .lineSpacing(3)
                        .foregroundStyle(SettingsPalette.errorText)
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
                                .foregroundStyle(SettingsPalette.refreshText)

                            Text("Cập nhật trạng thái Pro")
                                .font(.system(size: 12))
                                .underline()
                                .foregroundStyle(SettingsPalette.refreshText)
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
            .fill(SettingsPalette.rowDivider)
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
                .foregroundStyle(danger ? SettingsPalette.errorText : SettingsPalette.actionText)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 55)
                .background(
                    danger
                        ? SettingsPalette.dangerActionGradient
                        : SettingsPalette.primaryActionGradient
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(SettingsPalette.actionBorder, lineWidth: 1.5)
                }
                .shadow(
                    color: danger
                        ? SettingsPalette.dangerActionShadow
                        : SettingsPalette.primaryActionShadow,
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
                                ? SettingsPalette.paymentSelectedText
                                : SettingsPalette.paymentUnselectedIcon
                        )

                    Spacer(minLength: 4)

                    ZStack {
                        Circle()
                            .stroke(
                                selected
                                    ? SettingsPalette.paymentSelectedBorder
                                    : SettingsPalette.radioBorder,
                                lineWidth: 2
                            )
                            .background(
                                Circle()
                                    .fill(
                                        selected
                                            ? SettingsPalette.paymentSelectedBorder
                                            : Color.clear
                                    )
                            )
                            .frame(width: 24, height: 24)

                        if selected {
                            Circle()
                                .fill(SettingsPalette.radioInnerDot)
                                .frame(width: 8, height: 8)
                        }
                    }
                }

                Text(title)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(
                        selected
                            ? SettingsPalette.paymentSelectedText
                            : SettingsPalette.paymentTitleText
                    )
                    .padding(.top, 14)

                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(SettingsPalette.paymentDetailText)
                    .padding(.top, 5)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
            .background {
                ZStack {
                    (selected
                        ? SettingsPalette.paymentSelectedBackground
                        : SettingsPalette.paymentUnselectedBackground)
                    (selected
                        ? SettingsPalette.paymentSelectedOverlay
                        : SettingsPalette.paymentUnselectedOverlay)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        selected
                            ? SettingsPalette.paymentSelectedBorder
                            : SettingsPalette.paymentUnselectedBorder,
                        lineWidth: 1
                    )
            }
            .shadow(
                color: selected
                    ? SettingsPalette.paymentSelectedShadow
                    : SettingsPalette.paymentUnselectedShadow,
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
                    (isPro ? SettingsPalette.proCardGradient : SettingsPalette.standardCardGradient)
                    SettingsPalette.cardOverlayGradient
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        isPro ? SettingsPalette.proCardBorder : SettingsPalette.standardCardBorder,
                        lineWidth: 1
                    )
            }
            .shadow(
                color: isPro ? SettingsPalette.proCardShadow : SettingsPalette.standardCardShadow,
                radius: isPro ? 21 : 19,
                x: 0,
                y: 10
            )
            .padding(.bottom, 16)
    }
}

// MARK: - Settings Screen Palette (`SettingsScreen.tsx:120-381`)

private enum SettingsPalette {
    static let safeAreaBackground = Color(red: 14 / 255, green: 9 / 255, blue: 43 / 255) // #0E092B

    static let screenGradient = LinearGradient(
        colors: [
            Color(red: 33 / 255, green: 16 / 255, blue: 82 / 255), // #211052
            Color(red: 17 / 255, green: 8 / 255, blue: 47 / 255),  // #11082F
            Color(red: 12 / 255, green: 6 / 255, blue: 37 / 255)   // #0C0625
        ],
        startPoint: UnitPoint(x: 0.1, y: 0),
        endPoint: UnitPoint(x: 0.9, y: 1)
    )

    static let moonColor = Color(red: 255 / 255, green: 231 / 255, blue: 160 / 255) // #FFE7A0
    static let starOneColor = Color(red: 248 / 255, green: 183 / 255, blue: 255 / 255) // #F8B7FF
    static let starTwoColor = Color(red: 255 / 255, green: 226 / 255, blue: 154 / 255) // #FFE29A
    static let starThreeColor = Color(red: 255 / 255, green: 215 / 255, blue: 121 / 255) // #FFD779
    static let orbitBorder = Color(red: 235 / 255, green: 157 / 255, blue: 255 / 255).opacity(0.32)

    static let titleText = Color(red: 252 / 255, green: 245 / 255, blue: 255 / 255) // #FCF5FF
    static let subtitleText = Color(red: 184 / 255, green: 168 / 255, blue: 216 / 255) // #B8A8D8
    static let groupTitleText = Color(red: 228 / 255, green: 213 / 255, blue: 255 / 255) // #E4D5FF
    static let hintText = Color(red: 187 / 255, green: 174 / 255, blue: 214 / 255) // #BBAED6

    static let standardCardGradient = LinearGradient(
        colors: [
            Color(red: 50 / 255, green: 16 / 255, blue: 96 / 255), // #321060
            Color(red: 41 / 255, green: 16 / 255, blue: 81 / 255), // #291051
            Color(red: 33 / 255, green: 9 / 255, blue: 67 / 255)   // #210943
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let proCardGradient = LinearGradient(
        colors: [
            Color(red: 66 / 255, green: 23 / 255, blue: 119 / 255), // #421777
            Color(red: 50 / 255, green: 16 / 255, blue: 96 / 255),  // #321060
            Color(red: 35 / 255, green: 9 / 255, blue: 68 / 255)    // #230944
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardOverlayGradient = LinearGradient(
        colors: [
            Color(red: 247 / 255, green: 199 / 255, blue: 255 / 255).opacity(0.12),
            Color(red: 33 / 255, green: 12 / 255, blue: 76 / 255).opacity(0.04),
            Color(red: 8 / 255, green: 4 / 255, blue: 34 / 255).opacity(0.32)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let standardCardBorder = Color(red: 153 / 255, green: 95 / 255, blue: 210 / 255).opacity(0.62)
    static let proCardBorder = Color(red: 184 / 255, green: 111 / 255, blue: 226 / 255).opacity(0.70)
    static let standardCardShadow = Color(red: 26 / 255, green: 6 / 255, blue: 58 / 255).opacity(0.94)
    static let proCardShadow = Color(red: 37 / 255, green: 7 / 255, blue: 74 / 255).opacity(0.98)

    static let reminderIconTint = Color(red: 255 / 255, green: 210 / 255, blue: 108 / 255) // #FFD26C
    static let reminderIconBackground = Color(red: 127 / 255, green: 75 / 255, blue: 168 / 255).opacity(0.28)
    static let reminderIconBorder = Color(red: 255 / 255, green: 209 / 255, blue: 109 / 255).opacity(0.46)

    static let timeIconTint = Color(red: 199 / 255, green: 164 / 255, blue: 255 / 255) // #C7A4FF
    static let timeIconBackground = Color(red: 86 / 255, green: 59 / 255, blue: 152 / 255).opacity(0.36)
    static let timeIconBorder = Color(red: 182 / 255, green: 137 / 255, blue: 241 / 255).opacity(0.44)

    static let profileIconTint = Color(red: 244 / 255, green: 184 / 255, blue: 255 / 255) // #F4B8FF
    static let profileIconBackground = Color(red: 139 / 255, green: 58 / 255, blue: 157 / 255).opacity(0.31)
    static let profileIconBorder = Color(red: 237 / 255, green: 160 / 255, blue: 255 / 255).opacity(0.45)

    static let switchActiveTrack = Color(red: 245 / 255, green: 186 / 255, blue: 91 / 255) // #F5BA5B
    static let rowDivider = Color(red: 182 / 255, green: 133 / 255, blue: 231 / 255).opacity(0.23)

    static let timeButtonBorder = Color(red: 90 / 255, green: 70 / 255, blue: 119 / 255) // #5A4677
    static let timeTextInactive = Color(red: 214 / 255, green: 201 / 255, blue: 235 / 255) // #D6C9EB
    static let timeTextActive = Color(red: 36 / 255, green: 19 / 255, blue: 63 / 255) // #24133F

    static let primaryActionGradient = LinearGradient(
        colors: [
            Color(red: 67 / 255, green: 32 / 255, blue: 120 / 255), // #432078
            Color(red: 49 / 255, green: 22 / 255, blue: 94 / 255),  // #31165E
            Color(red: 33 / 255, green: 16 / 255, blue: 67 / 255)   // #211043
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let dangerActionGradient = LinearGradient(
        colors: [
            Color(red: 93 / 255, green: 32 / 255, blue: 94 / 255), // #5D205E
            Color(red: 64 / 255, green: 20 / 255, blue: 66 / 255), // #401442
            Color(red: 40 / 255, green: 16 / 255, blue: 49 / 255)  // #281031
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let actionBorder = Color(red: 255 / 255, green: 213 / 255, blue: 115 / 255).opacity(0.64)
    static let actionText = Color(red: 255 / 255, green: 224 / 255, blue: 138 / 255) // #FFE08A
    static let primaryActionShadow = Color(red: 42 / 255, green: 10 / 255, blue: 87 / 255).opacity(0.82)
    static let dangerActionShadow = Color(red: 75 / 255, green: 16 / 255, blue: 78 / 255).opacity(0.82)

    static let inlineActionBackground = Color(red: 73 / 255, green: 38 / 255, blue: 119 / 255).opacity(0.68)
    static let inlineActionBorder = Color(red: 255 / 255, green: 211 / 255, blue: 110 / 255).opacity(0.52)
    static let inlineActionShadow = Color(red: 25 / 255, green: 6 / 255, blue: 50 / 255).opacity(0.76)

    static let crownBackground = Color(red: 40 / 255, green: 32 / 255, blue: 87 / 255) // #282057
    static let crownBorder = Color(red: 200 / 255, green: 140 / 255, blue: 241 / 255) // #C88CF1
    static let crownSymbolColor = Color(red: 255 / 255, green: 211 / 255, blue: 110 / 255) // #FFD36E
    static let cardTitleGold = Color(red: 255 / 255, green: 209 / 255, blue: 109 / 255) // #FFD16D

    static let planBadgeInactiveBackground = Color(red: 39 / 255, green: 32 / 255, blue: 74 / 255) // #27204A
    static let planBadgeInactiveBorder = Color(red: 102 / 255, green: 81 / 255, blue: 142 / 255) // #66518E
    static let planBadgeInactiveText = Color(red: 199 / 255, green: 185 / 255, blue: 228 / 255) // #C7B9E4
    static let planBadgeActiveBorder = Color(red: 255 / 255, green: 215 / 255, blue: 127 / 255) // #FFD77F
    static let planBadgeActiveText = Color(red: 17 / 255, green: 15 / 255, blue: 32 / 255) // #110F20

    static let paymentSectionLabel = Color(red: 198 / 255, green: 184 / 255, blue: 227 / 255) // #C6B8E3
    static let paymentUnselectedBackground = Color(red: 37 / 255, green: 16 / 255, blue: 74 / 255) // #25104A
    static let paymentSelectedBackground = Color(red: 60 / 255, green: 26 / 255, blue: 96 / 255) // #3C1A60
    static let paymentUnselectedBorder = Color(red: 128 / 255, green: 77 / 255, blue: 183 / 255).opacity(0.62)
    static let paymentSelectedBorder = Color(red: 255 / 255, green: 210 / 255, blue: 95 / 255) // #FFD25F
    static let paymentUnselectedShadow = Color(red: 23 / 255, green: 5 / 255, blue: 47 / 255).opacity(0.78)
    static let paymentSelectedShadow = Color(red: 42 / 255, green: 11 / 255, blue: 82 / 255).opacity(0.90)

    static let paymentSelectedOverlay = LinearGradient(
        colors: [
            Color(red: 255 / 255, green: 226 / 255, blue: 154 / 255).opacity(0.14),
            Color(red: 65 / 255, green: 34 / 255, blue: 99 / 255).opacity(0.12),
            Color(red: 14 / 255, green: 7 / 255, blue: 39 / 255).opacity(0.34)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let paymentUnselectedOverlay = LinearGradient(
        colors: [
            Color(red: 237 / 255, green: 191 / 255, blue: 255 / 255).opacity(0.09),
            Color(red: 13 / 255, green: 6 / 255, blue: 42 / 255).opacity(0.28)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let paymentUnselectedIcon = Color(red: 182 / 255, green: 175 / 255, blue: 201 / 255) // #B6AFC9
    static let paymentTitleText = Color(red: 242 / 255, green: 234 / 255, blue: 251 / 255) // #F2EAFB
    static let paymentDetailText = Color(red: 173 / 255, green: 162 / 255, blue: 197 / 255) // #ADA2C5
    static let paymentSelectedText = Color(red: 245 / 255, green: 210 / 255, blue: 123 / 255) // #F5D27B
    static let radioBorder = Color(red: 114 / 255, green: 88 / 255, blue: 155 / 255) // #72589B
    static let radioInnerDot = Color(red: 77 / 255, green: 43 / 255, blue: 96 / 255) // #4D2B60

    static let upgradeButtonGradient = LinearGradient(
        colors: [
            Color(red: 255 / 255, green: 232 / 255, blue: 170 / 255), // #FFE8AA
            Color(red: 245 / 255, green: 189 / 255, blue: 85 / 255),  // #F5BD55
            Color(red: 217 / 255, green: 139 / 255, blue: 46 / 255)   // #D98B2E
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let upgradeButtonBorder = Color(red: 255 / 255, green: 241 / 255, blue: 170 / 255) // #FFF1AA
    static let upgradeButtonText = Color(red: 33 / 255, green: 20 / 255, blue: 67 / 255) // #211443
    static let upgradeButtonShadow = Color(red: 228 / 255, green: 160 / 255, blue: 57 / 255).opacity(0.58)

    static let warningText = Color(red: 252 / 255, green: 211 / 255, blue: 77 / 255) // #FCD34D
    static let errorText = Color(red: 253 / 255, green: 164 / 255, blue: 175 / 255) // #FDA4AF
    static let refreshText = Color(red: 198 / 255, green: 189 / 255, blue: 217 / 255) // #C6BDD9
}

#Preview("Tài khoản khách (Free)") {
    SettingsView(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.supabaseClient.isConfigured = { true }
            $0.supabaseClient.currentSession = { nil }
            $0.dailyNotificationClient = .previewValue
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
            $0.dailyNotificationClient = .previewValue
            $0.billingClient = .previewValue
            $0.hapticClient = .testValue
        }
    )
}
