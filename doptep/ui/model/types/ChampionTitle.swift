//
//  ChampionTitle.swift
//  doptep
//

import Foundation

enum ChampionTitle: String, CaseIterable {
    case matchKing
    case sniper
    case playmaker
    case wall
    case pitbull
    case magician
    case maestro
    case cannon
    case allRounder
    case offTarget
    case hothead
    case workhorse
    case engine
    case greyCardinal
    case teamPlayer
    case shadow
    case ghost
    case tourist
    case spectator
    case furniture
    case statue

    static let activeFallbacks: [ChampionTitle] = [.workhorse, .engine, .greyCardinal, .teamPlayer, .shadow]

    static let emptyFallbacks: [ChampionTitle] = [.ghost, .tourist, .spectator, .furniture, .statue]

    var localizationKey: String { "champion_title_\(rawValue)" }

    var descriptionKey: String { "champion_title_\(rawValue)_description" }

    var systemImage: String {
        switch self {
        case .matchKing: return "crown.fill"
        case .sniper: return "scope"
        case .playmaker: return "wand.and.stars"
        case .wall: return "shield.lefthalf.filled"
        case .pitbull: return "bolt.fill"
        case .magician: return "sparkles"
        case .maestro: return "music.note"
        case .cannon: return "flame.fill"
        case .allRounder: return "star.circle.fill"
        case .offTarget: return "arrow.up.right.circle"
        case .hothead: return "exclamationmark.triangle.fill"
        case .workhorse: return "hammer.fill"
        case .engine: return "speedometer"
        case .greyCardinal: return "theatermasks.fill"
        case .teamPlayer: return "person.2.fill"
        case .shadow: return "moon.fill"
        case .ghost: return "eye.slash.fill"
        case .tourist: return "camera.fill"
        case .spectator: return "binoculars.fill"
        case .furniture: return "sofa.fill"
        case .statue: return "figure.stand"
        }
    }

    var accentHex: String {
        switch self {
        case .matchKing: return "#FFC83D"
        case .sniper: return "#FF5A5F"
        case .playmaker: return "#4FC3F7"
        case .wall: return "#7E8CE0"
        case .pitbull: return "#FF8A3D"
        case .magician: return "#C77DFF"
        case .maestro: return "#2EC4B6"
        case .cannon: return "#FF6B35"
        case .allRounder: return "#80ED99"
        case .offTarget: return "#A0A4AB"
        case .hothead: return "#E63946"
        case .workhorse: return "#D4A373"
        case .engine: return "#F4A261"
        case .greyCardinal: return "#B8C0FF"
        case .teamPlayer: return "#5DADE2"
        case .shadow: return "#7D8597"
        case .ghost: return "#8D99AE"
        case .tourist: return "#48CAE4"
        case .spectator: return "#90BE6D"
        case .furniture: return "#BC8A5F"
        case .statue: return "#ADB5BD"
        }
    }
}
