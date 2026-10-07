import ComposableArchitecture
import UIKit
/*Đây là một dependency client của TCA để phát haptic feedback (rung nhẹ của iPhone) mà vẫn test được và không bị dính chặt vào UIKit.
 
 Nó làm gì?

 Cung cấp 4 kiểu rung:

 Hàm    Cảm giác    Dùng khi
 selection    tích tắc rất nhẹ    đổi lựa chọn, cuộn picker, chọn ngày
 lightImpact    chạm nhẹ    bấm nút thông thường
 mediumImpact    chạm vừa    hành động quan trọng hơn
 success    rung 2 nhịp báo thành công    lưu xong, hoàn tất tác vụ*/
@DependencyClient
struct HapticClient: Sendable {
    var selection: @Sendable () async -> Void
    var lightImpact: @Sendable () async -> Void
    var mediumImpact: @Sendable () async -> Void
    var success: @Sendable () async -> Void
}

extension HapticClient: DependencyKey {
    static let liveValue = Self(
        selection: {
            await MainActor.run {
                UISelectionFeedbackGenerator().selectionChanged()
            }
        },
        lightImpact: {
            await MainActor.run {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        },
        mediumImpact: {
            await MainActor.run {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        },
        success: {
            await MainActor.run {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    )

    static let testValue = Self(
        selection: {},
        lightImpact: {},
        mediumImpact: {},
        success: {}
    )
}

extension DependencyValues {
    var hapticClient: HapticClient {
        get { self[HapticClient.self] }
        set { self[HapticClient.self] = newValue }
    }
}
