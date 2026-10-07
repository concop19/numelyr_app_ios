import Foundation

/// Catalog bốn kiểu trải bài. Dữ liệu 78 lá được load từ `TarotDeck.json`
/// bởi `TarotEngine`, thay vì được khai báo lặp lại trong mã Swift.
public nonisolated enum TarotCatalog {
    public static let singleSpread = TarotSpread(
        id: .single,
        nameVi: "Trải bài 1 Lá (Thông điệp Trọng Tâm)",
        descVi: "Một thông điệp dẫn lối rõ ràng và tức thời cho thời điểm hiện tại.",
        positions: [
            TarotPosition(
                id: "single-1",
                nameVi: "Thông điệp Trực Giác",
                descVi: "Điều quan trọng nhất vũ trụ muốn bạn lưu tâm lúc này."
            )
        ]
    )

    public static let threeCardSpread = TarotSpread(
        id: .threeCard,
        nameVi: "Trải bài 3 Lá (Quá Khứ · Hiện Tại · Tương Lai)",
        descVi: "Nhìn lại cội nguồn, nhận diện thách thức hiện tại và xu hướng tương lai gần.",
        positions: [
            TarotPosition(
                id: "pos-1",
                nameVi: "Quá Khứ (Gốc rễ)",
                descVi: "Nguyên nhân và ảnh hưởng đã định hình tình thế hiện tại."
            ),
            TarotPosition(
                id: "pos-2",
                nameVi: "Hiện Tại (Thực trạng)",
                descVi: "Năng lượng cốt lõi và bài học bạn đang đối diện."
            ),
            TarotPosition(
                id: "pos-3",
                nameVi: "Tương Lai Gần (Xu hướng)",
                descVi: "Xu hướng phát triển sắp tới nếu tiếp tục hướng đi này."
            )
        ]
    )

    public static let twoOptionsSpread = TarotSpread(
        id: .twoOptions,
        nameVi: "Trải bài 5 Lá (Hai Lựa Chọn A vs B)",
        descVi: "So sánh chi tiết 2 ngã rẽ và định lượng phương án được vũ trụ ủng hộ hơn.",
        positions: [
            TarotPosition(
                id: "opt-1",
                nameVi: "Tình Trạng Nền Tảng",
                descVi: "Bản chất thực sự phía sau câu hỏi phân vân của bạn."
            ),
            TarotPosition(
                id: "opt-2",
                nameVi: "Phương Án A (Tiến trình)",
                descVi: "Trải nghiệm và thử thách trên con đường lựa chọn A."
            ),
            TarotPosition(
                id: "opt-3",
                nameVi: "Phương Án A (Kết quả)",
                descVi: "Xu hướng thành quả nếu bạn chọn phương án A."
            ),
            TarotPosition(
                id: "opt-4",
                nameVi: "Phương Án B (Tiến trình)",
                descVi: "Trải nghiệm và thử thách trên con đường lựa chọn B."
            ),
            TarotPosition(
                id: "opt-5",
                nameVi: "Phương Án B (Kết quả)",
                descVi: "Xu hướng thành quả nếu bạn chọn phương án B."
            )
        ]
    )

    public static let relationshipSpread = TarotSpread(
        id: .relationship,
        nameVi: "Trải bài 5 Lá (Mối Quan Hệ Tình Cảm & Kết Nối)",
        descVi: "Khám phá sự giao thoa năng lượng giữa 2 người, nút thắt và tiềm năng gắn kết.",
        positions: [
            TarotPosition(
                id: "rel-1",
                nameVi: "Năng Lượng Của Bạn",
                descVi: "Tâm thế, cảm xúc và góc nhìn của bạn trong mối quan hệ."
            ),
            TarotPosition(
                id: "rel-2",
                nameVi: "Năng Lượng Phản Chiếu Đối Phương",
                descVi: "Thái độ và năng lượng đối phương phản chiếu tới bạn."
            ),
            TarotPosition(
                id: "rel-3",
                nameVi: "Sợi Dây Kết Nối",
                descVi: "Bản chất mẫu hình tương tác hiện tại giữa hai người."
            ),
            TarotPosition(
                id: "rel-4",
                nameVi: "Nút Thắt Cần Hóa Giải",
                descVi: "Thử thách lớn nhất hoặc điều chưa được giãi bày."
            ),
            TarotPosition(
                id: "rel-5",
                nameVi: "Tiềm Năng Phát Triển",
                descVi: "Tương lai của mối quan hệ nếu cả hai cùng nỗ lực."
            )
        ]
    )

    public static let allSpreads: [TarotSpread] = [
        singleSpread,
        threeCardSpread,
        twoOptionsSpread,
        relationshipSpread
    ]

    public static let spreads: [TarotSpreadID: TarotSpread] = [
        .single: singleSpread,
        .threeCard: threeCardSpread,
        .twoOptions: twoOptionsSpread,
        .relationship: relationshipSpread
    ]

    public static func spread(for id: TarotSpreadID?) -> TarotSpread {
        guard let id, let found = spreads[id] else {
            return singleSpread
        }
        return found
    }

    public static func spread(rawId: String?) -> TarotSpread {
        guard let rawId, let id = TarotSpreadID(rawValue: rawId) else {
            return singleSpread
        }
        return spread(for: id)
    }
}
