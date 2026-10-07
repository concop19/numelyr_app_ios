import ComposableArchitecture
import Foundation

@Reducer
struct AstrologyInsightFeature {
    @ObservableState
    struct State: Equatable, Sendable {
        var fortune: AstroFortuneSlip
        var metadata: AstroFeatureMetadata?

        init(fortune: AstroFortuneSlip, metadata: AstroFeatureMetadata? = nil) {
            self.fortune = fortune
            self.metadata = metadata ?? fortune.astroMetadata
        }

        var sheetTitle: String {
            AstrologyInsightFeature.normalizedTitle(fortune.title)
        }

        var birthDescriptionText: String? {
            guard let metadata else { return nil }
            return AstrologyInsightFeature.birthDescription(for: metadata)
        }

        var anchorCategoryText: String? {
            guard let category = fortune.anchorCaDao.category?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  !category.isEmpty
            else {
                return nil
            }
            return category
        }

        var hasAnchorCaDao: Bool {
            !fortune.anchorCaDao.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    enum Action: Equatable, Sendable {
        case closeTapped
    }

    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .closeTapped:
                return .run { _ in await dismiss() }
            }
        }
    }

    // MARK: - Pure Formatting & Localization Helpers (Parity with AstrologyInsightSheet.tsx)

    nonisolated static let zodiacViMap: [String: String] = [
        "Aries": "Bạch Dương ♈",
        "Taurus": "Kim Ngưu ♉",
        "Gemini": "Song Tử ♊",
        "Cancer": "Cự Giải ♋",
        "Leo": "Sư Tử ♌",
        "Virgo": "Xử Nữ ♍",
        "Libra": "Thiên Bình ♎",
        "Scorpio": "Bọ Cạp ♏",
        "Sagittarius": "Nhân Mã ♐",
        "Capricorn": "Ma Kết ♑",
        "Aquarius": "Bảo Bình ♒",
        "Pisces": "Song Ngư ♓",
    ]

    nonisolated static let planetViMap: [String: String] = [
        "Sun": "Mặt Trời",
        "Moon": "Mặt Trăng",
        "Mercury": "Sao Thủy",
        "Venus": "Sao Kim",
        "Mars": "Sao Hỏa",
        "Jupiter": "Sao Mộc",
        "Saturn": "Sao Thổ",
        "Uranus": "Sao Thiên Vương",
        "Neptune": "Sao Hải Vương",
        "Pluto": "Sao Diêm Vương",
    ]

    nonisolated static func zodiacVi(_ sign: String) -> String {
        zodiacViMap[sign] ?? sign
    }

    nonisolated static func planetVi(_ planet: String) -> String {
        planetViMap[planet] ?? planet
    }

    nonisolated static func normalizedTitle(_ title: String?) -> String {
        guard let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty
        else {
            return "Quẻ hôm nay"
        }
        return trimmed
    }

    nonisolated static func birthDescription(for metadata: AstroFeatureMetadata) -> String {
        if let birthTime = metadata.birthTime?.trimmingCharacters(in: .whitespacesAndNewlines),
           !birthTime.isEmpty
        {
            return "Dựa trên ngày sinh \(metadata.birthDate) lúc \(birthTime)."
        }
        return "Dựa trên ngày sinh \(metadata.birthDate) với giờ sinh ước lượng."
    }

    nonisolated static func temperamentSummary(for metadata: AstroFeatureMetadata) -> String {
        "\(metadata.temperament.dominantElement) · \(metadata.temperament.dominantModality)"
    }

    nonisolated static func aspectFormula(for aspect: DetectedAstroAspect) -> String {
        "\(planetVi(aspect.transitPlanet)) · \(aspect.nameVi) · \(planetVi(aspect.natalPlanet))"
    }

    nonisolated static func aspectMeta(for aspect: DetectedAstroAspect) -> String {
        String(
            format: "Góc %.0f° · Sai số %.1f°",
            locale: Locale(identifier: "en_US_POSIX"),
            aspect.actualAngle,
            aspect.orb
        )
    }

    nonisolated static func scorePercent(_ value: Double) -> Int {
        guard value.isFinite else { return 0 }
        let rounded = Int((value * 100).rounded())
        return min(100, max(0, rounded))
    }
}
