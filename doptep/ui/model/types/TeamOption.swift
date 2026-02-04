//
//  TeamOption.swift
//  doptep
//

import Foundation

enum TeamOption: String, CaseIterable {
    case goal
    case assist
    case save
    case dribble
    case shot
    case pass

    var localizationKey: String {
        switch self {
        case .goal: return "team_option_goal"
        case .assist: return "team_option_assist"
        case .save: return "team_option_save"
        case .dribble: return "team_option_dribble"
        case .shot: return "team_option_shot"
        case .pass: return "team_option_pass"
        }
    }
}
