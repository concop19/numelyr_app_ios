import Foundation

/// Pure domain engine tính toán Âm lịch Việt Nam (thuật toán Hồ Ngọc Đức),
/// Can Chi, 12 giờ Hoàng/Hắc đạo, Tiết khí, Việc nên/kiêng và tiện ích Lịch Blốc.
///
/// Đối chiếu 1:1 với `numelyra_app/src/services/lunarService.ts`,
/// `numelyra_app/src/store/userProfile.ts` và `numelyra_app/src/screens/CalendarScreen.tsx`.
public enum LunarService {

    // MARK: - 1. Constants

    public static let defaultTimeZoneOffset: Double = 7.0
    public static let defaultFallbackBirthYear: Int = 1998

    public static var vietnamTimeZone: TimeZone {
        TimeZone(secondsFromGMT: Int(defaultTimeZoneOffset * 3600)) ?? .gmt
    }

    public static var defaultCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "vi_VN")
        calendar.timeZone = vietnamTimeZone
        calendar.firstWeekday = 2 // Thứ Hai
        return calendar
    }

    public static let thienCan: [String] = [
        "Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"
    ]

    public static let diaChi: [String] = [
        "Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"
    ]

    public static let solarMonthsVi: [String] = [
        "Tháng 1", "Tháng 2", "Tháng 3", "Tháng 4", "Tháng 5", "Tháng 6",
        "Tháng 7", "Tháng 8", "Tháng 9", "Tháng 10", "Tháng 11", "Tháng 12"
    ]

    public static let lunarMonthsVi: [String] = [
        "Giêng", "Hai", "Ba", "Tư", "Năm", "Sáu",
        "Bảy", "Tám", "Chín", "Mười", "Mười một", "Chạp"
    ]

    public static let solarMonthsEn: [String] = [
        "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
        "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"
    ]

    public static let weekdaysViSundayFirst: [String] = [
        "Chủ Nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy"
    ]

    public static let weekdaysEnSundayFirst: [String] = [
        "SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"
    ]

    public static let weekdaysViMondayFirst: [String] = [
        "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy", "Chủ Nhật"
    ]

    public static let weekdaysShortViMondayFirst: [String] = [
        "Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "CN"
    ]

    private struct RawHourDefinition: Sendable {
        let name: String
        let range: String
        let startHour: Int
    }
    // cấu trúc các dư liệu giờ ví dụ thanh long -> 23h tới 1h , phạm vi là 2 tiéng

    private static let gioInfo: [RawHourDefinition] = [
        .init(name: "Tý", range: "23h-01h", startHour: 23),
        .init(name: "Sửu", range: "01h-03h", startHour: 1),
        .init(name: "Dần", range: "03h-05h", startHour: 3),
        .init(name: "Mão", range: "05h-07h", startHour: 5),
        .init(name: "Thìn", range: "07h-09h", startHour: 7),
        .init(name: "Tỵ", range: "09h-11h", startHour: 9),
        .init(name: "Ngọ", range: "11h-13h", startHour: 11),
        .init(name: "Mùi", range: "13h-15h", startHour: 13),
        .init(name: "Thân", range: "15h-17h", startHour: 15),
        .init(name: "Dậu", range: "17h-19h", startHour: 17),
        .init(name: "Tuất", range: "19h-21h", startHour: 19),
        .init(name: "Hợi", range: "21h-23h", startHour: 21),
    ]

    /// Tứ Hành Xung: mỗi con giáp xung với con giáp đối diện (cách 6 vị trí)
    public static let tuHanhXung: [String: String] = [
        "Tý": "Ngọ", "Sửu": "Mùi", "Dần": "Thân", "Mão": "Dậu",
        "Thìn": "Tuất", "Tỵ": "Hợi", "Ngọ": "Tý", "Mùi": "Sửu",
        "Thân": "Dần", "Dậu": "Mão", "Tuất": "Thìn", "Hợi": "Tỵ"
    ]
