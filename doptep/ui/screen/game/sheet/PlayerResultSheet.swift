//
//  PlayerResultSheet.swift
//  doptep
//
//  Created by K.Alimtayev on 30.07.2026.
//


import SwiftUI
import RevenueCat
import RevenueCatUI

struct PlayerResultSheet: View {
    let playerResult: PlayerResultUiModel
    let onSave: (TeamOption, Int) -> Void
    let onDismiss: () -> Void

    @State private var value: Int

    init(playerResult: PlayerResultUiModel, onSave: @escaping (TeamOption, Int) -> Void, onDismiss: @escaping () -> Void) {
        self.playerResult = playerResult
        self.onSave = onSave
        self.onDismiss = onDismiss

        let initialValue: Int
        switch playerResult.option {
        case .goal: initialValue = playerResult.playerUiModel.goals
        case .assist: initialValue = playerResult.playerUiModel.assists
        case .save: initialValue = playerResult.playerUiModel.saves
        case .tackle: initialValue = playerResult.playerUiModel.tackles
        case .dribble: initialValue = playerResult.playerUiModel.dribbles
        case .shot: initialValue = playerResult.playerUiModel.shots
        case .pass: initialValue = playerResult.playerUiModel.passes
        case .yellowCard: initialValue = playerResult.playerUiModel.yellowCards
        case .redCard: initialValue = playerResult.playerUiModel.redCards
        }
        _value = State(initialValue: initialValue)
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Player Info
                    HStack(spacing: 12) {
                        PlayerTeamBadge(teamColor: playerResult.playerUiModel.teamColor, number: playerResult.playerUiModel.number, size: 24)

                        Text(playerResult.playerUiModel.name)
                            .font(.titleMedium)

                        Spacer()
                    }
                    .padding(.horizontal)

                    // Stat Type
                    Text(NSLocalizedString(playerResult.option.localizationKey, comment: ""))
                        .font(.titleMedium)
                        .foregroundColor(AppColor.onSurfaceVariant)

                    // Value Stepper
                    HStack(spacing: 32) {
                        Button {
                            if value > 0 {
                                value -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.custom("Montserrat-SemiBold", size: 44))
                                .foregroundColor(AppColor.error)
                        }

                        Text("\(value)")
                            .font(.custom("Montserrat-Bold", size: 48))
                            .frame(minWidth: 80)

                        Button {
                            value += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.custom("Montserrat-SemiBold", size: 44))
                                .foregroundColor(AppColor.primary)
                        }
                    }

                    // Save Button
                    Button {
                        onSave(playerResult.option, value)
                    } label: {
                        Text(NSLocalizedString("save", comment: ""))
                            .font(.titleMedium)
                            .foregroundColor(AppColor.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColor.primary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Text(NSLocalizedString("result_correction_text", comment: ""))
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.bodySmall)
                        .foregroundColor(AppColor.error)
                        .padding(.horizontal)
                }
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
            .background(AppColor.surface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("edit_result", comment: ""))
                        .font(.bodyMedium)
                        .foregroundColor(AppColor.onSurface)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
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