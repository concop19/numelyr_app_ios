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
        /// Chế độ nội dung của sheet: thông tin cát hung hoặc điển tích/văn học.
        var mode: Mode
        /// Snapshot Âm lịch/Hoàng lịch của ngày đang được trình bày chi tiết.
        var snapshot: LunarDaySnapshot
        /// Câu ca dao của ngày; có thể được cập nhật sau khi sheet đã mở nếu tải chưa xong.
        var caDao: CaDaoRecord?
        /// Metadata tranh minh họa gắn với ngày Âm lịch đang xem.
        var art: CalendarArtItem
        /// Dữ liệu ảnh từ xa dùng trong sheet; `nil` để dùng asset fallback của `art`.
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
