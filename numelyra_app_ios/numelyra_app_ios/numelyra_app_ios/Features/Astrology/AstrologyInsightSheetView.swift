import ComposableArchitecture
import SwiftUI

struct AstrologyInsightSheetView: View {
    let store: StoreOf<AstrologyInsightFeature>

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 10 / 255, green: 23 / 255, blue: 64 / 255),
                    Color(red: 8 / 255, green: 13 / 255, blue: 37 / 255),
                    Color(red: 5 / 255, green: 7 / 255, blue: 22 / 255),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color(red: 190 / 255, green: 232 / 255, blue: 1.0).opacity(0.48))
                    .frame(width: 48, height: 5)
                    .padding(.top, 10)
                    .accessibilityHidden(true)

                headerView

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        insightCard(
                            icon: "eye",
                            iconColor: Color(red: 167 / 255, green: 139 / 255, blue: 250 / 255),
                            title: "Gương soi tâm trí",
                            bodyText: store.fortune.mirror
                        )

                        insightCard(
                            icon: "bolt",
                            iconColor: Color(red: 94 / 255, green: 234 / 255, blue: 212 / 255),
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
                    Color(red: 104 / 255, green: 220 / 255, blue: 1.0).opacity(0.42),
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
                    .foregroundStyle(Color(red: 113 / 255, green: 231 / 255, blue: 1.0))

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
                    .foregroundStyle(Color(red: 231 / 255, green: 247 / 255, blue: 1.0))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color(red: 85 / 255, green: 164 / 255, blue: 217 / 255).opacity(0.14))
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                Color(red: 152 / 255, green: 225 / 255, blue: 1.0).opacity(0.25),
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
                .fill(Color(red: 126 / 255, green: 216 / 255, blue: 1.0).opacity(0.24))
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
                    .foregroundStyle(Color(red: 244 / 255, green: 247 / 255, blue: 1.0))
            }

            Text(bodyText)
                .font(.system(size: 14))
                .lineSpacing(5)
                .foregroundStyle(Color(red: 213 / 255, green: 224 / 255, blue: 242 / 255))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 30 / 255, green: 44 / 255, blue: 91 / 255).opacity(0.58))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    Color(red: 131 / 255, green: 183 / 255, blue: 1.0).opacity(0.22),
                    lineWidth: 1
                )
        )
    }

    private func natalSection(metadata: AstroFeatureMetadata) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionDivider

            Text("Lá số bản mệnh")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(Color(red: 119 / 255, green: 232 / 255, blue: 1.0))

            if let birthDescription = store.birthDescriptionText {
                Text(birthDescription)
                    .font(.system(size: 13))
                    .lineSpacing(4)
                    .foregroundStyle(Color(red: 175 / 255, green: 195 / 255, blue: 217 / 255))
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
                .foregroundStyle(Color(red: 119 / 255, green: 232 / 255, blue: 1.0))

            Text(metadata.vibeSummary)
                .font(.system(size: 13))
                .lineSpacing(4)
                .foregroundStyle(Color(red: 175 / 255, green: 195 / 255, blue: 217 / 255))

            VStack(alignment: .leading, spacing: 7) {
                Text("MẶT TRĂNG QUÁ CẢNH")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(Color(red: 158 / 255, green: 180 / 255, blue: 204 / 255))

                Text(AstrologyInsightFeature.zodiacVi(metadata.transitMoonSign))
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Color.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Color(red: 25 / 255, green: 74 / 255, blue: 111 / 255).opacity(0.48))
            )

            if let topAspect = metadata.topAspect {
                VStack(alignment: .leading, spacing: 5) {
                    Text("GÓC CHIẾU NỔI BẬT")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(Color(red: 196 / 255, green: 167 / 255, blue: 1.0))

                    Text(AstrologyInsightFeature.aspectFormula(for: topAspect))
                        .font(.system(size: 14, weight: .bold))
                        .lineSpacing(3)
                        .foregroundStyle(Color.white)
                        .padding(.top, 2)

                    Text(AstrologyInsightFeature.aspectMeta(for: topAspect))
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 181 / 255, green: 169 / 255, blue: 206 / 255))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 73 / 255, green: 53 / 255, blue: 119 / 255).opacity(0.48))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            Color(red: 193 / 255, green: 156 / 255, blue: 1.0).opacity(0.20),
                            lineWidth: 1
                        )
                )
            }

            VStack(spacing: 12) {
                scoreBar(
                    label: "Hài hòa",
                    value: metadata.scores.harmony,
                    color: Color(red: 94 / 255, green: 234 / 255, blue: 212 / 255)
                )
                scoreBar(
                    label: "Thử thách",
                    value: metadata.scores.tension,
                    color: Color(red: 251 / 255, green: 113 / 255, blue: 133 / 255)
                )
                scoreBar(
                    label: "Hội tụ",
                    value: metadata.scores.conjunction,
                    color: Color(red: 251 / 255, green: 191 / 255, blue: 36 / 255)
                )
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 16 / 255, green: 30 / 255, blue: 70 / 255).opacity(0.72))
            )
        }
    }

    private var anchorCaDaoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionDivider

            Text("Nhịp ca dao neo quẻ")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(Color(red: 119 / 255, green: 232 / 255, blue: 1.0))

            VStack(alignment: .leading, spacing: 10) {
                Text("“\(store.fortune.anchorCaDao.content)”")
                    .font(.system(size: 14, weight: .regular, design: .serif).italic())
                    .lineSpacing(5)
                    .foregroundStyle(Color(red: 227 / 255, green: 236 / 255, blue: 248 / 255))

                if let category = store.anchorCategoryText {
                    Text(category)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 113 / 255, green: 231 / 255, blue: 1.0))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 16 / 255, green: 30 / 255, blue: 70 / 255).opacity(0.66))
            )
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color(red: 113 / 255, green: 231 / 255, blue: 1.0))
                    .frame(width: 2)
                    .padding(.vertical, 6)
            }
        }
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color(red: 111 / 255, green: 205 / 255, blue: 1.0).opacity(0.25))
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
                .foregroundStyle(Color(red: 158 / 255, green: 180 / 255, blue: 204 / 255))

            Text(value)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Color.white)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color(red: 37 / 255, green: 54 / 255, blue: 103 / 255).opacity(0.55))
        )
    }

    private func scoreBar(label: String, value: Double, color: Color) -> some View {
        let percent = AstrologyInsightFeature.scorePercent(value)
        return VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(red: 200 / 255, green: 213 / 255, blue: 230 / 255))
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
