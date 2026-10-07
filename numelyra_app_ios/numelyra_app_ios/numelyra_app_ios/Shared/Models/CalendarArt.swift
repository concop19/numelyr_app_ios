import Foundation

public nonisolated enum CalendarSeason: String, CaseIterable, Codable, Equatable, Sendable {
    case spring
    case summer
    case autumn = "autom"
    case winter

    public var nameVi: String {
        switch self {
        case .spring: "MÙA XUÂN"
        case .summer: "MÙA HẠ"
        case .autumn: "MÙA THU"
        case .winter: "MÙA ĐÔNG"
        }
    }

    public var hanCharacter: String {
        switch self {
        case .spring: "春"
        case .summer: "夏"
        case .autumn: "秋"
        case .winter: "冬"
        }
    }

    public var emoji: String {
        switch self {
        case .spring: "🌸"
        case .summer: "☀️"
        case .autumn: "🍁"
        case .winter: "❄️"
        }
    }

    var fallbackAsset: AppAsset {
        switch self {
        case .spring: .calendarSpringFallback
        case .summer: .calendarSummerFallback
        case .autumn: .calendarAutumnFallback
        case .winter: .calendarWinterFallback
        }
    }
}

public nonisolated struct CalendarLiterature: Equatable, Sendable {
    public var id: String
    public var title: String
    public var hanTitle: String?
    public var author: String
    public var period: String?
    public var excerpt: String
    public var fullContent: String?
    public var description: String
    public var location: String?
}

public nonisolated struct CalendarArtItem: Equatable, Sendable {
    public var id: String
    public var season: CalendarSeason
    public var imageURL: URL?
    public var imageIndex: Int
    public var literature: CalendarLiterature

    public var seasonLabel: String {
        "\(season.emoji) \(season.nameVi) • \(season.hanCharacter)"
    }
}
