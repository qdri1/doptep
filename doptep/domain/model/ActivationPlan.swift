//
//  ActivationPlan.swift
//  doptep
//

import Foundation

enum ActivationPlan: String, CaseIterable {
    case monthly = "subscription_monthly"
    case yearly = "annual_subscription"
    case unlimited = "lifetime_dop_tep"
    case oneday = "one_day_access"

    var productId: String {
        return rawValue
    }
}
