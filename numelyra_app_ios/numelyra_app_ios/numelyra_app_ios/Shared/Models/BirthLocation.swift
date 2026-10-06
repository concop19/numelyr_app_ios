import Foundation

public nonisolated enum BirthTimeAccuracy: String, Codable, CaseIterable, Equatable, Sendable {
    case exact
    case unknown
}

/// Reference that is safe to persist and sync. Google Place data is deliberately excluded.
public nonisolated struct BirthLocationReference: Codable, Equatable, Sendable {
    public var placeID: String
    public var userLabel: String

    public init(placeID: String, userLabel: String) {
        self.placeID = placeID
        self.userLabel = userLabel
    }
}

/// Short-lived Places data used locally to resolve the birth instant and chart angles.
public nonisolated struct ResolvedBirthLocation: Codable, Equatable, Sendable {
    public var placeID: String
    public var userLabel: String
    public var latitude: Double
    public var longitude: Double
    public var timeZoneIdentifier: String
    public var resolvedAt: Date
    public var expiresAt: Date

    public init(
        placeID: String,
        userLabel: String,
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String,
        resolvedAt: Date,
        expiresAt: Date
    ) {
        self.placeID = placeID
        self.userLabel = userLabel
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
        self.resolvedAt = resolvedAt
        self.expiresAt = expiresAt
    }

    public func isExpired(at date: Date = Date()) -> Bool {
        expiresAt <= date
    }
}

public nonisolated struct BirthPlaceSearchSession: Hashable, Sendable {
    public var id: String

    public init(id: String = UUID().uuidString) {
        self.id = id
    }
}

public nonisolated struct BirthPlaceSuggestion: Identifiable, Equatable, Sendable {
    public var id: String { placeID }
    public var placeID: String
    public var primaryText: String
    public var secondaryText: String?

    public var userLabel: String {
        guard let secondaryText, !secondaryText.isEmpty else { return primaryText }
        return "\(primaryText), \(secondaryText)"
    }

    public init(placeID: String, primaryText: String, secondaryText: String? = nil) {
        self.placeID = placeID
        self.primaryText = primaryText
        self.secondaryText = secondaryText
    }
}
