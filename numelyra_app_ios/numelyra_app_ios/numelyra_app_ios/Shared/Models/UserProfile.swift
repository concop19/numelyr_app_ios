import Foundation

public nonisolated enum Gender: String, Codable, CaseIterable, Equatable, Sendable {
    case male
    case female

    public var titleVi: String {
        switch self {
        case .male: return "Nam"
        case .female: return "Nữ"
        }
    }
}

public nonisolated struct UserProfile: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var fullName: String
    public var birthDate: String // Format ISO YYYY-MM-DD, e.g. "1998-10-20"
    public var gender: Gender?
    public var isDefault: Bool
    public var birthTime: String? // e.g. "14:30"
    public var birthPlace: String? // e.g. "Hà Nội"
    public var birthLocation: BirthLocationReference?
    public var birthTimeAccuracy: BirthTimeAccuracy?

    public init(
        id: String = UUID().uuidString,
        fullName: String,
        birthDate: String,
        gender: Gender? = nil,
        isDefault: Bool = false,
        birthTime: String? = nil,
        birthPlace: String? = nil,
        birthLocation: BirthLocationReference? = nil,
        birthTimeAccuracy: BirthTimeAccuracy? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.birthDate = birthDate
        self.gender = gender
        self.isDefault = isDefault
        self.birthTime = birthTime
        self.birthPlace = birthPlace
        self.birthLocation = birthLocation
        self.birthTimeAccuracy = birthTimeAccuracy
    }

    public var effectiveBirthTimeAccuracy: BirthTimeAccuracy {
        if let birthTimeAccuracy { return birthTimeAccuracy }
        return birthTime?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? .exact
            : .unknown
    }
}
