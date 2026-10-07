import CryptoKit
import Foundation

public nonisolated enum OAuthCallbackPayload: Equatable, Sendable {
    case pkceCode(String)
    case implicitTokens(accessToken: String, refreshToken: String)
    case error(String)
}

public nonisolated struct PKCEChallenge: Equatable, Sendable {
    public let verifier: String
    public let challenge: String
    public let method: String

    public init(verifier: String) {
        self.verifier = verifier
        let digest = SHA256.hash(data: Data(verifier.utf8))
        self.challenge = Self.base64URLEncode(Data(digest))
        self.method = "s256"
    }

    public static func random() -> PKCEChallenge {
        var bytes = [UInt8](repeating: 0, count: 32)
        for index in bytes.indices {
            bytes[index] = UInt8.random(in: 0 ... 255)
        }
        let verifier = base64URLEncode(Data(bytes))
        return PKCEChallenge(verifier: verifier)
    }

    public static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

public nonisolated enum AuthEngine {
    /// Kiểm tra định dạng email theo đúng biểu thức `/^\S+@\S+\.\S+$/` của `LoginScreen.tsx`.
    public static func isValidEmail(_ rawEmail: String) -> Bool {
        let normalized = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty,
              normalized.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
        else {
            return false
        }
        let range = NSRange(normalized.startIndex ..< normalized.endIndex, in: normalized)
        guard let regex = try? NSRegularExpression(pattern: #"^\S+@\S+\.\S+$"#) else {
            return false
        }
        return regex.firstMatch(in: normalized, options: [], range: range) != nil
    }

    /// Kiểm tra hợp lệ dữ liệu form đăng nhập / đăng ký theo đúng thứ tự trong `LoginScreen.tsx`.
    public static func validateSubmission(
        email: String,
        password: String,
        fullName: String,
        isSignUp: Bool
    ) -> Result<ValidatedAuthCredentials, AuthValidationError> {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(normalizedEmail) else {
            return .failure(.invalidEmail)
        }
        guard password.count >= 6 else {
            return .failure(.shortPassword)
        }
        let trimmedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        if isSignUp && trimmedFullName.isEmpty {
            return .failure(.missingFullName)
        }
        return .success(
            ValidatedAuthCredentials(
                email: normalizedEmail,
                password: password,
                fullName: isSignUp ? trimmedFullName : nil
            )
        )
    }

    /// Phân tích URL callback OAuth (hỗ trợ cả PKCE `?code=...` và Implicit `#access_token=...&refresh_token=...`)
    /// tương ứng với `authContext.tsx:221-251`.
    public static func parseOAuthCallback(_ url: URL) -> OAuthCallbackPayload? {
        let urlString = url.absoluteString
        let hashPart: String = {
            guard let hashIndex = urlString.firstIndex(of: "#") else { return "" }
            return String(urlString[urlString.index(after: hashIndex)...])
        }()
        let queryPart: String = {
            guard let questionIndex = urlString.firstIndex(of: "?") else { return "" }
            let afterQuestion = urlString[urlString.index(after: questionIndex)...]
            if let hashIndex = afterQuestion.firstIndex(of: "#") {
                return String(afterQuestion[..<hashIndex])
            }
            return String(afterQuestion)
        }()

        let activeRawParams = !hashPart.isEmpty ? hashPart : queryPart
        guard !activeRawParams.isEmpty else { return nil }

        var components = URLComponents()
        components.percentEncodedQuery = activeRawParams
        let items = components.queryItems ?? []

        func value(for name: String) -> String? {
            items.first(where: { $0.name == name })?.value?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let errorDesc = value(for: "error_description"), !errorDesc.isEmpty {
            return .error(errorDesc.replacingOccurrences(of: "+", with: " "))
        }
        if let errorCode = value(for: "error"), !errorCode.isEmpty {
            return .error(errorCode)
        }

        if let code = value(for: "code"), !code.isEmpty {
            return .pkceCode(code)
        }

        if let accessToken = value(for: "access_token"),
           let refreshToken = value(for: "refresh_token"),
           !accessToken.isEmpty,
           !refreshToken.isEmpty
        {
            return .implicitTokens(accessToken: accessToken, refreshToken: refreshToken)
        }

        return nil
    }

    // MARK: - Profile Sync Logic (`authContext.tsx:38-128`)

    /// Khóa định danh chuẩn hóa `<fullName.trim().lowercased()>|<birthDate>` dùng để đối chiếu Cloud và Local.
    public static func profileIdentityKey(fullName: String, birthDate: String) -> String {
        let normalizedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedDate = birthDate.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(normalizedName)|\(normalizedDate)"
    }

    /// Chọn `full_name` ưu tiên cho bảng `profiles` trên Supabase:
    /// hồ sơ mặc định local -> hồ sơ đầu tiên local -> `user_metadata.full_name` -> `nil`.
    public static func primaryFullName(
        localProfiles: [UserProfile],
        metadataFullName: String?
    ) -> String? {
        let primary = localProfiles.first(where: \.isDefault) ?? localProfiles.first
        if let localName = primary?.fullName.trimmingCharacters(in: .whitespacesAndNewlines),
           !localName.isEmpty
        {
            return localName
        }
        if let metaName = metadataFullName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !metaName.isEmpty
        {
            return metaName
        }
        return nil
    }

    /// Lọc danh sách các hồ sơ chỉ mới có ở máy cục bộ (chưa tồn tại trên Cloud) để đẩy lên Supabase.
    public static func localOnlyProfiles(
        localProfiles: [UserProfile],
        remoteProfiles: [CloudNumerologyProfileDTO]
    ) -> [UserProfile] {
        let remoteKeys = Set(
            remoteProfiles.map { profileIdentityKey(fullName: $0.name, birthDate: $0.birthDate) }
        )
        return localProfiles.filter {
            !remoteKeys.contains(profileIdentityKey(fullName: $0.fullName, birthDate: $0.birthDate))
        }
    }

    /// Hợp nhất danh sách hồ sơ từ Cloud (`remoteProfiles` + `insertedProfiles`) và Local (`localProfiles`)
    /// thành một danh sách duy nhất không trùng lặp, bảo toàn `gender` và các thuộc tính mở rộng từ Local.
    public static func mergeProfiles(
        remoteProfiles: [CloudNumerologyProfileDTO],
        insertedProfiles: [CloudNumerologyProfileDTO] = [],
        localProfiles: [UserProfile]
    ) -> [UserProfile] {
        var remoteItems: [UserProfile] = remoteProfiles.map { row in
            UserProfile(
                id: row.id,
                fullName: row.name,
                birthDate: row.birthDate,
                gender: nil,
                isDefault: false
            )
        }

        // Trong `authContext.tsx`: `insertedData.forEach(ins => remoteItems.unshift(...))`
        for inserted in insertedProfiles {
            remoteItems.insert(
                UserProfile(
                    id: inserted.id,
                    fullName: inserted.name,
                    birthDate: inserted.birthDate,
                    gender: nil,
                    isDefault: false
                ),
                at: 0
            )
        }

        var orderedKeys: [String] = []
        var mergedMap: [String: UserProfile] = [:]

        for item in remoteItems {
            let key = profileIdentityKey(fullName: item.fullName, birthDate: item.birthDate)
            if mergedMap[key] == nil {
                orderedKeys.append(key)
            }
            mergedMap[key] = item
        }

        for local in localProfiles {
            let key = profileIdentityKey(fullName: local.fullName, birthDate: local.birthDate)
            if let existing = mergedMap[key] {
                mergedMap[key] = UserProfile(
                    id: existing.id,
                    fullName: existing.fullName,
                    birthDate: existing.birthDate,
                    gender: local.gender ?? existing.gender,
                    isDefault: local.isDefault || existing.isDefault,
                    birthTime: local.birthTime ?? existing.birthTime,
                    birthPlace: local.birthPlace ?? existing.birthPlace,
                    birthLocation: local.birthLocation ?? existing.birthLocation,
                    birthTimeAccuracy: local.birthTimeAccuracy ?? existing.birthTimeAccuracy
                )
            } else {
                orderedKeys.append(key)
                mergedMap[key] = local
            }
        }

        return orderedKeys.compactMap { mergedMap[$0] }
    }

    /// Xác định `activeProfileID` hợp lệ sau khi đồng bộ.
    public static func resolvedActiveProfileID(
        currentActiveID: String?,
        unifiedProfiles: [UserProfile]
    ) -> String? {
        guard !unifiedProfiles.isEmpty else { return nil }
        if let currentActiveID, unifiedProfiles.contains(where: { $0.id == currentActiveID }) {
            return currentActiveID
        }
        return unifiedProfiles[0].id
    }
}
