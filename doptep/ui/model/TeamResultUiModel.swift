//
//  TeamResultUiModel.swift
//  doptep
//

import Foundation

struct TeamResultUiModel: Equatable {
    let teamUiModel: TeamUiModel
    let option: TeamResultOption

    var value: Int {
        teamUiModel.value(of: option)
    }
}

extension TeamUiModel {

    func value(of option: TeamResultOption) -> Int {
        switch option {
        case .games: return games
        case .wins: return wins
        case .draws: return draws
        case .loses: return loses
        case .goals: return goals
        case .conceded: return conceded
        case .points: return points
        }
    }

    func withValue(_ value: Int, for option: TeamResultOption) -> TeamUiModel {
        TeamUiModel(
            id: id,
            gameId: gameId,
            name: name,
            color: color,
            games: option == .games ? value : games,
            wins: option == .wins ? value : wins,
            draws: option == .draws ? value : draws,
            loses: option == .loses ? value : loses,
            goals: option == .goals ? value : goals,
            conceded: option == .conceded ? value : conceded,
            points: option == .points ? value : points
        )
    }
}

extension TeamHistoryModel {

    func value(of option: TeamResultOption) -> Int {
        switch option {
        case .games: return games
        case .wins: return wins
        case .draws: return draws
        case .loses: return loses
        case .goals: return goals
        case .conceded: return conceded
        case .points: return points
        }
    }

    func setValue(_ value: Int, for option: TeamResultOption) {
        switch option {
        case .games: games = value
        case .wins: wins = value
        case .draws: draws = value
        case .loses: loses = value
        case .goals: goals = value
        case .conceded: conceded = value
        case .points: points = value
        }
    }
}
