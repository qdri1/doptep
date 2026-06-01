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
    let yellowCards: Int
    let redCards: Int
    let number: Int?

    init(
        id: UUID,
        teamId: UUID,
        teamColor: TeamColor,
        teamName: String,
        teamPoints: Int,
        teamGoalsDifference: Int,
        name: String,
        goals: Int,
        assists: Int,
        dribbles: Int,
        passes: Int,
        shots: Int,
        saves: Int,
        yellowCards: Int,
        redCards: Int,
        number: Int?
    ) {
        self.id = id
        self.teamId = teamId
        self.teamColor = teamColor
        self.teamName = teamName
        self.teamPoints = teamPoints
        self.teamGoalsDifference = teamGoalsDifference
        self.name = name
        self.goals = goals
        self.assists = assists
        self.dribbles = dribbles
        self.passes = passes
        self.shots = shots
        self.saves = saves
        self.yellowCards = yellowCards
        self.redCards = redCards
        self.number = number
    }
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
            saves: saves,
            yellowCards: yellowCards,
            redCards: redCards,
            number: number
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
            saves: saves,
            yellowCards: yellowCards,
            redCards: redCards,
            number: number
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
            saves: 0,
            yellowCards: 0,
            redCards: 0,
            number: nil
        )
    }
}
