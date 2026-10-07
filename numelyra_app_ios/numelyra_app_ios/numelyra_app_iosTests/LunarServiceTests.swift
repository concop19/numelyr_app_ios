import Foundation
import XCTest
@testable import numelyra_app_ios

final class LunarServiceTests: XCTestCase {
    func testSolarToLunarGoldenDatesAndLeapMonth() {
        XCTAssertEqual(
            LunarService.solarToLunar(day: 10, month: 2, year: 2024),
            LunarDate(day: 1, month: 1, year: 2024)
        )
        XCTAssertEqual(
            LunarService.solarToLunar(day: 17, month: 2, year: 2026),
            LunarDate(day: 1, month: 1, year: 2026)
        )
        XCTAssertEqual(
            LunarService.solarToLunar(day: 22, month: 3, year: 2023),
            LunarDate(day: 1, month: 2, year: 2023, leap: true)
        )
    }

    func testCanChiHourNguThuDonFormula() {
        // Ngày Giáp (0) và Kỷ (5) khởi giờ Tý là Giáp Tý
        XCTAssertEqual(LunarService.getCanChiHour(hourChiIdx: 0, dayCanIdx: 0), "Giáp Tý")
        XCTAssertEqual(LunarService.getCanChiHour(hourChiIdx: 1, dayCanIdx: 5), "Ất Sửu")
        // Ngày Ất (1) và Canh (6) khởi giờ Tý là Bính Tý
        XCTAssertEqual(LunarService.getCanChiHour(hourChiIdx: 0, dayCanIdx: 1), "Bính Tý")
        // Ngày Bính (2) và Tân (7) khởi giờ Tý là Mậu Tý
        XCTAssertEqual(LunarService.getCanChiHour(hourChiIdx: 0, dayCanIdx: 2), "Mậu Tý")
        // Ngày Đinh (3) và Nhâm (8) khởi giờ Tý là Canh Tý
        XCTAssertEqual(LunarService.getCanChiHour(hourChiIdx: 0, dayCanIdx: 3), "Canh Tý")
        // Ngày Mậu (4) và Quý (9) khởi giờ Tý là Nhâm Tý
        XCTAssertEqual(LunarService.getCanChiHour(hourChiIdx: 0, dayCanIdx: 4), "Nhâm Tý")
    }

    func testNapAmAndNguHanhByBirthYear() {
        // 1984 Giáp Tý -> Hải Trung Kim (hành Kim, trong khi Thiên Can Giáp là Mộc)
        XCTAssertEqual(LunarService.getNapAmYear(birthYear: 1984), "Hải Trung Kim")
        XCTAssertEqual(LunarService.getNguHanh(birthYear: 1984), "Kim")
        XCTAssertEqual(LunarService.getThienCanNguHanh(birthYear: 1984), "Mộc")

        // 1998 Mậu Dần -> Thành Đầu Thổ
        XCTAssertEqual(LunarService.getNapAmYear(birthYear: 1998), "Thành Đầu Thổ")
        XCTAssertEqual(LunarService.getNguHanh(birthYear: 1998), "Thổ")

        // 1996 Bính Tý -> Giản Hạ Thủy
        XCTAssertEqual(LunarService.getNapAmYear(birthYear: 1996), "Giản Hạ Thủy")
        XCTAssertEqual(LunarService.getNguHanh(birthYear: 1996), "Thủy")

        // Sinh ngày 15/01/1998 Dương lịch (trước Tết Mậu Dần 28/01/1998) -> Năm Âm lịch là 1997 (Đinh Sửu - Giản Hạ Thủy)
        let preTetLunarYear = LunarService.extractBirthYear(from: "1998-01-15")
        XCTAssertEqual(preTetLunarYear, 1997)
        XCTAssertEqual(LunarService.getZodiac(birthYear: preTetLunarYear), "Sửu")
        XCTAssertEqual(LunarService.getNapAmYear(birthYear: preTetLunarYear), "Giản Hạ Thủy")

        // Sinh ngày 15/06/1998 Dương lịch (sau Tết) -> Năm Âm lịch là 1998 (Mậu Dần - Thành Đầu Thổ)
        let postTetLunarYear = LunarService.extractBirthYear(from: "1998-06-15")
        XCTAssertEqual(postTetLunarYear, 1998)
        XCTAssertEqual(LunarService.getZodiac(birthYear: postTetLunarYear), "Dần")
        XCTAssertEqual(LunarService.getNapAmYear(birthYear: postTetLunarYear), "Thành Đầu Thổ")

        XCTAssertEqual(LunarService.extractBirthYear(from: "2000-02-30"), 1998)
    }

