//
//  TeamHistoryRepository.swift
//  doptep
//

import SwiftData
import Foundation

@MainActor
final class TeamHistoryRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getTeamsHistories(gameId: UUID) throws -> [TeamUiModel] {
        let descriptor = FetchDescriptor<TeamHistoryModel>(
            predicate: #Predicate { $0.gameId == gameId }
        )
        let models = try context.fetch(descriptor)
        return models.map { model in
            TeamUiModel(
                id: model.originalId,
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

    func getTeamHistory(teamId: UUID) throws -> TeamUiModel? {
        let descriptor = FetchDescriptor<TeamHistoryModel>(
            predicate: #Predicate { $0.originalId == teamId }
        )
        guard let model = try context.fetch(descriptor).first else {
            return nil
        }
        return TeamUiModel(
            id: model.originalId,
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

    func saveTeamHistory(_ model: TeamHistoryModel) {
        context.insert(model)
    }

    func updateTeamHistory(_ uiModel: TeamUiModel) throws {
        guard let model = try getTeamHistoryEntity(teamId: uiModel.id) else { return }
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

    func getTeamHistoryEntity(teamId: UUID) throws -> TeamHistoryModel? {
        let descriptor = FetchDescriptor<TeamHistoryModel>(
            predicate: #Predicate { $0.originalId == teamId }
        )
        return try context.fetch(descriptor).first
    }
}
