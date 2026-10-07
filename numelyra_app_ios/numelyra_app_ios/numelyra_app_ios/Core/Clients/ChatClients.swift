import AVFoundation
import ComposableArchitecture
import CoreLocation
import Foundation
import Speech
import UIKit

@DependencyClient
struct ChatClient: Sendable {
    var classify: @Sendable (_ request: ChatClassifyRequest) async throws -> AgentDecision
    var answer: @Sendable (_ request: ChatAgentRequest) async throws -> (String, ChatCardPayload?)
}

extension ChatClient: DependencyKey {
    static var liveValue: Self {
        @Dependency(\.supabaseClient) var supabase
        return Self(
            classify: { payload in
                let data = try await Self.post(payload, to: AppConfig.chatClassifyURL, token: await supabase.accessToken())
                let response = try JSONDecoder().decode(ChatClassifyResponse.self, from: data)
                guard response.ok, let decision = response.data else { throw ChatError.server(response.error ?? "Không thể phân loại câu hỏi.") }
                return decision
            },
            answer: { payload in
                let data = try await Self.post(payload, to: AppConfig.chatAgentURL, token: await supabase.accessToken(), timeout: 60)
                let response = try JSONDecoder().decode(ChatAgentResponse.self, from: data)
                guard response.ok, let result = response.data else { throw ChatError.server(response.error ?? "Không thể tạo lời giải.") }
                var card = try result.cardPayload.map { raw -> ChatCardPayload in
                    try JSONDecoder().decode(ChatCardPayload.self, from: JSONEncoder().encode(raw))
                }
                if case let .agentSynthesis(value)? = card {
                    var merged = value
                    merged.questionText = payload.message
                    merged.drawnCards = payload.tarotCards
                    if merged.ziWeiCompatibility == nil { merged.ziWeiCompatibility = payload.ziWeiCompatibility }
                    card = .agentSynthesis(merged)
                } else if case let .placeSuggestions(places)? = card {
                    card = .agentSynthesis(.init(decision: payload.decision, profiles: payload.profiles, drawnCards: payload.tarotCards, indicators1: payload.indicators.profile1, indicators2: payload.indicators.profile2, ziWeiCompatibility: payload.ziWeiCompatibility, colorGuidance: payload.colorGuidance, questionText: payload.message, placeSuggestions: places))
                } else if case let .tarot(legacy)? = card {
                    var merged = legacy
                    merged.cards = payload.tarotCards
                    card = .tarot(merged)
                } else if card == nil {
                    card = .agentSynthesis(.init(decision: payload.decision, profiles: payload.profiles, drawnCards: payload.tarotCards, indicators1: payload.indicators.profile1, indicators2: payload.indicators.profile2, tuViBazi: payload.tuViBazi, ziWeiCompatibility: payload.ziWeiCompatibility, colorGuidance: payload.colorGuidance, questionText: payload.message))
                }
                return (result.replyText, card)
            }
        )
    }
    static let testValue = Self()

    private static func post<T: Encodable>(_ payload: T, to url: URL, token: String?, timeout: TimeInterval = 30) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token, !token.isEmpty { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONEncoder().encode(payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
            throw ChatError.server(message ?? "Máy chủ Chat không phản hồi.")
        }
        return data
    }
}

extension DependencyValues {
    var chatClient: ChatClient { get { self[ChatClient.self] } set { self[ChatClient.self] = newValue } }
}

