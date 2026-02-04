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

    private func getLiveGameEntity(gameId: UUID) throws -> LiveGameModel? {
        let descriptor = FetchDescriptor<LiveGameModel>(
            predicate: #Predicate { $0.gameId == gameId }
        )
        return try context.fetch(descriptor).first
    }
}
