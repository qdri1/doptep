//
//  GameInfoSheet.swift
//  doptep
//
//  Created by K.Alimtayev on 30.07.2026.
//


import SwiftUI
import RevenueCat
import RevenueCatUI

struct GameInfoSheet: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Live Game Block Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.titleLarge)
                                .foregroundColor(AppColor.onSurfaceVariant)
                            
                            Text(NSLocalizedString("live_game_info_replace_teams", comment: ""))
                                .font(.labelSmall)
                                .foregroundColor(AppColor.onSurface)
                        }
                        HStack(spacing: 12) {
                            Image(systemName: "pause.fill")
                                .foregroundColor(AppColor.onSurface)
                            
                            Text(NSLocalizedString("live_game_info_pause_timer", comment: ""))
                                .font(.labelSmall)
                                .foregroundColor(AppColor.onSurface)
                        }
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .foregroundColor(AppColor.onSurface)

                            Text(NSLocalizedString("live_game_info_play_timer", comment: ""))
                                .font(.labelSmall)
                                .foregroundColor(AppColor.onSurface)
                        }
                    }

                    Divider()

                    // Teams Block Info
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(symbol: NSLocalizedString("games_short", comment: ""), description: NSLocalizedString("teams_block_info_games", comment: ""))
                        InfoRow(symbol: NSLocalizedString("wins_short", comment: ""), description: NSLocalizedString("teams_block_info_wins", comment: ""))
                        InfoRow(symbol: NSLocalizedString("draws_short", comment: ""), description: NSLocalizedString("teams_block_info_draws", comment: ""))
                        InfoRow(symbol: NSLocalizedString("loses_short", comment: ""), description: NSLocalizedString("teams_block_info_loses", comment: ""))
                        InfoRow(symbol: NSLocalizedString("goals_short", comment: ""), description: NSLocalizedString("teams_block_info_goals_conceded", comment: ""))
                        InfoRow(symbol: NSLocalizedString("goal_difference_short", comment: ""), description: NSLocalizedString("teams_block_info_goals_difference", comment: ""))
                        InfoRow(symbol: NSLocalizedString("points_short", comment: ""), description: NSLocalizedString("teams_block_info_points", comment: ""))
                    }

                    Divider()

                    // Players Block Info
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(symbol: NSLocalizedString("goals_icon", comment: ""), description: NSLocalizedString("players_block_info_goals", comment: ""))
                        InfoRow(symbol: NSLocalizedString("assists_icon", comment: ""), description: NSLocalizedString("players_block_info_assists", comment: ""))
                        InfoRow(symbol: NSLocalizedString("saves_icon", comment: ""), description: NSLocalizedString("players_block_info_saves", comment: ""))
                        InfoRow(symbol: NSLocalizedString("tackles_icon", comment: ""), description: NSLocalizedString("players_block_info_tackles", comment: ""))
                        InfoRow(symbol: NSLocalizedString("dribbles_icon", comment: ""), description: NSLocalizedString("players_block_info_dribbles", comment: ""))
                        InfoRow(symbol: NSLocalizedString("shots_icon", comment: ""), description: NSLocalizedString("players_block_info_shots", comment: ""))
                        InfoRow(symbol: NSLocalizedString("passes_icon", comment: ""), description: NSLocalizedString("players_block_info_passes", comment: ""))
                        InfoRow(symbol: NSLocalizedString("player_result_yellow_card", comment: ""), description: NSLocalizedString("players_block_info_yellow_card", comment: ""))
                        InfoRow(symbol: NSLocalizedString("player_result_red_card", comment: ""), description: NSLocalizedString("players_block_info_red_card", comment: ""))
                    }
                    
                    Divider()
                    
                    HStack(spacing: 12) {
                        Text(NSLocalizedString("live_game_info_streak_title", comment: ""))
                            .font(.labelSmall)
                            .foregroundColor(AppColor.outline)

                        Text(NSLocalizedString("live_game_info_streak_desc", comment: ""))
                            .font(.labelSmall)
                            .foregroundColor(AppColor.onSurface)
                    }

                    Spacer()
                }
                .padding()
            }
            .background(AppColor.surface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("function_info", comment: ""))
                        .font(.bodyMedium)
                        .foregroundColor(AppColor.onSurface)
                }
            }
        }
    }
}

struct InfoRow: View {
    let symbol: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Text(symbol)
                .font(.labelSmall)
                .foregroundColor(AppColor.outline)
                
            Text(description)
                .font(.labelSmall)
                .foregroundColor(AppColor.onSurface)
        }
    }
}
