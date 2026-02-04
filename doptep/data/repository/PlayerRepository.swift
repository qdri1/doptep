//
//  PlayerRepository.swift
//  doptep
//

import SwiftData
import Foundation

@MainActor
final class PlayerRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getPlayers(teamId: UUID) throws -> [PlayerUiModel] {
        let teamModel = try getTeamModel(teamId: teamId)
        let teamGoalsDifference = (teamModel?.goals ?? 0) - (teamModel?.conceded ?? 0)

        let descriptor = FetchDescriptor<PlayerModel>(
            predicate: #Predicate { $0.teamId == teamId }
        )
        let models = try context.fetch(descriptor)
        return models.map { model in
            PlayerUiModel(
                id: model.id,
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

    func getPlayer(id: UUID) throws -> PlayerUiModel? {
        let descriptor = FetchDescriptor<PlayerModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try context.fetch(descriptor).first else {
            return nil
        }
        return PlayerUiModel(
            id: model.id,
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

    func savePlayer(_ model: PlayerModel) -> UUID {
        context.insert(model)
        return model.id
    }

    func updatePlayer(_ uiModel: PlayerUiModel) throws {
        guard let model = try getPlayerEntity(id: uiModel.id) else { return }
        model.name = uiModel.name
        model.goals = uiModel.goals
        model.assists = uiModel.assists
        model.dribbles = uiModel.dribbles
        model.passes = uiModel.passes
        model.shots = uiModel.shots
        model.saves = uiModel.saves
    }

    func deletePlayer(_ model: PlayerModel) {
        context.delete(model)
    }

    func deletePlayer(id: UUID) throws {
        if let player = try getPlayerEntity(id: id) {
            context.delete(player)
        }
    }

    private func getPlayerEntity(id: UUID) throws -> PlayerModel? {
        let descriptor = FetchDescriptor<PlayerModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    private func getTeamModel(teamId: UUID) throws -> TeamModel? {
        let descriptor = FetchDescriptor<TeamModel>(
            predicate: #Predicate { $0.id == teamId }
        )
        return try context.fetch(descriptor).first
    }
}
