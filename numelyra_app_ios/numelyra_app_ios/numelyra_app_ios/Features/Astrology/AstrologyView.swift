import ComposableArchitecture
import SwiftUI
import UIKit

struct AstrologyView: View {
    @Bindable var store: StoreOf<AstrologyFeature>
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            AstrologyTodayContent(store: store)
        } destination: { pathStore in
            switch pathStore.case {
            case let .natal(natalStore):
                AstrologyNatalChartView(
                    store: natalStore,
                    profile: store.profile,
                    metadata: store.metadata,
                    calculationError: store.calculationErrorMessage
                )
            case let .detail(detailStore):
                AstrologyDetailView(store: detailStore, metadata: store.metadata)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            store.send(.scenePhaseChanged(isActive: scenePhase == .active))
            store.send(.onAppear)
        }
        .onDisappear { store.send(.onDisappear) }
        .onChange(of: scenePhase) { _, phase in
            store.send(.scenePhaseChanged(isActive: phase == .active))
        }
        .sheet(item: $store.scope(state: \.$destination, action: \.destination).profilePicker) {
            AstrologyProfilePickerView(store: $0)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $store.scope(state: \.$destination, action: \.destination).birthData) {
            AstrologyBirthDataView(store: $0)
                .presentationDetents([.fraction(0.86), .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $store.scope(state: \.insight, action: \.insight)) { insightStore in
            AstrologyInsightSheetView(store: insightStore)
                .presentationDetents([.fraction(0.88), .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
        }
        .sheet(
            item: Binding(
                get: { store.sharePayload },
                set: { if $0 == nil { store.send(.shareSheetDismissed) } }
            )
        ) { payload in
            AstrologyActivityShareSheet(payload: payload)
        }
    }
}

private struct AstrologyTodayContent: View {
    let store: StoreOf<AstrologyFeature>

    var body: some View {
        AstrologyBackground(asset: .astrologyBackgroundToday) {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 14) {
                    if let profile = store.profile {
                        hero(profile: profile)
                    } else {
                        missingProfile
                    }

                    if let calculationError = store.calculationErrorMessage, store.profile != nil {
                        AstrologyCard {
                            Label(calculationError, systemImage: "exclamationmark.triangle")
                                .font(.footnote)
                                .foregroundStyle(Color.pink.opacity(0.9))
                        }
                    }

                    if let metadata = store.metadata {
                        calendarSummary(metadata)
                        if metadata.birthDataPrecision != .complete {
                            precisionCallout(metadata)
                        }
                        planetGuidance(metadata)
                        natalCallToAction
                        interpretation(metadata)
                    }

                    if store.isLoading, store.metadata != nil, store.fortune == nil {
                        HStack(spacing: 9) {
                            ProgressView().tint(AstrologyPalette.cyan)
                            Text("Đang tải phần luận giải trực tuyến…")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

                    if let error = store.errorMessage {
                        networkError(error)
                    }
                }
                .frame(maxWidth: 720)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func hero(profile: UserProfile) -> some View {
        ZStack(alignment: .top) {
            Image(appAsset: .astrologyBackgroundToday)
                .resizable()
                .scaledToFill()
                .frame(height: 340)
                .clipped()
            LinearGradient(
                colors: [.clear, AstrologyPalette.deep.opacity(0.18), AstrologyPalette.deep.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
            Image(appAsset: .astrologyShootingStar)
                .resizable()
                .scaledToFit()
                .frame(width: 76, height: 76)
                .opacity(0.58)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 76)
                .padding(.trailing, 18)

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Button { store.send(.profileTapped) } label: {
                        HStack(spacing: 9) {
                            zodiacAvatar
                            VStack(alignment: .leading, spacing: 3) {
                                Text(profile.fullName)
                                    .font(.system(size: 17, weight: .bold, design: .serif))
                                    .lineLimit(1)
                                Text(profileSubtitle(profile))
                                    .font(.caption2)
                                    .foregroundStyle(AstrologyPalette.muted)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 2)
                            Image(systemName: "chevron.down")
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 7)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(.ultraThinMaterial.opacity(0.55), in: Capsule())
                        .overlay(Capsule().stroke(AstrologyPalette.gold.opacity(0.4)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Đổi hồ sơ, hiện tại là \(profile.fullName)")

                    Button { store.send(.shareTapped) } label: {
                        Image(appAsset: .astrologyShareIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .frame(width: 44, height: 44)
                            .background(AstrologyPalette.deep.opacity(0.72), in: Circle())
                            .overlay(Circle().stroke(AstrologyPalette.gold.opacity(0.5)))
                    }
                    .disabled(store.fortune == nil || store.isLoading)
                    .opacity(store.fortune == nil || store.isLoading ? 0.45 : 1)
                    .accessibilityLabel("Chia sẻ luận giải hôm nay")
                }
                .padding(12)

                Button { store.send(.openInsightTapped) } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("THÔNG ĐIỆP HÔM NAY")
                            .font(.caption2.bold())
                            .tracking(1.5)
                            .foregroundStyle(AstrologyPalette.gold)
                        if store.isLoading, store.fortune == nil {
                            HStack {
                                ProgressView().tint(AstrologyPalette.gold)
                                Text("Đang đọc bầu trời của bạn…")
                            }
                            .font(.footnote)
                            .foregroundStyle(AstrologyPalette.muted)
                        } else {
                            Text(store.fortune?.verse ?? store.metadata?.vibeSummary ?? "Chạm để xem bức tranh năng lượng hôm nay.")
                                .font(.system(size: 17, design: .serif).italic())
                                .lineSpacing(4)
                                .lineLimit(4)
                                .multilineTextAlignment(.leading)
                        }
                        Label("Xem luận giải", systemImage: "arrow.right")
                            .font(.footnote.bold())
                            .foregroundStyle(AstrologyPalette.gold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(AstrologyPalette.deep.opacity(0.32), in: RoundedRectangle(cornerRadius: 19))
                    .overlay(RoundedRectangle(cornerRadius: 19).stroke(AstrologyPalette.gold.opacity(0.18)))
                }
                .buttonStyle(.plain)
                .disabled(store.fortune == nil)
                .padding(.horizontal, 20)
                .padding(.top, 32)
            }
        }
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(AstrologyPalette.violetBorder.opacity(0.56)))
    }

    @ViewBuilder
    private var zodiacAvatar: some View {
        if let raw = store.metadata?.natalSunSign, let sign = AstrologyZodiacID(rawValue: raw) {
            Image(appAsset: AppAsset.astrologyZodiac(sign))
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(AstrologyPalette.gold, lineWidth: 1.5))
        } else {
            Text(String(store.profile?.fullName.first ?? "✦"))
                .font(.title2.bold())
                .frame(width: 40, height: 40)
                .background(AstrologyPalette.purple, in: Circle())
                .overlay(Circle().stroke(AstrologyPalette.gold, lineWidth: 1.5))
        }
    }

    private var missingProfile: some View {
        AstrologyCard {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 42))
                    .foregroundStyle(AstrologyPalette.gold)
                Text("Chưa có hồ sơ để dựng lá số")
                    .font(.title3.bold())
                Text("Chọn một hồ sơ có ngày sinh để bắt đầu.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Chọn hồ sơ") { store.send(.profileTapped) }
                    .buttonStyle(.borderedProminent)
                    .tint(AstrologyPalette.purple)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 26)
        }
    }

    private func calendarSummary(_ metadata: AstroFeatureMetadata) -> some View {
        AstrologyPaperCard {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("HÔM NAY")
                            .font(.caption2.bold())
                            .tracking(1.2)
                            .foregroundStyle(Color(hex: 0x7555A4))
                        Text(store.currentDate.formatted(Date.FormatStyle(date: .long, time: .omitted, locale: .appVietnamese)))
                            .font(.system(size: 18, weight: .bold, design: .serif))
                            .foregroundStyle(AstrologyPalette.paperText)
                    }
                    Spacer()
                    Image(appAsset: .astrologyCalendarIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                HStack(spacing: 7) {
                    summaryTile("Năng lượng", value: dominantLabel(metadata.dominantSignal), icon: "sparkles")
                    summaryTile("Cảm xúc", value: zodiacLabel(metadata.transitMoonSign), icon: "moon.stars")
                }
                HStack(spacing: 7) {
                    summaryTile("Góc nổi bật", value: metadata.topAspect?.nameVi ?? "Chưa có góc chính", icon: "point.3.connected.trianglepath.dotted")
                    summaryTile("Trọng tâm", value: metadata.dailyContext?.activatedHouses.first.map { "Nhà \($0.house) · \($0.topicVi)" } ?? "Giữ nhịp", icon: "scope")
                }
            }
        }
        .padding(.top, -48)
    }

    private func summaryTile(_ title: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(Color(hex: 0x7555A4))
                .frame(width: 30, height: 30)
                .background(Color(hex: 0x7555A4).opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 8.5, weight: .heavy))
                    .foregroundStyle(Color(hex: 0x65557A))
                Text(value)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AstrologyPalette.paperText)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
        .background(Color.white.opacity(0.54), in: RoundedRectangle(cornerRadius: 17))
    }

    private func precisionCallout(_ metadata: AstroFeatureMetadata) -> some View {
        Button { store.send(.birthDataTapped) } label: {
            HStack(spacing: 10) {
                Image(systemName: "compass.drawing")
                    .font(.title3)
                    .foregroundStyle(AstrologyPalette.cyan)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Hoàn thiện dữ liệu lá số").font(.subheadline.bold())
                    Text(precisionMessage(metadata)).font(.caption).foregroundStyle(AstrologyPalette.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(AstrologyPalette.gold)
            }
            .padding(12)
            .background(Color(hex: 0x142A5B).opacity(0.9), in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).stroke(AstrologyPalette.cyan.opacity(0.32)))
        }
        .buttonStyle(.plain)
    }

    private func planetGuidance(_ metadata: AstroFeatureMetadata) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .bottom) {
                AstrologySectionTitle(eyebrow: "PLANETARY GUIDANCE", title: "Dẫn đường hành tinh")
                Spacer()
                Button("Lá số") { store.send(.natalTapped) }
                    .font(.footnote.bold())
                    .foregroundStyle(AstrologyPalette.gold)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(AstrologyPlanetID.allCases, id: \.self) { planet in
                        Button { store.send(.detailTapped(.planet(planet), mode: .transit)) } label: {
                            planetCard(planet, metadata: metadata)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func planetCard(_ planet: AstrologyPlanetID, metadata: AstroFeatureMetadata) -> some View {
        let placement = metadata.transitPlanets?.first { $0.name == planet.rawValue }
        let aspect = metadata.notableTransitAspects?.first { $0.transitPlanet == planet.rawValue }
        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Image(appAsset: .astrologyBackgroundPlanetDetail)
                    .resizable().scaledToFill().frame(width: 185, height: 158).clipped()
                Image(appAsset: AppAsset.astrologyPlanetArtwork(planet))
                    .resizable().scaledToFit().frame(width: 126, height: 118)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(planet.nameVi).font(.headline.weight(.heavy))
                        Spacer()
                        Text(planet.symbol).font(.title2).foregroundStyle(AstrologyPalette.gold)
                    }
                    Text(planet.themes).font(.system(size: 8, weight: .heavy)).foregroundStyle(AstrologyPalette.pink)
                }
                .padding(12)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(aspect.map { "\($0.nameVi) · orb \(String(format: "%.1f", $0.orb))°" } ?? placement.map { zodiacLabel($0.sign) } ?? "Chưa có góc nổi bật")
                    .font(.caption)
                    .lineLimit(3)
                Text(aspect.map { natureLabel($0.nature) } ?? "NHỊP HIỆN TẠI")
                    .font(.caption2.bold())
                    .tracking(0.8)
                    .foregroundStyle(AstrologyPalette.cyan)
            }
            .padding(12)
        }
        .frame(width: 185, height: 252, alignment: .top)
        .background(AstrologyPalette.purple.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(AstrologyPalette.violetBorder.opacity(0.7)))
    }

    private var natalCallToAction: some View {
        Button { store.send(.natalTapped) } label: {
            HStack(spacing: 12) {
                Text("✦").font(.largeTitle).frame(width: 48, height: 48).background(.white.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("Khám phá Natal Chart").font(.system(size: 17, weight: .bold, design: .serif))
                    Text("12 cung, vị trí hành tinh và các góc bản mệnh").font(.caption).foregroundStyle(.white.opacity(0.82))
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill").font(.title).foregroundStyle(AstrologyPalette.gold)
            }
            .padding(14)
            .background(LinearGradient(colors: [Color(hex: 0x8C58F5), Color(hex: 0x5D45CA), Color(hex: 0x283B9E)], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 21))
        }
        .buttonStyle(.plain)
    }

    private func interpretation(_ metadata: AstroFeatureMetadata) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            AstrologySectionTitle(eyebrow: "TODAY'S INTERPRETATION", title: "Luận giải hôm nay")
            Button { store.send(.openInsightTapped) } label: {
                HStack(alignment: .top, spacing: 11) {
                    Image(systemName: "sparkles").font(.title3).foregroundStyle(AstrologyPalette.gold)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.fortune?.title ?? "Bức tranh năng lượng hiện tại").font(.headline)
                        Text(store.fortune?.mirror ?? metadata.vibeSummary).font(.subheadline).foregroundStyle(AstrologyPalette.muted).lineLimit(4)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(AstrologyPalette.lavender)
                }
                .padding(15)
                .background(AstrologyPalette.purple.opacity(0.9), in: RoundedRectangle(cornerRadius: 21))
                .overlay(RoundedRectangle(cornerRadius: 21).stroke(AstrologyPalette.violetBorder.opacity(0.35)))
            }
            .buttonStyle(.plain)
            .disabled(store.fortune == nil)
        }
    }

    private func networkError(_ message: String) -> some View {
        AstrologyCard {
            HStack(spacing: 10) {
                Image(systemName: "icloud.slash").foregroundStyle(.pink)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Luận giải trực tuyến tạm gián đoạn").font(.subheadline.bold())
                    Text(message).font(.caption).foregroundStyle(AstrologyPalette.muted)
                }
                Spacer()
                Button { store.send(.retryTapped) } label: { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.bordered)
            }
        }
    }

    private func profileSubtitle(_ profile: UserProfile) -> String {
        let sign = store.metadata.map { zodiacLabel($0.natalSunSign) }
        return [profile.birthDate, sign].compactMap { $0 }.joined(separator: " · ")
    }
}

