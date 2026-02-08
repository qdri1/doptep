//
//  GameUiModel.swift
//  doptep
//
//  Created by Kudaibergen Alimtayev on 30.12.2025.
//

import Foundation

struct GameUiModel: Identifiable {
    let id: UUID
    let name: String
    let gameFormat: GameFormat
    let teamQuantity: TeamQuantity
    let gameRule: GameRule
    let timeInMinutes: Int
    let modifiedTime: Date
}