    func testHoangDaoHoursMatchTwelveDayStarsAndThanhLongStart() {
        // Ngày 17/02/2026 (Mùng 1 Tết Bính Ngọ) -> Ngày Nhâm Tuất (Địa Chi Tuất = 10)
        // Ngày Thìn/Tuất khởi Thanh Long tại giờ Thìn (index 4)
        let hours = LunarService.getHoangDaoHours(day: 17, month: 2, year: 2026, zodiac: "Dần")
        XCTAssertEqual(hours.count, 12)

        let hoangDaoNames = hours.filter(\.isHoangDao).map(\.name)
        // Ngày Thìn, Tuất có 6 giờ Hoàng Đạo: Dần, Thìn, Tỵ, Thân, Dậu, Hợi
        XCTAssertEqual(hoangDaoNames, ["Dần", "Thìn", "Tỵ", "Thân", "Dậu", "Hợi"])

        // Giờ Thìn (index 4) phải là Thanh Long; Giờ Dần (index 2) phải là Tư Mệnh
        XCTAssertEqual(hours[4].name, "Thìn")
        XCTAssertEqual(hours[4].label, "Thanh Long")
        XCTAssertTrue(hours[4].isHoangDao)
        XCTAssertTrue(hours[4].isDayClash) // Ngày Tuất xung giờ Thìn (Nhật Phá)

        XCTAssertEqual(hours[2].name, "Dần")
        XCTAssertEqual(hours[2].label, "Tư Mệnh")
        XCTAssertTrue(hours[2].isHoangDao)
        XCTAssertFalse(hours[2].isDayClash)

        // Tuổi Dần xung giờ Thân (index 8)
        XCTAssertEqual(hours[8].name, "Thân")
        XCTAssertTrue(hours[8].isClash)
    }

    func testBestDepartureHourDoesNotSelectMidnightTyInTheMorning() {
        // Ngày có giờ Tý (23h-01h) là Hoàng Đạo, kiểm tra lúc 8h sáng phải chọn giờ ban ngày chứ không chọn giờ Tý (startHour = 23)
        // Ngày 15/02/2026 là ngày Canh Thân (Dần/Thân khởi Thanh Long tại Tý -> Tý, Sửu, Thìn, Tỵ, Mùi, Tuất là Hoàng Đạo)
        let bestMorning = LunarService.getBestDepartureHour(
            day: 15,
            month: 2,
            year: 2026,
            zodiac: "Tý",
            currentHour: 8
        )
        XCTAssertEqual(bestMorning?.name, "Thìn")
        XCTAssertEqual(bestMorning?.range, "07h-09h")
    }

    func testBestDepartureHourHandlesBothPartsOfTyHourAndDoesNotReturnPastHour() {
        let midnightTy = LunarService.getBestDepartureHour(
            day: 15,
            month: 2,
            year: 2026,
            zodiac: "Tý",
            currentHour: 0,
            currentMinute: 30
        )
        XCTAssertEqual(midnightTy?.name, "Tý")

        let lateTy = LunarService.getBestDepartureHour(
            day: 15,
            month: 2,
            year: 2026,
            zodiac: "Tý",
            currentHour: 23,
            currentMinute: 30
        )
        XCTAssertEqual(lateTy?.name, "Tý")

        let noPastFallback = LunarService.getBestDepartureHour(
            day: 17,
            month: 2,
            year: 2026,
            zodiac: "Dần",
            currentHour: 23,
            currentMinute: 30
        )
        XCTAssertNil(noPastFallback)
    }

    func testDayDirectionUsesDayThienCanAndHacThanCycle() {
        // Ngày 17/02/2026 là ngày Nhâm Tuất (Can Nhâm = 8, Sexagenary index = 58)
        // Can Nhâm: Hỷ Thần = Chính Nam, Tài Thần = Chính Tây
        // Nhâm Tuất (58): Hạc Thần tại Đông Nam (56..59, 0..1)
        let dir = LunarService.getDayDirection(day: 17, month: 2, year: 2026)
        XCTAssertEqual(dir.hyThan, "Chính Nam")
        XCTAssertEqual(dir.taiThan, "Chính Tây")
        XCTAssertEqual(dir.hacThan, "Đông Nam")
    }

