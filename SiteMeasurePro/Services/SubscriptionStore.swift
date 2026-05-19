import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class SubscriptionStore {
    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var currentPlan: SubscriptionPlan = .free
    private(set) var isLoading = false
    var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { await observeTransactions() }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    var hasActiveSubscription: Bool {
        currentPlan != .free
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedProducts = try await Product.products(for: AppConstants.StoreKit.productIDs)
            products = fetchedProducts.sorted { lhs, rhs in
                plan(for: lhs.id).rank < plan(for: rhs.id).rank
            }
            errorMessage = nil
        } catch {
            errorMessage = "Unable to load subscription products. Check App Store Connect or StoreKit test configuration."
        }
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .pending:
                errorMessage = "Purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                errorMessage = "Unknown purchase result."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = "Unable to restore purchases: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        var activeIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard AppConstants.StoreKit.productIDs.contains(transaction.productID) else { continue }
            activeIDs.insert(transaction.productID)
        }

        purchasedProductIDs = activeIDs
        currentPlan = activeIDs
            .map(plan(for:))
            .max() ?? .free
    }

    private func observeTransactions() async {
        for await result in Transaction.updates {
            guard let transaction = try? checkVerified(result) else { continue }
            await transaction.finish()
            await refreshEntitlements()
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionStoreError.unverifiedTransaction
        case .verified(let signedType):
            return signedType
        }
    }

    private func plan(for productID: String) -> SubscriptionPlan {
        switch productID {
        case AppConstants.StoreKit.proMonthlyProductID:
            return .proMonthly
        case AppConstants.StoreKit.proYearlyProductID:
            return .proYearly
        case AppConstants.StoreKit.businessMonthlyProductID:
            return .businessMonthly
        default:
            return .free
        }
    }
}

enum SubscriptionStoreError: LocalizedError {
    case unverifiedTransaction

    var errorDescription: String? {
        "The App Store transaction could not be verified."
    }
}
