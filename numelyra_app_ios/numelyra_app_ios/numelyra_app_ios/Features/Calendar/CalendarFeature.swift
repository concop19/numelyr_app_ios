import ComposableArchitecture
import Foundation

@Reducer
struct CalendarFeature {
    @ObservableState
    struct State: Equatable {
        var selectedDate: Date
        var profile: UserProfile?
        var snapshot: LunarDaySnapshot?
        var caDao: CaDaoRecord?
        var art: CalendarArtItem?
        var remoteArtData: Data?
        var isLoadingCaDao = false

        @Presents
        var datePicker: CalendarDatePickerFeature.State?
        // the hien nhieu man hinh trong. man hinh
        @Presents
        var detail: CalendarDetailFeature.State?

        init(selectedDate: Date = Date(), profile: UserProfile? = nil) {
            self.selectedDate = selectedDate
            self.profile = profile
        }
    }

    enum Action: Equatable {
        case onAppear
        case previousDayTapped
        case nextDayTapped
        case todayTapped
        case weekDayTapped(Date)
        case datePickerTapped
        case auspiciousCardTapped
        case cultureTapped
        case contentLoaded(date: Date, caDao: CaDaoRecord)
        case artImageLoaded(artID: String, Data?)
        case datePicker(PresentationAction<CalendarDatePickerFeature.Action>)
        case detail(PresentationAction<CalendarDetailFeature.Action>)
    }
    // nếu tồn tại 1 featủe và view khac như sheet làm giao diện con trong giao diện chính ta có thể dùng  đặt action và state cùng tên
    // với action sẽ nhân đối số đầu vòa presentationAction< feature đó>

    @Dependency(\.lunarClient) var lunarClient
    @Dependency(\.caDaoClient) var caDaoClient
    @Dependency(\.calendarArtClient) var calendarArtClient
    @Dependency(\.hapticClient) var hapticClient
    @Dependency(\.date.now) var now

    private nonisolated enum CancelID: Hashable, Sendable {
        case caDao
        case artImage
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.snapshot == nil else { return .none }
                return refresh(&state, date: state.selectedDate)

            case .previousDayTapped:
                let date = lunarClient.moveDate(state.selectedDate, -1, .day)
                return select(&state, date: date)

            case .nextDayTapped:
                let date = lunarClient.moveDate(state.selectedDate, 1, .day)
                return select(&state, date: date)

            case .todayTapped:
                return select(&state, date: now)

            case let .weekDayTapped(date):
                return select(&state, date: date)

            case .datePickerTapped:
                state.datePicker = CalendarDatePickerFeature.State(
                    selectedDate: state.selectedDate,
                    displayedMonth: state.selectedDate,
                    days: lunarClient.monthPickerDays(state.selectedDate)
                )
                return .run { _ in await hapticClient.lightImpact() }

            case .auspiciousCardTapped:
                guard let detail = detailState(from: state, mode: .auspicious) else { return .none }
                state.detail = detail
                return .run { _ in await hapticClient.lightImpact() }

            case .cultureTapped:
                guard let detail = detailState(from: state, mode: .culture) else { return .none }
                state.detail = detail
                return .run { _ in await hapticClient.lightImpact() }

            case let .contentLoaded(date, caDao):
                guard LunarService.defaultCalendar.isDate(date, inSameDayAs: state.selectedDate) else {
                    return .none
                }
                state.caDao = caDao
                state.isLoadingCaDao = false
                state.detail?.caDao = caDao
                return .none

            case let .artImageLoaded(artID, data):
                guard state.art?.id == artID else { return .none }
                state.remoteArtData = data
                if state.detail?.art.id == artID {
                    state.detail?.remoteImageData = data
                }
                return .none

            case let .datePicker(.presented(.delegate(.selected(date)))):
                state.datePicker = nil
                return select(&state, date: date)

            case .datePicker:
                return .none

            case .detail:
                return .none
            }
        }
        .ifLet(\.$datePicker, action: \.datePicker) {
            CalendarDatePickerFeature()
        }
        .ifLet(\.$detail, action: \.detail) {
            CalendarDetailFeature()
        }
    }

    private func select(_ state: inout State, date: Date) -> Effect<Action> {
        state.selectedDate = date
        let refreshEffect = refresh(&state, date: date)
        return .merge(
            refreshEffect,
            .run { _ in await hapticClient.selection() }
        )
    }

    private func refresh(_ state: inout State, date: Date) -> Effect<Action> {
        let birthDate = state.profile?.birthDate
        let snapshot = lunarClient.daySnapshot(date, birthDate, nil)
        let art = calendarArtClient.item(snapshot.lunarDate)

        state.snapshot = snapshot
        state.art = art
        state.caDao = nil
        state.remoteArtData = nil
        state.isLoadingCaDao = true

        let caDaoEffect: Effect<Action> = .run { send in
            await send(.contentLoaded(date: date, caDao: caDaoClient.dailyCaDao(date)))
        }
        .cancellable(id: CancelID.caDao, cancelInFlight: true)

        let artEffect: Effect<Action>
        if let url = art.imageURL {
            artEffect = .run { send in
                let data = try? await calendarArtClient.loadImage(url)
                await send(.artImageLoaded(artID: art.id, data))
            }
            .cancellable(id: CancelID.artImage, cancelInFlight: true)
        } else {
            artEffect = .none
        }

        return .merge(caDaoEffect, artEffect)
    }

    private func detailState(from state: State, mode: CalendarDetailFeature.Mode) -> CalendarDetailFeature.State? {
        guard let snapshot = state.snapshot, let art = state.art else { return nil }
        return CalendarDetailFeature.State(
            mode: mode,
            snapshot: snapshot,
            caDao: state.caDao,
            art: art,
            remoteImageData: state.remoteArtData
        )
    }
}
