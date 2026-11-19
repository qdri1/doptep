//
//  PaywallViewModel.swift
//  doptep
//

import Foundation
import RevenueCat

enum PaywallEffect: Equatable {
    case close
    case purchased
}

@MainActor
final class PaywallViewModel: ObservableObject {

    @Published var selectedPlan: ActivationPlan = .yearly
    @Published private(set) var products: [ActivationPlan: StoreProduct] = [:]
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published var alertMessage: String?
    @Published var effect: PaywallEffect?

    let showOneDay: Bool

    init(showOneDay: Bool = true) {
        self.showOneDay = showOneDay
    }

    // MARK: - Prices

    func price(for plan: ActivationPlan) -> String? {
        products[plan]?.localizedPriceString
    }

    var selectedPrice: String? {
        price(for: selectedPlan)
    }

    var isSubscriptionSelected: Bool {
        selectedPlan == .monthly || selectedPlan == .yearly
    }

    /// Yearly price split per month, e.g. "≈ 830 ₸".
    var yearlyPerMonth: String? {
        products[.yearly]?.localizedPricePerMonth
    }

    /// How much cheaper the yearly plan is compared to 12 monthly payments, in percent.
    var yearlySavingsPercent: Int? {
        guard let monthly = products[.monthly]?.price,
              let yearly = products[.yearly]?.price,
              monthly > 0 else { return nil }
        let monthlyPerYear = monthly * 12
        guard monthlyPerYear > yearly else { return nil }
        
        let ratio = NSDecimalNumber(decimal: (monthlyPerYear - yearly) / monthlyPerYear).doubleValue
        let percent = Int(ratio * 100)
        return percent > 0 ? percent : nil
    }

    // MARK: - Actions

    func onAppear() {
        guard products.isEmpty, !isLoadingProducts else { return }
        Task { await loadProducts() }
    }

    func onPlanSelected(_ plan: ActivationPlan) {
        selectedPlan = plan
    }

    func onCloseClicked() {
        effect = .close
    }

    func onBuyClicked() {
        guard !isPurchasing else { return }
        Task { await purchaseSelectedPlan() }
    }

    func onRestoreClicked() {
        guard !isPurchasing else { return }
        Task { await restorePurchases() }
    }

    // MARK: - RevenueCat

    private func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        let plans = ActivationPlan.allCases
        let storeProducts = await Purchases.shared.products(plans.map(\.productId))
        var result: [ActivationPlan: StoreProduct] = [:]
        for product in storeProducts {
            if let plan = plans.first(where: { $0.productId == product.productIdentifier }) {
                result[plan] = product
            }
        }
        products = result
    }

    private func purchaseSelectedPlan() async {
        if products[selectedPlan] == nil {
            await loadProducts()
        }
        guard let product = products[selectedPlan] else {
            alertMessage = NSLocalizedString("purchase_failed", comment: "")
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await Purchases.shared.purchase(product: product)
            guard !result.userCancelled else { return }
            if RevenueCatManager.shared.updateBillingType(from: result.customerInfo) {
                effect = .purchased
            } else {
                alertMessage = NSLocalizedString("no_active_entitlement", comment: "")
            }
        } catch {
            let code = (error as NSError).code
            guard code != ErrorCode.purchaseCancelledError.rawValue else { return }
            if code == ErrorCode.paymentPendingError.rawValue {
                // Ask to Buy / extra bank confirmation: the payment completes later and RevenueCat
                // notifies the app (RevenueCatManager delegate), which then grants the access.
                alertMessage = NSLocalizedString("purchase_pending", comment: "")
                return
            }
            alertMessage = error.localizedDescription
        }
    }

    private func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            if RevenueCatManager.shared.updateBillingType(from: customerInfo) {
                effect = .purchased
            } else {
                alertMessage = NSLocalizedString("no_active_entitlement", comment: "")
            }
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
