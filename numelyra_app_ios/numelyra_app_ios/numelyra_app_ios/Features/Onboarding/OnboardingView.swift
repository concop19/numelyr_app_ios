import ComposableArchitecture
import SwiftUI

struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            AppScreenBackground()
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    mascotSection
                    titleSection
                    formSection
                    submitButton
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .frame(maxWidth: AppTheme.Size.contentMaxWidth)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .preferredColorScheme(.dark)
        .alert(
            "Thông báo",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.send(.errorMessageDismissed) } }
            )
        ) {
            Button("Đã hiểu") {
                store.send(.errorMessageDismissed)
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    // MARK: - Mascot
    private var mascotSection: some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0x16142A))
                .frame(width: 88, height: 88)
                .overlay(
                    Circle()
                        .stroke(AppTheme.Colors.primaryBright, lineWidth: 2)
                )
                .shadow(color: AppTheme.Colors.primaryBright.opacity(0.3), radius: 10)

            Text("🐱")
                .font(.system(size: 42))

            Text("✨")
                .font(.system(size: 20))
                .offset(x: 32, y: -30)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Titles
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Xin chào, tôi là Tiểu Linh Miêu!")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Hãy cho tôi biết đôi điều về bạn để tôi có thể tư vấn phong thủy, lịch cá nhân và vận mệnh chính xác hơn nhé.")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, 24)
        }
    }

    // MARK: - Form
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Họ tên
            VStack(alignment: .leading, spacing: 6) {
                Text("Họ và tên")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xCBD5E1))

                TextField(
                    "Nguyễn Văn A",
                    text: Binding(
                        get: { store.fullName },
                        set: { store.send(.fullNameChanged($0)) }
                    )
                )
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(hex: 0x1C1A32))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: 0x2E2954), lineWidth: 1)
                )
                .foregroundStyle(.white)
            }

            // Ngày sinh
            VStack(alignment: .leading, spacing: 6) {
                Text("Ngày sinh (dương lịch)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xCBD5E1))

                HStack(spacing: 8) {
                    TextField(
                        "DD",
                        text: Binding(
                            get: { store.birthDay },
                            set: { store.send(.birthDayChanged($0)) }
                        )
                    )
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 14)
                    .background(Color(hex: 0x1C1A32))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: 0x2E2954), lineWidth: 1)
                    )
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)

                    Text("/")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: 0x64748B))

                    TextField(
                        "MM",
                        text: Binding(
                            get: { store.birthMonth },
                            set: { store.send(.birthMonthChanged($0)) }
                        )
                    )
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 14)
                    .background(Color(hex: 0x1C1A32))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: 0x2E2954), lineWidth: 1)
                    )
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)

                    Text("/")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: 0x64748B))

                    TextField(
                        "YYYY",
                        text: Binding(
                            get: { store.birthYear },
                            set: { store.send(.birthYearChanged($0)) }
                        )
                    )
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 14)
                    .background(Color(hex: 0x1C1A32))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: 0x2E2954), lineWidth: 1)
                    )
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity * 1.4)
                }
            }

            // Giới tính
            VStack(alignment: .leading, spacing: 6) {
                Text("Giới tính")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xCBD5E1))

                HStack(spacing: 12) {
                    genderOption(gender: .male, label: "👨 Nam")
                    genderOption(gender: .female, label: "👩 Nữ")
                }
            }
        }
        .padding(.bottom, 28)
    }

    private func genderOption(gender: Gender, label: String) -> some View {
        let isSelected = store.gender == gender
        return Button {
            store.send(.genderChanged(gender))
        } label: {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isSelected ? AppTheme.Colors.primaryBright : Color(hex: 0x94A3B8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(isSelected ? Color(hex: 0x26224A) : Color(hex: 0x1C1A32))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? AppTheme.Colors.primaryBright : Color(hex: 0x2E2954), lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            store.send(.submitTapped)
        } label: {
            Group {
                if store.isSaving {
                    ProgressView()
                        .tint(Color(hex: 0x0B0B14))
                } else {
                    Text("✨ Bắt đầu hành trình")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: 0x0B0B14))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(AppTheme.Gradients.goldAction)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: AppTheme.Colors.primaryBright.opacity(0.35), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(store.isSaving)
        .opacity(store.isSaving ? 0.7 : 1.0)
    }
}

#Preview {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }
    )
}
