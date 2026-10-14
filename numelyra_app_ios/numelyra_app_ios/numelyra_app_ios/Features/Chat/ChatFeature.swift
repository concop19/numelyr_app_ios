import ComposableArchitecture
import Foundation

@Reducer
struct ChatProfilePickerFeature {
    enum Mode: Equatable { case single, couple }
    @ObservableState
    struct State: Equatable {
        /// Toàn bộ hồ sơ cục bộ có thể chọn hoặc xóa trong picker.
        var profiles: [UserProfile]
        /// ID các hồ sơ đang chọn; tối đa một ID ở chế độ cá nhân và hai ID ở chế độ cặp đôi.
        var selectedIDs: [String]
        /// Chế độ chọn một hồ sơ cá nhân hoặc hai hồ sơ để luận tương hợp.
        var mode: Mode
        /// Điều khiển việc hiển thị form tạo hồ sơ mới ngay trong picker.
        var isAdding = false
        /// Họ tên đang nhập cho hồ sơ mới.
        var newName = ""
        /// Ngày sinh đang nhập cho hồ sơ mới theo định dạng lưu trữ `YYYY-MM-DD`.
        var newBirthDate = "2000-01-01"
        /// Giờ sinh đang nhập cho hồ sơ mới theo định dạng `HH:mm`.
        var newBirthTime = "12:00"
        /// Cho biết người dùng xác nhận có giờ sinh chính xác; nếu không, hồ sơ lưu giờ sinh là `nil`.
        var hasBirthTime = false
        /// Giới tính đang chọn cho hồ sơ mới.
        var newGender = Gender.female
        /// Lỗi tạo hồ sơ hoặc cảnh báo chưa chọn đủ hồ sơ để xác nhận.
        var errorMessage: String?
    }
    enum Action: Equatable {
        case modeChanged(Mode), profileTapped(String), confirmTapped, addToggled
        case nameChanged(String), birthDateChanged(String), birthTimeChanged(String), hasBirthTimeChanged(Bool), genderChanged(Gender), saveProfileTapped
        case deleteTapped(String), closeTapped
        case delegate(Delegate)
        enum Delegate: Equatable
        { case selected([UserProfile]);
            case close }
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
    @ObservableState
    struct State: Equatable {
        /// Bán kính tìm kiếm tối đa tính bằng kilomet.
        var distance = 5.0
        /// Mức ngân sách dùng để lọc địa điểm phù hợp.
        var budget = PlaceBudget.medium
        /// Kiểu người đồng hành dùng để cá nhân hóa gợi ý địa điểm.
        var companion = PlaceCompanion.solo
        /// Quy định kết quả chỉ gồm các địa điểm đang mở cửa hay không.
        var openNow = true
        /// Cho biết feature đang xin/lấy vị trí hiện tại và tìm ngữ cảnh địa điểm.
        var isLocating = false
        /// Lỗi quyền vị trí hoặc lỗi định vị cần hiển thị trong picker.
        var errorMessage: String?
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
    @ObservableState
    struct State: Equatable, Identifiable {
        /// ID của lượt trả lời đang thực hiện nghi thức, đồng thời liên kết với tin nhắn mascot tương ứng.
        var id: String
        /// Câu hỏi của người dùng được hiển thị trong nghi thức Tarot.
        var question: String
        /// Các lá Tarot đã rút cho kiểu trải bài của lượt hiện tại.
        var cards: [DrawnTarotCard]
        /// Số lá đã được người dùng lật, dùng để xác định lá kế tiếp và thời điểm hoàn tất nghi thức.
        var revealedCount = 0
        /// Giai đoạn nghi thức: chờ luận giải, luận giải đã sẵn sàng, hoặc đã lật đủ bài để hiển thị.
        var status = Status.waiting
        /// Nội dung luận giải trả về từ agent; có thể chưa có trong lúc người dùng đang lật bài.
        var replyText: String?

