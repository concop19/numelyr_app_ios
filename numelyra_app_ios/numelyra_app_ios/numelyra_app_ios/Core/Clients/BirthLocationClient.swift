import ComposableArchitecture
import Foundation
import MapKit

public nonisolated enum BirthLocationClientError: Error, Equatable, LocalizedError, Sendable {
    case noResults
    case invalidSelection
    case missingTimeZone
    case serviceUnavailable(String)

    public var errorDescription: String? {
        switch self {
        case .noResults:
            return "Không tìm thấy thành phố phù hợp."
        case .invalidSelection:
            return "Địa điểm đã chọn không còn khả dụng. Vui lòng tìm lại."
        case .missingTimeZone:
            return "Không xác định được múi giờ của địa điểm này."
        case let .serviceUnavailable(message):
            return message
        }
    }
}

@DependencyClient
nonisolated struct BirthLocationClient {
    var makeSession: @Sendable () async -> BirthPlaceSearchSession = { .init() }
    var suggestions: @Sendable (
        _ query: String,
        _ session: BirthPlaceSearchSession
    ) async throws -> [BirthPlaceSuggestion]
    var resolve: @Sendable (
        _ suggestion: BirthPlaceSuggestion,
        _ session: BirthPlaceSearchSession
    ) async throws -> ResolvedBirthLocation
    var refresh: @Sendable (_ placeID: String) async throws -> ResolvedBirthLocation
}

extension BirthLocationClient: DependencyKey {
    static let liveValue: Self = {
        let service = AppleBirthLocationService()
        return Self(
            makeSession: { await service.makeSession() },
            suggestions: { query, session in
                try await service.suggestions(query: query, session: session)
            },
            resolve: { suggestion, session in
                try await service.resolve(suggestion: suggestion, session: session)
            },
            refresh: { placeID in
                try await service.refresh(placeID: placeID)
            }
        )
    }()

    static let testValue = Self()
    static let previewValue = Self(
        makeSession: { BirthPlaceSearchSession(id: "preview-session") },
        suggestions: { query, _ in
            [
                BirthPlaceSuggestion(
                    placeID: "preview-hanoi",
                    primaryText: query.isEmpty ? "Hà Nội" : query,
                    secondaryText: "Việt Nam"
                ),
            ]
        },
        resolve: { suggestion, _ in
            ResolvedBirthLocation(
                placeID: suggestion.placeID,
                userLabel: suggestion.userLabel,
                latitude: 21.0278,
                longitude: 105.8342,
                timeZoneIdentifier: "Asia/Ho_Chi_Minh",
                resolvedAt: Date(),
                expiresAt: Date().addingTimeInterval(30 * 86_400)
            )
        },
        refresh: { _ in throw BirthLocationClientError.invalidSelection }
    )
}

extension DependencyValues {
    var birthLocationClient: BirthLocationClient {
        get { self[BirthLocationClient.self] }
        set { self[BirthLocationClient.self] = newValue }
    }
}

@MainActor
private final class AppleBirthLocationService {
    private var sessionItems: [String: [String: MKMapItem]] = [:]
    private let cache = BirthLocationCache()

    func makeSession() -> BirthPlaceSearchSession {
        let session = BirthPlaceSearchSession()
        sessionItems[session.id] = [:]
        return session
    }

    func suggestions(query: String, session: BirthPlaceSearchSession) async throws -> [BirthPlaceSuggestion] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count >= 3 else { return [] }

        let request = MKLocalSearch.Request(naturalLanguageQuery: normalized)
        request.resultTypes = .address
        let search = MKLocalSearch(request: request)
        let response: MKLocalSearch.Response
        do {
            response = try await withTaskCancellationHandler {
                try await search.start()
            } onCancel: {
                search.cancel()
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw BirthLocationClientError.serviceUnavailable(error.localizedDescription)
        }

        var stored: [String: MKMapItem] = [:]
        var seen: Set<String> = []
        let suggestions = response.mapItems.compactMap { item -> BirthPlaceSuggestion? in
            guard let identifier = item.identifier?.rawValue,
                  seen.insert(identifier).inserted
            else { return nil }
            let primary = item.addressRepresentations?.cityName ?? item.name
            guard let primary, !primary.isEmpty else { return nil }
            let contextual = item.addressRepresentations?.cityWithContext(.full)
            let secondary = contextual == primary
                ? item.addressRepresentations?.regionName
                : contextual
            stored[identifier] = item
            return BirthPlaceSuggestion(
                placeID: identifier,
                primaryText: primary,
                secondaryText: secondary
            )
        }
        sessionItems[session.id] = stored
        return Array(suggestions.prefix(5))
    }

    func resolve(
        suggestion: BirthPlaceSuggestion,
        session: BirthPlaceSearchSession
    ) async throws -> ResolvedBirthLocation {
        guard let item = sessionItems[session.id]?[suggestion.placeID] else {
            throw BirthLocationClientError.invalidSelection
        }
        let resolved = try makeResolvedLocation(item: item, fallbackLabel: suggestion.userLabel)
        await cache.save(resolved)
        sessionItems[session.id] = nil
        return resolved
    }

    func refresh(placeID: String) async throws -> ResolvedBirthLocation {
        if let cached = await cache.load(placeID: placeID), !cached.isExpired() {
            return cached
        }
        guard let identifier = MKMapItem.Identifier(rawValue: placeID) else {
            throw BirthLocationClientError.invalidSelection
        }
        let request = MKMapItemRequest(mapItemIdentifier: identifier)
        let item: MKMapItem
        do {
            item = try await request.mapItem
        } catch {
            throw BirthLocationClientError.serviceUnavailable(error.localizedDescription)
        }
        let resolved = try makeResolvedLocation(item: item, fallbackLabel: item.name ?? "Nơi sinh")
        await cache.save(resolved)
        return resolved
    }

    private func makeResolvedLocation(
        item: MKMapItem,
        fallbackLabel: String
    ) throws -> ResolvedBirthLocation {
        guard let identifier = item.identifier?.rawValue else {
            throw BirthLocationClientError.invalidSelection
        }
        guard let timeZone = item.timeZone else {
            throw BirthLocationClientError.missingTimeZone
        }
        let now = Date()
        return ResolvedBirthLocation(
            placeID: identifier,
            userLabel: item.addressRepresentations?.cityWithContext(.full) ?? fallbackLabel,
            latitude: item.location.coordinate.latitude,
            longitude: item.location.coordinate.longitude,
            timeZoneIdentifier: timeZone.identifier,
            resolvedAt: now,
            expiresAt: now.addingTimeInterval(30 * 86_400)
        )
    }
}

private actor BirthLocationCache {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load(placeID: String) -> ResolvedBirthLocation? {
        guard let data = defaults.data(forKey: key(placeID)) else { return nil }
        return try? decoder.decode(ResolvedBirthLocation.self, from: data)
    }

    func save(_ location: ResolvedBirthLocation) {
        guard let data = try? encoder.encode(location) else { return }
        defaults.set(data, forKey: key(location.placeID))
    }

    private func key(_ placeID: String) -> String {
        "@birth_location_apple_v1_\(placeID)"
    }
}
