import SwiftUI

// Feature-level semantic tokens live under AppTheme so views never need to
// decode colors or redefine gradients. Values remain grouped by feature to
// avoid coupling unrelated roles just because they currently share a swatch.

extension AppTheme.Colors {
    enum Auth {
        static let safeAreaBackground = Color(hex: 0xFFF4EC)
        static let cardBackground = Color(hex: 0xFFFDFB)
        static let cardBorder = Color.clear
        static let cardShadow = Color(hex: 0xC65A35, opacity: 0.16)
        static let eyebrow = Color(hex: 0xA54A3A)
        static let brand = Color(hex: 0xF04435)
        static let tagline = Color(hex: 0xCE633C)
        static let description = Color(hex: 0x8E5E58)
        static let googleBackground = Color.white
        static let googleBorder = Color(hex: 0xE8D2CA)
        static let googleBadgeRed = Color(hex: 0xEA4335)
        static let googleButtonText = Color(hex: 0x3C4043)
        static let googleShadow = Color(hex: 0xC65A35, opacity: 0.10)
        static let dividerLine = Color(hex: 0xF1CFC7)
        static let dividerText = Color(hex: 0xB68179)
        static let inputBackground = Color(hex: 0xFFF9F5)
        static let inputBorder = Color(hex: 0xF1CFC7)
        static let inputText = Color(hex: 0x5B302B)
        static let placeholder = Color(hex: 0xB68179)
        static let cursorTint = Color(hex: 0xF04435)
        static let showPasswordText = Color(hex: 0xD45B3B)
        static let submitBackground = Color(hex: 0xF04A38)
        static let submitText = Color(hex: 0xFFF9F5)
        static let submitShadow = Color.clear
        static let modeEmphasis = Color(hex: 0xEC4938)
        static let guestText = Color(hex: 0xA54A3A)
        static let warningText = Color(hex: 0xA33126)
        static let errorText = Color(hex: 0xA33126)
        static let successText = Color(hex: 0x3D7A50)
    }

    enum Calendar {
        static let background = AppTheme.Colors.backgroundElevated
        static let text = Color(hex: 0xFFF0FF)
        static let gold = Color(hex: 0xFFD793)
        static let pink = Color(hex: 0xF5B8E8)
        static let hotPink = Color(hex: 0xFF88C6)
        static let monthChip = Color(hex: 0x301464)
        static let purpleBorder = Color(hex: 0x9147C6)
    }

    enum Wallpaper {
        static let background = Color(hex: 0x211438)
        static let deepPurple = background
        static let gold = Color(hex: 0xF7CC6A)
        static let mutedText = AppTheme.Colors.inputPlaceholder
    }

    enum NumerologyCards {
        static let background = Color(hex: 0x070913)
        static let headerBorder = Color(hex: 0xD4AF37, opacity: 0.20)
        static let goldPrimary = Color(hex: 0xE5A93C)
        static let goldHighlight = Color(hex: 0xFCD34D)
        static let bannerBg = Color(hex: 0xE5A93C, opacity: 0.10)
        static let bannerBorder = Color(hex: 0xE5A93C, opacity: 0.20)
        static let bannerText = Color(hex: 0xFDE68A)
        static let tabActiveBg = Color(hex: 0xE5A93C, opacity: 0.20)
        static let cardContainerBg = Color(hex: 0x0F1528)
        static let cardBorder = Color(hex: 0xE5A93C, opacity: 0.22)
        static let imageFrameBg = Color(hex: 0x1E293B)
        static let badgeOverlayBg = Color(hex: 0x05070F, opacity: 0.85)
        static let numBadgeBorder = Color(hex: 0xD4AF37, opacity: 0.40)
        static let valueOverlayBg = Color(hex: 0x070A16, opacity: 0.92)
        static let valueOverlayBorder = Color(hex: 0xE5A93C, opacity: 0.30)
        static let valueOverlayMasterBg = Color(hex: 0x581C87, opacity: 0.92)
        static let valueOverlayMasterBorder = Color(hex: 0xA78BFA)
        static let masterValueText = Color(hex: 0xFEF08A)
    }

