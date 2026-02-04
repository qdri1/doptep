//
//  AddGameEffect.swift
//  doptep
//

import Foundation

enum AddGameEffect: Hashable, Identifiable, Equatable {
    case showColorsBottomSheet
    case showSnackbar(message: String)
    case openGameScreen(gameId: UUID)
    case closeScreen
    case closeScreenWithResult

    var id: String {
        switch self {
        case .showColorsBottomSheet:
            return "showColorsBottomSheet"
        case .showSnackbar(let message):
            return "showSnackbar_\(message)"
        case .openGameScreen(let gameId):
            return "openGameScreen_\(gameId)"
        case .closeScreen:
            return "closeScreen"
        case .closeScreenWithResult:
            return "closeScreenWithResult"
        }
    }
}
