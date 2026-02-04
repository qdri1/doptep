//
//  TeamRepository.swift
//  doptep
//

import SwiftData
import Foundation

@MainActor
final class TeamRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getTeams(gameId: UUID) throws -> [TeamUiModel] {
        let descriptor = FetchDescriptor<TeamModel>(
            predicate: #Predicate { $0.gameId == gameId }
        )
        let models = try context.fetch(descriptor)
        return models.map { model in
            TeamUiModel(
                id: model.id,
                gameId: model.gameId,
                name: model.name,
                color: TeamColor.from(model.color),
                games: model.games,
                wins: model.wins,
                draws: model.draws,
                loses: model.loses,
                goals: model.goals,
                conceded: model.conceded,
                points: model.points
            )
        }
    }

    func getTeam(id: UUID) throws -> TeamUiModel? {
        let descriptor = FetchDescriptor<TeamModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try context.fetch(descriptor).first else {
            return nil
        }
        return TeamUiModel(
            id: model.id,
            gameId: model.gameId,
            name: model.name,
            color: TeamColor.from(model.color),
            games: model.games,
            wins: model.wins,
            draws: model.draws,
            loses: model.loses,
            goals: model.goals,
            conceded: model.conceded,
            points: model.points
        )
    }

    func saveTeam(_ model: TeamModel) -> UUID {
        context.insert(model)
        return model.id
    }

    func updateTeam(_ uiModel: TeamUiModel) throws {
        guard let model = try getTeamEntity(id: uiModel.id) else { return }
        model.name = uiModel.name
        model.color = uiModel.color.rawValue
        model.games = uiModel.games
        model.wins = uiModel.wins
        model.draws = uiModel.draws
        model.loses = uiModel.loses
        model.goals = uiModel.goals
        model.conceded = uiModel.conceded
        model.points = uiModel.points
    }

    func deleteTeam(_ model: TeamModel) {
        context.delete(model)
    }

    func deleteTeam(id: UUID) throws {
        if let team = try getTeamEntity(id: id) {
            context.delete(team)
        }
    }

    private func getTeamEntity(id: UUID) throws -> TeamModel? {
        let descriptor = FetchDescriptor<TeamModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
}
