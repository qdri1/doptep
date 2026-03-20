//
//  GameResultsEffect.swift
//  doptep
//

import Foundation

enum GameResultsEffect: Hashable, Identifiable, Equatable {
    case closeScreen
    case showClearResultsConfirmationBottomSheet
    case showPlayerResultBottomSheet(playerResultUiModel: PlayerResultUiModel)
    case showSnackbar(message: String)
    case showBestPlayersBottomSheet(bestPlayers: [BestPlayerUiModel])
    case showClearAllGamesResultsConfirmationBottomSheet

    var id: String {
        switch self {
        case .closeScreen: return "closeScreen"
        case .showClearResultsConfirmationBottomSheet: return "showClearResultsConfirmationBottomSheet"
        case .showPlayerResultBottomSheet: return "showPlayerResultBottomSheet"
        case .showSnackbar(let message): return "showSnackbar_\(message)"
        case .showBestPlayersBottomSheet: return "showBestPlayersBottomSheet"
        case .showClearAllGamesResultsConfirmationBottomSheet: return "showClearAllGamesResultsConfirmationBottomSheet"
        }
    }

    static func == (lhs: GameResultsEffect, rhs: GameResultsEffect) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
