import Foundation

public nonisolated enum BillingPlan: String, Codable, Equatable, Sendable {
    case free
    case pro
}

public nonisolated enum BillingProvider: String, Codable, Equatable, Sendable {
    case payos
    case paypal
}

public nonisolated struct SubscriptionDetail: Codable, Equatable, Sendable {
    public var provider: BillingProvider?
    public var status: String?
    public var currentPeriodEnd: String?
    public var cancelAtPeriodEnd: Bool?

    enum CodingKeys: String, CodingKey {
        case provider, status
        case currentPeriodEnd = "current_period_end"
        case cancelAtPeriodEnd = "cancel_at_period_end"
    }

    public init(
        provider: BillingProvider? = nil,
        status: String? = nil,
        currentPeriodEnd: String? = nil,
        cancelAtPeriodEnd: Bool? = nil
    ) {
        self.provider = provider
        self.status = status
        self.currentPeriodEnd = currentPeriodEnd
        self.cancelAtPeriodEnd = cancelAtPeriodEnd
    }
}

public nonisolated struct BillingStatus: Codable, Equatable, Sendable {
    public var authenticated: Bool
    public var plan: BillingPlan
    public var canManageBilling: Bool?
    public var checkoutPending: Bool?
    public var subscription: SubscriptionDetail?

    public init(
        authenticated: Bool = false,
        plan: BillingPlan = .free,
        canManageBilling: Bool? = nil,
        checkoutPending: Bool? = nil,
        subscription: SubscriptionDetail? = nil
    ) {
        self.authenticated = authenticated
        self.plan = plan
        self.canManageBilling = canManageBilling
        self.checkoutPending = checkoutPending
        self.subscription = subscription
    }
}

public nonisolated struct DailyReminderSettings: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var hour: Int // 0 - 23, default 20
    public var minute: Int // 0 - 59, default 0

    public init(enabled: Bool = false, hour: Int = 20, minute: Int = 0) {
        self.enabled = enabled
        self.hour = hour
        self.minute = minute
    }

    public var isValid: Bool {
        (0...23).contains(hour) && (0...59).contains(minute)
    }
}
