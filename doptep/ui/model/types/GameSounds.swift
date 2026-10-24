//
//  GameSounds.swift
//  doptep
//

import Foundation

enum GameSounds: String, CaseIterable {
    case dopTep = "sound_dop_tep_1"
    case whistle
    case startMatch = "start_match"
    case penaltyRealMadrid = "sound_penalty_real_madrid"
    case leagueChemp = "sound_league_chemp"
    case freedFromDesire = "sound_freed_from_desire_more"
    case shakiraDaiDai = "shakira_dai_dai"
    case goalFans = "sound_goal_fans"
    case uoUoUo = "sound_uo_uo_uo"
    case stadiumApplause = "stadium_applause"
    case girlsApplause = "girls_applause"
    case suiii = "suiiiii"
    case suiiiFull = "suiii_full"
    case goalGoalGoal = "gol_gol_gol"
    case oiiiKandaiGoal = "oooi_kandai_gol"
    case bilgeninIstepJatyr = "bilgenin_istep_jatyr"
    case europaKarashy = "europa_karashy"
    case satpayev = "satpayev_gol_full"
    case anarbekov = "sound_anarbekov"
    case goalSave = "goal_save"
    case kakoiSave = "kakoi_save_full"
    case toniKrossPass = "toni_kross_pass_full"
    case kandaiGalamatPas = "kandai_galamat_pas_jane_gol_full"
    case modrichtynPasy = "modrichtyn_pasy"
    case tondyrypTastagan = "tondyryp_tastagan"
    case sharipCommentator = "sharip_commentator"

    var localizationKey: String {
        switch self {
        case .dopTep: return "sound_dop_tep"
        case .whistle: return "sound_whistle"
        case .startMatch: return "sound_start_match"
        case .penaltyRealMadrid: return "sound_penalty_real_madrid"
        case .leagueChemp: return "sound_league_chemp"
        case .freedFromDesire: return "sound_freed_from_desire"
        case .goalFans: return "sound_goal_fans"
        case .anarbekov: return "sound_anarbekov"
        case .uoUoUo: return "sound_uo_uo_uo"
        case .shakiraDaiDai: return "sound_shakira_dai_dai"
        case .satpayev: return "sound_satpayev_goal"
        case .kakoiSave: return "sound_kakoi_save"
        case .toniKrossPass: return "sound_toni_kross_pass"
        case .kandaiGalamatPas: return "sound_kandai_galamat_pas"
        case .sharipCommentator: return "sound_sharip_commentator"
        case .stadiumApplause: return "sound_stadium_applause"
        case .girlsApplause: return "sound_girls_applause"
        case .bilgeninIstepJatyr: return "sound_bilgenin_istep_jatyr"
        case .europaKarashy: return "sound_europa_karashy"
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
