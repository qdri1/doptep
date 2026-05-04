//
//  RevenueCatManager.swift
//  doptep
//

import Foundation
import RevenueCat

final class RevenueCatManager: NSObject {

    static let shared = RevenueCatManager()

    // Replace with your actual API key from the RevenueCat dashboard
    private let apiKey = "appl_XfdhOgttCOBDdtEfJunkgVHnOWD"

    // Replace with your entitlement identifier from the RevenueCat dashboard
    private let entitlementId = "dop_tep_pro"

    private override init() {}

    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
        let language = UserDefaults.standard.string(forKey: "app_language") ?? "ru"
        Purchases.shared.overridePreferredUILocale(language)
    }

    func updateLocale(_ language: String) {
        Purchases.shared.overridePreferredUILocale(language)
    }

    @MainActor func updateBillingType(from customerInfo: CustomerInfo) -> Bool {
        if let entitlement = customerInfo.entitlements.active[entitlementId] {
            let productId = entitlement.productIdentifier
            if productId == ActivationPlan.unlimited.productId {
                BillingManager.shared.setBillingType(.lifetime)
            } else {
                BillingManager.shared.setBillingType(.subscribe)
            }
            return true
        }

        // Consumables don't create persistent entitlements. Detect a fresh oneday purchase
        // by checking for a nonSubscription transaction within the last 5 minutes.
        let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
        let hasFreshOnedayPurchase = customerInfo.nonSubscriptions.contains {
            $0.productIdentifier == ActivationPlan.oneday.productId && $0.purchaseDate > fiveMinutesAgo
        }

        if hasFreshOnedayPurchase {
            if !BillingManager.shared.hasValidOnedayAccess() {
                BillingManager.shared.setOnedayExpirationDate()
            }
            BillingManager.shared.setBillingType(.oneday)
            return true
        }

        if !BillingManager.shared.isSecretActivated() && !BillingManager.shared.hasValidOnedayAccess() {
            BillingManager.shared.setBillingType(.limited)
        }
        return false
    }
}

extension RevenueCatManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.updateBillingType(from: customerInfo)
        }
    }
}
