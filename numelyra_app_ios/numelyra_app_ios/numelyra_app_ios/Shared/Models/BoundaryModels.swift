import Foundation

/// Lossless fallback for backend payloads that are not yet represented by a typed model.
public enum JSONValue: Codable, Equatable, Sendable {
    case object([String: JSONValue])
    case array([JSONValue])
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([JSONValue].self) { self = .array(value) }
        else { self = .object(try container.decode([String: JSONValue].self)) }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .object(value): try container.encode(value)
        case let .array(value): try container.encode(value)
        case let .string(value): try container.encode(value)
        case let .number(value): try container.encode(value)
        case let .bool(value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

// MARK: - Supabase rows and authentication

public struct AccountProfileDTO: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var email: String?
    public var fullName: String?
    public var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, email
        case fullName = "full_name"
        case updatedAt = "updated_at"
    }
}

public struct CloudNumerologyProfileDTO: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var userId: String
    public var name: String
    public var birthDate: String
    public var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case userId = "user_id"
        case birthDate = "birth_date"
        case createdAt = "created_at"
    }
}

public struct NumerologyKnowledgeDTO: Codable, Equatable, Sendable {
    public var indicatorKey: String
    public var numberValue: String
    public var content: String
    public var title: String?

    enum CodingKeys: String, CodingKey {
        case content, title
        case indicatorKey = "indicator_key"
        case numberValue = "number_value"
    }
}

public struct AuthSession: Codable, Equatable, Sendable {
    public var accessToken: String
    public var refreshToken: String
    public var userId: String
    public var userEmail: String?
    public var expiresAt: Date?
}

// MARK: - Location and chat API

public enum PlaceBudget: String, Codable, CaseIterable, Equatable, Sendable {
    case low
    case medium
    case flexible
}

public enum PlaceCompanion: String, Codable, CaseIterable, Equatable, Sendable {
    case solo
    case date
    case friends
    case family
}

public struct PlaceSearchPreferences: Codable, Equatable, Sendable {
    public var maxDistanceKm: Double
    public var budget: PlaceBudget
    public var companion: PlaceCompanion
    public var openNow: Bool
}

public struct PlaceSearchContext: Codable, Equatable, Sendable {
    public var preferences: PlaceSearchPreferences
    public var latitude: Double
    public var longitude: Double

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        preferences = PlaceSearchPreferences(
            maxDistanceKm: try container.decode(Double.self, forKey: .maxDistanceKm),
            budget: try container.decode(PlaceBudget.self, forKey: .budget),
            companion: try container.decode(PlaceCompanion.self, forKey: .companion),
            openNow: try container.decode(Bool.self, forKey: .openNow)
        )
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
    }

    public init(preferences: PlaceSearchPreferences, latitude: Double, longitude: Double) {
        self.preferences = preferences
        self.latitude = latitude
        self.longitude = longitude
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(preferences.maxDistanceKm, forKey: .maxDistanceKm)
        try container.encode(preferences.budget, forKey: .budget)
        try container.encode(preferences.companion, forKey: .companion)
        try container.encode(preferences.openNow, forKey: .openNow)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }

    private enum CodingKeys: String, CodingKey {
        case maxDistanceKm, budget, companion, openNow, latitude, longitude
    }
}

public struct ChatClassifyRequest: Codable, Equatable, Sendable {
    public var message: String
    public var profiles: [UserProfile]
}

public struct ChatClassifyResponse: Codable, Equatable, Sendable {
    public var ok: Bool
    public var data: AgentDecision?
    public var error: String?
}

public struct ChatIndicatorsPayload: Codable, Equatable, Sendable {
    public var profile1: [NumerologyIndicator]
    public var profile2: [NumerologyIndicator]?
}

public struct ChatAgentRequest: Codable, Equatable, Sendable {
    public var message: String
    public var decision: AgentDecision
    public var timeZone: String?
    public var profiles: [UserProfile]
    public var indicators: ChatIndicatorsPayload
    public var tarotCards: [DrawnTarotCard]
    public var colorGuidance: ColorGuidanceContext?
    public var tuViBazi: TuViBaziSynastry?
    public var placeContext: PlaceSearchContext?
}

public struct ChatAgentResponseData: Codable, Equatable, Sendable {
    public var replyText: String
    public var cardPayload: JSONValue?
}

public struct ChatAgentResponse: Codable, Equatable, Sendable {
    public var ok: Bool
    public var data: ChatAgentResponseData?
    public var error: String?
}

// MARK: - Wallpaper API

public struct LuckyWallpaperRequest: Codable, Equatable, Sendable {
    public var fullName: String
    public var birthDate: String
    public var lifePathNumber: Int
    public var destinyNumber: Int
    public var personalYearNumber: Int
    public var personalDayNumber: Int
    public var intentionId: String
    public var styleId: String
    public var deviceType: String
    public var customWish: String
    public var count: Int
}

public struct LocalizedNameDTO: Codable, Equatable, Sendable {
    public var nameVi: String?

    enum CodingKeys: String, CodingKey {
        case nameVi = "name_vi"
    }
}

public struct LuckyWallpaperResponse: Codable, Equatable, Sendable {
    public var success: Bool
    public var imageUrls: [String]?
    public var imageUrl: String?
    public var affirmationVi: String?
    public var explanationVi: String?
    public var luckyColorsVi: [String]?
    public var style: LocalizedNameDTO?
    public var intention: LocalizedNameDTO?
    public var error: String?

    enum CodingKeys: String, CodingKey {
        case success, imageUrls, imageUrl, style, intention, error
        case affirmationVi = "affirmation_vi"
        case explanationVi = "explanation_vi"
        case luckyColorsVi = "luckyColors_vi"
    }
}

