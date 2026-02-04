//
//  GameRule.swift
//  doptep
//
//  Created by Kudaibergen Alimtayev on 30.12.2025.
//


protocol GameRule {
    var localizationKey: String { get }
}

enum GameRuleFactory {

    static func getRule(
        teamQuantity: TeamQuantity,
        rule: String
    ) -> GameRule {
        switch teamQuantity {
        case .team2:
            return GameRuleTeam2.from(rule)
        case .team3:
            return GameRuleTeam3.from(rule)
        case .team4:
            return GameRuleTeam4.from(rule)
        }
    }
}

enum GameRuleTeam2: String, GameRule, CaseIterable {
    case afterTimeChangeSide
    case afterTimeStaySide

    var localizationKey: String {
        switch self {
        case .afterTimeChangeSide: return "game_rule_2_change_side"
        case .afterTimeStaySide: return "game_rule_2_stay_side"
        }
    }

    static func from(_ value: String, defaultValue: GameRuleTeam2 = .afterTimeChangeSide) -> GameRuleTeam2 {
        GameRuleTeam2(rawValue: value) ?? defaultValue
    }
}

enum GameRuleTeam3: String, GameRule, CaseIterable {
    case only2Games
    case winnerStay2
    case winnerStay3
    case winnerStay4
    case winnerStayUnlimited

    var localizationKey: String {
        switch self {
        case .only2Games: return "game_rule_3_only_2_games"
        case .winnerStay2: return "game_rule_3_winner_stay_2"
        case .winnerStay3: return "game_rule_3_winner_stay_3"
        case .winnerStay4: return "game_rule_3_winner_stay_4"
        case .winnerStayUnlimited: return "game_rule_3_winner_stay_unlimited"
        }
    }

    static func from(_ value: String, defaultValue: GameRuleTeam3 = .only2Games) -> GameRuleTeam3 {
        GameRuleTeam3(rawValue: value) ?? defaultValue
    }
}

enum GameRuleTeam4: String, GameRule, CaseIterable {
    case only3Games
    case winnerStay3
    case winnerStay4
    case winnerStay5
    case winnerStay6
    case winnerStayUnlimited

    var localizationKey: String {
        switch self {
        case .only3Games: return "game_rule_4_only_3_games"
        case .winnerStay3: return "game_rule_4_winner_stay_3"
        case .winnerStay4: return "game_rule_4_winner_stay_4"
        case .winnerStay5: return "game_rule_4_winner_stay_5"
        case .winnerStay6: return "game_rule_4_winner_stay_6"
        case .winnerStayUnlimited: return "game_rule_4_winner_stay_unlimited"
        }
    }

    static func from(_ value: String, defaultValue: GameRuleTeam4 = .only3Games) -> GameRuleTeam4 {
        GameRuleTeam4(rawValue: value) ?? defaultValue
    }
}
