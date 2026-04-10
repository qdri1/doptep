//
//  GameResultsAction.swift
//  doptep
//

import Foundation

enum GameResultsAction {
    case onBackClicked
    case onPlayerResultClicked(playerResultUiModel: PlayerResultUiModel)
    case onSavePlayerResultClicked(playerResultUiModel: PlayerResultUiModel, playerResultValue: Int)
    case onBestPlayersAllGamesClicked
    case onClearAllGamesResultsClicked
    case onClearAllGamesResultsConfirmationClicked
    case onRemovePlayerClicked(playerId: UUID)
    case onActivateClicked
}
