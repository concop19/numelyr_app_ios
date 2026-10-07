import ComposableArchitecture
import Foundation
import XCTest
@testable import numelyra_app_ios

@MainActor
final class AuthFeatureTests: XCTestCase {
    func testOnAppearLoadsSupabaseConfigurationState() async {
        let store = TestStore(initialState: AuthFeature.State(isConfigured: true)) {
            AuthFeature()
        } withDependencies: {
            $0.supabaseClient.isConfigured = { false }
            $0.hapticClient = .testValue
        }

        await store.send(.onAppear) {
            $0.isConfigured = false
        }

        XCTAssertEqual(store.state.isActionDisabled, true)
        XCTAssertEqual(
            store.state.unconfiguredNotice,
            "Chưa có cấu hình Supabase cho mobile app. Bạn vẫn có thể dùng chế độ Khách."
        )
    }

    func testValidationRejectsInvalidEmailShortPasswordAndMissingSignUpNameWithMediumHaptic() async {
        let mediumHapticCount = LockIsolated(0)

        let store = TestStore(initialState: AuthFeature.State(isConfigured: true)) {
            AuthFeature()
        } withDependencies: {
            $0.hapticClient.mediumImpact = {
                mediumHapticCount.withValue { $0 += 1 }
            }
            $0.hapticClient.selection = {}
        }

        // 1. Invalid email
        await store.send(.emailChanged("invalid-email")) {
            $0.email = "invalid-email"
        }
        await store.send(.submitTapped) {
            $0.errorMessage = "Hãy nhập một địa chỉ email hợp lệ."
        }
        XCTAssertEqual(mediumHapticCount.value, 1)

        // 2. Short password (< 6 characters)
        await store.send(.emailChanged("  an.nguyen@numelyra.online  ")) {
            $0.email = "  an.nguyen@numelyra.online  "
        }
        await store.send(.passwordChanged("12345")) {
            $0.password = "12345"
        }
        await store.send(.submitTapped) {
            $0.errorMessage = "Mật khẩu cần có ít nhất 6 ký tự."
        }
        XCTAssertEqual(mediumHapticCount.value, 2)

        // 3. Sign-up mode requires non-empty fullName
        await store.send(.toggleModeTapped) {
            $0.isSignUp = true
            $0.errorMessage = nil
            $0.message = nil
        }
        await store.send(.passwordChanged("123456")) {
            $0.password = "123456"
        }
        await store.send(.fullNameChanged("   ")) {
            $0.fullName = "   "
        }
        await store.send(.submitTapped) {
            $0.errorMessage = "Hãy nhập tên của bạn để tạo tài khoản."
        }
        XCTAssertEqual(mediumHapticCount.value, 3)
    }

    func testSignInSuccessTrimsEmailAndEmitsDidAuthenticateDelegate() async {
        let capturedEmail = LockIsolated<String?>(nil)
        let capturedPassword = LockIsolated<String?>(nil)
        let expectedSession = AuthSession(
            accessToken: "jwt-123",
            refreshToken: "refresh-123",
            userId: "user-1",
            userEmail: "an.nguyen@numelyra.online"
        )

        var initialState = AuthFeature.State(isConfigured: true)
        initialState.email = "  an.nguyen@numelyra.online \n"
        initialState.password = "secret123"

        let store = TestStore(initialState: initialState) {
            AuthFeature()
        } withDependencies: {
            $0.hapticClient = .testValue
            $0.supabaseClient.signIn = { email, password in
                capturedEmail.setValue(email)
                capturedPassword.setValue(password)
                return expectedSession
            }
        }

        await store.send(.submitTapped) {
            $0.isSubmitting = true
        }
        await store.receive(.signInResponse(.success(expectedSession))) {
            $0.isSubmitting = false
        }
        await store.receive(.delegate(.didAuthenticate(expectedSession)))

        XCTAssertEqual(capturedEmail.value, "an.nguyen@numelyra.online")
        XCTAssertEqual(capturedPassword.value, "secret123")
    }

    func testSignUpWithEmailConfirmationShowsMessageAndSwitchesToSignInMode() async {
        let capturedFullName = LockIsolated<String?>(nil)
        var initialState = AuthFeature.State(
            isSignUp: true,
            fullName: "  Nguyễn Văn An  ",
            email: "an.nguyen@numelyra.online",
            password: "secret123",
            isConfigured: true
        )
        initialState.errorMessage = "Lỗi cũ"

        let store = TestStore(initialState: initialState) {
            AuthFeature()
        } withDependencies: {
            $0.hapticClient = .testValue
            $0.supabaseClient.signUp = { _, _, fullName in
                capturedFullName.setValue(fullName)
                return AuthSignUpResult(
                    needsEmailConfirmation: true,
                    session: nil,
                    userId: "new-user-1"
                )
            }
        }

        await store.send(.submitTapped) {
            $0.isSubmitting = true
            $0.errorMessage = nil
        }
        await store.receive(
            .signUpResponse(
                .success(
                    AuthSignUpResult(
                        needsEmailConfirmation: true,
                        session: nil,
                        userId: "new-user-1"
                    )
                )
            )
        ) {
            $0.isSubmitting = false
            $0.isSignUp = false
            $0.message = AuthFeature.emailConfirmationMessage
        }

        XCTAssertEqual(capturedFullName.value, "Nguyễn Văn An")
    }

