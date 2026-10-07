import ComposableArchitecture
import Foundation

@Reducer
struct AuthFeature {
    static let emailConfirmationMessage =
        "Tài khoản đã được tạo. Hãy kiểm tra email để xác nhận, rồi đăng nhập lại."
    static let unconfiguredMessage =
        "Chưa có cấu hình Supabase cho mobile app. Bạn vẫn có thể dùng chế độ Khách."

    @ObservableState
    struct State: Equatable {
        var isSignUp: Bool
        var fullName: String
        var email: String
        var password: String
        var isPasswordVisible: Bool
        var isSubmitting: Bool
        var isGoogleSubmitting: Bool
        var isConfigured: Bool
        var allowGuest: Bool
        var message: String?
        var errorMessage: String?

        init(
            isSignUp: Bool = false,
            fullName: String = "",
            email: String = "",
            password: String = "",
            isPasswordVisible: Bool = false,
            isSubmitting: Bool = false,
            isGoogleSubmitting: Bool = false,
            isConfigured: Bool = true,
            allowGuest: Bool = true,
            message: String? = nil,
            errorMessage: String? = nil
        ) {
            self.isSignUp = isSignUp
            self.fullName = fullName
            self.email = email
            self.password = password
            self.isPasswordVisible = isPasswordVisible
            self.isSubmitting = isSubmitting
            self.isGoogleSubmitting = isGoogleSubmitting
            self.isConfigured = isConfigured
            self.allowGuest = allowGuest
            self.message = message
            self.errorMessage = errorMessage
        }

        var isActionDisabled: Bool {
            isSubmitting || isGoogleSubmitting || !isConfigured
        }

        var descriptionText: String {
            isSignUp
                ? "Tạo tài khoản để đồng bộ hành trình của bạn."
                : "Đăng nhập để lưu và đồng bộ hành trình của bạn."
        }

        var submitButtonTitle: String {
            isSignUp ? "TẠO TÀI KHOẢN" : "ĐĂNG NHẬP"
        }

        var passwordToggleTitle: String {
            isPasswordVisible ? "ẨN" : "HIỆN"
        }

        var modePromptPrefix: String {
            isSignUp ? "Đã có tài khoản? " : "Chưa có tài khoản? "
        }

        var modePromptEmphasis: String {
            isSignUp ? "Đăng nhập" : "Tạo tài khoản"
        }

        var unconfiguredNotice: String? {
            isConfigured ? nil : AuthFeature.unconfiguredMessage
        }
    }

    enum Action: Equatable {
        case onAppear
        case fullNameChanged(String)
        case emailChanged(String)
        case passwordChanged(String)
        case togglePasswordVisibilityTapped
        case toggleModeTapped
        case submitTapped
        case googleSignInTapped
        case continueAsGuestTapped
        case signInResponse(Result<AuthSession, AuthError>)
        case signUpResponse(Result<AuthSignUpResult, AuthError>)
        case googleSignInResponse(Result<AuthSession, AuthError>)
        case delegate(Delegate)

        enum Delegate: Equatable, Sendable {
            case didAuthenticate(AuthSession)
            case didContinueAsGuest
        }
    }

