import ComposableArchitecture
import Foundation

@Reducer
struct CalendarDetailFeature {
    enum Mode: Equatable, Sendable {
        case auspicious
        case culture

        var title: String {
            switch self {
            case .auspicious: "HOÀNG LỊCH & VIỆC CÁT HUNG"
            case .culture: "ĐIỂN TÍCH & NGUYÊN TÁC VĂN HỌC"
            }
        }

        var icon: String {
            switch self {
            case .auspicious: "safari"
            case .culture: "book.closed"
            }
        }
    }

    @ObservableState
    struct State: Equatable {
        var mode: Mode
        var snapshot: LunarDaySnapshot
        var caDao: CaDaoRecord?
        var art: CalendarArtItem
        var remoteImageData: Data?
    }

    enum Action: Equatable {
        case closeTapped
    }

    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .closeTapped:
                return .run { _ in await dismiss() }
            }
        }
    }
}
