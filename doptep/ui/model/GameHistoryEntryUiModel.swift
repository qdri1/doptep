import Foundation

struct GameHistoryEntryUiModel: Identifiable {
    let id = UUID()
    let gameNumber: Int
    let leftTeamName: String
    let leftTeamColor: TeamColor
    let leftTeamGoals: Int
    let rightTeamName: String
    let rightTeamColor: TeamColor
    let rightTeamGoals: Int
    let winnerTeamName: String
    let durationSeconds: Int
    let actionEvents: [GameHistoryActionEventUiModel]

    var durationFormatted: String? {
        guard durationSeconds > 0 else { return nil }
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct GameHistoryActionEventUiModel: Identifiable {
    let id = UUID()
    let teamName: String
    let teamColor: TeamColor
    let playerName: String
    let playerNumber: Int?
    let actionType: String
    let elapsedSeconds: Int

    var elapsedFormatted: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
