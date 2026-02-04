//
//  PlayerUiModel.swift
//  doptep
//

import Foundation

struct PlayerUiModel: Identifiable, Equatable {
    let id: UUID
    let teamId: UUID
    let teamColor: TeamColor
    let teamName: String
    let teamPoints: Int
    let teamGoalsDifference: Int
    let name: String
    let goals: Int
    let assists: Int
    let dribbles: Int
    let passes: Int
    let shots: Int
    let saves: Int
}

extension PlayerUiModel {

    func toPlayerModel() -> PlayerModel {
        PlayerModel(
            teamId: teamId,
            name: name,
            goals: goals,
            assists: assists,
            dribbles: dribbles,
            passes: passes,
            shots: shots,
            saves: saves
        )
    }

    func toPlayerHistoryModel() -> PlayerHistoryModel {
        PlayerHistoryModel(
            originalId: id,
            teamId: teamId,
            name: name,
            goals: goals,
            assists: assists,
            dribbles: dribbles,
            passes: passes,
            shots: shots,
            saves: saves
        )
    }

    static func empty(teamId: UUID) -> PlayerUiModel {
        PlayerUiModel(
            id: UUID(),
            teamId: teamId,
            teamColor: .red,
            teamName: "",
            teamPoints: 0,
            teamGoalsDifference: 0,
            name: "",
            goals: 0,
            assists: 0,
            dribbles: 0,
            passes: 0,
            shots: 0,
            saves: 0
        )
    }
}
