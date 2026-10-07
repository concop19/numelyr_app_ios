import ComposableArchitecture
import SwiftUI

struct IndicatorDetailView: View {
    let store: StoreOf<IndicatorDetailFeature>

    var body: some View {
        VStack(spacing: 0) {
            headerRow

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroSection
                        .padding(.top, 18)

                    knowledgeBanner
                        .padding(.top, 18)
                        .padding(.bottom, 14)

                    if store.isLoading {
                        loadingSection
                    } else if let reading = store.reading {
                        readingSection(reading)
                    }

                    Spacer()
                        .frame(height: 36)
                }
                .padding(.horizontal, 20)
            }

            footerRow
        }
        .background(DetailPalette.modalBackground.ignoresSafeArea())
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(DetailPalette.modalBorder, lineWidth: 1)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
        }
        .preferredColorScheme(.dark)
        .task {
            store.send(.onAppear)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            HStack(spacing: 10) {
                Text("#\(store.indicator.definition.number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DetailPalette.goldText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(DetailPalette.numberBadgeBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(DetailPalette.numberBadgeBorder, lineWidth: 1)
                    }

                Text(store.indicator.definition.categoryNameVi.uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            Button {
                store.send(.closeTapped)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Đóng luận giải chi tiết")
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                DetailPalette.imagePlaceholder

                if let asset = AppAsset(rawValue: store.indicator.definition.assetName) {
                    Image(appAsset: asset)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 105, height: 155)
                        .clipped()
                }

                DetailPalette.cardGlowOverlay
            }
            .frame(width: 105, height: 155)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DetailPalette.cardImageBorder, lineWidth: 1.5)
            }
            .shadow(color: DetailPalette.goldPrimary.opacity(0.25), radius: 10, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 0) {
                Text(store.indicator.definition.nameVi)
                    .font(.system(size: 20, weight: .bold))
                    .kerning(0.3)
                    .foregroundStyle(.white)

                Text(store.indicator.definition.nameEn)
                    .font(.system(size: 12, weight: .regular))
                    .italic()
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.top, 2)

                HStack(spacing: 8) {
                    Text("Kết quả của bạn:")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))

                    Text(store.indicator.displayValue)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(
                            store.indicator.isMaster
                                ? DetailPalette.masterValueText
                                : DetailPalette.goldText
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            store.indicator.isMaster
                                ? DetailPalette.masterPillBg
                                : DetailPalette.valuePillBg
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    store.indicator.isMaster
                                        ? DetailPalette.masterPillBorder
                                        : DetailPalette.goldPrimary,
                                    lineWidth: 1
                                )
                        }

                    if store.indicator.isMaster {
                        Text("Master")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DetailPalette.masterTagText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DetailPalette.masterTagBg)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
                .padding(.top, 10)

                Text(store.indicator.definition.description)
                    .font(.system(size: 12))
                    .lineSpacing(4)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Knowledge Banner

    private var knowledgeBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "book")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DetailPalette.goldText)

            Text("Luận giải tri thức chuẩn Pythagoras • Tức thì & Không qua AI")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.65))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    // MARK: - Loading

    private var loadingSection: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
                .tint(DetailPalette.goldPrimary)

            Text("Đang tra cứu kho tri thức bản mệnh...")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    // MARK: - Reading Content

    private func readingSection(_ reading: KnowledgeReading) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. Bản Chất Cốt Lõi & Năng Lượng
            sectionCard {
                sectionTitle(
                    icon: "sparkles",
                    iconColor: DetailPalette.goldText,
                    title: "Bản Chất Cốt Lõi & Năng Lượng",
                    titleColor: .white
                )

                Text(reading.overview)
                    .font(.system(size: 13.5))
                    .lineSpacing(5)
                    .foregroundStyle(.white.opacity(0.82))
            }

            // 2. Điểm Mạnh Tự Nhiên
            if !reading.strengths.isEmpty {
                sectionCard {
                    sectionTitle(
                        icon: "suit.diamond",
                        iconColor: DetailPalette.cyanIcon,
                        title: "Điểm Mạnh Tự Nhiên",
                        titleColor: .white
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(reading.strengths.enumerated()), id: \.offset) { _, item in
                            bulletRow(text: item, dotColor: DetailPalette.greenBullet)
                        }
                    }
                }
            }

            // 3. Vùng Bóng Tối Cần Lưu Ý
            if !reading.challenges.isEmpty {
                sectionCard {
                    sectionTitle(
                        icon: "moon",
                        iconColor: DetailPalette.purpleIcon,
                        title: "Vùng Bóng Tối Cần Lưu Ý",
                        titleColor: .white
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(reading.challenges.enumerated()), id: \.offset) { _, item in
                            bulletRow(text: item, dotColor: DetailPalette.redBullet)
                        }
                    }
                }
            }

            // 4. Lời Khuyên & Bước Chuyển Hóa
            if !reading.advice.isEmpty {
                sectionCard(isAdvice: true) {
                    sectionTitle(
                        icon: "leaf",
                        iconColor: DetailPalette.mintIcon,
                        title: "Lời Khuyên & Bước Chuyển Hóa",
                        titleColor: DetailPalette.goldText
                    )

                    Text(reading.advice)
                        .font(.system(size: 13.5))
                        .italic()
                        .lineSpacing(5)
                        .foregroundStyle(DetailPalette.adviceBodyText)
                }
            }

            // 5. Toàn Văn Chi Tiết Sách Gốc
            if store.canExpandFullArticle, let fullContent = reading.fullContent {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        store.send(.toggleFullArticleTapped)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: store.isFullArticleExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DetailPalette.expandBlue)

                            Text(
                                store.isFullArticleExpanded
                                    ? "Thu gọn bài luận giải"
                                    : "Đọc toàn văn tư liệu gốc"
                            )
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(DetailPalette.expandBlue)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)

                    if store.isFullArticleExpanded {
                        Text(fullContent)
                            .font(.system(size: 12))
                            .lineSpacing(4)
                            .foregroundStyle(.white.opacity(0.72))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(.black.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(.white.opacity(0.05), lineWidth: 1)
                            }
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private func sectionCard<Content: View>(
        isAdvice: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(isAdvice ? DetailPalette.adviceBg : .white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isAdvice ? DetailPalette.adviceBorder : .white.opacity(0.07), lineWidth: 1)
        }
    }

    private func sectionTitle(
        icon: String,
        iconColor: Color,
        title: String,
        titleColor: Color
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.system(size: 14, weight: .bold))
                .kerning(0.3)
                .foregroundStyle(titleColor)
        }
    }

    private func bulletRow(text: String, dotColor: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 11))
                .foregroundStyle(dotColor)
                .padding(.top, 4)

            Text(text)
                .font(.system(size: 13))
                .lineSpacing(4)
                .foregroundStyle(.white.opacity(0.82))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Footer

    private var footerRow: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)

            Button {
                store.send(.confirmCloseTapped)
            } label: {
                Text("Đã Hiểu • Quay Lại 24 Lá Bài")
                    .font(.system(size: 14.5, weight: .bold))
                    .kerning(0.5)
                    .foregroundStyle(DetailPalette.footerBtnText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DetailPalette.goldPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: DetailPalette.goldPrimary.opacity(0.35), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(DetailPalette.modalBackground)
    }
}

