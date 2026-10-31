//
//  LiveGameRepository.swift
//  doptep
//

import SwiftData
import Foundation

@MainActor
final class LiveGameRepository {

    private let context: ModelContext
    private let timerKey = "timer_value"

    init(context: ModelContext) {
        self.context = context
    }

    func getLiveGame(gameId: UUID) throws -> LiveGameUiModel? {
        let descriptor = FetchDescriptor<LiveGameModel>(
            predicate: #Predicate { $0.gameId == gameId }
        )
        guard let model = try context.fetch(descriptor).first else {
            return nil
        }
        return LiveGameUiModel(
            id: model.id,
            gameId: model.gameId,
            leftTeamId: model.leftTeamId,
            leftTeamName: model.leftTeamName,
            leftTeamColor: TeamColor.from(model.leftTeamColor),
            leftTeamGoals: model.leftTeamGoals,
            leftTeamWinCount: model.leftTeamWinCount,
            rightTeamId: model.rightTeamId,
            rightTeamName: model.rightTeamName,
            rightTeamColor: TeamColor.from(model.rightTeamColor),
            rightTeamGoals: model.rightTeamGoals,
            rightTeamWinCount: model.rightTeamWinCount,
            gameCount: model.gameCount,
            isLive: model.isLive
        )
    }

    func saveLiveGame(_ model: LiveGameModel) -> UUID {
        context.insert(model)
        return model.id
    }

    func updateLiveGame(_ uiModel: LiveGameUiModel) throws {
        guard let model = try getLiveGameEntity(gameId: uiModel.gameId) else { return }
        model.leftTeamId = uiModel.leftTeamId
        model.leftTeamName = uiModel.leftTeamName
        model.leftTeamColor = uiModel.leftTeamColor.rawValue
        model.leftTeamGoals = uiModel.leftTeamGoals
        model.leftTeamWinCount = uiModel.leftTeamWinCount
        model.rightTeamId = uiModel.rightTeamId
        model.rightTeamName = uiModel.rightTeamName
        model.rightTeamColor = uiModel.rightTeamColor.rawValue
        model.rightTeamGoals = uiModel.rightTeamGoals
        model.rightTeamWinCount = uiModel.rightTeamWinCount
        model.gameCount = uiModel.gameCount
        model.isLive = uiModel.isLive
    }

    func deleteLiveGame(gameId: UUID) throws {
        if let model = try getLiveGameEntity(gameId: gameId) {
            context.delete(model)
        }
    }

    func saveTimerValue(_ value: Int) {
        UserDefaults.standard.set(value, forKey: timerKey)
    }

    func clearTimerValue() {
        UserDefaults.standard.set(0, forKey: timerKey)
    }

    func getTimerValue() -> Int {
        UserDefaults.standard.integer(forKey: timerKey)
    }

    func getLastLeftTeamId(gameId: UUID) -> UUID? {
        UserDefaults.standard.string(forKey: lastLeftTeamKey(gameId: gameId)).flatMap(UUID.init(uuidString:))
    }

    func saveLastLeftTeamId(gameId: UUID, teamId: UUID) {
        UserDefaults.standard.set(teamId.uuidString, forKey: lastLeftTeamKey(gameId: gameId))
    }

    func clearLastLeftTeamId(gameId: UUID) {
        UserDefaults.standard.removeObject(forKey: lastLeftTeamKey(gameId: gameId))
    }

    func getTeamOrder(gameId: UUID) -> [UUID]? {
        UserDefaults.standard.stringArray(forKey: teamOrderKey(gameId: gameId))?.compactMap(UUID.init(uuidString:))
    }

    func saveTeamOrder(gameId: UUID, teamIds: [UUID]) {
        UserDefaults.standard.set(teamIds.map(\.uuidString), forKey: teamOrderKey(gameId: gameId))
    }

    func clearTeamOrder(gameId: UUID) {
        UserDefaults.standard.removeObject(forKey: teamOrderKey(gameId: gameId))
    }

    func getRoundRobinStart(gameId: UUID) -> Int {
        UserDefaults.standard.integer(forKey: roundRobinStartKey(gameId: gameId))
    }

    func saveRoundRobinStart(gameId: UUID, gameCount: Int) {
        UserDefaults.standard.set(gameCount, forKey: roundRobinStartKey(gameId: gameId))
    }

    func clearRoundRobinStart(gameId: UUID) {
        UserDefaults.standard.removeObject(forKey: roundRobinStartKey(gameId: gameId))
    }

    private func roundRobinStartKey(gameId: UUID) -> String {
        "round_robin_start_\(gameId.uuidString)"
    }

    private func teamOrderKey(gameId: UUID) -> String {
        "team_order_\(gameId.uuidString)"
    }

    private func lastLeftTeamKey(gameId: UUID) -> String {
        "last_left_team_id_\(gameId.uuidString)"
    }

    private func getLiveGameEntity(gameId: UUID) throws -> LiveGameModel? {
        let descriptor = FetchDescriptor<LiveGameModel>(
            predicate: #Predicate { $0.gameId == gameId }
        )
        return try context.fetch(descriptor).first
    }
}
