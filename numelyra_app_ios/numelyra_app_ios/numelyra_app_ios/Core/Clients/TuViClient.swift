import ComposableArchitecture

@DependencyClient
public struct TuViClient: Sendable {
    public var generateChart: @Sendable (_ input: ZiWeiBirthInput) throws -> ZiWeiChart
    public var evaluateLoveCompatibility: @Sendable (
        _ chartA: ZiWeiChart,
        _ chartB: ZiWeiChart
    ) throws -> ZiWeiLoveAnalysis = { chartA, chartB in
        try TuViEngine.evaluateLoveCompatibility(chartA: chartA, chartB: chartB)
    }
}

extension TuViClient: DependencyKey {
    public static let liveValue = Self(
        generateChart: { input in
            try TuViEngine.generateChart(input)
        },
        evaluateLoveCompatibility: { chartA, chartB in
            try TuViEngine.evaluateLoveCompatibility(chartA: chartA, chartB: chartB)
        }
    )

    public static let previewValue = liveValue
    public static let testValue = Self()
}

public extension DependencyValues {
    var tuViClient: TuViClient {
        get { self[TuViClient.self] }
        set { self[TuViClient.self] = newValue }
    }
}
