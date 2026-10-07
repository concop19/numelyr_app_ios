import AuthenticationServices
import ComposableArchitecture
import Foundation
import Security
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Keychain Session Storage

public nonisolated enum AuthSessionKeychain {
    public static let service = "com.numelyra.app.auth"
    public static let account = "supabase_auth_session"

    public static func save(_ session: AuthSession, service: String = Self.service, account: String = Self.account) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    public static func load(service: String = Self.service, account: String = Self.account) -> AuthSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let session = try? JSONDecoder().decode(AuthSession.self, from: data)
        else {
            return nil
        }
        return session
    }

    public static func clear(service: String = Self.service, account: String = Self.account) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Supabase Auth & Profile Sync Service

public nonisolated enum SupabaseAuthService {
    private struct SupabaseUserPayload: Decodable, Sendable {
        var id: String
        var email: String?
        var userMetadata: UserMetadata?

        struct UserMetadata: Decodable, Sendable {
            var fullName: String?

            enum CodingKeys: String, CodingKey {
                case fullName = "full_name"
            }
        }

        enum CodingKeys: String, CodingKey {
            case id, email
            case userMetadata = "user_metadata"
        }
    }

    private struct SupabaseTokenResponse: Decodable, Sendable {
        var accessToken: String?
        var refreshToken: String?
        var expiresAt: Double?
        var expiresIn: Double?
        var user: SupabaseUserPayload?

        enum CodingKeys: String, CodingKey {
            case user
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresAt = "expires_at"
            case expiresIn = "expires_in"
        }
    }

    private struct SupabaseSignUpEnvelope: Decodable, Sendable {
        var id: String?
        var email: String?
        var accessToken: String?
        var refreshToken: String?
        var expiresAt: Double?
        var expiresIn: Double?
        var user: SupabaseUserPayload?
        var session: SupabaseTokenResponse?

        enum CodingKeys: String, CodingKey {
            case id, email, user, session
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresAt = "expires_at"
            case expiresIn = "expires_in"
        }
    }

    private struct SupabaseErrorEnvelope: Decodable, Sendable {
        var msg: String?
        var message: String?
        var errorDescription: String?
        var error: String?

        enum CodingKeys: String, CodingKey {
            case msg, message, error
            case errorDescription = "error_description"
        }

        var resolvedMessage: String? {
            for candidate in [errorDescription, msg, message, error] {
                if let trimmed = candidate?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !trimmed.isEmpty
                {
                    return trimmed
                }
            }
            return nil
        }
    }

    private struct SignInBody: Encodable, Sendable {
        var email: String
        var password: String
    }

    private struct SignUpBody: Encodable, Sendable {
        var email: String
        var password: String
        var data: Metadata?

        struct Metadata: Encodable, Sendable {
            var fullName: String?

            enum CodingKeys: String, CodingKey {
                case fullName = "full_name"
            }
        }
    }

    private struct RefreshBody: Encodable, Sendable {
        var refreshToken: String

        enum CodingKeys: String, CodingKey {
            case refreshToken = "refresh_token"
        }
    }

    private struct PKCEExchangeBody: Encodable, Sendable {
        var authCode: String
        var codeVerifier: String

        enum CodingKeys: String, CodingKey {
            case authCode = "auth_code"
            case codeVerifier = "code_verifier"
        }
    }

    private struct CloudNumerologyInsertPayload: Encodable, Sendable {
        var userId: String
        var name: String
        var birthDate: String

        enum CodingKeys: String, CodingKey {
            case name
            case userId = "user_id"
            case birthDate = "birth_date"
        }
    }

    public static func currentValidSession() async -> AuthSession? {
        guard let stored = AuthSessionKeychain.load() else { return nil }
        if let expiresAt = stored.expiresAt, expiresAt.timeIntervalSinceNow <= 30 {
            if let refreshed = try? await refreshSession(refreshToken: stored.refreshToken) {
                return refreshed
            }
        }
        return stored
    }

    public static func signIn(email: String, password: String) async throws -> AuthSession {
        let (baseURL, anonKey) = try requireConfiguration()
        var components = URLComponents(
            url: baseURL.appending(path: "auth/v1/token"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        guard let url = components?.url else {
            throw AuthError.signInFallback
        }

        let body = try JSONEncoder().encode(
            SignInBody(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
        )
        let data = try await sendAuthRequest(
            url: url,
            method: "POST",
            anonKey: anonKey,
            bearerToken: nil,
            body: body,
            fallbackError: AuthError.signInFallback.message
        )
        let decoded = try JSONDecoder().decode(SupabaseTokenResponse.self, from: data)
        guard let session = makeSession(from: decoded) else {
            throw AuthError.signInFallback
        }

        AuthSessionKeychain.save(session)
        await syncProfilesForUser(
            session: session,
            metadataFullName: decoded.user?.userMetadata?.fullName
        )
        return session
    }

    public static func signUp(
        email: String,
        password: String,
        fullName: String?
    ) async throws -> AuthSignUpResult {
        let (baseURL, anonKey) = try requireConfiguration()
        let url = baseURL.appending(path: "auth/v1/signup")
        let trimmedName = fullName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let metadata = (trimmedName?.isEmpty == false)
            ? SignUpBody.Metadata(fullName: trimmedName)
            : nil
        let body = try JSONEncoder().encode(
            SignUpBody(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                data: metadata
            )
        )
        let data = try await sendAuthRequest(
            url: url,
            method: "POST",
            anonKey: anonKey,
            bearerToken: nil,
            body: body,
            fallbackError: AuthError.signInFallback.message
        )
        let decoded = try JSONDecoder().decode(SupabaseSignUpEnvelope.self, from: data)
        let resolvedUser = decoded.user ?? decoded.session?.user
        let resolvedUserID = resolvedUser?.id ?? decoded.id
        let resolvedEmail = resolvedUser?.email ?? decoded.email

        let resolvedSession: AuthSession? = {
            if let nested = decoded.session, let session = makeSession(from: nested) {
                return session
            }
            guard let accessToken = decoded.accessToken,
                  let refreshToken = decoded.refreshToken,
                  let userID = resolvedUserID,
                  !accessToken.isEmpty,
                  !refreshToken.isEmpty
            else {
                return nil
            }
            let expiry = resolveExpiry(expiresAt: decoded.expiresAt, expiresIn: decoded.expiresIn)
            return AuthSession(
                accessToken: accessToken,
                refreshToken: refreshToken,
                userId: userID,
                userEmail: resolvedEmail,
                expiresAt: expiry
            )
        }()

        if let resolvedSession {
            AuthSessionKeychain.save(resolvedSession)
            await syncProfilesForUser(
                session: resolvedSession,
                metadataFullName: resolvedUser?.userMetadata?.fullName ?? trimmedName
            )
        }

        let needsEmailConfirmation = (resolvedUserID != nil && resolvedSession == nil)
        return AuthSignUpResult(
            needsEmailConfirmation: needsEmailConfirmation,
            session: resolvedSession,
            userId: resolvedUserID
        )
    }

    public static func signInWithGoogle() async throws -> AuthSession {
        let (baseURL, anonKey) = try requireConfiguration()
        let pkce = PKCEChallenge.random()

        var components = URLComponents(
            url: baseURL.appending(path: "auth/v1/authorize"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: AppConfig.authCallbackURL.absoluteString),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "code_challenge_method", value: pkce.method)
        ]
        guard let authorizeURL = components?.url else {
            throw AuthError.googleSignInFallback
        }

        let callbackURL = try await WebAuthSessionRunner.authenticate(
            url: authorizeURL,
            callbackScheme: AppConfig.authCallbackScheme
        )

        guard let payload = AuthEngine.parseOAuthCallback(callbackURL) else {
            throw AuthError.googleSignInFallback
        }

        switch payload {
        case let .error(message):
            throw AuthError(message: message)

        case let .pkceCode(code):
            let session = try await exchangePKCECode(
                code: code,
                codeVerifier: pkce.verifier,
                baseURL: baseURL,
                anonKey: anonKey
            )
            AuthSessionKeychain.save(session)
            await syncProfilesForUser(session: session, metadataFullName: nil)
            return session

        case let .implicitTokens(accessToken, refreshToken):
            let user = try await fetchUser(
                accessToken: accessToken,
                baseURL: baseURL,
                anonKey: anonKey
            )
            let session = AuthSession(
                accessToken: accessToken,
                refreshToken: refreshToken,
                userId: user.id,
                userEmail: user.email,
                expiresAt: Date().addingTimeInterval(3600)
            )
            AuthSessionKeychain.save(session)
            await syncProfilesForUser(
                session: session,
                metadataFullName: user.userMetadata?.fullName
            )
            return session
        }
    }

    public static func signOut() async throws {
        defer {
            AuthSessionKeychain.clear()
        }
        guard let (baseURL, anonKey) = try? requireConfiguration(),
              let session = AuthSessionKeychain.load()
        else {
            return
        }
        let url = baseURL.appending(path: "auth/v1/logout")
        _ = try? await sendAuthRequest(
            url: url,
            method: "POST",
            anonKey: anonKey,
            bearerToken: session.accessToken,
            body: nil,
            fallbackError: "Không thể đăng xuất."
        )
    }

    public static func syncLocalProfiles() async {
        guard let session = await currentValidSession() else { return }
        await syncProfilesForUser(session: session, metadataFullName: nil)
    }

    // MARK: - Internal Helpers

    private static func requireConfiguration() throws -> (URL, String) {
        guard let url = AppConfig.supabaseURL,
              let key = AppConfig.supabaseAnonKey
        else {
            throw AuthError.unconfigured
        }
        return (url, key)
    }

    private static func refreshSession(refreshToken: String) async throws -> AuthSession {
        let (baseURL, anonKey) = try requireConfiguration()
        var components = URLComponents(
            url: baseURL.appending(path: "auth/v1/token"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]
        guard let url = components?.url else {
            throw AuthError.signInFallback
        }
        let body = try JSONEncoder().encode(RefreshBody(refreshToken: refreshToken))
        let data = try await sendAuthRequest(
            url: url,
            method: "POST",
            anonKey: anonKey,
            bearerToken: nil,
            body: body,
            fallbackError: AuthError.signInFallback.message
        )
        let decoded = try JSONDecoder().decode(SupabaseTokenResponse.self, from: data)
        guard let session = makeSession(from: decoded) else {
            throw AuthError.signInFallback
        }
        AuthSessionKeychain.save(session)
        return session
    }

    private static func exchangePKCECode(
        code: String,
        codeVerifier: String,
        baseURL: URL,
        anonKey: String
    ) async throws -> AuthSession {
        var components = URLComponents(
            url: baseURL.appending(path: "auth/v1/token"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "grant_type", value: "pkce")]
        guard let url = components?.url else {
            throw AuthError.googleSignInFallback
        }
        let body = try JSONEncoder().encode(
            PKCEExchangeBody(authCode: code, codeVerifier: codeVerifier)
        )
        let data = try await sendAuthRequest(
            url: url,
            method: "POST",
            anonKey: anonKey,
            bearerToken: nil,
            body: body,
            fallbackError: AuthError.googleSignInFallback.message
        )
        let decoded = try JSONDecoder().decode(SupabaseTokenResponse.self, from: data)
        guard let session = makeSession(from: decoded) else {
            throw AuthError.googleSignInFallback
        }
        return session
    }

    private static func fetchUser(
        accessToken: String,
        baseURL: URL,
        anonKey: String
    ) async throws -> SupabaseUserPayload {
        let url = baseURL.appending(path: "auth/v1/user")
        let data = try await sendAuthRequest(
            url: url,
            method: "GET",
            anonKey: anonKey,
            bearerToken: accessToken,
            body: nil,
            fallbackError: AuthError.googleSignInFallback.message
        )
        return try JSONDecoder().decode(SupabaseUserPayload.self, from: data)
    }

    private static func syncProfilesForUser(
        session: AuthSession,
        metadataFullName: String?
    ) async {
        guard let (baseURL, anonKey) = try? requireConfiguration() else { return }

        do {
            let localProfiles = UserProfileStorage.loadAllProfiles()
            let primaryFullName = AuthEngine.primaryFullName(
                localProfiles: localProfiles,
                metadataFullName: metadataFullName
            )

            // 1. Upsert account row into `profiles` (`onConflict: id`)
            var accountComponents = URLComponents(
                url: baseURL.appending(path: "rest/v1/profiles"),
                resolvingAgainstBaseURL: false
            )
            accountComponents?.queryItems = [URLQueryItem(name: "on_conflict", value: "id")]
            if let accountURL = accountComponents?.url {
                let accountRow = AccountProfileDTO(
                    id: session.userId,
                    email: session.userEmail,
                    fullName: primaryFullName,
                    updatedAt: ISO8601DateFormatter().string(from: Date())
                )
                let accountData = try JSONEncoder().encode(accountRow)
                _ = try await sendPostgRESTRequest(
                    url: accountURL,
                    method: "POST",
                    anonKey: anonKey,
                    accessToken: session.accessToken,
                    prefer: "resolution=merge-duplicates,return=minimal",
                    body: accountData
                )
            }

            // 2. Fetch cloud profiles from `user_numerology_profiles` ordered by `created_at.desc`
            var selectComponents = URLComponents(
                url: baseURL.appending(path: "rest/v1/user_numerology_profiles"),
                resolvingAgainstBaseURL: false
            )
            selectComponents?.queryItems = [
                URLQueryItem(name: "select", value: "id,user_id,name,birth_date,created_at"),
                URLQueryItem(name: "user_id", value: "eq.\(session.userId)"),
                URLQueryItem(name: "order", value: "created_at.desc")
            ]
            guard let selectURL = selectComponents?.url else { return }
            let remoteData = try await sendPostgRESTRequest(
                url: selectURL,
                method: "GET",
                anonKey: anonKey,
                accessToken: session.accessToken,
                prefer: nil,
                body: nil
            )
            let remoteProfiles = (try? JSONDecoder().decode([CloudNumerologyProfileDTO].self, from: remoteData)) ?? []

            // 3. Push local-only profiles to `user_numerology_profiles`
            let localOnly = AuthEngine.localOnlyProfiles(
                localProfiles: localProfiles,
                remoteProfiles: remoteProfiles
            )
            var insertedProfiles: [CloudNumerologyProfileDTO] = []
            if !localOnly.isEmpty {
                var insertComponents = URLComponents(
                    url: baseURL.appending(path: "rest/v1/user_numerology_profiles"),
                    resolvingAgainstBaseURL: false
                )
                insertComponents?.queryItems = [
                    URLQueryItem(name: "select", value: "id,user_id,name,birth_date,created_at")
                ]
                if let insertURL = insertComponents?.url {
                    let rows = localOnly.map {
                        CloudNumerologyInsertPayload(
                            userId: session.userId,
                            name: $0.fullName,
                            birthDate: $0.birthDate
                        )
                    }
                    let insertBody = try JSONEncoder().encode(rows)
                    if let insertedData = try? await sendPostgRESTRequest(
                        url: insertURL,
                        method: "POST",
                        anonKey: anonKey,
                        accessToken: session.accessToken,
                        prefer: "return=representation",
                        body: insertBody
                    ) {
                        insertedProfiles = (try? JSONDecoder().decode([CloudNumerologyProfileDTO].self, from: insertedData)) ?? []
                    }
                }
            }

            // 4. Merge & persist unified profiles
            let unified = AuthEngine.mergeProfiles(
                remoteProfiles: remoteProfiles,
                insertedProfiles: insertedProfiles,
                localProfiles: localProfiles
            )
            if !unified.isEmpty {
                UserProfileStorage.saveAllProfiles(unified)
                if let activeID = AuthEngine.resolvedActiveProfileID(
                    currentActiveID: UserProfileStorage.activeProfileID(),
                    unifiedProfiles: unified
                ) {
                    UserProfileStorage.setActiveProfileID(activeID)
                }
            }
        } catch {
            // Matching authContext.tsx:125-127: warn and do not fail authentication when profile sync errors
        }
    }

    private static func makeSession(from token: SupabaseTokenResponse) -> AuthSession? {
        guard let accessToken = token.accessToken,
              let refreshToken = token.refreshToken,
              let userID = token.user?.id,
              !accessToken.isEmpty,
              !refreshToken.isEmpty
        else {
            return nil
        }
        return AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userId: userID,
            userEmail: token.user?.email,
            expiresAt: resolveExpiry(expiresAt: token.expiresAt, expiresIn: token.expiresIn)
        )
    }

    private static func resolveExpiry(expiresAt: Double?, expiresIn: Double?) -> Date? {
        if let expiresAt, expiresAt > 0 {
            return Date(timeIntervalSince1970: expiresAt)
        }
        if let expiresIn, expiresIn > 0 {
            return Date().addingTimeInterval(expiresIn)
        }
        return nil
    }

    private static func sendAuthRequest(
        url: URL,
        method: String,
        anonKey: String,
        bearerToken: String?,
        body: Data?,
        fallbackError: String
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(bearerToken ?? anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError(message: fallbackError)
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let envelope = try? JSONDecoder().decode(SupabaseErrorEnvelope.self, from: data)
            throw AuthError(message: envelope?.resolvedMessage ?? fallbackError)
        }
        return data
    }

    private static func sendPostgRESTRequest(
        url: URL,
        method: String,
        anonKey: String,
        accessToken: String,
        prefer: String?,
        body: Data?
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if let prefer {
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
        }
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200 ... 299).contains(http.statusCode)
        else {
            throw AuthError(message: "Không thể đồng bộ dữ liệu hồ sơ.")
        }
        return data
    }
}

// MARK: - ASWebAuthenticationSession Runner

@MainActor
private final class WebAuthSessionRunner: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var activeSession: ASWebAuthenticationSession?

    static func authenticate(url: URL, callbackScheme: String) async throws -> URL {
        let runner = WebAuthSessionRunner()
        return try await runner.start(url: url, callbackScheme: callbackScheme)
    }

    private func start(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { [weak self] callbackURL, error in
                self?.activeSession = nil
                if let error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: AuthError.cancelled)
                    } else {
                        continuation.resume(
                            throwing: AuthError.from(
                                error,
                                fallback: AuthError.googleSignInFallback.message
                            )
                        )
                    }
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: AuthError.googleSignInFallback)
                    return
                }
                continuation.resume(returning: callbackURL)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.activeSession = session
            if !session.start() {
                self.activeSession = nil
                continuation.resume(throwing: AuthError.googleSignInFallback)
            }
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if canImport(UIKit)
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let keyWindow = scenes.flatMap(\.windows).first(where: \.isKeyWindow) {
            return keyWindow
        }
        if let windowScene = scenes.first {
            return ASPresentationAnchor(windowScene: windowScene)
        }
        #endif
        return ASPresentationAnchor()
    }
}

