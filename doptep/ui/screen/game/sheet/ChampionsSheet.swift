//
//  ChampionsSheet.swift
//  doptep
//

import SwiftUI

struct ChampionsSheet: View {
    let champions: ChampionsUiModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    ChampionTeamHeroCard(team: champions.teamUiModel)

                    ForEach(champions.players) { champion in
                        ChampionPlayerRow(champion: champion)
                    }

                    Spacer()
                        .frame(height: 16)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
            .background(AppColor.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("champions", comment: ""))
                        .font(.bodyMedium)
                        .foregroundColor(AppColor.onSurface)
                }
            }
        }
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
            String(format: NSLocalizedString("champions_goals", comment: ""), team.goals, team.conceded),
            String(format: NSLocalizedString("champions_record", comment: ""), team.wins, team.draws, team.loses)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 28, height: 28)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#FFD166"))
                }

                Text(NSLocalizedString("champions_first_place", comment: ""))
                    .font(.labelLarge)
                    .foregroundColor(Color(hex: "#FFD166"))
                    .textCase(.uppercase)
                    .tracking(0.4)

                Spacer()
            }
            .padding(.horizontal, 16)

            HStack(spacing: 10) {
                PlayerTeamBadge(teamColor: team.color, number: nil, size: 24)

                Text(teamName)
                    .font(.titleLarge)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(stats, id: \.self) { statText in
                        Text(statText)
                            .font(.labelSmall)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.white.opacity(0.16)))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
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
                    endRadius: 170
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color(hex: "#E0A800").opacity(0.4), radius: 14, x: 0, y: 6)
        .overlay(alignment: .topTrailing) {
            HeroBadge(
                text: "TOP 1",
                gradientColors: [Color(hex: "#A86F00"), Color(hex: "#F2B705")],
                shadowColor: Color(hex: "#E0A800").opacity(0.5)
            )
            .padding(.top, 32)
            .padding(.trailing, 20)
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
                    .minimumScaleFactor(0.7)

                HStack(spacing: 6) {
                    PlayerTeamBadge(teamColor: player.teamColor, number: player.number, size: 18)

                    Text(player.name)
                        .font(.bodyMedium)
                        .foregroundColor(AppColor.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
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