        /// Cho biết toàn bộ lá đã lật và luận giải đã được mở khóa để hiển thị/cho phép đóng.
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
    @ObservableState
    struct State: Equatable, Identifiable {
        /// Tin nhắn trả lời của mascot đang được trình bày ở chế độ chi tiết.
        var message: ChatMessage
        /// Câu hỏi người dùng gần nhất đứng trước tin nhắn trả lời; `nil` nếu lịch sử không còn câu hỏi tương ứng.
        var question: String?
        /// Định danh ổn định của màn chi tiết, lấy trực tiếp từ ID tin nhắn.
        var id: String { message.id }
    }
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
    @Reducer
    enum Destination {
        case profilePicker(ChatProfilePickerFeature)
        case placePicker(ChatPlacePickerFeature)
        case ritual(ChatReadingRitualFeature)
        case numerologyCards(NumerologyCardsFeature)
        case detail(ChatReadingDetailFeature)
    }
    @ObservableState
    struct State: Equatable {
        /// Chủ sở hữu lịch sử chat hiện tại: user ID của phiên đăng nhập hoặc `guest`.
        var ownerID = "guest"
        /// Cho biết hồ sơ và lịch sử của `ownerID` đã được nạp xong, cho phép gửi tin nhắn mới.
        var isHydrated = false
        /// Tối đa 100 tin nhắn gần nhất của chủ sở hữu hiện tại.
        var messages: [ChatMessage] = []
        /// Điều khiển việc hiển thị toàn bộ lịch sử thay vì chỉ lượt hội thoại gần nhất.
        var showAllHistory = false
        /// Nội dung đang soạn trong ô nhập chat.
        var draft = ""
        /// Hồ sơ dùng cho lượt chat: rỗng khi chưa chọn, một hồ sơ để luận cá nhân hoặc hai hồ sơ để luận tương hợp.
        var selectedProfiles: [UserProfile] = []
        /// Cho biết lượt chat hiện tại đang phân loại, tạo câu trả lời hoặc chờ hoàn tất nghi thức.
        var isLoading = false
        /// Cho biết dịch vụ nhận dạng giọng nói đang thu âm và phát transcript.
        var isListening = false
        /// Lỗi nhận dạng giọng nói hoặc lỗi nghiệp vụ cần hiển thị cho người dùng.
        var errorMessage: String?
        /// Ngữ cảnh trung gian của lượt đang xử lý, giữ quyết định agent và dữ liệu đã chuẩn bị cho request.
        var pending: PendingTurn?
        /// Khóa trạng thái animation của mascot, hiện dùng các giá trị `idle`, `thinking` và `answer`.
        var mascotState = "idle"
        /// Khóa biến thể hình ảnh mascot; hiện feature giữ giá trị `default` cho mọi lượt chat.
        var mascotCategory = "default"
        /// Token của lần hydrate đang chạy, dùng để bỏ qua response cũ sau khi owner hoặc lifecycle thay đổi.
        var hydrationID: UUID?
        /// Presentation duy nhất đang mở trong Chat, như picker hồ sơ, vị trí, Tarot, thần số học hoặc chi tiết.
        @Presents var destination: Destination.State?

