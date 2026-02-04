//
//  SettingsItemType.swift
//  doptep
//

import Foundation

enum SettingsItemType: CaseIterable {
    case language
    case share
    case evaluate
    case telegram
    case activation

    var iconName: String {
        switch self {
        case .language: return "globe"
        case .share: return "square.and.arrow.up"
        case .evaluate: return "star"
        case .telegram: return "paperplane"
        case .activation: return "sparkles"
        }
    }

    var displayName: String {
        switch self {
        case .language: return NSLocalizedString("settings_item_language", comment: "")
        case .share: return NSLocalizedString("settings_item_share", comment: "")
        case .evaluate: return NSLocalizedString("settings_item_star", comment: "")
        case .telegram: return NSLocalizedString("settings_item_telegram", comment: "")
        case .activation: return NSLocalizedString("settings_item_activation", comment: "")
        }
    }
}
