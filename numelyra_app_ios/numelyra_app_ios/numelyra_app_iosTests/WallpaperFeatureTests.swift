import ComposableArchitecture
import Foundation
import XCTest
@testable import numelyra_app_ios

@MainActor
final class WallpaperFeatureTests: XCTestCase {
    func testGenerateBuildsReactNativePayloadAndReplacesPresets() async throws {
        let clock = TestClock()
        let capturedRequest = LockIsolated<LuckyWallpaperRequest?>(nil)
        let generated = [makeRemoteItem(index: 1), makeRemoteItem(index: 2)]
        let profile = UserProfile(
            id: "profile-1",
            fullName: "Nguyễn An",
            birthDate: "1998-10-20",
            gender: .female
        )
        var initialState = WallpaperFeature.State(profile: profile)
        initialState.prompt = "Một khu rừng bình yên"

        let store = TestStore(initialState: initialState) {
            WallpaperFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.date.now = makeDate(2026, 10, 7)
            $0.hapticClient = .testValue
            $0.wallpaperClient.randomStyle = { WallpaperStyleOption.allStyles[4] }
            $0.wallpaperClient.randomIntention = { WallpaperIntentionOption.allIntentions[2] }
            $0.wallpaperClient.generate = { request in
                capturedRequest.setValue(request)
                return generated
            }
            $0.wallpaperClient.save = { _ in WallpaperSaveResult(message: "saved") }
        }

        await store.send(.generateTapped) {
            $0.step = .generating
        }
        await clock.advance(by: .milliseconds(2_500))
        await store.receive(.generationSucceeded(generated)) {
            $0.history = generated
            $0.step = .result
            $0.toastMessage = "✨ Đã tạo xong 2 phiên bản hình nền may mắn!"
        }

        let request = try XCTUnwrap(capturedRequest.value)
        XCTAssertEqual(request.fullName, "Nguyễn An")
        XCTAssertEqual(request.birthDate, "1998-10-20")
        XCTAssertEqual(request.customWish, "Một khu rừng bình yên")
        XCTAssertEqual(request.styleId, "watercolor_nature")
        XCTAssertEqual(request.intentionId, "peace")
        XCTAssertEqual(request.deviceType, "mobile")
        XCTAssertEqual(request.count, 4)

        await clock.advance(by: .milliseconds(2_650))
        await store.receive(.toastDismissed("✨ Đã tạo xong 2 phiên bản hình nền may mắn!")) {
            $0.toastMessage = nil
        }
    }

    func testGenerationFailureReturnsToInputWithoutMockFallback() async {
        let clock = TestClock()
        let initialHistory = WallpaperFeature.presetItems
        let store = TestStore(initialState: WallpaperFeature.State(history: initialHistory)) {
            WallpaperFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.hapticClient = .testValue
            $0.wallpaperClient.randomStyle = { WallpaperStyleOption.allStyles[0] }
            $0.wallpaperClient.randomIntention = { WallpaperIntentionOption.allIntentions[0] }
            $0.wallpaperClient.generate = { _ in throw WallpaperClientError.noImage }
            $0.wallpaperClient.save = { _ in WallpaperSaveResult(message: "saved") }
        }

        await store.send(.generateTapped) {
            $0.step = .generating
        }
        await clock.advance(by: .milliseconds(2_500))
        await store.receive(.generationFailed(WallpaperClientError.noImage.localizedDescription)) {
            $0.step = .input
            $0.toastMessage = "⚠️ Không thể tạo hình nền: Máy chủ chưa trả về hình nền nào."
        }
        XCTAssertEqual(store.state.history, initialHistory)

        await clock.advance(by: .milliseconds(2_650))
        await store.receive(.toastDismissed("⚠️ Không thể tạo hình nền: Máy chủ chưa trả về hình nền nào.")) {
            $0.toastMessage = nil
        }
    }

    func testSaveFailureRestoresSavingState() async {
        let clock = TestClock()
        let item = makeRemoteItem(index: 1)
        let store = TestStore(initialState: WallpaperFeature.State(history: [item])) {
            WallpaperFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.hapticClient = .testValue
            $0.wallpaperClient.randomStyle = { WallpaperStyleOption.allStyles[0] }
            $0.wallpaperClient.randomIntention = { WallpaperIntentionOption.allIntentions[0] }
            $0.wallpaperClient.generate = { _ in [item] }
            $0.wallpaperClient.save = { _ in throw WallpaperClientError.photosPermissionDenied }
        }

        await store.send(.saveTapped(item)) {
            $0.isSaving = true
        }
        await store.receive(.saveFailed(WallpaperClientError.photosPermissionDenied.localizedDescription)) {
            $0.isSaving = false
            $0.toastMessage = "Cần cấp quyền thêm ảnh để lưu hình nền."
        }

        await clock.advance(by: .milliseconds(2_650))
        await store.receive(.toastDismissed("Cần cấp quyền thêm ảnh để lưu hình nền.")) {
            $0.toastMessage = nil
        }
    }

    func testRequestJSONUsesActualReactNativePersonalCycleKeys() throws {
        let request = LuckyWallpaperRequest(
            fullName: "An",
            birthDate: "1998-10-20",
            lifePathNumber: 3,
            destinyNumber: 8,
            personalYear: 5,
            personalDay: 7,
            intentionId: "peace",
            styleId: "watercolor_nature",
            customWish: "Bình yên"
        )
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
        )

        XCTAssertEqual(object["personalYear"] as? Int, 5)
        XCTAssertEqual(object["personalDay"] as? Int, 7)
        XCTAssertNil(object["personalYearNumber"])
        XCTAssertNil(object["personalDayNumber"])
    }

    private func makeRemoteItem(index: Int) -> WallpaperItem {
        WallpaperItem(
            id: "ai-\(index)",
            imageUrl: "https://example.com/\(index).png",
            title: "Bản \(index)",
            affirmationVi: "Bình an",
            explanationVi: "Giải thích",
            luckyColorsVi: ["Tím"],
            styleName: "Mộng mơ",
            intentionName: "An lạc"
        )
    }

    private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar(identifier: .gregorian).date(
            from: DateComponents(year: year, month: month, day: day, hour: 12)
        )!
    }
}
