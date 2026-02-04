//
//  GameRepository.swift
//  doptep
//
//  Created by Kudaibergen Alimtayev on 30.12.2025.
//


import SwiftData
import Foundation

@MainActor
final class GameRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // SELECT * FROM games
    func getGames() throws -> [GameUiModel] {
        let descriptor = FetchDescriptor<GameModel>()
        let models = try context.fetch(descriptor)
        return models.map { $0.toUiModel() }
    }

    // SELECT * FROM games WHERE id = :id
    func getGame(id: UUID) throws -> GameUiModel? {
        let descriptor = FetchDescriptor<GameModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first?.toUiModel()
    }

    // INSERT OR REPLACE
    func saveGame(_ model: GameModel) {
        context.insert(model)
    }

    // UPDATE
    func updateGame(_ uiModel: GameUiModel) throws {
        guard let model = try getGameEntity(id: uiModel.id) else { return }
        model.name = uiModel.name
        model.timeInMinutes = uiModel.timeInMinutes
    }

    func deleteGame(_ model: GameModel) {
        context.delete(model)
    }

    func deleteGame(id: UUID) throws {
        if let game = try getGameEntity(id: id) {
            context.delete(game)
        }
    }

    private func getGameEntity(id: UUID) throws -> GameModel? {
        let descriptor = FetchDescriptor<GameModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
}
