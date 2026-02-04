//
//  GameFormat.swift
//  doptep
//
//  Created by Kudaibergen Alimtayev on 30.12.2025.
//


enum GameFormat: String, CaseIterable {
    case format4x4 = "4x4"
    case format5x5 = "5x5"
    case format6x6 = "6x6"
    case format7x7 = "7x7"
    case format8x8 = "8x8"
    case format9x9 = "9x9"
    case format10x10 = "10x10"
    case format11x11 = "11x11"

    var playerQuantity: Int {
        switch self {
        case .format4x4:
            4
        case .format5x5:
            5
        case .format6x6:
            6
        case .format7x7:
            7
        case .format8x8:
            8
        case .format9x9:
            9
        case .format10x10:
            10
        case .format11x11:
            11
        }
    }

    static func from(_ value: String, defaultValue: GameFormat = .format5x5) -> GameFormat {
        GameFormat(rawValue: value) ?? defaultValue
    }
}
