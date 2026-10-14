import Foundation
import XCTest
@testable import numelyra_app_ios

final class DateFormatExtensionTests: XCTestCase {
    func testStorageDateRoundTripsAndRejectsInvalidCalendarDate() throws {
        let formatter = DateFormatter.appStorageDate
        let date = try XCTUnwrap(formatter.date(from: "2026-10-13"))

        XCTAssertEqual(formatter.string(from: date), "2026-10-13")
        XCTAssertNil(formatter.date(from: "2026-02-30"))
        XCTAssertEqual(
            DateFormatter.appStorageDateString(year: 2000, month: 1, day: 1),
            "2000-01-01"
        )
        XCTAssertNil(DateFormatter.appStorageDateString(year: 2026, month: 2, day: 30))
    }

    func testISO8601ParserAcceptsStandardAndFractionalSeconds() {
        XCTAssertNotNil(ISO8601DateFormatter.appDate(from: "2026-10-06T12:00:00Z"))
        XCTAssertNotNil(ISO8601DateFormatter.appDate(from: "2026-10-06T12:00:00.123Z"))
        XCTAssertNil(ISO8601DateFormatter.appDate(from: "2026-10-06"))
    }

    func testLocalDateKeyUsesRequestedTimeZone() throws {
        let date = try XCTUnwrap(
            ISO8601DateFormatter.appDate(from: "2026-10-13T18:30:00Z")
        )

        XCTAssertEqual(
            DateFormatter.appLocalDateKey(timeZone: TimeZone(secondsFromGMT: 7 * 3_600)!)
                .string(from: date),
            "2026-10-14"
        )
        XCTAssertEqual(
            DateFormatter.appLocalDateKey(timeZone: TimeZone(secondsFromGMT: 0)!)
                .string(from: date),
            "2026-10-13"
        )
    }

    func testVietnameseDateAndClockFormats() throws {
        let date = try XCTUnwrap(
            ISO8601DateFormatter.appDate(from: "2026-10-05T16:45:00Z")
        )
        let utc = try XCTUnwrap(TimeZone(secondsFromGMT: 0))

        XCTAssertEqual(
            DateFormatter.appVietnameseShortDate(timeZone: utc).string(from: date),
            "5/10/2026"
        )
        XCTAssertEqual(
            DateFormatter.appBirthTime(timeZone: utc).string(from: date),
            "16:45"
        )
        XCTAssertEqual(
            DateFormatter.appMessageTime(timeZone: utc).string(from: date),
            "16:45"
        )
    }
}
