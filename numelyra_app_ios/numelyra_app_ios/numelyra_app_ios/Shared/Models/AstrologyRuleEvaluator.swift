import Foundation

public nonisolated struct AstrologyRuleFacts: Codable, Equatable, Sendable {
    public var temperament: [String: Double]
    public var natalSigns: [String: String]
    public var natalHouses: [String: Int]
    public var transitHouses: [String: Int]
    public var aspects: [DetectedAstroAspect]
    public var hasReliableNatalContext: Bool

    public init(
        temperament: [String: Double] = [:],
        natalSigns: [String: String] = [:],
        natalHouses: [String: Int] = [:],
        transitHouses: [String: Int] = [:],
        aspects: [DetectedAstroAspect] = [],
        hasReliableNatalContext: Bool = false
    ) {
        self.temperament = temperament
        self.natalSigns = natalSigns
        self.natalHouses = natalHouses
        self.transitHouses = transitHouses
        self.aspects = aspects
        self.hasReliableNatalContext = hasReliableNatalContext
    }

    public init(
        temperament: AstroTemperamentMetadata,
        natalSigns: [String: String],
        natalHouses: [String: Int] = [:],
        transitHouses: [String: Int] = [:],
        aspects: [DetectedAstroAspect] = [],
        hasReliableNatalContext: Bool
    ) {
        self.init(
            temperament: [
                "temperament.fire": temperament.balance.fire,
                "temperament.earth": temperament.balance.earth,
                "temperament.air": temperament.balance.air,
                "temperament.water": temperament.balance.water,
                "temperament.cardinal": temperament.balance.cardinal,
                "temperament.fixed": temperament.balance.fixed,
                "temperament.mutable": temperament.balance.mutable,
            ],
            natalSigns: natalSigns,
            natalHouses: natalHouses,
            transitHouses: transitHouses,
            aspects: aspects,
            hasReliableNatalContext: hasReliableNatalContext
        )
    }
}

public nonisolated struct AstrologyRuleRenderedPayload: Codable, Equatable, Sendable {
    public var experience: String
    public var challenge: String
    public var supportiveExpression: String
    public var advice: String
}

public nonisolated struct AstrologyRuleMatch: Codable, Equatable, Sendable, Identifiable {
    public var id: String { ruleIds.joined(separator: "+") }
    public var ruleIds: [String]
    public var themes: [String]
    public var score: Double
    public var payload: AstrologyRuleRenderedPayload
}

public nonisolated struct AstrologyRuleTopic: Codable, Equatable, Sendable, Identifiable {
    public var id: String { topicId }
    public var topicId: String
    public var title: String
    public var score: Double
    public var matchedRuleIds: [String]
    public var supportingSignalCount: Int
    public var supportingThemes: [String]
    public var payload: AstrologyRuleRenderedPayload
}

public nonisolated struct AstrologyRuleEvaluation: Codable, Equatable, Sendable {
    public var catalogId: String
    public var schemaVersion: Int
    public var matches: [AstrologyRuleMatch]
    public var topTopics: [AstrologyRuleTopic]
}

