import ComposableArchitecture
import Foundation
import Photos
import UIKit

nonisolated enum WallpaperClientError: LocalizedError, Equatable, Sendable {
    case invalidResponse
    case server(statusCode: Int, message: String?)
    case noImage
    case invalidImage
    case photosPermissionDenied

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Dữ liệu hình nền từ máy chủ không hợp lệ."
        case let .server(statusCode, message):
            return message ?? "Máy chủ phản hồi mã \(statusCode)."
        case .noImage:
            return "Máy chủ chưa trả về hình nền nào."
        case .invalidImage:
            return "Không thể chuẩn bị ảnh để lưu."
        case .photosPermissionDenied:
            return "Cần cấp quyền thêm ảnh để lưu hình nền."
        }
    }
}

nonisolated struct WallpaperSaveResult: Equatable, Sendable {
    var message: String
}

@DependencyClient
nonisolated struct WallpaperClient: Sendable {
    var randomStyle: @Sendable () -> WallpaperStyleOption = {
        WallpaperStyleOption.allStyles[0]
    }
    var randomIntention: @Sendable () -> WallpaperIntentionOption = {
        WallpaperIntentionOption.allIntentions[0]
    }
    var generate: @Sendable (_ request: LuckyWallpaperRequest) async throws -> [WallpaperItem]
    var save: @Sendable (_ item: WallpaperItem) async throws -> WallpaperSaveResult
}

extension WallpaperClient: DependencyKey {
    static var liveValue: Self {
        @Dependency(\.supabaseClient) var supabaseClient

        return Self(
            randomStyle: {
                WallpaperStyleOption.allStyles.randomElement() ?? WallpaperStyleOption.allStyles[0]
            },
            randomIntention: {
                WallpaperIntentionOption.allIntentions.randomElement() ?? WallpaperIntentionOption.allIntentions[0]
            },
            generate: { request in
                let accessToken = await supabaseClient.accessToken()
                return try await requestWallpapers(request, accessToken: accessToken)
            },
            save: { item in
                try await saveToPhotoLibrary(item)
            }
        )
    }

    static let previewValue = Self(
        randomStyle: { WallpaperStyleOption.allStyles[4] },
        randomIntention: { WallpaperIntentionOption.allIntentions[2] },
        generate: { request in
            previewItems(prompt: request.customWish)
        },
        save: { _ in
            WallpaperSaveResult(message: "✨ Đã lưu hình nền may mắn vào bộ sưu tập!")
        }
    )

    static let testValue = Self()
}

extension DependencyValues {
    var wallpaperClient: WallpaperClient {
        get { self[WallpaperClient.self] }
        set { self[WallpaperClient.self] = newValue }
    }
}

extension WallpaperClient {
    private static func requestWallpapers(
        _ payload: LuckyWallpaperRequest,
        accessToken: String?
    ) async throws -> [WallpaperItem] {
        var urlRequest = URLRequest(url: AppConfig.luckyWallpaperURL)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 60
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accessToken, !accessToken.isEmpty {
            urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        urlRequest.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WallpaperClientError.invalidResponse
        }
        let decoded = try? JSONDecoder().decode(LuckyWallpaperResponse.self, from: data)
        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw WallpaperClientError.server(
                statusCode: httpResponse.statusCode,
                message: decoded?.error
            )
        }
        guard let decoded, decoded.success else {
            throw WallpaperClientError.server(
                statusCode: httpResponse.statusCode,
                message: decoded?.error
            )
        }

        let rawURLs = (decoded.imageUrls?.isEmpty == false ? decoded.imageUrls : nil)
            ?? decoded.imageUrl.map { [$0] }
            ?? []
        guard !rawURLs.isEmpty else { throw WallpaperClientError.noImage }

        let affirmation = decoded.affirmationVi
            ?? fallbackAffirmation(lifePath: payload.lifePathNumber, intention: payload.intentionId)
        let explanation = decoded.explanationVi
            ?? "Hội tụ năng lượng số \(payload.lifePathNumber) với phong cách đã chọn."
        let colors = decoded.luckyColorsVi?.isEmpty == false
            ? decoded.luckyColorsVi!
            : ["Vàng hoàng kim", "Tím huyền bí"]
        let styleName = decoded.style?.nameVi
            ?? WallpaperStyleOption.allStyles.first(where: { $0.id == payload.styleId })?.label
            ?? payload.styleId
        let intentionName = decoded.intention?.nameVi
            ?? WallpaperIntentionOption.allIntentions.first(where: { $0.id == payload.intentionId })?.label
            ?? payload.intentionId

