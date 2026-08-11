//
//  LiveGameResultSheet.swift
//  doptep
//
//  Created by K.Alimtayev on 30.07.2026.
//


import SwiftUI
import RevenueCat
import RevenueCatUI

struct LiveGameResultSheet: View {
    let liveGameResult: LiveGameResultUiModel
    let onSave: (Int) -> Void
    let onDismiss: () -> Void

    @State private var value: Int

    init(liveGameResult: LiveGameResultUiModel, onSave: @escaping (Int) -> Void, onDismiss: @escaping () -> Void) {
        self.liveGameResult = liveGameResult
        self.onSave = onSave
        self.onDismiss = onDismiss
        let goals = liveGameResult.isLeftTeam
            ? liveGameResult.liveGameUiModel.leftTeamGoals
            : liveGameResult.liveGameUiModel.rightTeamGoals
        _value = State(initialValue: goals)
    }

    private var teamName: String {
        liveGameResult.isLeftTeam
            ? liveGameResult.liveGameUiModel.leftTeamName
            : liveGameResult.liveGameUiModel.rightTeamName
    }

    private var teamColor: Color {
        (liveGameResult.isLeftTeam
            ? liveGameResult.liveGameUiModel.leftTeamColor
            : liveGameResult.liveGameUiModel.rightTeamColor).color
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Team Info
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(teamColor)
                            .frame(width: 24, height: 24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(teamColor == .white ? AppColor.surfaceVariant : Color.clear, lineWidth: 1)
                            )

                        Text(teamName)
                            .font(.titleMedium)

                        Spacer()
                    }
                    .padding(.horizontal)

                    // Stat Type
                    Text(NSLocalizedString("goals", comment: ""))
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
                        onSave(value)
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
                    Text(NSLocalizedString("edit_team_goals", comment: ""))
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