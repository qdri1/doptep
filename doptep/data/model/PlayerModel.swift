//
//  PlayerModel.swift
//  doptep
//

import SwiftData
import Foundation

@Model
final class PlayerModel {
    @Attribute(.unique) var id: UUID
    var teamId: UUID
    var name: String
    var goals: Int
    var assists: Int
    var dribbles: Int
    var passes: Int
    var shots: Int
    var saves: Int

    init(
        id: UUID = UUID(),
        teamId: UUID,
        name: String,
        goals: Int = 0,
        assists: Int = 0,
        dribbles: Int = 0,
        passes: Int = 0,
        shots: Int = 0,
        saves: Int = 0
    ) {
        self.id = id
        self.teamId = teamId
        self.name = name
        self.goals = goals
        self.assists = assists
        self.dribbles = dribbles
        self.passes = passes
        self.shots = shots
        self.saves = saves
    }
}

extension PlayerModel {

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
}
