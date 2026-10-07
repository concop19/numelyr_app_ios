import ComposableArchitecture
import Foundation
#if canImport(SafariServices) && canImport(UIKit)
import SafariServices
import UIKit
#endif

public nonisolated struct BillingError: LocalizedError, Equatable, Sendable {
    public var message: String

    public init(message: String) {
        self.message = message
    }

    public var errorDescription: String? {
        message
    }

    public static let statusFallback = BillingError(
        message: "Không thể tải trạng thái gói Pro."
    )
    public static let checkoutFallback = BillingError(
        message: "Không thể mở trang thanh toán."
    )

    public static func from(_ error: any Error, fallback: String) -> BillingError {
        if let billingError = error as? BillingError {
            return billingError
        }
        let localized = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return BillingError(message: localized.isEmpty ? fallback : localized)
    }
}

// MARK: - Billing HTTP & Checkout Service (`billingService.ts`)

public nonisolated enum BillingService {
    public static func getBillingStatus(accessToken: String?) async throws -> BillingStatus {
        var request = URLRequest(
            url: AppConfig.billingSubscriptionURL,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 30
        )
        request.httpMethod = "GET"
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        if let accessToken, !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BillingError.statusFallback
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let envelope = try? JSONDecoder().decode(BillingErrorEnvelope.self, from: data)
            let message = envelope?.error?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw BillingError(
                message: (message?.isEmpty == false)
                    ? message!
                    : BillingError.statusFallback.message
            )
        }
        guard let decoded = try? JSONDecoder().decode(BillingStatus.self, from: data) else {
            throw BillingError.statusFallback
        }
        return decoded
    }

    public static func requestCheckoutURL(
        provider: BillingProvider,
        accessToken: String?
    ) async throws -> URL {
        let endpoint = (provider == .payos)
            ? AppConfig.payosCheckoutURL
            : AppConfig.paypalCheckoutURL
        var request = URLRequest(url: endpoint, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accessToken, !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(CheckoutRequest(locale: "vi"))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BillingError.checkoutFallback
        }
        let decoded = (try? JSONDecoder().decode(CheckoutResponse.self, from: data)) ?? CheckoutResponse()
        guard (200 ... 299).contains(http.statusCode),
              let checkoutURL = SettingsEngine.resolveCheckoutURL(from: decoded, provider: provider)
        else {
            let message = decoded.error?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw BillingError(
                message: (message?.isEmpty == false)
                    ? message!
                    : BillingError.checkoutFallback.message
            )
        }
        return checkoutURL
    }
}

#if canImport(SafariServices) && canImport(UIKit)
@MainActor
private final class SafariCheckoutRunner: NSObject, SFSafariViewControllerDelegate {
    private static var activeRunners: [ObjectIdentifier: SafariCheckoutRunner] = [:]
    private var continuation: CheckedContinuation<Void, Never>?

    static func open(url: URL) async {
        guard let presenter = topViewController() else {
            _ = await UIApplication.shared.open(url)
            return
        }
        let runner = SafariCheckoutRunner()
        let key = ObjectIdentifier(runner)
        activeRunners[key] = runner
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            runner.continuation = continuation
            let safari = SFSafariViewController(url: url)
            safari.delegate = runner
            safari.dismissButtonStyle = .done
            presenter.present(safari, animated: true)
        }
        activeRunners.removeValue(forKey: key)
    }

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        continuation?.resume()
        continuation = nil
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let keyWindow = scenes.flatMap(\.windows).first(where: \.isKeyWindow)
            ?? scenes.flatMap(\.windows).first
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
#endif

// MARK: - TCA DependencyClient

@DependencyClient
nonisolated struct BillingClient: Sendable {
    var getBillingStatus: @Sendable () async throws -> BillingStatus
    var beginCheckout: @Sendable (_ provider: BillingProvider) async throws -> Void
}

extension BillingClient: DependencyKey {
    static var liveValue: Self {
        @Dependency(\.supabaseClient) var supabaseClient

        return Self(
            getBillingStatus: {
                let token = await supabaseClient.accessToken()
                return try await BillingService.getBillingStatus(accessToken: token)
            },
            beginCheckout: { provider in
                let token = await supabaseClient.accessToken()
                let checkoutURL = try await BillingService.requestCheckoutURL(
                    provider: provider,
                    accessToken: token
                )
                #if canImport(SafariServices) && canImport(UIKit)
                await SafariCheckoutRunner.open(url: checkoutURL)
                #endif
            }
        )
    }

    static let testValue = Self()

    static let previewValue = Self(
        getBillingStatus: {
            BillingStatus(
                authenticated: true,
                plan: .free,
                canManageBilling: true,
                checkoutPending: false,
                subscription: nil
            )
        },
        beginCheckout: { _ in }
    )
}

extension DependencyValues {
    var billingClient: BillingClient {
        get { self[BillingClient.self] }
        set { self[BillingClient.self] = newValue }
    }
}
