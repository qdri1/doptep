//
//  TeamUiModel.swift
//  doptep
//

import Foundation

struct TeamUiModel: Identifiable, Equatable {
    let id: UUID
    let gameId: UUID
    let name: String
    let color: TeamColor
    let games: Int
    let wins: Int
    let draws: Int
    let loses: Int
    let goals: Int
    let conceded: Int
    let points: Int

    var goalsDifference: Int {
        goals - conceded
    }
}

extension TeamUiModel {

    func toTeamModel() -> TeamModel {
        TeamModel(
            gameId: gameId,
            name: name,
            color: color.rawValue,
            games: games,
            wins: wins,
            draws: draws,
            loses: loses,
            goals: goals,
            conceded: conceded,
            points: points
        )
    }

    func toTeamHistoryModel() -> TeamHistoryModel {
        TeamHistoryModel(
            originalId: id,
            gameId: gameId,
            name: name,
            color: color.rawValue,
            games: games,
            wins: wins,
            draws: draws,
            loses: loses,
            goals: goals,
            conceded: conceded,
            points: points
        )
    }

    static func empty(gameId: UUID, color: TeamColor = .red) -> TeamUiModel {
        TeamUiModel(
            id: UUID(),
            gameId: gameId,
            name: "",
            color: color,
            games: 0,
            wins: 0,
            draws: 0,
            loses: 0,
            goals: 0,
            conceded: 0,
            points: 0
        )
    }
}
