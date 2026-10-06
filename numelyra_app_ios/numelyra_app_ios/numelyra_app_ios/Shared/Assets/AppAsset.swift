import SwiftUI

/// Type-safe names for assets already transferred from the React Native app.
enum AppAsset: String, CaseIterable, Sendable {
    case authMascot = "AuthMascot"

    case tabChat = "TabChat"
    case tabCalendar = "TabCalendar"
    case tabWallpaper = "TabWallpaper"
    case tabSettings = "TabSettings"

    case chatSceneSky = "ChatSceneSky"
    case chatSceneMountains = "ChatSceneMountains"
    case chatSceneForeground = "ChatSceneForeground"
    case chatSceneStars = "ChatSceneStars"
    case chatSceneMoon = "ChatSceneMoon"

    case chatFlameIdleSprite = "ChatFlameIdleSprite"
    case chatFlameThinkingSprite = "ChatFlameThinkingSprite"
    case chatFlameAnswerSprite = "ChatFlameAnswerSprite"
    case chatVIPBadge = "ChatVIPBadge"
    case chatAmbientGlow = "ChatAmbientGlow"

    var image: Image {
        Image(rawValue)
    }
}

extension Image {
    init(appAsset: AppAsset) {
        self.init(appAsset.rawValue)
    }
}
