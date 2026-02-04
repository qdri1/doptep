//
//  TeamQuantity.swift
//  doptep
//
//  Created by Kudaibergen Alimtayev on 30.12.2025.
//


enum TeamQuantity: Int, CaseIterable {
    case team2 = 2
    case team3 = 3
    case team4 = 4

    static func from(_ value: Int, defaultValue: TeamQuantity = .team3) -> TeamQuantity {
        TeamQuantity(rawValue: value) ?? defaultValue
    }
}
