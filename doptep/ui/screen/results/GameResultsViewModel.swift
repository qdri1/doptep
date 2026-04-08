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

        case .onPlayerResultClicked(let playerResultUiModel):
            effect = .showPlayerResultBottomSheet(playerResultUiModel: playerResultUiModel)
            
        case .onSavePlayerResultClicked(let playerResultUiModel, let playerResultValue):
            onSavePlayerResultClicked(playerResultUiModel: playerResultUiModel, playerResultValue: playerResultValue)

        case .onBestPlayersAllGamesClicked:
            onBestPlayersAllGamesClicked()

        case .onClearAllGamesResultsClicked:
            setEffect(.showClearAllGamesResultsConfirmationBottomSheet)

        case .onClearAllGamesResultsConfirmationClicked:
            onClearAllGamesResultsConfirmationClicked()

        case .onRemovePlayerClicked(let playerId):
            onRemovePlayerClicked(playerId: playerId)

        case .onActivateClicked:
            break
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
                if player1.saves != player2.saves {
                    return player1.saves > player2.saves
                }
                let player1Extra = player1.dribbles + player1.shots + player1.passes
                let player2Extra = player2.dribbles + player2.shots + player2.passes
                if player1Extra != player2Extra {
                    return player1Extra > player2Extra
                }
                if player1.redCards != player2.redCards {
                    return player1.redCards < player2.redCards
                }
                if player1.yellowCards != player2.yellowCards {
                    return player1.yellowCards < player2.yellowCards
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

            var deletedPlayerIds = Set<UUID>()
            for player in playerUiModelList {
                if (try? playerRepository.getPlayer(id: player.id)) == nil {
                    deletedPlayerIds.insert(player.id)
                }
            }

            let billingType = BillingManager.shared.getCurrentBillingType()
            let uiLimited = billingType == .limited

            uiState = GameResultsUiState(
                teamUiModelList: teamUiModelList,
                playerUiModelList: playerUiModelList,
                deletedPlayerIds: deletedPlayerIds,
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
                id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                teamName: player.teamName, teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                goals: playerResultValue, assists: player.assists, dribbles: player.dribbles,
                passes: player.passes, shots: player.shots, saves: player.saves,
                yellowCards: player.yellowCards, redCards: player.redCards
            )
        case .assist:
            updatedPlayer = PlayerUiModel(
                id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                teamName: player.teamName, teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                goals: player.goals, assists: playerResultValue, dribbles: player.dribbles,
                passes: player.passes, shots: player.shots, saves: player.saves,
                yellowCards: player.yellowCards, redCards: player.redCards
            )
        case .save:
            updatedPlayer = PlayerUiModel(
                id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                teamName: player.teamName, teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                passes: player.passes, shots: player.shots, saves: playerResultValue,
                yellowCards: player.yellowCards, redCards: player.redCards
            )
        case .dribble:
            updatedPlayer = PlayerUiModel(
                id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                teamName: player.teamName, teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                goals: player.goals, assists: player.assists, dribbles: playerResultValue,
                passes: player.passes, shots: player.shots, saves: player.saves,
                yellowCards: player.yellowCards, redCards: player.redCards
            )
        case .shot:
            updatedPlayer = PlayerUiModel(
                id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                teamName: player.teamName, teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                passes: player.passes, shots: playerResultValue, saves: player.saves,
                yellowCards: player.yellowCards, redCards: player.redCards
            )
        case .pass:
            updatedPlayer = PlayerUiModel(
                id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                teamName: player.teamName, teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                passes: playerResultValue, shots: player.shots, saves: player.saves,
                yellowCards: player.yellowCards, redCards: player.redCards
            )
        case .yellowCard:
            updatedPlayer = PlayerUiModel(
                id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                teamName: player.teamName, teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                passes: player.passes, shots: player.shots, saves: player.saves,
                yellowCards: playerResultValue, redCards: player.redCards
            )
        case .redCard:
            updatedPlayer = PlayerUiModel(
                id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                teamName: player.teamName, teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                passes: player.passes, shots: player.shots, saves: player.saves,
                yellowCards: player.yellowCards, redCards: playerResultValue
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

    private func onBestPlayersAllGamesClicked() {
        do {
            let allTeams = try teamHistoryRepository.getAllTeamsHistories()
            var allPlayers: [PlayerUiModel] = []
            for team in allTeams {
                let players = try playerHistoryRepository.getPlayersHistories(teamId: team.id)
                allPlayers.append(contentsOf: players)
            }

            var bestPlayers: [BestPlayerUiModel] = []

            if let best = allPlayers.max(by: { lhs, rhs in
                let lhsScore = (lhs.goals * 3) + (lhs.assists * 2) + (lhs.saves * 2) + lhs.dribbles + lhs.passes + lhs.shots - lhs.yellowCards - (lhs.redCards * 3)
                let rhsScore = (rhs.goals * 3) + (rhs.assists * 2) + (rhs.saves * 2) + rhs.dribbles + rhs.passes + rhs.shots - rhs.yellowCards - (rhs.redCards * 3)
                return lhsScore < rhsScore
            }) {
                bestPlayers.append(BestPlayerUiModel(option: .bestPlayer, playerUiModel: best))
            }

            let statOptions: [(BestPlayerOption, (PlayerUiModel) -> Bool, (PlayerUiModel) -> Int)] = [
                (.goals, { $0.goals > 0 }, { $0.goals }),
                (.assists, { $0.assists > 0 }, { $0.assists }),
                (.saves, { $0.saves > 0 }, { $0.saves }),
                (.dribbles, { $0.dribbles > 0 }, { $0.dribbles }),
                (.passes, { $0.passes > 0 }, { $0.passes }),
                (.shots, { $0.shots > 0 }, { $0.shots }),
            ]
            for (option, filter, selector) in statOptions {
                if let best = allPlayers.filter(filter).max(by: { selector($0) < selector($1) }) {
                    bestPlayers.append(BestPlayerUiModel(option: option, playerUiModel: best))
                }
            }

            if let aggressive = allPlayers.filter({ $0.yellowCards > 0 || $0.redCards > 0 })
                .reversed()
                .max(by: { ($0.yellowCards + ($0.redCards * 3)) < ($1.yellowCards + ($1.redCards * 3)) }) {
                bestPlayers.append(BestPlayerUiModel(option: .aggressivePlayer, playerUiModel: aggressive))
            }

            setEffect(.showBestPlayersBottomSheet(bestPlayers: bestPlayers))
        } catch {
            print("Error computing best players of all games: \(error)")
        }
    }

    private func onClearAllGamesResultsConfirmationClicked() {
        do {
            let allTeams = try teamHistoryRepository.getAllTeamsHistories()
            for teamUiModel in allTeams {
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
                for player in playerHistories {
                    let clearedPlayer = PlayerUiModel(
                        id: player.id,
                        teamId: player.teamId,
                        teamColor: player.teamColor,
                        teamName: player.teamName,
                        teamPoints: player.teamPoints,
                        teamGoalsDifference: player.teamGoalsDifference,
                        name: player.name,
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
            fetchGameHistory()
        } catch {
            print("Error clearing all games results: \(error)")
        }
    }

    private func onRemovePlayerClicked(playerId: UUID) {
        do {
            try playerHistoryRepository.deletePlayerHistory(playerId: playerId)
            fetchGameHistory()
        } catch {
            print("Error removing player history: \(error)")
        }
    }

    private func setEffect(_ effect: GameResultsEffect) {
        self.effect = effect
    }
}
