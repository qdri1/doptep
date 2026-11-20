//
//  ActivationUiState.swift
//  doptep
//

import Foundation

struct ActivationUiState {
    var billingType: BillingType = .limited
    var onedayExpirationDate: Date? = nil
    var subscriptionPlan: ActivationPlan? = nil
}
