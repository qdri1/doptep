//
//  HiddenColumnsStorage.swift
//  doptep
//

import Foundation

enum HiddenColumnsStorage {
    private static func key(for gameId: UUID) -> String {
        "hidden_columns_\(gameId.uuidString)"
    }

    static func load(gameId: UUID) -> Set<TeamOption> {
        guard let rawValues = UserDefaults.standard.stringArray(forKey: key(for: gameId)) else {
            return []
        }
        return Set(rawValues.compactMap { TeamOption(rawValue: $0) })
    }

    static func save(_ options: Set<TeamOption>, gameId: UUID) {
        let rawValues = options.map { $0.rawValue }
        UserDefaults.standard.set(rawValues, forKey: key(for: gameId))
    }
}
