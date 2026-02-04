//
//  ActivationPlan.swift
//  doptep
//

import Foundation

enum ActivationPlan: String, CaseIterable {
    case monthly = "monthly_premium_upgrade"
    case yearly = "yearly_premium_upgrade"
    case unlimited = "premium_upgrade"

    var productId: String {
        return rawValue
    }

    var displayName: String {
        switch self {
        case .monthly: return NSLocalizedString("activation_plan_1", comment: "")
        case .yearly: return NSLocalizedString("activation_plan_2", comment: "")
        case .unlimited: return NSLocalizedString("activation_plan_3", comment: "")
        }
    }

    var description: String {
        switch self {
        case .monthly, .yearly: return NSLocalizedString("activation_plan_desc_subscribe", comment: "")
        case .unlimited: return NSLocalizedString("activation_plan_desc_lifetime", comment: "")
        }
    }
}