// MARK: - TCA DependencyClient

@DependencyClient
nonisolated struct SupabaseClient: Sendable {
    var isConfigured: @Sendable () -> Bool = { false }
    /// Trả JWT hiện tại nếu người dùng đã đăng nhập. Astrology và các API client
    /// dùng closure này thay vì phụ thuộc trực tiếp vào Supabase SDK.
    var accessToken: @Sendable () async -> String? = { nil }
    var currentSession: @Sendable () async -> AuthSession? = { nil }
    var signIn: @Sendable (_ email: String, _ password: String) async throws -> AuthSession
    var signUp: @Sendable (_ email: String, _ password: String, _ fullName: String?) async throws -> AuthSignUpResult
    var signInWithGoogle: @Sendable () async throws -> AuthSession
    var signOut: @Sendable () async throws -> Void
    var syncLocalProfiles: @Sendable () async -> Void = {}
}

extension SupabaseClient: DependencyKey {
    static let liveValue = Self(
        isConfigured: {
            AppConfig.isSupabaseConfigured
        },
        accessToken: {
            await SupabaseAuthService.currentValidSession()?.accessToken
        },
        currentSession: {
            await SupabaseAuthService.currentValidSession()
        },
        signIn: { email, password in
            try await SupabaseAuthService.signIn(email: email, password: password)
        },
        signUp: { email, password, fullName in
            try await SupabaseAuthService.signUp(email: email, password: password, fullName: fullName)
        },
        signInWithGoogle: {
            try await SupabaseAuthService.signInWithGoogle()
        },
        signOut: {
            try await SupabaseAuthService.signOut()
        },
        syncLocalProfiles: {
            await SupabaseAuthService.syncLocalProfiles()
        }
    )

