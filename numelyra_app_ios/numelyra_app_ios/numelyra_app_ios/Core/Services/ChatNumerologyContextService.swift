import Foundation

/// Builds compact, value-specific numerology context for the chat agent.
/// This catalog is deliberately separate from the long-form 24-indicator readings.
nonisolated enum ChatNumerologyContextService {
    private struct Catalog: Decodable, Sendable {
        struct Indicator: Decodable, Sendable {
            var name: String
            var values: [String: String]
        }

        var indicators: [String: Indicator]
    }

    private static let catalog: Catalog? = {
        guard let url = Bundle.main.url(forResource: "ChatNumerologyContext.v1", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(Catalog.self, from: data)
    }()

    static func enrich(_ indicators: [NumerologyIndicator]) -> [NumerologyIndicator] {
        guard let catalog else { return indicators }

        return indicators.map { indicator in
            guard let definition = catalog.indicators[indicator.key] else { return indicator }
            let value = indicator.value.displayValue
            guard let interpretation = definition.values[value] else { return indicator }
            var compact = indicator
            compact.meaning = "\(definition.name) \(value): \(interpretation)"
            return compact
        }
    }
}
