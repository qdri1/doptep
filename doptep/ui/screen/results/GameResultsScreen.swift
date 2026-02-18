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
    @State private var showPlayerResultSheet = false
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
                                viewModel.action(GameResultsAction.onPlayerResultClicked(playerResultUiModel: playerResult))
                            }
                        )
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .background(AppColor.background)
        .navigationBarHidden(true)
        .onChange(of: viewModel.effect) { _, effect in
            guard let effect = effect else { return }
            handleEffect(effect)
            viewModel.clearEffect()
        }
        .sheet(isPresented: $showPlayerResultSheet) {
            if let playerResult = playerResultUiModel {
                GameResultPlayerResultSheet(
                    playerResultUiModel: playerResult,
                    onSaveClicked: { resultUiModel, value in
                        viewModel.action(.onSavePlayerResultClicked(
                            playerResultUiModel: resultUiModel,
                            playerResultValue: value
                        ))
                        showPlayerResultSheet = false
                    },
                    onDismissed: {
                        showPlayerResultSheet = false
                    }
                )
                .presentationDetents([.medium])
            }
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
            showPlayerResultSheet = true

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

            HStack(alignment: .top, spacing: 8) {
                // Place
                resultsStatColumn(
                    header: "#",
                    values: teamUiModelList.enumerated().map { ("\($0.offset + 1)", nil) }
                )

                // Team name (flexible)
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("team", comment: ""))
                        .font(.labelSmall)
                        .foregroundColor(AppColor.outline)

                    ForEach(teamUiModelList, id: \.id) { team in
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(team.color.color)
                                .frame(width: 12, height: 12)

                            ZStack(alignment: .center) {
                                Text(team.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.labelSmall)
                                    .foregroundColor(.clear)
                                    .lineLimit(1)

                                Text(team.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.labelSmall)
                                    .foregroundColor(AppColor.onSurface)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Stats columns
                resultsStatColumn(
                    header: NSLocalizedString("games_short", comment: ""),
                    values: teamUiModelList.map { ("\($0.games)", nil) }
                )
                resultsStatColumn(
                    header: NSLocalizedString("wins_short", comment: ""),
                    values: teamUiModelList.map { ("\($0.wins)", nil) }
                )
                resultsStatColumn(
                    header: NSLocalizedString("draws_short", comment: ""),
                    values: teamUiModelList.map { ("\($0.draws)", nil) }
                )
                resultsStatColumn(
                    header: NSLocalizedString("loses_short", comment: ""),
                    values: teamUiModelList.map { ("\($0.loses)", nil) }
                )
                resultsStatColumn(
                    header: NSLocalizedString("goals_short", comment: ""),
                    values: teamUiModelList.map { ("\($0.goals)-\($0.conceded)", nil) }
                )
                resultsStatColumn(
                    header: NSLocalizedString("goal_difference_short", comment: ""),
                    values: teamUiModelList.map {
                        ($0.goalsDifference > 0 ? "+\($0.goalsDifference)" : "\($0.goalsDifference)", nil)
                    }
                )
                resultsStatColumn(
                    header: NSLocalizedString("points_short", comment: ""),
                    values: teamUiModelList.map { ("\($0.points)", Font.labelLarge) }
                )
            }
            .padding(12)
            .background(AppColor.surface)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Players Results Block

struct PlayersResultsBlock: View {
    let playerUiModelList: [PlayerUiModel]
    let uiLimited: Bool
    let onPlayerResultClicked: (PlayerResultUiModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack(alignment: .top, spacing: 12) {
                // Place
                resultsStatColumn(
                    header: "#",
                    values: playerUiModelList.enumerated().map { ("\($0.offset + 1)", nil) }
                )

                // Player name (flexible)
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("player", comment: ""))
                        .font(.labelSmall)
                        .foregroundColor(AppColor.outline)

                    ForEach(playerUiModelList, id: \.id) { player in
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(player.teamColor.color)
                                .frame(width: 12, height: 12)

                            ZStack(alignment: .center) {
                                Text(player.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.labelSmall)
                                    .foregroundColor(.clear)
                                    .lineLimit(1)

                                Text(player.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.labelSmall)
                                    .foregroundColor(AppColor.onSurface)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Stat columns (tappable)
                resultsPlayerStatColumn(
                    header: NSLocalizedString("goals_icon", comment: ""),
                    players: playerUiModelList,
                    valuePath: \.goals,
                    option: .goal,
                    uiLimited: uiLimited,
                    onPlayerResultClicked: onPlayerResultClicked
                )
                resultsPlayerStatColumn(
                    header: NSLocalizedString("assists_icon", comment: ""),
                    players: playerUiModelList,
                    valuePath: \.assists,
                    option: .assist,
                    uiLimited: uiLimited,
                    onPlayerResultClicked: onPlayerResultClicked
                )
                resultsPlayerStatColumn(
                    header: NSLocalizedString("saves_icon", comment: ""),
                    players: playerUiModelList,
                    valuePath: \.saves,
                    option: .save,
                    uiLimited: uiLimited,
                    onPlayerResultClicked: onPlayerResultClicked
                )
                resultsPlayerStatColumn(
                    header: NSLocalizedString("dribbles_icon", comment: ""),
                    players: playerUiModelList,
                    valuePath: \.dribbles,
                    option: .dribble,
                    uiLimited: uiLimited,
                    onPlayerResultClicked: onPlayerResultClicked
                )
                resultsPlayerStatColumn(
                    header: NSLocalizedString("shots_icon", comment: ""),
                    players: playerUiModelList,
                    valuePath: \.shots,
                    option: .shot,
                    uiLimited: uiLimited,
                    onPlayerResultClicked: onPlayerResultClicked
                )
                resultsPlayerStatColumn(
                    header: NSLocalizedString("passes_icon", comment: ""),
                    players: playerUiModelList,
                    valuePath: \.passes,
                    option: .pass,
                    uiLimited: uiLimited,
                    onPlayerResultClicked: onPlayerResultClicked
                )
            }
            .padding(12)
            .background(AppColor.surface)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Helper Functions

private func resultsStatColumn(header: String, values: [(String, Font?)]) -> some View {
    VStack(spacing: 8) {
        Text(header)
            .font(.labelSmall)
            .foregroundColor(AppColor.outline)

        ForEach(Array(values.enumerated()), id: \.offset) { _, item in
            Text(item.0)
                .font(item.1 ?? .labelSmall)
                .foregroundColor(AppColor.onSurface)
        }
    }
}

private func resultsPlayerStatColumn(
    header: String,
    players: [PlayerUiModel],
    valuePath: KeyPath<PlayerUiModel, Int>,
    option: TeamOption,
    uiLimited: Bool,
    onPlayerResultClicked: @escaping (PlayerResultUiModel) -> Void
) -> some View {
    VStack(spacing: 8) {
        Text(header)
            .font(.labelSmall)
            .foregroundColor(AppColor.outline)

        let font = if option == .goal {
            Font.labelLarge
        } else {
            Font.labelSmall
        }

        ForEach(players, id: \.id) { player in
            Text("\(player[keyPath: valuePath])")
                .font(font)
                .foregroundColor(AppColor.onSurface)
                .onTapGesture {
                    onPlayerResultClicked(PlayerResultUiModel(
                        playerUiModel: player,
                        option: option
                    ))
                }
        }
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
                        .background(AppColor.primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            .background(AppColor.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("edit_result", comment: ""))
                        .font(.bodyMedium)
                        .foregroundColor(AppColor.onSurface)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onDismissed()
                    } label: {
                        Text(NSLocalizedString("cancel", comment: ""))
                            .font(.bodySmall)
                            .foregroundColor(AppColor.outline)
                    }
                }
            }
        }
    }
}

extension PlayerResultUiModel: Identifiable {
    var id: UUID { playerUiModel.id }
}
