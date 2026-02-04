//
//  LiveGameUiModel.swift
//  doptep
//

import Foundation

struct LiveGameUiModel: Identifiable, Equatable {
    let id: UUID
    let gameId: UUID
    let leftTeamId: UUID
    let leftTeamName: String
    let leftTeamColor: TeamColor
    let leftTeamGoals: Int
    let leftTeamWinCount: Int
    let rightTeamId: UUID
    let rightTeamName: String
    let rightTeamColor: TeamColor
    let rightTeamGoals: Int
    let rightTeamWinCount: Int
    let gameCount: Int
    let isLive: Bool

    var isLeftTeamWin: Bool {
        leftTeamGoals > rightTeamGoals
    }

    var isRightTeamWin: Bool {
        leftTeamGoals < rightTeamGoals
    }

    var leftTeamMaxLines: Int {
        let wordsCount = leftTeamName.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .count
        return min(wordsCount, 3)
    }

    var rightTeamMaxLines: Int {
        let wordsCount = rightTeamName.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .count
        return min(wordsCount, 3)
    }
}

extension LiveGameUiModel {

    func toLiveGameModel() -> LiveGameModel {
        LiveGameModel(
            gameId: gameId,
            leftTeamId: leftTeamId,
            leftTeamName: leftTeamName,
            leftTeamColor: leftTeamColor.rawValue,
            leftTeamGoals: leftTeamGoals,
            leftTeamWinCount: leftTeamWinCount,
            rightTeamId: rightTeamId,
            rightTeamName: rightTeamName,
            rightTeamColor: rightTeamColor.rawValue,
            rightTeamGoals: rightTeamGoals,
            rightTeamWinCount: rightTeamWinCount,
            gameCount: gameCount,
            isLive: isLive
        )
    }

    func updating(
        leftTeamGoals: Int? = nil,
        leftTeamWinCount: Int? = nil,
        rightTeamGoals: Int? = nil,
        rightTeamWinCount: Int? = nil,
        gameCount: Int? = nil,
        isLive: Bool? = nil
    ) -> LiveGameUiModel {
        LiveGameUiModel(
            id: id,
            gameId: gameId,
            leftTeamId: leftTeamId,
            leftTeamName: leftTeamName,
            leftTeamColor: leftTeamColor,
            leftTeamGoals: leftTeamGoals ?? self.leftTeamGoals,
            leftTeamWinCount: leftTeamWinCount ?? self.leftTeamWinCount,
            rightTeamId: rightTeamId,
            rightTeamName: rightTeamName,
            rightTeamColor: rightTeamColor,
            rightTeamGoals: rightTeamGoals ?? self.rightTeamGoals,
            rightTeamWinCount: rightTeamWinCount ?? self.rightTeamWinCount,
            gameCount: gameCount ?? self.gameCount,
            isLive: isLive ?? self.isLive
        )
    }
}
