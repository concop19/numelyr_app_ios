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
        /// Giai đoạn khởi chạy hiện tại, quyết định app hiển thị loading, đăng nhập, onboarding hay giao diện chính.
        var launchFlow: LaunchFlow = .loading
        /// Tab đang được chọn trong giao diện chính; Chat là tab mặc định.
        var selectedTab: Tab = .chat
        /// Cho biết màn hình Auth đang được trình bày toàn màn hình từ Settings hay không.
        var isAuthPresented = false
        /// State luôn tồn tại của tính năng Chat.
        var chat = ChatFeature.State()
        /// State luôn tồn tại của tính năng Lịch.
        var calendar = CalendarFeature.State()
        /// State luôn tồn tại của tính năng Chiêm tinh.
        var astrology = AstrologyFeature.State()
        /// State luôn tồn tại của tính năng Hình nền.
        var wallpaper = WallpaperFeature.State()
        /// State luôn tồn tại của tính năng Cài đặt và tài khoản.
        var settings = SettingsFeature.State()
        /// State của form đăng nhập/đăng ký, dùng ở cả luồng khởi chạy và màn hình phủ toàn màn hình từ Settings.
        var auth = AuthFeature.State()
        /// State của bước thu thập hồ sơ lần đầu sau khi đăng nhập hoặc tiếp tục dưới dạng khách.
        var onboarding = OnboardingFeature.State()
    }

    enum Action: Equatable {
        case onAppear
        case launchLoaded(session: AuthSession?, hasProfile: Bool, activeProfile: UserProfile?)
        case selectedTabChanged(Tab)
        case authPresentationChanged(Bool)
        case chat(ChatFeature.Action)
        case calendar(CalendarFeature.Action)
        case astrology(AstrologyFeature.Action)
        case wallpaper(WallpaperFeature.Action)
        case settings(SettingsFeature.Action)
        case auth(AuthFeature.Action)
        case onboarding(OnboardingFeature.Action)
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
                // reload du ;ieu ms nhat
                return .none
                // vi ban than tab chat nay no co thu am. roi xu li, du lieu,// nang
                // nen neu ko set up disappear thi no rat co the tien trinh van chay

            case let .authPresentationChanged(isPresented):
                state.isAuthPresented = isPresented
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
                        let syncEffect = synchronizeActiveProfile(active, in: &state) // nay nay chay //xog r ma
                        return .merge(syncEffect, .send(.chat(.ownerChanged("guest"))))
                    } else {
                        state.launchFlow = .onboarding
                        return .send(.chat(.ownerChanged("guest")))
                    }
                } else {
                    state.isAuthPresented = false
                    return .send(.chat(.ownerChanged("guest")))
                }
/*case didAuthenticate(AuthSession)
 case didContinueAsGuest
 case didDismiss*/
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

            case let .chat(.destination(.presented(.profilePicker(.delegate(.selected(profiles)))))):
                if let first = profiles.first {
                    userProfileClient.setActiveProfileID(first.id)
                    return synchronizeActiveProfile(first, in: &state)
                }
                return .none

            case let .wallpaper(.profilePicker(.presented(.delegate(.selected(profile))))):
                userProfileClient.setActiveProfileID(profile.id)
                return synchronizeActiveProfile(profile, in: &state)

            case let .astrology(.delegate(.profileChanged(profile))):
                return synchronizeActiveProfile(profile, in: &state)

            case .chat, .calendar, .astrology, .wallpaper, .settings, .auth, .onboarding:
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
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
    }
    // scope dùng khi state con luôn tồn tại
    // ifself là option có thể tồn tại hoặc ko

    private func synchronizeActiveProfile(_ profile: UserProfile?, in state: inout State) -> Effect<Action> {
        state.wallpaper.profile = profile

        if let profile {
            state.chat.selectedProfiles = [profile]
        }

        return .merge(
            .send(.astrology(.profileUpdated(profile))),
            .send(.calendar(.profileUpdated(profile)))
        )
    }
}
