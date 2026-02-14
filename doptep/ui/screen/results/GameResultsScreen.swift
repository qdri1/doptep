//
//  GameResultsScreen.swift
//  doptep
//

import SwiftUI
import SwiftData

struct GameResultsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GameResultsViewModel

    @State private var showClearResultsConfirmation = false
    @State private var playerResultUiModel: PlayerResultUiModel?
    @State private var snackbarMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack(spacing: 12) {
                Button {
                    viewModel.action(.onBackClicked)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.titleLarge)
                        .foregroundColor(AppColor.onSurface)
                }

                Text(NSLocalizedString("function_all_results", comment: ""))
                    .font(.bodyMedium)

                Spacer()

                Button {
                    viewModel.action(.onClearResultsClicked)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.titleLarge)
                        .foregroundColor(AppColor.onSurface)
                }
            }
            .padding(16)
            .background(AppColor.surface)

            // Content
            ScrollView {
                VStack(spacing: 16) {
                    // Teams Results Block (only show if more than 2 teams)
                    if viewModel.uiState.teamUiModelList.count > 2 {
                        TeamsResultsBlock(teamUiModelList: viewModel.uiState.teamUiModelList)
                    }

                    // Players Results Block
                    if !viewModel.uiState.playerUiModelList.isEmpty {
                        PlayersResultsBlock(
                            playerUiModelList: viewModel.uiState.playerUiModelList,
                            uiLimited: viewModel.uiState.uiLimited,
                            onPlayerResultClicked: { playerResult in
                                playerResultUiModel = playerResult
                            }
                        )
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .background(AppColor.background)
        .navigationBarHidden(true)
        .onChange(of: viewModel.effect) { _, effect in
            guard let effect = effect else { return }
            handleEffect(effect)
            viewModel.clearEffect()
        }
        .sheet(item: $playerResultUiModel) { playerResult in
            GameResultPlayerResultSheet(
                playerResultUiModel: playerResult,
                onSaveClicked: { resultUiModel, value in
                    viewModel.action(.onSavePlayerResultClicked(
                        playerResultUiModel: resultUiModel,
                        playerResultValue: value
                    ))
                    playerResultUiModel = nil
                },
                onDismissed: {
                    playerResultUiModel = nil
                }
            )
            .presentationDetents([.medium])
        }
        .confirmationDialog(
            NSLocalizedString("clear_all_results_title", comment: ""),
            isPresented: $showClearResultsConfirmation,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("yes", comment: ""), role: .destructive) {
                viewModel.action(.onClearResultsConfirmationClicked)
            }
            Button(NSLocalizedString("no", comment: ""), role: .cancel) {}
        }
        .snackbar(message: $snackbarMessage)
    }

    private func handleEffect(_ effect: GameResultsEffect) {
        switch effect {
        case .closeScreen:
            dismiss()

        case .showClearResultsConfirmationBottomSheet:
            showClearResultsConfirmation = true

        case .showPlayerResultBottomSheet(let playerResult):
            playerResultUiModel = playerResult

        case .showSnackbar(let message):
            snackbarMessage = message
        }
    }
}

// MARK: - Teams Results Block