struct AstrologyProfilePickerView: View {
    let store: StoreOf<AstrologyProfilePickerFeature>

    var body: some View {
        NavigationStack {
            List(store.profiles) { profile in
                Button { store.send(.profileTapped(profile.id)) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.fullName).font(.headline)
                            Text(profile.birthDate).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if store.selectedID == profile.id {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(AstrologyPalette.gold)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
            .navigationTitle("Chọn hồ sơ")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { store.send(.closeTapped) }
                }
            }
        }
    }
}

struct AstrologyBirthDataView: View {
    @Bindable var store: StoreOf<AstrologyBirthDataFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Numelyra dùng nơi sinh để xác định múi giờ và 12 nhà. Ứng dụng không đọc GPS hiện tại và không gửi tọa độ thô cho AI.", systemImage: "shield.checkered")
                        .font(.footnote)
                }
                Section("Nơi sinh") {
                    TextField("Ví dụ: Hà Nội, Việt Nam", text: Binding(get: { store.place }, set: { store.send(.placeChanged($0)) }))
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                    Button("Tìm và xác nhận địa điểm") { store.send(.choosePlaceTapped) }
                }
                Section("Bạn có biết chính xác giờ sinh?") {
                    Picker("Độ chính xác", selection: Binding(get: { store.knowsBirthTime }, set: { store.send(.knowsBirthTimeChanged($0)) })) {
                        Text("Có").tag(true)
                        Text("Không rõ").tag(false)
                    }
                    .pickerStyle(.segmented)
                    if store.knowsBirthTime {
                        TextField("14:30", text: Binding(get: { store.birthTime }, set: { store.send(.birthTimeChanged($0)) }))
                            .keyboardType(.numbersAndPunctuation)
                    }
                }
                if let error = store.errorMessage {
                    Section { Text(error).font(.footnote).foregroundStyle(.red) }
                }
                Section {
                    Button("Lưu và phân tích lại") { store.send(.saveTapped) }
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Nơi sinh & giờ sinh")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Đóng") { store.send(.closeTapped) } }
            }
            .sheet(item: $store.scope(state: \.$placePicker, action: \.placePicker)) {
                BirthPlacePickerView(store: $0)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

struct AstrologyBackground<Content: View>: View {
    let asset: AppAsset
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Image(appAsset: asset).resizable().scaledToFill().ignoresSafeArea()
            Image(appAsset: .astrologyStarDust)
                .resizable().scaledToFit().frame(width: 168, height: 138)
                .opacity(0.3).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 28)
            LinearGradient(colors: [AstrologyPalette.deep.opacity(0.1), AstrologyPalette.deep.opacity(0.35), AstrologyPalette.deep.opacity(0.97)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            content()
        }
        .background(AstrologyPalette.deep)
    }
}

