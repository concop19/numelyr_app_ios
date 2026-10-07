import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        TabView(
            selection: Binding(
                get: { store.selectedTab },
                set: { store.send(.selectedTabChanged($0)) }
            )
        ) {
            ChatView(
                store: store.scope(state: \.chat, action: \.chat)
            )
            .tabItem { Label("Chat", image: AppAsset.tabChat.rawValue) }
            .tag(AppFeature.Tab.chat)

            CalendarView(
                store: store.scope(state: \.calendar, action: \.calendar)
            )
            .tabItem { Label("Lịch", systemImage: "calendar") }
            .tag(AppFeature.Tab.calendar)

            AstrologyView(
                store: store.scope(state: \.astrology, action: \.astrology)
            )
            .tabItem { Label("Chiêm tinh", systemImage: "sparkles") }
            .tag(AppFeature.Tab.astrology)

            WallpaperView(
                store: store.scope(state: \.wallpaper, action: \.wallpaper)
            )
            .tabItem { Label("Hình nền", systemImage: "photo.on.rectangle.angled") }
            .tag(AppFeature.Tab.wallpaper)

            SettingsView(
                store: store.scope(state: \.settings, action: \.settings)
            )
            .tabItem { Label("Cài đặt", systemImage: "gearshape") }
            .tag(AppFeature.Tab.settings)

        }
        .tint(AppTheme.Colors.primary)
        .fullScreenCover(
            isPresented: Binding(
                get: { store.isAuthPresented },
                set: { store.send(.authPresentationChanged($0)) }
            )
        ) {
            AuthView(store: store.scope(state: \.auth, action: \.auth))
        }
    }
}

#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.astrologyClient = .previewValue
            $0.caDaoClient = .previewValue
            $0.calendarArtClient = .previewValue
            $0.wallpaperClient = .previewValue
            $0.supabaseClient = .previewValue
            $0.billingClient = .previewValue
            $0.dailyNotificationClient = .previewValue
            $0.hapticClient = .testValue
            $0.chatClient = .testValue
            $0.chatHistoryClient = .testValue
            $0.speechClient = .testValue
            $0.speechRecognitionClient = .testValue
            $0.placeLocationClient = .testValue
            $0.externalURLClient = .testValue
            $0.tuViClient = .previewValue
        }
    )
}