    func testDayActivitiesUsesThapNhiKienTru() {
        // Ngày 17/02/2026 (Mùng 1 tháng Giêng năm Bính Ngọ):
        // Tháng Giêng (Dần = 2), Ngày Nhâm Tuất (Tuất = 10) -> (10 - 2) % 12 = 8 -> Trực Thành (Tốt)
        let activities = LunarService.getDayActivities(day: 17, month: 2, year: 2026)
        XCTAssertEqual(activities.trucName, "Thành")
        XCTAssertEqual(activities.trucQuality, "Tốt")
        XCTAssertFalse(activities.yi.isEmpty)
        XCTAssertFalse(activities.ji.isEmpty)
    }

    func testDayActivitiesUsesSolarTermMonthInsteadOfLunarMonth() {
        // 05/02/2026 vẫn là 18 tháng Chạp nhưng đã qua Lập Xuân ngày 04/02.
        // Nguyệt kiến đã sang Dần; ngày Canh Tuất vì vậy là Trực Thành, không phải Trực Thu.
        XCTAssertEqual(
            LunarService.getSolarMonthDiaChiIndex(day: 5, month: 2, year: 2026),
            2
        )
        XCTAssertEqual(LunarService.getSolarMonthDiaChiIndex(day: 3, month: 2, year: 2026), 1)
        XCTAssertEqual(LunarService.getSolarMonthDiaChiIndex(day: 4, month: 2, year: 2026), 2)
        let activities = LunarService.getDayActivities(day: 5, month: 2, year: 2026)
        XCTAssertEqual(activities.trucName, "Thành")
    }

    func testSolarTermLabelMatchesSolarMonthTransition() {
        // Lập xuân 2025: nhập tiết vào tối 03/02/2025
        XCTAssertEqual(LunarService.getSolarTerm(day: 2, month: 2, year: 2025), "Đại hàn")
        XCTAssertEqual(LunarService.getSolarMonthDiaChiIndex(day: 2, month: 2, year: 2025), 1) // Sửu

        XCTAssertEqual(LunarService.getSolarTerm(day: 3, month: 2, year: 2025), "Lập xuân")
        XCTAssertEqual(LunarService.getSolarMonthDiaChiIndex(day: 3, month: 2, year: 2025), 2) // Dần

        XCTAssertEqual(LunarService.getSolarTerm(day: 4, month: 2, year: 2025), "Lập xuân")
        XCTAssertEqual(LunarService.getSolarMonthDiaChiIndex(day: 4, month: 2, year: 2025), 2) // Dần

        // Lập xuân 2026: nhập tiết vào 04/02/2026
        XCTAssertEqual(LunarService.getSolarTerm(day: 3, month: 2, year: 2026), "Đại hàn")
        XCTAssertEqual(LunarService.getSolarMonthDiaChiIndex(day: 3, month: 2, year: 2026), 1) // Sửu

        XCTAssertEqual(LunarService.getSolarTerm(day: 4, month: 2, year: 2026), "Lập xuân")
        XCTAssertEqual(LunarService.getSolarMonthDiaChiIndex(day: 4, month: 2, year: 2026), 2) // Dần

        XCTAssertEqual(LunarService.getSolarTerm(day: 5, month: 2, year: 2026), "Lập xuân")
        XCTAssertEqual(LunarService.getSolarMonthDiaChiIndex(day: 5, month: 2, year: 2026), 2) // Dần
    }

    func testSnapshotDoesNotRecommendDepartureHourForPastDate() throws {
        let calendar = LunarService.defaultCalendar
        let selectedDate = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 2, day: 15, hour: 12))
        )
        let referenceDate = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 2, day: 17, hour: 8))
        )

        let snapshot = LunarService.makeDaySnapshot(
            for: selectedDate,
            currentHour: 8,
            referenceDate: referenceDate
        )
        XCTAssertNil(snapshot.bestDepartureHour)
    }

    func testHeroLunarTextShowsLeapMonth() {
        XCTAssertEqual(
            LunarService.formatHeroLunarText(LunarDate(day: 1, month: 2, year: 2023, leap: true)),
            "1 tháng Hai nhuận · Âm lịch"
        )
    }
}
