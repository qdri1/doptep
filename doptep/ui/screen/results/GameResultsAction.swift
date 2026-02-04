//
//  GameResultsAction.swift
//  doptep
//

import Foundation

enum GameResultsAction {
    case onBackClicked
    case onClearResultsClicked
    case onClearResultsConfirmationClicked
    case onSavePlayerResultClicked(playerResultUiModel: PlayerResultUiModel, playerResultValue: Int)
}
