//
//  GameResultsUiState.swift
//  doptep
//

import Foundation

struct GameResultsUiState {
    var teamUiModelList: [TeamUiModel] = []
    var playerUiModelList: [PlayerUiModel] = []
    var deletedPlayerIds: Set<UUID> = []
    var uiLimited: Bool = true
}