//  các con giáp được đặt trên 1 vòng quay đối diện với con còn lại được gọi xung khắc để tìm các giờ ko bị xung khắc
    // giowf tốt hoặc hướng
    /// Giờ khởi sao Thanh Long (sao đầu tiên trong 12 sao Hoàng/Hắc đạo) theo Địa Chi của ngày:
    /// - Dần (2), Thân (8) -> Tý (0)
    /// - Mão (3), Dậu (9) -> Dần (2)
    /// - Thìn (4), Tuất (10) -> Thìn (4)
    /// - Tỵ (5), Hợi (11) -> Ngọ (6)
    /// - Tý (0), Ngọ (6) -> Thân (8)
    /// - Sửu (1), Mùi (7) -> Tuất (10)
    private static let thanhLongStartHourByDayChi: [Int: Int] = [
        0: 8, 6: 8,   // Tý, Ngọ -> Thân (8)
        1: 10, 7: 10, // Sửu, Mùi -> Tuất (10)
        2: 0, 8: 0,   // Dần, Thân -> Tý (0)
        3: 2, 9: 2,   // Mão, Dậu -> Dần (2)
        4: 4, 10: 4,  // Thìn, Tuất -> Thìn (4)
        5: 6, 11: 6   // Tỵ, Hợi -> Ngọ (6)
    ]
    //vì thanh long start ở ngày đầu tiên lịch sử là số 8 -> mỗi ngày nó sẽ lệch đi 2 đơn vị

    /// 6 cung xuất hành Lý Thuần Phong (Khổng Minh Lục Diệu) các trạng thái chỉ giờ tốt hay xấu
    private static let lyThuanPhongCung: [(name: String, isGood: Bool)] = [
        ("Đại An", true),
        ("Lưu Niên", false),
        ("Tốc Hỷ", true),
        ("Xích Khẩu", false),
        ("Tiểu Cát", true),
        ("Không Vong", false),
    ]

    /// Hướng Hỷ Thần theo 10 Thiên Can ngày (Giáp -> Quý):
    /// Giáp Kỷ Đông Bắc, Ất Canh Tây Bắc, Bính Tân Tây Nam, Đinh Nhâm Chính Nam, Mậu Quý Đông Nam.
    private static let hyThanByDayCan: [String] = [
        "Đông Bắc",  // 0: Giáp
        "Tây Bắc",   // 1: Ất
        "Tây Nam",   // 2: Bính
        "Chính Nam", // 3: Đinh
        "Đông Nam",  // 4: Mậu
        "Đông Bắc",  // 5: Kỷ
        "Tây Bắc",   // 6: Canh
        "Tây Nam",   // 7: Tân
        "Chính Nam", // 8: Nhâm
        "Đông Nam",  // 9: Quý
    ]

    /// Hướng Tài Thần theo 10 Thiên Can ngày (Giáp -> Quý) theo Hiệp Kỷ Biện Phương Thư.
    private static let taiThanByDayCan: [String] = [
        "Đông Nam",  // 0: Giáp
        "Đông Nam",  // 1: Ất
        "Chính Đông",// 2: Bính
        "Chính Đông",// 3: Đinh
        "Chính Bắc", // 4: Mậu
        "Chính Nam", // 5: Kỷ
        "Tây Nam",   // 6: Canh
        "Tây Nam",   // 7: Tân
        "Chính Tây", // 8: Nhâm
        "Tây Bắc",   // 9: Quý
    ]

    /// Thập Nhị Kiến Trừ (12 Trực) tính theo tương quan Địa Chi ngày và Địa Chi tháng âm lịch.
    private struct TrucDefinition: Sendable {
        let name: String
        let quality: String
        let yi: [String]
        let ji: [String]
    }

    private static let thapNhiKienTru: [TrucDefinition] = [
        .init(
            name: "Kiến",
            quality: "Tốt",
            yi: ["Xuất hành", "Khai trương", "Nhậm chức", "Cưới hỏi"],
            ji: ["Động thổ", "Đào giếng", "Mở kho"]
        ),
        .init(
            name: "Trừ",
            quality: "Tốt",
            yi: ["Cầu an", "Chữa bệnh", "Dọn dẹp", "Cầu phúc"],
            ji: ["Ký kết lớn", "Xuất hành xa", "Cưới hỏi"]
        ),
        .init(
            name: "Mãn",
            quality: "Tốt",
            yi: ["Cầu tài", "Khai trương", "Cúng tế", "Hội họp"],
            ji: ["Kiện tụng", "Động thổ", "Nhậm chức"]
        ),
        .init(
            name: "Bình",
            quality: "Bình",
            yi: ["Giao dịch", "Sửa chữa", "Hội họp", "Di chuyển"],
            ji: ["Động thổ lớn", "Đào móng", "Kiện tụng"]
        ),
        .init(
            name: "Định",
            quality: "Tốt",
            yi: ["Ký kết", "Giao dịch", "Cưới hỏi", "Cầu phúc"],
            ji: ["Kiện tụng", "Xuất hành xa", "Chữa bệnh"]
        ),
        .init(
            name: "Chấp",
            quality: "Bình",
            yi: ["Xây dựng", "Sửa chữa", "Cầu an", "Lập kế hoạch"],
            ji: ["Xuất hành xa", "Dời nhà", "Mở kho"]
        ),
        .init(
            name: "Phá",
            quality: "Xấu",
            yi: ["Phá dỡ cũ", "Chữa bệnh", "Dọn dẹp"],
            ji: ["Khai trương", "Cưới hỏi", "Ký kết", "Cầu tài"]
        ),
        .init(
            name: "Nguy",
            quality: "Xấu",
            yi: ["Cầu an", "Cúng tế", "Tĩnh dưỡng"],
            ji: ["Xuất hành xa", "Động thổ", "Mạo hiểm"]
        ),
        .init(
            name: "Thành",
            quality: "Tốt",
            yi: ["Khai trương", "Cưới hỏi", "Ký kết", "Nhập trạch"],
            ji: ["Kiện tụng", "Tranh chấp"]
        ),
        .init(
            name: "Thu",
            quality: "Bình",
            yi: ["Thu hoạch", "Tích trữ", "Nạp tài", "Giao dịch"],
            ji: ["Khởi công lớn", "An táng", "Xuất hành xa"]
        ),
        .init(
            name: "Khai",
            quality: "Tốt",
            yi: ["Khai trương", "Cầu tài", "Xuất hành", "Nhập trạch"],
            ji: ["An táng", "Kiện tụng", "Động thổ"]
        ),
        .init(
            name: "Bế",
            quality: "Xấu",
            yi: ["Tu bổ", "Tĩnh tâm", "Lập kế hoạch nội bộ"],
            ji: ["Khai trương", "Xuất hành", "Cưới hỏi", "Cầu tài"]
        ),
    ]
    // lấy con giấp của ngày trư con giáp của tháng để tìm dc  phần tử tương ứng và lấy dữ liệu

    private static let ngayHoangDaoStartByLunarMonth: [Int: Int] = [
        1: 0, 7: 0,
        2: 2, 8: 2,
        3: 4, 9: 4,
        4: 6, 10: 6,
        5: 8, 11: 8,
        6: 10, 12: 10
    ]

    private static let twelveDayStars: [(name: String, isHoangDao: Bool)] = [
        ("Thanh Long", true),
        ("Minh Đường", true),
        ("Thiên Hình", false),
        ("Chu Tước", false),
        ("Kim Quỹ", true),
        ("Thiên Đức", true),
        ("Bạch Hổ", false),
        ("Ngọc Đường", true),
        ("Thiên Lao", false),
        ("Huyền Vũ", false),
        ("Tư Mệnh", true),
        ("Câu Trận", false),
    ]

    private static let tietKhi: [String] = [
        "Xuân phân", "Thanh minh", "Cốc vũ", "Lập hạ", "Tiểu mãn", "Mang chủng",
        "Hạ chí", "Tiểu thử", "Đại thử", "Lập thu", "Xử thử", "Bạch lộ",
        "Thu phân", "Hàn lộ", "Sương giáng", "Lập đông", "Tiểu tuyết", "Đại tuyết",
        "Đông chí", "Tiểu hàn", "Đại hàn", "Lập xuân", "Vũ thủy", "Kinh trập"
    ]
