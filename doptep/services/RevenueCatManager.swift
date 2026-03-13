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
        let language = UserDefaults.standard.string(forKey: "app_language") ?? "ru"
        Purchases.shared.overridePreferredUILocale(language)
    }

    func updateLocale(_ language: String) {
        Purchases.shared.overridePreferredUILocale(language)
    }

    @MainActor func updateBillingType(from customerInfo: CustomerInfo) -> Bool {
        guard let entitlement = customerInfo.entitlements.active[entitlementId] else {
            BillingManager.shared.setBillingType(.limited)
            return false
        }

        let productId = entitlement.productIdentifier
        if productId == ActivationPlan.unlimited.productId {
            BillingManager.shared.setBillingType(.lifetime)
        } else {
            BillingManager.shared.setBillingType(.subscribe)
        }
        return true
    }
}

extension RevenueCatManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        
    }
}
