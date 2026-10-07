import ComposableArchitecture
import Foundation

@DependencyClient
public struct NumerologyClient: Sendable {
    public var calculate24: @Sendable (
        _ fullName: String,
        _ birthDate: String,
        _ referenceDate: Date
    ) -> NumerologySnapshot = { fullName, birthDate, referenceDate in
        NumerologyEngine.calculate24(
            fullName: fullName,
            birthDate: birthDate,
            referenceDate: referenceDate
        )
    }

    public var calculate24Cards: @Sendable (
        _ fullName: String,
        _ birthDate: String,
        _ referenceDate: Date
    ) -> [CalculatedNumerologyIndicator] = { fullName, birthDate, referenceDate in
        NumerologyEngine.calculate24Cards(
            fullName: fullName,
            birthDate: birthDate,
            referenceDate: referenceDate
        )
    }

    public var requestedIndicators: @Sendable (
        _ fullName: String,
        _ birthDate: String,
        _ keys: [String],
        _ referenceDate: Date
    ) -> [NumerologyIndicator] = { fullName, birthDate, keys, referenceDate in
        NumerologyEngine.requestedIndicators(
            fullName: fullName,
            birthDate: birthDate,
            keys: keys,
            referenceDate: referenceDate
        )
    }

    public var indicatorReading: @Sendable (
        _ indicatorKey: String,
        _ indicatorValue: String,
        _ cardNameVi: String
    ) -> KnowledgeReading = { indicatorKey, indicatorValue, cardNameVi in
        NumerologyKnowledgeService.getIndicatorReading(
            indicatorKey: indicatorKey,
            indicatorValue: indicatorValue,
            cardNameVi: cardNameVi
        )
    }
}

extension NumerologyClient: DependencyKey {
    public static let liveValue = Self(
        calculate24: { fullName, birthDate, referenceDate in
            NumerologyEngine.calculate24(
                fullName: fullName,
                birthDate: birthDate,
                referenceDate: referenceDate
            )
        },
        calculate24Cards: { fullName, birthDate, referenceDate in
            NumerologyEngine.calculate24Cards(
                fullName: fullName,
                birthDate: birthDate,
                referenceDate: referenceDate
            )
        },
        requestedIndicators: { fullName, birthDate, keys, referenceDate in
            NumerologyEngine.requestedIndicators(
                fullName: fullName,
                birthDate: birthDate,
                keys: keys,
                referenceDate: referenceDate
            )
        },
        indicatorReading: { indicatorKey, indicatorValue, cardNameVi in
            NumerologyKnowledgeService.getIndicatorReading(
                indicatorKey: indicatorKey,
                indicatorValue: indicatorValue,
                cardNameVi: cardNameVi
            )
        }
    )

    public static let previewValue = liveValue
    public static let testValue = Self()
}

public extension DependencyValues {
    var numerologyClient: NumerologyClient {
        get { self[NumerologyClient.self] }
        set { self[NumerologyClient.self] = newValue }
    }
}