        /// Danh sách tin nhắn View cần render theo chế độ lịch sử đầy đủ hoặc lượt gần nhất.
        var visibleMessages: [ChatMessage] { showAllHistory ? messages : Array(messages.suffix(messages.last?.sender == .mascot ? 2 : 1)) }
    }
    enum Action: Equatable {
        case onAppear, onDisappear, hydrated(UUID, String, [UserProfile], [ChatMessage]), ownerChanged(String)
        case draftChanged(String), sendTapped, classified(Result<AgentDecision, ChatError>), response(Result<ChatAnswer, ChatError>)
        case historyToggleTapped, profileTapped, mascotTapped, microphoneTapped, transcriptReceived(String), listeningEnded, listeningFailed(String)
        case messageTypingFinished(String), messageTapped(String), mapTapped(String), errorDismissed
        case locationResponse(Result<PlaceSearchContext, ChatError>)
        case destination(PresentationAction<Destination.Action>)
    }
    @Dependency(\.chatClient) var chatClient; @Dependency(\.chatHistoryClient) var history
    @Dependency(\.userProfileClient) var profilesClient; @Dependency(\.supabaseClient) var supabase
    @Dependency(\.numerologyClient) var numerology; @Dependency(\.speechClient) var speech
    @Dependency(\.speechRecognitionClient) var recognition; @Dependency(\.placeLocationClient) var location
    @Dependency(\.externalURLClient) var externalURL; @Dependency(\.date.now) var now; @Dependency(\.uuid) var uuid
    @Dependency(\.tuViClient) var tuViClient
    private nonisolated enum CancelID: Hashable, Sendable { case load, request, recognition, location }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let hydrationID = uuid()
                state.hydrationID = hydrationID
                return .run { send in
                    let session = await supabase.currentSession(); let owner = session?.userId ?? "guest"
                    await send(.hydrated(hydrationID, owner, profilesClient.loadAllProfiles(), await history.load(owner)))
                }.cancellable(id: CancelID.load, cancelInFlight: true)
            case .onDisappear:
                state.hydrationID = nil
                state.isListening = false
                state.isLoading = false
                state.pending = nil
                state.destination = nil
                state.mascotState = "idle"
                return .merge(.cancel(id: CancelID.load), .cancel(id: CancelID.recognition), .cancel(id: CancelID.request), .cancel(id: CancelID.location), .run { _ in await recognition.stop(); await location.cancel(); await speech.stop() })
            case let .hydrated(hydrationID, owner, profiles, messages):
                guard state.hydrationID == hydrationID else { return .none }
                if owner != state.ownerID {
                    state = State()
                    state.ownerID = owner
                    state.hydrationID = hydrationID
                }
                state.ownerID = owner
                state.messages = messages
                state.selectedProfiles = profilesClient.activeProfile().map { [$0] } ?? Array(profiles.prefix(1))
                state.isHydrated = true
                state.hydrationID = nil
                return .none
            case let .ownerChanged(owner):
                guard owner != state.ownerID else { return .none }
                let hydrationID = uuid()
                state = State()
                state.ownerID = owner
                state.hydrationID = hydrationID
                return .merge(
                    .cancel(id: CancelID.request), .cancel(id: CancelID.recognition), .cancel(id: CancelID.location),
                    .run { _ in await recognition.stop(); await location.cancel(); await speech.stop() },
                    .run { send in await send(.hydrated(hydrationID, owner, profilesClient.loadAllProfiles(), await history.load(owner))) }.cancellable(id: CancelID.load, cancelInFlight: true)
                )
            case let .draftChanged(value): state.draft = value; return .none
            case .sendTapped:
                let prompt = state.draft.trimmingCharacters(in: .whitespacesAndNewlines)
                guard state.isHydrated, !state.isLoading, !prompt.isEmpty else { return .none }
                guard !state.selectedProfiles.isEmpty else { state.destination = .profilePicker(pickerState(state)); return .none }
                if state.selectedProfiles.count > 1, ColorGuidanceEngine.isColorQuestion(prompt) { state.errorMessage = "Màu hợp mệnh cần đúng một hồ sơ. Hãy chọn chế độ Cá nhân."; state.destination = .profilePicker(pickerState(state)); return .none }
                if state.selectedProfiles.count > 1, state.selectedProfiles.contains(where: { $0.gender == nil || $0.effectiveBirthTimeAccuracy != .exact || $0.birthTime?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false }) {
                    state.errorMessage = "Luận tương hợp Tử Vi mới cần giới tính và giờ sinh chính xác của cả hai hồ sơ. Hãy bổ sung hồ sơ trước khi gửi."
                    state.destination = .profilePicker(pickerState(state))
                    return .none
                }
                state.messages.append(.init(id: "user-\(uuid().uuidString)", sender: .user, text: prompt, time: time(now)))
                state.messages = Array(state.messages.suffix(100)); state.showAllHistory = false; state.draft = ""; state.isLoading = true; state.mascotState = "thinking"
                let profiles = state.selectedProfiles; let snapshot = state.messages; let owner = state.ownerID
                return .merge(persist(owner, snapshot), .run { send in
                    do { await send(.classified(.success(try await chatClient.classify(.init(message: prompt, profiles: profiles))))) }
                    catch is CancellationError { }
                    catch { await send(.classified(.failure(.server(error.localizedDescription)))) }
                }.cancellable(id: CancelID.request, cancelInFlight: true))
            case let .classified(result):
                guard let user = state.messages.last(where: { $0.sender == .user }) else { return .none }
                let decision = (try? result.get()) ?? ChatDecisionEngine.evaluate(user.text, profiles: state.selectedProfiles)
                if decision.intent == .trash { appendAssistant(decision.replyText ?? ChatDecisionEngine.trashReply, card: nil, to: &state); return persist(state.ownerID, state.messages) }
                state.pending = PendingTurn(id: "mascot-\(uuid().uuidString)", prompt: user.text, decision: decision)
                if decision.intent == .whereToGo { state.isLoading = false; state.destination = .placePicker(.init()); return .none }
                return prepareResponse(&state)
            case let .locationResponse(result):
                switch result {
                case let .success(context):
                    state.destination = nil
                    state.pending?.place = context
                    state.isLoading = true
                    return prepareResponse(&state)
                case let .failure(error):
                    if case var .some(.placePicker(picker)) = state.destination {
                        picker.isLocating = false
                        picker.errorMessage = error.localizedDescription
                        state.destination = .placePicker(picker)
                    }
                    return .none
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
                if case var .some(.ritual(ritual)) = state.destination, ritual.id == pending.id {
                    ritual.replyText = output.text
                    ritual.status = .ready
                    state.destination = .ritual(ritual)
                    if ritual.revealedCount == pending.cards.count {
                        let finish = finishRitual(&state, text: output.text)
                        let save = persist(state.ownerID, state.messages)
                        state.pending = nil
                        return .merge(finish, save)
                    }
                }
                let effect = persist(state.ownerID, state.messages); state.pending = nil; return effect
            case .historyToggleTapped: state.showAllHistory.toggle(); return .none
            case .profileTapped: state.destination = .profilePicker(pickerState(state)); return .none
            case .mascotTapped:
                guard let profile = state.selectedProfiles.first else { state.destination = .profilePicker(pickerState(state)); return .none }
                state.destination = .numerologyCards(.init(activeProfile: profile)); return .none
            case .microphoneTapped:
                if state.isListening {
                    state.isListening = false
                    state.mascotState = state.messages.last?.sender == .mascot ? "answer" : "idle"
                    return .merge(.cancel(id: CancelID.recognition), .run { _ in await recognition.stop() })
                }
                state.isListening = true
                state.mascotState = "thinking"
                return .run { send in
                    do { for try await value in await recognition.start() { await send(.transcriptReceived(value)) }; await send(.listeningEnded) }
                    catch is CancellationError { }
                    catch { await send(.listeningFailed(error.localizedDescription)) }
                }.cancellable(id: CancelID.recognition, cancelInFlight: true)
            case let .transcriptReceived(value): state.draft = value; return .none
            case .listeningEnded: state.isListening = false; state.mascotState = state.messages.last?.sender == .mascot ? "answer" : "idle"; return .none
            case let .listeningFailed(message): state.isListening = false; state.mascotState = state.messages.last?.sender == .mascot ? "answer" : "idle"; state.errorMessage = message; return .none
            case let .messageTypingFinished(id): if let index = state.messages.firstIndex(where: { $0.id == id }) { state.messages[index].isTypingCompleted = true; return persist(state.ownerID, state.messages) }; return .none
            case let .messageTapped(id):
                guard let index = state.messages.firstIndex(where: { $0.id == id }), state.messages[index].sender == .mascot, state.messages[index].isTypingCompleted else { return .none }
                let question = state.messages[..<index].last(where: { $0.sender == .user })?.text
                state.destination = .detail(.init(message: state.messages[index], question: question))
                return .none
            case let .mapTapped(raw): guard let url = URL(string: raw) else { return .none }; return .run { _ in _ = await externalURL.open(url) }
            case .destination(.presented(.detail(.delegate(.close)))): state.destination = nil; return .none
            case let .destination(.presented(.detail(.delegate(.openMap(raw))))): guard let url = URL(string: raw) else { return .none }; return .run { _ in _ = await externalURL.open(url) }
            case .errorDismissed: state.errorMessage = nil; return .none
            case let .destination(.presented(.profilePicker(.delegate(.selected(values))))): state.selectedProfiles = values; state.destination = nil; return .none
            case .destination(.presented(.profilePicker(.delegate(.close)))): state.destination = nil; return .none
            case let .destination(.presented(.placePicker(.delegate(.locate(preferences))))):
                return .run { send in
                    do { await send(.locationResponse(.success(try await location.locate(preferences)))) }
                    catch is CancellationError { }
                    catch { await send(.locationResponse(.failure(.permissionDenied(error.localizedDescription)))) }
                }.cancellable(id: CancelID.location, cancelInFlight: true)
            case .destination(.presented(.placePicker(.delegate(.cancel)))):
                state.destination = nil; state.isLoading = false; state.pending = nil
                appendAssistant("✦ TIỂU LINH MIÊU CẦN VỊ TRÍ HIỆN TẠI:\nĐể lọc địa điểm theo khoảng cách thực tế, bạn hãy cho phép dùng vị trí một lần nhé.", card: nil, to: &state)
                return .merge(.cancel(id: CancelID.location), .run { _ in await location.cancel() }, persist(state.ownerID, state.messages))
            case .destination(.dismiss):
                let dismissedDestination = state.destination
                switch dismissedDestination {
                case .some(.placePicker):
                    state.isLoading = false
                    state.pending = nil
                    appendAssistant("✦ TIỂU LINH MIÊU CẦN VỊ TRÍ HIỆN TẠI:\nĐể lọc địa điểm theo khoảng cách thực tế, bạn hãy cho phép dùng vị trí một lần nhé.", card: nil, to: &state)
                    return .merge(.cancel(id: CancelID.location), .run { _ in await location.cancel() }, persist(state.ownerID, state.messages))
                case .some(.ritual):
                    state.isLoading = false
                    state.mascotState = "idle"
                    return .run { _ in await speech.stop() }
                case .some(.profilePicker), .some(.numerologyCards), .some(.detail), .none:
                    return .none
                }
            case .destination(.presented(.ritual(.delegate(.revealedAll)))):
                if case let .some(.ritual(ritual)) = state.destination, ritual.status == .ready, let text = ritual.replyText { return finishRitual(&state, text: text) }
                return .none
            case .destination(.presented(.ritual(.delegate(.close)))): state.destination = nil; state.isLoading = false; state.mascotState = "idle"; return .run { _ in await speech.stop() }
            case .destination(.presented(.numerologyCards(.delegate(.didClose)))), .destination(.presented(.numerologyCards(.closeTapped))): state.destination = nil; return .none
            case .destination: return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    private func pickerState(_ state: State) -> ChatProfilePickerFeature.State { .init(profiles: profilesClient.loadAllProfiles(), selectedIDs: state.selectedProfiles.map(\.id), mode: state.selectedProfiles.count > 1 ? .couple : .single) }
    private func persist(_ owner: String, _ messages: [ChatMessage]) -> Effect<Action> { .run { _ in try? await history.save(owner, messages) } }
    private func appendAssistant(_ text: String, card: ChatCardPayload?, to state: inout State) { state.messages.append(.init(id: "mascot-\(uuid().uuidString)", sender: .mascot, text: text, time: time(now), card: card, isTypingCompleted: false)); state.messages = Array(state.messages.suffix(100)); state.isLoading = false; state.mascotState = "answer"; state.pending = nil }
    private func time(_ date: Date) -> String {
        DateFormatter.appMessageTime().string(from: date)
    }
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
        if !pending.cards.isEmpty { state.destination = .ritual(.init(id: pending.id, question: pending.prompt, cards: pending.cards)) }
        let request = ChatAgentRequest(message: pending.prompt, decision: pending.decision, timeZone: TimeZone.current.identifier, profiles: state.selectedProfiles, indicators: .init(profile1: pending.indicators1, profile2: pending.indicators2), tarotCards: pending.cards, colorGuidance: pending.color, tuViBazi: nil, ziWeiCompatibility: pending.ziWeiCompatibility, placeContext: pending.place)
        return .run { send in
            do { let value = try await chatClient.answer(request); await send(.response(.success(ChatAnswer(text: value.0, card: value.1)))) }
            catch is CancellationError { }
            catch { await send(.response(.failure(.server(error.localizedDescription)))) }
        }.cancellable(id: CancelID.request, cancelInFlight: true)
    }
    private func finishRitual(_ state: inout State, text: String) -> Effect<Action> {
        if case var .some(.ritual(ritual)) = state.destination {
            ritual.status = .revealed
            state.destination = .ritual(ritual)
        }
        state.isLoading = false
        state.mascotState = "answer"
        return .run { _ in await speech.speak("detail", text) }
    }
    private func ziWeiInput(_ profile: UserProfile) -> ZiWeiBirthInput? {
        let date = profile.birthDate.split(separator: "-").compactMap { Int($0) }
        guard date.count == 3 else { return nil }
        let time = profile.birthTime?.split(separator: ":").compactMap { Int($0) } ?? []
        guard time.count == 2, let gender = profile.gender else { return nil }
        return .init(year: date[0], month: date[1], day: date[2], hour: time[0], minute: time[1], gender: gender, timeZoneOffsetHours: 7, ruleset: .vietnameseDefaultV2)
    }
}

extension ChatFeature.Destination.State: Equatable {}
extension ChatFeature.Destination.Action: Equatable {}
