import Foundation

/// Deterministic 4-season art and literature selection matching
/// `calendarArtConfig.ts` in the React Native application.
public nonisolated enum CalendarArtEngine {
    private static let stride = 17
    public static let defaultBaseURL = URL(string: "https://assets.numelyra.online")!

    public static func item(
        for lunarDate: LunarDate,
        baseURL: URL = defaultBaseURL
    ) -> CalendarArtItem {
        let season = season(for: lunarDate.month)
        let filenames = CalendarImageCatalog.filenames(for: season)
        let dayInSeason = ((lunarDate.month - 1) % 3) * 30
            + lunarDate.day
            + (lunarDate.leap ? 15 : 0)
        let yearOffset = positiveModulo(lunarDate.year * 37, filenames.count)
        let imageIndex = positiveModulo((dayInSeason - 1) * stride + yearOffset, filenames.count)
        let literature = literatureItems[positiveModulo(dayInSeason, literatureItems.count)]
        let imageURL = baseURL
            .appendingPathComponent(season.rawValue, isDirectory: true)
            .appendingPathComponent(filenames[imageIndex])

        return CalendarArtItem(
            id: "\(season.rawValue)-\(imageIndex)",
            season: season,
            imageURL: imageURL,
            imageIndex: imageIndex,
            literature: literature
        )
    }

    private static func season(for lunarMonth: Int) -> CalendarSeason {
        switch lunarMonth {
        case 1...3: .spring
        case 4...6: .summer
        case 7...9: .autumn
        default: .winter
        }
    }

    private static func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        guard divisor > 0 else { return 0 }
        return ((value % divisor) + divisor) % divisor
    }

    private static let literatureItems: [CalendarLiterature] = [
        .init(
            id: "art-nguc-trung-nhat-ky",
            title: "NHẬT KÝ TRONG TÙ",
            hanTitle: "獄中日記",
            author: "CHỦ TỊCH HỒ CHÍ MINH",
            period: "1890 - 1969",
            excerpt: "Thân thể ở trong lao,\nTinh thần ở ngoài lao;\nMuốn nên sự nghiệp lớn,\nTinh thần càng phải cao.",
            fullContent: "Thân tại ngục trung thân bất tự do,\nTinh thần dĩ tại ngục môn ngoại;\nDục thành đại sự nghiệp,\nTinh thần cánh yếu cao.\n\n(Dịch thơ: Thân thể ở trong lao / Tinh thần ở ngoài lao / Muốn nên sự nghiệp lớn / Tinh thần càng phải cao)",
            description: "Nhật ký trong tù là tập thơ chữ Hán gồm 134 bài theo thể Đường luật do Chủ tịch Hồ Chí Minh sáng tác trong thời gian bị giam giữ tại Quảng Tây (1942 - 1943). Tác phẩm được công nhận là Bảo vật Quốc gia.",
            location: "Bảo tàng Lịch sử Quốc gia — Hà Nội"
        ),
        .init(
            id: "art-truyen-kieu",
            title: "ĐOẠN TRƯỜNG TÂN THANH",
            hanTitle: "斷腸新聲",
            author: "ĐẠI THI HÀO NGUYỄN DU",
            period: "1765 - 1820",
            excerpt: "Trăm năm trong cõi người ta,\nChữ tài chữ mệnh khéo là ghét nhau.\nTrải qua một cuộc bể dâu,\nNhững điều trông thấy mà đau đớn lòng.",
            fullContent: "Thiện căn ở tại lòng ta,\nChữ tâm kia mới bằng ba chữ tài.\nLời quê chắp nhặt dông dài,\nMua vui cũng được một vài trống canh.",
            description: "Truyện Kiều là kiệt tác văn học kinh điển của dân tộc Việt Nam, được UNESCO vinh danh danh nhân văn hóa thế giới. Tác phẩm đúc kết triết lý nhân sinh sâu sắc về chữ Tâm và chữ Tài.",
            location: "Di sản Văn hóa Phi vật thể Nhân loại"
        ),
        .init(
            id: "art-nam-quoc-son-ha",
            title: "NAM QUỐC SƠN HÀ",
            hanTitle: "南國山河",
            author: "THÁI ÚY LÝ THƯỜNG KIỆT",
            period: "1019 - 1105",
            excerpt: "Nam quốc sơn hà Nam đế cư,\nTiệt nhiên định phận tại thiên thư.\nNhư hà nghịch lỗ lai xâm phạm,\nNhữ đẳng hành khan thủ bại hư.",
            fullContent: "Sông núi nước Nam vua Nam ở,\nRành rành định phận tại sách trời.\nCớ sao lũ giặc sang xâm phạm,\nChúng bay sẽ bị đánh tơi bời!",
            description: "Bản tuyên ngôn độc lập đầu tiên của nước Việt Nam, vang vọng bên dòng sông Như Nguyệt năm 1077, khẳng định chủ quyền thiêng liêng và ý chí bất khuất của dân tộc.",
            location: "Chiến tuyến sông Như Nguyệt (Bắc Ninh)"
        ),
        .init(
            id: "art-binh-ngo-dai-cao",
            title: "BÌNH NGÔ ĐẠI CÁO",
            hanTitle: "平吳大誥",
            author: "QUÂN SƯ NGUYỄN TRÃI",
            period: "1380 - 1442",
            excerpt: "Việc nhân nghĩa cốt ở yên dân,\nQuân điếu phạt trước lo trừ bạo.\nNhư nước Đại Việt ta từ trước,\nVốn xưng nền văn hiến đã lâu.",
            fullContent: "Đem đại nghĩa để thắng hung tàn,\nLấy chí nhân để thay cường bạo.\n... Xã tắc từ đây vững bền,\nGiang sơn từ đây đổi mới.",
            description: "Áng thiên cổ hùng văn tổng kết cuộc kháng chiến chống quân Minh thắng lợi của nghĩa quân Lam Sơn, khẳng định nền văn hiến và tinh thần nhân đạo sâu sắc của dân tộc.",
            location: "Lam Sơn — Thanh Hóa"
        )
    ]
}
