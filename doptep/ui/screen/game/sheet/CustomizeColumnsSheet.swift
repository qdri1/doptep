//
//  CustomizeColumnsSheet.swift
//  doptep
//
//  Created by K.Alimtayev on 30.07.2026.
//


import SwiftUI
import RevenueCat
import RevenueCatUI

struct CustomizeColumnsSheet: View {
    @Binding var hiddenOptions: Set<TeamOption>
    @Environment(\.dismiss) private var dismiss

    private let toggleableOptions: [TeamOption] = [.save, .dribble, .shot, .pass, .yellowCard, .redCard]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                Text(NSLocalizedString("customize_columns_subtitle", comment: ""))
                    .font(.bodySmall)
                    .foregroundColor(AppColor.outline)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                List {
                    ForEach(toggleableOptions, id: \.self) { option in
                        HStack {
                            Text(NSLocalizedString(option.localizationKey, comment: ""))
                                .font(.bodySmall)
                                .foregroundColor(AppColor.onSurface)
                            Spacer()
                            Image(systemName: hiddenOptions.contains(option) ? "checkmark.circle" : "checkmark.circle.fill")
                                .foregroundColor(hiddenOptions.contains(option) ? AppColor.outline : AppColor.primary)
                                .font(.title3)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if hiddenOptions.contains(option) {
                                hiddenOptions.remove(option)
                            } else {
                                hiddenOptions.insert(option)
                            }
                        }
                        .listRowBackground(AppColor.surface)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(AppColor.background)
            }
            .background(AppColor.background)
            .navigationTitle(NSLocalizedString("customize_columns_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("done", comment: "")) {
                        dismiss()
                    }
                    .font(.labelSmall)
                    .foregroundColor(AppColor.primary)
                }
            }
        }
    }
}