struct AstrologyCard<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        content().padding(15).frame(maxWidth: .infinity, alignment: .leading)
            .background(AstrologyPalette.navy.opacity(0.88), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(AstrologyPalette.violetBorder.opacity(0.45)))
    }
}

struct AstrologyPaperCard<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        content().padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [Color(hex: 0xFDE0CB), Color(hex: 0xF9CCB2)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(AstrologyPalette.gold.opacity(0.82)))
            .shadow(color: .black.opacity(0.3), radius: 18, y: 8)
    }
}

struct AstrologySectionTitle: View {
    let eyebrow: String
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow).font(.caption2.bold()).tracking(1.5).foregroundStyle(AstrologyPalette.cyan)
            Text(title).font(.system(size: 23, weight: .bold, design: .serif))
        }
    }
}

enum AstrologyPalette {
    static let deep = Color(hex: 0x080C43)
    static let navy = Color(hex: 0x0C0B44)
    static let purple = Color(hex: 0x321F74)
    static let gold = Color(hex: 0xFFD69B)
    static let cyan = Color(hex: 0x8AE5EA)
    static let pink = Color(hex: 0xF9B7DD)
    static let muted = Color(hex: 0xE8DFFF)
    static let lavender = Color(hex: 0xD6BDFF)
    static let violetBorder = Color(hex: 0xC9A7FF)
    static let paperText = Color(hex: 0x21184B)
}

