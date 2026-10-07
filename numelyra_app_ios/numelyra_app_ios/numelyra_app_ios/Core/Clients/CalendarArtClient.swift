import ComposableArchitecture
import Foundation

public enum CalendarArtClientError: Error, Equatable, Sendable {
    case invalidResponse
}

@DependencyClient
public struct CalendarArtClient: Sendable {
    public var item: @Sendable (_ lunarDate: LunarDate) -> CalendarArtItem = {
        CalendarArtEngine.item(for: $0)
    }

    public var loadImage: @Sendable (_ url: URL) async throws -> Data
}

extension CalendarArtClient: DependencyKey {
    public static let liveValue = Self(
        item: {
            CalendarArtEngine.item(for: $0, baseURL: AppConfig.calendarAssetBaseURL)
        },
        loadImage: { url in
            let request = URLRequest(
                url: url,
                cachePolicy: .returnCacheDataElseLoad,
                timeoutInterval: 15
            )
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode),
                  !data.isEmpty
            else {
                throw CalendarArtClientError.invalidResponse
            }
            return data
        }
    )

    public static let previewValue = Self(
        item: { CalendarArtEngine.item(for: $0) },
        loadImage: { _ in throw CalendarArtClientError.invalidResponse }
    )

    public static let testValue = Self()
}

public extension DependencyValues {
    var calendarArtClient: CalendarArtClient {
        get { self[CalendarArtClient.self] }
        set { self[CalendarArtClient.self] = newValue }
    }
}
