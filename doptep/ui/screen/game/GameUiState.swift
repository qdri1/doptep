//
//  GameUiState.swift
//  doptep
//

import Foundation

struct GameUiState {
    var gameUiModel: GameUiModel? = nil
    var liveGameUiModel: LiveGameUiModel? = nil
    var teamUiModelList: [TeamUiModel] = []
    var playerUiModelList: [PlayerUiModel] = []
    var showLeftTeamOptionsDropdown: Bool = false
    var showRightTeamOptionsDropdown: Bool = false
    var showLeftTeamChangeDropdown: Bool = false
    var showRightTeamChangeDropdown: Bool = false
    var isTimerPlay: Bool = false
    var billingType: BillingType = .lifetime
    var uiLimited: Bool = false
}
