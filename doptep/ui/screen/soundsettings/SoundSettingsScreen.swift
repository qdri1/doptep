//
//  SoundSettingsScreen.swift
//  doptep
//

import SwiftUI

struct SoundSettingsScreen: View {
    @StateObject private var viewModel = SoundSettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    settingsCard {
                        settingRow(
                            title: NSLocalizedString("sound_settings_all", comment: ""),
                            description: NSLocalizedString("sound_settings_all_description", comment: ""),
                            isOn: Binding(
                                get: { viewModel.isAllEnabled },
                                set: { viewModel.setAllEnabled($0) }
                            )
                        )
                    }

                    settingsCard {
                        ForEach(Array(GameSoundSetting.allCases.enumerated()), id: \.element) { index, setting in
                            if index > 0 {
                                Rectangle()
                                    .fill(AppColor.background)
                                    .frame(height: 1)
                                    .padding(.horizontal, 16)
                            }
                            settingRow(
                                title: NSLocalizedString(setting.titleKey, comment: ""),
                                description: NSLocalizedString(setting.descriptionKey, comment: ""),
                                isOn: Binding(
                                    get: { viewModel.isEnabled(setting) },
                                    set: { viewModel.setEnabled($0, for: setting) }
                                )
                            )
                        }
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .background(AppColor.background)
        .navigationBarHidden(true)
        .enableSwipeBack()
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.titleLarge)
                    .foregroundColor(AppColor.onSurface)
            }

            Text(NSLocalizedString("sound_settings_title", comment: ""))
                .font(.titleMedium)
                .foregroundColor(AppColor.onSurface)
                .frame(maxWidth: .infinity)

            Spacer()
                .frame(width: 24)
        }
        .padding()
        .background(AppColor.surface)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func settingRow(title: String, description: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.labelMedium)
                    .foregroundColor(AppColor.onSurface)
                Text(description)
                    .font(.labelSmall)
                    .foregroundColor(AppColor.outline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(AppColor.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
