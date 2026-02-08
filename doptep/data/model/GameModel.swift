//
//  GameModel.swift
//  doptep
//
//  Created by Kudaibergen Alimtayev on 30.12.2025.
//


import SwiftData
import Foundation

@Model
final class GameModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var format: String
    var teamQuantity: Int
    var rule: String
    var timeInMinutes: Int
    var modifiedTime: Date = Date()

    init(
        name: String,
        format: String,
        teamQuantity: Int,
        rule: String,
        timeInMinutes: Int
    ) {
        self.id = UUID()
        self.name = name
        self.format = format
        self.teamQuantity = teamQuantity
        self.rule = rule
        self.timeInMinutes = timeInMinutes
        self.modifiedTime = Date()
    }
}

extension GameModel {

    func toUiModel() -> GameUiModel {
        let format = GameFormat.from(format)
        let team = TeamQuantity.from(teamQuantity)
        let rule = GameRuleFactory.getRule(
            teamQuantity: team,
            rule: rule
        )

        return GameUiModel(
            id: id,
            name: name,
            gameFormat: format,
            teamQuantity: team,
            gameRule: rule,
            timeInMinutes: timeInMinutes,
            modifiedTime: modifiedTime
        )
    }
}
