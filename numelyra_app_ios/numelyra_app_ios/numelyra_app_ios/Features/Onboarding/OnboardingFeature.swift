import ComposableArchitecture
import Foundation

@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var fullName: String = ""
        var birthDay: String = ""
        var birthMonth: String = ""
        var birthYear: String = ""
        var gender: Gender = .male
        var isSaving: Bool = false
        var errorMessage: String?

        init(
            fullName: String = "",
            birthDay: String = "",
            birthMonth: String = "",
            birthYear: String = "",
            gender: Gender = .male,
            isSaving: Bool = false,
            errorMessage: String? = nil
        ) {
            self.fullName = fullName
            self.birthDay = birthDay
            self.birthMonth = birthMonth
            self.birthYear = birthYear
            self.gender = gender
            self.isSaving = isSaving
            self.errorMessage = errorMessage
        }
    }

    enum Action: Equatable {
        case fullNameChanged(String)
        case birthDayChanged(String)
        case birthMonthChanged(String)
        case birthYearChanged(String)
        case genderChanged(Gender)
        case submitTapped
        case errorMessageDismissed
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable, Sendable {
            case didComplete(UserProfile)
        }
    }

    @Dependency(\.userProfileClient) var userProfileClient
    @Dependency(\.hapticClient) var hapticClient
    @Dependency(\.uuid) var uuid

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .fullNameChanged(name):
                state.fullName = name
                state.errorMessage = nil
                return .none

            case let .birthDayChanged(day):
                state.birthDay = String(day.filter(\.isNumber).prefix(2))
                state.errorMessage = nil
                return .none

            case let .birthMonthChanged(month):
                state.birthMonth = String(month.filter(\.isNumber).prefix(2))
                state.errorMessage = nil
                return .none

            case let .birthYearChanged(year):
                state.birthYear = String(year.filter(\.isNumber).prefix(4))
                state.errorMessage = nil
                return .none

            case let .genderChanged(gender):
                state.gender = gender
                return .run { _ in await hapticClient.selection() }

            case .errorMessageDismissed:
                state.errorMessage = nil
                return .none

            case .submitTapped:
                let trimmedName = state.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else {
                    state.errorMessage = "Vui lòng nhập họ tên của bạn."
                    return .run { _ in await hapticClient.mediumImpact() }
                }

                guard let d = Int(state.birthDay),
                      let m = Int(state.birthMonth),
                      let y = Int(state.birthYear),
                      (1...31).contains(d),
                      (1...12).contains(m),
                      (1920...2026).contains(y)
                else {
                    state.errorMessage = "Vui lòng kiểm tra lại ngày/tháng/năm sinh."
                    return .run { _ in await hapticClient.mediumImpact() }
                }

                let birthDate = String(format: "%04d-%02d-%02d", y, m, d)
                state.isSaving = true
                state.errorMessage = nil

                return .run { [gender = state.gender] send in
                    await hapticClient.lightImpact()
                    do {
                        let newProfile = UserProfile(
                            id: uuid().uuidString,
                            fullName: trimmedName,
                            birthDate: birthDate,
                            gender: gender,
                            isDefault: true
                        )
                        let saved = try userProfileClient.addProfile(newProfile)
                        await send(.delegate(.didComplete(saved)))
                    } catch {
                        let fallback = UserProfile(
                            id: uuid().uuidString,
                            fullName: trimmedName,
                            birthDate: birthDate,
                            gender: gender,
                            isDefault: true
                        )
                        userProfileClient.saveAllProfiles([fallback])
                        userProfileClient.setActiveProfileID(fallback.id)
                        await send(.delegate(.didComplete(fallback)))
                    }
                }

            case .delegate:
                return .none
            }
        }
    }
}
