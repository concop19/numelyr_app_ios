import Foundation

public nonisolated enum AstrologyRuleDomain: String, Codable, CaseIterable, Equatable, Sendable {
    case temperament
    case placement
    case transitNatalAspect = "transit_natal_aspect"
    case transitHouse = "transit_house"
}

public nonisolated enum AstrologyRuleKind: String, Codable, CaseIterable, Equatable, Sendable {
    case temperamentBalance = "temperament_balance"
    case temperamentProfile = "temperament_profile"
    case planetSign = "planet_sign"
    case planetHouse = "planet_house"
    case transitNatalPair = "transit_natal_pair"
    case aspectModifier = "aspect_modifier"
    case transitHouse = "transit_house"
}

public nonisolated enum AstrologyRuleValue: Codable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case numbers([Double])
    case bool(Bool)

    public init(from decoder: Decoder) throws {
        if var array = try? decoder.unkeyedContainer() {
            var values: [Double] = []
            while !array.isAtEnd {
                values.append(try array.decode(Double.self))
            }
            self = .numbers(values)
            return
        }
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Điều kiện rule chỉ hỗ trợ string, number, bool hoặc mảng number."
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value): try container.encode(value)
        case let .number(value): try container.encode(value)
        case let .numbers(value): try container.encode(value)
        case let .bool(value): try container.encode(value)
        }
    }

    public var stringValue: String? {
        guard case let .string(value) = self else { return nil }
        return value
    }

    public var numberValue: Double? {
        guard case let .number(value) = self else { return nil }
        return value
    }
}

public nonisolated struct AstrologyRuleCompatibility: Codable, Equatable, Sendable {
    public var zodiac: String
    public var houseSystem: String
    public var engineVersion: String
    public var planets: [String]
    public var signs: [String]
    public var houses: [Int]
    public var aspects: [String]
}

public nonisolated struct AstrologyRuleSource: Codable, Equatable, Sendable {
    public var sourceId: String
    public var author: String
    public var title: String
    public var year: Int
    public var location: String
    public var url: URL
    public var licenseStatus: String
    public var verificationStatus: String
}

public nonisolated struct AstrologyRuleContentProvenance: Codable, Equatable, Sendable {
    public var sourceRefs: [String]
    public var location: String
    public var attributionType: String
    public var verificationStatus: String
}

public nonisolated struct AstrologyRulePayloadTemplate: Codable, Equatable, Sendable {
    public var experience: String
    public var challenge: String
    public var supportiveExpression: String
    public var advice: String
}

public nonisolated struct AstrologyRuleRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String { ruleId }
    public var ruleId: String
    public var version: Int
    public var domain: AstrologyRuleDomain
    public var kind: AstrologyRuleKind
    public var epistemicTier: String
    public var tradition: String
    public var conditions: [String: AstrologyRuleValue]
    public var themes: [String]
    public var payloadTemplateId: String
    public var templateBindings: [String: String]
    public var contentRefs: [String]
    public var sourceRefs: [String]
    public var requiresNatalContext: Bool
    public var editorialStatus: String
}

