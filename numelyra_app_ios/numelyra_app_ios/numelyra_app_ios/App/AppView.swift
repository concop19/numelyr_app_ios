import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                AppScreenBackground()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xLarge) {
                        Image(appAsset: .authMascot)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 210)
                            .accessibilityLabel("Linh vật Numelyra")

                        VStack(spacing: AppTheme.Spacing.small) {
                            Text("NUMELYRA")
                                .font(AppTheme.Typography.display)
                                .foregroundStyle(AppTheme.Colors.primaryBright)

                            Text("Swift foundation")
                                .font(AppTheme.Typography.callout)
                                .foregroundStyle(AppTheme.Colors.secondary)
                                .textCase(.uppercase)
                                .tracking(2)
                        }

                        foundationStatus
                        navigationAssets
                    }
                    .frame(maxWidth: AppTheme.Size.contentMaxWidth)
                    .padding(.horizontal, AppTheme.Spacing.large)
                    .padding(.vertical, AppTheme.Spacing.xLarge)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbarBackground(AppTheme.Colors.surface.opacity(0.94), for: .navigationBar)
        }
        .tint(AppTheme.Colors.primary)
        .preferredColorScheme(.dark)
        .onAppear {
            store.send(.onAppear)
        }
    }

    private var foundationStatus: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: store.isInitialized ? "checkmark.seal.fill" : "hourglass")
                .font(.title2)
                .foregroundStyle(
                    store.isInitialized ? AppTheme.Colors.success : AppTheme.Colors.warning
                )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text(store.isInitialized ? "Nền tảng đã sẵn sàng" : "Đang khởi tạo")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text("TCA, Supabase, asset catalog và theme dùng chung")
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var navigationAssets: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Asset điều hướng")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            HStack(spacing: AppTheme.Spacing.medium) {
                assetPreview(.tabChat, label: "Chat")
                assetPreview(.tabCalendar, label: "Lịch")
                assetPreview(.tabWallpaper, label: "Ảnh")
                assetPreview(.tabSettings, label: "Cài đặt")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private func assetPreview(_ asset: AppAsset, label: String) -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(appAsset: asset)
                .resizable()
                .scaledToFill()
                .frame(width: AppTheme.Size.tabIcon, height: AppTheme.Size.tabIcon)
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(AppTheme.Colors.primary.opacity(0.6), lineWidth: 1)
                }

            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
