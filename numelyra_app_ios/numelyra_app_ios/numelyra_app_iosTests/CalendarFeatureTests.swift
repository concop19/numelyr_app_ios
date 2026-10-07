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
