//
//  ActivationAction.swift
//  doptep
//

import Foundation

enum ActivationAction {
    case onBackClicked
    case showPriceButtonClicked
    case buyButtonClicked
    case manageSubscriptionsButtonClicked
    case onActivationPlanItemClicked(plan: ActivationPlan)
    case restorePurchases
}
