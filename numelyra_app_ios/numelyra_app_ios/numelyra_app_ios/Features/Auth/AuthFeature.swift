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
        /// Chọn chế độ của form: `true` để tạo tài khoản, `false` để đăng nhập.
        var isSignUp: Bool
        /// Họ tên người dùng nhập khi tạo tài khoản; không được yêu cầu ở chế độ đăng nhập.
        var fullName: String
        /// Địa chỉ email đang hiển thị trong ô nhập và được dùng để xác thực.
        var email: String
        /// Mật khẩu đang hiển thị trong ô nhập và được gửi cho Supabase khi submit.
        var password: String
        /// Điều khiển việc ô mật khẩu hiển thị ký tự rõ hay che nội dung.
        var isPasswordVisible: Bool
        /// Cho biết request đăng nhập/đăng ký bằng email đang chạy.
        var isSubmitting: Bool
        /// Cho biết luồng đăng nhập Google đang chạy.
        var isGoogleSubmitting: Bool
        /// Phản ánh Supabase đã được cấu hình hay chưa; khi `false`, các hành động xác thực bị khóa.
        var isConfigured: Bool
        /// Quy định màn hình hiện tại có cho phép người dùng tiếp tục bằng chế độ khách hay không.
        var allowGuest: Bool
        /// Thông báo thành công hoặc hướng dẫn không phải lỗi, ví dụ yêu cầu xác nhận email.
        var message: String?
        /// Thông báo lỗi validation hoặc lỗi trả về từ dịch vụ xác thực.
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

        /// Cho biết các nút xác thực phải bị vô hiệu hóa vì đang submit hoặc Supabase chưa sẵn sàng.
        var isActionDisabled: Bool {
            isSubmitting || isGoogleSubmitting || !isConfigured
        }

        /// Nội dung mô tả thay đổi theo chế độ đăng nhập hoặc tạo tài khoản.
        var descriptionText: String {
            isSignUp
                ? "Tạo tài khoản để đồng bộ hành trình của bạn."
                : "Đăng nhập để lưu và đồng bộ hành trình của bạn."
        }

        /// Tiêu đề nút submit tương ứng với chế độ hiện tại.
        var submitButtonTitle: String {
            isSignUp ? "TẠO TÀI KHOẢN" : "ĐĂNG NHẬP"
        }

        /// Nhãn hành động dùng để hiện hoặc ẩn mật khẩu.
        var passwordToggleTitle: String {
            isPasswordVisible ? "ẨN" : "HIỆN"
        }

        /// Phần văn bản thường trong lời nhắc chuyển đổi giữa đăng nhập và đăng ký.
        var modePromptPrefix: String {
            isSignUp ? "Đã có tài khoản? " : "Chưa có tài khoản? "
        }

        /// Phần văn bản nhấn mạnh, có thể bấm để chuyển đổi giữa đăng nhập và đăng ký.
        var modePromptEmphasis: String {
            isSignUp ? "Đăng nhập" : "Tạo tài khoản"
        }

        /// Cảnh báo cấu hình được hiển thị khi Supabase chưa sẵn sàng; `nil` khi đã cấu hình.
        var unconfiguredNotice: String? {
            isConfigured ? nil : AuthFeature.unconfiguredMessage
        }
    }

    enum Action: Equatable { // tai sao action la equatable
        // điều này phục vụ test
        case onAppear
        case fullNameChanged(String)
        case emailChanged(String)
        case passwordChanged(String)
        case togglePasswordVisibilityTapped
        case toggleModeTapped
        case submitTapped
        case googleSignInTapped
        case continueAsGuestTapped
        case dismissTapped
        case signInResponse(Result<AuthSession, AuthError>)
        case signUpResponse(Result<AuthSignUpResult, AuthError>)
        case googleSignInResponse(Result<AuthSession, AuthError>)
        case delegate(Delegate)

        enum Delegate: Equatable, Sendable {
            case didAuthenticate(AuthSession)
            case didContinueAsGuest
            case didDismiss
        }
    }
        // deligate dùng dể cho parent bt dc trạng thái lớn của màn hình này
    //

    @Dependency(\.supabaseClient) var supabaseClient
    @Dependency(\.hapticClient) var hapticClient
/*
 nonisolated báo cho Swift biết: thành viên này không thuộc về actor isolation của type chứa nó, nên có thể gọi từ bất kỳ đâu mà không cần await hay hop sang actor đó.*/
    private nonisolated enum CancelID: Hashable, Sendable {
        case submit
        case googleSignIn
    }
// tai sao cancel id can kha nang hashable ? lieu no co phai do can gui ra ngoai can decode encode? neu vay thì ta cần
    //-> bởi vì cancelid cần để lưu trữ dạng dic trong local điều này băts buộc nó cần hashable
    // dữ liệu này dc gửi từ đây sang thằng client lưu nên. cần sendable
    // encodable chu sao lại hashtable , sendable có thể chuyển giữ các luồng khác nhau vậy. tại sao state ko sendable
    // liệu điều đó có phải do th state ko dc gửi mà nằm trong 1 phần bộ nhớ dc truy cập trực tiếp
    // điều đó chỉ có thể chứng mik 1 điều sendable -:>. thực sự chỉ cần với việc gửi 1 số đối tượng giữa các luồng khác nhau state là 1 vùng bộ nhớ
    // cố định dc quy định
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isConfigured = supabaseClient.isConfigured()
                return .none
       // tại sao lại return none điều đó chỉ có thể hiểu dc là
                // return có thể là 2 thứ none -> 1 giá trị tạm thời dc sử dụng render-> or là sự gọi tới 1 action khác
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
// ở đây thấy 1 issues đó là 1 số data như fullname và email hay password _> onchaneg có thể đây là bindable thể hiện việc 2 giá trị àny và
                // gia trị trên màn hinfh được đồng bộ hóa với nhau
            case .togglePasswordVisibilityTapped:
                state.isPasswordVisible.toggle()
                return .run { _ in
                    await hapticClient.selection()
                }
       // ở đây khi người dùng bấm hiển thị mật khẩu -> set ispasswordvisible togggle có thể nhưviệc set sang giá trị đối
                // điều này thực hiện 1 hàm gọi run(_ in await. haptilient) client này thực hiện 1 tiến trình đồng bộ là nó sẽ thực hiện tạo âm thanh
            case .toggleModeTapped:
                state.isSignUp.toggle()
                state.errorMessage = nil
                state.message = nil
                return .run { _ in
                    await hapticClient.selection()
                }
                //

            case .continueAsGuestTapped:
                guard state.allowGuest else { return .none }
                return .merge(
                    .send(.delegate(.didContinueAsGuest)),// điều này khiến task này giải phóng ngay
                    .run { _ in
                        await hapticClient.lightImpact()
                    }
                )

            case .dismissTapped:
                return .send(.delegate(.didDismiss))
                  // guard state.allowGuest điều này check 1 vấn đề là allowguest có ok 0 nếu ko thì return nonn? tại sao lại phải guard?
                 // merge thực hiện 2 tiến trình song song. 1 là gửi 1  sự kiện action khác cần xử lí
                // 2 là chạy 1 thằng để kêu  âm thanh
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
