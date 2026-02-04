//
//  BillingType.swift
//  doptep
//

import Foundation

enum BillingType: String, CaseIterable {
    case limited
    case subscribe
    case lifetime

    var isPremium: Bool {
        self != .limited
    }
}
