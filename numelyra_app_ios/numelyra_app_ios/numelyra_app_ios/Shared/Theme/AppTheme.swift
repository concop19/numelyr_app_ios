import SwiftUI

/// Shared design tokens derived from the active React Native app shell.
///
/// Feature code should use these semantic tokens instead of introducing raw
/// colors, spacing values or corner radii. Feature-specific palettes can extend
/// this namespace when that feature is migrated.
enum AppTheme {
    enum Colors {
        static let background = Color(hex: 0x0B0B14)
        static let backgroundElevated = Color(hex: 0x171044)
        static let surface = Color(hex: 0x211052)
        static let surfaceRaised = Color(hex: 0x30195F)
        static let surfaceMuted = Color(hex: 0x1E1B2E)

        static let primary = Color(hex: 0xF5BA5B)
        static let primaryBright = Color(hex: 0xFFD07A)
        static let primaryDark = Color(hex: 0xD8892C)
        static let secondary = Color(hex: 0xB98BDC)
        static let accentPink = Color(hex: 0xF2A4CF)

        static let textPrimary = Color(hex: 0xFFF7E8)
        static let textSecondary = Color(hex: 0xD8C9E8)
        static let textMuted = Color(hex: 0x94A3B8)
        static let textOnPrimary = Color(hex: 0x24133F)

        static let border = Color(hex: 0x6E3A9D)
        static let divider = Color(hex: 0xB685E7).opacity(0.23)
        static let success = Color(hex: 0x4ADE80)
        static let warning = Color(hex: 0xFCD34D)
        static let error = Color(hex: 0xF87171)
        static let scrim = Color.black.opacity(0.72)
    }

    enum Gradients {
        static let screen = LinearGradient(
            colors: [Colors.surface, Color(hex: 0x11082F), Color(hex: 0x0C0625)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let primary = LinearGradient(
            colors: [Color(hex: 0xFFE39A), Colors.primary, Color(hex: 0xE9A642)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let surface = LinearGradient(
            colors: [Color(hex: 0x43236F), Color(hex: 0x28144F)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Typography {
        static let display = Font.system(size: 34, weight: .heavy, design: .rounded)
        static let title = Font.system(size: 24, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 20, weight: .bold, design: .rounded)
        static let headline = Font.system(size: 16, weight: .bold, design: .rounded)
        static let body = Font.system(size: 15, weight: .regular, design: .rounded)
        static let bodyStrong = Font.system(size: 15, weight: .semibold, design: .rounded)
        static let callout = Font.system(size: 13, weight: .medium, design: .rounded)
        static let caption = Font.system(size: 11, weight: .semibold, design: .rounded)
    }

    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
        static let xxxLarge: CGFloat = 48
    }

    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
    }

    enum Size {
        static let minimumTapTarget: CGFloat = 44
        static let buttonHeight: CGFloat = 52
        static let tabIcon: CGFloat = 32
        static let contentMaxWidth: CGFloat = 560
    }

    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.18)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let gentle = SwiftUI.Animation.easeInOut(duration: 0.55)
    }

    enum Shadow {
        static let card = AppShadow(
            color: Color(hex: 0x1A063A).opacity(0.75),
            radius: 18,
            x: 0,
            y: 10
        )
        static let glow = AppShadow(
            color: Colors.accentPink.opacity(0.28),
            radius: 12,
            x: 0,
            y: 4
        )
    }
}

struct AppShadow: Sendable {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
