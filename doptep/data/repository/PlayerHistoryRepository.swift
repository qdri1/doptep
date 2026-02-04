//
//  PlayerHistoryRepository.swift
//  doptep
//

import SwiftData
import Foundation

@MainActor
final class PlayerHistoryRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getPlayersHistories(teamId: UUID) throws -> [PlayerUiModel] {
        let teamModel = try getTeamHistoryModel(teamId: teamId)
        let teamGoalsDifference = (teamModel?.goals ?? 0) - (teamModel?.conceded ?? 0)

        let descriptor = FetchDescriptor<PlayerHistoryModel>(
            predicate: #Predicate { $0.teamId == teamId }
        )
        let models = try context.fetch(descriptor)
        return models.map { model in
            PlayerUiModel(
                id: model.originalId,
                teamId: model.teamId,
                teamColor: TeamColor.from(teamModel?.color ?? ""),
                teamName: teamModel?.name ?? "",
                teamPoints: teamModel?.points ?? 0,
                teamGoalsDifference: teamGoalsDifference,
                name: model.name,
                goals: model.goals,
                assists: model.assists,
                dribbles: model.dribbles,
                passes: model.passes,
                shots: model.shots,
                saves: model.saves
            )
        }
    }

    func getPlayerHistory(playerId: UUID) throws -> PlayerUiModel? {
        let descriptor = FetchDescriptor<PlayerHistoryModel>(
            predicate: #Predicate { $0.originalId == playerId }
        )
        guard let model = try context.fetch(descriptor).first else {
            return nil
        }
        return PlayerUiModel(
            id: model.originalId,
            teamId: model.teamId,
            teamColor: .red,
            teamName: "",
            teamPoints: 0,
            teamGoalsDifference: 0,
            name: model.name,
            goals: model.goals,
            assists: model.assists,
            dribbles: model.dribbles,
            passes: model.passes,
            shots: model.shots,
            saves: model.saves
        )
    }

    func getPlayerHistory(teamId: UUID, playerName: String) throws -> PlayerUiModel? {
        let descriptor = FetchDescriptor<PlayerHistoryModel>(
            predicate: #Predicate { $0.teamId == teamId && $0.name == playerName }
        )
        guard let model = try context.fetch(descriptor).first else {
            return nil
        }
        return PlayerUiModel(
            id: model.originalId,
            teamId: model.teamId,
            teamColor: .red,
            teamName: "",
            teamPoints: 0,
            teamGoalsDifference: 0,
            name: model.name,
            goals: model.goals,
            assists: model.assists,
            dribbles: model.dribbles,
            passes: model.passes,
            shots: model.shots,
            saves: model.saves
        )
    }

    func savePlayerHistory(_ model: PlayerHistoryModel) {
        context.insert(model)
    }

    func updatePlayerHistory(_ uiModel: PlayerUiModel) throws {
        guard let model = try getPlayerHistoryEntity(playerId: uiModel.id) else { return }
        model.name = uiModel.name
        model.goals = uiModel.goals
        model.assists = uiModel.assists
        model.dribbles = uiModel.dribbles
        model.passes = uiModel.passes
        model.shots = uiModel.shots
        model.saves = uiModel.saves
    }

    func deletePlayerHistory(_ model: PlayerHistoryModel) {
        context.delete(model)
    }

    func deletePlayerHistory(playerId: UUID) throws {
        if let model = try getPlayerHistoryEntity(playerId: playerId) {
            context.delete(model)
        }
    }

    private func getPlayerHistoryEntity(playerId: UUID) throws -> PlayerHistoryModel? {
        let descriptor = FetchDescriptor<PlayerHistoryModel>(
            predicate: #Predicate { $0.originalId == playerId }
        )
        return try context.fetch(descriptor).first
    }

    private func getTeamHistoryModel(teamId: UUID) throws -> TeamHistoryModel? {
        let descriptor = FetchDescriptor<TeamHistoryModel>(
            predicate: #Predicate { $0.originalId == teamId }
        )
        return try context.fetch(descriptor).first
    }
}
