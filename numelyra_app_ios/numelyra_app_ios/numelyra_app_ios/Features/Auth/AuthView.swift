import ComposableArchitecture
import SwiftUI

struct AuthView: View {
    @Bindable var store: StoreOf<AuthFeature>

    var body: some View {
        ZStack {
            AppTheme.Colors.Auth.safeAreaBackground
                .ignoresSafeArea()

            AppScreenBackground()
                .allowsHitTesting(false)

            skyDecorations
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSection
                        authCard
                    }
                    .padding(20)
                    .frame(maxWidth: AppTheme.Size.contentMaxWidth)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .center)
                }
                .scrollDismissesKeyboard(.interactively)
            }

            if !store.allowGuest {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            store.send(.dismissTapped)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.white.opacity(0.6))
                                .padding(16)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Đóng")
                    }
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            store.send(.onAppear)
        }
    }

    // MARK: - Sky Decorative Layer

    private var skyDecorations: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Text("✦")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.Colors.Auth.starOneColor)
                    .padding(.top, 56)
                    .padding(.leading, 30)

                Text("✧")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.Colors.Auth.starTwoColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 44)
                    .padding(.trailing, 38)

                Text("✦")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.Colors.Auth.starThreeColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 178)
                    .padding(.trailing, 26)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .clipped()
        }
    }

    // MARK: - Hero Mascot

    private var heroSection: some View {
        ZStack(alignment: .top) {
            RadialGradient(
                colors: [AppTheme.Colors.Auth.heroGlow, .clear],
                center: .center,
                startRadius: 8,
                endRadius: 118
            )
            .frame(width: 236, height: 236)
            .allowsHitTesting(false)

            Image(appAsset: .authMascot)
                .resizable()
                .scaledToFit()
                .frame(width: 245, height: 270)
                .padding(.top, -26)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 230)
        .clipped()
    }

    // MARK: - Auth Card

    private var authCard: some View {
        VStack(spacing: 0) {
            Text("✦ WELCOME TO")
                .font(.system(size: 12, weight: .heavy))
                .kerning(2)
                .foregroundStyle(AppTheme.Colors.Auth.eyebrow)
                .multilineTextAlignment(.center)

            Text("NUMELYRA")
                .font(.system(size: 34, weight: .black))
                .kerning(0.4)
                .foregroundStyle(AppTheme.Colors.Auth.brand)
                .shadow(color: AppTheme.Colors.Auth.brandGlow, radius: 10, x: 0, y: 2)
                .multilineTextAlignment(.center)
                .padding(.top, 2)

            Text("Unlock your magic ♡")
                .font(.system(size: 17, weight: .regular))
                .italic()
                .foregroundStyle(AppTheme.Colors.Auth.tagline)
                .multilineTextAlignment(.center)
                .padding(.top, 2)

            Text(store.descriptionText)
                .font(.system(size: 13))
                .lineSpacing(4)
                .foregroundStyle(AppTheme.Colors.Auth.description)
                .multilineTextAlignment(.center)
                .padding(.top, 14)
                .padding(.bottom, 18)

            googleSignInButton

            dividerRow

            formFields

            feedbackSection

            submitButton

            modeToggleButton

            if store.allowGuest {
                guestButton
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                AppTheme.Gradients.Auth.cardGradient
                AppTheme.Gradients.Auth.cardOverlay
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppTheme.Colors.Auth.cardBorder, lineWidth: 1)
        }
        .shadow(
            color: AppTheme.Colors.Auth.cardShadow,
            radius: 21,
            x: 0,
            y: 10
        )
    }

    // MARK: - Google Sign-In Button

    private var googleSignInButton: some View {
        Button {
            store.send(.googleSignInTapped)
        } label: {
            HStack(spacing: 0) {
                if store.isGoogleSubmitting {
                    ProgressView()
                        .tint(AppTheme.Colors.Auth.eyebrow)
                } else {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.Auth.googleBadgeRed)
                            .frame(width: 24, height: 24)

                        Text("G")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(Color.white)
                    }
                    .padding(.trailing, 10)

                    Text("Tiếp tục với Google")
                        .font(.system(size: 14, weight: .bold))
                        .kerning(0.2)
                        .foregroundStyle(AppTheme.Colors.Auth.googleButtonText)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, 16)
            .background(AppTheme.Gradients.Auth.googleButtonGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.Colors.Auth.googleBorder, lineWidth: 1.5)
            }
            .shadow(
                color: AppTheme.Colors.Auth.googleShadow,
                radius: 9,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(.plain)
        .disabled(store.isActionDisabled)
        .opacity(store.isActionDisabled ? 0.55 : 1.0)
        .padding(.bottom, 8)
        .accessibilityLabel("Tiếp tục với Google")
    }

    // MARK: - Divider

    private var dividerRow: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.Colors.Auth.dividerLine)
                .frame(height: 1)

            Text("HOẶC VỚI EMAIL")
                .font(.system(size: 11, weight: .bold))
                .kerning(0.8)
                .foregroundStyle(AppTheme.Colors.Auth.dividerText)
                .padding(.horizontal, 10)
                .fixedSize()

            Rectangle()
                .fill(AppTheme.Colors.Auth.dividerLine)
                .frame(height: 1)
        }
        .padding(.vertical, 14)
    }

    // MARK: - Form Inputs

    private var formFields: some View {
        VStack(spacing: 0) {
            if store.isSignUp {
                TextField(
                    "",
                    text: Binding(
                        get: { store.fullName },
                        set: { store.send(.fullNameChanged($0)) }
                    ),
                    prompt: Text("Họ và tên").foregroundStyle(AppTheme.Colors.Auth.placeholder)
                )
                .textInputAutocapitalization(.words)
                .textContentType(.name)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.Colors.Auth.inputText)
                .tint(AppTheme.Colors.Auth.cursorTint)
                .padding(.horizontal, 14)
                .frame(minHeight: 50)
                .background(AppTheme.Colors.Auth.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(AppTheme.Colors.Auth.inputBorder, lineWidth: 1)
                }
                .padding(.bottom, 10)
                .accessibilityLabel("Họ và tên")
            }

            TextField(
                "",
                text: Binding(
                    get: { store.email },
                    set: { store.send(.emailChanged($0)) }
                ),
                prompt: Text("Email").foregroundStyle(AppTheme.Colors.Auth.placeholder)
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .font(.system(size: 15))
            .foregroundStyle(AppTheme.Colors.Auth.inputText)
            .tint(AppTheme.Colors.Auth.cursorTint)
            .padding(.horizontal, 14)
            .frame(minHeight: 50)
            .background(AppTheme.Colors.Auth.inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(AppTheme.Colors.Auth.inputBorder, lineWidth: 1)
            }
            .padding(.bottom, 10)
            .accessibilityLabel("Email")

            HStack(spacing: 0) {
                Group {
                    if store.isPasswordVisible {
                        TextField(
                            "",
                            text: Binding(
                                get: { store.password },
                                set: { store.send(.passwordChanged($0)) }
                            ),
                            prompt: Text("Mật khẩu").foregroundStyle(AppTheme.Colors.Auth.placeholder)
                        )
                    } else {
                        SecureField(
                            "",
                            text: Binding(
                                get: { store.password },
                                set: { store.send(.passwordChanged($0)) }
                            ),
                            prompt: Text("Mật khẩu").foregroundStyle(AppTheme.Colors.Auth.placeholder)
                        )
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(store.isSignUp ? .newPassword : .password)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.Colors.Auth.inputText)
                .tint(AppTheme.Colors.Auth.cursorTint)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 50)
                .accessibilityLabel("Mật khẩu")

                Button {
                    store.send(.togglePasswordVisibilityTapped)
                } label: {
                    Text(store.passwordToggleTitle)
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(AppTheme.Colors.Auth.showPasswordText)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(store.isPasswordVisible ? "Ẩn mật khẩu" : "Hiện mật khẩu")
            }
            .frame(minHeight: 50)
            .background(AppTheme.Colors.Auth.inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(AppTheme.Colors.Auth.inputBorder, lineWidth: 1)
            }
        }
    }

    // MARK: - Feedback Messages

    private var feedbackSection: some View {
        VStack(spacing: 0) {
            if let unconfigured = store.unconfiguredNotice {
                Text(unconfigured)
                    .font(.system(size: 12))
                    .lineSpacing(3)
                    .foregroundStyle(AppTheme.Colors.Auth.warningText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }

            if let errorMessage = store.errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .lineSpacing(3)
                    .foregroundStyle(AppTheme.Colors.Auth.errorText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .accessibilityAddTraits(.isStaticText)
            }

            if let message = store.message, !message.isEmpty {
                Text(message)
                    .font(.system(size: 12))
                    .lineSpacing(3)
                    .foregroundStyle(AppTheme.Colors.Auth.successText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }
        }
    }

    // MARK: - Primary Submit Button

    private var submitButton: some View {
        Button {
            store.send(.submitTapped)
        } label: {
            Group {
                if store.isSubmitting {
                    ProgressView()
                        .tint(AppTheme.Colors.Auth.submitText)
                } else {
                    HStack(spacing: 8) {
                        Text(store.submitButtonTitle)
                            .font(.system(size: 14, weight: .black))
                            .kerning(0.4)
                            .foregroundStyle(AppTheme.Colors.Auth.submitText)

                        Image(systemName: "arrow.forward")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppTheme.Colors.Auth.submitText)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(AppTheme.Gradients.Auth.submitGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.Colors.Auth.submitBorder, lineWidth: 1)
            }
            .shadow(
                color: AppTheme.Colors.Auth.submitShadow,
                radius: 12,
                x: 0,
                y: 6
            )
        }
        .buttonStyle(.plain)
        .disabled(store.isActionDisabled)
        .opacity(store.isActionDisabled ? 0.55 : 1.0)
        .padding(.top, 16)
        .accessibilityLabel(store.submitButtonTitle)
    }

    // MARK: - Mode Switch & Guest Actions

    private var modeToggleButton: some View {
        Button {
            store.send(.toggleModeTapped)
        } label: {
            HStack(spacing: 0) {
                Text(store.modePromptPrefix)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.Colors.Auth.description)

                Text(store.modePromptEmphasis)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(AppTheme.Colors.Auth.modeEmphasis)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 17)
            .padding(.bottom, 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(store.modePromptPrefix)\(store.modePromptEmphasis)")
    }

    private var guestButton: some View {
        Button {
            store.send(.continueAsGuestTapped)
        } label: {
            Text("Tiếp tục với tư cách Khách")
                .font(.system(size: 12))
                .underline()
                .foregroundStyle(AppTheme.Colors.Auth.guestText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tiếp tục với tư cách Khách")
    }
}

#Preview("Đăng nhập") {
    AuthView(
        store: Store(initialState: AuthFeature.State()) {
            AuthFeature()
        } withDependencies: {
            $0.supabaseClient = .previewValue
            $0.hapticClient = .testValue
        }
    )
}

#Preview("Tạo tài khoản") {
    AuthView(
        store: Store(initialState: AuthFeature.State(isSignUp: true)) {
            AuthFeature()
        } withDependencies: {
            $0.supabaseClient = .previewValue
            $0.hapticClient = .testValue
        }
    )
}

#Preview("Chưa cấu hình Supabase") {
    AuthView(
        store: Store(initialState: AuthFeature.State(isConfigured: false)) {
            AuthFeature()
        } withDependencies: {
            $0.supabaseClient.isConfigured = { false }
            $0.hapticClient = .testValue
        }
    )
}
