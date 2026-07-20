import Foundation
import StoreKit
internal import Combine

/// Manages the TutorMate Premium auto-renewable subscriptions using StoreKit 2.
/// Entitlements are cryptographically verified by StoreKit on-device; only
/// verified transactions unlock premium access.
final class StoreManager: ObservableObject {

    static let shared = StoreManager()

    static let monthlyProductID = "com.tutormate.premium.monthly"
    static let annualProductID = "com.tutormate.premium.annual"
    static let productIDs: Set<String> = [monthlyProductID, annualProductID]

    @Published private(set) var products: [Product] = []
    @Published private(set) var isSubscribed = false

    private var transactionListener: Task<Void, Never>?

    private init() {
        // Listen for transaction updates (renewals, refunds, Ask to Buy
        // approvals, purchases on other devices) for the app's lifetime.
        transactionListener = Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard let self else { break }
                if let transaction = try? self.verified(update) {
                    await transaction.finish()
                    await self.refreshSubscriptionStatus()
                }
            }
        }

        Task {
            await loadProducts()
            await refreshSubscriptionStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyProductID }
    }

    var annualProduct: Product? {
        products.first { $0.id == Self.annualProductID }
    }

    /// Percentage saved by choosing the annual plan over 12 months of monthly,
    /// computed from the localized store prices.
    var annualSavingsPercent: Int? {
        guard let monthly = monthlyProduct?.price,
              let annual = annualProduct?.price,
              monthly > 0 else { return nil }
        let yearAtMonthlyRate = monthly * 12
        guard yearAtMonthlyRate > annual else { return nil }
        // Convert via Double: NSDecimalNumber.intValue returns 0 for the
        // high-precision decimals that division produces. Truncate rather
        // than round so the badge never overstates the savings.
        let fraction = NSDecimalNumber(decimal: (yearAtMonthlyRate - annual) / yearAtMonthlyRate).doubleValue
        return Int(fraction * 100)
    }

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
            await MainActor.run { products = loaded }
        } catch {
            print("Failed to load subscription products: \(error)")
        }
    }

    /// Purchases the given product. Returns true when the purchase completed
    /// and the user is now subscribed (false for cancellation or a pending
    /// Ask to Buy approval).
    @MainActor
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try verified(verification)
            await transaction.finish()
            await refreshSubscriptionStatus()
            return isSubscribed
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    /// Syncs with the App Store to restore purchases made on other devices
    /// or under the same Apple Account.
    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshSubscriptionStatus()
    }

    /// Recomputes `isSubscribed` from the current App Store entitlements.
    func refreshSubscriptionStatus() async {
        var active = false
        for await entitlement in Transaction.currentEntitlements {
            guard let transaction = try? verified(entitlement) else { continue }
            if Self.productIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                active = true
            }
        }
        let value = active
        await MainActor.run { isSubscribed = value }

        // Mirror the entitlement to Firestore so the website honors an
        // Apple subscription under the same login. A downgrade ("expired")
        // is only allowed when this Apple Account has a transaction history
        // for the subscription — see updateAppleSubscriptionStatus.
        var canDowngrade = false
        if !active {
            for id in Self.productIDs {
                if await Transaction.latest(for: id) != nil {
                    canDowngrade = true
                    break
                }
            }
        }
        await FirebaseManager.shared.updateAppleSubscriptionStatus(
            isActive: value,
            canDowngrade: canDowngrade
        )
    }

    /// Only accept transactions whose StoreKit signature checks out.
    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.failedVerification
        }
    }

    enum StoreError: LocalizedError {
        case failedVerification

        var errorDescription: String? {
            "Your purchase could not be verified by the App Store."
        }
    }
}