    func testGoogleSignInSuccessAndFailureFlow() async {
        let lightHapticCount = LockIsolated(0)
        let shouldFail = LockIsolated(true)
        let googleSession = AuthSession(
            accessToken: "google-jwt",
            refreshToken: "google-refresh",
            userId: "google-user-1",
            userEmail: "google@numelyra.online"
        )

        let store = TestStore(initialState: AuthFeature.State(isConfigured: true)) {
            AuthFeature()
        } withDependencies: {
            $0.hapticClient.lightImpact = {
                lightHapticCount.withValue { $0 += 1 }
            }
            $0.supabaseClient.signInWithGoogle = {
                if shouldFail.value {
                    throw AuthError.googleSignInFallback
                }
                return googleSession
            }
        }

        // 1. Failure case
        await store.send(.googleSignInTapped) {
            $0.isGoogleSubmitting = true
        }
        await store.receive(.googleSignInResponse(.failure(.googleSignInFallback))) {
            $0.isGoogleSubmitting = false
            $0.errorMessage = "Đăng nhập Google thất bại. Vui lòng thử lại."
        }
        XCTAssertEqual(lightHapticCount.value, 1)

        // 2. Success case
        shouldFail.setValue(false)
        await store.send(.googleSignInTapped) {
            $0.isGoogleSubmitting = true
            $0.errorMessage = nil
        }
        await store.receive(.googleSignInResponse(.success(googleSession))) {
            $0.isGoogleSubmitting = false
        }
        await store.receive(.delegate(.didAuthenticate(googleSession)))
        XCTAssertEqual(lightHapticCount.value, 2)
    }

    func testPasswordVisibilityAndContinueAsGuestBehavior() async {
        let selectionCount = LockIsolated(0)
        let lightImpactCount = LockIsolated(0)

        let store = TestStore(initialState: AuthFeature.State(allowGuest: true)) {
            AuthFeature()
        } withDependencies: {
            $0.hapticClient.selection = {
                selectionCount.withValue { $0 += 1 }
            }
            $0.hapticClient.lightImpact = {
                lightImpactCount.withValue { $0 += 1 }
            }
        }

        XCTAssertEqual(store.state.passwordToggleTitle, "HIỆN")
        await store.send(.togglePasswordVisibilityTapped) {
            $0.isPasswordVisible = true
        }
        XCTAssertEqual(store.state.passwordToggleTitle, "ẨN")
        XCTAssertEqual(selectionCount.value, 1)

        await store.send(.continueAsGuestTapped)
        await store.receive(.delegate(.didContinueAsGuest))
        XCTAssertEqual(lightImpactCount.value, 1)
    }

    func testOAuthCallbackParsingSupportsPKCEImplicitAndErrorFlows() throws {
        let pkceURL = try XCTUnwrap(URL(string: "numelyra://auth-callback?code=pkce-auth-code-123"))
        XCTAssertEqual(AuthEngine.parseOAuthCallback(pkceURL), .pkceCode("pkce-auth-code-123"))

        let implicitURL = try XCTUnwrap(
            URL(string: "numelyra://auth-callback#access_token=tok_abc&refresh_token=ref_xyz&token_type=bearer")
        )
        XCTAssertEqual(
            AuthEngine.parseOAuthCallback(implicitURL),
            .implicitTokens(accessToken: "tok_abc", refreshToken: "ref_xyz")
        )

        let errorURL = try XCTUnwrap(
            URL(string: "numelyra://auth-callback#error=access_denied&error_description=User+cancelled+login")
        )
        XCTAssertEqual(
            AuthEngine.parseOAuthCallback(errorURL),
            .error("User cancelled login")
        )
    }

    func testProfileSyncMergesRemoteAndLocalProfilesPreservingLocalGender() {
        let localProfiles = [
            UserProfile(
                id: "local-1",
                fullName: "Nguyễn Văn An",
                birthDate: "1998-10-20",
                gender: .male,
                isDefault: true,
                birthTime: "14:30",
                birthPlace: "Hà Nội"
            ),
            UserProfile(
                id: "local-2",
                fullName: "Trần Thị Bình",
                birthDate: "2000-01-15",
                gender: .female,
                isDefault: false
            )
        ]

        let remoteProfiles = [
            CloudNumerologyProfileDTO(
                id: "cloud-uuid-1",
                userId: "user-1",
                name: "  nguyễn văn an ",
                birthDate: "1998-10-20"
            ),
            CloudNumerologyProfileDTO(
                id: "cloud-uuid-3",
                userId: "user-1",
                name: "Lê Hoàng Nam",
                birthDate: "1995-05-05"
            )
        ]

        let localOnly = AuthEngine.localOnlyProfiles(
            localProfiles: localProfiles,
            remoteProfiles: remoteProfiles
        )
        XCTAssertEqual(localOnly.map(\.id), ["local-2"])

        let inserted = [
            CloudNumerologyProfileDTO(
                id: "cloud-uuid-2",
                userId: "user-1",
                name: "Trần Thị Bình",
                birthDate: "2000-01-15"
            )
        ]

        let unified = AuthEngine.mergeProfiles(
            remoteProfiles: remoteProfiles,
            insertedProfiles: inserted,
            localProfiles: localProfiles
        )

        XCTAssertEqual(unified.count, 3)
        XCTAssertEqual(unified[0].id, "cloud-uuid-2")
        XCTAssertEqual(unified[0].gender, .female)

        XCTAssertEqual(unified[1].id, "cloud-uuid-1")
        XCTAssertEqual(unified[1].gender, .male)
        XCTAssertEqual(unified[1].isDefault, true)
        XCTAssertEqual(unified[1].birthTime, "14:30")
        XCTAssertEqual(unified[1].birthPlace, "Hà Nội")

        // Cloud-only profile does not hardcode .female when gender is unknown on cloud
        XCTAssertEqual(unified[2].id, "cloud-uuid-3")
        XCTAssertNil(unified[2].gender)
    }
}