    enum IndicatorDetail {
        static let modalBackground = Color(hex: 0x0D1224)
        static let modalBorder = Color(hex: 0xD4AF37, opacity: 0.28)
        static let numberBadgeBg = Color(hex: 0xD4AF37, opacity: 0.15)
        static let numberBadgeBorder = Color(hex: 0xD4AF37, opacity: 0.35)
        static let goldPrimary = Color(hex: 0xE5A93C)
        static let goldText = Color(hex: 0xFCD34D)
        static let imagePlaceholder = Color(hex: 0x1E293B)
        static let cardImageBorder = Color(hex: 0xE5A93C, opacity: 0.45)
        static let cardGlowOverlay = Color(hex: 0xE5A93C, opacity: 0.04)
        static let valuePillBg = Color(hex: 0xE5A93C, opacity: 0.18)
        static let masterPillBg = Color(hex: 0xF59E0B, opacity: 0.30)
        static let masterPillBorder = Color(hex: 0xF59E0B)
        static let masterValueText = Color(hex: 0xFEF08A)
        static let masterTagBg = Color(hex: 0x7C3AED)
        static let masterTagText = Color(hex: 0xEDE9FE)
        static let cyanIcon = Color(hex: 0x7DD3FC)
        static let greenBullet = Color(hex: 0x34D399)
        static let purpleIcon = Color(hex: 0xC4B5FD)
        static let redBullet = Color(hex: 0xF87171)
        static let mintIcon = Color(hex: 0xA7F3D0)
        static let adviceBg = Color(hex: 0xE5A93C, opacity: 0.08)
        static let adviceBorder = Color(hex: 0xE5A93C, opacity: 0.25)
        static let adviceBodyText = Color(hex: 0xFEF3C7)
        static let expandBlue = Color(hex: 0x93C5FD)
        static let footerBtnText = Color(hex: 0x0A0E1A)
    }

    enum Astrology {
        static let background = Color(hex: 0x02091D)
        static let videoTint = Color(hex: 0x000D32)
        static let bottomFade = Color(hex: 0x02081D)
        static let titleGlow = Color(hex: 0x41C7FF)
        static let accent = Color(hex: 0x7CEBFF)
        static let headerText = Color(hex: 0xF2F8FF)
        static let geometryErrorText = Color(hex: 0xDDF8FF)
        static let symbolLabel = Color(hex: 0x6DEBFF)
        static let progress = Color(hex: 0x71E7FF)
        static let loadingText = Color(hex: 0xE2F7FF)
        static let errorText = Color(hex: 0xF4F9FF)
        static let buttonText = Color(hex: 0xE7FBFF)
        static let buttonTextStrong = Color(hex: 0xF5FCFF)
        static let retryBackground = Color(hex: 0x0F6097)
        static let errorCardBackground = Color(hex: 0x031339)
        static let actionBackground = Color(hex: 0x031846)
        static let actionBorder = Color(hex: 0x5BBEFF)
        static let actionGlow = Color(hex: 0x21BFFF)

        static let sheetDragHandle = Color(hex: 0xBEE8FF)
        static let mirrorIcon = Color(hex: 0xA78BFA)
        static let adviceIcon = Color(hex: 0x5EEAD4)
        static let sheetBorder = Color(hex: 0x68DCFF)
        static let closeText = Color(hex: 0xE7F7FF)
        static let closeBackground = Color(hex: 0x55A4D9)
        static let closeBorder = Color(hex: 0x98E1FF)
        static let headerDivider = Color(hex: 0x7ED8FF)
        static let insightTitle = Color(hex: 0xF4F7FF)
        static let insightBody = Color(hex: 0xD5E0F2)
        static let insightCardBackground = Color(hex: 0x1E2C5B)
        static let insightCardBorder = Color(hex: 0x83B7FF)
        static let sectionTitle = Color(hex: 0x77E8FF)
        static let sectionBody = Color(hex: 0xAFC3D9)
        static let dataLabel = Color(hex: 0x9EB4CC)
        static let transitCardBackground = Color(hex: 0x194A6F)
        static let aspectTitle = Color(hex: 0xC4A7FF)
        static let aspectMeta = Color(hex: 0xB5A9CE)
        static let aspectCardBackground = Color(hex: 0x493577)
        static let aspectCardBorder = Color(hex: 0xC19CFF)
        static let tensionScore = Color(hex: 0xFB7185)
        static let conjunctionScore = Color(hex: 0xFBBF24)
        static let scoreCardBackground = Color(hex: 0x101E46)
        static let caDaoText = Color(hex: 0xE3ECF8)
        static let sectionDivider = Color(hex: 0x6FCDFF)
        static let dataCardBackground = Color(hex: 0x253667)
        static let scoreLabel = Color(hex: 0xC8D5E6)

