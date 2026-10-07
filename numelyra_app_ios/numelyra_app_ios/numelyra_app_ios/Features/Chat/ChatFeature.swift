import ComposableArchitecture
import Foundation

@Reducer
struct ChatProfilePickerFeature {
    enum Mode: Equatable { case single, couple }
    @ObservableState struct State: Equatable {
        var profiles: [UserProfile]
        var selectedIDs: [String]
        var mode: Mode
        var isAdding = false
        var newName = ""
        var newBirthDate = "2000-01-01"
        var newBirthTime = "12:00"
        var hasBirthTime = false
        var newGender = Gender.female
        var errorMessage: String?
    }
    enum Action: Equatable {
        case modeChanged(Mode), profileTapped(String), confirmTapped, addToggled
        case nameChanged(String), birthDateChanged(String), birthTimeChanged(String), hasBirthTimeChanged(Bool), genderChanged(Gender), saveProfileTapped
        case deleteTapped(String), closeTapped
        case delegate(Delegate)
        enum Delegate: Equatable { case selected([UserProfile]); case close }
    }
    @Dependency(\.userProfileClient) var profilesClient
    var body: some Reducer<State, Action> { Reduce { state, action in
        switch action {
        case let .modeChanged(mode):
            state.mode = mode
            if mode == .single { state.selectedIDs = Array(state.selectedIDs.prefix(1)) }
            else if state.selectedIDs.count < 2 { state.selectedIDs = Array(state.profiles.prefix(2).map(\.id)) }
            return .none
        case let .profileTapped(id):
            if state.mode == .single {
                guard let profile = state.profiles.first(where: { $0.id == id }) else { return .none }
                profilesClient.setActiveProfileID(id)
                return .send(.delegate(.selected([profile])))
            }
            if state.selectedIDs.contains(id) { state.selectedIDs.removeAll { $0 == id } }
            else if state.selectedIDs.count < 2 { state.selectedIDs.append(id) }
            else { state.selectedIDs[1] = id }
            return .none
        case .confirmTapped:
            let chosen = state.selectedIDs.compactMap { id in state.profiles.first { $0.id == id } }
            guard state.mode == .single ? chosen.count == 1 : chosen.count == 2 else { state.errorMessage = "Vui lòng chọn đủ hồ sơ."; return .none }
            return .send(.delegate(.selected(chosen)))
        case .addToggled: state.isAdding.toggle(); state.errorMessage = nil; return .none
        case let .nameChanged(value): state.newName = value; return .none
        case let .birthDateChanged(value): state.newBirthDate = value; return .none
        case let .birthTimeChanged(value): state.newBirthTime = value; return .none
        case let .hasBirthTimeChanged(value): state.hasBirthTime = value; return .none
        case let .genderChanged(value): state.newGender = value; return .none
        case .saveProfileTapped:
            do {
                let profile = try profilesClient.addProfile(.init(fullName: state.newName, birthDate: state.newBirthDate, gender: state.newGender, birthTime: state.hasBirthTime ? state.newBirthTime : nil, birthTimeAccuracy: state.hasBirthTime ? .exact : .unknown))
                state.profiles.append(profile); state.newName = ""; state.isAdding = false; state.errorMessage = nil
                if state.mode == .single { profilesClient.setActiveProfileID(profile.id); return .send(.delegate(.selected([profile]))) }
                state.selectedIDs = Array((Array(state.selectedIDs.prefix(1)) + [profile.id]).prefix(2)); return .none
            } catch { state.errorMessage = error.localizedDescription; return .none }
        case let .deleteTapped(id):
            state.profiles = profilesClient.deleteProfile(id); state.selectedIDs.removeAll { $0 == id }; return .none
        case .closeTapped: return .send(.delegate(.close))
        case .delegate: return .none
        }
    } }
}

