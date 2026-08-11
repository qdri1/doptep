//
//  BestPlayersSheet.swift
//  doptep
//
//  Created by K.Alimtayev on 30.07.2026.
//


import SwiftUI
import RevenueCat
import RevenueCatUI

// Лучшие игроки

struct BestPlayersSheet: View {
    let bestPlayers: [BestPlayerUiModel]

    var body: some View {
        NavigationView {
            List {
                ForEach(bestPlayers, id: \.option) { bestPlayer in

                    VStack(alignment: .leading) {
                        Text(NSLocalizedString(bestPlayer.option.localizationKey, comment: ""))
                            .font(.labelSmall)
                            .foregroundColor(AppColor.outline)

                        HStack {
                            PlayerTeamBadge(teamColor: bestPlayer.playerUiModel.teamColor, number: bestPlayer.playerUiModel.number)

                            Text(bestPlayer.playerUiModel.name)
                                .font(.bodySmall)
                                .foregroundColor(AppColor.onSurface)

                            Spacer()

                            switch bestPlayer.option {
                            case .bestPlayer:
                                let result = [
                                    stat(bestPlayer.playerUiModel.goals, "text_goal"),
                                    stat(bestPlayer.playerUiModel.assists, "text_assist"),
                                    stat(bestPlayer.playerUiModel.saves, "text_save"),
                                    stat(bestPlayer.playerUiModel.dribbles, "text_dribble"),
                                    stat(bestPlayer.playerUiModel.passes, "text_pass"),
                                    stat(bestPlayer.playerUiModel.shots, "text_shot"),
                                    stat(bestPlayer.playerUiModel.yellowCards, "text_yellow_card"),
                                    stat(bestPlayer.playerUiModel.redCards, "text_red_card")
                                ]
                                .compactMap { $0 }
                                .joined(separator: ", ")

                                Text(result)
                                    .font(.bodySmall)
                                    .foregroundColor(AppColor.onSurface)
                                    .padding(.leading, 32)
                            case .goals:
                                Text("\(bestPlayer.playerUiModel.goals) \(NSLocalizedString("text_goal", comment: ""))")
                                    .font(.bodySmall)
                                    .foregroundColor(AppColor.onSurface)
                            case .assists:
                                Text("\(bestPlayer.playerUiModel.assists) \(NSLocalizedString("text_assist", comment: ""))")
                                    .font(.bodySmall)
                                    .foregroundColor(AppColor.onSurface)
                            case .saves:
                                Text("\(bestPlayer.playerUiModel.saves) \(NSLocalizedString("text_save", comment: ""))")
                                    .font(.bodySmall)
                                    .foregroundColor(AppColor.onSurface)
                            case .dribbles:
                                Text("\(bestPlayer.playerUiModel.dribbles) \(NSLocalizedString("text_dribble", comment: ""))")
                                    .font(.bodySmall)
                                    .foregroundColor(AppColor.onSurface)
                            case .passes:
                                Text("\(bestPlayer.playerUiModel.passes) \(NSLocalizedString("text_pass", comment: ""))")
                                    .font(.bodySmall)
                                    .foregroundColor(AppColor.onSurface)
                            case .shots:
                                Text("\(bestPlayer.playerUiModel.shots) \(NSLocalizedString("text_shot", comment: ""))")
                                    .font(.bodySmall)
                                    .foregroundColor(AppColor.onSurface)
                            case .aggressivePlayer:
                                let result = [
                                    stat(bestPlayer.playerUiModel.yellowCards, "text_yellow_card"),
                                    stat(bestPlayer.playerUiModel.redCards, "text_red_card")
                                ]
                                .compactMap { $0 }
                                .joined(separator: ", ")

                                Text(result)
                                    .font(.bodySmall)
                                    .foregroundColor(AppColor.onSurface)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("best_players", comment: ""))
                        .font(.bodyMedium)
                        .foregroundColor(AppColor.onSurface)
                }
            }
        }
    }
    
    func stat(_ value: Int, _ key: String) -> String? {
        value > 0 ? "\(value) \(NSLocalizedString(key, comment: ""))" : nil
    }
}
