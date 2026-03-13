//
//  ActivationEffect.swift
//  doptep
//

import Foundation

enum ActivationEffect: Hashable, Identifiable, Equatable {
    case closeScreen
    case openAppStoreSubscriptions

    var id: String {
        switch self {
        case .closeScreen: return "closeScreen"
        case .openAppStoreSubscriptions: return "openAppStoreSubscriptions"
        }
    }

    static func == (lhs: ActivationEffect, rhs: ActivationEffect) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