@Reducer
struct ChatPlacePickerFeature {
    @ObservableState struct State: Equatable {
        var distance = 5.0; var budget = PlaceBudget.medium; var companion = PlaceCompanion.solo; var openNow = true
        var isLocating = false; var errorMessage: String?
    }
    enum Action: Equatable {
        case distanceChanged(Double), budgetChanged(PlaceBudget), companionChanged(PlaceCompanion), openNowToggled, useLocationTapped, cancelTapped
        case delegate(Delegate)
        enum Delegate: Equatable { case locate(PlaceSearchPreferences); case cancel }
    }
    var body: some Reducer<State, Action> { Reduce { state, action in
        switch action {
        case let .distanceChanged(v): state.distance = v; return .none
        case let .budgetChanged(v): state.budget = v; return .none
        case let .companionChanged(v): state.companion = v; return .none
        case .openNowToggled: state.openNow.toggle(); return .none
        case .useLocationTapped: state.isLocating = true; state.errorMessage = nil; return .send(.delegate(.locate(.init(maxDistanceKm: state.distance, budget: state.budget, companion: state.companion, openNow: state.openNow))))
        case .cancelTapped: return .send(.delegate(.cancel))
        case .delegate: return .none
        }
    } }
}

@Reducer
struct ChatReadingRitualFeature {
    enum Status: Equatable { case waiting, ready, revealed }
    @ObservableState struct State: Equatable, Identifiable {
        var id: String; var question: String; var cards: [DrawnTarotCard]; var revealedCount = 0; var status = Status.waiting; var replyText: String?
        var canShowReading: Bool { revealedCount == cards.count && status == .revealed }
    }
    enum Action: Equatable { case revealNextTapped, closeTapped, delegate(Delegate); enum Delegate: Equatable { case revealedAll, close } }
    @Dependency(\.hapticClient) var haptics
    var body: some Reducer<State, Action> { Reduce { state, action in
        switch action {
        case .revealNextTapped:
            guard state.revealedCount < state.cards.count else { return .none }
            state.revealedCount += 1
            let done = state.revealedCount == state.cards.count
            return .merge(.run { _ in await haptics.mediumImpact() }, done ? .send(.delegate(.revealedAll)) : .none)
        case .closeTapped: return state.canShowReading ? .send(.delegate(.close)) : .none
        case .delegate: return .none
        }
    } }
}

@Reducer
struct ChatReadingDetailFeature {
    @ObservableState struct State: Equatable, Identifiable { var message: ChatMessage; var question: String?; var id: String { message.id } }
    enum Action: Equatable { case closeTapped, mapTapped(String), delegate(Delegate); enum Delegate: Equatable { case close; case openMap(String) } }
    var body: some Reducer<State, Action> { Reduce { _, action in
        switch action { case .closeTapped: return .send(.delegate(.close)); case let .mapTapped(url): return .send(.delegate(.openMap(url))); case .delegate: return .none }
    } }
}
struct ChatAnswer: Equatable { var text: String; var card: ChatCardPayload? }

