import ComposableArchitecture
import Foundation

@Reducer
struct CalendarDatePickerFeature {
    @ObservableState
    struct State: Equatable {
        var selectedDate: Date
        var displayedMonth: Date
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
