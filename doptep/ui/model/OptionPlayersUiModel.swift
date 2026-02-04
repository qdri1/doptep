//
//  OptionPlayersUiModel.swift
//  doptep
//

import Foundation

struct OptionPlayersUiModel: Equatable {
    let option: TeamOption
    let teamId: UUID
    let playerUiModelList: [PlayerUiModel]
}
