//
//  ChampionsSheet.swift
//  doptep
//

import SwiftUI

struct ChampionsSheet: View {
    let champions: ChampionsUiModel

    var body: some View {
        ScrollView {
            content
        }
        .background(AppColor.background)
    }

    private var content: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("champions", comment: ""))
                .font(.bodyMedium)
                .foregroundColor(AppColor.onSurface)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .padding(.bottom, 4)

            ChampionTeamHeroCard(team: champions.teamUiModel)

            ForEach(champions.players) { champion in
                ChampionPlayerRow(champion: champion)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}

private struct ChampionTeamHeroCard: View {
    let team: TeamUiModel

    private var teamName: String {
        team.name.isEmpty ? NSLocalizedString(team.color.localizationKey, comment: "") : team.name
    }

    private var stats: [String] {
        [
            String(format: NSLocalizedString("champions_points", comment: ""), team.points),
            String(format: NSLocalizedString("champions_record", comment: ""), team.wins, team.draws, team.loses),
            String(format: NSLocalizedString("champions_goals", comment: ""), team.goals, team.conceded)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12, weight: .bold))
                Text(NSLocalizedString("champions_first_place", comment: ""))
                    .font(.labelSmall)
                    .textCase(.uppercase)
                    .tracking(0.4)
                Spacer()
            }
            .foregroundColor(Color(hex: "#FFD166"))

            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(team.color.color)
                    .frame(width: 20, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )

                Text(teamName)
                    .font(.titleLarge)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 40)
            }

            HStack(spacing: 6) {
                ForEach(stats, id: \.self) { statText in
                    Text(statText)
                        .font(.labelSmall)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.16)))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#1B1500"), Color(hex: "#7A5800"), Color(hex: "#E0A800")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [Color(hex: "#FFE38A").opacity(0.55), Color.clear],
                    center: .topTrailing,
                    startRadius: 4,
                    endRadius: 180
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.4), Color.white.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .overlay(alignment: .topTrailing) {
            Text("#1")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(Color.white.opacity(0.9))
                .padding(.top, 10)
                .padding(.trailing, 16)
        }
    }
}

private struct ChampionPlayerRow: View {
    let champion: ChampionPlayerUiModel

    private var accent: Color { Color(hex: champion.title.accentHex) }

    private var player: PlayerUiModel { champion.playerUiModel }

    private var stats: [String] {
        [
            stat(player.goals, "⚽️"),
            stat(player.assists, "👟"),
            stat(player.saves, "🧤"),
            stat(player.tackles, "🛡️"),
            stat(player.dribbles, "🌀"),
            stat(player.shots, "💥"),
            stat(player.passes, "🎯"),
            stat(player.yellowCards, "🟨"),
            stat(player.redCards, "🟥")
        ]
        .compactMap { $0 }
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: 36, height: 36)

                Image(systemName: champion.title.systemImage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString(champion.title.localizationKey, comment: ""))
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(accent)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .lineLimit(1)

                Text(NSLocalizedString(champion.title.descriptionKey, comment: ""))
                    .font(.labelSmall)
                    .foregroundColor(AppColor.outline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 6) {
                    PlayerTeamBadge(teamColor: player.teamColor, number: player.number, size: 18)

                    Text(player.name)
                        .font(.bodyMedium)
                        .foregroundColor(AppColor.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .layoutPriority(1)

                    Spacer(minLength: 4)

                    Text(stats.joined(separator: "  "))
                        .font(.labelSmall)
                        .foregroundColor(AppColor.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColor.surface)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accent)
                .frame(width: 3)
                .padding(.vertical, 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func stat(_ value: Int, _ icon: String) -> String? {
        value > 0 ? "\(icon)\(value)" : nil
    }
}