// MARK: - Astrology API

/// Siêu dữ liệu chiêm tinh học gửi kèm trong request bốc quẻ lá thăm dân gian.
public nonisolated struct AstroFortuneRequestMetadata: Codable, Equatable, Sendable {
    /// Điểm số căng thẳng / thử thách [0.0 - 1.0] (tính từ tỷ trọng góc Vuông góc và Đối đỉnh).
    public var tensionScore: Double
    /// Điểm số hài hòa / thuận lợi [0.0 - 1.0] (tính từ tỷ trọng góc Tam hợp và Lục hợp).
    public var harmonyScore: Double
    /// Cường độ hội tụ năng lượng [0.0 - 1.0] (tỷ trọng góc Trùng tụ).
    public var conjunctionScore: Double
    /// Tín hiệu năng lượng chủ đạo trong ngày (tension, harmony, conjunction, balanced).
    public var dominantSignal: AstroDominantSignal
    /// Danh sách các nguyên tố và tính chất chiếm ưu thế (ví dụ: ["Lửa", "Tiên phong"]).
    public var dominantElements: [String]
    /// Các điểm nhấn chiêm tinh nổi bật nhất trong ngày (ví dụ: góc chiếu đỉnh, cung Mặt Trời, Mặt Trăng).
    public var highlights: [String]
    public var birthDataPrecision: AstroBirthDataPrecision?
    public var houseSystem: AstroHouseSystem?
    public var ascendantSign: String?
    public var midheavenSign: String?
    public var planetHouses: [String: Int]?
    public var activatedHouses: [ActivatedHouseScore]?
    public var angleHighlights: [String]?

    public init(
        tensionScore: Double,
        harmonyScore: Double,
        conjunctionScore: Double,
        dominantSignal: AstroDominantSignal,
        dominantElements: [String],
        highlights: [String],
        birthDataPrecision: AstroBirthDataPrecision? = nil,
        houseSystem: AstroHouseSystem? = nil,
        ascendantSign: String? = nil,
        midheavenSign: String? = nil,
        planetHouses: [String: Int]? = nil,
        activatedHouses: [ActivatedHouseScore]? = nil,
        angleHighlights: [String]? = nil
    ) {
        self.tensionScore = tensionScore
        self.harmonyScore = harmonyScore
        self.conjunctionScore = conjunctionScore
        self.dominantSignal = dominantSignal
        self.dominantElements = dominantElements
        self.highlights = highlights
        self.birthDataPrecision = birthDataPrecision
        self.houseSystem = houseSystem
        self.ascendantSign = ascendantSign
        self.midheavenSign = midheavenSign
        self.planetHouses = planetHouses
        self.activatedHouses = activatedHouses
        self.angleHighlights = angleHighlights
    }
}

/// Payload request gửi lên backend DeepSeek API để xin quẻ "Lá Thăm Chiêm Tinh Dân Gian".
public nonisolated struct AstroFortuneRequest: Codable, Equatable, Sendable {
    /// Nội dung câu ca dao hoặc thơ lục bát mẫu dùng làm nhịp điệu và cảm hứng cho quẻ.
    public var caDaoSample: String
    /// Thể loại của câu ca dao mẫu (ví dụ: "Dân gian", "Tình cảm gia đình").
    public var caDaoCategory: String
    /// Bản tóm tắt xu thế chiêm tinh ngắn gọn phục vụ xây dựng prompt cho AI.
    public var astroSummary: String
    /// Siêu dữ liệu chiêm tinh chi tiết của ngày hiện tại và bản mệnh.
    public var metadata: AstroFortuneRequestMetadata
    /// Danh sách tối đa 7 lời khuyên gần đây để AI tránh tạo nội dung trùng lặp.
    public var recentAdvice: [String]?
    /// Ngữ cảnh bổ sung của người dùng (tùy chọn).
    public var userContext: String?
}

/// Dữ liệu nội dung lá thăm chiêm tinh dân gian nhận về từ backend.
public nonisolated struct AstroFortuneResponsePayload: Codable, Equatable, Sendable {
    /// Tiêu đề của lá thăm (tùy chọn do AI sinh).
    public var title: String?
    /// Bài thơ 4 câu phán đoán vận thế theo nhịp điệu dân gian.
    public var verse: String
    /// "Gương soi" — phân tích phản chiếu tâm lý và góc nhìn nội tâm.
    public var mirror: String
    /// "Kế sách" — lời khuyên hành động và thái độ ứng xử cụ thể trong ngày.
    public var advice: String
}

/// Envelope response trả về từ backend API cho tính năng bốc quẻ chiêm tinh.
public nonisolated struct AstroFortuneResponse: Codable, Equatable, Sendable {
    /// Cờ trạng thái gọi API thành công hay không.
    public var success: Bool
    /// Dữ liệu quẻ thăm chi tiết nếu thành công.
    public var fortune: AstroFortuneResponsePayload?
    /// Thông báo lỗi từ máy chủ nếu thất bại.
    public var error: String?
}

// MARK: - Billing and notifications

public struct CheckoutRequest: Codable, Equatable, Sendable {
    public var locale: String

    public init(locale: String = "vi") {
        self.locale = locale
    }
}

public struct CheckoutResponse: Codable, Equatable, Sendable {
    public var checkoutUrl: String?
    public var approvalUrl: String?
    public var error: String?
}

public struct NotificationPayload: Codable, Equatable, Sendable {
    public var title: String
    public var body: String
    public var url: String
}