/// Pure evaluator for the v1 catalog. It only consumes structured chart facts; callers own chart calculation and API integration.
public nonisolated struct AstrologyRuleEvaluator: Sendable {
    private let catalog: AstrologyRuleCatalog

    public init(catalog: AstrologyRuleCatalog) throws {
        let failures = catalog.validationFailures()
        guard failures.isEmpty else { throw AstrologyRuleCatalogError.invalidCatalog(failures) }
        self.catalog = catalog
    }

    public func evaluate(_ facts: AstrologyRuleFacts, maximumTopics: Int = 3) -> AstrologyRuleEvaluation {
        let rulesByID = Dictionary(uniqueKeysWithValues: catalog.rules.map { ($0.ruleId, $0) })
        var matches: [AstrologyRuleMatch] = []

        for rule in catalog.rules {
            switch rule.kind {
            case .temperamentBalance:
                guard let metric = string("metric", in: rule), let value = facts.temperament[metric],
                      matchesThreshold(rule, value: value),
                      let rendered = render(rule, bindings: rule.templateBindings) else { continue }
                matches.append(.init(ruleIds: [rule.ruleId], themes: rule.themes, score: 1, payload: rendered))

            case .temperamentProfile:
                guard profileMatches(rule, facts: facts),
                      let rendered = render(rule, bindings: rule.templateBindings) else { continue }
                matches.append(.init(ruleIds: [rule.ruleId], themes: rule.themes, score: 1, payload: rendered))

            case .planetSign:
                guard let planet = string("planet", in: rule), let sign = string("sign", in: rule),
                      facts.natalSigns[planet] == sign,
                      let rendered = render(rule, bindings: rule.templateBindings) else { continue }
                matches.append(.init(ruleIds: [rule.ruleId], themes: rule.themes, score: 1, payload: rendered))

            case .planetHouse:
                guard facts.hasReliableNatalContext,
                      let planet = string("planet", in: rule), let house = integer("house", in: rule),
                      facts.natalHouses[planet] == house,
                      let rendered = render(rule, bindings: rule.templateBindings) else { continue }
                matches.append(.init(ruleIds: [rule.ruleId], themes: rule.themes, score: 1, payload: rendered))

            case .transitNatalPair:
                guard let transit = string("transitPlanet", in: rule), let natal = string("natalPlanet", in: rule) else { continue }
                for aspect in facts.aspects where aspect.transitPlanet == transit && aspect.natalPlanet == natal {
                    guard let definition = AstrologyEngine.majorAspects.first(where: { $0.type == aspect.type }),
                          aspect.orb.isFinite, aspect.orb >= 0, aspect.orb <= definition.maxOrb,
                          let modifier = rulesByID["aspect.modifier.\(aspect.type.rawValue)"] else { continue }
                    var bindings = rule.templateBindings
                    bindings["aspectStyle"] = "aspect.\(aspect.type.rawValue).style"
                    bindings["aspectSupport"] = "aspect.\(aspect.type.rawValue).support"
                    bindings["aspectAdvice"] = "aspect.\(aspect.type.rawValue).advice"
                    guard let rendered = render(rule, bindings: bindings) else { continue }
                    matches.append(.init(
                        ruleIds: [rule.ruleId, modifier.ruleId],
                        themes: Array(Set(rule.themes + modifier.themes)).sorted(),
                        score: max(0, aspect.weight),
                        payload: rendered
                    ))
                }

            case .aspectModifier:
                // Aspect modifiers are consumed together with the matching transit/natal pair.
                continue

            case .transitHouse:
                guard facts.hasReliableNatalContext,
                      let planet = string("transitPlanet", in: rule), let house = integer("house", in: rule),
                      facts.transitHouses[planet] == house,
                      let rendered = render(rule, bindings: rule.templateBindings) else { continue }
                matches.append(.init(ruleIds: [rule.ruleId], themes: rule.themes, score: 1, payload: rendered))
            }
        }

        return AstrologyRuleEvaluation(
            catalogId: catalog.catalogId,
            schemaVersion: catalog.schemaVersion,
            matches: matches.sorted { $0.score > $1.score },
            topTopics: synthesizeTopics(matches, rulesByID: rulesByID, maximumCount: max(0, maximumTopics))
        )
    }

    private func profileMatches(_ rule: AstrologyRuleRecord, facts: AstrologyRuleFacts) -> Bool {
        guard let metric = string("metric", in: rule), let threshold = rule.conditions["threshold"] else { return false }
        let relevant: [Double]
        switch metric {
        case "temperament.element.spread":
            relevant = ["fire", "earth", "air", "water"].compactMap { facts.temperament["temperament.\($0)"] }
        case "temperament.modality.spread":
            relevant = ["cardinal", "fixed", "mutable"].compactMap { facts.temperament["temperament.\($0)"] }
        case "temperament.all":
            relevant = ["fire", "earth", "air", "water", "cardinal", "fixed", "mutable"]
                .compactMap { facts.temperament["temperament.\($0)"] }
        default:
            return false
        }
        guard relevant.count == (metric == "temperament.element.spread" ? 4 : metric == "temperament.modality.spread" ? 3 : 7),
              relevant.allSatisfy({ $0.isFinite && (0 ... 1).contains($0) }) else { return false }
        if string("operator", in: rule) == "spread_lte", let bound = threshold.numberValue {
            return (relevant.max() ?? 0) - (relevant.min() ?? 0) <= bound
        }
        if string("operator", in: rule) == "balanced_range", case let .numbers(bounds) = threshold, bounds.count == 2 {
            return relevant.allSatisfy { $0 >= bounds[0] && $0 <= bounds[1] }
        }
        return false
    }

    private func matchesThreshold(_ rule: AstrologyRuleRecord, value: Double) -> Bool {
        guard value.isFinite, let op = string("operator", in: rule), let threshold = rule.conditions["threshold"] else { return false }
        switch (op, threshold) {
        case ("gte", .number(let bound)): return value >= bound
        case ("lte", .number(let bound)): return value <= bound
        case ("range", .numbers(let bounds)) where bounds.count == 2: return value >= bounds[0] && value <= bounds[1]
        default: return false
        }
    }

    private func render(_ rule: AstrologyRuleRecord, bindings: [String: String]) -> AstrologyRuleRenderedPayload? {
        guard let template = catalog.payloadTemplates[rule.payloadTemplateId] else { return nil }
        func expand(_ text: String) -> String? {
            var value = text
            for (placeholder, ref) in bindings {
                guard let content = catalog.contentLibrary[ref] else { return nil }
                value = value.replacingOccurrences(of: "{\(placeholder)}", with: content)
            }
            return value
        }
        guard let experience = expand(template.experience), let challenge = expand(template.challenge),
              let supportive = expand(template.supportiveExpression), let advice = expand(template.advice) else { return nil }
        return .init(experience: experience, challenge: challenge, supportiveExpression: supportive, advice: advice)
    }

    private func synthesizeTopics(
        _ matches: [AstrologyRuleMatch],
        rulesByID: [String: AstrologyRuleRecord],
        maximumCount: Int
    ) -> [AstrologyRuleTopic] {
        var grouped: [String: (title: String, matches: [AstrologyRuleMatch])] = [:]
        for match in matches {
            guard let primaryRule = match.ruleIds.first.flatMap({ rulesByID[$0] }) else { continue }
            let topic = topicIdentity(for: primaryRule)
            grouped[topic.id, default: (topic.title, [])].matches.append(match)
        }

        let topics = grouped.map { id, value -> AstrologyRuleTopic in
            let payloads = value.matches.map(\.payload)
            let signalIDs = Set(value.matches.compactMap { $0.ruleIds.first })
            return AstrologyRuleTopic(
                topicId: id,
                title: value.title,
                // Related placements add evidence without inflating the strongest engine score.
                score: value.matches.map(\.score).max() ?? 0,
                matchedRuleIds: Array(Set(value.matches.flatMap(\.ruleIds))).sorted(),
                supportingSignalCount: signalIDs.count,
                supportingThemes: Array(Set(value.matches.flatMap(\.themes))).sorted(),
                payload: AstrologyRuleRenderedPayload(
                    experience: joinUnique(payloads.map(\.experience)),
                    challenge: joinUnique(payloads.map(\.challenge)),
                    supportiveExpression: joinUnique(payloads.map(\.supportiveExpression)),
                    advice: joinUnique(payloads.map(\.advice))
                )
            )
        }

        return topics.sorted {
            if $0.score != $1.score { return $0.score > $1.score }
            if $0.supportingSignalCount != $1.supportingSignalCount { return $0.supportingSignalCount > $1.supportingSignalCount }
            return $0.id < $1.id
        }.prefix(maximumCount).map { $0 }
    }

    private func topicIdentity(for rule: AstrologyRuleRecord) -> (id: String, title: String) {
        func value(_ key: String) -> String { rule.conditions[key]?.stringValue ?? "unknown" }
        let planetTitles = [
            "Sun": "Mặt Trời", "Moon": "Mặt Trăng", "Mercury": "Sao Thủy", "Venus": "Sao Kim",
            "Mars": "Sao Hỏa", "Jupiter": "Sao Mộc", "Saturn": "Sao Thổ", "Uranus": "Thiên Vương",
            "Neptune": "Hải Vương", "Pluto": "Diêm Vương",
        ]
        switch rule.kind {
        case .temperamentBalance:
            let metric = value("metric")
            let key = metric.split(separator: ".").last.map(String.init) ?? metric
            let names = ["fire": "Lửa", "earth": "Đất", "air": "Khí", "water": "Nước",
                         "cardinal": "Tiên phong", "fixed": "Kiên định", "mutable": "Linh hoạt"]
            let dimension = ["fire", "earth", "air", "water"].contains(key) ? "Nguyên tố" : "Tính chất"
            return (metric, "\(dimension) \(names[key] ?? key)")
        case .temperamentProfile:
            let profile = value("profile")
            let titles = ["mixed_elements": "Phân bố nguyên tố", "mixed_modalities": "Nhịp tính chất", "balanced_profile": "Cân bằng khí chất"]
            return ("temperament.profile.\(profile)", titles[profile] ?? "Khí chất")
        case .planetSign, .planetHouse:
            let planet = value("planet")
            return ("natal.planet.\(planet)", "Natal · \(planetTitles[planet] ?? planet)")
        case .transitNatalPair:
            let transit = value("transitPlanet")
            let natal = value("natalPlanet")
            return ("transit_natal.\(transit).\(natal)", "\(planetTitles[transit] ?? transit) · \(planetTitles[natal] ?? natal)")
        case .transitHouse:
            let planet = value("transitPlanet")
            return ("transit.planet.\(planet)", "Transit · \(planetTitles[planet] ?? planet)")
        case .aspectModifier:
            let aspect = value("aspectType")
            return ("aspect.\(aspect)", "Góc \(aspect)")
        }
    }

    private func joinUnique(_ values: [String]) -> String {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }.joined(separator: " ")
    }

    private func string(_ key: String, in rule: AstrologyRuleRecord) -> String? {
        rule.conditions[key]?.stringValue
    }

    private func integer(_ key: String, in rule: AstrologyRuleRecord) -> Int? {
        guard let value = rule.conditions[key]?.numberValue, value.rounded() == value else { return nil }
        return Int(value)
    }
}