private enum DetailPalette {
    static let modalBackground = Color(red: 13 / 255, green: 18 / 255, blue: 36 / 255) // #0D1224
    static let modalBorder = Color(red: 212 / 255, green: 175 / 255, blue: 55 / 255).opacity(0.28)
    static let numberBadgeBg = Color(red: 212 / 255, green: 175 / 255, blue: 55 / 255).opacity(0.15)
    static let numberBadgeBorder = Color(red: 212 / 255, green: 175 / 255, blue: 55 / 255).opacity(0.35)
    static let goldPrimary = Color(red: 229 / 255, green: 169 / 255, blue: 60 / 255) // #E5A93C
    static let goldText = Color(red: 252 / 255, green: 211 / 255, blue: 77 / 255) // #FCD34D
    static let imagePlaceholder = Color(red: 30 / 255, green: 41 / 255, blue: 59 / 255) // #1E293B
    static let cardImageBorder = Color(red: 229 / 255, green: 169 / 255, blue: 60 / 255).opacity(0.45)
    static let cardGlowOverlay = Color(red: 229 / 255, green: 169 / 255, blue: 60 / 255).opacity(0.04)
    static let valuePillBg = Color(red: 229 / 255, green: 169 / 255, blue: 60 / 255).opacity(0.18)
    static let masterPillBg = Color(red: 245 / 255, green: 158 / 255, blue: 11 / 255).opacity(0.30)
    static let masterPillBorder = Color(red: 245 / 255, green: 158 / 255, blue: 11 / 255) // #F59E0B
    static let masterValueText = Color(red: 254 / 255, green: 240 / 255, blue: 138 / 255) // #FEF08A
    static let masterTagBg = Color(red: 124 / 255, green: 58 / 255, blue: 237 / 255) // #7C3AED
    static let masterTagText = Color(red: 237 / 255, green: 233 / 255, blue: 254 / 255) // #EDE9FE
    static let cyanIcon = Color(red: 125 / 255, green: 211 / 255, blue: 252 / 255) // #7DD3FC
    static let greenBullet = Color(red: 52 / 255, green: 211 / 255, blue: 153 / 255) // #34D399
    static let purpleIcon = Color(red: 196 / 255, green: 181 / 255, blue: 253 / 255) // #C4B5FD
    static let redBullet = Color(red: 248 / 255, green: 113 / 255, blue: 113 / 255) // #F87171
    static let mintIcon = Color(red: 167 / 255, green: 243 / 255, blue: 208 / 255) // #A7F3D0
    static let adviceBg = Color(red: 229 / 255, green: 169 / 255, blue: 60 / 255).opacity(0.08)
    static let adviceBorder = Color(red: 229 / 255, green: 169 / 255, blue: 60 / 255).opacity(0.25)
    static let adviceBodyText = Color(red: 254 / 255, green: 243 / 255, blue: 199 / 255) // #FEF3C7
    static let expandBlue = Color(red: 147 / 255, green: 197 / 255, blue: 253 / 255) // #93C5FD
    static let footerBtnText = Color(red: 10 / 255, green: 14 / 255, blue: 26 / 255) // #0A0E1A
}