private actor ChatHistoryStore {
    static let shared = ChatHistoryStore()
    private let rootOverride: URL?
    private struct Envelope: Codable {
        var version: Int
        var ownerID: String
        var messages: [ChatMessage]
    }
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(root: URL? = nil) { rootOverride = root }

    func load(_ owner: String) -> [ChatMessage] {
        let url = fileURL(owner)
        guard let data = try? Data(contentsOf: url),
              let envelope = try? decoder.decode(Envelope.self, from: data),
              envelope.version == 1,
              envelope.ownerID == owner
        else {
            if FileManager.default.fileExists(atPath: url.path) { try? FileManager.default.removeItem(at: url) }
            return []
        }
        return normalize(envelope.messages)
    }

    func save(_ owner: String, _ messages: [ChatMessage]) throws {
        let url = fileURL(owner)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(Envelope(version: 1, ownerID: owner, messages: normalize(messages))).write(to: url, options: .atomic)
    }

    private func normalize(_ values: [ChatMessage]) -> [ChatMessage] {
        values.suffix(100).map { value in
            var item = value
            if item.sender == .mascot { item.isTypingCompleted = true }
            return item
        }
    }

    private func fileURL(_ owner: String) -> URL {
        let root = rootOverride ?? ((try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)) ?? FileManager.default.temporaryDirectory).appending(path: "Numelyra/ChatHistory/v1")
        let safe = Data((owner.isEmpty ? "guest" : owner).utf8).base64EncodedString().replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "+", with: "-")
        return root.appending(path: "\(safe).json")
    }
}

@DependencyClient
struct ChatHistoryClient: Sendable {
    var load: @Sendable (_ owner: String) async -> [ChatMessage] = { _ in [] }
    var save: @Sendable (_ owner: String, _ messages: [ChatMessage]) async throws -> Void
}

extension ChatHistoryClient: DependencyKey {
    static let liveValue = Self(load: { await ChatHistoryStore.shared.load($0) }, save: { try await ChatHistoryStore.shared.save($0, $1) })
    static let testValue = Self()
}

extension ChatHistoryClient {
    static func fileBacked(directory: URL) -> Self {
        let store = ChatHistoryStore(root: directory)
        return Self(load: { await store.load($0) }, save: { try await store.save($0, $1) })
    }
}

extension DependencyValues {
    var chatHistoryClient: ChatHistoryClient { get { self[ChatHistoryClient.self] } set { self[ChatHistoryClient.self] = newValue } }
}

private final class SpeechBox: @unchecked Sendable {
    static let shared = SpeechBox()
    let synthesizer = AVSpeechSynthesizer()
}

@DependencyClient
struct SpeechClient: Sendable {
    var speak: @Sendable (_ id: String, _ text: String) async -> Void = { _, _ in }
    var stop: @Sendable () async -> Void = {}
}

extension SpeechClient: DependencyKey {
    static let liveValue = Self(
        speak: { _, raw in
            await MainActor.run {
                let box = SpeechBox.shared
                box.synthesizer.stopSpeaking(at: .immediate)
                let clean = raw.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
                    .replacingOccurrences(of: #"https?://\S+"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: "✦", with: "")
                let chunks = clean.split(separator: "\n", omittingEmptySubsequences: true).reduce(into: [String]()) { result, line in
                    let value = String(line)
                    if let last = result.indices.last, result[last].count + value.count < 700 { result[last] += ". \(value)" }
                    else { result.append(value) }
                }
                for chunk in chunks.flatMap({ value -> [String] in
                    guard value.count > 700 else { return [value] }
                    var output: [String] = [], current = ""
                    for word in value.split(separator: " ") {
                        if current.count + word.count > 700 { output.append(current); current = "" }
                        current += (current.isEmpty ? "" : " ") + word
                    }
                    if !current.isEmpty { output.append(current) }
                    return output
                }) {
                    let utterance = AVSpeechUtterance(string: chunk)
                    utterance.voice = AVSpeechSynthesisVoice(language: "vi-VN")
                    utterance.rate = 0.5
                    box.synthesizer.speak(utterance)
                }
            }
        },
        stop: { await MainActor.run { SpeechBox.shared.synthesizer.stopSpeaking(at: .immediate) } }
    )
    static let testValue = Self()
}

extension DependencyValues {
    var speechClient: SpeechClient { get { self[SpeechClient.self] } set { self[SpeechClient.self] = newValue } }
}

@MainActor
private final class RecognitionBox: @unchecked Sendable {
    static let shared = RecognitionBox()
    private let engine = AVAudioEngine()
    private var task: SFSpeechRecognitionTask?