struct TeamsResultsBlock: View {
    let teamUiModelList: [TeamUiModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("teams_leaderboard", comment: ""))
                .font(.titleMedium)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                // Header Row
                HStack(spacing: 0) {
                    Text("#")
                        .frame(width: 30, alignment: .center)
                    Text(NSLocalizedString("team", comment: ""))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(NSLocalizedString("games_short", comment: ""))
                        .frame(width: 35, alignment: .center)
                    Text(NSLocalizedString("wins_short", comment: ""))
                        .frame(width: 35, alignment: .center)
                    Text(NSLocalizedString("draws_short", comment: ""))
                        .frame(width: 35, alignment: .center)
                    Text(NSLocalizedString("loses_short", comment: ""))
                        .frame(width: 35, alignment: .center)
                    Text(NSLocalizedString("goals_short", comment: ""))
                        .frame(width: 50, alignment: .center)
                    Text(NSLocalizedString("points_short", comment: ""))
                        .frame(width: 35, alignment: .center)
                }
                .font(.labelMedium)
                .foregroundColor(AppColor.onSurfaceVariant)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)

                Divider()

                // Team Rows
                ForEach(Array(teamUiModelList.enumerated()), id: \.element.id) { index, team in
                    HStack(spacing: 0) {
                        Text("\(index + 1)")
                            .frame(width: 30, alignment: .center)

                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: team.color.rawValue))
                                .frame(width: 12, height: 12)
                            Text(team.name)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text("\(team.games)")
                            .frame(width: 35, alignment: .center)
                        Text("\(team.wins)")
                            .frame(width: 35, alignment: .center)
                        Text("\(team.draws)")
                            .frame(width: 35, alignment: .center)
                        Text("\(team.loses)")
                            .frame(width: 35, alignment: .center)
                        Text("\(team.goals)-\(team.conceded)")
                            .frame(width: 50, alignment: .center)
                        Text("\(team.points)")
                            .frame(width: 35, alignment: .center)
                            .font(.bodyLarge)
                    }
                    .font(.bodyMedium)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)

                    if index < teamUiModelList.count - 1 {
                        Divider()
                    }
                }
            }
            .background(AppColor.surfaceVariant)
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Players Results Block

struct PlayersResultsBlock: View {
    let playerUiModelList: [PlayerUiModel]
    let uiLimited: Bool
    let onPlayerResultClicked: (PlayerResultUiModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("players_leaderboard", comment: ""))
                .font(.titleMedium)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                // Header Row
                HStack(spacing: 0) {
                    Text("#")
                        .frame(width: 30, alignment: .center)
                    Text(NSLocalizedString("player", comment: ""))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(NSLocalizedString("goals_icon", comment: ""))
                        .frame(width: 35, alignment: .center)
                    Text(NSLocalizedString("assists_icon", comment: ""))
                        .frame(width: 35, alignment: .center)
                    Text(NSLocalizedString("saves_icon", comment: ""))
                        .frame(width: 35, alignment: .center)
                    Text(NSLocalizedString("dribbles_icon", comment: ""))
                        .frame(width: 35, alignment: .center)
                    Text(NSLocalizedString("shots_icon", comment: ""))
                        .frame(width: 35, alignment: .center)
                    Text(NSLocalizedString("passes_icon", comment: ""))
                        .frame(width: 35, alignment: .center)
                }
                .font(.labelMedium)
                .foregroundColor(AppColor.onSurfaceVariant)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)

                Divider()

                // Player Rows
                ForEach(Array(playerUiModelList.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: 0) {
                        Text("\(index + 1)")
                            .frame(width: 30, alignment: .center)

                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: player.teamColor.rawValue))
                                .frame(width: 12, height: 12)
                            Text(player.name)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        PlayerStatButton(
                            value: player.goals,
                            uiLimited: uiLimited
                        ) {
                            onPlayerResultClicked(PlayerResultUiModel(
                                playerUiModel: player,
                                option: .goal
                            ))
                        }
                        .frame(width: 35)

                        PlayerStatButton(
                            value: player.assists,
                            uiLimited: uiLimited
                        ) {
                            onPlayerResultClicked(PlayerResultUiModel(
                                playerUiModel: player,
                                option: .assist
                            ))
                        }
                        .frame(width: 35)

                        PlayerStatButton(
                            value: player.saves,
                            uiLimited: uiLimited
                        ) {
                            onPlayerResultClicked(PlayerResultUiModel(
                                playerUiModel: player,
                                option: .save
                            ))
                        }
                        .frame(width: 35)

                        PlayerStatButton(
                            value: player.dribbles,
                            uiLimited: uiLimited
                        ) {
                            onPlayerResultClicked(PlayerResultUiModel(
                                playerUiModel: player,
                                option: .dribble
                            ))
                        }
                        .frame(width: 35)

                        PlayerStatButton(
                            value: player.shots,
                            uiLimited: uiLimited
                        ) {
                            onPlayerResultClicked(PlayerResultUiModel(
                                playerUiModel: player,
                                option: .shot
                            ))
                        }
                        .frame(width: 35)

                        PlayerStatButton(
                            value: player.passes,
                            uiLimited: uiLimited
                        ) {
                            onPlayerResultClicked(PlayerResultUiModel(
                                playerUiModel: player,
                                option: .pass
                            ))
                        }
                        .frame(width: 35)
                    }
                    .font(.bodyMedium)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)

                    if index < playerUiModelList.count - 1 {
                        Divider()
                    }
                }
            }
            .background(AppColor.surfaceVariant)
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Player Stat Button

