//
//  ActivationEffect.swift
//  doptep
//

import Foundation

enum ActivationEffect: Hashable, Identifiable, Equatable {
    case closeScreen
    case openAppStoreSubscriptions
    case showSnackbar(message: String)
    case buySelectedPlan(plan: ActivationPlan)

    var id: String {
        switch self {
        case .closeScreen: return "closeScreen"
        case .openAppStoreSubscriptions: return "openAppStoreSubscriptions"
        case .showSnackbar(let message): return "showSnackbar_\(message)"
        case .buySelectedPlan(let plan): return "buySelectedPlan_\(plan.rawValue)"
        }
    }

    static func == (lhs: ActivationEffect, rhs: ActivationEffect) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
