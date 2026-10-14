import ComposableArchitecture
import Foundation
import XCTest
@testable import numelyra_app_ios

@MainActor
final class CalendarFeatureTests: XCTestCase {
    func testOnAppearLoadsSnapshotAndDailyCaDao() async {
        let date = makeDate(2026, 2, 17)
        let snapshot = LunarService.makeDaySnapshot(
            for: date,
            birthDateString: "1998-10-20",
            currentHour: 9
        )
        let art = offlineArt(for: snapshot.lunarDate)
        let caDao = CaDaoRecord(
            id: 42,
            title: "",
            content: "Uống nước nhớ nguồn",
            category: "Ca dao dân gian",
            url: ""
        )

        let store = TestStore(
            initialState: CalendarFeature.State(
                selectedDate: date,
                profile: UserProfile(fullName: "Minh Anh", birthDate: "1998-10-20")
            )
        ) {
            CalendarFeature()
        } withDependencies: {
            $0.lunarClient.daySnapshot = { date, birthDate, _ in
                LunarService.makeDaySnapshot(
                    for: date,
                    birthDateString: birthDate,
                    currentHour: 9
                )
            }
            $0.caDaoClient.dailyCaDao = { _ in caDao }
            $0.calendarArtClient.item = { _ in art }
            $0.calendarArtClient.loadImage = { _ in
                throw CalendarArtClientError.invalidResponse
            }
            $0.hapticClient = .testValue
        }

        await store.send(.onAppear) {
            $0.snapshot = snapshot
            $0.art = art
            $0.isLoadingCaDao = true
        }
        await store.receive(.contentLoaded(date: date, caDao: caDao)) {
            $0.caDao = caDao
            $0.isLoadingCaDao = false
        }
    }

    func testStaleCaDaoResponseDoesNotOverwriteNewDate() async {
        let oldDate = makeDate(2026, 2, 17)
        let newDate = makeDate(2026, 2, 18)
        let record = CaDaoRecord(id: 7, title: "", content: "Cũ", category: "", url: "")
        var state = CalendarFeature.State(selectedDate: newDate)
        state.caDao = nil
        state.isLoadingCaDao = true

        let store = TestStore(initialState: state) {
            CalendarFeature()
        }

        await store.send(.contentLoaded(date: oldDate, caDao: record))
    }

    func testCalendarArtSelectionMatchesReactNativeStride() {
        let spring = CalendarArtEngine.item(for: LunarDate(day: 1, month: 1, year: 2026))
        let summer = CalendarArtEngine.item(for: LunarDate(day: 1, month: 4, year: 2026))
        let autumn = CalendarArtEngine.item(for: LunarDate(day: 1, month: 7, year: 2026))
        let winter = CalendarArtEngine.item(for: LunarDate(day: 1, month: 10, year: 2026))

        XCTAssertEqual(CalendarImageCatalog.filenames(for: .spring).count, 122)
        XCTAssertEqual(CalendarImageCatalog.filenames(for: .summer).count, 73)
        XCTAssertEqual(CalendarImageCatalog.filenames(for: .autumn).count, 42)
        XCTAssertEqual(CalendarImageCatalog.filenames(for: .winter).count, 60)
        XCTAssertEqual(spring.season, .spring)
        XCTAssertEqual(summer.season, .summer)
        XCTAssertEqual(autumn.season, .autumn)
        XCTAssertEqual(winter.season, .winter)
        XCTAssertEqual(spring.literature.id, "art-truyen-kieu")

        let repeated = CalendarArtEngine.item(for: LunarDate(day: 1, month: 1, year: 2026))
        XCTAssertEqual(spring, repeated)
    }

