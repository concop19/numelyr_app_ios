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

    public var cachedImage: @Sendable (_ url: URL) -> Data? = { _ in nil }

    public var loadImage: @Sendable (_ url: URL) async throws -> Data

    public var prefetch: @Sendable (_ centerDate: Date) async -> Void = { _ in }
}

extension CalendarArtClient: DependencyKey {
    public static let liveValue = Self(
        item: {
            CalendarArtEngine.item(for: $0, baseURL: AppConfig.calendarAssetBaseURL)
        },
        cachedImage: { url in
            CalendarArtCache.shared.data(for: url)
        },
        loadImage: { url in
            if let cached = CalendarArtCache.shared.data(for: url) {
                return cached
            }

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

            CalendarArtCache.shared.store(
                data: data,
                for: url,
                referenceDate: Date(),
                baseURL: AppConfig.calendarAssetBaseURL
            )
            return data
        },
        prefetch: { centerDate in
            let cache = CalendarArtCache.shared
            let baseURL = AppConfig.calendarAssetBaseURL
            cache.purgeExceptWindow(around: centerDate, baseURL: baseURL)

            let calendar = LunarService.defaultCalendar
            for offset in -2...2 {
                guard let date = calendar.date(byAdding: .day, value: offset, to: centerDate) else { continue }
                let lunar = LunarService.solarToLunar(date: date, calendar: calendar)
                let art = CalendarArtEngine.item(for: lunar, baseURL: baseURL)
                guard let url = art.imageURL else { continue }

                if cache.data(for: url) == nil {
                    let request = URLRequest(
                        url: url,
                        cachePolicy: .returnCacheDataElseLoad,
                        timeoutInterval: 15
                    )
                    if let (data, response) = try? await URLSession.shared.data(for: request),
                       let httpResponse = response as? HTTPURLResponse,
                       (200..<300).contains(httpResponse.statusCode),
                       !data.isEmpty
                    {
                        cache.store(
                            data: data,
                            for: url,
                            referenceDate: centerDate,
                            baseURL: baseURL
                        )
                    }
                }
            }
        }
    )

    public static let previewValue = Self(
        item: { CalendarArtEngine.item(for: $0) },
        cachedImage: { _ in nil },
        loadImage: { _ in throw CalendarArtClientError.invalidResponse },
        prefetch: { _ in }
    )

    public static let testValue = Self()
}

public extension DependencyValues {
    var calendarArtClient: CalendarArtClient {
        get { self[CalendarArtClient.self] }
        set { self[CalendarArtClient.self] = newValue }
    }
}
