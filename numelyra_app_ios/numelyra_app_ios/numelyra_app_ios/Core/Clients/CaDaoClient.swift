import ComposableArchitecture
import Foundation

@DependencyClient
public struct CaDaoClient: Sendable {
    public var count: @Sendable () -> Int = {
        CaDaoDatabaseService.getCaDaoCount()
    }

    public var dailyCaDao: @Sendable (_ date: Date) -> CaDaoRecord = { date in
        CaDaoDatabaseService.getDailyCaDao(for: date)
    }

    public var randomCaDao: @Sendable () -> CaDaoRecord? = {
        CaDaoDatabaseService.getRandomCaDao()
    }

    public var byCategory: @Sendable (_ category: String, _ limit: Int) -> [CaDaoRecord] = { category, limit in
        CaDaoDatabaseService.getCaDaoByCategory(category, limit: limit)
    }
}

extension CaDaoClient: DependencyKey {
    public static let liveValue = Self(
        count: {
            CaDaoDatabaseService.getCaDaoCount()
        },
        dailyCaDao: { date in
            CaDaoDatabaseService.getDailyCaDao(for: date)
        },
        randomCaDao: {
            CaDaoDatabaseService.getRandomCaDao()
        },
        byCategory: { category, limit in
            CaDaoDatabaseService.getCaDaoByCategory(category, limit: limit)
        }
    )

    public static let previewValue = Self(
        count: { 16521 },
        dailyCaDao: { _ in
            CaDaoDatabaseService.emptyDBFallback
        },
        randomCaDao: {
            CaDaoDatabaseService.emptyDBFallback
        },
        byCategory: { _, _ in
            [CaDaoDatabaseService.emptyDBFallback]
        }
    )

    public static let testValue = Self()
}

public extension DependencyValues {
    var caDaoClient: CaDaoClient {
        get { self[CaDaoClient.self] }
        set { self[CaDaoClient.self] = newValue }
    }
}
