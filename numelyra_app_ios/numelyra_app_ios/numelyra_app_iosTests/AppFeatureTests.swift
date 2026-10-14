import ComposableArchitecture
import Foundation
import XCTest
@testable import numelyra_app_ios

@MainActor
final class AppFeatureTests: XCTestCase {
    private let sampleProfile = UserProfile(
        id: "p1",
        fullName: "Lê Mạnh",
        birthDate: "1998-10-20",
        gender: .male,
        isDefault: true
    )

    func testLaunchWhenHasProfileDirectlyEntersMainAndSyncsProfile() async {
        let store = TestStore(initialState: AppFeature.State(launchFlow: .loading)) {
            AppFeature()
        } withDependencies: {
            $0.supabaseClient.currentSession = { nil }
            $0.userProfileClient.hasProfile = { true }
            $0.userProfileClient.activeProfile = { self.sampleProfile }
        }

        await store.send(.onAppear)
        await store.receive(\.launchLoaded) {
            $0.launchFlow = .main
            $0.wallpaper.profile = self.sampleProfile
            $0.chat.selectedProfiles = [self.sampleProfile]
        }
        await store.receive(\.astrology.profileUpdated) {
            $0.astrology.profile = self.sampleProfile
            $0.astrology.needsRefresh = true
        }
        await store.receive(\.calendar.profileUpdated) {
            $0.calendar.profile = self.sampleProfile
        }
    }

    func testLaunchWhenNoProfileAndNoSessionEntersAuth() async {
        let store = TestStore(initialState: AppFeature.State(launchFlow: .loading)) {
            AppFeature()
        } withDependencies: {
            $0.supabaseClient.currentSession = { nil }
            $0.userProfileClient.hasProfile = { false }
            $0.userProfileClient.activeProfile = { nil }
        }

        await store.send(.onAppear)
        await store.receive(\.launchLoaded) {
            $0.launchFlow = .auth
            $0.auth.allowGuest = true
        }
    }

    func testAuthContinueAsGuestWithoutProfileTransitionsToOnboarding() async {
        var state = AppFeature.State()
        state.launchFlow = .auth
        let store = TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.userProfileClient.hasProfile = { false }
            $0.userProfileClient.activeProfile = { nil }
        }

        await store.send(.auth(.delegate(.didContinueAsGuest))) {
            $0.launchFlow = .onboarding
        }
        await store.receive(\.chat.ownerChanged)
    }

    func testOnboardingCompleteTransitionsToMainAndSyncsProfile() async {
        var state = AppFeature.State()
        state.launchFlow = .onboarding
        let store = TestStore(initialState: state) {
            AppFeature()
        }

        await store.send(.onboarding(.delegate(.didComplete(sampleProfile)))) {
            $0.launchFlow = .main
            $0.selectedTab = .chat
            $0.wallpaper.profile = self.sampleProfile
            $0.chat.selectedProfiles = [self.sampleProfile]
        }
        await store.receive(\.astrology.profileUpdated) {
            $0.astrology.profile = self.sampleProfile
            $0.astrology.needsRefresh = true
        }
        await store.receive(\.calendar.profileUpdated) {
            $0.calendar.profile = self.sampleProfile
        }
        await store.receive(\.chat.onAppear)
    }

    func testChatGameHubTappedPresentsGameHubAndCanBeClosed() async {
        var state = AppFeature.State()
        state.launchFlow = .main
        let store = TestStore(initialState: state) {
            AppFeature()
        }

        await store.send(.chat(.delegate(.gameHubTapped))) {
            $0.gameHub = GameHubFeature.State()
        }

        await store.send(.gameHub(.presented(.delegate(.close)))) {
            $0.gameHub = nil
        }
    }

    func testChatDestinationProfileSelectionSyncsActiveProfile() async {
        var state = AppFeature.State()
        state.launchFlow = .main
        state.chat.destination = .profilePicker(
            .init(profiles: [sampleProfile], selectedIDs: [], mode: .single)
        )
        let store = TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.userProfileClient.setActiveProfileID = { _ in }
        }

        await store.send(
            .chat(.destination(.presented(.profilePicker(.delegate(.selected([sampleProfile]))))))
        ) {
            $0.wallpaper.profile = self.sampleProfile
            $0.chat.selectedProfiles = [self.sampleProfile]
            $0.chat.destination = nil
        }
        await store.receive(\.astrology.profileUpdated) {
            $0.astrology.profile = self.sampleProfile
            $0.astrology.needsRefresh = true
        }
        await store.receive(\.calendar.profileUpdated) {
            $0.calendar.profile = self.sampleProfile
        }
    }

    func testSettingsRequestLoginPresentsAuthAndCanBeDismissed() async {
        var state = AppFeature.State()
        state.launchFlow = .main
        let store = TestStore(initialState: state) {
            AppFeature()
        }

        await store.send(.settings(.delegate(.didRequestLogin))) {
            $0.isAuthPresented = true
            $0.auth.allowGuest = false
        }

        await store.send(.auth(.delegate(.didDismiss))) {
            $0.isAuthPresented = false
        }
    }
}
