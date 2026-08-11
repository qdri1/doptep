//
//  OptionPlayersSheet.swift
//  doptep
//
//  Created by K.Alimtayev on 30.07.2026.
//


import SwiftUI
import RevenueCat
import RevenueCatUI

struct OptionPlayersSheet: View {
    let optionPlayers: OptionPlayersUiModel
    let onPlayerSelected: (PlayerUiModel) -> Void
    let onAutoGoalSelected: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(optionPlayers.playerUiModelList) { player in
                    Button {
                        onPlayerSelected(player)
                    } label: {
                        HStack(spacing: 8) {
                            PlayerTeamBadge(teamColor: player.teamColor, number: player.number)
                            Text(player.name.prefix(1)).font(.titleSmall).bold().foregroundColor(AppColor.onSurface)
                            + Text(player.name.dropFirst()).font(.titleSmall).foregroundColor(AppColor.onSurface)
                        }
                        .padding(4)
                    }
                }

                if optionPlayers.option == .goal {
                    Button {
                        onAutoGoalSelected()
                    } label: {
                        Text(NSLocalizedString("auto_goal", comment: ""))
                            .font(.titleSmall)
                            .foregroundColor(.orange)
                            .padding(4)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .title) {
                    Text(NSLocalizedString(optionPlayers.option.localizationKey, comment: ""))
                        .font(.titleMedium)
                        .foregroundColor(AppColor.onSurface)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Text(NSLocalizedString("cancel", comment: ""))
                            .font(.bodySmall)
                            .foregroundColor(AppColor.outline)
                    }
                }
            }
        }
    }
}