        static let constellationLabel = Color(red: 0.43, green: 0.92, blue: 1)
        static let ambientStar = Color(red: 0.84, green: 0.96, blue: 1)
        static let constellationGlow = Color(red: 0.15, green: 0.75, blue: 1)
        static let constellationStroke = Color(red: 0.89, green: 0.98, blue: 1)
        static let starHaloShadow = Color(red: 0.09, green: 0.77, blue: 1)
        static let starHalo = Color(red: 0.07, green: 0.75, blue: 1)
        static let starMiddleShadow = Color(red: 0.66, green: 0.95, blue: 1)
        static let starMiddle = Color(red: 0.35, green: 0.87, blue: 1)
        static let starRays = Color(red: 0.91, green: 0.98, blue: 1)
        static let constellationPreviewBackground = Color(red: 0.01, green: 0.04, blue: 0.12)
    }

    enum Settings {
        static let safeAreaBackground = Color(hex: 0x0E092B)
        static let moonColor = Color(hex: 0xFFE7A0)
        static let starOneColor = Color(hex: 0xF8B7FF)
        static let starTwoColor = Color(hex: 0xFFE29A)
        static let starThreeColor = Color(hex: 0xFFD779)
        static let orbitBorder = Color(hex: 0xEB9DFF, opacity: 0.32)
        static let titleText = Color(hex: 0xFCF5FF)
        static let subtitleText = Color(hex: 0xB8A8D8)
        static let groupTitleText = Color(hex: 0xE4D5FF)
        static let hintText = Color(hex: 0xBBAED6)
        static let standardCardBorder = AppTheme.Colors.cardBorder
        static let proCardBorder = Color(hex: 0xB86FE2, opacity: 0.70)
        static let standardCardShadow = Color(hex: 0x1A063A, opacity: 0.94)
        static let proCardShadow = Color(hex: 0x25074A, opacity: 0.98)
        static let profileIconTint = Color(hex: 0xF4B8FF)
        static let profileIconBackground = Color(hex: 0x8B3A9D, opacity: 0.31)
        static let profileIconBorder = Color(hex: 0xEDA0FF, opacity: 0.45)
        static let switchActiveTrack = AppTheme.Colors.primary
        static let rowDivider = AppTheme.Colors.divider
        static let actionBorder = Color(hex: 0xFFD573, opacity: 0.64)
        static let actionText = Color(hex: 0xFFE08A)
        static let primaryActionShadow = Color(hex: 0x2A0A57, opacity: 0.82)
        static let dangerActionShadow = Color(hex: 0x4B104E, opacity: 0.82)
        static let inlineActionBackground = Color(hex: 0x492677, opacity: 0.68)
        static let inlineActionBorder = Color(hex: 0xFFD36E, opacity: 0.52)
        static let inlineActionShadow = Color(hex: 0x190632, opacity: 0.76)
        static let crownBackground = Color(hex: 0x282057)
        static let crownBorder = Color(hex: 0xC88CF1)
        static let crownSymbolColor = Color(hex: 0xFFD36E)
        static let cardTitleGold = Color(hex: 0xFFD16D)
        static let planBadgeInactiveBackground = Color(hex: 0x27204A)
        static let planBadgeInactiveBorder = Color(hex: 0x66518E)
        static let planBadgeInactiveText = Color(hex: 0xC7B9E4)
        static let planBadgeActiveBorder = Color(hex: 0xFFD77F)
        static let planBadgeActiveText = Color(hex: 0x110F20)
        static let paymentSectionLabel = Color(hex: 0xC6B8E3)
        static let paymentUnselectedBackground = Color(hex: 0x25104A)
        static let paymentSelectedBackground = Color(hex: 0x3C1A60)
        static let paymentUnselectedBorder = Color(hex: 0x804DB7, opacity: 0.62)
        static let paymentSelectedBorder = Color(hex: 0xFFD25F)
        static let paymentUnselectedShadow = Color(hex: 0x17052F, opacity: 0.78)
        static let paymentSelectedShadow = Color(hex: 0x2A0B52, opacity: 0.90)
        static let paymentUnselectedIcon = Color(hex: 0xB6AFC9)
        static let paymentTitleText = Color(hex: 0xF2EAFB)
        static let paymentDetailText = Color(hex: 0xADA2C5)
        static let paymentSelectedText = Color(hex: 0xF5D27B)
        static let radioBorder = Color(hex: 0x72589B)
        static let radioInnerDot = Color(hex: 0x4D2B60)
        static let upgradeButtonBorder = Color(hex: 0xFFF1AA)
        static let upgradeButtonText = Color(hex: 0x211443)
        static let upgradeButtonShadow = Color(hex: 0xE4A039, opacity: 0.58)
        static let warningText = AppTheme.Colors.warning
        static let errorText = AppTheme.Colors.errorSoft
        static let refreshText = Color(hex: 0xC6BDD9)
    }
}

