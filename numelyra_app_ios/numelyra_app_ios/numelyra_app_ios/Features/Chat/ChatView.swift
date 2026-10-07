import ComposableArchitecture
import SwiftUI

struct ChatView: View {
    @Bindable var store: StoreOf<ChatFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ChatSceneBackgroundView(reduceMotion: reduceMotion)
            VStack(spacing: 0) {
                header
                timeline
                composer
            }
        }
        .preferredColorScheme(.dark)
        .task { store.send(.onAppear) }
        .onDisappear { store.send(.onDisappear) }
        .sheet(item: $store.scope(state: \.profilePicker, action: \.profilePicker)) { ChatProfilePickerView(store: $0) }
        .sheet(item: $store.scope(state: \.placePicker, action: \.placePicker)) { ChatPlacePickerView(store: $0).presentationDetents([.large]) }
        .fullScreenCover(item: $store.scope(state: \.ritual, action: \.ritual)) { ChatReadingRitualView(store: $0) }
        .fullScreenCover(item: $store.scope(state: \.detail, action: \.detail)) { ChatReadingDetailView(store: $0) }
        .fullScreenCover(item: $store.scope(state: \.numerologyCards, action: \.numerologyCards)) { NumerologyCardsView(store: $0) }
        .alert("Numelyra", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.send(.errorDismissed) } })) {
            Button("Đã hiểu") { store.send(.errorDismissed) }
        } message: { Text(store.errorMessage ?? "") }
    }

    private var header: some View {
        HStack {
            Button { store.send(.gameHubTapped) } label: {
                Image(AppAsset.chatSceneMoon.rawValue).resizable().scaledToFit().frame(width: 48, height: 48).opacity(0.48)
            }.buttonStyle(.plain).disabled(true).accessibilityLabel("Game Hub chưa khả dụng")
            Spacer()
            Text("Numelyra").font(.system(size: 23, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.Colors.textPrimary)
            Spacer()
            Button { store.send(.historyToggleTapped) } label: {
                Image(systemName: store.showAllHistory ? "clock.arrow.2.circlepath" : "clock").font(.title3.weight(.semibold)).frame(width: 44, height: 44).background(.white.opacity(0.09), in: Circle())
            }.buttonStyle(.plain).foregroundStyle(AppTheme.Colors.primaryBright).accessibilityLabel(store.showAllHistory ? "Thu gọn lịch sử trò chuyện" : "Mở toàn bộ lịch sử trò chuyện")
        }.padding(.horizontal, 14).padding(.top, 6)
    }

    private var timeline: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(store.visibleMessages) { message in
                        if message.sender == .user {
                            HStack { Spacer(minLength: 55); Text(message.text).font(AppTheme.Typography.body).foregroundStyle(.white).padding(.horizontal, 15).padding(.vertical, 11).background(LinearGradient(colors: [Color(hex: 0x4B2475), Color(hex: 0x7C42A6)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18)) }
                        } else {
                            AssistantPreview(message: message) { store.send(.messageTypingFinished(message.id)) } onOpen: { store.send(.messageTapped(message.id)) }
                        }
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }.padding(.horizontal, 16).padding(.top, 10)
            }
            .onChange(of: store.messages.count) { _, _ in withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } }
            .overlay {
                if store.messages.isEmpty && !store.isLoading {
                    VStack(spacing: 8) {
                        Text("Hi, I’m Numelyra").font(.title2.bold()).foregroundStyle(.white)
                        Text("Ask me anything\nor share how you feel.").multilineTextAlignment(.center).foregroundStyle(AppTheme.Colors.textSecondary)
                        Button { store.send(.mascotTapped) } label: { FlameMascotView(state: "idle", size: 175, reduceMotion: reduceMotion) }.buttonStyle(.plain).accessibilityLabel("Mở 24 lá bài Thần số học")
                    }
                } else if store.isLoading {
                    FlameMascotView(state: "thinking", size: 170, reduceMotion: reduceMotion).accessibilityLabel("Tiểu Linh Miêu đang suy nghĩ")
                }
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 8) {
            Button { store.send(.profileTapped) } label: { Image(systemName: "plus").font(.title2).frame(width: 50, height: 50).background(AppTheme.Gradients.secondaryAction, in: Circle()) }.accessibilityLabel("Chọn hồ sơ luận giải")
            HStack(spacing: 4) {
                TextField("Type a message...", text: Binding(get: { store.draft }, set: { store.send(.draftChanged($0)) })).textFieldStyle(.plain).foregroundStyle(.white).submitLabel(.send).onSubmit { store.send(.sendTapped) }
                Button { store.send(.microphoneTapped) } label: { Image(systemName: store.isListening ? "waveform.circle.fill" : "mic.fill").foregroundStyle(store.isListening ? AppTheme.Colors.errorSoft : AppTheme.Colors.secondary).frame(width: 38, height: 38) }.accessibilityLabel(store.isListening ? "Dừng nhận diện giọng nói" : "Nhập bằng giọng nói")
                Button { store.send(.sendTapped) } label: { Image(systemName: store.isLoading ? "hourglass" : "arrow.up").font(.headline).foregroundStyle(AppTheme.Colors.textOnPrimary).frame(width: 44, height: 44).background(AppTheme.Gradients.goldAction, in: Circle()) }.disabled(store.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isLoading || !store.isHydrated).accessibilityLabel("Gửi tin nhắn")
            }.padding(.leading, 18).padding(.trailing, 5).frame(height: 56).background(AppTheme.Colors.inputBackground.opacity(0.88), in: Capsule()).overlay(Capsule().stroke(AppTheme.Colors.inputBorder))
        }.padding(.horizontal, 14).padding(.vertical, 9).background(.black.opacity(0.12))
    }
}

