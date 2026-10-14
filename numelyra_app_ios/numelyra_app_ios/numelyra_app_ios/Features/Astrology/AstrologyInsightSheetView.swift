import ComposableArchitecture
import SwiftUI

struct AstrologyInsightSheetView: View {
    let store: StoreOf<AstrologyInsightFeature>

    var body: some View {
        ZStack {
            AppTheme.Gradients.Astrology.insightSheet
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(AppTheme.Colors.Astrology.sheetDragHandle.opacity(0.48))
                    .frame(width: 48, height: 5)
                    .padding(.top, 10)
                    .accessibilityHidden(true)

                headerView

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        insightCard(
                            icon: "eye",
                            iconColor: AppTheme.Colors.Astrology.mirrorIcon,
                            title: "Gương soi tâm trí",
                            bodyText: store.fortune.mirror
                        )

                        insightCard(
                            icon: "bolt",
                            iconColor: AppTheme.Colors.Astrology.adviceIcon,
                            title: "Kế sách bỏ túi",
                            bodyText: store.fortune.advice
                        )

                        if let metadata = store.metadata {
                            natalSection(metadata: metadata)
                            transitSection(metadata: metadata)
                        }

                        if store.hasAnchorCaDao {
                            anchorCaDaoSection
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 18)
                }
            }
        }
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    AppTheme.Colors.Astrology.sheetBorder.opacity(0.42),
                    lineWidth: 1
                )
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("GIẢI MÃ CHIÊM TINH")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.8)
                    .foregroundStyle(AppTheme.Colors.Astrology.progress)

                Text(store.sheetTitle)
                    .font(.system(size: 21, weight: .regular, design: .serif))
                    .foregroundStyle(Color.white)
            }

            Spacer(minLength: 8)

            Button {
                store.send(.closeTapped)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.Astrology.closeText)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(AppTheme.Colors.Astrology.closeBackground.opacity(0.14))
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                AppTheme.Colors.Astrology.closeBorder.opacity(0.25),
                                lineWidth: 1
                            )
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Đóng")
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.Colors.Astrology.headerDivider.opacity(0.24))
                .frame(height: 0.5)
        }
    }

    private func insightCard(
        icon: String,
        iconColor: Color,
        title: String,
        bodyText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(AppTheme.Colors.Astrology.insightTitle)
            }

            Text(bodyText)
                .font(.system(size: 14))
                .lineSpacing(5)
                .foregroundStyle(AppTheme.Colors.Astrology.insightBody)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.Colors.Astrology.insightCardBackground.opacity(0.58))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    AppTheme.Colors.Astrology.insightCardBorder.opacity(0.22),
                    lineWidth: 1
                )
        )
    }

    private func natalSection(metadata: AstroFeatureMetadata) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionDivider

            Text("Lá số bản mệnh")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(AppTheme.Colors.Astrology.sectionTitle)

            if let birthDescription = store.birthDescriptionText {
                Text(birthDescription)
                    .font(.system(size: 13))
                    .lineSpacing(4)
                    .foregroundStyle(AppTheme.Colors.Astrology.sectionBody)
            }

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    dataCard(
                        label: "MẶT TRỜI BẢN MỆNH",
                        value: AstrologyInsightFeature.zodiacVi(metadata.natalSunSign)
                    )
                    dataCard(
                        label: "MẶT TRĂNG BẢN MỆNH",
                        value: AstrologyInsightFeature.zodiacVi(metadata.natalMoonSign)
                    )
                }

                dataCard(
                    label: "KHÍ CHẤT NỔI TRỘI",
                    value: AstrologyInsightFeature.temperamentSummary(for: metadata),
                    minHeight: 68
                )
            }
        }
    }

    private func transitSection(metadata: AstroFeatureMetadata) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionDivider

            Text("Bầu trời hôm nay")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(AppTheme.Colors.Astrology.sectionTitle)

            Text(metadata.vibeSummary)
                .font(.system(size: 13))
                .lineSpacing(4)
                .foregroundStyle(AppTheme.Colors.Astrology.sectionBody)

            VStack(alignment: .leading, spacing: 7) {
                Text("MẶT TRĂNG QUÁ CẢNH")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(AppTheme.Colors.Astrology.dataLabel)

                Text(AstrologyInsightFeature.zodiacVi(metadata.transitMoonSign))
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Color.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(AppTheme.Colors.Astrology.transitCardBackground.opacity(0.48))
            )

            if let topAspect = metadata.topAspect {
                VStack(alignment: .leading, spacing: 5) {
                    Text("GÓC CHIẾU NỔI BẬT")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(AppTheme.Colors.Astrology.aspectTitle)

                    Text(AstrologyInsightFeature.aspectFormula(for: topAspect))
                        .font(.system(size: 14, weight: .bold))
                        .lineSpacing(3)
                        .foregroundStyle(Color.white)
                        .padding(.top, 2)

                    Text(AstrologyInsightFeature.aspectMeta(for: topAspect))
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.Colors.Astrology.aspectMeta)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.Colors.Astrology.aspectCardBackground.opacity(0.48))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            AppTheme.Colors.Astrology.aspectCardBorder.opacity(0.20),
                            lineWidth: 1
                        )
                )
            }

            VStack(spacing: 12) {
                scoreBar(
                    label: "Hài hòa",
                    value: metadata.scores.harmony,
                    color: AppTheme.Colors.Astrology.adviceIcon
                )
                scoreBar(
                    label: "Thử thách",
                    value: metadata.scores.tension,
                    color: AppTheme.Colors.Astrology.tensionScore
                )
                scoreBar(
                    label: "Hội tụ",
                    value: metadata.scores.conjunction,
                    color: AppTheme.Colors.Astrology.conjunctionScore
                )
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.Colors.Astrology.scoreCardBackground.opacity(0.72))
            )
        }
    }

    private var anchorCaDaoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionDivider

            Text("Nhịp ca dao neo quẻ")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(AppTheme.Colors.Astrology.sectionTitle)

            VStack(alignment: .leading, spacing: 10) {
                Text("“\(store.fortune.anchorCaDao.content)”")
                    .font(.system(size: 14, weight: .regular, design: .serif).italic())
                    .lineSpacing(5)
                    .foregroundStyle(AppTheme.Colors.Astrology.caDaoText)

                if let category = store.anchorCategoryText {
                    Text(category)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.Astrology.progress)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.Colors.Astrology.scoreCardBackground.opacity(0.66))
            )
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(AppTheme.Colors.Astrology.progress)
                    .frame(width: 2)
                    .padding(.vertical, 6)
            }
        }
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(AppTheme.Colors.Astrology.sectionDivider.opacity(0.25))
            .frame(height: 0.5)
            .padding(.vertical, 4)
    }

    private func dataCard(
        label: String,
        value: String,
        minHeight: CGFloat = 82
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(AppTheme.Colors.Astrology.dataLabel)

            Text(value)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Color.white)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(AppTheme.Colors.Astrology.dataCardBackground.opacity(0.55))
        )
    }

    private func scoreBar(label: String, value: Double, color: Color) -> some View {
        let percent = AstrologyInsightFeature.scorePercent(value)
        return VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.Astrology.scoreLabel)
                Spacer()
                Text("\(percent)%")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(color)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 5)

                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * CGFloat(percent) / 100.0, height: 5)
                }
            }
            .frame(height: 5)
        }
    }
}