// người xưa  ko có dự báo thời tiết họ sử dụng tietkhi de mieu ta thoi tiet voi 4 mua theo lich am
    private static let conGiapEmoji: [String: String] = [
        "Tý": "🐭", "Sửu": "🐮", "Dần": "🐯", "Mão": "🐱",
        "Thìn": "🐉", "Tỵ": "🐍", "Ngọ": "🐴", "Mùi": "🐐",
        "Thân": "🐵", "Dậu": "🐔", "Tuất": "🐶", "Hợi": "🐷"
    ]

    private static let nguHanhByCan: [String: String] = [
        "Giáp": "Mộc", "Ất": "Mộc",
        "Bính": "Hỏa", "Đinh": "Hỏa",
        "Mậu": "Thổ", "Kỷ": "Thổ",
        "Canh": "Kim", "Tân": "Kim",
        "Nhâm": "Thủy", "Quý": "Thủy"
    ]

    /// Bảng 30 cặp Nạp Âm theo thứ tự Lục Thập Hoa Giáp (0 = Giáp Tý/Ất Sửu ... 29 = Nhâm Tuất/Quý Hợi)
    private static let lucThapHoaGiapNapAm: [(name: String, element: String)] = [
        ("Hải Trung Kim", "Kim"),     // 0: Giáp Tý, Ất Sửu
        ("Lư Trung Hỏa", "Hỏa"),      // 1: Bính Dần, Đinh Mão
        ("Đại Lâm Mộc", "Mộc"),       // 2: Mậu Thìn, Kỷ Tỵ
        ("Lộ Bàng Thổ", "Thổ"),       // 3: Canh Ngọ, Tân Mùi
        ("Kiếm Phong Kim", "Kim"),    // 4: Nhâm Thân, Quý Dậu
        ("Sơn Đầu Hỏa", "Hỏa"),       // 5: Giáp Tuất, Ất Hợi
        ("Giản Hạ Thủy", "Thủy"),     // 6: Bính Tý, Đinh Sửu
        ("Thành Đầu Thổ", "Thổ"),     // 7: Mậu Dần, Kỷ Mão
        ("Bạch Lạp Kim", "Kim"),      // 8: Canh Thìn, Tân Tỵ
        ("Dương Liễu Mộc", "Mộc"),    // 9: Nhâm Ngọ, Quý Mùi
        ("Tuyền Trung Thủy", "Thủy"), // 10: Giáp Thân, Ất Dậu
        ("Ốc Thượng Thổ", "Thổ"),     // 11: Bính Tuất, Đinh Hợi
        ("Tích Lịch Hỏa", "Hỏa"),     // 12: Mậu Tý, Kỷ Sửu
        ("Tùng Bách Mộc", "Mộc"),     // 13: Canh Dần, Tân Mão
        ("Trường Lưu Thủy", "Thủy"),  // 14: Nhâm Thìn, Quý Tỵ
        ("Sa Trung Kim", "Kim"),      // 15: Giáp Ngọ, Ất Mùi
        ("Sơn Hạ Hỏa", "Hỏa"),        // 16: Bính Thân, Đinh Dậu
        ("Bình Địa Mộc", "Mộc"),      // 17: Mậu Tuất, Kỷ Hợi
        ("Bích Thượng Thổ", "Thổ"),   // 18: Canh Tý, Tân Sửu
        ("Kim Bạch Kim", "Kim"),      // 19: Nhâm Dần, Quý Mão
        ("Phú Đăng Hỏa", "Hỏa"),      // 20: Giáp Thìn, Ất Tỵ
        ("Thiên Hà Thủy", "Thủy"),    // 21: Bính Ngọ, Đinh Mùi
        ("Đại Trạch Thổ", "Thổ"),     // 22: Mậu Thân, Kỷ Dậu
        ("Thoa Xuyến Kim", "Kim"),    // 23: Canh Tuất, Tân Hợi
        ("Tang Đố Mộc", "Mộc"),       // 24: Nhâm Tý, Quý Sửu
        ("Đại Khê Thủy", "Thủy"),     // 25: Giáp Dần, Ất Mão
        ("Sa Trung Thổ", "Thổ"),      // 26: Bính Thìn, Đinh Tỵ
        ("Thiên Thượng Hỏa", "Hỏa"),  // 27: Mậu Ngọ, Kỷ Mùi
        ("Thạch Lựu Mộc", "Mộc"),     // 28: Canh Thân, Tân Dậu
        ("Đại Hải Thủy", "Thủy"),     // 29: Nhâm Tuất, Quý Hợi
    ]

    private static let nguHanhEmojiMap: [String: String] = [
        "Kim": "🪙", "Mộc": "🌿", "Thủy": "💧", "Hỏa": "🔥", "Thổ": "🪨"
    ]

    // MARK: - Math Helpers

    @inline(__always)
    private static func floorDiv(_ a: Int, _ b: Int) -> Int {
        Int(floor(Double(a) / Double(b)))
    }

    @inline(__always)
    private static func positiveMod(_ value: Int, _ modulus: Int) -> Int {
        ((value % modulus) + modulus) % modulus
    }

    // MARK: - 2. Thuật toán Âm Lịch (Hồ Ngọc Đức)

    public static func jdFromDate(day dd: Int, month mm: Int, year yy: Int) -> Int {
        let a = floorDiv(14 - mm, 12)
        let y = yy + 4800 - a
        let m = mm + 12 * a - 3
        var jd = dd + floorDiv(153 * m + 2, 5) + 365 * y + floorDiv(y, 4) - floorDiv(y, 100) + floorDiv(y, 400) - 32045
        if jd < 2299161 {
            jd = dd + floorDiv(153 * m + 2, 5) + 365 * y + floorDiv(y, 4) - 32083
        }
        return jd
    }

    public static func newMoon(_ k: Int) -> Double {
        let kDouble = Double(k)
        let T = kDouble / 1236.85
        let T2 = T * T
        let T3 = T2 * T
        let dr = Double.pi / 180.0
        var jd1 = 2415020.75933 + 29.53058868 * kDouble + 0.0001178 * T2 - 0.000000155 * T3
        jd1 += 0.00033 * sin((166.56 + 132.87 * T - 0.009173 * T2) * dr)
        let M = 359.2242 + 29.10535608 * kDouble - 0.0000333 * T2 - 0.00000347 * T3
        let Mpr = 306.0253 + 385.81691806 * kDouble + 0.0107306 * T2 + 0.00001236 * T3
        let F = 21.2964 + 390.67050646 * kDouble - 0.0016528 * T2 - 0.00000239 * T3
        var c1 = (0.1734 - 0.000393 * T) * sin(M * dr) + 0.0021 * sin(2.0 * dr * M)
        c1 = c1 - 0.4068 * sin(Mpr * dr) + 0.0161 * sin(dr * 2.0 * Mpr)
        c1 = c1 - 0.0004 * sin(dr * 3.0 * Mpr)
        c1 = c1 + 0.0104 * sin(dr * 2.0 * F) - 0.0051 * sin(dr * (M + Mpr))
        c1 = c1 - 0.0074 * sin(dr * (M - Mpr)) + 0.0004 * sin(dr * (2.0 * F + M))
        c1 = c1 - 0.0004 * sin(dr * (2.0 * F - M)) - 0.0006 * sin(dr * (2.0 * F + Mpr))
        c1 = c1 + 0.0010 * sin(dr * (2.0 * F - Mpr)) + 0.0005 * sin(dr * (2.0 * Mpr + M))
        let deltat: Double
        if T < -11.0 {
            deltat = 0.001 + 0.000839 * T + 0.0002261 * T2 - 0.00000845 * T3 - 0.000000081 * T * T3
        } else {
            deltat = -0.000278 + 0.000265 * T + 0.000262 * T2
        }
        return jd1 + c1 - deltat
    }

    public static func sunLongitude(_ jdn: Double) -> Double {
        let T = (jdn - 2451545.0) / 36525.0
        let T2 = T * T
        let dr = Double.pi / 180.0
        let M = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2
        let L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2
        var DL = (1.9146 - 0.004817 * T - 0.000014 * T2) * sin(dr * M)
        DL = DL + (0.019993 - 0.000101 * T) * sin(dr * 2.0 * M) + 0.00029 * sin(dr * 3.0 * M)
        var L = (L0 + DL) * dr
        L = L - Double.pi * 2.0 * floor(L / (Double.pi * 2.0))
        return L
    }

    public static func getSunLongitude(dayNumber: Int, timeZone: Double = defaultTimeZoneOffset) -> Int {
        Int(floor(sunLongitude(Double(dayNumber) - 0.5 - timeZone / 24.0) / Double.pi * 6.0))
    }

    public static func getNewMoonDay(k: Int, timeZone: Double = defaultTimeZoneOffset) -> Int {
        Int(floor(newMoon(k) + 0.5 + timeZone / 24.0))
    }

    public static func getLunarMonth11(year yy: Int, timeZone: Double = defaultTimeZoneOffset) -> Int {
        let off = jdFromDate(day: 31, month: 12, year: yy) - 2415021
        let k = Int(floor(Double(off) / 29.530588853))
        var nm = getNewMoonDay(k: k, timeZone: timeZone)
        let sunLong = getSunLongitude(dayNumber: nm, timeZone: timeZone)
        if sunLong >= 9 {
            nm = getNewMoonDay(k: k - 1, timeZone: timeZone)
        }
        return nm
    }

    public static func getLeapMonthOffset(a11: Int, timeZone: Double = defaultTimeZoneOffset) -> Int {
        let k = Int(floor((Double(a11) - 2415021.076998695) / 29.530588853 + 0.5))
        var last = 0
        var i = 1
        var arc = getSunLongitude(dayNumber: getNewMoonDay(k: k + i, timeZone: timeZone), timeZone: timeZone)
        repeat {
            last = arc
            i += 1
            arc = getSunLongitude(dayNumber: getNewMoonDay(k: k + i, timeZone: timeZone), timeZone: timeZone)
        } while arc != last && i < 14
        return i - 1
    }

    public static func solarToLunar(
        day dd: Int,
        month mm: Int,
        year yy: Int,
        timeZone: Double = defaultTimeZoneOffset
    ) -> LunarDate {
        let dayNumber = jdFromDate(day: dd, month: mm, year: yy)
        let k = Int(floor((Double(dayNumber) - 2415021.076998695) / 29.530588853))
        var monthStart = getNewMoonDay(k: k + 1, timeZone: timeZone)
        if monthStart > dayNumber {
            monthStart = getNewMoonDay(k: k, timeZone: timeZone)
        }
        var a11 = getLunarMonth11(year: yy, timeZone: timeZone)
        var b11 = a11
        var lunarYear: Int
        if a11 >= monthStart {
            lunarYear = yy
            a11 = getLunarMonth11(year: yy - 1, timeZone: timeZone)
        } else {
            lunarYear = yy + 1
            b11 = getLunarMonth11(year: yy + 1, timeZone: timeZone)
        }
        let lunarDay = dayNumber - monthStart + 1
        let diff = floorDiv(monthStart - a11, 29)
        var lunarLeap = false
        var lunarMonth = diff + 11
        if b11 - a11 > 365 {
            let leapMonthDiff = getLeapMonthOffset(a11: a11, timeZone: timeZone)
            if diff >= leapMonthDiff {
                lunarMonth = diff + 10
                if diff == leapMonthDiff {
                    lunarLeap = true
                }
            }
        }
        if lunarMonth > 12 {
            lunarMonth -= 12
        }
        if lunarMonth >= 11 && diff < 4 {
            lunarYear -= 1
        }
        return LunarDate(day: lunarDay, month: lunarMonth, year: lunarYear, leap: lunarLeap)
    }

    public static func solarToLunar(
        date: Date,
        calendar: Calendar = defaultCalendar,
        timeZone: Double = defaultTimeZoneOffset
    ) -> LunarDate {
        let comps = calendar.dateComponents([.day, .month, .year], from: date)
        return solarToLunar(
            day: comps.day ?? 1,
            month: comps.month ?? 1,
            year: comps.year ?? 2026,
            timeZone: timeZone
        )
    }

    // MARK: - 3. Can Chi, Con Giáp & Ngũ Hành

    public static func getCanChiYear(_ lunarYear: Int) -> String {
        let canIdx = positiveMod(lunarYear - 4, 10)
        let chiIdx = positiveMod(lunarYear - 4, 12)
        return "\(thienCan[canIdx]) \(diaChi[chiIdx])"
    }

    public static func getCanChiMonth(lunarMonth: Int, lunarYear: Int) -> String {
        let yearCanIdx = positiveMod(lunarYear - 4, 10)
        let monthCanStart = positiveMod(yearCanIdx * 2 + 2, 10)
        let canIdx = positiveMod(monthCanStart + lunarMonth - 1, 10)
        let chiIdx = positiveMod(lunarMonth + 1, 12) // Tháng Giêng = Dần (index 2)
        return "\(thienCan[canIdx]) \(diaChi[chiIdx])"
    }

    public static func getCanChiDay(day dd: Int, month mm: Int, year yy: Int) -> String {
        let jd = jdFromDate(day: dd, month: mm, year: yy)
        let canIdx = positiveMod(jd + 9, 10)
        let chiIdx = positiveMod(jd + 1, 12)
        return "\(thienCan[canIdx]) \(diaChi[chiIdx])"
    }

    public static func getDayThienCan(day dd: Int, month mm: Int, year yy: Int) -> Int {
        let jd = jdFromDate(day: dd, month: mm, year: yy)
        return positiveMod(jd + 9, 10)
    }

    public static func getDayDiaChi(day dd: Int, month mm: Int, year yy: Int) -> Int {
        let jd = jdFromDate(day: dd, month: mm, year: yy)
        return positiveMod(jd + 1, 12)
    }

    /// Chỉ số ngày trong chu kỳ Lục Thập Hoa Giáp (0 = Giáp Tý ... 59 = Quý Hợi).
    public static func getDaySexagenaryIndex(day dd: Int, month mm: Int, year yy: Int) -> Int {
        let jd = jdFromDate(day: dd, month: mm, year: yy)
        return positiveMod(jd + 49, 60)
    }

    /// Tính Can Chi của giờ theo khẩu quyết Ngũ Thử Độn:
    /// Giáp Kỷ hoàn gia Giáp, Ất Canh Bính tác sơ, Bính Tân tầm Mậu Tý, Đinh Nhâm Canh Tý cư, Mậu Quý hà phương覓, Nhâm Tý thị chân đồ.
    public static func getCanChiHour(hourChiIdx: Int, dayCanIdx: Int) -> String {
        let normalizedChi = positiveMod(hourChiIdx, 12)
        let normalizedDayCan = positiveMod(dayCanIdx, 10)
        let hourCanStart = positiveMod((normalizedDayCan % 5) * 2, 10)
        let hourCanIdx = positiveMod(hourCanStart + normalizedChi, 10)
        return "\(thienCan[hourCanIdx]) \(diaChi[normalizedChi])"
    }

    /// Trích xuất Năm sinh Âm lịch từ chuỗi ngày sinh Dương lịch (`YYYY-MM-DD`, `DD/MM/YYYY` hoặc `YYYY`).
    /// Nếu có đủ ngày-tháng-năm Dương lịch, tự động đổi sang Âm lịch để người sinh tháng 1-2 trước Tết nhận đúng tuổi & mệnh năm Âm lịch.
    public static func extractBirthYear(from birthDateString: String?) -> Int {
        guard let raw = birthDateString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            return defaultFallbackBirthYear
        }

        // Trường hợp 1: Định dạng chuẩn ISO "YYYY-MM-DD..."
        let datePrefix = String(raw.prefix(10))
        let dashParts = datePrefix.split(separator: "-")
        if dashParts.count == 3,
           let year = Int(dashParts[0]), year > 1800, year < 2200,
           let month = Int(dashParts[1]), (1...12).contains(month),
           let day = Int(dashParts[2]), (1...31).contains(day) {
            return solarToLunar(day: day, month: month, year: year).year
        }

        // Trường hợp 2: Định dạng "DD/MM/YYYY"
        let slashParts = raw.split(separator: "/")
        if slashParts.count == 3,
           let day = Int(slashParts[0]), (1...31).contains(day),
           let month = Int(slashParts[1]), (1...12).contains(month),
           let year = Int(slashParts[2].prefix(4)), year > 1800, year < 2200 {
            return solarToLunar(day: day, month: month, year: year).year
        }

        // Trường hợp 3: Chỉ truyền 4 chữ số năm ("1998")
        let prefixYear = String(raw.prefix(4))
        if prefixYear.count == 4, let year = Int(prefixYear), year > 1800, year < 2200 {
            return year
        }
        return defaultFallbackBirthYear
    }

    public static func getZodiac(birthYear: Int) -> String {
        let idx = positiveMod(birthYear - 4, 12)
        return diaChi[idx]
    }

    public static func getZodiacEmoji(_ zodiac: String) -> String {
        conGiapEmoji[zodiac] ?? "🔮"
    }

    public static func getThienCanYear(_ year: Int) -> String {
        let idx = positiveMod(year - 4, 10)
        return thienCan[idx]
    }

    /// Tra cứu Ngũ Hành Nạp Âm 60 Hoa Giáp theo năm sinh (trả về tên Nạp Âm và hành Kim/Mộc/Thủy/Hỏa/Thổ).
    public static func getNapAm(birthYear: Int) -> (name: String, element: String) {
        let sexagenaryIdx = positiveMod(birthYear - 4, 60)
        let pairIdx = sexagenaryIdx / 2
        return lucThapHoaGiapNapAm[pairIdx]
    }

    public static func getNapAmYear(birthYear: Int) -> String {
        getNapAm(birthYear: birthYear).name
    }

    /// Trả về hành Nạp Âm chuẩn theo năm sinh (ví dụ: 1998 Mậu Dần -> Thành Đầu Thổ -> "Thổ").
    public static func getNguHanh(birthYear: Int) -> String {
        getNapAm(birthYear: birthYear).element
    }

    /// Trả về Ngũ Hành của riêng Thiên Can năm sinh (Giáp/Ất -> Mộc, Bính/Đinh -> Hỏa...).
    public static func getThienCanNguHanh(birthYear: Int) -> String {
        let can = getThienCanYear(birthYear)
        return nguHanhByCan[can] ?? ""
    }

    public static func getNguHanhEmoji(_ nguHanh: String) -> String {
        nguHanhEmojiMap[nguHanh] ?? "✨"
    }

    // MARK: - 4. Giờ Hoàng Đạo / Hắc Đạo & Giờ Xuất Hành Đại Cát

    /// Tính cung xuất hành Lý Thuần Phong (Khổng Minh Lục Diệu) theo ngày âm, tháng âm và chỉ số giờ (0 = Tý ... 11 = Hợi).
    public static func getLyThuanPhongHour(
        lunarDay: Int,
        lunarMonth: Int,
        hourChiIdx: Int
    ) -> (name: String, isGood: Bool) {
        let idx = positiveMod(lunarMonth + lunarDay + hourChiIdx - 2, 6)
        return lyThuanPhongCung[idx]
    }

    public static func getHoangDaoHours(
        day dd: Int,
        month mm: Int,
        year yy: Int,
        zodiac: String? = nil
    ) -> [LunarHourInfo] {
        let lunar = solarToLunar(day: dd, month: mm, year: yy)
        let dayCanIdx = getDayThienCan(day: dd, month: mm, year: yy)
        let dayChiIdx = getDayDiaChi(day: dd, month: mm, year: yy)
        let thanhLongStart = thanhLongStartHourByDayChi[dayChiIdx] ?? 0

        let userClashHour: String? = {
            guard let zodiac, !zodiac.isEmpty else { return nil }
            return tuHanhXung[zodiac]
        }()
        let dayClashHour = tuHanhXung[diaChi[dayChiIdx]]

        return gioInfo.enumerated().map { idx, gio in
            let starOffset = positiveMod(idx - thanhLongStart, 12)
            let star = twelveDayStars[starOffset]
            let isClash = (userClashHour == gio.name)
            let isDayClash = (dayClashHour == gio.name)
            let canChi = getCanChiHour(hourChiIdx: idx, dayCanIdx: dayCanIdx)
            let ltp = getLyThuanPhongHour(
                lunarDay: lunar.day,
                lunarMonth: lunar.month,
                hourChiIdx: idx
            )

            return LunarHourInfo(
                name: gio.name,
                canChi: canChi,
                range: gio.range,
                startHour: gio.startHour,
                isHoangDao: star.isHoangDao,
                isClash: isClash,
                isDayClash: isDayClash,
                label: star.name,
                lyThuanPhong: ltp.name,
                isLyThuanPhongGood: ltp.isGood
            )
        }
    }

    public static func getBestDepartureHour(
        day dd: Int,
        month mm: Int,
        year yy: Int,
        zodiac: String,
        currentHour: Int
    ) -> LunarHourInfo? {
        let hours = getHoangDaoHours(day: dd, month: mm, year: yy, zodiac: zodiac)
        // Sắp xếp theo thứ tự thời gian thực trong ngày (01h Sửu -> 21h Hợi -> 23h Tý)
        // để tránh lỗi Giờ Tý (startHour = 23, index 0) bị chọn nhầm vào buổi sáng/chiều.
        let chronologicalHours = hours.sorted { $0.startHour < $1.startHour }
        let baseCandidates = chronologicalHours.filter { $0.isHoangDao && !$0.isClash }
        guard !baseCandidates.isEmpty else { return nil }

        let tier1 = baseCandidates.filter { !$0.isDayClash && $0.isLyThuanPhongGood }
        let tier2 = baseCandidates.filter { !$0.isDayClash }
        let tiers = [tier1, tier2, baseCandidates]

        for tier in tiers where !tier.isEmpty {
            if let upcoming = tier.first(where: { $0.startHour >= currentHour }) {
                return upcoming
            }
        }

        // Nếu mọi giờ tốt trong ngày đều đã qua, trả về giờ tốt nhất đầu tiên của ngày
        for tier in tiers where !tier.isEmpty {
            return tier.first
        }
        return baseCandidates.first
    }

    // MARK: - 5. Việc Nên / Kiêng, Ngày Kỵ & Hướng Xuất Hành

    /// Tính Trực của ngày theo Thập Nhị Kiến Trừ (Kiến, Trừ, Mãn, Bình, Định, Chấp, Phá, Nguy, Thành, Thu, Khai, Bế)
    /// và trả về danh sách việc nên làm (`yi`) / kiêng kỵ (`ji`).
    public static func getDayActivities(day dd: Int, month mm: Int, year yy: Int) -> DayActivities {
        let lunar = solarToLunar(day: dd, month: mm, year: yy)
        let dayChiIdx = getDayDiaChi(day: dd, month: mm, year: yy)
        let monthChiIdx = positiveMod(lunar.month + 1, 12) // Tháng Giêng = Dần (2)
        let trucIdx = positiveMod(dayChiIdx - monthChiIdx, 12)
        let truc = thapNhiKienTru[trucIdx]
        return DayActivities(
            trucName: truc.name,
            trucQuality: truc.quality,
            yi: truc.yi,
            ji: truc.ji
        )
    }

    public static func isNguyetKy(lunarDay: Int) -> Bool {
        lunarDay == 5 || lunarDay == 14 || lunarDay == 23
    }

    public static func isTamNuong(lunarDay: Int) -> Bool {
        switch lunarDay {
        case 3, 7, 13, 18, 22, 27:
            return true
        default:
            return false
        }
    }

    public static func getDayWarning(lunarDay: Int) -> String? {
        if isNguyetKy(lunarDay: lunarDay) {
            return "⚠️ Ngày Nguyệt Kỵ — nên hạn chế khởi sự việc lớn"
        }
        if isTamNuong(lunarDay: lunarDay) {
            return "⚠️ Ngày Tam Nương — không nên cưới hỏi, khai trương"
        }
        return nil
    }

    /// Tính phương vị Hạc Thần (hung thần cần tránh khi xuất hành) theo chu kỳ 60 ngày Lục Thập Hoa Giáp.
    /// Trả về `nil` vào 16 ngày Hạc Thần tại thiên (từ Quý Tỵ đến Mậu Thân).
    public static func getHacThanDirection(day dd: Int, month mm: Int, year yy: Int) -> String? {
        let sexagenaryIdx = getDaySexagenaryIndex(day: dd, month: mm, year: yy)
        switch sexagenaryIdx {
        case 29...44: // Quý Tỵ (29) -> Mậu Thân (44): 16 ngày Hạc Thần lên trời
            return nil
        case 45...50: // Kỷ Dậu (45) -> Giáp Dần (50): 6 ngày ở Đông Bắc
            return "Đông Bắc"
        case 51...55: // Ất Mão (51) -> Kỷ Mùi (55): 5 ngày ở Chính Đông
            return "Chính Đông"
        case 56...59, 0...1: // Canh Thân (56) -> Ất Sửu (1): 6 ngày ở Đông Nam
            return "Đông Nam"
        case 2...6:   // Bính Dần (2) -> Canh Ngọ (6): 5 ngày ở Chính Nam
            return "Chính Nam"
        case 7...12:  // Tân Mùi (7) -> Bính Tý (12): 6 ngày ở Tây Nam
            return "Tây Nam"
        case 13...17: // Đinh Sửu (13) -> Tân Tỵ (17): 5 ngày ở Chính Tây
            return "Chính Tây"
        case 18...23: // Nhâm Ngọ (18) -> Đinh Hợi (23): 6 ngày ở Tây Bắc
            return "Tây Bắc"
        case 24...28: // Mậu Tý (24) -> Nhâm Thìn (28): 5 ngày ở Chính Bắc
            return "Chính Bắc"
        default:
            return nil
        }
    }

    /// Tính hướng xuất hành chuẩn theo Thiên Can của ngày (Hỷ Thần & Tài Thần) và Can Chi 60 ngày (Hạc Thần).
    public static func getDayDirection(day dd: Int, month mm: Int, year yy: Int) -> DayDirection {
        let dayCanIdx = getDayThienCan(day: dd, month: mm, year: yy)
        let hyThan = hyThanByDayCan[dayCanIdx]
        let taiThan = taiThanByDayCan[dayCanIdx]
        let hacThan = getHacThanDirection(day: dd, month: mm, year: yy)

        let summaryDirection: String
        if hyThan == taiThan {
            summaryDirection = hyThan
        } else {
            summaryDirection = "\(hyThan) (Hỷ) · \(taiThan) (Tài)"
        }

        return DayDirection(
            huong: summaryDirection,
            than: "Hỷ Thần & Tài Thần",
            hyThan: hyThan,
            taiThan: taiThan,
            hacThan: hacThan
        )
    }

    // MARK: - 6. Sao Hoàng/Hắc Đạo Ngày, 24 Tiết Khí & Tháng Đủ/Thiếu

    public static func getDayHoangDaoStatus(
        day dd: Int,
        month mm: Int,
        year yy: Int,
        lunarMonth: Int
    ) -> DayHoangDaoStatus {
        let dayChiIdx = getDayDiaChi(day: dd, month: mm, year: yy)
        let normalizedMonth = positiveMod(lunarMonth - 1, 12) + 1
        let startOffset = ngayHoangDaoStartByLunarMonth[normalizedMonth] ?? 0
        let relOffset = positiveMod(dayChiIdx - startOffset, 12)
        let sao = twelveDayStars[relOffset]
        let label = sao.isHoangDao
            ? "Ngày Hoàng đạo (\(sao.name))"
            : "Ngày Hắc đạo (\(sao.name))"
        return DayHoangDaoStatus(isHoangDao: sao.isHoangDao, label: label)
    }

    public static func getSolarTerm(day dd: Int, month mm: Int, year yy: Int) -> String {
        let jdn = jdFromDate(day: dd, month: mm, year: yy)
        let rad = sunLongitude(Double(jdn) - 0.5 - defaultTimeZoneOffset / 24.0)
        var deg = (rad * 180.0 / Double.pi).truncatingRemainder(dividingBy: 360.0)
        if deg < 0 {
            deg += 360.0
        }
        let idx = positiveMod(Int(floor(deg / 15.0)), 24)
        return tietKhi[idx]
    }

    public static func isLunarMonthFull(
        day dd: Int,
        month mm: Int,
        year yy: Int,
        lunarMonth: Int,
        lunarYear: Int
    ) -> Bool {
        let dayNumber = jdFromDate(day: dd, month: mm, year: yy)
        let k = Int(floor((Double(dayNumber) - 2415021.076998695) / 29.530588853))
        let nm1 = getNewMoonDay(k: k, timeZone: defaultTimeZoneOffset)
        let nm2 = getNewMoonDay(k: k + 1, timeZone: defaultTimeZoneOffset)
        let nm3 = getNewMoonDay(k: k + 2, timeZone: defaultTimeZoneOffset)

        if dayNumber >= nm2 {
            return (nm3 - nm2) >= 30
        }
        return (nm2 - nm1) >= 30
    }

    // MARK: - 7. Định dạng Chuỗi & Lịch Tuần / Tháng

    public static func formatLunarDate(_ lunar: LunarDate) -> String {
        let leapStr = lunar.leap ? " (nhuận)" : ""
        return "Ngày \(lunar.day) tháng \(lunar.month)\(leapStr) năm \(getCanChiYear(lunar.year))"
    }

    public static func getLunarMonthNameVi(_ lunarMonth: Int) -> String {
        guard (1...12).contains(lunarMonth) else { return "\(lunarMonth)" }
        return lunarMonthsVi[lunarMonth - 1]
    }

    public static func formatHeroLunarText(_ lunar: LunarDate) -> String {
        "\(lunar.day) tháng \(getLunarMonthNameVi(lunar.month)) · Âm lịch"
    }

    public static func getMonthVi(_ month: Int) -> String {
        guard (1...12).contains(month) else { return "Tháng \(month)" }
        return solarMonthsVi[month - 1]
    }

    public static func getMonthEn(_ month: Int) -> String {
        guard (1...12).contains(month) else { return "" }
        return solarMonthsEn[month - 1]
    }

    public static func getDayOfWeekVi(_ date: Date, calendar: Calendar = defaultCalendar) -> String {
        let weekday = calendar.component(.weekday, from: date) // 1 = CN ... 7 = T7
        let idx = positiveMod(weekday - 1, 7)
        return weekdaysViSundayFirst[idx]
    }

    public static func getDayOfWeekEn(_ date: Date, calendar: Calendar = defaultCalendar) -> String {
        let weekday = calendar.component(.weekday, from: date) // 1 = CN ... 7 = T7
        let idx = positiveMod(weekday - 1, 7)
        return weekdaysEnSundayFirst[idx]
    }

    public static func getWeekInfo(
        for currentDate: Date,
        calendar: Calendar = defaultCalendar
    ) -> CalendarWeekInfo {
        let comps = calendar.dateComponents([.day, .month, .year, .weekday], from: currentDate)
        let dd = comps.day ?? 1
        let mm = comps.month ?? 1
        let yy = comps.year ?? 2026
        // JS getDay(): 0 = Sunday .. 6 = Saturday; Calendar weekday: 1 = Sunday .. 7 = Saturday
        let jsDay = positiveMod((comps.weekday ?? 1) - 1, 7)
        let dayNr = positiveMod(jsDay + 6, 7) // Monday = 0 ... Sunday = 6

        // Tìm Thứ Năm gần nhất theo chuẩn ISO-8601 (khớp 100% logic lunarService.ts:517-525)
        let thursdayDate = calendar.date(byAdding: .day, value: -dayNr + 3, to: currentDate) ?? currentDate
        let thursdayComps = calendar.dateComponents([.day, .month, .year], from: thursdayDate)
        let thursdayYear = thursdayComps.year ?? yy
        let thursdayJD = jdFromDate(
            day: thursdayComps.day ?? dd,
            month: thursdayComps.month ?? mm,
            year: thursdayYear
        )

        let jan1JD = jdFromDate(day: 1, month: 1, year: thursdayYear)
        // Công thức thứ trong tuần từ JDN: (JDN + 1) % 7 -> 0 = CN, 1 = T2, ..., 4 = T5
        let jan1JsDay = positiveMod(jan1JD + 1, 7)
        let firstThursdayOffset = jan1JsDay == 4 ? 0 : positiveMod(4 - jan1JsDay, 7)
        let firstThursdayJD = jan1JD + firstThursdayOffset
        let weekNumber = 1 + Int(ceil(Double(thursdayJD - firstThursdayJD) / 7.0))

        // Tìm ngày Thứ Hai của tuần chứa currentDate
        let diffToMonday = jsDay == 0 ? -6 : 1 - jsDay
        let mondayDate = calendar.date(byAdding: .day, value: diffToMonday, to: currentDate) ?? currentDate

        var days: [CalendarDayItem] = []
        days.reserveCapacity(7)
        for i in 0..<7 {
            let itemDate = calendar.date(byAdding: .day, value: i, to: mondayDate) ?? mondayDate
            let itemComps = calendar.dateComponents([.day, .month, .year], from: itemDate)
            let itemDay = itemComps.day ?? 1
            let isCurrentDay = (itemDay == dd)
                && ((itemComps.month ?? 0) == mm)
                && ((itemComps.year ?? 0) == yy)
            days.append(
                CalendarDayItem(
                    date: itemDate,
                    dayNumber: itemDay,
                    dayOfWeekVi: weekdaysViMondayFirst[i],
                    dayOfWeekShort: weekdaysShortViMondayFirst[i],
                    isCurrentDay: isCurrentDay
                )
            )
        }

        return CalendarWeekInfo(weekNumber: weekNumber, days: days)
    }

    /// Dịch chuyển ngày theo đơn vị `.day` hoặc `.month` (tự động kẹp ngày cuối tháng như `CalendarScreen.tsx:28-39`).
    public static func moveDate(
        _ value: Date,
        amount: Int,
        unit: CalendarDateUnit,
        calendar: Calendar = defaultCalendar
    ) -> Date {
        switch unit {
        case .day:
            return calendar.date(byAdding: .day, value: amount, to: value) ?? value
        case .month:
            let comps = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second, .nanosecond],
                from: value
            )
            var firstOfMonthComps = DateComponents()
            firstOfMonthComps.year = comps.year
            firstOfMonthComps.month = comps.month
            firstOfMonthComps.day = 1
            firstOfMonthComps.hour = comps.hour
            firstOfMonthComps.minute = comps.minute
            firstOfMonthComps.second = comps.second
            firstOfMonthComps.nanosecond = comps.nanosecond

            guard let currentMonthStart = calendar.date(from: firstOfMonthComps),
                  let targetMonthStart = calendar.date(byAdding: .month, value: amount, to: currentMonthStart),
                  let dayRange = calendar.range(of: .day, in: .month, for: targetMonthStart) else {
                return calendar.date(byAdding: .month, value: amount, to: value) ?? value
            }

            let clampedDay = min(comps.day ?? 1, dayRange.count)
            var targetComps = calendar.dateComponents(
                [.year, .month, .hour, .minute, .second, .nanosecond],
                from: targetMonthStart
            )
            targetComps.day = clampedDay
            return calendar.date(from: targetComps) ?? targetMonthStart
        }
    }

    /// Tạo lưới 42 ngày (6 tuần x 7 cột, bắt đầu từ Thứ Hai) cho Month Picker Modal (`CalendarScreen.tsx:65-68`).
    public static func getMonthPickerDays(
        for pickerDate: Date,
        calendar: Calendar = defaultCalendar
    ) -> [Date] {
        let comps = calendar.dateComponents([.year, .month], from: pickerDate)
        var firstDayComps = DateComponents()
        firstDayComps.year = comps.year
        firstDayComps.month = comps.month
        firstDayComps.day = 1

        guard let firstOfMonth = calendar.date(from: firstDayComps) else {
            return []
        }

        let weekday = calendar.component(.weekday, from: firstOfMonth) // 1 = CN ... 7 = T7
        let jsDay = positiveMod(weekday - 1, 7)
        let firstDayOffset = positiveMod(jsDay + 6, 7) // Monday = 0 ... Sunday = 6

        return (0..<42).compactMap { index in
            calendar.date(byAdding: .day, value: index - firstDayOffset, to: firstOfMonth)
        }
    }

    // MARK: - 8. Snapshot Tổng Hợp cho Màn hình Calendar

    public static func makeDaySnapshot(
        for date: Date,
        birthDateString: String? = nil,
        currentHour: Int? = nil,
        calendar: Calendar = defaultCalendar,
        timeZone: Double = defaultTimeZoneOffset
    ) -> LunarDaySnapshot {
        let comps = calendar.dateComponents([.day, .month, .year, .hour], from: date)
        let day = comps.day ?? 1
        let month = comps.month ?? 1
        let year = comps.year ?? 2026
        let resolvedHour = currentHour ?? (comps.hour ?? 0)

        let birthYear = extractBirthYear(from: birthDateString)
        let zodiac = getZodiac(birthYear: birthYear)
        let zodiacEmoji = getZodiacEmoji(zodiac)
        let napAm = getNapAm(birthYear: birthYear)
        let nguHanh = napAm.element
        let nguHanhEmoji = getNguHanhEmoji(nguHanh)

        let lunar = solarToLunar(day: day, month: month, year: year, timeZone: timeZone)
        let lunarMonthName = getLunarMonthNameVi(lunar.month)
        let canChiDay = getCanChiDay(day: day, month: mmOrMonth(month), year: year)
        let canChiMonth = getCanChiMonth(lunarMonth: lunar.month, lunarYear: lunar.year)
        let canChiYear = getCanChiYear(lunar.year)

        let dayHoangDao = getDayHoangDaoStatus(
            day: day,
            month: month,
            year: year,
            lunarMonth: lunar.month
        )
        let solarTerm = getSolarTerm(day: day, month: month, year: year)
        let hours = getHoangDaoHours(day: day, month: month, year: year, zodiac: zodiac)
        let bestHour = getBestDepartureHour(
            day: day,
            month: month,
            year: year,
            zodiac: zodiac,
            currentHour: resolvedHour
        )
        let direction = getDayDirection(day: day, month: month, year: year)
        let activities = getDayActivities(day: day, month: month, year: year)
        let warning = getDayWarning(lunarDay: lunar.day)
        let weekInfo = getWeekInfo(for: date, calendar: calendar)
        let monthFull = isLunarMonthFull(
            day: day,
            month: month,
            year: year,
            lunarMonth: lunar.month,
            lunarYear: lunar.year
        )

        return LunarDaySnapshot(
            solarDate: date,
            day: day,
            month: month,
            year: year,
            weekdayVi: getDayOfWeekVi(date, calendar: calendar),
            weekdayEn: getDayOfWeekEn(date, calendar: calendar),
            monthVi: getMonthVi(month),
            monthEn: getMonthEn(month),
            lunarDate: lunar,
            lunarMonthNameVi: lunarMonthName,
            heroLunarText: formatHeroLunarText(lunar),
            formattedLunarDate: formatLunarDate(lunar),
            isLunarMonthFull: monthFull,
            canChiDay: canChiDay,
            canChiMonth: canChiMonth,
            canChiYear: canChiYear,
            dayHoangDaoStatus: dayHoangDao,
            solarTerm: solarTerm,
            hours: hours,
            bestDepartureHour: bestHour,
            direction: direction,
            activities: activities,
            warning: warning,
            weekInfo: weekInfo,
            userBirthYear: birthYear,
            userZodiac: zodiac,
            userZodiacEmoji: zodiacEmoji,
            userNguHanh: nguHanh,
            userNapAm: napAm.name,
            userNguHanhEmoji: nguHanhEmoji
        )
    }

    @inline(__always)
    private static func mmOrMonth(_ month: Int) -> Int { month }
}
