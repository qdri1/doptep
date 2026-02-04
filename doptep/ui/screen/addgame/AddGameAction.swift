//
//  AddGameAction.swift
//  doptep
//

import Foundation

enum AddGameAction {
    case closeScreen
    case onGameTextValueChanged(value: String)
    case onTimeTextValueChanged(value: String)
    case onGameFormatSelected(format: GameFormat)
    case onTeamQuantitySelected(teamQuantity: TeamQuantity)
    case onGameRuleSelected(rule: GameRule)
    case onTeamTabClicked(tabIndex: Int)
    case onTeamColorClicked
    case onTeamColorSelected(color: TeamColor)
    case onTeamNameValueChanged(tabIndex: Int, value: String)
    case onPlayerNameValueChanged(tabIndex: Int, fieldIndex: Int, value: String)
    case onAddPlayerClicked(tabIndex: Int)
    case onFinishClicked
}
