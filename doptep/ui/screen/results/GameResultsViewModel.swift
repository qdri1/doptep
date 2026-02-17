//
//  GameResultsViewModel.swift
//  doptep
//

import Foundation
import SwiftData

@MainActor
final class GameResultsViewModel: ObservableObject {

    private let gameId: UUID
    private let modelContext: ModelContext
    private let teamHistoryRepository: TeamHistoryRepository
    private let playerHistoryRepository: PlayerHistoryRepository
    private let playerRepository: PlayerRepository

    @Published var uiState = GameResultsUiState()
    @Published var effect: GameResultsEffect?

    init(
        gameId: UUID,
        modelContext: ModelContext
    ) {
        self.gameId = gameId
        self.modelContext = modelContext
        self.teamHistoryRepository = TeamHistoryRepository(context: modelContext)
        self.playerHistoryRepository = PlayerHistoryRepository(context: modelContext)
        self.playerRepository = PlayerRepository(context: modelContext)

        fetchGameHistory()
    }

    func action(_ action: GameResultsAction) {
        switch action {
        case .onBackClicked:
            setEffect(.closeScreen)

        case .onClearResultsClicked:
            setEffect(.showClearResultsConfirmationBottomSheet)

        case .onClearResultsConfirmationClicked:
            onClearResultsConfirmationClicked()

        case .onSavePlayerResultClicked(let playerResultUiModel, let playerResultValue):
            onSavePlayerResultClicked(playerResultUiModel: playerResultUiModel, playerResultValue: playerResultValue)
        }
    }

    func clearEffect() {
        effect = nil
    }

    private func fetchGameHistory() {
        do {
            let teamUiModelList = try teamHistoryRepository.getTeamsHistories(gameId: gameId)
                .sorted { (team1, team2) -> Bool in
                    if team1.points != team2.points {
                        return team1.points > team2.points
                    }
                    if team1.goalsDifference != team2.goalsDifference {
                        return team1.goalsDifference > team2.goalsDifference
                    }
                    return team1.name < team2.name
                }

            var allPlayers: [PlayerUiModel] = []
            for teamUiModel in teamUiModelList {
                let players = try playerHistoryRepository.getPlayersHistories(teamId: teamUiModel.id)
                allPlayers.append(contentsOf: players)
            }

            let playerUiModelList = allPlayers.sorted { (player1, player2) -> Bool in
                if player1.goals != player2.goals {
                    return player1.goals > player2.goals
                }
                if player1.assists != player2.assists {
                    return player1.assists > player2.assists
                }
                let player1Extra = player1.saves + player1.dribbles + player1.shots + player1.passes
                let player2Extra = player2.saves + player2.dribbles + player2.shots + player2.passes
                if player1Extra != player2Extra {
                    return player1Extra > player2Extra
                }
                if player1.teamPoints != player2.teamPoints {
                    return player1.teamPoints > player2.teamPoints
                }
                if player1.teamGoalsDifference != player2.teamGoalsDifference {
                    return player1.teamGoalsDifference > player2.teamGoalsDifference
                }
                if player1.teamName != player2.teamName {
                    return player1.teamName < player2.teamName
                }
                return player1.name < player2.name
            }

            let billingType = BillingManager.shared.getCurrentBillingType()
            let uiLimited = billingType == .limited

            uiState = GameResultsUiState(
                teamUiModelList: teamUiModelList,
                playerUiModelList: playerUiModelList,
                uiLimited: uiLimited
            )
        } catch {
            print("Error fetching game history: \(error)")
        }
    }

