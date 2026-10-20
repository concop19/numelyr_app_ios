import ComposableArchitecture
import SwiftUI
import UIKit

struct HistoricalFigureView: View {
    @Bindable var store: StoreOf<HistoricalFigureFeature>

    var body: some View {
        ZStack {
            Color(red: 10 / 255, green: 9 / 255, blue: 20 / 255).ignoresSafeArea()
            VStack(spacing: 0) {
                controls
                content
            }
        }
        .preferredColorScheme(.dark)
        .task { store.send(.onAppear) }
        .sheet(
            isPresented: Binding(
                get: { store.shareText != nil },
                set: { if !$0 { store.send(.shareDismissed) } }
            )
        ) {
            if let shareText = store.shareText {
                ActivityShareView(items: [shareText])
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Spacer()
            Button { store.send(.shareTapped) } label: {
                Image(systemName: "square.and.arrow.up")
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.12), in: Circle())
            }
            .disabled(store.figure == nil)
            .accessibilityLabel("Chia sẻ")

            Button { store.send(.closeTapped) } label: {
                Image(systemName: "xmark")
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.12), in: Circle())
            }
            .accessibilityLabel("Đóng")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .loading:
            VStack(spacing: 16) {
                ProgressView().controlSize(.large).tint(Self.gold)
                Text("Đang truy vấn kho tàng lịch sử nhân loại...")
                    .foregroundStyle(.white.opacity(0.68))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            messageState(
                icon: "safari",
                title: "Chưa tìm thấy nhân vật tương ứng",
                message: "Hệ thống đang tiếp tục cập nhật dữ liệu nhân vật cho bộ số của bạn."
            )

        case let .failed(message):
            messageState(icon: "exclamationmark.triangle", title: "Không thể tra cứu", message: message, canRetry: true)

        case .loaded:
            if let figure = store.figure { figureContent(figure) }
        }
    }

    private func messageState(icon: String, title: String, message: String, canRetry: Bool = false) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 50)).foregroundStyle(.white.opacity(0.42))
            Text(title).font(.title3.bold()).foregroundStyle(.white)
            Text(message).font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.58))
            if canRetry {
                Button("Thử lại") { store.send(.retryTapped) }
                    .buttonStyle(.borderedProminent).tint(Self.gold).foregroundStyle(Color(red: 22 / 255, green: 14 / 255, blue: 52 / 255))
            }
            Button("Quay lại Bản đồ") { store.send(.closeTapped) }
                .foregroundStyle(Self.gold)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func figureContent(_ figure: NumerologyRepresentative) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                portrait(figure)
                VStack(spacing: 4) {
                    Text(store.displayName)
                        .font(.system(size: 27, weight: .bold))
                        .multilineTextAlignment(.center)
                    if let originalName = store.originalName {
                        Text("(\(originalName))").font(.subheadline).foregroundStyle(.white.opacity(0.55))
                    }
                }

                FlowLayout(spacing: 8) {
                    if !figure.lifespan.isEmpty { badge(icon: "clock", text: figure.lifespan, color: Self.gold) }
                    badge(icon: "text.bubble", text: "\(figure.sitelinks) bài viết", color: Color(red: 141 / 255, green: 160 / 255, blue: 248 / 255))
                    badge(icon: "sparkles", text: figure.matchType.labelVi, color: Color(red: 1, green: 101 / 255, blue: 132 / 255))
                }

                numbers(figure)
                biography(figure)

                if figure.wikipediaURL.flatMap({ URL(string: $0) }) != nil {
                    Button { store.send(.openSourceTapped) } label: {
                        HStack {
                            Image(systemName: "globe")
                            Text("Khám phá trên Wikipedia")
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Self.gold)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 42 / 255, green: 33 / 255, blue: 72 / 255), Color(red: 29 / 255, green: 22 / 255, blue: 53 / 255)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 15)
                        )
                    }
                }

                Button { store.send(.closeTapped) } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color(red: 1, green: 79 / 255, blue: 153 / 255))
                        .frame(width: 48, height: 34)
                }
                .accessibilityLabel("Quay lại Bản đồ")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
    }

    private func portrait(_ figure: NumerologyRepresentative) -> some View {
        ZStack {
            LinearGradient(colors: [Color(red: 30 / 255, green: 22 / 255, blue: 59 / 255), Color(red: 18 / 255, green: 13 / 255, blue: 37 / 255)], startPoint: .top, endPoint: .bottom)
            if let data = store.imageData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                VStack(spacing: 10) {
                    if store.isImageLoading { ProgressView().tint(Self.gold) }
                    Image(systemName: "person.crop.circle").font(.system(size: 80)).foregroundStyle(Self.gold)
                    Text(store.displayName).font(.headline).foregroundStyle(Self.gold)
                }
            }
            LinearGradient(colors: [.clear, Color.black.opacity(0.75)], startPoint: .center, endPoint: .bottom)
        }
        .frame(maxWidth: 400)
        .frame(height: min(UIScreen.main.bounds.height * 0.46, 390))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 18, y: 10)
    }

    private func numbers(_ figure: NumerologyRepresentative) -> some View {
        HStack {
            number("Đường đời", figure.lifePath)
            Divider().overlay(Self.gold.opacity(0.25)).frame(height: 28)
            number("Sứ mệnh", figure.expression)
            Divider().overlay(Self.gold.opacity(0.25)).frame(height: 28)
            number("Linh hồn", figure.soulUrge)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Self.gold.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(Self.gold.opacity(0.22)) }
    }

    private func number(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text(label.uppercased()).font(.system(size: 10)).foregroundStyle(.white.opacity(0.58))
            Text("\(value)").font(.title3.bold()).foregroundStyle(Self.gold)
        }
        .frame(maxWidth: .infinity)
    }

    private func biography(_ figure: NumerologyRepresentative) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 4) {
                languageButton(.vietnamese, title: "Tiếng Việt", icon: "character.book.closed")
                languageButton(.english, title: "English", icon: "globe")
            }
            .padding(3)
            .background(.white.opacity(0.07), in: Capsule())

            Text(store.biography)
                .font(.system(size: 14))
                .lineSpacing(5)
                .foregroundStyle(.white.opacity(0.78))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(store.isBiographyExpanded ? nil : 6)

            if store.biography.count > 250 {
                Button(biographyToggleTitle) {
                    store.send(.toggleBiographyTapped)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Self.gold)
            }
        }
    }

    private var biographyToggleTitle: String {
        switch (store.language, store.isBiographyExpanded) {
        case (.vietnamese, false): return "Đọc trọn vẹn tiểu sử ▾"
        case (.vietnamese, true): return "Thu gọn ▴"
        case (.english, false): return "Read full biography ▾"
        case (.english, true): return "Collapse ▴"
        }
    }

    private func languageButton(_ language: RepresentativeLanguage, title: String, icon: String) -> some View {
        Button { store.send(.languageSelected(language)) } label: {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(store.language == language ? Color(red: 22 / 255, green: 14 / 255, blue: 52 / 255) : .white.opacity(0.65))
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
                .background(store.language == language ? Self.gold : .clear, in: Capsule())
        }
    }

    private func badge(icon: String, text: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12), in: Capsule())
    }

    private static let gold = Color(red: 232 / 255, green: 188 / 255, blue: 121 / 255)
}

private struct ActivityShareView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var measuredWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth > 0, rowWidth + spacing + size.width > maxWidth {
                measuredWidth = max(measuredWidth, rowWidth)
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += (rowWidth == 0 ? 0 : spacing) + size.width
            rowHeight = max(rowHeight, size.height)
        }
        measuredWidth = max(measuredWidth, rowWidth)
        return CGSize(width: min(measuredWidth, maxWidth), height: totalHeight + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var horizontalPosition = bounds.minX
        var verticalPosition = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if horizontalPosition > bounds.minX, horizontalPosition + size.width > bounds.maxX {
                horizontalPosition = bounds.minX
                verticalPosition += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: horizontalPosition, y: verticalPosition),
                proposal: ProposedViewSize(size)
            )
            horizontalPosition += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
