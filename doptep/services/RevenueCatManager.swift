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
        // Verbose SDK logs only in debug builds.
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .warn
        #endif
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

        // Secret activation code = lifetime access. Checked before "1 day" so a one-day purchase can't
        // replace it (and then expire to the free version), and so an ended subscription of such a user
        // falls back to lifetime instead of staying "subscribe".
        if BillingManager.shared.isSecretActivated() {
            BillingManager.shared.setBillingType(.lifetime)
            return true
        }

        // "1 day" is a consumable, so it has no entitlement: access is granted while the latest
        // one-day transaction is younger than 24 hours, counted from the purchase itself.
        // (Previously only purchases from the last 5 minutes were accepted, so a payment that reached
        // the app later — deferred / bank-confirmed payment, app closed right after paying — was
        // charged without granting access.)
        let latestOnedayPurchase = customerInfo.nonSubscriptions
            .filter { $0.productIdentifier == ActivationPlan.oneday.productId }
            .map(\.purchaseDate)
            .max()

        if let purchaseDate = latestOnedayPurchase,
           purchaseDate.addingTimeInterval(BillingManager.onedayDuration) > Date() {
            BillingManager.shared.setOnedayExpirationDate(purchaseDate: purchaseDate)
            BillingManager.shared.setBillingType(.oneday)
            return true
        }

        if !BillingManager.shared.hasValidOnedayAccess() {
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