    private func onClearResultsConfirmationClicked() {
        do {
            let teamUiModelList = try teamHistoryRepository.getTeamsHistories(gameId: gameId)

            for teamUiModel in teamUiModelList {
                let clearedTeam = TeamUiModel(
                    id: teamUiModel.id,
                    gameId: teamUiModel.gameId,
                    name: teamUiModel.name,
                    color: teamUiModel.color,
                    games: 0,
                    wins: 0,
                    draws: 0,
                    loses: 0,
                    goals: 0,
                    conceded: 0,
                    points: 0
                )
                try teamHistoryRepository.updateTeamHistory(clearedTeam)

                let playerHistories = try playerHistoryRepository.getPlayersHistories(teamId: teamUiModel.id)
                for playerHistoryUiModel in playerHistories {
                    let playerUiModel = try playerRepository.getPlayer(id: playerHistoryUiModel.id)
                    if playerUiModel == nil {
                        try playerHistoryRepository.deletePlayerHistory(playerId: playerHistoryUiModel.id)
                    } else {
                        let clearedPlayer = PlayerUiModel(
                            id: playerHistoryUiModel.id,
                            teamId: playerHistoryUiModel.teamId,
                            teamColor: playerHistoryUiModel.teamColor,
                            teamName: playerHistoryUiModel.teamName,
                            teamPoints: playerHistoryUiModel.teamPoints,
                            teamGoalsDifference: playerHistoryUiModel.teamGoalsDifference,
                            name: playerHistoryUiModel.name,
                            goals: 0,
                            assists: 0,
                            dribbles: 0,
                            passes: 0,
                            shots: 0,
                            saves: 0
                        )
                        try playerHistoryRepository.updatePlayerHistory(clearedPlayer)
                    }
                }
            }

            fetchGameHistory()
        } catch {
            print("Error clearing results: \(error)")
        }
    }

    private func onSavePlayerResultClicked(
        playerResultUiModel: PlayerResultUiModel,
        playerResultValue: Int
    ) {
        let player = playerResultUiModel.playerUiModel

        let updatedPlayer: PlayerUiModel
        switch playerResultUiModel.option {
        case .goal:
            updatedPlayer = PlayerUiModel(
                id: player.id,
                teamId: player.teamId,
                teamColor: player.teamColor,
                teamName: player.teamName,
                teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference,
                name: player.name,
                goals: playerResultValue,
                assists: player.assists,
                dribbles: player.dribbles,
                passes: player.passes,
                shots: player.shots,
                saves: player.saves
            )
        case .assist:
            updatedPlayer = PlayerUiModel(
                id: player.id,
                teamId: player.teamId,
                teamColor: player.teamColor,
                teamName: player.teamName,
                teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference,
                name: player.name,
                goals: player.goals,
                assists: playerResultValue,
                dribbles: player.dribbles,
                passes: player.passes,
                shots: player.shots,
                saves: player.saves
            )
        case .save:
            updatedPlayer = PlayerUiModel(
                id: player.id,
                teamId: player.teamId,
                teamColor: player.teamColor,
                teamName: player.teamName,
                teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference,
                name: player.name,
                goals: player.goals,
                assists: player.assists,
                dribbles: player.dribbles,
                passes: player.passes,
                shots: player.shots,
                saves: playerResultValue
            )
        case .dribble:
            updatedPlayer = PlayerUiModel(
                id: player.id,
                teamId: player.teamId,
                teamColor: player.teamColor,
                teamName: player.teamName,
                teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference,
                name: player.name,
                goals: player.goals,
                assists: player.assists,
                dribbles: playerResultValue,
                passes: player.passes,
                shots: player.shots,
                saves: player.saves
            )
        case .shot:
            updatedPlayer = PlayerUiModel(
                id: player.id,
                teamId: player.teamId,
                teamColor: player.teamColor,
                teamName: player.teamName,
                teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference,
                name: player.name,
                goals: player.goals,
                assists: player.assists,
                dribbles: player.dribbles,
                passes: player.passes,
                shots: playerResultValue,
                saves: player.saves
            )
        case .pass:
            updatedPlayer = PlayerUiModel(
                id: player.id,
                teamId: player.teamId,
                teamColor: player.teamColor,
                teamName: player.teamName,
                teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference,
                name: player.name,
                goals: player.goals,
                assists: player.assists,
                dribbles: player.dribbles,
                passes: playerResultValue,
                shots: player.shots,
                saves: player.saves
            )
        }

        do {
            try playerHistoryRepository.updatePlayerHistory(updatedPlayer)
            fetchGameHistory()
            setEffect(.showSnackbar(message: NSLocalizedString("save_success", comment: "")))
        } catch {
            print("Error saving player result: \(error)")
        }
    }

    private func setEffect(_ effect: GameResultsEffect) {
        self.effect = effect
    }
}
