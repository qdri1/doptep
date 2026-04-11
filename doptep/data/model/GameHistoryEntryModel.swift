import SwiftData
import Foundation

@Model
final class GameHistoryEntryModel {
    @Attribute(.unique) var id: UUID
    var gameId: UUID
    var gameNumber: Int
    var leftTeamName: String
    var leftTeamColor: String
    var leftTeamGoals: Int
    var rightTeamName: String
    var rightTeamColor: String
    var rightTeamGoals: Int
    var winnerTeamName: String
    var durationSeconds: Int

    init(
        gameId: UUID,
        gameNumber: Int,
        leftTeamName: String,
        leftTeamColor: String,
        leftTeamGoals: Int,
        rightTeamName: String,
        rightTeamColor: String,
        rightTeamGoals: Int,
        winnerTeamName: String,
        durationSeconds: Int
    ) {
        self.id = UUID()
        self.gameId = gameId
        self.gameNumber = gameNumber
        self.leftTeamName = leftTeamName
        self.leftTeamColor = leftTeamColor
        self.leftTeamGoals = leftTeamGoals
        self.rightTeamName = rightTeamName
        self.rightTeamColor = rightTeamColor
        self.rightTeamGoals = rightTeamGoals
        self.winnerTeamName = winnerTeamName
        self.durationSeconds = durationSeconds
    }
}
