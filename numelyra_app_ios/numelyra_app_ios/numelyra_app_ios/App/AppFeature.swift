import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    enum Tab: Hashable {
        case chat
        case calendar
        case astrology
        case wallpaper
        case settings
    }

    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .chat
        var isAuthPresented = false
        var chat = ChatFeature.State()
        var calendar = CalendarFeature.State()
        var astrology = AstrologyFeature.State()
        var wallpaper = WallpaperFeature.State()
        var settings = SettingsFeature.State()
        var auth = AuthFeature.State()
    }

    enum Action: Equatable {
        case selectedTabChanged(Tab)
        case authPresentationChanged(Bool)
        case chat(ChatFeature.Action)
        case calendar(CalendarFeature.Action)
        case astrology(AstrologyFeature.Action)
        case wallpaper(WallpaperFeature.Action)
        case settings(SettingsFeature.Action)
        case auth(AuthFeature.Action)
    }

    @Dependency(\.userProfileClient) var userProfileClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                return .none

            case let .authPresentationChanged(isPresented):
                state.isAuthPresented = isPresented
                return .none

            case let .auth(.delegate(.didAuthenticate(session))):
                state.settings.session = session
                state.isAuthPresented = false
                let active = userProfileClient.activeProfile()
                if let active {
                    state.calendar.profile = active
                    state.wallpaper.profile = active
                }
                state.selectedTab = .chat
                return .merge(.send(.astrology(.profileUpdated(active))), .send(.chat(.ownerChanged(session.userId))))

            case .auth(.delegate(.didContinueAsGuest)):
                state.isAuthPresented = false
                state.selectedTab = .chat
                return .send(.chat(.ownerChanged("guest")))

            case .settings(.delegate(.didRequestLogin)):
                state.auth.allowGuest = false
                state.isAuthPresented = true
                return .none

            case .settings(.delegate(.didSyncProfiles)):
                let active = userProfileClient.activeProfile()
                if let active {
                    state.calendar.profile = active
                    state.wallpaper.profile = active
                }
                return .merge(.send(.astrology(.profileUpdated(active))), .send(.chat(.onAppear)))

            case .settings(.delegate(.didSignOut)):
                state.settings.session = nil
                return .send(.chat(.ownerChanged("guest")))

            case .chat(.delegate(.gameHubTapped)):
                return .none

            case .chat, .calendar, .astrology, .wallpaper, .settings, .auth:
                return .none
            }
        }
        Scope(state: \.chat, action: \.chat) {
            ChatFeature()
        }
        Scope(state: \.calendar, action: \.calendar) {
            CalendarFeature()
        }
        Scope(state: \.astrology, action: \.astrology) {
            AstrologyFeature()
        }
        Scope(state: \.wallpaper, action: \.wallpaper) {
            WallpaperFeature()
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }
    }
}
