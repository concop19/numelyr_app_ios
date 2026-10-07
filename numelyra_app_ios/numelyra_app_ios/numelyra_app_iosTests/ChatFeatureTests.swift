import ComposableArchitecture
import Foundation
import XCTest
@testable import numelyra_app_ios

final class ChatEngineTests: XCTestCase {
    private let profile = UserProfile(id: "p1", fullName: "Nguyễn An", birthDate: "1998-10-20", gender: .male)

    func testDecisionEngineCoversPrimaryIntentsAndTrash() {
        XCTAssertEqual(ChatDecisionEngine.evaluate("test", profiles: [profile]).intent, .trash)
        XCTAssertEqual(ChatDecisionEngine.evaluate("Màu nào hợp với tôi?", profiles: [profile]).intent, .colorGuidance)
        XCTAssertEqual(ChatDecisionEngine.evaluate("Tôi nên đi đâu hôm nay?", profiles: [profile]).intent, .whereToGo)
        XCTAssertEqual(ChatDecisionEngine.evaluate("Tính cách của tôi thế nào?", profiles: [profile]).intent, .corePersonality)
        XCTAssertEqual(ChatDecisionEngine.evaluate("Sắp tới công việc ra sao?", profiles: [profile]).intent, .timingTrajectory)
        XCTAssertEqual(ChatDecisionEngine.evaluate("Cho tôi lời khuyên hôm nay", profiles: [profile]).intent, .dailyGuidance)
        XCTAssertEqual(ChatDecisionEngine.evaluate("Một câu hỏi không khớp", profiles: [profile]).intent, .general)
        XCTAssertEqual(ChatDecisionEngine.evaluate("Chúng tôi có hợp nhau?", profiles: [profile, UserProfile(id: "p2", fullName: "Minh", birthDate: "2000-01-01", gender: .female)]).intent, .loveMatch)
    }

    func testTarotSpreadCountsAreOneThreeAndFive() throws {
        let engine = try TarotEngine.bundled()
        XCTAssertEqual(engine.drawCardsForSpread(.single).count, 1)
        XCTAssertEqual(engine.drawCardsForSpread(.threeCard).count, 3)
        XCTAssertEqual(engine.drawCardsForSpread(.twoOptions).count, 5)
        XCTAssertEqual(engine.drawCardsForSpread(.relationship).count, 5)
    }

    func testUnknownPayloadRoundTripsLosslessly() throws {
        let data = Data(#"{"type":"future_widget","nested":{"enabled":true},"count":3}"#.utf8)
        let decoded = try JSONDecoder().decode(ChatCardPayload.self, from: data)
        guard case let .unsupported(raw) = decoded else { return XCTFail("Expected unsupported payload") }
        let roundTrip = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(decoded))
        XCTAssertEqual(roundTrip, raw)
    }

    func testNestedPlaceSuggestionsDecode() throws {
        let data = Data(#"{"placeSuggestions":{"areaLabel":"Quận 1","attribution":"Google Maps","places":[{"placeId":"abc","name":"Vườn Tao Đàn","mapsUrl":"https://maps.google.com/?q=abc","distanceKm":1.2,"openNow":true}]}}"#.utf8)
        let payload = try JSONDecoder().decode(ChatCardPayload.self, from: data)
        guard case let .placeSuggestions(value) = payload else { return XCTFail("Expected place suggestions") }
        XCTAssertEqual(value.areaLabel, "Quận 1")
        XCTAssertEqual(value.places.first?.name, "Vườn Tao Đàn")
    }

    func testNewZiWeiCompatibilityIsUsedByOfflineSynthesis() throws {
        let second = UserProfile(id: "p2", fullName: "Minh", birthDate: "2000-01-01", gender: .female, birthTime: "08:30")
        let chart1 = try TuViEngine.generateChart(.init(year: 1998, month: 10, day: 20, hour: 12, gender: .male))
        let chart2 = try TuViEngine.generateChart(.init(year: 2000, month: 1, day: 1, hour: 8, minute: 30, gender: .female))
        let analysis = try TuViEngine.evaluateLoveCompatibility(chartA: chart1, chartB: chart2)
        let compatibility = ChatZiWeiCompatibilityPayload(chart1: chart1, chart2: chart2, analysis: analysis)
        let decision = AgentDecision(mode: .compatibility, intent: .loveMatch)
        let result = ChatSynthesisEngine.make(prompt: "Có hợp nhau không?", decision: decision, profiles: [profile, second], indicators: [], cards: [], ziWeiCompatibility: compatibility)
        XCTAssertTrue(result.0.contains("\(analysis.score)/100"))
        XCTAssertEqual(result.1.ziWeiCompatibility, compatibility)
        XCTAssertNil(result.1.tuViBazi)
    }
}

final class ChatHistoryClientTests: XCTestCase {
    func testOwnerIsolationLimitAndCompletedRestore() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "numelyra-chat-history-tests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let client = ChatHistoryClient.fileBacked(directory: root)
        let guest = (0..<105).map { index in ChatMessage(id: "g-\(index)", sender: index.isMultiple(of: 2) ? .user : .mascot, text: "guest \(index)", isTypingCompleted: false) }
        let user = [ChatMessage(id: "u-1", sender: .mascot, text: "user", isTypingCompleted: false)]

        try await client.save("guest", guest)
        try await client.save("user-1", user)

        let restoredGuest = await client.load("guest")
        let restoredUser = await client.load("user-1")
        XCTAssertEqual(restoredGuest.count, 100)
        XCTAssertEqual(restoredGuest.first?.id, "g-5")
        XCTAssertEqual(restoredUser.map(\.id), ["u-1"])
        XCTAssertTrue(restoredGuest.filter { $0.sender == .mascot }.allSatisfy(\.isTypingCompleted))
        XCTAssertTrue(restoredUser[0].isTypingCompleted)
    }
}

@MainActor
final class ChatReducerTests: XCTestCase {
    func testSendWithoutProfilePresentsPickerBeforeAppendingQuestion() async {
        var state = ChatFeature.State()
        state.isHydrated = true
        state.draft = "Tương lai của tôi thế nào?"
        let store = TestStore(initialState: state) { ChatFeature() } withDependencies: {
            $0.userProfileClient.loadAllProfiles = { [] }
        }

        await store.send(.sendTapped) {
            $0.profilePicker = .init(profiles: [], selectedIDs: [], mode: .single)
        }
        XCTAssertTrue(store.state.messages.isEmpty)
    }

    func testColorQuestionWithTwoProfilesDoesNotAppendOrCallAgent() async {
        let profiles = [
            UserProfile(id: "a", fullName: "An", birthDate: "1998-10-20", gender: .male),
            UserProfile(id: "b", fullName: "Bình", birthDate: "2000-01-01", gender: .female),
        ]
        var state = ChatFeature.State()
        state.isHydrated = true
        state.selectedProfiles = profiles
        state.draft = "Màu gì hợp với chúng tôi?"
        let store = TestStore(initialState: state) { ChatFeature() } withDependencies: {
            $0.userProfileClient.loadAllProfiles = { profiles }
        }

        await store.send(.sendTapped) {
            $0.errorMessage = "Màu hợp mệnh cần đúng một hồ sơ. Hãy chọn chế độ Cá nhân."
            $0.profilePicker = .init(profiles: profiles, selectedIDs: ["a", "b"], mode: .couple)
        }
        XCTAssertTrue(store.state.messages.isEmpty)
        XCTAssertFalse(store.state.isLoading)
    }
}
