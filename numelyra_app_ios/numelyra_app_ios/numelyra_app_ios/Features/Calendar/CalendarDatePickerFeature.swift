import ComposableArchitecture
import Foundation

@Reducer
struct CalendarDatePickerFeature {
    @ObservableState
    struct State: Equatable {
        /// Ngày đang được chọn ở màn hình lịch chính, dùng để đánh dấu ô tương ứng trong lưới.
        var selectedDate: Date
        /// Tháng đang được hiển thị và được thay đổi bởi nút tháng trước/tháng sau.
        var displayedMonth: Date
        /// Danh sách ngày tạo lưới tháng 6 tuần, bao gồm các ngày đệm ở hai đầu khi cần.
        var days: [Date]
    }

    enum Action: Equatable {
        case previousMonthTapped
        case nextMonthTapped
        case dateTapped(Date)
        case todayTapped
        case closeTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case selected(Date)
        }
    }

    @Dependency(\.lunarClient) var lunarClient
    @Dependency(\.date.now) var now
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .previousMonthTapped:
                state.displayedMonth = lunarClient.moveDate(state.displayedMonth, -1, .month)
                state.days = lunarClient.monthPickerDays(state.displayedMonth)
                return .none

            case .nextMonthTapped:
                state.displayedMonth = lunarClient.moveDate(state.displayedMonth, 1, .month)
                state.days = lunarClient.monthPickerDays(state.displayedMonth)
                return .none

            case let .dateTapped(date):
                return .send(.delegate(.selected(date)))

            case .todayTapped:
                return .send(.delegate(.selected(now)))

            case .closeTapped:
                return .run { _ in await dismiss() }

            case .delegate:
                return .none
            }
        }
    }
}
