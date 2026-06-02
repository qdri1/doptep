import SwiftData
import Foundation

@MainActor
final class GameHistoryRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getGameHistory(gameId: UUID) throws -> [GameHistoryEntryUiModel] {
        let entryDescriptor = FetchDescriptor<GameHistoryEntryModel>(
            predicate: #Predicate { $0.gameId == gameId },
            sortBy: [SortDescriptor(\.gameNumber)]
        )
        let entries = try context.fetch(entryDescriptor)
        return try entries.map { entry in
            let entryId = entry.id
            let eventDescriptor = FetchDescriptor<GameHistoryActionEventModel>(
                predicate: #Predicate { $0.historyEntryId == entryId },
                sortBy: [SortDescriptor(\.elapsedSeconds)]
            )
            let events = try context.fetch(eventDescriptor).map { event in
                return GameHistoryActionEventUiModel(
                    teamName: event.teamName,
                    teamColor: TeamColor.from(event.teamColor),
                    playerName: event.playerName,
                    playerNumber: event.playerNumber,
                    actionType: event.actionType,
                    elapsedSeconds: event.elapsedSeconds
                )
            }
            return GameHistoryEntryUiModel(
                gameNumber: entry.gameNumber,
                leftTeamName: entry.leftTeamName,
                leftTeamColor: TeamColor.from(entry.leftTeamColor),
                leftTeamGoals: entry.leftTeamGoals,
                rightTeamName: entry.rightTeamName,
                rightTeamColor: TeamColor.from(entry.rightTeamColor),
                rightTeamGoals: entry.rightTeamGoals,
                winnerTeamName: entry.winnerTeamName,
                durationSeconds: entry.durationSeconds,
                actionEvents: events
            )
        }
    }

    func saveEntry(_ entry: GameHistoryEntryModel) -> UUID {
        context.insert(entry)
        try? context.save()
        return entry.id
    }

    func saveActionEvent(_ event: GameHistoryActionEventModel) {
        context.insert(event)
        try? context.save()
    }

    func deleteGameHistory(gameId: UUID) throws {
        let descriptor = FetchDescriptor<GameHistoryEntryModel>(
            predicate: #Predicate { $0.gameId == gameId }
        )
        let entries = try context.fetch(descriptor)
        for entry in entries {
            context.delete(entry)
        }
        try? context.save()
    }
}
