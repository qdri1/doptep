//
//  SettingsEffect.swift
//  doptep
//

import Foundation

enum SettingsEffect: Hashable, Identifiable, Equatable {
    case showSelectLanguage
    case share
    case openAppStore
    case openTelegram
    case openActivationScreen

    var id: String {
        switch self {
        case .showSelectLanguage: return "showSelectLanguage"
        case .share: return "share"
        case .openAppStore: return "openAppStore"
        case .openTelegram: return "openTelegram"
        case .openActivationScreen: return "openActivationScreen"
        }
    }
}
