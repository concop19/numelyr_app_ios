import AstronomyKit
import Foundation

nonisolated enum AstrologyEngine {
    static let engineVersion = "astrology-v3-porphyry-1"
//thong bao phien ban
    enum EngineError: LocalizedError, Equatable {
        case invalidBirthDate(String)
        case invalidBirthTime(String)
        case invalidTimeZone(String)
        case nonexistentLocalTime(String)

        var errorDescription: String? {
            switch self {
            case let .invalidBirthDate(value):
                return "Ngày sinh không hợp lệ: \(value)"
            case let .invalidBirthTime(value):
                return "Giờ sinh không hợp lệ: \(value)"
            case let .invalidTimeZone(value):
                return "Múi giờ nơi sinh không hợp lệ: \(value)"
            case let .nonexistentLocalTime(value):
                return "Giờ sinh \(value) không tồn tại trong múi giờ đã chọn do chuyển giờ mùa hè."
            }
        }
    }
    //: localLizeError, equatable. danh dau day la th dc xa ra ẽxception va co the so sanh

    struct ResolvedBirthDate: Equatable, Sendable {
        var date: Date
        var isTimeEstimated: Bool
        var precision: AstroBirthDataPrecision
        var isLocalTimeAmbiguous: Bool
    }
//cau truc cua birthdate. sau khi da dc result,-> ngay, giờ ước tính,gio dia ph co mo ho ko
    static let zodiacSigns = [
        "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
        "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces",
    ]

    static let zodiacQualities: [ZodiacQuality] = [
        .init(element: .fire, modality: .cardinal),
        .init(element: .earth, modality: .fixed),
        .init(element: .air, modality: .mutable),
        .init(element: .water, modality: .cardinal),
        .init(element: .fire, modality: .fixed),
        .init(element: .earth, modality: .mutable),
        .init(element: .air, modality: .cardinal),
        .init(element: .water, modality: .fixed),
        .init(element: .fire, modality: .mutable),
        .init(element: .earth, modality: .cardinal),
        .init(element: .air, modality: .fixed),
        .init(element: .water, modality: .mutable),
    ]

    static let majorAspects: [AstroAspectDefinition] = [
        .init(type: .conjunction, symbol: "☌", nameVi: "Trùng tụ", targetAngle: 0, maxOrb: 8, nature: .neutral, baseWeight: 1),
        .init(type: .sextile, symbol: "⚹", nameVi: "Lục hợp", targetAngle: 60, maxOrb: 5, nature: .harmony, baseWeight: 0.7),
        .init(type: .square, symbol: "□", nameVi: "Vuông góc", targetAngle: 90, maxOrb: 7, nature: .tension, baseWeight: 1),
        .init(type: .trine, symbol: "△", nameVi: "Tam hợp", targetAngle: 120, maxOrb: 7, nature: .harmony, baseWeight: 0.9),
        .init(type: .opposition, symbol: "☍", nameVi: "Đối đỉnh", targetAngle: 180, maxOrb: 8, nature: .tension, baseWeight: 1),
    ]

    private static let planetOrder = [
        "Sun", "Moon", "Mercury", "Venus", "Mars",
        "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto",
    ]

    private static let fastPlanets: Set<String> = ["Sun", "Moon", "Mercury", "Venus", "Mars"]

    private static let transitActivityWeights: [String: Double] = [
        "Moon": 1,
        "Sun": 0.85,
        "Mercury": 0.85,
        "Venus": 0.85,
        "Mars": 0.85,
        "Jupiter": 0.45,
        "Saturn": 0.45,
        "Uranus": 0.25,
        "Neptune": 0.25,
        "Pluto": 0.25,
    ]

    static func resolveBirthDate(
        _ birthDate: String,
        birthTime: String? = nil,
        accuracy: BirthTimeAccuracy? = nil,
        location: ResolvedBirthLocation? = nil
    ) throws -> ResolvedBirthDate {
        let datePart = birthDate.split(separator: "T", maxSplits: 1).first.map(String.init) ?? birthDate
        let separator: Character? = datePart.contains("-") ? "-" : (datePart.contains("/") ? "/" : nil)
        var year = 2000
        var month = 1
        var day = 1

        if let separator {
            let values = datePart.split(separator: separator).compactMap { Int($0) }
            guard values.count >= 3 else { throw EngineError.invalidBirthDate(birthDate) }
            if separator == "-" {
                year = values[0]
                month = values[1]
                day = values[2]
            } else {
                day = values[0]
                month = values[1]
                year = values[2]
            }
        }

        var hour = 12
        var minute = 0
        var isTimeEstimated = true
        let effectiveAccuracy = accuracy
            ?? (birthTime?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? .exact : .unknown)
        if effectiveAccuracy == .exact,
           let birthTime,
           !birthTime.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            let values = birthTime
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .split(separator: ":")
                .compactMap { Int($0) }
            guard values.count >= 2,
                  (0 ... 23).contains(values[0]),
                  (0 ... 59).contains(values[1])
            else { throw EngineError.invalidBirthTime(birthTime) }
            hour = values[0]
            minute = values[1]
            isTimeEstimated = false
        }

        var calendar = Calendar(identifier: .gregorian)
        if let location {
            guard let timeZone = TimeZone(identifier: location.timeZoneIdentifier) else {
                throw EngineError.invalidTimeZone(location.timeZoneIdentifier)
            }
            calendar.timeZone = timeZone
        } else {
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        }
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: 0
        )
        guard let date = calendar.date(from: components),
              calendar.component(.year, from: date) == year,
              calendar.component(.month, from: date) == month,
              calendar.component(.day, from: date) == day,
              calendar.component(.hour, from: date) == hour,
              calendar.component(.minute, from: date) == minute
        else {
            if !isTimeEstimated, location != nil {
                throw EngineError.nonexistentLocalTime("\(birthDate) \(birthTime ?? "")")
            }
            throw EngineError.invalidBirthDate(birthDate)
        }

        var resolvedDate = date
        var isAmbiguous = false
        if !isTimeEstimated, location != nil,
           let startOfDay = calendar.date(from: DateComponents(year: year, month: month, day: day))
        {
            let matching = DateComponents(hour: hour, minute: minute, second: 0)
            let first = calendar.nextDate(
                after: startOfDay.addingTimeInterval(-1),
                matching: matching,
                matchingPolicy: .strict,
                repeatedTimePolicy: .first,
                direction: .forward
            )
            let last = calendar.nextDate(
                after: startOfDay.addingTimeInterval(-1),
                matching: matching,
                matchingPolicy: .strict,
                repeatedTimePolicy: .last,
                direction: .forward
            )
            if let first, let last,
               calendar.isDate(first, inSameDayAs: startOfDay),
               calendar.isDate(last, inSameDayAs: startOfDay)
            {
                resolvedDate = first
                isAmbiguous = first != last
            }
        }

        let precision: AstroBirthDataPrecision
        if isTimeEstimated {
            precision = .dateOnly
        } else if location == nil {
            precision = .timeWithoutLocation
        } else {
            precision = .complete
        }
        return ResolvedBirthDate(
            date: resolvedDate,
            isTimeEstimated: isTimeEstimated,
            precision: precision,
            isLocalTimeAmbiguous: isAmbiguous
        )
    }

    static func longitudeToZodiac(_ longitude: Double) -> (sign: String, signIndex: Int, degreeInSign: Double, normalized: Double) {
        let normalizedLongitude = positiveModulo(longitude, divisor: 360)
        let signIndex = Int(floor(normalizedLongitude / 30)) % zodiacSigns.count
        return (
            zodiacSigns[signIndex],
            signIndex,
            positiveModulo(normalizedLongitude, divisor: 30),
            rounded(normalizedLongitude / 360, places: 6)
        )
    }

    static func calculatePlanetaryChart(date: Date, isTimeEstimated: Bool = false) throws -> AstroPlanetaryChart {
        let time = AstronomyKit.AstroTime(date)
        let longitudes: [(String, Double)] = [
            ("Sun", try Sun.eclipticState(at: time).longitude),
            ("Moon", try Moon.eclipticState(at: time).longitude),
            ("Mercury", try CelestialBody.mercury.geocentricEclipticState(at: time).longitude),
            ("Venus", try CelestialBody.venus.geocentricEclipticState(at: time).longitude),
            ("Mars", try CelestialBody.mars.geocentricEclipticState(at: time).longitude),
            ("Jupiter", try CelestialBody.jupiter.geocentricEclipticState(at: time).longitude),
            ("Saturn", try CelestialBody.saturn.geocentricEclipticState(at: time).longitude),
            ("Uranus", try CelestialBody.uranus.geocentricEclipticState(at: time).longitude),
            ("Neptune", try CelestialBody.neptune.geocentricEclipticState(at: time).longitude),
            ("Pluto", try CelestialBody.pluto.geocentricEclipticState(at: time).longitude),
        ]
        let planetList = longitudes.map { name, longitude in
            let zodiac = longitudeToZodiac(longitude)
            return AstroPlanetPosition(
                name: name,
                longitude: longitude,
                sign: zodiac.sign,
                signIndex: zodiac.signIndex,
                degreeInSign: zodiac.degreeInSign,
                normalized: zodiac.normalized
            )
        }
        return AstroPlanetaryChart(
            targetDate: date,
            isTimeEstimated: isTimeEstimated,
            planets: Dictionary(uniqueKeysWithValues: planetList.map { ($0.name, $0) }),
            planetList: planetList
        )
    }

    static func computeNatalChart(_ input: AstroBirthInput) throws -> AstroPlanetaryChart {
        let resolved = try resolveBirthDate(
            input.birthDate,
            birthTime: input.birthTime,
            accuracy: input.birthTimeAccuracy,
            location: input.resolvedBirthLocation
        )
        return try calculatePlanetaryChart(date: resolved.date, isTimeEstimated: resolved.isTimeEstimated)
    }

    static func makeNatalSnapshot(input: AstroBirthInput, fingerprint: String) throws -> AstroNatalSnapshot {
        let resolved = try resolveBirthDate(
            input.birthDate,
            birthTime: input.birthTime,
            accuracy: input.birthTimeAccuracy,
            location: input.resolvedBirthLocation
        )
        let chart = try calculatePlanetaryChart(
            date: resolved.date,
            isTimeEstimated: resolved.isTimeEstimated
        )
        guard resolved.precision == .complete,
              let location = input.resolvedBirthLocation
        else {
            return AstroNatalSnapshot(
                fingerprint: fingerprint,
                engineVersion: engineVersion,
                chart: chart,
                context: nil
            )
        }
        let angles = calculateAngles(
            date: resolved.date,
            latitude: location.latitude,
            longitude: location.longitude
        )
        let cusps = calculatePorphyryCusps(angles: angles)
        let planetHouses = assignPlanetsToHouses(chart.planetList, cusps: cusps)
        let context = AstroNatalContext(
            birthUTC: resolved.date,
            angles: angles,
            houseCusps: cusps,
            planetHouses: planetHouses,
            precision: resolved.precision,
            isLocalTimeAmbiguous: resolved.isLocalTimeAmbiguous
        )
        return AstroNatalSnapshot(
            fingerprint: fingerprint,
            engineVersion: engineVersion,
            chart: chart,
            context: context
        )
    }

    static func calculateAngles(date: Date, latitude: Double, longitude: Double) -> AstroAngles {
        let julianDate = date.timeIntervalSince1970 / 86_400 + 2_440_587.5
        let centuries = (julianDate - 2_451_545.0) / 36_525
        let gmst = 280.460_618_37
            + 360.985_647_366_29 * (julianDate - 2_451_545.0)
            + 0.000_387_933 * centuries * centuries
            - centuries * centuries * centuries / 38_710_000
        let sidereal = degreesToRadians(positiveModulo(gmst + longitude, divisor: 360))
        let obliquity = degreesToRadians(
            23.439_291_111
                - 0.013_004_167 * centuries
                - 0.000_000_164 * centuries * centuries
                + 0.000_000_504 * centuries * centuries * centuries
        )
        let latitudeRadians = degreesToRadians(max(-89.999, min(89.999, latitude)))
        let midheaven = radiansToDegrees(atan2(sin(sidereal), cos(sidereal) * cos(obliquity)))
        let ascendant = radiansToDegrees(
            atan2(
                cos(sidereal),
                -(sin(sidereal) * cos(obliquity) + tan(latitudeRadians) * sin(obliquity))
            )
        )
        let asc = positiveModulo(ascendant, divisor: 360)
        let mc = positiveModulo(midheaven, divisor: 360)
        return AstroAngles(
            ascendant: rounded(asc, places: 6),
            descendant: rounded(positiveModulo(asc + 180, divisor: 360), places: 6),
            midheaven: rounded(mc, places: 6),
            imumCoeli: rounded(positiveModulo(mc + 180, divisor: 360), places: 6)
        )
    }

    static func calculatePorphyryCusps(angles: AstroAngles) -> [AstroHouseCusp] {
        var values = Array(repeating: 0.0, count: 12)
        values[0] = angles.ascendant
        values[3] = angles.imumCoeli
        values[6] = angles.descendant
        values[9] = angles.midheaven
        for startHouse in [0, 3, 6, 9] {
            let endHouse = (startHouse + 3) % 12
            let arc = positiveModulo(values[endHouse] - values[startHouse], divisor: 360)
            values[(startHouse + 1) % 12] = positiveModulo(values[startHouse] + arc / 3, divisor: 360)
            values[(startHouse + 2) % 12] = positiveModulo(values[startHouse] + arc * 2 / 3, divisor: 360)
        }
        return values.enumerated().map {
            AstroHouseCusp(house: $0.offset + 1, longitude: rounded($0.element, places: 6))
        }
    }

    static func house(for longitude: Double, cusps: [AstroHouseCusp]) -> Int? {
        guard cusps.count == 12 else { return nil }
        let ordered = cusps.sorted { $0.house < $1.house }
        let target = positiveModulo(longitude, divisor: 360)
        for index in ordered.indices {
            let start = ordered[index].longitude
            let end = ordered[(index + 1) % ordered.count].longitude
            let span = positiveModulo(end - start, divisor: 360)
            let offset = positiveModulo(target - start, divisor: 360)
            if offset < span || (span == 0 && offset == 0) {
                return ordered[index].house
            }
        }
        return nil
    }

    static func assignPlanetsToHouses(
        _ planets: [AstroPlanetPosition],
        cusps: [AstroHouseCusp]
    ) -> [String: Int] {
        Dictionary(uniqueKeysWithValues: planets.compactMap { planet in
            house(for: planet.longitude, cusps: cusps).map { (planet.name, $0) }
        })
    }

    static func calculateTemperamentBalance(_ planetList: [AstroPlanetPosition]) -> TemperamentBalance {
        var elementCounts: [AstroElement: Int] = [:]
        var modalityCounts: [AstroModality: Int] = [:]
        for planet in planetList where zodiacQualities.indices.contains(planet.signIndex) {
            let quality = zodiacQualities[planet.signIndex]
            elementCounts[quality.element, default: 0] += 1
            modalityCounts[quality.modality, default: 0] += 1
        }
        let total = Double(max(planetList.count, 1))
        return TemperamentBalance(
            fire: rounded(Double(elementCounts[.fire, default: 0]) / total),
            earth: rounded(Double(elementCounts[.earth, default: 0]) / total),
            air: rounded(Double(elementCounts[.air, default: 0]) / total),
            water: rounded(Double(elementCounts[.water, default: 0]) / total),
            cardinal: rounded(Double(modalityCounts[.cardinal, default: 0]) / total),
            fixed: rounded(Double(modalityCounts[.fixed, default: 0]) / total),
            mutable: rounded(Double(modalityCounts[.mutable, default: 0]) / total)
        )
    }

    static func shortestAngleDifference(_ lhs: Double, _ rhs: Double) -> Double {
        let difference = positiveModulo(abs(lhs - rhs), divisor: 360)
        return difference > 180 ? 360 - difference : difference
    }

    static func analyzeAspects(
        transitChart: AstroPlanetaryChart,
        natalChart: AstroPlanetaryChart
    ) -> AstroAspectAnalysis {
        var detected: [(index: Int, aspect: DetectedAstroAspect)] = []
        for transit in transitChart.planetList {
            for natal in natalChart.planetList {
                let angle = shortestAngleDifference(transit.longitude, natal.longitude)
                for definition in majorAspects {
                    let orb = abs(angle - definition.targetAngle)
                    guard orb <= definition.maxOrb else { continue }
                    let orbFactor = max(0, 1 - orb / definition.maxOrb)
                    detected.append((
                        detected.count,
                        DetectedAstroAspect(
                            transitPlanet: transit.name,
                            natalPlanet: natal.name,
                            type: definition.type,
                            symbol: definition.symbol,
                            nameVi: definition.nameVi,
                            targetAngle: definition.targetAngle,
                            actualAngle: rounded(angle, places: 2),
                            orb: rounded(orb, places: 2),
                            weight: rounded(definition.baseWeight * orbFactor),
                            nature: definition.nature
                        )
                    ))
                }
            }
        }

        let aspects = detected.sorted { lhs, rhs in
            let lhsWeight = lhs.aspect.weight * (transitActivityWeights[lhs.aspect.transitPlanet] ?? 0.25)
            let rhsWeight = rhs.aspect.weight * (transitActivityWeights[rhs.aspect.transitPlanet] ?? 0.25)
            if lhsWeight != rhsWeight { return lhsWeight > rhsWeight }
            if lhs.aspect.orb != rhs.aspect.orb { return lhs.aspect.orb < rhs.aspect.orb }
            return lhs.index < rhs.index
        }.map(\.aspect)
        let scores = calculateAspectScores(aspects)
        return AstroAspectAnalysis(
            aspects: aspects,
            topAspect: aspects.first,
            tensionScore: scores.tension,
            harmonyScore: scores.harmony,
            conjunctionIntensity: scores.conjunction,
            fastPlanetActivity: scores.fastPlanetActivity
        )
    }
