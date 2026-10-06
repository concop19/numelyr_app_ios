import Foundation

public struct WallpaperItem: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var imageUrl: String
    public var title: String
    public var affirmationVi: String
    public var explanationVi: String
    public var luckyColorsVi: [String]
    public var styleName: String
    public var intentionName: String

    public init(
        id: String = UUID().uuidString,
        imageUrl: String,
        title: String,
        affirmationVi: String,
        explanationVi: String,
        luckyColorsVi: [String] = [],
        styleName: String,
        intentionName: String
    ) {
        self.id = id
        self.imageUrl = imageUrl
        self.title = title
        self.affirmationVi = affirmationVi
        self.explanationVi = explanationVi
        self.luckyColorsVi = luckyColorsVi
        self.styleName = styleName
        self.intentionName = intentionName
    }
}

public struct WallpaperStyleOption: Identifiable, Equatable, Sendable {
    public var id: String
    public var label: String

    public init(id: String, label: String) {
        self.id = id
        self.label = label
    }

    public static let allStyles: [WallpaperStyleOption] = [
        .init(id: "sacred_geometry", label: "Hình học thiêng"),
        .init(id: "luxury_gold_3d", label: "3D ánh hoàng kim"),
        .init(id: "ethereal_minimalist", label: "Thiền tĩnh huyền bí"),
        .init(id: "cosmic_celestial", label: "Vũ trụ cung hoàng đạo"),
        .init(id: "watercolor_nature", label: "Thiên nhiên mộng mơ"),
        .init(id: "minimalist_clean", label: "Tối giản thuần khiết")
    ]
}

public struct WallpaperIntentionOption: Identifiable, Equatable, Sendable {
    public var id: String
    public var label: String

    public init(id: String, label: String) {
        self.id = id
        self.label = label
    }

    public static let allIntentions: [WallpaperIntentionOption] = [
        .init(id: "wealth", label: "Thịnh vượng & Tài lộc"),
        .init(id: "love", label: "Tình duyên & Bình yên"),
        .init(id: "peace", label: "An lạc & Chữa lành"),
        .init(id: "career", label: "Sự nghiệp thăng hoa"),
        .init(id: "protection", label: "Bảo hộ năng lượng"),
        .init(id: "healing", label: "Cân bằng thân tâm trí")
    ]
}
