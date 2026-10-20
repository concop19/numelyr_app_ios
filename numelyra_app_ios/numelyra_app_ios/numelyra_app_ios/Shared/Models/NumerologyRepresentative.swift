import Foundation

public nonisolated enum RepresentativeMatchType: String, Codable, Equatable, Sendable {
    case exactThree = "exact_3"
    case coreTwo = "core_2"
    case lifePathOne = "lifepath_1"

    public var labelVi: String {
        switch self {
        case .exactThree: return "100% Đồng Điệu 3 Số"
        case .coreTwo: return "Đồng Điệu Đường Đời & Sứ Mệnh"
        case .lifePathOne: return "Đồng Điệu Đường Đời"
        }
    }
}

public nonisolated struct NumerologyRepresentative: Identifiable, Codable, Equatable, Sendable {
    public var id: Int
    public var lifePath: Int
    public var expression: Int
    public var soulUrge: Int
    public var nameUsed: String
    public var displayName: String
    public var displayNameVi: String?
    public var birthDate: String
    public var deathDate: String?
    public var description: String?
    public var wikidataURL: String
    public var wikipediaURL: String?
    public var sitelinks: Int
    public var imageURL: String?
    public var biography: String?
    public var biographyVi: String?
    public var biographyEn: String?
    public var matchType: RepresentativeMatchType

    public init(
        id: Int,
        lifePath: Int,
        expression: Int,
        soulUrge: Int,
        nameUsed: String,
        displayName: String,
        displayNameVi: String? = nil,
        birthDate: String,
        deathDate: String? = nil,
        description: String? = nil,
        wikidataURL: String,
        wikipediaURL: String? = nil,
        sitelinks: Int,
        imageURL: String? = nil,
        biography: String? = nil,
        biographyVi: String? = nil,
        biographyEn: String? = nil,
        matchType: RepresentativeMatchType
    ) {
        self.id = id
        self.lifePath = lifePath
        self.expression = expression
        self.soulUrge = soulUrge
        self.nameUsed = nameUsed
        self.displayName = displayName
        self.displayNameVi = displayNameVi
        self.birthDate = birthDate
        self.deathDate = deathDate
        self.description = description
        self.wikidataURL = wikidataURL
        self.wikipediaURL = wikipediaURL
        self.sitelinks = sitelinks
        self.imageURL = imageURL
        self.biography = biography
        self.biographyVi = biographyVi
        self.biographyEn = biographyEn
        self.matchType = matchType
    }

    public var preferredDisplayName: String {
        nonEmpty(displayNameVi) ?? nonEmpty(displayName) ?? "Nhân Vật Lịch Sử"
    }

    public func displayName(for language: RepresentativeLanguage) -> String {
        switch language {
        case .vietnamese: return preferredDisplayName
        case .english: return nonEmpty(displayName) ?? preferredDisplayName
        }
    }

    public func biography(for language: RepresentativeLanguage) -> String {
        let fallbackVi = "Chưa có thông tin chi tiết về cuộc đời nhân vật này."
        let fallbackEn = "No detailed biography available."
        switch language {
        case .vietnamese:
            return nonEmpty(biographyVi) ?? nonEmpty(biography) ?? nonEmpty(description) ?? fallbackVi
        case .english:
            return nonEmpty(biographyEn) ?? nonEmpty(biography) ?? nonEmpty(description) ?? fallbackEn
        }
    }

    public var sourceURL: URL? {
        guard let rawValue = nonEmpty(wikipediaURL) ?? nonEmpty(wikidataURL) else { return nil }
        return URL(string: rawValue)
    }

    public var lifespan: String {
        let birth = Self.year(from: birthDate)
        let death = Self.year(from: deathDate)
        guard let birth else { return "" }
        return death.map { "\(birth) – \($0)" } ?? "Sinh năm \(birth)"
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }

    private static func year(from value: String?) -> String? {
        guard let value,
              let range = value.range(of: "-?[0-9]{1,4}", options: .regularExpression)
        else { return nil }
        return String(value[range])
    }
}

public nonisolated enum RepresentativeLanguage: String, Codable, Equatable, Sendable {
    case vietnamese = "vi"
    case english = "en"
}

public nonisolated struct RepresentativeTriple: Codable, Equatable, Sendable {
    public var lifePath: Int
    public var expression: Int
    public var soulUrge: Int

    public init(lifePath: Int, expression: Int, soulUrge: Int) {
        self.lifePath = lifePath
        self.expression = expression
        self.soulUrge = soulUrge
    }
}

public nonisolated enum RepresentativeLookupError: Error, Equatable, Sendable {
    case databaseUnavailable
    case queryFailed(String)
    case invalidImageResponse

    public var messageVi: String {
        switch self {
        case .databaseUnavailable:
            return "Không thể mở kho dữ liệu nhân vật. Vui lòng thử lại."
        case .queryFailed:
            return "Không thể tra cứu nhân vật đồng điệu lúc này."
        case .invalidImageResponse:
            return "Không thể tải ảnh nhân vật."
        }
    }
}
