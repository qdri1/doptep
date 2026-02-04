//
//  GameAction.swift
//  doptep
//

import Foundation

enum GameAction {
    case onBackClicked
    case onGoBackConfirmationClicked
    case onDeleteGameConfirmationClicked
    case onClearResultsConfirmationClicked
    case onStartFinishButtonClicked
    case onFinishGameConfirmationClicked
    case onTimerClicked
    case onLeftTeamClicked
    case onRightTeamClicked
    case onLeftTeamOptionSelected(option: TeamOption?)
    case onRightTeamOptionSelected(option: TeamOption?)
    case onTeamChangeIconClicked
    case onLeftTeamChangeClicked(teamId: UUID?)
    case onRightTeamChangeClicked(teamId: UUID?)
    case onOptionPlayersSelected(teamId: UUID, playerUiModel: PlayerUiModel, option: TeamOption)
    case onOptionPlayersAutoGoalSelected(teamId: UUID)
    case onStayTeamSelectionBottomSheetDismissed
    case onLeftTeamStayClicked
    case onRightTeamStayClicked
    case onSoundClicked(sound: GameSounds)
    case onFunctionClicked(function: GameFunction)
    case onPlayerResultClicked(playerResultUiModel: PlayerResultUiModel)
    case onSavePlayerResultClicked(playerResultUiModel: PlayerResultUiModel, playerResultValue: Int)
    case onLiveGameResultClicked(liveGameResultUiModel: LiveGameResultUiModel)
    case onSaveLiveGameResultClicked(liveGameResultUiModel: LiveGameResultUiModel, teamGoalsValue: Int)
    case onActivateClicked
}
