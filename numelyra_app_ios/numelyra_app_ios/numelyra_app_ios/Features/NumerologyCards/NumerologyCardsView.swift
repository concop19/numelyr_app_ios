import ComposableArchitecture
import SwiftUI

struct NumerologyCardsView: View {
    @Bindable var store: StoreOf<NumerologyCardsFeature>
    @State private var scrollPosition: String?

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = min(round(proxy.size.width * 0.62), 260)
            let cardHeight = round(cardWidth * 1.58)

            ZStack {
                Image(appAsset: .numerologyBackground)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [Self.background.opacity(0.45), Self.background.opacity(0.65), Self.background.opacity(0.88)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    categoryTabs

                    if store.filteredIndicators.isEmpty {
                        emptyState
                    } else {
                        carousel(cardWidth: cardWidth, cardHeight: cardHeight, viewportWidth: proxy.size.width)
                        counter
                        Rectangle().fill(Self.gold.opacity(0.4)).frame(height: 1).padding(.horizontal, 34)
                        insightPanel
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            store.send(.onAppear)
            await Task.yield()
            scrollPosition = store.filteredIndicators.first?.id
        }
        .onChange(of: store.selectedCategory) { _, _ in
            withAnimation(.easeOut(duration: 0.25)) {
                scrollPosition = store.filteredIndicators.first?.id
            }
        }
        .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
            IndicatorDetailView(store: detailStore)
                .presentationDetents([.fraction(0.92), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .fullScreenCover(item: $store.scope(state: \.historicalFigure, action: \.historicalFigure)) { figureStore in
            HistoricalFigureView(store: figureStore)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button { store.send(.findFigureTapped) } label: {
                Label("Tri Kỷ 3 Số", systemImage: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Self.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Self.gold.opacity(0.15), in: Capsule())
                    .overlay { Capsule().stroke(Self.gold.opacity(0.45)) }
            }
            .disabled(store.representativeTriple == nil)
            .accessibilityLabel("Tìm nhân vật đồng điệu 3 chỉ số")

            VStack(spacing: 2) {
                Label("Bản Đồ Linh Hồn", systemImage: "sparkles")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(Self.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("Khám phá 24 chỉ số của bạn")
                    .font(.system(size: 11))
                    .foregroundStyle(Self.textSecondary)
            }
            .frame(maxWidth: .infinity)

            if store.showsCloseButton {
                Button { store.send(.closeTapped) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Self.textPrimary.opacity(0.9))
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.1), in: Circle())
                }
                .accessibilityLabel("Đóng")
            } else {
                Color.clear.frame(width: 34, height: 34)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NumerologyCardsFeature.CategoryFilter.allTabs, id: \.id) { tab in
                    let isActive = store.selectedCategory == tab
                    Button { store.send(.categorySelected(tab)) } label: {
                        Text(tab.label)
                            .font(.system(size: 12, weight: isActive ? .bold : .semibold))
                            .foregroundStyle(isActive ? Self.background : Self.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(isActive ? Self.gold : Self.surface.opacity(0.75), in: Capsule())
                            .overlay { Capsule().stroke(isActive ? Self.gold : .white.opacity(0.12)) }
                    }
                    .accessibilityLabel("Nhóm \(tab.label)")
                    .accessibilityAddTraits(isActive ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }

    private func carousel(cardWidth: CGFloat, cardHeight: CGFloat, viewportWidth: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(Array(store.filteredIndicators.enumerated()), id: \.element.id) { index, item in
                    let isActive = index == store.activeIndex
                    Button {
                        store.send(.cardTapped(index: index, indicator: item))
                        if !isActive {
                            withAnimation(.easeOut(duration: 0.25)) { scrollPosition = item.id }
                        }
                    } label: {
                        card(item, isActive: isActive, width: cardWidth, height: cardHeight)
                    }
                    .buttonStyle(.plain)
                    .id(item.id)
                    .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                        content
                            .scaleEffect(phase.isIdentity ? 1 : 0.92)
                            .opacity(phase.isIdentity ? 1 : 0.62)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, max((viewportWidth - cardWidth) / 2, 0), for: .scrollContent)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .onChange(of: scrollPosition) { _, id in
            guard let id,
                  let index = store.filteredIndicators.firstIndex(where: { $0.id == id })
            else { return }
            store.send(.activeIndexChanged(index))
        }
        .frame(height: cardHeight + 10)
    }

    private func card(
        _ item: CalculatedNumerologyIndicator,
        isActive: Bool,
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        ZStack {
            if let asset = AppAsset(rawValue: item.definition.assetName) {
                Image(appAsset: asset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            }

            RoundedRectangle(cornerRadius: 18)
                .stroke(Self.gold.opacity(isActive ? 0.95 : 0.35), lineWidth: isActive ? 2 : 1)
                .padding(7)

            VStack {
                Spacer()
                Text(item.definition.nameEn.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .kerning(1.1)
                    .foregroundStyle(isActive ? Self.background : Self.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(isActive ? Self.gold : Self.surface.opacity(0.93))
                    .padding(.horizontal, 8)
                    .padding(.bottom, 11)
            }
        }
        .frame(width: width, height: height)
        .background(Self.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20).stroke(Self.gold.opacity(isActive ? 0.9 : 0.35), lineWidth: isActive ? 2 : 1)
        }
        .shadow(color: Self.gold.opacity(isActive ? 0.28 : 0.08), radius: isActive ? 15 : 5, y: 6)
        .accessibilityLabel("\(item.definition.nameVi), chỉ số \(item.displayValue)")
        .accessibilityHint(isActive ? "Chạm để mở luận giải" : "Chạm để đưa lá bài vào giữa")
    }

    private var counter: some View {
        Text("✦ \(String(format: "%02d", store.activeIndex + 1)) / \(String(format: "%02d", store.filteredIndicators.count)) ✦")
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundStyle(Self.gold)
            .padding(.vertical, 6)
    }

    @ViewBuilder
    private var insightPanel: some View {
        if let indicator = store.currentIndicator {
            VStack(spacing: 7) {
                Text("\(indicator.definition.categoryNameVi.uppercased()) · SỐ \(indicator.displayValue)")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1.1)
                    .foregroundStyle(Self.gold)

                Text(indicator.definition.nameVi)
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundStyle(Self.textPrimary)
                    .lineLimit(1)

                Text(store.currentSummary)
                    .font(.system(size: 12.5))
                    .lineSpacing(3)
                    .foregroundStyle(Self.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Button { store.send(.findFigureTapped) } label: {
                    Label("Tìm người chung 3 chỉ số với bạn", systemImage: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Self.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 1, green: 228 / 255, blue: 160 / 255),
                                    Self.gold,
                                    Color(red: 209 / 255, green: 154 / 255, blue: 75 / 255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                }
                .disabled(store.representativeTriple == nil)

                Button("Khám phá luận giải chỉ số này ↗") { store.send(.exploreCurrentTapped) }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Self.gold)
            }
            .padding(.horizontal, 22)
            .padding(.top, 9)
            .padding(.bottom, 12)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(Self.gold)
            Text("Chưa có hồ sơ để lập bản đồ")
                .font(.headline)
                .foregroundStyle(Self.textPrimary)
            Text("Hãy tạo hoặc chọn hồ sơ có họ tên và ngày sinh, sau đó mở lại Bản đồ 24 Chỉ số.")
                .font(.subheadline)
                .foregroundStyle(Self.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private static let background = Color(red: 22 / 255, green: 14 / 255, blue: 52 / 255)
    private static let surface = Color(red: 41 / 255, green: 32 / 255, blue: 68 / 255)
    private static let gold = Color(red: 232 / 255, green: 188 / 255, blue: 121 / 255)
    private static let textPrimary = Color(red: 246 / 255, green: 240 / 255, blue: 232 / 255)
    private static let textSecondary = Color(red: 173 / 255, green: 162 / 255, blue: 197 / 255)
}

#Preview("Bản Đồ Linh Hồn") {
    NumerologyCardsView(
        store: Store(
            initialState: NumerologyCardsFeature.State(
                activeProfile: UserProfile(fullName: "Nguyễn Văn An", birthDate: "1998-10-20")
            )
        ) { NumerologyCardsFeature() }
    )
}
