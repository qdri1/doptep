//
//  GameEffect.swift
//  doptep
//

import Foundation

enum GameEffect: Hashable, Identifiable, Equatable {
    case closeScreen
    case closeScreenWithResult
    case openUpdateGame(gameId: UUID)
    case openGameResultsScreen(gameId: UUID)
    case showOptionPlayersBottomSheet(optionPlayersUiModel: OptionPlayersUiModel)
    case showPlayerResultBottomSheet(playerResultUiModel: PlayerResultUiModel)
    case showLiveGameResultBottomSheet(liveGameResultUiModel: LiveGameResultUiModel)
    case showStayTeamSelectionBottomSheet
    case showDeleteGameConfirmationBottomSheet
    case showClearResultsConfirmationBottomSheet
    case showFinishGameConfirmationBottomSheet
    case showGoBackConfirmationBottomSheet
    case showGameInfoBottomSheet
    case openActivationScreen
    case showBestPlayersBottomSheet(bestPlayers: [BestPlayerUiModel])
    case showSnackbar(message: String)

    var id: String {
        switch self {
        case .closeScreen: return "closeScreen"
        case .closeScreenWithResult: return "closeScreenWithResult"
        case .openUpdateGame(let gameId): return "openUpdateGame_\(gameId)"
        case .openGameResultsScreen(let gameId): return "openGameResultsScreen_\(gameId)"
        case .showOptionPlayersBottomSheet: return "showOptionPlayersBottomSheet"
        case .showPlayerResultBottomSheet: return "showPlayerResultBottomSheet"
        case .showLiveGameResultBottomSheet: return "showLiveGameResultBottomSheet"
        case .showStayTeamSelectionBottomSheet: return "showStayTeamSelectionBottomSheet"
        case .showDeleteGameConfirmationBottomSheet: return "showDeleteGameConfirmationBottomSheet"
        case .showClearResultsConfirmationBottomSheet: return "showClearResultsConfirmationBottomSheet"
        case .showFinishGameConfirmationBottomSheet: return "showFinishGameConfirmationBottomSheet"
        case .showGoBackConfirmationBottomSheet: return "showGoBackConfirmationBottomSheet"
        case .showGameInfoBottomSheet: return "showGameInfoBottomSheet"
        case .openActivationScreen: return "openActivationScreen"
        case .showBestPlayersBottomSheet: return "showBestPlayersBottomSheet"
        case .showSnackbar(let message): return "showSnackbar_\(message)"
        }
    }

    static func == (lhs: GameEffect, rhs: GameEffect) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
