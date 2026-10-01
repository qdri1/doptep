//
//  BestPlayersSheet.swift
//  doptep
//
//  Created by K.Alimtayev on 30.07.2026.
//


import SwiftUI
import RevenueCat
import RevenueCatUI

// Лучшие игроки

struct BestPlayersSheet: View {
    let bestPlayers: [BestPlayerUiModel]

    var body: some View {
        NavigationView {
            List {
                ForEach(bestPlayers, id: \.option) { bestPlayer in
                    if bestPlayer.option == .bestPlayer {
                        BestPlayerHeroCard(bestPlayer: bestPlayer)
                            .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    } else {
                        VStack(alignment: .leading) {
                            Text(NSLocalizedString(bestPlayer.option.localizationKey, comment: ""))
                                .font(.labelSmall)
                                .foregroundColor(AppColor.outline)

                            HStack {
                                PlayerTeamBadge(teamColor: bestPlayer.playerUiModel.teamColor, number: bestPlayer.playerUiModel.number)

                                Text(bestPlayer.playerUiModel.name)
                                    .font(.bodySmall)
                                    .foregroundColor(AppColor.onSurface)

                                Spacer()

                                switch bestPlayer.option {
                                case .bestPlayer:
                                    EmptyView()
                                case .goals:
                                    Text("\(bestPlayer.playerUiModel.goals) \(NSLocalizedString("text_goal", comment: ""))")
                                        .font(.bodySmall)
                                        .foregroundColor(AppColor.onSurface)
                                case .assists:
                                    Text("\(bestPlayer.playerUiModel.assists) \(NSLocalizedString("text_assist", comment: ""))")
                                        .font(.bodySmall)
                                        .foregroundColor(AppColor.onSurface)
                                case .saves:
                                    Text("\(bestPlayer.playerUiModel.saves) \(NSLocalizedString("text_save", comment: ""))")
                                        .font(.bodySmall)
                                        .foregroundColor(AppColor.onSurface)
                                case .tackles:
                                    Text("\(bestPlayer.playerUiModel.tackles) \(NSLocalizedString("text_tackle", comment: ""))")
                                        .font(.bodySmall)
                                        .foregroundColor(AppColor.onSurface)
                                case .dribbles:
                                    Text("\(bestPlayer.playerUiModel.dribbles) \(NSLocalizedString("text_dribble", comment: ""))")
                                        .font(.bodySmall)
                                        .foregroundColor(AppColor.onSurface)
                                case .passes:
                                    Text("\(bestPlayer.playerUiModel.passes) \(NSLocalizedString("text_pass", comment: ""))")
                                        .font(.bodySmall)
                                        .foregroundColor(AppColor.onSurface)
                                case .shots:
                                    Text("\(bestPlayer.playerUiModel.shots) \(NSLocalizedString("text_shot", comment: ""))")
                                        .font(.bodySmall)
                                        .foregroundColor(AppColor.onSurface)
                                case .aggressivePlayer:
                                    let result = [
                                        stat(bestPlayer.playerUiModel.yellowCards, "text_yellow_card"),
                                        stat(bestPlayer.playerUiModel.redCards, "text_red_card")
                                    ]
                                    .compactMap { $0 }
                                    .joined(separator: ", ")

                                    Text(result)
                                        .font(.bodySmall)
                                        .foregroundColor(AppColor.onSurface)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("best_players", comment: ""))
                        .font(.bodyMedium)
                        .foregroundColor(AppColor.onSurface)
                }
            }
        }
    }

    func stat(_ value: Int, _ key: String) -> String? {
        value > 0 ? "\(value) \(NSLocalizedString(key, comment: ""))" : nil
    }
}

// MARK: - Best Player Hero Card

private struct BestPlayerHeroCard: View {
    let bestPlayer: BestPlayerUiModel

    private var stats: [String] {
        [
            stat(bestPlayer.playerUiModel.goals, "text_goal"),
            stat(bestPlayer.playerUiModel.assists, "text_assist"),
            stat(bestPlayer.playerUiModel.saves, "text_save"),
            stat(bestPlayer.playerUiModel.tackles, "text_tackle"),
            stat(bestPlayer.playerUiModel.dribbles, "text_dribble"),
            stat(bestPlayer.playerUiModel.passes, "text_pass"),
            stat(bestPlayer.playerUiModel.shots, "text_shot"),
            stat(bestPlayer.playerUiModel.yellowCards, "text_yellow_card"),
            stat(bestPlayer.playerUiModel.redCards, "text_red_card")
        ]
        .compactMap { $0 }
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

                Text(NSLocalizedString(bestPlayer.option.localizationKey, comment: ""))
                    .font(.labelLarge)
                    .foregroundColor(Color(hex: "#FFD166"))
                    .textCase(.uppercase)
                    .tracking(0.4)

                Spacer()
            }

            HStack(spacing: 10) {
                PlayerTeamBadge(teamColor: bestPlayer.playerUiModel.teamColor, number: bestPlayer.playerUiModel.number, size: 24)

                Text(bestPlayer.playerUiModel.name)
                    .font(.titleLarge)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()
            }

            if !stats.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(stats, id: \.self) { statText in
                        Text(statText)
                            .font(.labelSmall)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.16))
                            )
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#3D0B02"), Color(hex: "#B3200B"), Color(hex: "#FF7A1A")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [Color(hex: "#FFD166").opacity(0.55), Color.clear],
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
        .shadow(color: Color(hex: "#FF4E00").opacity(0.4), radius: 14, x: 0, y: 6)
        .overlay(alignment: .topTrailing) {
            // Positioned independently of the row layout above, so it
            // floats over the card rather than pushing the trophy/name
            // rows around — sits roughly on the seam between them.
            mvpBadge
                .padding(.top, 32)
                .padding(.trailing, 20)
        }
    }

    private var mvpBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .font(.system(size: 16, weight: .bold))

            Text("MVP")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .tracking(0.5)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FF3D00"), Color(hex: "#FF9F1C")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.5), lineWidth: 0.75)
        )
        .shadow(color: Color(hex: "#FF3D00").opacity(0.5), radius: 6, x: 0, y: 2)
        .rotationEffect(.degrees(-4))
    }

    private func stat(_ value: Int, _ key: String) -> String? {
        value > 0 ? "\(value) \(NSLocalizedString(key, comment: ""))" : nil
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
