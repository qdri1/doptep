//
//  TeamChangeDropdown.swift
//  doptep
//
//  Created by K.Alimtayev on 30.07.2026.
//


import SwiftUI
import RevenueCat
import RevenueCatUI

struct TeamChangeDropdown: View {
    let teams: [TeamUiModel]
    let excludeTeamIds: [UUID]
    let onTeamSelected: (UUID) -> Void
    let onDismiss: () -> Void

    var availableTeams: [TeamUiModel] {
        teams.filter { !excludeTeamIds.contains($0.id) }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(availableTeams) { team in
                    Button {
                        onTeamSelected(team.id)
                    } label: {
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(team.color.color)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(team.color == .white ? AppColor.surfaceVariant : Color.clear, lineWidth: 1)
                                )
                            Text(team.name)
                                .font(.bodySmall)
                                .foregroundColor(AppColor.onSurface)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("choose_team", comment: ""))
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