    @Dependency(\.supabaseClient) var supabaseClient
    @Dependency(\.hapticClient) var hapticClient
/*
 nonisolated báo cho Swift biết: thành viên này không thuộc về actor isolation của type chứa nó, nên có thể gọi từ bất kỳ đâu mà không cần await hay hop sang actor đó.*/
    private nonisolated enum CancelID: Hashable, Sendable {
        case submit
        case googleSignIn
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isConfigured = supabaseClient.isConfigured()
                return .none

            case let .fullNameChanged(fullName):
                state.fullName = fullName
                return .none
   /// tại sao ko để state ở bên trong view ?
        // vì đơn giản ta phải thêm đối số vào nếu mún dùng feature ,. nếu đẻ đây là 1 binable state === thif bọn chúng nối tới vơi nhau
                // chúng ta ví dụ login ta chỉ cần ghi send login kiể
            case let .emailChanged(email):
                state.email = email
                return .none

            case let .passwordChanged(password):
                state.password = password
                return .none

            case .togglePasswordVisibilityTapped:
                state.isPasswordVisible.toggle()
                return .run { _ in
                    await hapticClient.selection()
                }

            case .toggleModeTapped:
                state.isSignUp.toggle()
                state.errorMessage = nil
                state.message = nil
                return .run { _ in
                    await hapticClient.selection()
                }

            case .continueAsGuestTapped:
                guard state.allowGuest else { return .none }
                return .merge(
                    .send(.delegate(.didContinueAsGuest)),// điều này khiến task này giải phóng ngay
                    .run { _ in
                        await hapticClient.lightImpact()
                    }
                )

            case .googleSignInTapped:
                guard !state.isActionDisabled else { return .none }
                // điều này sẽ ko xayr khi ch có cấu hình hoặc dag submit
                state.isGoogleSubmitting = true
                state.errorMessage = nil
                state.message = nil
                return .merge(
                    .run { _ in
                        await hapticClient.lightImpact()
                    },
                    .run { send in
                        do {
                            let session = try await supabaseClient.signInWithGoogle()
                            await send(.googleSignInResponse(.success(session)))
                        } catch is CancellationError {
                            return
                            // catch này để làm khi ng dùng hủy dăng nhập bằng gg
                        } catch {
                            let authError = AuthError.from(
                                error,
                                fallback: AuthError.googleSignInFallback.message
                            )
                            // catch này bắt khi thực hiện lỗi sảy ra  trong quá trình đăng nhâpk
                            await send(.googleSignInResponse(.failure(authError)))
                            //
                        }
                    } // cancellable là gì?  hạn chế có tiền trình cùng id dag chạy
                    // huỷ nó rồi chạy cái này
                    .cancellable(id: CancelID.googleSignIn, cancelInFlight: true)
                )

            case .submitTapped:
                guard !state.isActionDisabled else { return .none }

                let validation = AuthEngine.validateSubmission(
                    email: state.email,
                    password: state.password,
                    fullName: state.fullName,
                    isSignUp: state.isSignUp
                )

                switch validation {
                case let .failure(validationError):
                    state.errorMessage = validationError.errorDescription
                    return .run { _ in
                        await hapticClient.mediumImpact()
                    }

                case let .success(credentials):
                    let isSignUp = state.isSignUp
                    state.isSubmitting = true
                    state.errorMessage = nil
                    state.message = nil

                    return .merge(
                        .run { _ in
                            await hapticClient.mediumImpact()
                        },
                        .run { send in
                            do {
                                if isSignUp {
                                    let result = try await supabaseClient.signUp(
                                        credentials.email,
                                        credentials.password,
                                        credentials.fullName
                                    )
                                    await send(.signUpResponse(.success(result)))
                                } else {
                                    let session = try await supabaseClient.signIn(
                                        credentials.email,
                                        credentials.password
                                    )
                                    await send(.signInResponse(.success(session)))
                                }
                            } catch is CancellationError {
                                return
                            } catch {
                                let authError = AuthError.from(
                                    error,
                                    fallback: AuthError.signInFallback.message
                                )
                                if isSignUp {
                                    await send(.signUpResponse(.failure(authError)))
                                } else {
                                    await send(.signInResponse(.failure(authError)))
                                }
                            }
                        }
                        .cancellable(id: CancelID.submit, cancelInFlight: true)
                    )
                }

            case let .signInResponse(.success(session)):
                state.isSubmitting = false
                return .send(.delegate(.didAuthenticate(session)))

            case let .signInResponse(.failure(error)):
                state.isSubmitting = false
                state.errorMessage = error.message
                return .none

            case let .signUpResponse(.success(result)):
                state.isSubmitting = false
                if result.needsEmailConfirmation {
                    state.message = Self.emailConfirmationMessage
                    state.isSignUp = false
                    return .none
                }
                if let session = result.session {
                    return .send(.delegate(.didAuthenticate(session)))
                }
                state.message = Self.emailConfirmationMessage
                state.isSignUp = false
                return .none

            case let .signUpResponse(.failure(error)):
                state.isSubmitting = false
                state.errorMessage = error.message
                return .none

            case let .googleSignInResponse(.success(session)):
                state.isGoogleSubmitting = false
                return .send(.delegate(.didAuthenticate(session)))

            case let .googleSignInResponse(.failure(error)):
                state.isGoogleSubmitting = false
                state.errorMessage = error.message
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
