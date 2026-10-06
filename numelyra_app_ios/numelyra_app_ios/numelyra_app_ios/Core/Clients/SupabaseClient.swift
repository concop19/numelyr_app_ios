import ComposableArchitecture
import Foundation
import Supabase

@DependencyClient
nonisolated struct SupabaseClient {
    var isConfigured: @Sendable () -> Bool = { false }
    /// Trả JWT hiện tại nếu người dùng đã đăng nhập. Astrology và các API client
    /// dùng closure này thay vì phụ thuộc trực tiếp vào Supabase SDK.
    var accessToken: @Sendable () async -> String?
}

extension SupabaseClient: DependencyKey {
    static let liveValue = Self(
        isConfigured: { false },
        accessToken: { nil }
    )
    static let testValue = Self()
    static let previewValue = Self(
        isConfigured: { true },
        accessToken: { nil }
    )
}

extension DependencyValues {
    var supabaseClient: SupabaseClient {
        get { self[SupabaseClient.self] }
        set { self[SupabaseClient.self] = newValue }
    }
}
