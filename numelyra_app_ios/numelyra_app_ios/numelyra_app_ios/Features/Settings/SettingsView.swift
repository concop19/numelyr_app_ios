import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .top) {
            Image(appAsset: .settingsSkyBackground)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(hex: 0x0C0850, opacity: 0.03),
                    Color(hex: 0x1B0859, opacity: 0.20),
                    Color(hex: 0x100542, opacity: 0.70)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                groundBackground
            }
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

                    sectionGroupTitle("CÀI ĐẶT CHUNG")
                    informationCard
                    recentActivityCard
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

    // MARK: - RN Artwork (`SettingsScreen.tsx:121-127`)

    private var groundBackground: some View {
        GeometryReader { proxy in
            Image(appAsset: .settingsGroundBackground)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width * 1.62, height: 340)
                .offset(x: -proxy.size.width * 0.31)
                .frame(width: proxy.size.width, height: 210, alignment: .bottomLeading)
                .clipped()
        }
        .frame(height: 210)
        .opacity(0.88)
    }

    // MARK: - Hero Header (`SettingsScreen.tsx:129-253`)

    private var heroHeader: some View {
        ZStack(alignment: .bottom) {
            heroDecorations

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xFFB6D7), Color(hex: 0xFFD98B), Color(hex: 0x9D6CFF)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)

                Circle()
                    .fill(Color(hex: 0x321774, opacity: 0.94))
                    .padding(4)

                SettingsFlameMascot(size: 112)
                    .clipShape(Circle())
            }
            .frame(width: 150, height: 150)
            .shadow(color: Color(hex: 0xFF9CCB, opacity: 0.72), radius: 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 20)

            VStack(spacing: 2) {
                Text("Cài đặt tài khoản")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color(hex: 0x20085C, opacity: 0.8), radius: 5, x: 0, y: 2)

                Text(store.accountHandle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xE8DFFC))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .frame(height: 276)
        .accessibilityElement(children: .contain)
    }

    private var heroDecorations: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(Color(hex: 0xFFAFDD))
                    .frame(width: 56, height: 1)
                    .rotationEffect(.degrees(-38))
                    .shadow(color: .white, radius: 4)
                    .position(x: 104, y: 67)

                Image(systemName: "sparkles")
                    .font(.system(size: 19))
                    .foregroundStyle(Color(hex: 0xFFE17D))
                    .position(x: 36, y: 84)

                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: 0xFFF3A8))
                    .position(x: proxy.size.width - 66, y: 90)

                Text("☾")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.Settings.moonColor)
                    .rotationEffect(.degrees(-17))
                    .shadow(color: Color(hex: 0xFFD75D, opacity: 0.75), radius: 13)
                    .position(x: proxy.size.width - 58, y: 51)

                SettingsHeroClouds()
                    .frame(width: proxy.size.width, height: 58)
                    .offset(y: 145)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
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
        SettingsCardContainer(isLight: true) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    settingIconBadge(
                        systemName: store.isAuthenticated ? "person" : "person.badge.plus",
                        iconColor: Color(hex: 0x5D238B),
                        backgroundColor: Color(hex: 0xFFEADB),
                        borderColor: Color(hex: 0xF4D7C7)
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Thông tin cá nhân")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(Color(hex: 0x2E2052))
                            .lineLimit(1)

                        Text(store.accountRowDetail)
                            .font(.system(size: 12))
                            .lineSpacing(2)
                            .foregroundStyle(Color(hex: 0x8D7D91))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 58)

                Rectangle()
                    .fill(Color(hex: 0x5C3A69, opacity: 0.18))
                    .frame(height: 0.5)
                    .padding(.vertical, 14)

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

    // MARK: - Informational rows (`SettingsScreen.tsx:264-329`)

    private var informationCard: some View {
        VStack(spacing: 0) {
            informationRow(
                .language,
                icon: "globe",
                label: "Ngôn ngữ",
                detail: "Tiếng Việt",
                iconColor: Color(hex: 0x5B35D2),
                iconBackground: Color(hex: 0xFFD8E6)
            )
            informationDivider
            informationRow(
                .activity,
                icon: "chart.bar.fill",
                label: "Hoạt động của bạn",
                detail: "Lịch sử trải bài, lịch sử hỏi AI",
                iconColor: Color(hex: 0x6B32B2),
                iconBackground: Color(hex: 0xFFDCE4)
            )
            informationDivider
            informationRow(
                .privacy,
                icon: "lock.fill",
                label: "Quyền riêng tư",
                iconColor: Color(hex: 0x5D35C5),
                iconBackground: Color(hex: 0xF1DBED)
            )
            informationDivider
            informationRow(
                .help,
                icon: "questionmark.circle.fill",
                label: "Trợ giúp",
                iconColor: Color(hex: 0x6D218B),
                iconBackground: Color(hex: 0xFBE1E4)
            )
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 7)
        .background(Color(hex: 0xFFF4E8))
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .stroke(Color(hex: 0xFFE7D5), lineWidth: 1)
        }
        .shadow(color: Color(hex: 0x130139, opacity: 0.36), radius: 18, x: 0, y: 10)
        .padding(.bottom, 14)
    }

    private func informationRow(
        _ item: SettingsFeature.Action.InformationItem,
        icon: String,
        label: String,
        detail: String? = nil,
        iconColor: Color,
        iconBackground: Color
    ) -> some View {
        Button {
            store.send(.informationItemTapped(item))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 42, height: 42)
                    .background(iconBackground, in: Circle())

                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: 0x2E2052))
                        .lineLimit(1)

                    if let detail {
                        Text(detail)
                            .font(.system(size: 12.5))
                            .foregroundStyle(Color(hex: 0x8D7D91))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.forward")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x736684))
            }
            .frame(minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(detail.map { "\(label), \($0)" } ?? label)
        .accessibilityAddTraits(.isButton)
    }

    private var informationDivider: some View {
        Rectangle()
            .fill(Color(hex: 0x5C3A69, opacity: 0.18))
            .frame(height: 0.5)
    }

    private var recentActivityCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 24))
                .foregroundStyle(Color(hex: 0xF777E5))

            VStack(alignment: .leading, spacing: 3) {
                Text("Hoạt động gần đây")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 4)

                Text("•  12 lượt xem tarot tháng này")
                Text("•  8 lần xem chiêm tinh")
                Text("•  5 ngày mở lịch liên tiếp")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color(hex: 0xF5ECFF))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .topLeading)
        .background {
            LinearGradient(
                colors: [Color(hex: 0x2D177C, opacity: 0.96), Color(hex: 0x341789, opacity: 0.93), Color(hex: 0x210E68, opacity: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xFF7CBE, opacity: 0.62), lineWidth: 1.5)
        }
        .shadow(color: Color(hex: 0x180343, opacity: 0.36), radius: 14, x: 0, y: 8)
        .overlay(alignment: .topTrailing) {
            Image(systemName: "sparkles")
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: 0xFFE473))
                .padding(.top, 16)
                .padding(.trailing, 26)
                .accessibilityHidden(true)
        }
        .padding(.bottom, 14)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Subcomponents

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
    var isLight: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    if isPro {
                        AppTheme.Gradients.Settings.proCardGradient
                        AppTheme.Gradients.Settings.cardOverlayGradient
                    } else if isLight {
                        LinearGradient(
                            colors: [Color(hex: 0xFFFDFB), Color(hex: 0xFFF4E8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        AppTheme.Gradients.Settings.standardCardGradient
                        AppTheme.Gradients.Settings.cardOverlayGradient
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        isPro
                            ? AppTheme.Colors.Settings.proCardBorder
                            : isLight ? Color(hex: 0xFFE7D5) : AppTheme.Colors.Settings.standardCardBorder,
                        lineWidth: 1
                    )
            }
            .shadow(
                color: isPro
                    ? AppTheme.Colors.Settings.proCardShadow
                    : isLight ? Color(hex: 0x130139, opacity: 0.36) : AppTheme.Colors.Settings.standardCardShadow,
                radius: isPro ? 21 : 19,
                x: 0,
                y: 10
            )
            .padding(.bottom, 16)
    }
}

