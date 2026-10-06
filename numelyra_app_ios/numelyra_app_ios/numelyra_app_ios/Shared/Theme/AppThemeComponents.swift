import SwiftUI

struct AppScreenBackground: View {
    var body: some View {
        ZStack {
         AppTheme.Gradients.screen
           
            RadialGradient(
                colors: [AppTheme.Colors.accentPink.opacity(0.15), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 330
            )

            RadialGradient(
                colors: [AppTheme.Colors.secondary.opacity(0.13), .clear],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.headline)
            .foregroundStyle(AppTheme.Colors.textOnPrimary)
            .frame(maxWidth: .infinity, minHeight: AppTheme.Size.buttonHeight)
            .padding(.horizontal, AppTheme.Spacing.large)
            .background(AppTheme.Gradients.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            .shadow(
                color: AppTheme.Shadow.glow.color,
                radius: AppTheme.Shadow.glow.radius,
                x: AppTheme.Shadow.glow.x,
                y: AppTheme.Shadow.glow.y
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

private struct AppCardModifier: ViewModifier {
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.Gradients.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                    .stroke(AppTheme.Colors.border.opacity(0.64), lineWidth: 1)
            }
            .shadow(
                color: AppTheme.Shadow.card.color,
                radius: AppTheme.Shadow.card.radius,
                x: AppTheme.Shadow.card.x,
                y: AppTheme.Shadow.card.y
            )
    }
}

extension View {
    func appCard(padding: CGFloat = AppTheme.Spacing.large) -> some View {
        modifier(AppCardModifier(padding: padding))
    }
}
