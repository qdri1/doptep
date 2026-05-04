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

    private let userDefaults = UserDefaults.standard
    private let onedayExpirationKey = "onedayExpirationDate"

    private init() {
        loadSavedState()
    }

    // MARK: - Public Methods

    func getCurrentBillingType() -> BillingType {
        return billingType
    }

    func setBillingType(_ type: BillingType) {
        billingType = type
        userDefaults.set(type.rawValue, forKey: "billingType")
    }

    func isSecretActivated() -> Bool {
        userDefaults.bool(forKey: "secretActivated")
    }

    func setSecretActivated(_ value: Bool) {
        userDefaults.set(value, forKey: "secretActivated")
    }

    // MARK: - One-Day Access

    var onedayExpirationDate: Date? {
        userDefaults.object(forKey: onedayExpirationKey) as? Date
    }

    func setOnedayExpirationDate() {
        let expiration = Date().addingTimeInterval(24 * 60 * 60)
        userDefaults.set(expiration, forKey: onedayExpirationKey)
    }

    func hasValidOnedayAccess() -> Bool {
        guard let expiration = userDefaults.object(forKey: onedayExpirationKey) as? Date else {
            return false
        }
        return expiration > Date()
    }

    /// Returns true if the oneday access was expired and billing was downgraded.
    @discardableResult
    func checkAndUpdateOnedayExpiration() -> Bool {
        guard billingType == .oneday, !hasValidOnedayAccess() else { return false }
        clearOnedayExpiration()
        setBillingType(.limited)
        return true
    }

    // MARK: - Private Methods

    private func clearOnedayExpiration() {
        userDefaults.removeObject(forKey: onedayExpirationKey)
    }

    private func loadSavedState() {
        let savedBillingType = userDefaults.string(forKey: "billingType") ?? BillingType.limited.rawValue
        let savedType = BillingType(rawValue: savedBillingType) ?? .limited

        if savedType == .oneday && !hasValidOnedayAccess() {
            clearOnedayExpiration()
            setBillingType(.limited)
        } else {
            billingType = savedType
        }
    }
}
