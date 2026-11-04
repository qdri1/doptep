//
//  ChampionsUiModel.swift
//  doptep
//

import Foundation

struct ChampionPlayerUiModel: Equatable, Identifiable {
    let playerUiModel: PlayerUiModel
    let title: ChampionTitle

    var id: UUID { playerUiModel.id }
}

struct ChampionsUiModel: Equatable {
    let teamUiModel: TeamUiModel
    let players: [ChampionPlayerUiModel]
}

extension ChampionsUiModel {

    static func make(team: TeamUiModel, players: [PlayerUiModel]) -> ChampionsUiModel {
        ChampionsUiModel(teamUiModel: team, players: assignTitles(players: players))
    }

    private struct Candidate {
        let playerIndex: Int
        let title: ChampionTitle
        let strength: Double
    }

    private static func score(_ player: PlayerUiModel) -> Int {
        (player.goals * 3) + (player.assists * 2) + (player.saves * 2) + player.tackles + player.dribbles + player.passes + player.shots - player.yellowCards - (player.redCards * 3)
    }

    private static func contributionCount(_ player: PlayerUiModel) -> Int {
        [player.goals, player.assists, player.saves, player.tackles, player.dribbles, player.passes, player.shots]
            .filter { $0 > 0 }
            .count
    }

    private static func isEmpty(_ player: PlayerUiModel) -> Bool {
        contributionCount(player) == 0 && player.yellowCards == 0 && player.redCards == 0
    }

    private static func assignTitles(players: [PlayerUiModel]) -> [ChampionPlayerUiModel] {
        guard !players.isEmpty else { return [] }

        var candidates: [Candidate] = []

        let scores = players.map(score)
        if let bestScore = scores.max(), bestScore > 0, let bestIndex = scores.firstIndex(of: bestScore) {
            candidates.append(Candidate(playerIndex: bestIndex, title: .matchKing, strength: 10))
        }

        let statTitles: [(ChampionTitle, (PlayerUiModel) -> Int, Double)] = [
            (.sniper, { $0.goals }, 1.0),
            (.wall, { $0.saves }, 0.98),
            (.playmaker, { $0.assists }, 0.96),
            (.pitbull, { $0.tackles }, 0.9),
            (.magician, { $0.dribbles }, 0.88),
            (.maestro, { $0.passes }, 0.86),
            (.cannon, { $0.shots }, 0.84),
        ]

        for (title, selector, weight) in statTitles {
            let teamMax = players.map(selector).max() ?? 0
            guard teamMax > 0 else { continue }
            for (index, player) in players.enumerated() {
                let value = selector(player)
                guard value > 0 else { continue }
                candidates.append(Candidate(playerIndex: index, title: title, strength: Double(value) / Double(teamMax) * weight))
            }
        }

        for (index, player) in players.enumerated() {
            let contributions = contributionCount(player)
            if contributions >= 4 {
                candidates.append(Candidate(playerIndex: index, title: .allRounder, strength: 0.8 + Double(contributions) * 0.03))
            }
            if player.shots >= 3 && player.goals == 0 {
                candidates.append(Candidate(playerIndex: index, title: .offTarget, strength: 0.95 + Double(player.shots) * 0.01))
            }
            let cardWeight = player.yellowCards + player.redCards * 3
            if cardWeight > 0 {
                candidates.append(Candidate(playerIndex: index, title: .hothead, strength: (player.redCards > 0 ? 1.05 : 0.7) + Double(cardWeight) * 0.01))
            }
        }

        let sortedCandidates = candidates.enumerated().sorted { lhs, rhs in
            if lhs.element.strength != rhs.element.strength { return lhs.element.strength > rhs.element.strength }
            return lhs.offset < rhs.offset
        }.map(\.element)

        var titles: [Int: ChampionTitle] = [:]
        var usedTitles: Set<ChampionTitle> = []
        for candidate in sortedCandidates {
            guard titles[candidate.playerIndex] == nil, !usedTitles.contains(candidate.title) else { continue }
            titles[candidate.playerIndex] = candidate.title
            usedTitles.insert(candidate.title)
        }

        let result = players.enumerated().map { index, player in
            ChampionPlayerUiModel(
                playerUiModel: player,
                title: titles[index] ?? (isEmpty(player) ? .ghost : .teamPlayer)
            )
        }

        let order = Dictionary(uniqueKeysWithValues: ChampionTitle.allCases.enumerated().map { ($1, $0) })
        return result.enumerated().sorted { lhs, rhs in
            let lhsOrder = order[lhs.element.title] ?? 0
            let rhsOrder = order[rhs.element.title] ?? 0
            if lhsOrder != rhsOrder { return lhsOrder < rhsOrder }
            return lhs.offset < rhs.offset
        }.map(\.element)
    }
}
