//
//  LiveGameModel.swift
//  doptep
//

import SwiftData
import Foundation

@Model
final class LiveGameModel {
    @Attribute(.unique) var id: UUID
    var gameId: UUID
    var leftTeamId: UUID
    var leftTeamName: String
    var leftTeamColor: String
    var leftTeamGoals: Int
    var leftTeamWinCount: Int
    var rightTeamId: UUID
    var rightTeamName: String
    var rightTeamColor: String
    var rightTeamGoals: Int
    var rightTeamWinCount: Int
    var gameCount: Int
    var isLive: Bool

    init(
        gameId: UUID,
        leftTeamId: UUID,
        leftTeamName: String,
        leftTeamColor: String,
        leftTeamGoals: Int = 0,
        leftTeamWinCount: Int = 0,
        rightTeamId: UUID,
        rightTeamName: String,
        rightTeamColor: String,
        rightTeamGoals: Int = 0,
        rightTeamWinCount: Int = 0,
        gameCount: Int = 0,
        isLive: Bool = false
    ) {
        self.id = UUID()
        self.gameId = gameId
        self.leftTeamId = leftTeamId
        self.leftTeamName = leftTeamName
        self.leftTeamColor = leftTeamColor
        self.leftTeamGoals = leftTeamGoals
        self.leftTeamWinCount = leftTeamWinCount
        self.rightTeamId = rightTeamId
        self.rightTeamName = rightTeamName
        self.rightTeamColor = rightTeamColor
        self.rightTeamGoals = rightTeamGoals
        self.rightTeamWinCount = rightTeamWinCount
        self.gameCount = gameCount
        self.isLive = isLive
    }
}