struct PlayerStatButton: View {
    let value: Int
    let uiLimited: Bool
    let action: () -> Void

    var body: some View {
        Button {
            if !uiLimited {
                action()
            }
        } label: {
            Text("\(value)")
                .font(.bodyMedium)
                .foregroundColor(uiLimited ? AppColor.onSurfaceVariant : AppColor.onSurface)
        }
        .disabled(uiLimited)
    }
}

// MARK: - Player Result Sheet

struct GameResultPlayerResultSheet: View {
    let playerResultUiModel: PlayerResultUiModel
    let onSaveClicked: (PlayerResultUiModel, Int) -> Void
    let onDismissed: () -> Void

    @State private var value: Int

    init(
        playerResultUiModel: PlayerResultUiModel,
        onSaveClicked: @escaping (PlayerResultUiModel, Int) -> Void,
        onDismissed: @escaping () -> Void
    ) {
        self.playerResultUiModel = playerResultUiModel
        self.onSaveClicked = onSaveClicked
        self.onDismissed = onDismissed

        let initialValue: Int
        switch playerResultUiModel.option {
        case .goal: initialValue = playerResultUiModel.playerUiModel.goals
        case .assist: initialValue = playerResultUiModel.playerUiModel.assists
        case .save: initialValue = playerResultUiModel.playerUiModel.saves
        case .dribble: initialValue = playerResultUiModel.playerUiModel.dribbles
        case .shot: initialValue = playerResultUiModel.playerUiModel.shots
        case .pass: initialValue = playerResultUiModel.playerUiModel.passes
        }
        _value = State(initialValue: initialValue)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Player Info
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: playerResultUiModel.playerUiModel.teamColor.rawValue))
                        .frame(width: 24, height: 24)

                    Text(playerResultUiModel.playerUiModel.name)
                        .font(.titleMedium)

                    Spacer()
                }
                .padding(.horizontal)

                // Stat Type
                Text(NSLocalizedString(playerResultUiModel.option.localizationKey, comment: ""))
                    .font(.titleMedium)
                    .foregroundColor(AppColor.onSurfaceVariant)

                // Value Stepper
                HStack(spacing: 32) {
                    Button {
                        if value > 0 {
                            value -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.custom("Montserrat-SemiBold", size: 44))
                            .foregroundColor(AppColor.error)
                    }

                    Text("\(value)")
                        .font(.custom("Montserrat-Bold", size: 48))
                        .frame(minWidth: 80)

                    Button {
                        value += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.custom("Montserrat-SemiBold", size: 44))
                            .foregroundColor(AppColor.primary)
                    }
                }

                Spacer()

                // Save Button
                Button {
                    onSaveClicked(playerResultUiModel, value)
                } label: {
                    Text(NSLocalizedString("save", comment: ""))
                        .font(.titleMedium)
                        .foregroundColor(AppColor.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColor.tertiary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            .navigationTitle(NSLocalizedString("edit_result", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) {
                        onDismissed()
                    }
                }
            }
        }
    }
}

extension PlayerResultUiModel: Identifiable {
    var id: UUID { playerUiModel.id }
}
