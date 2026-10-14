import ComposableArchitecture
import SwiftUI

struct NumerologyCardsView: View {
    @Bindable var store: StoreOf<NumerologyCardsFeature>

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = max((proxy.size.width - 48) / 2, 120)
            let columns = [
                GridItem(.fixed(cardWidth), spacing: 8),
                GridItem(.fixed(cardWidth), spacing: 8)
            ]

            VStack(spacing: 0) {
                topHeader

                noticeBanner

                categoryTabsBar

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(store.filteredIndicators) { item in
                            cardItemView(item, cardWidth: cardWidth)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.Colors.NumerologyCards.background.ignoresSafeArea())
        }
        .preferredColorScheme(.dark)
        .task {
            store.send(.onAppear)
        }
        .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
            IndicatorDetailView(store: detailStore)
                .presentationDetents([.fraction(0.92), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
    }

    // MARK: - Top Header

    private var topHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.NumerologyCards.goldPrimary)

                    Text("Bản Đồ 24 Chỉ Số Thần Số Học")
                        .font(.system(size: 17, weight: .heavy))
                        .kerning(0.3)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                (
                    Text("Hồ sơ: ")
                        .foregroundStyle(.white.opacity(0.65))
                    + Text(store.displayFullName)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.Colors.NumerologyCards.goldHighlight)
                    + Text(" • Sinh ngày: \(store.displayBirthDate)")
                        .foregroundStyle(.white.opacity(0.65))
                )
                .font(.system(size: 12))
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if store.showsCloseButton {
                Button {
                    store.send(.closeTapped)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Đóng bản đồ 24 chỉ số")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.Colors.NumerologyCards.headerBorder)
                .frame(height: 1)
        }
    }

    // MARK: - Notice Banner

    private var noticeBanner: some View {
        Text("Chạm vào bất kỳ lá bài nào để mở bài luận giải tri thức bản mệnh tức thì.")
            .font(.system(size: 11.5))
            .foregroundStyle(AppTheme.Colors.NumerologyCards.bannerText)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(AppTheme.Colors.NumerologyCards.bannerBg)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.Colors.NumerologyCards.bannerBorder, lineWidth: 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
    }

    // MARK: - Category Filter Tabs

    private var categoryTabsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NumerologyCardsFeature.CategoryFilter.allTabs, id: \.id) { tab in
                    let isActive = store.selectedCategory == tab
                    Button {
                        store.send(.categorySelected(tab))
                    } label: {
                        Text(tab.label)
                            .font(.system(size: 12, weight: isActive ? .bold : .semibold))
                            .foregroundStyle(
                                isActive
                                    ? AppTheme.Colors.NumerologyCards.goldHighlight
                                    : .white.opacity(0.65)
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                isActive
                                    ? AppTheme.Colors.NumerologyCards.tabActiveBg
                                    : .white.opacity(0.06)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(
                                        isActive
                                            ? AppTheme.Colors.NumerologyCards.goldPrimary
                                            : .white.opacity(0.1),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Nhóm \(tab.label)")
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 10)
    }

    // MARK: - Card Item

    private func cardItemView(
        _ item: CalculatedNumerologyIndicator,
        cardWidth: CGFloat
    ) -> some View {
        let imageHeight = cardWidth * 1.38

        return Button {
            store.send(.cardTapped(item))
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    AppTheme.Colors.NumerologyCards.imageFrameBg

                    if let asset = AppAsset(rawValue: item.definition.assetName) {
                        Image(appAsset: asset)
                            .resizable()
                            .scaledToFill()
                            .frame(width: cardWidth, height: imageHeight)
                            .clipped()
                    }

                    // Top-Left Number Badge & Top-Right Category Tag
                    VStack {
                        HStack(alignment: .top) {
                            Text("#\(item.definition.number)")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(AppTheme.Colors.NumerologyCards.goldHighlight)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.Colors.NumerologyCards.badgeOverlayBg)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(AppTheme.Colors.NumerologyCards.numBadgeBorder, lineWidth: 1)
                                }

                            Spacer(minLength: 4)

                            Text(item.definition.categoryNameVi)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.75))
                                .lineLimit(1)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.Colors.NumerologyCards.badgeOverlayBg)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(.white.opacity(0.15), lineWidth: 1)
                                }
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 8)

                        Spacer()

                        // Value Overlay Bottom
                        HStack {
                            Text("Chỉ số:")
                                .font(.system(size: 10.5))
                                .foregroundStyle(.white.opacity(0.6))

                            Spacer(minLength: 4)

                            Text(item.displayValue)
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(
                                    item.isMaster
                                        ? AppTheme.Colors.NumerologyCards.masterValueText
                                        : AppTheme.Colors.NumerologyCards.goldHighlight
                                )
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            item.isMaster
                                ? AppTheme.Colors.NumerologyCards.valueOverlayMasterBg
                                : AppTheme.Colors.NumerologyCards.valueOverlayBg
                        )
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(
                                    item.isMaster
                                        ? AppTheme.Colors.NumerologyCards.valueOverlayMasterBorder
                                        : AppTheme.Colors.NumerologyCards.valueOverlayBorder
                                )
                                .frame(height: 1)
                        }
                    }
                }
                .frame(width: cardWidth, height: imageHeight)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.definition.nameVi)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(item.definition.nameEn)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.NumerologyCards.cardContainerBg)
            }
            .frame(width: cardWidth)
            .background(AppTheme.Colors.NumerologyCards.cardContainerBg)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.Colors.NumerologyCards.cardBorder, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.definition.nameVi), chỉ số \(item.displayValue)")
    }
}

#Preview("Bản Đồ 24 Chỉ Số") {
    NumerologyCardsView(
        store: Store(
            initialState: NumerologyCardsFeature.State(
                activeProfile: UserProfile(
                    fullName: "Nguyễn Văn An",
                    birthDate: "1998-10-20",
                    gender: .male
                )
            )
        ) {
            NumerologyCardsFeature()
        } withDependencies: {
            $0.numerologyClient = .previewValue
            $0.userProfileClient = .previewValue
            $0.hapticClient = .testValue
        }
    )
}
