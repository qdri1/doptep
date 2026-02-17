//
//  BillingManager.swift
//  doptep
//

import Foundation
import StoreKit

@MainActor
final class BillingManager: ObservableObject {

    static let shared = BillingManager()

    @Published private(set) var billingType: BillingType = .limited
    @Published private(set) var monthlyPrice: String?
    @Published private(set) var yearlyPrice: String?
    @Published private(set) var unlimitedPrice: String?
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIds: Set<String> = []

    private var updateListenerTask: Task<Void, Error>?

    private let userDefaults = UserDefaults.standard

    private init() {
        loadSavedState()
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods

    func getCurrentBillingType() -> BillingType {
        return billingType
    }

    func purchase(_ plan: ActivationPlan) async throws -> Bool {
        guard let product = products.first(where: { $0.id == plan.productId }) else {
            return false
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return true
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }

    // MARK: - Private Methods

    private func loadSavedState() {
        let savedBillingType = userDefaults.string(forKey: "billingType") ?? BillingType.limited.rawValue
        billingType = BillingType(rawValue: savedBillingType) ?? .limited
    }

    private func loadProducts() async {
        do {
            let productIds = ActivationPlan.allCases.map { $0.productId }
            products = try await Product.products(for: productIds)

            for product in products {
                switch product.id {
                case ActivationPlan.monthly.productId:
                    monthlyPrice = product.displayPrice
                case ActivationPlan.yearly.productId:
                    yearlyPrice = product.displayPrice
                case ActivationPlan.unlimited.productId:
                    unlimitedPrice = product.displayPrice
                default:
                    break
                }
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }

    private func updatePurchasedProducts() async {
        var purchasedIds: Set<String> = []
        var hasActiveSubscription = false
        var hasLifetime = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchasedIds.insert(transaction.productID)

                if transaction.productID == ActivationPlan.unlimited.productId {
                    hasLifetime = true
                } else if transaction.productID == ActivationPlan.monthly.productId ||
                          transaction.productID == ActivationPlan.yearly.productId {
                    hasActiveSubscription = true
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }

        purchasedProductIds = purchasedIds

        if hasLifetime {
            billingType = .lifetime
        } else if hasActiveSubscription {
            billingType = .subscribe
        } else {
            billingType = .limited
        }

        userDefaults.set(billingType.rawValue, forKey: "billingType")
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