private struct SettingsFlameMascot: View {
    let size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 10 : 0.1)) { context in
            let frame = reduceMotion
                ? 0
                : Int(context.date.timeIntervalSinceReferenceDate * 10) % 12

            GeometryReader { _ in
                Image(AppAsset.chatFlameIdleSprite.rawValue)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: size * 4, height: size * 3)
                    .offset(
                        x: -CGFloat(frame % 4) * size,
                        y: -CGFloat(frame / 4) * size
                    )
            }
            .frame(width: size, height: size)
            .clipped()
        }
        .frame(width: size, height: size)
        .shadow(color: Color(hex: 0xFFAE64, opacity: 0.45), radius: 20)
        .accessibilityHidden(true)
    }
}

private struct SettingsHeroClouds: View {
    var body: some View {
        HStack(spacing: -34) {
            cloud(width: 126, height: 71, color: Color(hex: 0xA245C5))
                .offset(y: 18)
            cloud(width: 132, height: 62, color: Color(hex: 0x7533AF))
                .offset(y: 23)
            cloud(width: 132, height: 70, color: Color(hex: 0x7E3AB7))
                .offset(y: 17)
            cloud(width: 126, height: 76, color: Color(hex: 0xB34DAF))
                .offset(y: 14)
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private func cloud(width: CGFloat, height: CGFloat, color: Color) -> some View {
        Ellipse()
            .fill(color)
            .frame(width: width, height: height)
            .shadow(color: Color(hex: 0xFF83BE, opacity: 0.6), radius: 8, x: 0, y: -7)
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