private struct AssistantPreview: View {
    let message: ChatMessage; let onFinish: () -> Void; let onOpen: () -> Void
    @State private var shown = 0
    var body: some View {
        HStack { Button(action: onOpen) { Text(String(message.text.prefix(message.isTypingCompleted ? message.text.count : shown)) + (message.isTypingCompleted ? "" : " ▌")).font(AppTheme.Typography.body).foregroundStyle(Color(hex: 0x301934)).lineLimit(3).frame(maxWidth: .infinity, alignment: .leading).padding(14).background(Color(hex: 0xF6DEC4), in: RoundedRectangle(cornerRadius: 20)) }.buttonStyle(.plain).disabled(!message.isTypingCompleted); Spacer(minLength: 42) }
        .task(id: message.id) {
            guard !message.isTypingCompleted else { shown = message.text.count; return }
            while shown < message.text.count { try? await Task.sleep(for: .milliseconds(20)); shown = min(shown + 4, message.text.count) }
            onFinish()
        }
    }
}

private struct ChatSceneBackgroundView: View {
    let reduceMotion: Bool
    @State private var twinkle = false
    var body: some View {
        ZStack {
            Image(AppAsset.chatSceneSky.rawValue).resizable().scaledToFill()
            Image(AppAsset.chatSceneStars.rawValue).resizable().scaledToFit().frame(maxWidth: 180).opacity(twinkle ? 1 : 0.62).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(.top, 90).padding(.leading, 18)
            Image(AppAsset.chatSceneMountains.rawValue).resizable().scaledToFill()
            Image(AppAsset.chatSceneForeground.rawValue).resizable().scaledToFill()
        }.ignoresSafeArea().clipped().onAppear { guard !reduceMotion else { return }; withAnimation(.easeInOut(duration: 2.3).repeatForever(autoreverses: true)) { twinkle = true } }
    }
}

private struct FlameMascotView: View {
    let state: String; let size: CGFloat; let reduceMotion: Bool
    private var asset: AppAsset { state == "thinking" ? .chatFlameThinkingSprite : state == "answer" ? .chatFlameAnswerSprite : .chatFlameIdleSprite }
    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 10 : 1 / 12)) { context in
            let frame = reduceMotion ? 0 : Int(context.date.timeIntervalSinceReferenceDate * 12) % 12
            GeometryReader { _ in Image(asset.rawValue).resizable().frame(width: size * 4, height: size * 3).offset(x: -CGFloat(frame % 4) * size, y: -CGFloat(frame / 4) * size) }.frame(width: size, height: size).clipped()
        }.frame(width: size, height: size).shadow(color: .orange.opacity(0.45), radius: 20)
    }
}