        return rawURLs.prefix(payload.count).enumerated().compactMap { index, rawURL in
            guard let resolvedURL = resolve(rawURL) else { return nil }
            return WallpaperItem(
                id: "ai-\(UUID().uuidString)-\(index)",
                imageUrl: resolvedURL.absoluteString,
                title: "\(payload.customWish) • Bản #\(index + 1)",
                affirmationVi: affirmation,
                explanationVi: explanation,
                luckyColorsVi: colors,
                styleName: styleName,
                intentionName: intentionName
            )
        }
    }

    private static func resolve(_ rawURL: String) -> URL? {
        if let url = URL(string: rawURL), url.scheme != nil { return url }
        return URL(string: rawURL, relativeTo: AppConfig.apiBaseURL)?.absoluteURL
    }

    private static func fallbackAffirmation(lifePath: Int, intention: String) -> String {
        let messages: [Int: String] = [
            1: "Tôi tự tin tiên phong mở lối, ánh sáng vũ trụ dẫn đường thành công.",
            2: "Trực giác an tĩnh dẫn dắt tôi đến sự hài hòa và kết nối sâu sắc.",
            3: "Nguồn cảm hứng vô tận tuôn trào, niềm vui lan tỏa muôn nơi.",
            4: "Nền tảng vững chãi, kiên định tạo dựng tương lai bình an và giàu có.",
            5: "Tự do chuyển hóa, đón nhận muôn ngàn phước lành bất ngờ từ vũ trụ.",
            6: "Tình yêu thương vô điều kiện và vẻ đẹp nuôi dưỡng trọn vẹn tâm hồn.",
            7: "Minh triết nội tâm soi sáng mọi nẻo đường tôi bước qua.",
            8: "Thịnh vượng tài chính và quyền năng cá nhân thức tỉnh trọn vẹn.",
            9: "Lòng trắc ẩn bao la mở ra chu kỳ mới ngập tràn ánh sáng và may mắn."
        ]
        let intentionLabel = WallpaperIntentionOption.allIntentions
            .first(where: { $0.id == intention })?.label ?? intention
        return "\(messages[lifePath] ?? messages[8]!) (Ý niệm: \(intentionLabel))"
    }

    private static func saveToPhotoLibrary(_ item: WallpaperItem) async throws -> WallpaperSaveResult {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw WallpaperClientError.photosPermissionDenied
        }

        let image: UIImage
        if let assetName = item.bundledAssetName {
            guard let bundled = UIImage(named: assetName) else {
                throw WallpaperClientError.invalidImage
            }
            image = bundled
        } else {
            guard let url = URL(string: item.imageUrl) else {
                throw WallpaperClientError.invalidImage
            }
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200 ... 299).contains(http.statusCode),
                  let downloaded = UIImage(data: data)
            else {
                throw WallpaperClientError.invalidImage
            }
            image = downloaded
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
        return WallpaperSaveResult(message: "✨ Đã lưu hình nền may mắn vào bộ sưu tập!")
    }

    static func previewItems(prompt: String = "Falling asleep...") -> [WallpaperItem] {
        let assetNames = [
            "WallpaperMockCard1",
            "WallpaperMockCard2",
            "WallpaperMockCard3",
            "WallpaperMockCard4"
        ]
        return assetNames.enumerated().map { index, assetName in
            WallpaperItem(
                id: "preview-\(index)",
                imageUrl: "asset://\(assetName)",
                title: "\(prompt) • Bản #\(index + 1)",
                affirmationVi: "Vũ trụ ban tặng sự bình yên tuyệt đối và may mắn vĩnh cửu.",
                explanationVi: "Màu sắc và biểu tượng được phối theo nhịp năng lượng cá nhân của bạn.",
                luckyColorsVi: ["Tím hoàng hôn", "Vàng ánh trăng"],
                styleName: "Thiên nhiên mộng mơ",
                intentionName: "An lạc & Chữa lành"
            )
        }
    }
}

extension WallpaperItem {
    var bundledAssetName: String? {
        guard imageUrl.hasPrefix("asset://") else { return nil }
        return String(imageUrl.dropFirst("asset://".count))
    }
}
