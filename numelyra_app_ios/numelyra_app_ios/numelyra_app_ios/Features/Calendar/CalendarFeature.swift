import ComposableArchitecture
import Foundation

@Reducer
struct CalendarFeature {
    @ObservableState
    struct State: Equatable {
        /// Ngày Dương lịch đang được chọn và làm đầu vào cho toàn bộ nội dung lịch.
        var selectedDate: Date
        /// Hồ sơ đang hoạt động; ngày sinh của hồ sơ được dùng để cá nhân hóa snapshot lịch.
        var profile: UserProfile?
        /// Kết quả Hoàng lịch/Âm lịch đã tính cho `selectedDate` và hồ sơ hiện tại.
        var snapshot: LunarDaySnapshot?
        /// Câu ca dao được chọn theo ngày, tải bất đồng bộ từ cơ sở dữ liệu cục bộ.
        var caDao: CaDaoRecord?
        /// Metadata tranh minh họa được chọn theo ngày Âm lịch hiện tại.
        var art: CalendarArtItem?
        /// Dữ liệu ảnh tranh tải từ xa hoặc lấy từ cache; `nil` để View dùng ảnh fallback đi kèm app.
        var remoteArtData: Data?
        /// Cho biết thao tác đọc ca dao cho ngày hiện tại đang diễn ra.
        var isLoadingCaDao = false
        /// Dirty flag yêu cầu tính lại snapshot khi hồ sơ đổi trước lần xuất hiện kế tiếp của màn hình.
        var needsRefresh = false

        /// State của sheet chọn ngày; có giá trị khi bộ chọn ngày đang được trình bày.
        @Presents
        var datePicker: CalendarDatePickerFeature.State?
        /// State của sheet chi tiết Hoàng lịch hoặc văn hóa; có giá trị khi sheet đang được trình bày.
        @Presents
        var detail: CalendarDetailFeature.State?

        init(selectedDate: Date = Date(), profile: UserProfile? = nil, needsRefresh: Bool = false) {
            self.selectedDate = selectedDate
            self.profile = profile
            self.needsRefresh = needsRefresh
        }
    }

    enum Action: Equatable {
        case onAppear
        case profileUpdated(UserProfile?)
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
        case prefetch
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.snapshot == nil || state.needsRefresh else { return .none }
                state.needsRefresh = false
                return refresh(&state, date: state.selectedDate)

            case let .profileUpdated(newProfile):
                let oldBirthDate = state.profile?.birthDate
                let newBirthDate = newProfile?.birthDate
                let oldID = state.profile?.id
                let newID = newProfile?.id
                state.profile = newProfile

                guard oldID != newID || oldBirthDate != newBirthDate else {
                    return .none
                }

                if state.snapshot != nil {
                    state.needsRefresh = true
                }
                return .none

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
        state.isLoadingCaDao = true

        if let url = art.imageURL, let cached = calendarArtClient.cachedImage(url) {
            state.remoteArtData = cached
        } else {
            state.remoteArtData = nil
        }

        let caDaoEffect: Effect<Action> = .run { send in
            await send(.contentLoaded(date: date, caDao: caDaoClient.dailyCaDao(date)))
        }
        .cancellable(id: CancelID.caDao, cancelInFlight: true)

        let artEffect: Effect<Action>
        if state.remoteArtData != nil {
            artEffect = .none
        } else if let url = art.imageURL {
            artEffect = .run { send in
                let data = try? await calendarArtClient.loadImage(url)
                await send(.artImageLoaded(artID: art.id, data))
            }
            .cancellable(id: CancelID.artImage, cancelInFlight: true)
        } else {
            artEffect = .none
        }

        let prefetchEffect: Effect<Action>
        if art.imageURL != nil {
            prefetchEffect = .run { [date] _ in
                await calendarArtClient.prefetch(date)
            }
            .cancellable(id: CancelID.prefetch, cancelInFlight: true)
        } else {
            prefetchEffect = .none
        }

        return .merge(caDaoEffect, artEffect, prefetchEffect)
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
