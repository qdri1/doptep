//
//  SoundSettingsStorage.swift
//  doptep
//

import Foundation

/// App-wide on/off switches for automatic game sounds. Everything is enabled by default.
enum SoundSettingsStorage {
    private static func key(for setting: GameSoundSetting) -> String {
        "sound_setting_\(setting.rawValue)"
    }

    static func isEnabled(_ setting: GameSoundSetting) -> Bool {
        UserDefaults.standard.object(forKey: key(for: setting)) as? Bool ?? true
    }

    static func setEnabled(_ enabled: Bool, for setting: GameSoundSetting) {
        UserDefaults.standard.set(enabled, forKey: key(for: setting))
    }

    static func loadAll() -> [GameSoundSetting: Bool] {
        Dictionary(uniqueKeysWithValues: GameSoundSetting.allCases.map { ($0, isEnabled($0)) })
    }

    static func setAllEnabled(_ enabled: Bool) {
        GameSoundSetting.allCases.forEach { setEnabled(enabled, for: $0) }
    }
}
