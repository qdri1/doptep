//
//  SettingsEffect.swift
//  doptep
//

import Foundation

enum SettingsEffect: Hashable, Identifiable, Equatable {
    case showSelectLanguage
    case share
    case openAppStore
    case openTelegram(url: String)
    case openWhatsapp(url: String)
    case openActivationScreen
    case showPaywall
    case activationSuccess
    case activationError

    var id: String {
        switch self {
        case .showSelectLanguage: return "showSelectLanguage"
        case .share: return "share"
        case .openAppStore: return "openAppStore"
        case .openTelegram: return "openTelegram"
        case .openWhatsapp: return "openWhatsapp"
        case .openActivationScreen: return "openActivationScreen"
        case .showPaywall: return "showPaywall"
        case .activationSuccess: return "activationSuccess"
        case .activationError: return "activationError"
        }
    }
}
