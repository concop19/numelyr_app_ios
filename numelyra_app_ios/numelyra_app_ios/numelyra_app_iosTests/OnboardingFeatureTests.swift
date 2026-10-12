import ComposableArchitecture
import Foundation
import XCTest
@testable import numelyra_app_ios

@MainActor
final class OnboardingFeatureTests: XCTestCase {
    func testValidationRejectsEmptyNameAndInvalidBirthDates() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        } withDependencies: {
            $0.hapticClient.mediumImpact = {}
            $0.hapticClient.selection = {}
        }

        // 1. Submit with empty name
        await store.send(.submitTapped) {
            $0.errorMessage = "Vui lòng nhập họ tên của bạn."
        }

        // 2. Set valid name but invalid date
        await store.send(.fullNameChanged("Nguyễn Văn An")) {
            $0.fullName = "Nguyễn Văn An"
            $0.errorMessage = nil
        }
        await store.send(.birthDayChanged("35")) {
            $0.birthDay = "35"
        }
        await store.send(.birthMonthChanged("13")) {
            $0.birthMonth = "13"
        }
        await store.send(.birthYearChanged("1998")) {
            $0.birthYear = "1998"
        }
        await store.send(.submitTapped) {
            $0.errorMessage = "Vui lòng kiểm tra lại ngày/tháng/năm sinh."
        }
    }

    func testValidSubmissionSavesProfileAndEmitsDelegateDidComplete() async {
        let savedProfileHolder = LockIsolated<UserProfile?>(nil)
        let testUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let expectedProfile = UserProfile(
            id: testUUID.uuidString,
            fullName: "Trần Thị Bình",
            birthDate: "1999-08-15",
            gender: .female,
            isDefault: true
        )

        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        } withDependencies: {
            $0.uuid = .constant(testUUID)
            $0.hapticClient.lightImpact = {}
            $0.hapticClient.selection = {}
            $0.userProfileClient.addProfile = { profile in
                savedProfileHolder.setValue(profile)
                return profile
            }
        }

        await store.send(.fullNameChanged("Trần Thị Bình")) {
            $0.fullName = "Trần Thị Bình"
        }
        await store.send(.birthDayChanged("15")) {
            $0.birthDay = "15"
        }
        await store.send(.birthMonthChanged("08")) {
            $0.birthMonth = "08"
        }
        await store.send(.birthYearChanged("1999")) {
            $0.birthYear = "1999"
        }
        await store.send(.genderChanged(.female)) {
            $0.gender = .female
        }

        await store.send(.submitTapped) {
            $0.isSaving = true
        }

        await store.receive(.delegate(.didComplete(expectedProfile)))

        XCTAssertEqual(savedProfileHolder.value, expectedProfile)
    }
}
