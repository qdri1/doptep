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

        case .onPlayerResultClicked(let playerResultUiModel):
            effect = .showPlayerResultBottomSheet(playerResultUiModel: playerResultUiModel)

        case .onSavePlayerResultClicked(let playerResultUiModel, let playerResultValue):
            onSavePlayerResultClicked(playerResultUiModel: playerResultUiModel, playerResultValue: playerResultValue)

        case .onTeamResultClicked(let teamUiModel):
            effect = .showTeamResultBottomSheet(teamUiModel: teamUiModel)

        case .onSaveTeamResultClicked(let teamUiModel, let pointsValue):
            onSaveTeamResultClicked(teamUiModel: teamUiModel, pointsValue: pointsValue)

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
                .sorted { lhs, rhs in
                    if lhs.points != rhs.points { return lhs.points > rhs.points }
                    if lhs.goalsDifference != rhs.goalsDifference { return lhs.goalsDifference > rhs.goalsDifference }
                    return lhs.name < rhs.name
                }

            var allPlayers: [PlayerUiModel] = []
            for teamUiModel in teamUiModelList {
                let players = try playerHistoryRepository.getPlayersHistories(teamId: teamUiModel.id)
                allPlayers.append(contentsOf: players)
            }

            let playerUiModelList = allPlayers.sorted { lhs, rhs in
                if lhs.goals != rhs.goals { return lhs.goals > rhs.goals }
                if lhs.assists != rhs.assists { return lhs.assists > rhs.assists }
                if lhs.saves != rhs.saves { return lhs.saves > rhs.saves }
                let lhsOther = lhs.dribbles + lhs.shots + lhs.passes
                let rhsOther = rhs.dribbles + rhs.shots + rhs.passes
                if lhsOther != rhsOther { return lhsOther > rhsOther }
                if lhs.redCards != rhs.redCards { return lhs.redCards < rhs.redCards }
                if lhs.yellowCards != rhs.yellowCards { return lhs.yellowCards < rhs.yellowCards }
                if lhs.teamPoints != rhs.teamPoints { return lhs.teamPoints > rhs.teamPoints }
                if lhs.teamGoalsDifference != rhs.teamGoalsDifference { return lhs.teamGoalsDifference > rhs.teamGoalsDifference }
                if lhs.teamName != rhs.teamName { return lhs.teamName < rhs.teamName }
                return lhs.name < rhs.name
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
                yellowCards: player.yellowCards, redCards: player.redCards,
                number: player.number
            )
        case .assist:
            updatedPlayer = PlayerUiModel(
                id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                teamName: player.teamName, teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                goals: player.goals, assists: playerResultValue, dribbles: player.dribbles,
                passes: player.passes, shots: player.shots, saves: player.saves,
                yellowCards: player.yellowCards, redCards: player.redCards,
                number: player.number
            )
        case .save:
            updatedPlayer = PlayerUiModel(
                id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                teamName: player.teamName, teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                passes: player.passes, shots: player.shots, saves: playerResultValue,
                yellowCards: player.yellowCards, redCards: player.redCards,
                number: player.number
            )
        case .dribble:
            updatedPlayer = PlayerUiModel(
                id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                teamName: player.teamName, teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                goals: player.goals, assists: player.assists, dribbles: playerResultValue,
                passes: player.passes, shots: player.shots, saves: player.saves,
                yellowCards: player.yellowCards, redCards: player.redCards,
                number: player.number
            )
        case .shot:
            updatedPlayer = PlayerUiModel(
                id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                teamName: player.teamName, teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                passes: player.passes, shots: playerResultValue, saves: player.saves,
                yellowCards: player.yellowCards, redCards: player.redCards,
                number: player.number
            )
        case .pass:
            updatedPlayer = PlayerUiModel(
                id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                teamName: player.teamName, teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                passes: playerResultValue, shots: player.shots, saves: player.saves,
                yellowCards: player.yellowCards, redCards: player.redCards,
                number: player.number
            )
        case .yellowCard:
            updatedPlayer = PlayerUiModel(
                id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                teamName: player.teamName, teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                passes: player.passes, shots: player.shots, saves: player.saves,
                yellowCards: playerResultValue, redCards: player.redCards,
                number: player.number
            )
        case .redCard:
            updatedPlayer = PlayerUiModel(
                id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                teamName: player.teamName, teamPoints: player.teamPoints,
                teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                passes: player.passes, shots: player.shots, saves: player.saves,
                yellowCards: player.yellowCards, redCards: playerResultValue,
                number: player.number
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

    private func onSaveTeamResultClicked(teamUiModel: TeamUiModel, pointsValue: Int) {
        let updatedTeam = TeamUiModel(
            id: teamUiModel.id,
            gameId: teamUiModel.gameId,
            name: teamUiModel.name,
            color: teamUiModel.color,
            games: teamUiModel.games,
            wins: teamUiModel.wins,
            draws: teamUiModel.draws,
            loses: teamUiModel.loses,
            goals: teamUiModel.goals,
            conceded: teamUiModel.conceded,
            points: pointsValue
        )
        do {
            try teamHistoryRepository.updateTeamHistory(updatedTeam)
            fetchGameHistory()
            setEffect(.showSnackbar(message: NSLocalizedString("save_success", comment: "")))
        } catch {
            print("Error saving team result: \(error)")
        }
    }

    private func onBestPlayersAllGamesClicked() {
        var bestPlayers: [BestPlayerUiModel] = []
        let allPlayers = uiState.playerUiModelList
        
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
                        saves: 0,
                        yellowCards: 0,
                        redCards: 0,
                        number: player.number
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
