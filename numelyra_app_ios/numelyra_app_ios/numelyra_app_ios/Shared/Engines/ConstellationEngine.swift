import Foundation
import SVGPath

nonisolated enum ConstellationEngine {
    static let maximumPathLength = 250_000
    static let maximumStars = 300

    static func dailySymbol(
        date: Date = .now,
        profileKey: String = "guest",
        calendar: Calendar = .autoupdatingCurrent,
        symbols: [ConstellationSymbolPreset] = ConstellationSymbolCatalog.all
    ) -> ConstellationSymbolPreset {
        precondition(!symbols.isEmpty, "The constellation catalog must not be empty.")

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let civilDate = utcCalendar.date(from: DateComponents(
            year: components.year,
            month: components.month,
            day: components.day
        )) ?? Date(timeIntervalSince1970: 0)
        let localDayNumber = Int64(floor(civilDate.timeIntervalSince1970 / 86_400))

        let normalizedProfileKey = profileKey
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(with: Locale(identifier: "vi_VN"))
        let profileHash = fnv1aUTF16(normalizedProfileKey.isEmpty ? "guest" : normalizedProfileKey)
        let dayHash = UInt32(truncatingIfNeeded: localDayNumber) &* 2_654_435_761
        let index = Int((profileHash &+ dayHash) % UInt32(symbols.count))
        return symbols[index]
    }

    static func buildGeometry(for symbol: ConstellationSymbolPreset) throws -> ConstellationGeometry {
        let pathData = symbol.pathData.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pathData.isEmpty else { throw ConstellationError.emptyPath }
        guard pathData.utf8.count <= maximumPathLength else { throw ConstellationError.pathTooLarge }
        guard symbol.viewBox.width > 0, symbol.viewBox.height > 0 else {
            throw ConstellationError.invalidViewBox
        }

        let options = symbol.sampling
        guard (2...300).contains(options.samplesPerContour),
              (0..<90).contains(options.straightToleranceDegrees),
              (0...10).contains(options.filterPasses),
              (2...100).contains(options.curveDetail)
        else {
            throw ConstellationError.invalidSampling
        }

        let parsedPath: SVGPath
        do {
            parsedPath = try SVGPath(
                string: pathData,
                with: .init(invertYAxis: false)
            )
        } catch {
            throw ConstellationError.invalidPath
        }

        let denseContours = flatten(
            parsedPath,
            curveDetail: options.curveDetail,
            closeOpenSubpaths: symbol.treatsSubpathsAsClosed
        )

        let contours = denseContours.compactMap { contour -> ConstellationContour? in
            guard contour.points.count >= 2 else { return nil }
            let sampled = sampleByArcLength(
                contour.points,
                intervals: options.samplesPerContour
            )
            let simplified = removeRepeatedClosedEndpoint(
                simplify(
                    sampled,
                    straightToleranceDegrees: options.straightToleranceDegrees,
                    passes: options.filterPasses
                )
            )
            guard simplified.count >= 2 else { return nil }
            return .init(points: simplified, isClosed: contour.isClosed)
        }

        let geometry = ConstellationGeometry(viewBox: symbol.viewBox, contours: contours)
        guard geometry.starCount > 0 else { throw ConstellationError.noUsableContours }
        guard geometry.starCount <= maximumStars else {
            throw ConstellationError.tooManyStars(geometry.starCount)
        }
        return geometry
    }

    static func fit(
        _ geometry: ConstellationGeometry,
        inside bounds: ConstellationBounds
    ) -> ConstellationGeometry {
        guard geometry.viewBox.width > 0, geometry.viewBox.height > 0,
              bounds.width > 0, bounds.height > 0
        else { return geometry }

        let scale = min(
            bounds.width / geometry.viewBox.width,
            bounds.height / geometry.viewBox.height
        )
        let renderedWidth = geometry.viewBox.width * scale
        let renderedHeight = geometry.viewBox.height * scale
        let offsetX = bounds.x + (bounds.width - renderedWidth) / 2
        let offsetY = bounds.y + (bounds.height - renderedHeight) / 2

        return .init(
            viewBox: .init(
                minX: bounds.x,
                minY: bounds.y,
                width: bounds.width,
                height: bounds.height
            ),
            contours: geometry.contours.map { contour in
                .init(
                    points: contour.points.map { point in
                        .init(
                            x: offsetX + (point.x - geometry.viewBox.minX) * scale,
                            y: offsetY + (point.y - geometry.viewBox.minY) * scale
                        )
                    },
                    isClosed: contour.isClosed
                )
            }
        )
    }

    static func ambientStars(seed: UInt32, count: Int) -> [AmbientStar] {
        guard count > 0 else { return [] }
        var state = seed
        func random() -> Double {
            state = state &* 1_664_525 &+ 1_013_904_223
            return Double(state) / 4_294_967_296
        }

        return (0..<count).map { _ in
            .init(
                x: random(),
                y: random(),
                radius: 0.45 + random() * 1.45,
                opacity: 0.25 + random() * 0.7
            )
        }
    }

    // MARK: - Path flattening

    private struct DenseContour {
        var points: [ConstellationPoint]
        var isClosed: Bool
    }

    private static func flatten(
        _ path: SVGPath,
        curveDetail: Int,
        closeOpenSubpaths: Bool
    ) -> [DenseContour] {
        var contours: [DenseContour] = []
        var points: [ConstellationPoint] = []
        var current = ConstellationPoint(x: 0, y: 0)
        var start: ConstellationPoint?

        func point(_ value: SVGPoint) -> ConstellationPoint {
            .init(x: value.x, y: value.y)
        }

        func samePoint(_ first: ConstellationPoint, _ second: ConstellationPoint) -> Bool {
            abs(first.x - second.x) < 0.0001 && abs(first.y - second.y) < 0.0001
        }

        func finish(closed: Bool) {
            guard points.count >= 2 else {
                points.removeAll(keepingCapacity: true)
                start = nil
                return
            }
            let shouldClose = closed || closeOpenSubpaths
            if shouldClose, let first = points.first, let last = points.last,
               !samePoint(first, last) {
                points.append(first)
            }
            contours.append(.init(points: points, isClosed: shouldClose))
            points.removeAll(keepingCapacity: true)
            start = nil
        }

        func appendCubic(
            from p0: ConstellationPoint,
            control1 p1: ConstellationPoint,
            control2 p2: ConstellationPoint,
            to p3: ConstellationPoint
        ) {
            for step in 1...curveDetail {
                let t = Double(step) / Double(curveDetail)
                let inverse = 1 - t
                points.append(.init(
                    x: inverse * inverse * inverse * p0.x
                        + 3 * inverse * inverse * t * p1.x
                        + 3 * inverse * t * t * p2.x
                        + t * t * t * p3.x,
                    y: inverse * inverse * inverse * p0.y
                        + 3 * inverse * inverse * t * p1.y
                        + 3 * inverse * t * t * p2.y
                        + t * t * t * p3.y
                ))
            }
        }

        func appendQuadratic(
            from p0: ConstellationPoint,
            control p1: ConstellationPoint,
            to p2: ConstellationPoint
        ) {
            for step in 1...curveDetail {
                let t = Double(step) / Double(curveDetail)
                let inverse = 1 - t
                points.append(.init(
                    x: inverse * inverse * p0.x + 2 * inverse * t * p1.x + t * t * p2.x,
                    y: inverse * inverse * p0.y + 2 * inverse * t * p1.y + t * t * p2.y
                ))
            }
        }

        func appendCommand(_ command: SVGCommand) {
            switch command {
            case let .moveTo(value):
                finish(closed: false)
                current = point(value)
                start = current
                points = [current]

            case let .lineTo(value):
                current = point(value)
                if points.isEmpty {
                    start = current
                    points.append(current)
                } else {
                    points.append(current)
                }

            case let .quadratic(control, end):
                let destination = point(end)
                appendQuadratic(from: current, control: point(control), to: destination)
                current = destination

            case let .cubic(control1, control2, end):
                let destination = point(end)
                appendCubic(
                    from: current,
                    control1: point(control1),
                    control2: point(control2),
                    to: destination
                )
                current = destination

            case let .arc(arc):
                let commands = arc.asBezierPath(from: .init(x: current.x, y: current.y))
                commands.forEach(appendCommand)

            case .end:
                if let start { current = start }
                finish(closed: true)
            }
        }

        path.commands.forEach(appendCommand)
        finish(closed: false)
        return contours
    }

    private static func sampleByArcLength(
        _ points: [ConstellationPoint],
        intervals: Int
    ) -> [ConstellationPoint] {
        guard points.count >= 2 else { return points }
        var cumulative = [0.0]
        cumulative.reserveCapacity(points.count)
        for index in 1..<points.count {
            cumulative.append(
                cumulative[index - 1] + distance(points[index - 1], points[index])
            )
        }
        guard let totalLength = cumulative.last, totalLength > 0, totalLength.isFinite else {
            return []
        }

        var result: [ConstellationPoint] = []
        result.reserveCapacity(intervals + 1)
        var segment = 1
        for index in 0...intervals {
            let target = Double(index) / Double(intervals) * totalLength
            while segment < cumulative.count - 1, cumulative[segment] < target {
                segment += 1
            }
            let lowerLength = cumulative[segment - 1]
            let upperLength = cumulative[segment]
            let span = upperLength - lowerLength
            let ratio = span > 0 ? (target - lowerLength) / span : 0
            let lower = points[segment - 1]
            let upper = points[segment]
            result.append(.init(
                x: lower.x + (upper.x - lower.x) * ratio,
                y: lower.y + (upper.y - lower.y) * ratio
            ))
        }
        return result
    }

    private static func simplify(
        _ points: [ConstellationPoint],
        straightToleranceDegrees: Double,
        passes: Int
    ) -> [ConstellationPoint] {
        var result = points
        for _ in 0..<passes {
            result = filterStraightPoints(result, toleranceDegrees: straightToleranceDegrees)
        }
        return result
    }

    private static func filterStraightPoints(
        _ points: [ConstellationPoint],
        toleranceDegrees: Double
    ) -> [ConstellationPoint] {
        guard points.count >= 3 else { return points }
        var excluded: Set<Int> = []
        var index = 0
        while index < points.count - 2 {
            let firstAngle = direction(from: points[index], to: points[index + 1])
            let secondAngle = direction(from: points[index + 2], to: points[index + 1])
            var difference = abs(firstAngle - secondAngle)
            if difference > .pi { difference = .pi * 2 - difference }
            if abs(180 - difference * 180 / .pi) < toleranceDegrees {
                excluded.insert(index + 1)
                index += 1
            }
            index += 1
        }
        return points.enumerated().compactMap { excluded.contains($0.offset) ? nil : $0.element }
    }

    private static func removeRepeatedClosedEndpoint(
        _ points: [ConstellationPoint],
        epsilon: Double = 0.01
    ) -> [ConstellationPoint] {
        guard let first = points.first, let last = points.last, points.count >= 2 else {
            return points
        }
        return distance(first, last) <= epsilon ? Array(points.dropLast()) : points
    }

    private static func direction(from: ConstellationPoint, to: ConstellationPoint) -> Double {
        let angle = atan2(to.y - from.y, to.x - from.x)
        return angle < 0 ? angle + .pi * 2 : angle
    }

    private static func distance(_ first: ConstellationPoint, _ second: ConstellationPoint) -> Double {
        hypot(first.x - second.x, first.y - second.y)
    }

    private static func fnv1aUTF16(_ value: String) -> UInt32 {
        var hash: UInt32 = 2_166_136_261
        for codeUnit in value.utf16 {
            hash ^= UInt32(codeUnit)
            hash = hash &* 16_777_619
        }
        return hash
    }
}
