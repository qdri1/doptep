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

    // MARK: - Private Methods

    private func loadSavedState() {
        let savedBillingType = userDefaults.string(forKey: "billingType") ?? BillingType.limited.rawValue
        billingType = BillingType(rawValue: savedBillingType) ?? .limited
    }
}
