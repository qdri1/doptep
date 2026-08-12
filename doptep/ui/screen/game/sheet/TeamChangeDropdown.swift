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
                                .frame(width: 16, height: 16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(team.color == .white ? AppColor.surfaceVariant : Color.clear, lineWidth: 1)
                                )
                            Text(team.name)
                                .font(.titleSmall)
                                .foregroundColor(AppColor.onSurface)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .title) {
                    Text(NSLocalizedString("choose_team", comment: ""))
                        .font(.titleMedium)
                        .foregroundColor(AppColor.onSurface)
                }
            }
        }
    }
}