    func stream() -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    guard status == .authorized else { continuation.finish(throwing: ChatError.permissionDenied("Cần cấp quyền Nhận dạng giọng nói để dùng micro.")); return }
                    AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                        Task { @MainActor in
                            guard allowed else { continuation.finish(throwing: ChatError.permissionDenied("Cần cấp quyền Micro để nhập bằng giọng nói.")); return }
                            do { try self.start(continuation) } catch { continuation.finish(throwing: error) }
                        }
                    }
                }
            }
            continuation.onTermination = { _ in Task { @MainActor in self.stop() } }
        }
    }

    private func start(_ continuation: AsyncThrowingStream<String, Error>.Continuation) throws {
        stop()
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        let node = engine.inputNode
        let format = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in request.append(buffer) }
        engine.prepare(); try engine.start()
        task = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))?.recognitionTask(with: request) { result, error in
            if let text = result?.bestTranscription.formattedString, !text.isEmpty { continuation.yield(text) }
            if let error { continuation.finish(throwing: error) }
            else if result?.isFinal == true { continuation.finish() }
        }
    }

    func stop() {
        task?.cancel(); task = nil
        if engine.isRunning { engine.stop() }
        engine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

@DependencyClient
struct SpeechRecognitionClient: Sendable {
    var start: @Sendable () async -> AsyncThrowingStream<String, Error> = { AsyncThrowingStream { $0.finish() } }
    var stop: @Sendable () async -> Void = {}
}

extension SpeechRecognitionClient: DependencyKey {
    static let liveValue = Self(start: { await RecognitionBox.shared.stream() }, stop: { await RecognitionBox.shared.stop() })
    static let testValue = Self()
}

extension DependencyValues {
    var speechRecognitionClient: SpeechRecognitionClient { get { self[SpeechRecognitionClient.self] } set { self[SpeechRecognitionClient.self] = newValue } }
}

@MainActor
private final class LocationBox: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    static let shared = LocationBox()
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?
    override init() { super.init(); manager.delegate = self; manager.desiredAccuracy = kCLLocationAccuracyHundredMeters }
    func request() async throws -> CLLocation {
        if let location = manager.location, abs(location.timestamp.timeIntervalSinceNow) <= 300, location.horizontalAccuracy <= 1_000 { return location }
        let status = manager.authorizationStatus
        if status == .denied || status == .restricted { throw ChatError.permissionDenied("Bạn cần cho phép dùng vị trí hiện tại để tìm địa điểm gần bạn.") }
        return try await withCheckedThrowingContinuation {
            continuation = $0
            if status == .notDetermined { manager.requestWhenInUseAuthorization() }
            else { manager.requestLocation() }
        }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: manager.requestLocation()
        case .denied, .restricted:
            continuation?.resume(throwing: ChatError.permissionDenied("Bạn cần cho phép dùng vị trí hiện tại để tìm địa điểm gần bạn.")); continuation = nil
        default: break
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { continuation?.resume(returning: locations.last ?? CLLocation()); continuation = nil }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { continuation?.resume(throwing: error); continuation = nil }
}

@DependencyClient
struct PlaceLocationClient: Sendable {
    var locate: @Sendable (_ preferences: PlaceSearchPreferences) async throws -> PlaceSearchContext
}
extension PlaceLocationClient: DependencyKey {
    static let liveValue = Self(locate: { preferences in let value = try await LocationBox.shared.request(); return .init(preferences: preferences, latitude: value.coordinate.latitude, longitude: value.coordinate.longitude) })
    static let testValue = Self()
}
extension DependencyValues { var placeLocationClient: PlaceLocationClient { get { self[PlaceLocationClient.self] } set { self[PlaceLocationClient.self] = newValue } } }

@DependencyClient
struct ExternalURLClient: Sendable { var open: @Sendable (_ url: URL) async -> Bool = { _ in false } }
extension ExternalURLClient: DependencyKey {
    static let liveValue = Self(open: { url in
        await MainActor.run {
            guard UIApplication.shared.canOpenURL(url) else { return false }
            UIApplication.shared.open(url)
            return true
        }
    })
    static let testValue = Self()
}
extension DependencyValues { var externalURLClient: ExternalURLClient { get { self[ExternalURLClient.self] } set { self[ExternalURLClient.self] = newValue } } }
