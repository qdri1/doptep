//
//  GameRulesSheet.swift
//  doptep
//

import SwiftUI

struct GameRulesSheet: View {
    let rules: [GameRule]
    let selectedRule: GameRule?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(rules, id: \.localizationKey) { rule in
                        GameRuleInfoCard(
                            rule: rule,
                            isSelected: rule.localizationKey == selectedRule?.localizationKey
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(AppColor.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("game_rules", comment: ""))
                        .font(.bodyMedium)
                        .foregroundColor(AppColor.onSurface)
                }
            }
        }
    }
}

private struct GameRuleInfoCard: View {
    let rule: GameRule
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString(rule.localizationKey, comment: ""))
                .font(.bodyMedium)
                .foregroundColor(isSelected ? AppColor.primary : AppColor.onSurface)

            Text(GameRuleInfo.description(for: rule))
                .font(.labelSmall)
                .foregroundColor(AppColor.onSurface)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("game_rule_example", comment: ""))
                    .font(.labelSmall)
                    .foregroundColor(AppColor.outline)
                Text(GameRuleInfo.example(for: rule))
                    .font(.labelSmall)
                    .foregroundColor(AppColor.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColor.background)
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? AppColor.primary : Color.clear, lineWidth: 1)
        )
    }
}

private enum GameRuleInfo {

    static func description(for rule: GameRule) -> String {
        guard let (key, maxGames) = keyAndMaxGames(for: rule, prefix: "game_rule_description") else { return "" }
        return text(key: key, maxGames: maxGames)
    }

    static func example(for rule: GameRule) -> String {
        guard let (key, maxGames) = keyAndMaxGames(for: rule, prefix: "game_rule_example") else { return "" }
        return text(key: key, maxGames: maxGames)
    }

    private static func text(key: String, maxGames: Int?) -> String {
        let format = NSLocalizedString(key, comment: "")
        guard let maxGames else { return format }
        return String(format: format, maxGames)
    }

    private static func keyAndMaxGames(for rule: GameRule, prefix: String) -> (String, Int?)? {
        switch rule {
        case let rule as GameRuleTeam2:
            switch rule {
            case .afterTimeChangeSide: return ("\(prefix)_2_change_side", nil)
            case .afterTimeStaySide: return ("\(prefix)_2_stay_side", nil)
            }
        case let rule as GameRuleTeam3:
            switch rule {
            case .only2Games: return ("\(prefix)_3_only_2_games", nil)
            case .winnerStay3: return ("\(prefix)_3_winner_stay", 3)
            case .winnerStay4: return ("\(prefix)_3_winner_stay", 4)
            case .winnerStayUnlimited: return ("\(prefix)_3_winner_stay_unlimited", nil)
            }
        case let rule as GameRuleTeam4:
            switch rule {
            case .only2Games: return ("\(prefix)_4_only_2_games", nil)
            case .roundRobin: return ("\(prefix)_4_round_robin", nil)
            case .winnerStay3: return ("\(prefix)_4_winner_stay", 3)
            case .winnerStay4: return ("\(prefix)_4_winner_stay", 4)
            case .winnerStay5: return ("\(prefix)_4_winner_stay", 5)
            case .winnerStay6: return ("\(prefix)_4_winner_stay", 6)
            case .winnerStayUnlimited: return ("\(prefix)_4_winner_stay_unlimited", nil)
            }
        default:
            return nil
        }
    }
}
