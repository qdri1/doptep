//
//  TeamOption.swift
//  doptep
//

import Foundation

enum TeamOption: String, CaseIterable {
    case goal
    case assist
    case save
    case tackle
    case dribble
    case shot
    case pass
    case yellowCard
    case redCard

    var localizationKey: String {
        switch self {
        case .goal: return "team_option_goal"
        case .assist: return "team_option_assist"
        case .save: return "team_option_save"
        case .tackle: return "team_option_tackle"
        case .dribble: return "team_option_dribble"
        case .shot: return "team_option_shot"
        case .pass: return "team_option_pass"
        case .yellowCard: return "team_option_yellow_card"
        case .redCard: return "team_option_red_card"
        }
    }
}
