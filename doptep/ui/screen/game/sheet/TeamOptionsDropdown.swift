//
//  TeamOptionsDropdown.swift
//  doptep
//
//  Created by K.Alimtayev on 30.07.2026.
//


import SwiftUI
import RevenueCat
import RevenueCatUI

struct TeamOptionsDropdown: View {
    let teamName: String
    let teamColor: Color
    let hiddenOptions: Set<TeamOption>
    let onOptionSelected: (TeamOption) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(TeamOption.allCases.filter { !hiddenOptions.contains($0) }, id: \.self) { option in
                    Button {
                        onOptionSelected(option)
                    } label: {
                        Text(NSLocalizedString(option.localizationKey, comment: ""))
                            .font(.titleSmall)
                            .foregroundColor(AppColor.onSurface)
                            .padding(4)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .title) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(teamColor)
                            .frame(width: 20, height: 20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(teamColor == .white ? AppColor.surfaceVariant : Color.clear, lineWidth: 1)
                            )
                        Text(teamName)
                            .font(.titleMedium)
                            .foregroundColor(AppColor.onSurface)
                    }
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