extension AppTheme.Gradients {
    enum Calendar {
        static let goldGradient = AppTheme.Gradients.goldAction
        static let circleGradient = LinearGradient(
            colors: [Color(hex: 0x4A2D82), Color(hex: 0x30195F), Color(hex: 0x1D103F)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let cardGradient = AppTheme.Gradients.surface
    }

    enum Wallpaper {
        static let goldGradient = LinearGradient(
            colors: [Color(hex: 0xFFE5A1), Color(hex: 0xF5B84E), Color(hex: 0xDF962F)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let secondaryGradient = AppTheme.Gradients.Calendar.circleGradient
    }

    enum Astrology {
        static let screenFade = LinearGradient(
            stops: [
                .init(color: AppTheme.Colors.Astrology.bottomFade.opacity(0), location: 0),
                .init(color: AppTheme.Colors.Astrology.bottomFade.opacity(0.08), location: 0.68),
                .init(color: AppTheme.Colors.Astrology.bottomFade.opacity(0.48), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        static let insightSheet = LinearGradient(
            colors: [Color(hex: 0x0A1740), Color(hex: 0x080D25), Color(hex: 0x050716)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    enum Settings {
        static let screenGradient = LinearGradient(
            colors: [Color(hex: 0x211052), Color(hex: 0x11082F), Color(hex: 0x0C0625)],
            startPoint: UnitPoint(x: 0.1, y: 0),
            endPoint: UnitPoint(x: 0.9, y: 1)
        )
        static let standardCardGradient = AppTheme.Gradients.cardElevated
        static let proCardGradient = LinearGradient(
            colors: [Color(hex: 0x421777), Color(hex: 0x321060), Color(hex: 0x230944)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let cardOverlayGradient = AppTheme.Gradients.cardOverlay
        static let primaryActionGradient = AppTheme.Gradients.secondaryAction
        static let dangerActionGradient = LinearGradient(
            colors: [Color(hex: 0x5D205E), Color(hex: 0x401442), Color(hex: 0x281031)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let paymentSelectedOverlay = LinearGradient(
            colors: [
                Color(hex: 0xFFE29A, opacity: 0.14),
                Color(hex: 0x412263, opacity: 0.12),
                Color(hex: 0x0E0727, opacity: 0.34)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        static let paymentUnselectedOverlay = LinearGradient(
            colors: [
                Color(hex: 0xEDBFFF, opacity: 0.09),
                Color(hex: 0x0D062A, opacity: 0.28)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        static let upgradeButtonGradient = AppTheme.Gradients.goldAction
    }
}