struct ChatProfilePickerView: View {
    @Bindable var store: StoreOf<ChatProfilePickerFeature>
    var body: some View {
        NavigationStack { ScrollView { VStack(spacing: 14) {
            Picker("Chế độ", selection: Binding(get: { store.mode }, set: { store.send(.modeChanged($0)) })) { Text("Cá nhân").tag(ChatProfilePickerFeature.Mode.single); Text("Tình duyên").tag(ChatProfilePickerFeature.Mode.couple) }.pickerStyle(.segmented)
            if let error = store.errorMessage { Text(error).foregroundStyle(AppTheme.Colors.error).font(.caption) }
            ForEach(store.profiles) { profile in
                HStack {
                    Button { store.send(.profileTapped(profile.id)) } label: {
                        HStack { Text(profile.gender == .male ? "👨" : "👩"); VStack(alignment: .leading) { Text(profile.fullName).font(.headline); Text(profile.birthDate).font(.caption).foregroundStyle(AppTheme.Colors.textMuted) }; Spacer(); if store.selectedIDs.contains(profile.id) { Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.Colors.primary) } }
                    }.buttonStyle(.plain)
                    if store.profiles.count > 1 { Button(role: .destructive) { store.send(.deleteTapped(profile.id)) } label: { Image(systemName: "trash") }.buttonStyle(.borderless).accessibilityLabel("Xóa hồ sơ \(profile.fullName)") }
                }.padding().background(AppTheme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: 14))
            }
            if store.isAdding {
                VStack(spacing: 10) {
                    TextField("Họ và tên", text: Binding(get: { store.newName }, set: { store.send(.nameChanged($0)) })).textFieldStyle(.roundedBorder)
                    DatePicker("Ngày sinh", selection: birthDateBinding, in: ...Date(), displayedComponents: .date).datePickerStyle(.compact)
                    Toggle("Biết chính xác giờ sinh", isOn: Binding(get: { store.hasBirthTime }, set: { store.send(.hasBirthTimeChanged($0)) }))
                    if store.hasBirthTime { DatePicker("Giờ sinh", selection: birthTimeBinding, displayedComponents: .hourAndMinute).datePickerStyle(.compact) }
                    Picker("Giới tính", selection: Binding(get: { store.newGender }, set: { store.send(.genderChanged($0)) })) { ForEach(Gender.allCases, id: \.self) { Text($0.titleVi).tag($0) } }.pickerStyle(.segmented)
                    Button("Lưu hồ sơ") { store.send(.saveProfileTapped) }.buttonStyle(.borderedProminent).tint(AppTheme.Colors.primary)
                }
            } else { Button("Thêm hồ sơ người thân / bạn bè") { store.send(.addToggled) }.buttonStyle(.bordered) }
            if store.mode == .couple { Button("Xác nhận hai hồ sơ") { store.send(.confirmTapped) }.buttonStyle(.borderedProminent).tint(.pink).disabled(store.selectedIDs.count != 2) }
        }.padding() } .background(AppTheme.Colors.backgroundElevated).navigationTitle("Chọn Hồ Sơ Luận Giải").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Đóng") { store.send(.closeTapped) } } } }.preferredColorScheme(.dark)
    }
    private var birthDateBinding: Binding<Date> {
        Binding(get: {
            let formatter = DateFormatter(); formatter.calendar = Calendar(identifier: .gregorian); formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: store.newBirthDate) ?? Date(timeIntervalSince1970: 946_684_800)
        }, set: { value in
            let formatter = DateFormatter(); formatter.calendar = Calendar(identifier: .gregorian); formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "yyyy-MM-dd"
            store.send(.birthDateChanged(formatter.string(from: value)))
        })
    }
    private var birthTimeBinding: Binding<Date> {
        Binding(get: {
            let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "HH:mm"
            return formatter.date(from: store.newBirthTime) ?? Date(timeIntervalSince1970: 43_200)
        }, set: { value in
            let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "HH:mm"
            store.send(.birthTimeChanged(formatter.string(from: value)))
        })
    }
}

