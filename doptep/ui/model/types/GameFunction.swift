//
//  GameFunction.swift
//  doptep
//

import Foundation

enum GameFunction: String, CaseIterable {
    case bestPlayers
    case edit
    case clearResults
    case info
    case allResults
    case delete

    var localizationKey: String {
        switch self {
        case .bestPlayers: return "function_best_players"
        case .edit: return "function_edit"
        case .clearResults: return "function_clear_result"
        case .info: return "function_info"
        case .allResults: return "function_all_results"
        case .delete: return "function_remove"
        }
    }

    var systemImage: String {
        switch self {
        case .bestPlayers: return "hand.thumbsup.fill"
        case .edit: return "pencil"
        case .clearResults: return "arrow.clockwise"
        case .info: return "info.circle"
        case .allResults: return "calendar"
        case .delete: return "trash"
        }
    }
}
