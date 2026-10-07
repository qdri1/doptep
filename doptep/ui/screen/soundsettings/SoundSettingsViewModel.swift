//
//  SoundSettingsViewModel.swift
//  doptep
//

import Foundation

@MainActor
final class SoundSettingsViewModel: ObservableObject {

    @Published private(set) var settings: [GameSoundSetting: Bool] = SoundSettingsStorage.loadAll()

    var isAllEnabled: Bool {
        settings.values.allSatisfy { $0 }
    }

    func isEnabled(_ setting: GameSoundSetting) -> Bool {
        settings[setting] ?? true
    }

    func setAllEnabled(_ enabled: Bool) {
        SoundSettingsStorage.setAllEnabled(enabled)
        settings = SoundSettingsStorage.loadAll()
    }

    func setEnabled(_ enabled: Bool, for setting: GameSoundSetting) {
        SoundSettingsStorage.setEnabled(enabled, for: setting)
        settings[setting] = enabled
    }
}
