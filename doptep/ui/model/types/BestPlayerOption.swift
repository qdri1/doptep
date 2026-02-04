//
//  BestPlayerOption.swift
//  doptep
//

import Foundation

enum BestPlayerOption: String, CaseIterable {
    case bestPlayer
    case goals
    case assists
    case saves
    case dribbles
    case passes
    case shots

    var localizationKey: String {
        switch self {
        case .bestPlayer: return "best_player_option_best_player"
        case .goals: return "best_player_option_goals"
        case .assists: return "best_player_option_assists"
        case .saves: return "best_player_option_saves"
        case .dribbles: return "best_player_option_dribbles"
        case .passes: return "best_player_option_passes"
        case .shots: return "best_player_option_shots"
        }
    }
}