/*aspects    Danh sách đã xếp hạng    Tất cả góc chiếu tìm được hôm nay, quan trọng nhất đứng đầu
 topAspect    aspects.first    Góc nổi bật nhất ngày hôm nay
 tensionScore    scores.tension    Mức căng thẳng, thử thách
 harmonyScore    scores.harmony    Mức hài hòa, thuận lợi
 conjunctionIntensity    scores.conjunction    Mức hội tụ năng lượng
 fastPlanetActivity    scores.fastPlanetActivity    Mức hoạt động của hành tinh nhanh*/
    static func calculateAspectScores(_ aspects: [DetectedAstroAspect]) -> AstroScoreMetadata {
        var weightedTension = 0.0
        var weightedHarmony = 0.0
        var weightedConjunction = 0.0
        var weightedFastActivity = 0.0
        var totalWeightedActivity = 0.0

        for aspect in aspects {
            let dailyWeight = aspect.weight * (transitActivityWeights[aspect.transitPlanet] ?? 0.25)
            totalWeightedActivity += dailyWeight
            switch aspect.nature {
            case .tension: weightedTension += dailyWeight
            case .harmony: weightedHarmony += dailyWeight
            case .neutral where aspect.type == .conjunction: weightedConjunction += dailyWeight
            case .neutral: break
            }
            if fastPlanets.contains(aspect.transitPlanet) {
                weightedFastActivity += dailyWeight
            }
        }

        let directionalTotal = weightedTension + weightedHarmony
        return AstroScoreMetadata(
            tension: directionalTotal > 0 ? clampedScore(weightedTension / directionalTotal) : 0,
            harmony: directionalTotal > 0 ? clampedScore(weightedHarmony / directionalTotal) : 0,
            conjunction: totalWeightedActivity > 0 ? clampedScore(weightedConjunction / totalWeightedActivity) : 0,
            fastPlanetActivity: totalWeightedActivity > 0 ? clampedScore(weightedFastActivity / totalWeightedActivity) : 0
        )
    }

    static func dominantSignal(tension: Double, harmony: Double, conjunction: Double) -> AstroDominantSignal {
        if conjunction >= 0.28 { return .conjunction }
        if tension - harmony >= 0.2 { return .tension }
        if harmony - tension >= 0.2 { return .harmony }
        return .balanced
    }

    static let houseTopicsVi: [Int: String] = [
        1: "Bản thân", 2: "Tài chính", 3: "Giao tiếp", 4: "Gia đình",
        5: "Tình cảm", 6: "Thói quen", 7: "Quan hệ", 8: "Chuyển hóa",
        9: "Học hỏi", 10: "Sự nghiệp", 11: "Cộng đồng", 12: "Nội tâm",
    ]

    static func analyzeAngleAspects(
        transitChart: AstroPlanetaryChart,
        angles: AstroAngles
    ) -> [AstroAngleAspect] {
        let targets = [("ASC", angles.ascendant), ("MC", angles.midheaven)]
        var result: [AstroAngleAspect] = []
        for transit in transitChart.planetList {
            for target in targets {
                let angle = shortestAngleDifference(transit.longitude, target.1)
                for definition in majorAspects {
                    let orb = abs(angle - definition.targetAngle)
                    let maximumOrb = min(3, definition.maxOrb)
                    guard orb <= maximumOrb else { continue }
                    let orbFactor = max(0, 1 - orb / maximumOrb)
                    result.append(
                        AstroAngleAspect(
                            transitPlanet: transit.name,
                            angle: target.0,
                            type: definition.type,
                            nameVi: definition.nameVi,
                            orb: rounded(orb, places: 2),
                            weight: rounded(definition.baseWeight * orbFactor),
                            nature: definition.nature
                        )
                    )
                }
            }
        }
        return result.sorted {
            let lhs = $0.weight * (transitActivityWeights[$0.transitPlanet] ?? 0.25)
            let rhs = $1.weight * (transitActivityWeights[$1.transitPlanet] ?? 0.25)
            if lhs != rhs { return lhs > rhs }
            return $0.orb < $1.orb
        }
    }

    static func makeDailyContext(
        transitChart: AstroPlanetaryChart,
        natalContext: AstroNatalContext,
        aspects: [DetectedAstroAspect]
    ) -> AstroDailyContext {
        let transitHouses = assignPlanetsToHouses(
            transitChart.planetList,
            cusps: natalContext.houseCusps
        )
        let angleAspects = analyzeAngleAspects(
            transitChart: transitChart,
            angles: natalContext.angles
        )
        var rawScores: [Int: Double] = [:]
        for (planet, house) in transitHouses {
            rawScores[house, default: 0] += transitActivityWeights[planet] ?? 0.25
        }
        for aspect in aspects {
            guard let house = natalContext.planetHouses[aspect.natalPlanet] else { continue }
            rawScores[house, default: 0] += aspect.weight
                * (transitActivityWeights[aspect.transitPlanet] ?? 0.25)
        }
        for aspect in angleAspects {
            let house = aspect.angle == "ASC" ? 1 : 10
            rawScores[house, default: 0] += aspect.weight
                * (transitActivityWeights[aspect.transitPlanet] ?? 0.25)
        }
        let maximum = rawScores.values.max() ?? 0
        let activated = rawScores
            .map { house, score in
                ActivatedHouseScore(
                    house: house,
                    score: maximum > 0 ? rounded(score / maximum) : 0,
                    topicVi: houseTopicsVi[house] ?? ""
                )
            }
            .sorted {
                if $0.score != $1.score { return $0.score > $1.score }
                return $0.house < $1.house
            }
        return AstroDailyContext(
            transitHouses: transitHouses,
            angleAspects: angleAspects,
            activatedHouses: Array(activated.prefix(3))
        )
    }

    static func generateVector(
        input: AstroBirthInput,
        currentDate: Date,
        natalSnapshot suppliedSnapshot: AstroNatalSnapshot? = nil
    ) throws -> AstroVectorResult {
        let natalSnapshot = try suppliedSnapshot ?? makeNatalSnapshot(input: input, fingerprint: "uncached")
        let natalChart = natalSnapshot.chart
        let transitChart = try calculatePlanetaryChart(date: currentDate)
        let aspectAnalysis = analyzeAspects(transitChart: transitChart, natalChart: natalChart)
        let dailyContext = natalSnapshot.context.map {
            makeDailyContext(
                transitChart: transitChart,
                natalContext: $0,
                aspects: aspectAnalysis.aspects
            )
        }
        let temperament = calculateTemperamentBalance(natalChart.planetList)
        var vector = Array(repeating: 0.0, count: 32)
        vector[0] = natalChart.isTimeEstimated ? 0.7 : 1

        for (index, name) in planetOrder.enumerated() {
            vector[1 + index] = natalChart.planets[name]?.normalized ?? 0
            vector[11 + index] = transitChart.planets[name]?.normalized ?? 0
        }
        vector[21] = temperament.fire
        vector[22] = temperament.earth
        vector[23] = temperament.air
        vector[24] = temperament.water
        vector[25] = temperament.cardinal
        vector[26] = temperament.fixed
        vector[27] = temperament.mutable
        vector[28] = aspectAnalysis.tensionScore
        vector[29] = aspectAnalysis.harmonyScore
        vector[30] = aspectAnalysis.conjunctionIntensity
        vector[31] = aspectAnalysis.fastPlanetActivity
        vector = vector.map { value in
            guard value.isFinite else { return 0 }
            return rounded(min(1, max(0, value)))
        }

        let elements: [(String, Double)] = [
            ("Lửa", temperament.fire),
            ("Đất", temperament.earth),
            ("Khí", temperament.air),
            ("Nước", temperament.water),
        ]
        let modalities: [(String, Double)] = [
            ("Tiên phong", temperament.cardinal),
            ("Kiên định", temperament.fixed),
            ("Linh hoạt", temperament.mutable),
        ]
        let signal = dominantSignal(
            tension: aspectAnalysis.tensionScore,
            harmony: aspectAnalysis.harmonyScore,
            conjunction: aspectAnalysis.conjunctionIntensity
        )
        let summaries: [AstroDominantSignal: String] = [
            .tension: "Các góc ma sát đang trội hơn, phù hợp với việc rà soát rủi ro và giữ lời nói rõ ràng.",
            .harmony: "Các góc hỗ trợ đang trội hơn, thuận lợi để chủ động kết nối và triển khai việc quan trọng.",
            .conjunction: "Năng lượng đang hội tụ mạnh, phù hợp để chọn một trọng tâm và làm đến nơi đến chốn.",
            .balanced: "Các dòng tác động đan xen khá cân bằng, phù hợp để duy trì nhịp sống và quan sát tín hiệu mới.",
        ]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let metadata = AstroFeatureMetadata(
            birthDate: input.birthDate,
            birthTime: input.birthTime,
            hasExactTime: !natalChart.isTimeEstimated,
            confidenceScore: vector[0],
            currentDateIso: formatter.string(from: currentDate),
            natalSunSign: natalChart.planets["Sun"]?.sign ?? "Unknown",
            natalMoonSign: natalChart.planets["Moon"]?.sign ?? "Unknown",
            transitMoonSign: transitChart.planets["Moon"]?.sign ?? "Unknown",
            temperament: AstroTemperamentMetadata(
                balance: temperament,
                dominantElement: firstMaximum(elements),
                dominantModality: firstMaximum(modalities)
            ),
            topAspect: aspectAnalysis.topAspect,
            totalAspectsCount: aspectAnalysis.aspects.count,
            scores: AstroScoreMetadata(
                tension: aspectAnalysis.tensionScore,
                harmony: aspectAnalysis.harmonyScore,
                conjunction: aspectAnalysis.conjunctionIntensity,
                fastPlanetActivity: aspectAnalysis.fastPlanetActivity
            ),
            dominantSignal: signal,
            vibeSummary: summaries[signal] ?? "",
            birthDataPrecision: natalSnapshot.context?.precision
                ?? (natalChart.isTimeEstimated ? .dateOnly : .timeWithoutLocation),
            natalContext: natalSnapshot.context,
            dailyContext: dailyContext
        )
        return AstroVectorResult(vector: vector, metadata: metadata)
    }

    static func cosineSimilarity(_ lhs: [Double], _ rhs: [Double]) -> Double {
        guard !lhs.isEmpty, lhs.count == rhs.count else { return 0 }
        var dotProduct = 0.0
        var lhsNorm = 0.0
        var rhsNorm = 0.0
        for index in lhs.indices {
            dotProduct += lhs[index] * rhs[index]
            lhsNorm += lhs[index] * lhs[index]
            rhsNorm += rhs[index] * rhs[index]
        }
        guard lhsNorm > 0, rhsNorm > 0 else { return 0 }
        return rounded(dotProduct / (sqrt(lhsNorm) * sqrt(rhsNorm)))
    }

    private static func firstMaximum(_ values: [(String, Double)]) -> String {
        values.dropFirst().reduce(values[0]) { best, candidate in
            candidate.1 > best.1 ? candidate : best
        }.0
    }

    private static func positiveModulo(_ value: Double, divisor: Double) -> Double {
        let result = value.truncatingRemainder(dividingBy: divisor)
        return result < 0 ? result + divisor : result
    }

    private static func rounded(_ value: Double, places: Int = 4) -> Double {
        let scale = pow(10, Double(places))
        return (value * scale).rounded() / scale
    }

    private static func clampedScore(_ value: Double) -> Double {
        rounded(min(1, max(0, value)))
    }

    private static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }

    private static func radiansToDegrees(_ radians: Double) -> Double {
        radians * 180 / .pi
    }
}
