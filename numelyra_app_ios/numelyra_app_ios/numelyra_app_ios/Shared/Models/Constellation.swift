import Foundation

struct ConstellationSamplingOptions: Equatable, Sendable {
    var samplesPerContour = 42
    var straightToleranceDegrees = 16.0
    var filterPasses = 5
    var curveDetail = 20
}

struct ConstellationSymbolPreset: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let pathData: String
    var viewBox = ConstellationViewBox(minX: 0, minY: 0, width: 24, height: 24)
    var treatsSubpathsAsClosed = true
    var sampling = ConstellationSamplingOptions()
}

struct ConstellationPoint: Equatable, Sendable {
    var x: Double
    var y: Double
}

struct ConstellationViewBox: Equatable, Sendable {
    var minX: Double
    var minY: Double
    var width: Double
    var height: Double
}

struct ConstellationContour: Equatable, Sendable {
    var points: [ConstellationPoint]
    var isClosed: Bool
}

struct ConstellationGeometry: Equatable, Sendable {
    var viewBox: ConstellationViewBox
    var contours: [ConstellationContour]

    var starCount: Int {
        contours.reduce(0) { $0 + $1.points.count }
    }
}

struct ConstellationBounds: Equatable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

struct AmbientStar: Equatable, Sendable {
    var x: Double
    var y: Double
    var radius: Double
    var opacity: Double
}

enum ConstellationError: Error, Equatable, LocalizedError {
    case emptyPath
    case pathTooLarge
    case invalidViewBox
    case invalidSampling
    case invalidPath
    case noUsableContours
    case tooManyStars(Int)

    var errorDescription: String? {
        switch self {
        case .emptyPath:
            return "SVG không có path hợp lệ để dựng chòm sao."
        case .pathTooLarge:
            return "SVG vượt quá giới hạn 250 KB."
        case .invalidViewBox:
            return "viewBox của SVG không hợp lệ."
        case .invalidSampling:
            return "Cấu hình lấy mẫu chòm sao không hợp lệ."
        case .invalidPath:
            return "Có path SVG không thể được phân tích."
        case .noUsableContours:
            return "SVG không tạo ra đủ điểm chòm sao."
        case let .tooManyStars(count):
            return "Chòm sao có \(count) điểm, vượt quá giới hạn 300 điểm."
        }
    }
}
