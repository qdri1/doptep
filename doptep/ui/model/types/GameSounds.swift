//
//  GameSounds.swift
//  doptep
//

import Foundation

enum GameSounds: String, CaseIterable {
    case whistle
    case leagueChemp = "sound_league_chemp"
    case goalFans = "sound_goal_fans"
    case uoUoUo = "sound_uo_uo_uo"
    case stadiumApplause = "stadium_applause"
    case girlsApplause = "girls_applause"
    case suiii = "suiiiii"
    case suiiiFull = "suiii_full"
    case goalGoalGoal = "gol_gol_gol"
    case oiiiKandaiGoal = "oooi_kandai_gol"
    case anarbekov = "sound_anarbekov"
    case bilgeninIstepJatyr = "bilgenin_istep_jatyr"
    case goalSave = "goal_save"
    case modrichtynPasy = "modrichtyn_pasy"
    case tondyrypTastagan = "tondyryp_tastagan"

    var localizationKey: String {
        switch self {
        case .whistle: return "sound_whistle"
        case .leagueChemp: return "sound_league_chemp"
        case .goalFans: return "sound_goal_fans"
        case .anarbekov: return "sound_anarbekov"
        case .uoUoUo: return "sound_uo_uo_uo"
        case .stadiumApplause: return "sound_stadium_applause"
        case .girlsApplause: return "sound_girls_applause"
        case .bilgeninIstepJatyr: return "sound_bilgenin_istep_jatyr"
        case .goalSave: return "sound_goal_save"
        case .modrichtynPasy: return "sound_modrichtyn_pasy"
        case .tondyrypTastagan: return "sound_tondyryp_tastagan"
        case .suiii: return "sound_suiii"
        case .suiiiFull: return "sound_suiii_full"
        case .goalGoalGoal: return "sound_goal_goal_goal"
        case .oiiiKandaiGoal: return "sound_oooi_kandai_gol"
        }
    }

    var fileName: String {
        rawValue
    }
}
