//
//  HomeEffect.swift
//  doptep
//
//  Created by Kudaibergen Alimtayev on 30.12.2025.
//

import Foundation

enum HomeEffect: Hashable, Identifiable, Equatable  {
    case openAddGameScreen
    case openGameScreen(UUID)

    var id: String {
        switch self {
        case .openAddGameScreen:
            return "openAddGameScreen"
        case .openGameScreen(let id):
            return "openGameScreen_\(id)"
        }
    }
}