struct ChatReadingRitualView: View {
    @Bindable var store: StoreOf<ChatReadingRitualFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Image(AppAsset.chatDetailBackground.rawValue).resizable().scaledToFill().ignoresSafeArea()
            Image(AppAsset.chatDetailMat.rawValue).resizable().scaledToFit().opacity(0.72).padding(.horizontal, 8)
            VStack(spacing: 18) {
                Text("NGHI THỨC RÚT BÀI").font(.title2.weight(.black)).tracking(2).foregroundStyle(AppTheme.Colors.primaryBright)
                Text(store.question).font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.84)).padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(store.cards.enumerated()), id: \.element.id) { index, card in
                            RitualCard(card: card, revealed: index < store.revealedCount, reduceMotion: reduceMotion)
                        }
                    }.padding(.horizontal, 20)
                }
                if store.revealedCount < store.cards.count {
                    Button(store.revealedCount == 0 ? "Lật lá bài đầu tiên" : "Lật lá tiếp theo") { store.send(.revealNextTapped) }
                        .buttonStyle(.borderedProminent).tint(AppTheme.Colors.primary)
                } else if !store.canShowReading {
                    ProgressView("Tiểu Linh Miêu đang hoàn tất lời giải…").tint(AppTheme.Colors.primaryBright).foregroundStyle(.white)
                }
                if store.canShowReading, let reply = store.replyText {
                    ScrollView { Text(reply).font(.body).foregroundStyle(Color(hex: 0x301934)).frame(maxWidth: .infinity, alignment: .leading).padding(20) }
                        .frame(maxHeight: 260).background(Image(AppAsset.chatDetailPaper.rawValue).resizable(capInsets: EdgeInsets(top: 30, leading: 30, bottom: 30, trailing: 30)).opacity(0.94)).padding(.horizontal)
                    Button("Hoàn tất") { store.send(.closeTapped) }.buttonStyle(.borderedProminent).tint(AppTheme.Colors.primary)
                }
                HStack { Image(AppAsset.chatDetailCandle.rawValue).resizable().scaledToFit().frame(height: 90); Spacer(); Image(AppAsset.chatDetailBook.rawValue).resizable().scaledToFit().frame(height: 90) }.padding(.horizontal, 28)
            }.padding(.vertical, 24)
        }.preferredColorScheme(.dark).interactiveDismissDisabled(!store.canShowReading)
    }
}

