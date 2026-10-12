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

    enum LaunchFlow: Equatable {
        case loading
        case auth
        case onboarding
        case main
    }

    @ObservableState
    struct State: Equatable {
        var launchFlow: LaunchFlow = .loading
        var selectedTab: Tab = .chat
        var isAuthPresented = false
        var chat = ChatFeature.State()
        var calendar = CalendarFeature.State()
        var astrology = AstrologyFeature.State()
        var wallpaper = WallpaperFeature.State()
        var settings = SettingsFeature.State()
        var auth = AuthFeature.State()
        var onboarding = OnboardingFeature.State()
        @Presents var gameHub: GameHubFeature.State?
    }

    enum Action: Equatable {
        case onAppear
        case launchLoaded(session: AuthSession?, hasProfile: Bool, activeProfile: UserProfile?)
        case selectedTabChanged(Tab)
        case authPresentationChanged(Bool)
        case handleDeepLink(URL)
        case chat(ChatFeature.Action)
        case calendar(CalendarFeature.Action)
        case astrology(AstrologyFeature.Action)
        case wallpaper(WallpaperFeature.Action)
        case settings(SettingsFeature.Action)
        case auth(AuthFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case gameHub(PresentationAction<GameHubFeature.Action>)
    }

    @Dependency(\.userProfileClient) var userProfileClient
    @Dependency(\.supabaseClient) var supabaseClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let session = await supabaseClient.currentSession()
                    let hasProf = userProfileClient.hasProfile()
                    let active = userProfileClient.activeProfile()
                    await send(.launchLoaded(session: session, hasProfile: hasProf, activeProfile: active))
                }

            case let .launchLoaded(session, hasProf, active):
                state.settings.session = session
                if hasProf {
                    state.launchFlow = .main
                    return synchronizeActiveProfile(active, in: &state)
                } else if session != nil {
                    state.launchFlow = .onboarding
                    return .none
                } else {
                    state.auth.allowGuest = true
                    state.launchFlow = .auth
                    return .none
                }

            case let .selectedTabChanged(tab):
                let previousTab = state.selectedTab
                state.selectedTab = tab
                if previousTab == .chat, tab != .chat {
                    return .send(.chat(.onDisappear))
                }
                if previousTab != .chat, tab == .chat {
                    return .send(.chat(.onAppear))
                }
                return .none

            case let .authPresentationChanged(isPresented):
                state.isAuthPresented = isPresented
                return .none

            case let .handleDeepLink(url):
                guard url.scheme == "numelyra" else { return .none }
                if url.host == "games" || url.path.contains("games") {
                    let isDaily = url.path.contains("daily")
                    state.gameHub = GameHubFeature.State(isDailyMode: isDaily)
                }
                return .none

            case let .auth(.delegate(.didAuthenticate(session))):
                state.settings.session = session
                let hasProf = userProfileClient.hasProfile()
                let active = userProfileClient.activeProfile()

                if state.launchFlow == .auth {
                    if hasProf {
                        state.launchFlow = .main
                        state.selectedTab = .chat
                        let syncEffect = synchronizeActiveProfile(active, in: &state)
                        return .merge(syncEffect, .send(.chat(.ownerChanged(session.userId))))
                    } else {
                        state.launchFlow = .onboarding
                        return .send(.chat(.ownerChanged(session.userId)))
                    }
                } else {
                    state.isAuthPresented = false
                    let syncEffect = synchronizeActiveProfile(active, in: &state)
                    return .merge(syncEffect, .send(.chat(.ownerChanged(session.userId))))
                }

            case .auth(.delegate(.didContinueAsGuest)):
                let hasProf = userProfileClient.hasProfile()
                let active = userProfileClient.activeProfile()

                if state.launchFlow == .auth {
                    if hasProf {
                        state.launchFlow = .main
                        state.selectedTab = .chat
                        let syncEffect = synchronizeActiveProfile(active, in: &state)
                        return .merge(syncEffect, .send(.chat(.ownerChanged("guest"))))
                    } else {
                        state.launchFlow = .onboarding
                        return .send(.chat(.ownerChanged("guest")))
                    }
                } else {
                    state.isAuthPresented = false
                    return .send(.chat(.ownerChanged("guest")))
                }

            case .auth(.delegate(.didDismiss)):
                state.isAuthPresented = false
                return .none

            case let .onboarding(.delegate(.didComplete(profile))):
                state.launchFlow = .main
                state.selectedTab = .chat
                let syncEffect = synchronizeActiveProfile(profile, in: &state)
                return .merge(syncEffect, .send(.chat(.onAppear)))

            case .settings(.delegate(.didRequestLogin)):
                state.auth.allowGuest = false
                state.isAuthPresented = true
                return .none

            case .settings(.delegate(.didSyncProfiles)):
                let active = userProfileClient.activeProfile()
                let syncEffect = synchronizeActiveProfile(active, in: &state)
                return .merge(syncEffect, .send(.chat(.onAppear)))

            case .settings(.delegate(.didSignOut)):
                state.settings.session = nil
                return .send(.chat(.ownerChanged("guest")))

            case .chat(.delegate(.gameHubTapped)):
                state.gameHub = GameHubFeature.State()
                return .none

            case .gameHub(.presented(.delegate(.close))):
                state.gameHub = nil
                return .none

            case let .chat(.profilePicker(.presented(.delegate(.selected(profiles))))):
                if let first = profiles.first {
                    userProfileClient.setActiveProfileID(first.id)
                    return synchronizeActiveProfile(first, in: &state)
                }
                return .none

            case let .wallpaper(.profilePicker(.presented(.delegate(.selected(profile))))):
                userProfileClient.setActiveProfileID(profile.id)
                return synchronizeActiveProfile(profile, in: &state)

            case .chat, .calendar, .astrology, .wallpaper, .settings, .auth, .onboarding, .gameHub:
                return .none
            }
        }
        .ifLet(\.$gameHub, action: \.gameHub) {
            GameHubFeature()
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
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
    }

    private func synchronizeActiveProfile(_ profile: UserProfile?, in state: inout State) -> Effect<Action> {
        state.calendar.profile = profile
        state.wallpaper.profile = profile
        if let profile {
            state.chat.selectedProfiles = [profile]
        }
        return .send(.astrology(.profileUpdated(profile)))
    }
}