@Reducer
struct ChatFeature {
    struct PendingTurn: Equatable {
        var id: String; var prompt: String; var decision: AgentDecision
        var indicators1: [NumerologyIndicator] = []; var indicators2: [NumerologyIndicator]?; var cards: [DrawnTarotCard] = []
        var color: ColorGuidanceContext?; var place: PlaceSearchContext?; var ziWeiCompatibility: ChatZiWeiCompatibilityPayload?
    }
    @ObservableState struct State: Equatable {
        var ownerID = "guest"; var isHydrated = false; var messages: [ChatMessage] = []; var showAllHistory = false
        var draft = ""; var selectedProfiles: [UserProfile] = []; var isLoading = false; var isListening = false
        var errorMessage: String?; var pending: PendingTurn?; var mascotState = "idle"; var mascotCategory = "default"
        @Presents var profilePicker: ChatProfilePickerFeature.State?
        @Presents var placePicker: ChatPlacePickerFeature.State?
        @Presents var ritual: ChatReadingRitualFeature.State?
        @Presents var numerologyCards: NumerologyCardsFeature.State?
        @Presents var detail: ChatReadingDetailFeature.State?
        var visibleMessages: [ChatMessage] { showAllHistory ? messages : Array(messages.suffix(messages.last?.sender == .mascot ? 2 : 1)) }
    }
    enum Action: Equatable {
        case onAppear, onDisappear, hydrated(String, [UserProfile], [ChatMessage]), ownerChanged(String)
        case draftChanged(String), sendTapped, classified(Result<AgentDecision, ChatError>), response(Result<ChatAnswer, ChatError>)
        case historyToggleTapped, profileTapped, mascotTapped, microphoneTapped, transcriptReceived(String), listeningEnded, listeningFailed(String)
        case messageTypingFinished(String), messageTapped(String), mapTapped(String), errorDismissed, gameHubTapped
        case locationResponse(Result<PlaceSearchContext, ChatError>)
        case profilePicker(PresentationAction<ChatProfilePickerFeature.Action>)
        case placePicker(PresentationAction<ChatPlacePickerFeature.Action>)
        case ritual(PresentationAction<ChatReadingRitualFeature.Action>)
        case numerologyCards(PresentationAction<NumerologyCardsFeature.Action>)
        case detail(PresentationAction<ChatReadingDetailFeature.Action>)
        case delegate(Delegate)
        enum Delegate: Equatable { case gameHubTapped }
    }
    @Dependency(\.chatClient) var chatClient; @Dependency(\.chatHistoryClient) var history
    @Dependency(\.userProfileClient) var profilesClient; @Dependency(\.supabaseClient) var supabase
    @Dependency(\.numerologyClient) var numerology; @Dependency(\.speechClient) var speech
    @Dependency(\.speechRecognitionClient) var recognition; @Dependency(\.placeLocationClient) var location
    @Dependency(\.externalURLClient) var externalURL; @Dependency(\.date.now) var now; @Dependency(\.uuid) var uuid
    @Dependency(\.tuViClient) var tuViClient
    private enum CancelID: Hashable { case load, request, recognition, location }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let session = await supabase.currentSession(); let owner = session?.userId ?? "guest"
                    await send(.hydrated(owner, profilesClient.loadAllProfiles(), await history.load(owner)))
                }.cancellable(id: CancelID.load, cancelInFlight: true)
            case .onDisappear:
                state.isListening = false
                return .merge(.cancel(id: CancelID.load), .cancel(id: CancelID.recognition), .cancel(id: CancelID.request), .cancel(id: CancelID.location), .run { _ in await recognition.stop(); await speech.stop() })
            case let .hydrated(owner, profiles, messages):
                state.ownerID = owner; state.messages = messages; state.selectedProfiles = profilesClient.activeProfile().map { [$0] } ?? Array(profiles.prefix(1)); state.isHydrated = true; return .none
            case let .ownerChanged(owner):
                guard owner != state.ownerID else { return .none }; state = State(ownerID: owner)
                return .merge(
                    .cancel(id: CancelID.request), .cancel(id: CancelID.recognition), .cancel(id: CancelID.location),
                    .run { _ in await recognition.stop(); await speech.stop() },
                    .run { send in await send(.hydrated(owner, profilesClient.loadAllProfiles(), await history.load(owner))) }.cancellable(id: CancelID.load, cancelInFlight: true)
                )
            case let .draftChanged(value): state.draft = value; return .none
            case .sendTapped:
                let prompt = state.draft.trimmingCharacters(in: .whitespacesAndNewlines)
                guard state.isHydrated, !state.isLoading, !prompt.isEmpty else { return .none }
                guard !state.selectedProfiles.isEmpty else { state.profilePicker = pickerState(state); return .none }
                if state.selectedProfiles.count > 1, ColorGuidanceEngine.isColorQuestion(prompt) { state.errorMessage = "Màu hợp mệnh cần đúng một hồ sơ. Hãy chọn chế độ Cá nhân."; state.profilePicker = pickerState(state); return .none }
                if state.selectedProfiles.count > 1, state.selectedProfiles.contains(where: { $0.gender == nil || $0.effectiveBirthTimeAccuracy != .exact || $0.birthTime?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false }) {
                    state.errorMessage = "Luận tương hợp Tử Vi mới cần giới tính và giờ sinh chính xác của cả hai hồ sơ. Hãy bổ sung hồ sơ trước khi gửi."
                    state.profilePicker = pickerState(state)
                    return .none
                }
                state.messages.append(.init(id: "user-\(uuid().uuidString)", sender: .user, text: prompt, time: time(now)))
                state.messages = Array(state.messages.suffix(100)); state.draft = ""; state.isLoading = true; state.mascotState = "thinking"
                let profiles = state.selectedProfiles; let snapshot = state.messages; let owner = state.ownerID
                return .merge(persist(owner, snapshot), .run { send in do { await send(.classified(.success(try await chatClient.classify(.init(message: prompt, profiles: profiles))))) } catch { await send(.classified(.failure(.server(error.localizedDescription)))) } }.cancellable(id: CancelID.request, cancelInFlight: true))
            case let .classified(result):
                guard let user = state.messages.last(where: { $0.sender == .user }) else { return .none }
                let decision = (try? result.get()) ?? ChatDecisionEngine.evaluate(user.text, profiles: state.selectedProfiles)
                if decision.intent == .trash { appendAssistant(decision.replyText ?? ChatDecisionEngine.trashReply, card: nil, to: &state); return persist(state.ownerID, state.messages) }
                state.pending = PendingTurn(id: "mascot-\(uuid().uuidString)", prompt: user.text, decision: decision)
                if decision.intent == .whereToGo { state.isLoading = false; state.placePicker = .init(); return .none }
                return prepareResponse(&state)
            case let .locationResponse(result):
                switch result {
                case let .success(context): state.placePicker = nil; state.pending?.place = context; state.isLoading = true; return prepareResponse(&state)
                case let .failure(error): state.placePicker?.isLocating = false; state.placePicker?.errorMessage = error.localizedDescription; return .none
                }
            case let .response(result):
                guard let pending = state.pending else { return .none }
                let output: ChatAnswer
                switch result {
                case let .success(value): output = value
                case .failure:
                    let local = ChatSynthesisEngine.make(prompt: pending.prompt, decision: pending.decision, profiles: state.selectedProfiles, indicators: pending.indicators1, cards: pending.cards, color: pending.color, ziWeiCompatibility: pending.ziWeiCompatibility)
                    output = ChatAnswer(text: local.0, card: .agentSynthesis(local.1))
                }
                state.messages.append(.init(id: pending.id, sender: .mascot, text: output.text, time: time(now), card: output.card, isTypingCompleted: false))
                state.messages = Array(state.messages.suffix(100)); state.isLoading = !pending.cards.isEmpty; state.mascotState = pending.cards.isEmpty ? "answer" : "thinking"
                if state.ritual?.id == pending.id {
                    state.ritual?.replyText = output.text
                    state.ritual?.status = .ready
                    if state.ritual?.revealedCount == pending.cards.count {
                        let finish = finishRitual(&state, text: output.text)
                        let save = persist(state.ownerID, state.messages)
                        state.pending = nil
                        return .merge(finish, save)
                    }
                }
                let effect = persist(state.ownerID, state.messages); state.pending = nil; return effect
            case .historyToggleTapped: state.showAllHistory.toggle(); return .none
            case .profileTapped: state.profilePicker = pickerState(state); return .none
            case .mascotTapped:
                guard let profile = state.selectedProfiles.first else { state.profilePicker = pickerState(state); return .none }
                state.numerologyCards = .init(activeProfile: profile); return .none
            case .microphoneTapped:
                if state.isListening { state.isListening = false; return .merge(.cancel(id: CancelID.recognition), .run { _ in await recognition.stop() }) }
                state.isListening = true
                return .run { send in do { for try await value in await recognition.start() { await send(.transcriptReceived(value)) }; await send(.listeningEnded) } catch { await send(.listeningFailed(error.localizedDescription)) } }.cancellable(id: CancelID.recognition, cancelInFlight: true)
            case let .transcriptReceived(value): state.draft = value; return .none
            case .listeningEnded: state.isListening = false; return .none
            case let .listeningFailed(message): state.isListening = false; state.errorMessage = message; return .none
            case let .messageTypingFinished(id): if let index = state.messages.firstIndex(where: { $0.id == id }) { state.messages[index].isTypingCompleted = true; return persist(state.ownerID, state.messages) }; return .none
            case let .messageTapped(id):
                guard let index = state.messages.firstIndex(where: { $0.id == id }), state.messages[index].sender == .mascot, state.messages[index].isTypingCompleted else { return .none }
                let question = state.messages[..<index].last(where: { $0.sender == .user })?.text; state.detail = .init(message: state.messages[index], question: question); return .none
            case let .mapTapped(raw): guard let url = URL(string: raw) else { return .none }; return .run { _ in _ = await externalURL.open(url) }
            case .detail(.presented(.delegate(.close))): state.detail = nil; return .none
            case let .detail(.presented(.delegate(.openMap(raw)))): guard let url = URL(string: raw) else { return .none }; return .run { _ in _ = await externalURL.open(url) }
            case .errorDismissed: state.errorMessage = nil; return .none
            case .gameHubTapped: return .send(.delegate(.gameHubTapped))
            case let .profilePicker(.presented(.delegate(.selected(values)))): state.selectedProfiles = values; state.profilePicker = nil; return .none
            case .profilePicker(.presented(.delegate(.close))): state.profilePicker = nil; return .none
            case let .placePicker(.presented(.delegate(.locate(preferences)))):
                return .run { send in do { await send(.locationResponse(.success(try await location.locate(preferences)))) } catch { await send(.locationResponse(.failure(.permissionDenied(error.localizedDescription)))) } }.cancellable(id: CancelID.location, cancelInFlight: true)
            case .placePicker(.presented(.delegate(.cancel))):
                state.placePicker = nil; state.isLoading = false; state.pending = nil
                appendAssistant("✦ TIỂU LINH MIÊU CẦN VỊ TRÍ HIỆN TẠI:\nĐể lọc địa điểm theo khoảng cách thực tế, bạn hãy cho phép dùng vị trí một lần nhé.", card: nil, to: &state)
                return persist(state.ownerID, state.messages)
            case .ritual(.presented(.delegate(.revealedAll))):
                if state.ritual?.status == .ready, let text = state.ritual?.replyText { return finishRitual(&state, text: text) }; return .none
            case .ritual(.presented(.delegate(.close))): state.ritual = nil; state.isLoading = false; state.mascotState = "idle"; return .run { _ in await speech.stop() }
            case .numerologyCards(.presented(.delegate(.didClose))), .numerologyCards(.presented(.closeTapped)): state.numerologyCards = nil; return .none
            case .profilePicker, .placePicker, .ritual, .numerologyCards, .detail, .delegate: return .none
            }
        }
        .ifLet(\.$profilePicker, action: \.profilePicker) { ChatProfilePickerFeature() }
        .ifLet(\.$placePicker, action: \.placePicker) { ChatPlacePickerFeature() }
        .ifLet(\.$ritual, action: \.ritual) { ChatReadingRitualFeature() }
        .ifLet(\.$numerologyCards, action: \.numerologyCards) { NumerologyCardsFeature() }
        .ifLet(\.$detail, action: \.detail) { ChatReadingDetailFeature() }
    }

    private func pickerState(_ state: State) -> ChatProfilePickerFeature.State { .init(profiles: profilesClient.loadAllProfiles(), selectedIDs: state.selectedProfiles.map(\.id), mode: state.selectedProfiles.count > 1 ? .couple : .single) }
    private func persist(_ owner: String, _ messages: [ChatMessage]) -> Effect<Action> { .run { _ in try? await history.save(owner, messages) } }
    private func appendAssistant(_ text: String, card: ChatCardPayload?, to state: inout State) { state.messages.append(.init(id: "mascot-\(uuid().uuidString)", sender: .mascot, text: text, time: time(now), card: card, isTypingCompleted: false)); state.messages = Array(state.messages.suffix(100)); state.isLoading = false; state.mascotState = "answer"; state.pending = nil }
    private func time(_ date: Date) -> String { let f = DateFormatter(); f.locale = Locale(identifier: "vi_VN"); f.dateFormat = "HH:mm"; return f.string(from: date) }
    private func prepareResponse(_ state: inout State) -> Effect<Action> {
        guard var pending = state.pending, let p1 = state.selectedProfiles.first else { return .none }
        pending.indicators1 = numerology.requestedIndicators(p1.fullName, p1.birthDate, pending.decision.targetIndicators, now)
        if state.selectedProfiles.count > 1 { let p2 = state.selectedProfiles[1]; pending.indicators2 = numerology.requestedIndicators(p2.fullName, p2.birthDate, pending.decision.targetIndicators, now) }
        if state.selectedProfiles.count > 1, pending.decision.mode == .compatibility {
            let p2 = state.selectedProfiles[1]
            guard let input1 = ziWeiInput(p1), let input2 = ziWeiInput(p2),
                  let chart1 = try? tuViClient.generateChart(input1), let chart2 = try? tuViClient.generateChart(input2),
                  let analysis = try? tuViClient.evaluateLoveCompatibility(chart1, chart2)
            else {
                appendAssistant("✦ CHƯA THỂ LẬP ĐỦ HAI LÁ SỐ:\nHãy kiểm tra ngày sinh, giờ sinh chính xác và giới tính của cả hai hồ sơ rồi thử lại.", card: nil, to: &state)
                return persist(state.ownerID, state.messages)
            }
            pending.ziWeiCompatibility = .init(chart1: chart1, chart2: chart2, analysis: analysis)
        }
        if pending.decision.needsTarot { pending.cards = (try? TarotEngine.bundled().drawCardsForSpread(pending.decision.spreadId)) ?? [] }
        if pending.decision.intent == .colorGuidance, let card = pending.cards.first { pending.color = try? ColorGuidanceEngine.create(birthDate: p1.birthDate, card: card) }
        state.pending = pending
        if !pending.cards.isEmpty { state.ritual = .init(id: pending.id, question: pending.prompt, cards: pending.cards) }
        let request = ChatAgentRequest(message: pending.prompt, decision: pending.decision, timeZone: TimeZone.current.identifier, profiles: state.selectedProfiles, indicators: .init(profile1: pending.indicators1, profile2: pending.indicators2), tarotCards: pending.cards, colorGuidance: pending.color, tuViBazi: nil, ziWeiCompatibility: pending.ziWeiCompatibility, placeContext: pending.place)
        return .run { send in do { let value = try await chatClient.answer(request); await send(.response(.success(ChatAnswer(text: value.0, card: value.1)))) } catch { await send(.response(.failure(.server(error.localizedDescription)))) } }.cancellable(id: CancelID.request, cancelInFlight: true)
    }
    private func finishRitual(_ state: inout State, text: String) -> Effect<Action> { state.ritual?.status = .revealed; state.isLoading = false; state.mascotState = "answer"; return .run { _ in await speech.speak("detail", text) } }
    private func ziWeiInput(_ profile: UserProfile) -> ZiWeiBirthInput? {
        let date = profile.birthDate.split(separator: "-").compactMap { Int($0) }
        guard date.count == 3 else { return nil }
        let time = profile.birthTime?.split(separator: ":").compactMap { Int($0) } ?? []
        guard time.count == 2, let gender = profile.gender else { return nil }
        return .init(year: date[0], month: date[1], day: date[2], hour: time[0], minute: time[1], gender: gender, timeZoneOffsetHours: 7, ruleset: .vietnameseDefaultV2)
    }
}
