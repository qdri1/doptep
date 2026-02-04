//
//  TeamHistoryModel.swift
//  doptep
//

import SwiftData
import Foundation

@Model
final class TeamHistoryModel {
    @Attribute(.unique) var id: UUID
    var originalId: UUID
    var gameId: UUID
    var name: String
    var color: String
    var games: Int
    var wins: Int
    var draws: Int
    var loses: Int
    var goals: Int
    var conceded: Int
    var points: Int

    init(
        originalId: UUID,
        gameId: UUID,
        name: String,
        color: String,
        games: Int = 0,
        wins: Int = 0,
        draws: Int = 0,
        loses: Int = 0,
        goals: Int = 0,
        conceded: Int = 0,
        points: Int = 0
    ) {
        self.id = UUID()
        self.originalId = originalId
        self.gameId = gameId
        self.name = name
        self.color = color
        self.games = games
        self.wins = wins
        self.draws = draws
        self.loses = loses
        self.goals = goals
        self.conceded = conceded
        self.points = points
    }

    var goalsDifference: Int {
        goals - conceded
    }
}
