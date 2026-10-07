//
//  GameSoundSetting.swift
//  doptep
//

import Foundation

/// Automatic sounds and voice-overs that GameScreen plays on its own
/// (manual sound buttons in the sounds section are not affected).
enum GameSoundSetting: String, CaseIterable {
    case startMatch
    case finishMatch
    case oneMinuteLeft
    case tenSecondsLeft
    case actionVoice
    case actionSounds

    var titleKey: String {
        switch self {
        case .startMatch: return "sound_setting_start_match"
        case .finishMatch: return "sound_setting_finish_match"
        case .oneMinuteLeft: return "sound_setting_one_minute_left"
        case .tenSecondsLeft: return "sound_setting_ten_seconds_left"
        case .actionVoice: return "sound_setting_action_voice"
        case .actionSounds: return "sound_setting_action_sounds"
        }
    }

    var descriptionKey: String {
        "\(titleKey)_description"
    }
}