func zodiacLabel(_ raw: String) -> String {
    guard let sign = AstrologyZodiacID(rawValue: raw) else { return raw }
    return "\(sign.nameVi) \(sign.symbol)"
}

func dominantLabel(_ signal: AstroDominantSignal) -> String {
    switch signal {
    case .tension: "Cần điều chỉnh"
    case .harmony: "Thuận dòng"
    case .conjunction: "Đang hội tụ"
    case .balanced: "Cân bằng"
    }
}

func natureLabel(_ nature: AstroAspectNature) -> String {
    switch nature {
    case .tension: "Thử thách"
    case .harmony: "Hỗ trợ"
    case .neutral: "Hội tụ"
    }
}

func precisionMessage(_ metadata: AstroFeatureMetadata) -> String {
    switch metadata.birthDataPrecision {
    case .complete: "Đã dựng đủ 12 nhà theo hệ Porphyry."
    case .timeWithoutLocation: "Đã có giờ sinh nhưng cần nơi sinh để xác định 12 nhà."
    case .dateOnly, .none: "Đang dùng mốc 12:00 tạm tính; bổ sung nơi và giờ sinh để tăng độ chính xác."
    }
}

private struct AstrologyActivityShareSheet: UIViewControllerRepresentable {
    let payload: AstrologyFeature.SharePayload
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [payload.message], applicationActivities: nil)
        controller.setValue(payload.title, forKey: "subject")
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    AstrologyView(
        store: Store(initialState: AstrologyFeature.State()) {
            AstrologyFeature()
        } withDependencies: {
            $0.astrologyClient = .previewValue
            $0.caDaoClient = .previewValue
            $0.userProfileClient = .previewValue
            $0.birthLocationClient = .previewValue
            $0.hapticClient = .testValue
        }
    )
}
