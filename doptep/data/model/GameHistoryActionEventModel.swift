import SwiftData
import Foundation

@Model
final class GameHistoryActionEventModel {
    @Attribute(.unique) var id: UUID
    var historyEntryId: UUID
    var teamName: String
    var teamColor: String
    var playerName: String
    var playerNumber: Int?
    var actionType: String
    var elapsedSeconds: Int

    init(
        historyEntryId: UUID,
        teamName: String,
        teamColor: String,
        playerName: String,
        playerNumber: Int?,
        actionType: String,
        elapsedSeconds: Int
    ) {
        self.id = UUID()
        self.historyEntryId = historyEntryId
        self.teamName = teamName
        self.teamColor = teamColor
        self.playerName = playerName
        self.playerNumber = playerNumber
        self.actionType = actionType
        self.elapsedSeconds = elapsedSeconds
    }
}
