//
//  ActivationUiState.swift
//  doptep
//

import Foundation

struct ActivationUiState {
    var billingType: BillingType = .limited
    var pageIndex: Int = 0
    var selectedPlan: ActivationPlan?
    var monthlyPrice: String?
    var yearlyPrice: String?
    var unlimitedPrice: String?
    var isLoading: Bool = false
}
