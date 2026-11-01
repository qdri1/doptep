//
//  PitchSurface.swift
//  doptep
//

import SwiftUI

enum PitchSurface: String, CaseIterable {
    case grass = "Grass"
    case parquet = "Parquet"

    var localizationKey: String {
        switch self {
        case .grass: return "pitch_surface_grass"
        case .parquet: return "pitch_surface_parquet"
        }
    }

    var style: PitchStyle {
        switch self {
        case .grass:
            return PitchStyle(
                dark: Color(hex: "#0B2F1B"),
                mid: Color(hex: "#123D22"),
                deep: Color(hex: "#0A2818"),
                centerMarkAlpha: 0.06,
                dividerAlpha: 0.10,
                ballSize: 24
            )
        case .parquet:
            return PitchStyle(
                dark: Color(hex: "#6E4310"),
                mid: Color(hex: "#A2661C"),
                deep: Color(hex: "#54320A"),
                centerMarkAlpha: 0.22,
                dividerAlpha: 0.28,
                ballSize: 20
            )
        }
    }

    static func from(_ value: String) -> PitchSurface {
        PitchSurface(rawValue: value) ?? .grass
    }
}

struct PitchStyle {
    let dark: Color
    let mid: Color
    let deep: Color
    let centerMarkAlpha: Double
    let dividerAlpha: Double
    let ballSize: CGFloat
}