public nonisolated struct AstrologyRuleCatalog: Codable, Equatable, Sendable {
    public static let expectedRuleCount = 489
    public static let expectedCountsByKind: [AstrologyRuleKind: Int] = [
        .temperamentBalance: 21,
        .temperamentProfile: 3,
        .planetSign: 120,
        .planetHouse: 120,
        .transitNatalPair: 100,
        .aspectModifier: 5,
        .transitHouse: 120,
    ]

    public var catalogId: String
    public var schemaVersion: Int
    public var tradition: String
    public var compatibility: AstrologyRuleCompatibility
    public var sourceReferences: [AstrologyRuleSource]
    public var contentLibrary: [String: String]
    public var contentProvenance: [String: AstrologyRuleContentProvenance]
    public var payloadTemplates: [String: AstrologyRulePayloadTemplate]
    public var rules: [AstrologyRuleRecord]

    public init(
        catalogId: String,
        schemaVersion: Int,
        tradition: String,
        compatibility: AstrologyRuleCompatibility,
        sourceReferences: [AstrologyRuleSource],
        contentLibrary: [String: String],
        contentProvenance: [String: AstrologyRuleContentProvenance],
        payloadTemplates: [String: AstrologyRulePayloadTemplate],
        rules: [AstrologyRuleRecord]
    ) {
        self.catalogId = catalogId
        self.schemaVersion = schemaVersion
        self.tradition = tradition
        self.compatibility = compatibility
        self.sourceReferences = sourceReferences
        self.contentLibrary = contentLibrary
        self.contentProvenance = contentProvenance
        self.payloadTemplates = payloadTemplates
        self.rules = rules
    }

    public init(data: Data, decoder: JSONDecoder = JSONDecoder()) throws {
        do {
            self = try decoder.decode(Self.self, from: data)
        } catch {
            throw AstrologyRuleCatalogError.malformedJSON
        }
        let failures = validationFailures()
        guard failures.isEmpty else {
            throw AstrologyRuleCatalogError.invalidCatalog(failures)
        }
    }

    public static func bundled(in bundle: Bundle = .main) throws -> Self {
        let url = bundle.url(forResource: "AstrologyRules.v1", withExtension: "json")
            ?? bundle.url(forResource: "AstrologyRules.v1", withExtension: "json", subdirectory: "Resources")
            ?? bundle.url(forResource: "AstrologyRules.v1", withExtension: "json", subdirectory: "Shared/Resources")

        guard let url else { throw AstrologyRuleCatalogError.resourceNotFound }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw AstrologyRuleCatalogError.unreadableResource
        }
        return try Self(data: data)
    }

    public func validationFailures() -> [String] {
        var failures: [String] = []
        if catalogId != "astrology_rule_v1" { failures.append("catalogId không đúng.") }
        if schemaVersion != 1 { failures.append("schemaVersion không được hỗ trợ.") }
        if tradition != "modern_psychological" { failures.append("tradition không đúng profile v1.") }
        if compatibility.zodiac != "tropical" { failures.append("Catalog phải dùng tropical zodiac.") }
        if compatibility.houseSystem != "porphyry" { failures.append("Catalog phải dùng hệ nhà Porphyry.") }
        if compatibility.engineVersion != AstrologyEngine.engineVersion {
            failures.append("Catalog không tương thích engine \(AstrologyEngine.engineVersion).")
        }

        let expectedPlanets = ["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"]
        let expectedSigns = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
        let expectedAspects = ["conjunction", "sextile", "square", "trine", "opposition"]
        if compatibility.planets != expectedPlanets { failures.append("Danh sách planets không đủ hoặc sai thứ tự.") }
        if compatibility.signs != expectedSigns { failures.append("Danh sách signs không đủ hoặc sai thứ tự.") }
        if compatibility.houses != Array(1 ... 12) { failures.append("Catalog phải có 12 nhà.") }
        if compatibility.aspects != expectedAspects { failures.append("Catalog phải có đủ 5 góc chính theo thứ tự engine.") }

        let ids = rules.map(\.ruleId)
        let duplicates = Dictionary(grouping: ids, by: { $0 })
            .filter { $0.key.isEmpty || $0.value.count > 1 }
            .map(\.key)
            .sorted()
        if !duplicates.isEmpty { failures.append("Rule ID rỗng hoặc trùng: \(duplicates.joined(separator: ", ")).") }
        if rules.count != Self.expectedRuleCount {
            failures.append("Cần đúng \(Self.expectedRuleCount) rule components; hiện có \(rules.count).")
        }

        let sources = Set(sourceReferences.map(\.sourceId))
        if sources.count != sourceReferences.count { failures.append("sourceId bị trùng.") }
        var sourceByID: [String: AstrologyRuleSource] = [:]
        for source in sourceReferences where sourceByID[source.sourceId] == nil {
            sourceByID[source.sourceId] = source
        }
        if sourceReferences.contains(where: { $0.author.isEmpty || $0.title.isEmpty || $0.location.isEmpty || $0.url.scheme != "https" }) {
            failures.append("Source reference thiếu tác giả, nhan đề, vị trí trích dẫn hoặc HTTPS URL.")
        }
        if Set(contentProvenance.keys) != Set(contentLibrary.keys) {
            failures.append("contentProvenance phải phủ đúng toàn bộ contentLibrary.")
        }
        for (contentID, provenance) in contentProvenance {
            if provenance.sourceRefs.isEmpty || provenance.sourceRefs.contains(where: { sourceByID[$0] == nil }) {
                failures.append("\(contentID): provenance thiếu sourceRefs hợp lệ.")
            }
            if provenance.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                failures.append("\(contentID): provenance thiếu vị trí/chủ đề tham chiếu.")
            }
            if provenance.attributionType != "original_paraphrase_basis" {
                failures.append("\(contentID): attributionType không hợp lệ.")
            }
            if provenance.verificationStatus != "topic_mapped_page_not_verified" {
                failures.append("\(contentID): verificationStatus không hợp lệ.")
            }
        }

        let ruleCounts = Dictionary(grouping: rules, by: \.kind).mapValues(\.count)
        for kind in AstrologyRuleKind.allCases {
            let expected = Self.expectedCountsByKind[kind, default: 0]
            let actual = ruleCounts[kind, default: 0]
            if actual != expected { failures.append("\(kind.rawValue) cần \(expected) rule; hiện có \(actual).") }
        }

        for rule in rules {
            if rule.version != 1 { failures.append("\(rule.ruleId): version phải là 1.") }
            if rule.tradition != "modern_psychological" { failures.append("\(rule.ruleId): tradition sai.") }
            if rule.themes.isEmpty || rule.themes.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                failures.append("\(rule.ruleId): themes không được rỗng.")
            }
            if payloadTemplates[rule.payloadTemplateId] == nil { failures.append("\(rule.ruleId): thiếu payload template \(rule.payloadTemplateId).") }
            if rule.contentRefs.isEmpty || rule.contentRefs.contains(where: { contentLibrary[$0]?.isEmpty != false }) {
                failures.append("\(rule.ruleId): contentRefs rỗng hoặc không tồn tại.")
            }
            if !Self.hasValidBindings(rule, templates: payloadTemplates, content: contentLibrary) {
                failures.append("\(rule.ruleId): templateBindings thiếu, thừa hoặc trỏ tới content không tồn tại.")
            }
            if rule.sourceRefs.isEmpty || rule.sourceRefs.contains(where: { sourceByID[$0] == nil }) {
                failures.append("\(rule.ruleId): sourceRefs rỗng hoặc không tồn tại.")
            }
            if rule.contentRefs.contains(where: { contentID in
                guard let provenance = contentProvenance[contentID] else { return true }
                return !rule.sourceRefs.allSatisfy(provenance.sourceRefs.contains)
            }) {
                failures.append("\(rule.ruleId): content provenance không bao phủ nguồn của rule.")
            }
            if rule.editorialStatus != "original_paraphrase_review_required" {
                failures.append("\(rule.ruleId): editorialStatus không được bỏ qua review.")
            }
            if rule.kind == .planetHouse || rule.kind == .transitHouse {
                if !rule.requiresNatalContext { failures.append("\(rule.ruleId): rule nhà phải yêu cầu natal context.") }
            } else if rule.requiresNatalContext {
                failures.append("\(rule.ruleId): không được yêu cầu natal context cho loại rule này.")
            }
            if !Self.isValid(rule) { failures.append("\(rule.ruleId): domain, kind hoặc conditions không hợp lệ.") }
            if !Self.identityMatchesConditions(rule) {
                failures.append("\(rule.ruleId): ruleId không khớp kind/conditions.")
            }
        }

        let expectedIDs = Self.expectedRuleIDs(planets: expectedPlanets, signs: expectedSigns, aspects: expectedAspects)
        let actualIDs = Set(ids)
        let missing = expectedIDs.subtracting(actualIDs).sorted()
        let unexpected = actualIDs.subtracting(expectedIDs).sorted()
        if !missing.isEmpty { failures.append("Thiếu rule IDs: \(missing.prefix(5).joined(separator: ", ")).") }
        if !unexpected.isEmpty { failures.append("Có rule IDs ngoài bộ v1: \(unexpected.prefix(5).joined(separator: ", ")).") }
        return failures
    }

    private static func isValid(_ rule: AstrologyRuleRecord) -> Bool {
        func string(_ key: String) -> String? { rule.conditions[key]?.stringValue }
        func number(_ key: String) -> Double? { rule.conditions[key]?.numberValue }
        switch rule.kind {
        case .temperamentBalance:
            guard rule.domain == .temperament,
                  let metric = string("metric"),
                  ["fire", "earth", "air", "water", "cardinal", "fixed", "mutable"].contains(where: { metric == "temperament.\($0)" }),
                  let op = string("operator"), ["gte", "lte", "range"].contains(op),
                  let threshold = rule.conditions["threshold"]
            else { return false }
            if op == "range" {
                guard case let .numbers(bounds) = threshold, bounds.count == 2,
                      bounds[0] >= 0, bounds[1] <= 1, bounds[0] <= bounds[1]
                else { return false }
            } else {
                guard let value = number("threshold"), (0 ... 1).contains(value) else { return false }
            }
            return rule.epistemicTier == "INFR" && Self.thresholdMatchesState(rule)
        case .temperamentProfile:
            guard rule.domain == .temperament, rule.epistemicTier == "INFR",
                  let profile = string("profile"),
                  let metric = string("metric"),
                  let threshold = rule.conditions["threshold"]
            else { return false }
            switch profile {
            case "mixed_elements":
                return metric == "temperament.element.spread"
                    && string("operator") == "spread_lte"
                    && (threshold.numberValue.map { (0 ... 1).contains($0) } ?? false)
            case "mixed_modalities":
                return metric == "temperament.modality.spread"
                    && string("operator") == "spread_lte"
                    && (threshold.numberValue.map { (0 ... 1).contains($0) } ?? false)
            case "balanced_profile":
                guard metric == "temperament.all", string("operator") == "balanced_range",
                      case let .numbers(bounds) = threshold, bounds.count == 2 else { return false }
                return bounds[0] >= 0 && bounds[1] <= 1 && bounds[0] <= bounds[1]
            default:
                return false
            }
        case .planetSign:
            return rule.domain == .placement && rule.epistemicTier == "DOCT"
                && Self.planets.contains(string("planet") ?? "")
                && Self.signs.contains(string("sign") ?? "")
        case .planetHouse:
            guard rule.domain == .placement, rule.epistemicTier == "DOCT",
                  Self.planets.contains(string("planet") ?? ""),
                  let house = number("house"), house.isFinite,
                  (1 ... 12).contains(house), house.rounded() == house
            else { return false }
            return true
        case .transitNatalPair:
            return rule.domain == .transitNatalAspect && rule.epistemicTier == "DOCT"
                && rule.payloadTemplateId == "transit_natal_aspect"
                && Self.planets.contains(string("transitPlanet") ?? "")
                && Self.planets.contains(string("natalPlanet") ?? "")
        case .aspectModifier:
            return rule.domain == .transitNatalAspect && rule.epistemicTier == "DOCT"
                && Self.aspects.contains(string("aspectType") ?? "")
        case .transitHouse:
            guard rule.domain == .transitHouse, rule.epistemicTier == "DOCT",
                  Self.planets.contains(string("transitPlanet") ?? ""),
                  let house = number("house"), house.isFinite,
                  (1 ... 12).contains(house), house.rounded() == house
            else { return false }
            return true
        }
    }

    private static func thresholdMatchesState(_ rule: AstrologyRuleRecord) -> Bool {
        guard let metric = rule.conditions["metric"]?.stringValue,
              let op = rule.conditions["operator"]?.stringValue,
              let threshold = rule.conditions["threshold"] else { return false }
        let isElement = ["temperament.fire", "temperament.earth", "temperament.air", "temperament.water"].contains(metric)
        let isModality = ["temperament.cardinal", "temperament.fixed", "temperament.mutable"].contains(metric)
        guard isElement || isModality else { return false }
        let high = isElement ? 0.4 : 0.5
        let low = 0.1
        let mid: [Double] = isElement ? [0.2, 0.3] : [0.2, 0.4]
        switch (op, threshold) {
        case ("gte", .number(let value)):
            return rule.ruleId.hasSuffix(".high") && abs(value - high) < 0.000_000_1
        case ("lte", .number(let value)):
            return rule.ruleId.hasSuffix(".low") && abs(value - low) < 0.000_000_1
        case ("range", .numbers(let bounds)) where bounds.count == 2:
            return rule.ruleId.hasSuffix(".mid") && abs(bounds[0] - mid[0]) < 0.000_000_1 && abs(bounds[1] - mid[1]) < 0.000_000_1
        default:
            return false
        }
    }

    private static let planets = ["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"]
    private static let signs = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
    private static let aspects = ["conjunction", "sextile", "square", "trine", "opposition"]

    private static func identityMatchesConditions(_ rule: AstrologyRuleRecord) -> Bool {
        func string(_ key: String) -> String? { rule.conditions[key]?.stringValue }
        func number(_ key: String) -> Int? {
            guard let value = rule.conditions[key]?.numberValue,
                  value.isFinite, (1 ... 12).contains(value), value.rounded() == value else { return nil }
            return Int(value)
        }
        switch rule.kind {
        case .temperamentBalance:
            guard let metric = string("metric") else { return false }
            let parts = metric.split(separator: ".")
            guard parts.count == 2, parts[0] == "temperament" else { return false }
            let key = String(parts[1])
            let elements = ["fire", "earth", "air", "water"]
            let modalities = ["cardinal", "fixed", "mutable"]
            let prefix: String
            if elements.contains(key) { prefix = "element" }
            else if modalities.contains(key) { prefix = "modality" }
            else { return false }
            let state: String
            switch string("operator") {
            case "gte": state = "high"
            case "lte": state = "low"
            case "range": state = "mid"
            default: return false
            }
            return rule.ruleId == "temperament.\(prefix).\(key).\(state)"
        case .temperamentProfile:
            guard let profile = string("profile") else { return false }
            let expectedMetric: String
            switch profile {
            case "mixed_elements": expectedMetric = "temperament.element.spread"
            case "mixed_modalities": expectedMetric = "temperament.modality.spread"
            case "balanced_profile": expectedMetric = "temperament.all"
            default: return false
            }
            return rule.ruleId == "temperament.profile.\(profile)" && string("metric") == expectedMetric
        case .planetSign:
            guard let planet = string("planet"), let sign = string("sign") else { return false }
            return rule.ruleId == "placement.planet.\(planet).sign.\(sign)"
        case .planetHouse:
            guard let planet = string("planet"), let house = number("house") else { return false }
            return rule.ruleId == "placement.planet.\(planet).house.\(house)"
        case .transitNatalPair:
            guard let transit = string("transitPlanet"), let natal = string("natalPlanet") else { return false }
            return rule.ruleId == "aspect.pair.transit.\(transit).natal.\(natal)"
        case .aspectModifier:
            guard let aspect = string("aspectType") else { return false }
            return rule.ruleId == "aspect.modifier.\(aspect)"
        case .transitHouse:
            guard let planet = string("transitPlanet"), let house = number("house") else { return false }
            return rule.ruleId == "transit.house.\(planet).\(house)"
        }
    }

    private static func hasValidBindings(
        _ rule: AstrologyRuleRecord,
        templates: [String: AstrologyRulePayloadTemplate],
        content: [String: String]
    ) -> Bool {
        guard let template = templates[rule.payloadTemplateId],
              !rule.templateBindings.isEmpty,
              rule.templateBindings.values.allSatisfy({ rule.contentRefs.contains($0) && content[$0]?.isEmpty == false })
        else { return false }

        let templateText = [template.experience, template.challenge, template.supportiveExpression, template.advice]
            .joined(separator: " ")
        let pattern = #"\{([A-Za-z][A-Za-z0-9]*)\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(templateText.startIndex..., in: templateText)
        let placeholders = Set(regex.matches(in: templateText, range: range).compactMap { match -> String? in
            guard let valueRange = Range(match.range(at: 1), in: templateText) else { return nil }
            return String(templateText[valueRange])
        })
        return placeholders == Set(rule.templateBindings.keys)
    }

    private static func expectedRuleIDs(planets: [String], signs: [String], aspects: [String]) -> Set<String> {
        var ids = Set<String>()
        let elements = ["fire", "earth", "air", "water"]
        let modalities = ["cardinal", "fixed", "mutable"]
        for element in elements {
            for state in ["high", "low", "mid"] { ids.insert("temperament.element.\(element).\(state)") }
        }
        for modality in modalities {
            for state in ["high", "low", "mid"] { ids.insert("temperament.modality.\(modality).\(state)") }
        }
        for profile in ["mixed_elements", "mixed_modalities", "balanced_profile"] { ids.insert("temperament.profile.\(profile)") }
        for planet in planets {
            for sign in signs { ids.insert("placement.planet.\(planet).sign.\(sign)") }
            for house in 1 ... 12 { ids.insert("placement.planet.\(planet).house.\(house)") }
            for natalPlanet in planets { ids.insert("aspect.pair.transit.\(planet).natal.\(natalPlanet)") }
            for house in 1 ... 12 { ids.insert("transit.house.\(planet).\(house)") }
        }
        for aspect in aspects { ids.insert("aspect.modifier.\(aspect)") }
        return ids
    }
}

public nonisolated enum AstrologyRuleCatalogError: Error, Equatable, Sendable {
    case resourceNotFound
    case unreadableResource
    case malformedJSON
    case invalidCatalog([String])
}

extension AstrologyRuleCatalogError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .resourceNotFound: "Không tìm thấy AstrologyRules.v1.json trong app bundle."
        case .unreadableResource: "Không thể đọc AstrologyRules.v1.json."
        case .malformedJSON: "AstrologyRules.v1.json không đúng schema."
        case let .invalidCatalog(failures): "Catalog astrology không hợp lệ: \(failures.joined(separator: " "))"
        }
    }
}