private struct RitualCard: View {
    let card: DrawnTarotCard; let revealed: Bool; let reduceMotion: Bool
    var body: some View {
        ZStack {
            Image(AppAsset.tarotCardBack.rawValue).resizable().scaledToFill().opacity(revealed ? 0 : 1)
            Image(AppAsset.tarotCard(id: card.card.id).rawValue).resizable().scaledToFill().rotationEffect(card.isReversed ? .degrees(180) : .zero).opacity(revealed ? 1 : 0)
        }
        .frame(width: 118, height: 184).clipped().clipShape(RoundedRectangle(cornerRadius: 9))
        .rotation3DEffect(.degrees(revealed && !reduceMotion ? 360 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(reduceMotion ? nil : .spring(response: 0.65, dampingFraction: 0.78), value: revealed)
        .accessibilityLabel(revealed ? "\(card.card.nameVi), \(card.isReversed ? "ngược" : "xuôi")" : "Lá bài chưa lật")
    }
}

struct ChatPlacePickerView: View {
    @Bindable var store: StoreOf<ChatPlacePickerFeature>
    var body: some View { NavigationStack { Form {
        Section("Khoảng cách tối đa") { Picker("Khoảng cách", selection: Binding(get: { store.distance }, set: { store.send(.distanceChanged($0)) })) { Text("2 km").tag(2.0); Text("5 km").tag(5.0); Text("10 km").tag(10.0) }.pickerStyle(.segmented) }
        Section("Ngân sách") { Picker("Ngân sách", selection: Binding(get: { store.budget }, set: { store.send(.budgetChanged($0)) })) { Text("Tiết kiệm").tag(PlaceBudget.low); Text("Vừa phải").tag(PlaceBudget.medium); Text("Linh hoạt").tag(PlaceBudget.flexible) } }
        Section("Đi cùng") { Picker("Đi cùng", selection: Binding(get: { store.companion }, set: { store.send(.companionChanged($0)) })) { Text("Một mình").tag(PlaceCompanion.solo); Text("Hẹn hò").tag(PlaceCompanion.date); Text("Bạn bè").tag(PlaceCompanion.friends); Text("Gia đình").tag(PlaceCompanion.family) }; Toggle("Ưu tiên nơi đang mở", isOn: Binding(get: { store.openNow }, set: { _ in store.send(.openNowToggled) })) }
        if let error = store.errorMessage { Text(error).foregroundStyle(.red) }
        Button(store.isLocating ? "Đang xác định vị trí…" : "Dùng vị trí hiện tại") { store.send(.useLocationTapped) }.disabled(store.isLocating)
    }.navigationTitle("Tìm nơi phù hợp").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Để sau") { store.send(.cancelTapped) } } } } }
}

struct ChatReadingDetailView: View {
    @Bindable var store: StoreOf<ChatReadingDetailFeature>
    var body: some View { NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 16) {
        if let question = store.question { GroupBox("CÂU HỎI CỦA BẠN") { Text(question).italic().frame(maxWidth: .infinity, alignment: .leading) } }
        let cards = drawnCards(store.message.card)
        if !cards.isEmpty { ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(cards) { card in VStack { Image(AppAsset.tarotCard(id: card.card.id).rawValue).resizable().scaledToFill().frame(width: 110, height: 168).clipped().rotationEffect(card.isReversed ? .degrees(180) : .zero); Text(card.position.nameVi).font(.caption).lineLimit(1) }.frame(width: 112) } } } }
        Text(store.message.text).font(.body).padding(18).foregroundStyle(Color(hex: 0x301934)).background(Color(hex: 0xF6DEC4), in: RoundedRectangle(cornerRadius: 24))
        if let compatibility = compatibility(store.message.card) {
            VStack(alignment: .leading, spacing: 10) {
                HStack { Label("Tương hợp Tử Vi", systemImage: "sparkles"); Spacer(); Text("\(compatibility.analysis.score)/100").font(.title2.bold()).foregroundStyle(AppTheme.Colors.primaryBright) }
                ProgressView(value: Double(compatibility.analysis.score), total: 100).tint(AppTheme.Colors.primary)
                Text(compatibility.analysis.summaryVi)
                ForEach(compatibility.analysis.contributions, id: \.titleVi) { item in
                    VStack(alignment: .leading, spacing: 2) { Text("\(item.points >= 0 ? "+" : "")\(item.points) · \(item.titleVi)").font(.subheadline.bold()); Text(item.detailVi).font(.caption).foregroundStyle(AppTheme.Colors.textSecondary) }
                }
                Text(compatibility.analysis.disclaimerVi).font(.caption2).foregroundStyle(AppTheme.Colors.textMuted)
            }.padding().background(AppTheme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: 16))
        }
        if let places = places(store.message.card) { PlaceSuggestionsView(data: places) { store.send(.mapTapped($0)) } }
    }.padding() }.background(AppTheme.Colors.background.ignoresSafeArea()).navigationTitle("Luận giải chi tiết").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Quay lại") { store.send(.closeTapped) } } } }.preferredColorScheme(.dark) }
    private func drawnCards(_ payload: ChatCardPayload?) -> [DrawnTarotCard] { if case let .agentSynthesis(value)? = payload { return value.drawnCards }; if case let .tarot(value)? = payload { return value.cards }; return [] }
    private func places(_ payload: ChatCardPayload?) -> PlaceSuggestionsPayload? { if case let .placeSuggestions(value)? = payload { return value }; if case let .agentSynthesis(value)? = payload { return value.placeSuggestions }; return nil }
    private func compatibility(_ payload: ChatCardPayload?) -> ChatZiWeiCompatibilityPayload? { if case let .agentSynthesis(value)? = payload { return value.ziWeiCompatibility }; return nil }
}

private struct PlaceSuggestionsView: View {
    let data: PlaceSuggestionsPayload; let open: (String) -> Void
    var body: some View { VStack(alignment: .leading, spacing: 8) { HStack { Label("Địa điểm đã lọc", systemImage: "map"); Spacer(); Text(data.areaLabel).font(.caption) }; ForEach(data.places) { place in Button { open(place.mapsUrl) } label: { HStack { Image(systemName: "location.fill").foregroundStyle(AppTheme.Colors.primary); VStack(alignment: .leading) { Text(place.name).font(.headline); if let address = place.address { Text(address).font(.caption) }; Text([place.distanceKm.map { String(format: "%.1f km", $0) }, place.openNow.map { $0 ? "Đang mở" : "Đã đóng" }].compactMap { $0 }.joined(separator: " · ")).font(.caption).foregroundStyle(AppTheme.Colors.primaryBright); if let why = place.whySelected { Text(why).font(.caption).italic() } }; Spacer(); Image(systemName: "arrow.up.right.square") }.foregroundStyle(AppTheme.Colors.textPrimary) }.buttonStyle(.plain).padding(.vertical, 7); Divider() }; Text("Nguồn địa điểm: \(data.attribution)").font(.caption2).foregroundStyle(AppTheme.Colors.textMuted) }.padding().background(AppTheme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: 16)) }
}
