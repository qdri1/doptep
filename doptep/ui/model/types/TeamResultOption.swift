//
//  TeamResultOption.swift
//  doptep
//

import Foundation

enum TeamResultOption: String, CaseIterable {
    case games
    case wins
    case draws
    case loses
    case goals
    case conceded
    case points

    var localizationKey: String {
        switch self {
        case .games: return "teams_block_info_games"
        case .wins: return "teams_block_info_wins"
        case .draws: return "teams_block_info_draws"
        case .loses: return "teams_block_info_loses"
        case .goals: return "team_result_option_goals"
        case .conceded: return "team_result_option_conceded"
        case .points: return "teams_block_info_points"
        }
    }
}