    func testProfileUpdatedMarksNeedsRefreshAndReloadsOnAppear() async {
        let date = makeDate(2026, 2, 17)
        let oldProfile = UserProfile(id: "1", fullName: "Minh Anh", birthDate: "1998-10-20")
        let newProfile = UserProfile(id: "2", fullName: "Bảo Ngọc", birthDate: "2000-01-15")
        let snapshot1 = LunarService.makeDaySnapshot(for: date, birthDateString: "1998-10-20", currentHour: 9)
        let snapshot2 = LunarService.makeDaySnapshot(for: date, birthDateString: "2000-01-15", currentHour: 9)
        let art = offlineArt(for: snapshot1.lunarDate)
        let caDao = CaDaoRecord(id: 1, title: "", content: "Lời ru", category: "Ca dao", url: "")

        var state = CalendarFeature.State(selectedDate: date, profile: oldProfile)
        state.snapshot = snapshot1
        state.art = art

        let store = TestStore(initialState: state) {
            CalendarFeature()
        } withDependencies: {
            $0.lunarClient.daySnapshot = { _, birthDate, _ in
                birthDate == "2000-01-15" ? snapshot2 : snapshot1
            }
            $0.caDaoClient.dailyCaDao = { _ in caDao }
            $0.calendarArtClient.item = { _ in art }
            $0.calendarArtClient.loadImage = { _ in throw CalendarArtClientError.invalidResponse }
            $0.hapticClient = .testValue
        }

        await store.send(.profileUpdated(newProfile)) {
            $0.profile = newProfile
            $0.needsRefresh = true
        }

        await store.send(.onAppear) {
            $0.needsRefresh = false
            $0.snapshot = snapshot2
            $0.isLoadingCaDao = true
        }
        await store.receive(\.contentLoaded) {
            $0.caDao = caDao
            $0.isLoadingCaDao = false
        }
    }

    func testOnAppearUsesCachedImageImmediatelyWhenAvailable() async {
        let date = makeDate(2026, 2, 17)
        let snapshot = LunarService.makeDaySnapshot(for: date, birthDateString: nil, currentHour: 9)
        var art = CalendarArtEngine.item(for: snapshot.lunarDate)
        let cachedData = Data("cached-art-data".utf8)
        let testURL = URL(string: "https://assets.numelyra.online/spring/test.jpeg")!
        art.imageURL = testURL

        let caDao = CaDaoRecord(id: 1, title: "", content: "Lời ru", category: "Ca dao", url: "")

        let store = TestStore(initialState: CalendarFeature.State(selectedDate: date)) {
            CalendarFeature()
        } withDependencies: {
            $0.lunarClient.daySnapshot = { _, _, _ in snapshot }
            $0.caDaoClient.dailyCaDao = { _ in caDao }
            $0.calendarArtClient.item = { _ in art }
            $0.calendarArtClient.cachedImage = { url in
                url == testURL ? cachedData : nil
            }
            $0.calendarArtClient.prefetch = { _ in }
            $0.hapticClient = .testValue
        }

        await store.send(.onAppear) {
            $0.snapshot = snapshot
            $0.art = art
            $0.remoteArtData = cachedData
            $0.isLoadingCaDao = true
        }

        await store.receive(\.contentLoaded) {
            $0.caDao = caDao
            $0.isLoadingCaDao = false
        }
    }

    func testCalendarArtCacheRollingWindowActiveKeysAndPurge() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CalendarArtCacheTests-\(UUID().uuidString)")
        let cache = CalendarArtCache(directoryURL: tempDir)
        defer { cache.removeAll(); try? FileManager.default.removeItem(at: tempDir) }

        let centerDate = makeDate(2026, 2, 17)
        let activeKeys = cache.activeImageKeys(around: centerDate)

        // Cửa sổ ±2 ngày quanh 17/02/2026: tối đa 5 ngày
        XCTAssertLessThanOrEqual(activeKeys.count, 5)
        XCTAssertGreaterThanOrEqual(activeKeys.count, 1)

        // Lưu 1 file hợp lệ trong activeKeys và 1 file rác ngoài cửa sổ
        let validURL = URL(string: "https://assets.numelyra.online/spring/\(activeKeys.first!)")!
        let staleURL = URL(string: "https://assets.numelyra.online/spring/stale_image_outside_window.jpeg")!

        cache.store(data: Data("valid".utf8), for: validURL, referenceDate: centerDate)
        cache.store(data: Data("stale".utf8), for: staleURL, referenceDate: centerDate)

        // Sau purge quanh centerDate, file hợp lệ còn tồn tại, file rác bị xoá
        XCTAssertNotNil(cache.data(for: validURL))
        XCTAssertNil(cache.data(for: staleURL))
    }

    private func offlineArt(for lunarDate: LunarDate) -> CalendarArtItem {
        var item = CalendarArtEngine.item(for: lunarDate)
        item.imageURL = nil
        return item
    }

    private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        LunarService.defaultCalendar.date(
            from: DateComponents(year: year, month: month, day: day, hour: 12)
        )!
    }
}