    static let testValue = Self()

    static let previewValue = Self(
        isConfigured: { true },
        accessToken: { "preview-jwt-token" },
        currentSession: {
            AuthSession(
                accessToken: "preview-jwt-token",
                refreshToken: "preview-refresh-token",
                userId: "preview-user-id",
                userEmail: "an.nguyen@numelyra.online",
                expiresAt: Date().addingTimeInterval(3600)
            )
        },
        signIn: { email, _ in
            AuthSession(
                accessToken: "preview-jwt-token",
                refreshToken: "preview-refresh-token",
                userId: "preview-user-id",
                userEmail: email,
                expiresAt: Date().addingTimeInterval(3600)
            )
        },
        signUp: { email, _, _ in
            AuthSignUpResult(
                needsEmailConfirmation: true,
                session: nil,
                userId: "preview-signup-user"
            )
        },
        signInWithGoogle: {
            AuthSession(
                accessToken: "preview-google-jwt",
                refreshToken: "preview-google-refresh",
                userId: "preview-google-user",
                userEmail: "google.user@numelyra.online",
                expiresAt: Date().addingTimeInterval(3600)
            )
        },
        signOut: {},
        syncLocalProfiles: {}
    )
}

extension DependencyValues {
    var supabaseClient: SupabaseClient {
        get { self[SupabaseClient.self] }
        set { self[SupabaseClient.self] = newValue }
    }
}
