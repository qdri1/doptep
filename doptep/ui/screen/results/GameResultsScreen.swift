//
//  GameResultsScreen.swift
//  doptep
//

import SwiftUI
import SwiftData

struct GameResultsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GameResultsViewModel

    @State private var showPlayerResultSheet = false
    @State private var playerResultUiModel: PlayerResultUiModel?
    @State private var showTeamResultSheet = false
    @State private var teamResultUiModel: TeamUiModel?
    @State private var snackbarMessage: String?
    @State private var showBestPlayersSheet = false
    @State private var bestPlayersForSheet: [BestPlayerUiModel] = []
    @State private var showClearAllGamesConfirmation = false
    @State private var showRemovePlayerConfirmation = false
    @State private var playerToRemove: PlayerUiModel?
    @State private var hiddenStatOptions: Set<TeamOption> = []

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button {
                    viewModel.action(.onBackClicked)
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.titleLarge)
                        .foregroundColor(AppColor.onSurface)
                }

                Text(NSLocalizedString("function_all_results", comment: ""))
                    .font(.titleMedium)
                    .foregroundColor(AppColor.onSurface)
                    .frame(maxWidth: .infinity)
                
                Spacer()
                    .frame(width: 24)
            }
            .padding()
            .background(AppColor.surface)

            // Content
            ScrollView {
                VStack(spacing: 16) {
                    // Teams Results Block (only show if more than 2 teams)
                    if viewModel.uiState.teamUiModelList.count > 2 {
                        TeamsResultsBlock(
                            teamUiModelList: viewModel.uiState.teamUiModelList,
                            onTeamResultClicked: { team in
                                viewModel.action(GameResultsAction.onTeamResultClicked(teamUiModel: team))
                            }
                        )
                    }

                    // Players Results Block
                    if !viewModel.uiState.playerUiModelList.isEmpty {
                        PlayersResultsBlock(
                            playerUiModelList: viewModel.uiState.playerUiModelList,
                            deletedPlayerIds: viewModel.uiState.deletedPlayerIds,
                            uiLimited: viewModel.uiState.uiLimited,
                            hiddenOptions: hiddenStatOptions,
                            onPlayerResultClicked: { playerResult in
                                viewModel.action(GameResultsAction.onPlayerResultClicked(playerResultUiModel: playerResult))
                            },
                            onRemovePlayerClicked: { player in
                                playerToRemove = player
                                showRemovePlayerConfirmation = true
                            },
                            onActivateClicked: {}
                        )
                    }
                    
                    functionsSection
                }
                .padding(.vertical, 16)
            }
        }
        .background(AppColor.background)
        .navigationBarHidden(true)
        .enableSwipeBack()
        .onAppear {
            hiddenStatOptions = HiddenColumnsStorage.load(gameId: viewModel.gameId)
        }
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
        .sheet(isPresented: $showTeamResultSheet) {
            if let teamResult = teamResultUiModel {
                GameTeamResultSheet(
                    teamUiModel: teamResult,
                    onSaveClicked: { team, value in
                        viewModel.action(.onSaveTeamResultClicked(
                            teamUiModel: team,
                            pointsValue: value
                        ))
                        showTeamResultSheet = false
                    },
                    onDismissed: {
                        showTeamResultSheet = false
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .confirmationDialog(
            NSLocalizedString("clear_all_results_title", comment: ""),
            isPresented: $showClearAllGamesConfirmation,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("yes", comment: ""), role: .destructive) {
                viewModel.action(.onClearAllGamesResultsConfirmationClicked)
            }
            Button(NSLocalizedString("no", comment: ""), role: .cancel) {}
        }
        .sheet(isPresented: $showBestPlayersSheet) {
            BestPlayersSheet(bestPlayers: bestPlayersForSheet)
                .presentationDetents([.large])
        }
        .confirmationDialog(
            String(format: NSLocalizedString("remove_player_confirm_text", comment: ""), playerToRemove?.name ?? ""),
            isPresented: $showRemovePlayerConfirmation,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("yes", comment: ""), role: .destructive) {
                if let player = playerToRemove {
                    viewModel.action(.onRemovePlayerClicked(playerId: player.id))
                }
            }
            Button(NSLocalizedString("no", comment: ""), role: .cancel) {}
        }
        .snackbar(message: $snackbarMessage)
    }

    private func handleEffect(_ effect: GameResultsEffect) {
        switch effect {
        case .closeScreen:
            dismiss()

        case .showPlayerResultBottomSheet(let playerResult):
            playerResultUiModel = playerResult
            showPlayerResultSheet = true

        case .showTeamResultBottomSheet(let teamResult):
            teamResultUiModel = teamResult
            showTeamResultSheet = true

        case .showSnackbar(let message):
            snackbarMessage = message

        case .showBestPlayersBottomSheet(let bestPlayers):
            bestPlayersForSheet = bestPlayers
            showBestPlayersSheet = true

        case .showClearAllGamesResultsConfirmationBottomSheet:
            showClearAllGamesConfirmation = true
        }
    }

    private var functionsSection: some View {
        let uiLimited = viewModel.uiState.uiLimited
        return VStack(alignment: .leading, spacing: 8) {
            let isLocked = uiLimited
            Button {
                if isLocked {
                    viewModel.action(.onActivateClicked)
                } else {
                    viewModel.action(.onBestPlayersAllGamesClicked)
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "hand.thumbsup.fill")
                        .frame(width: 24, height: 24)
                        .font(.titleLarge)
                    Text(NSLocalizedString("function_best_players_all_games", comment: ""))
                        .font(.labelMedium)
                    Spacer()
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(AppColor.outline)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(AppColor.surface)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .foregroundColor(isLocked ? AppColor.outline : AppColor.onSurface)

            Button {
                viewModel.action(.onClearAllGamesResultsClicked)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 24, height: 24)
                        .font(.titleLarge)
                    Text(NSLocalizedString("function_clear_all_results", comment: ""))
                        .font(.labelMedium)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(AppColor.surface)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .foregroundColor(AppColor.onSurface)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Teams Results Block

struct TeamsResultsBlock: View {
    let teamUiModelList: [TeamUiModel]
    let onTeamResultClicked: (TeamUiModel) -> Void

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
                                .frame(width: 16, height: 16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(team.color == .white ? AppColor.surfaceVariant : Color.clear, lineWidth: 1)
                                )

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
                resultsTeamPointsColumn(
                    teams: teamUiModelList,
                    onTeamResultClicked: onTeamResultClicked
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
    let deletedPlayerIds: Set<UUID>
    let uiLimited: Bool
    let hiddenOptions: Set<TeamOption>
    let onPlayerResultClicked: (PlayerResultUiModel) -> Void
    let onRemovePlayerClicked: (PlayerUiModel) -> Void
    let onActivateClicked: () -> Void

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
                            PlayerTeamBadge(teamColor: player.teamColor, number: player.number)

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

                            if deletedPlayerIds.contains(player.id) {
                                Button {
                                    onRemovePlayerClicked(player)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.labelSmall)
                                        .foregroundColor(AppColor.outline)
                                }
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
                if !hiddenOptions.contains(.save) {
                    resultsPlayerStatColumn(
                        header: NSLocalizedString("saves_icon", comment: ""),
                        players: playerUiModelList,
                        valuePath: \.saves,
                        option: .save,
                        uiLimited: uiLimited,
                        onPlayerResultClicked: onPlayerResultClicked
                    )
                }
                if !hiddenOptions.contains(.dribble) {
                    resultsPlayerStatColumn(
                        header: NSLocalizedString("dribbles_icon", comment: ""),
                        players: playerUiModelList,
                        valuePath: \.dribbles,
                        option: .dribble,
                        uiLimited: uiLimited,
                        onPlayerResultClicked: onPlayerResultClicked
                    )
                }
                if !hiddenOptions.contains(.shot) {
                    resultsPlayerStatColumn(
                        header: NSLocalizedString("shots_icon", comment: ""),
                        players: playerUiModelList,
                        valuePath: \.shots,
                        option: .shot,
                        uiLimited: uiLimited,
                        onPlayerResultClicked: onPlayerResultClicked
                    )
                }
                if !hiddenOptions.contains(.pass) {
                    resultsPlayerStatColumn(
                        header: NSLocalizedString("passes_icon", comment: ""),
                        players: playerUiModelList,
                        valuePath: \.passes,
                        option: .pass,
                        uiLimited: uiLimited,
                        onPlayerResultClicked: onPlayerResultClicked
                    )
                }
                if !hiddenOptions.contains(.yellowCard) {
                    resultsPlayerStatColumn(
                        header: NSLocalizedString("player_result_yellow_card", comment: ""),
                        players: playerUiModelList,
                        valuePath: \.yellowCards,
                        option: .yellowCard,
                        uiLimited: uiLimited,
                        onPlayerResultClicked: onPlayerResultClicked
                    )
                }
                if !hiddenOptions.contains(.redCard) {
                    resultsPlayerStatColumn(
                        header: NSLocalizedString("player_result_red_card", comment: ""),
                        players: playerUiModelList,
                        valuePath: \.redCards,
                        option: .redCard,
                        uiLimited: uiLimited,
                        onPlayerResultClicked: onPlayerResultClicked
                    )
                }
            }
            .padding(12)
            .background(AppColor.surface)
            .cornerRadius(12)
            .overlay {
                if uiLimited {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColor.surface)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.largeTitle)
                            .foregroundColor(AppColor.outline)
                        
                        Text(NSLocalizedString("player_result_limited_text", comment: ""))
                            .font(.bodySmall)
                            .foregroundColor(AppColor.outline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .onTapGesture {
                        onActivateClicked()
                    }
                }
            }
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

private func resultsTeamPointsColumn(
    teams: [TeamUiModel],
    onTeamResultClicked: @escaping (TeamUiModel) -> Void
) -> some View {
    VStack(spacing: 8) {
        Text(NSLocalizedString("points_short", comment: ""))
            .font(.labelSmall)
            .foregroundColor(AppColor.outline)

        ForEach(teams, id: \.id) { team in
            Text("\(team.points)")
                .font(.labelLarge)
                .foregroundColor(AppColor.onSurface)
                .onTapGesture {
                    onTeamResultClicked(team)
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
        case .yellowCard: initialValue = playerResultUiModel.playerUiModel.yellowCards
        case .redCard: initialValue = playerResultUiModel.playerUiModel.redCards
        }
        _value = State(initialValue: initialValue)
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Player Info
                    HStack(spacing: 12) {
                        PlayerTeamBadge(teamColor: playerResultUiModel.playerUiModel.teamColor, number: playerResultUiModel.playerUiModel.number, size: 24)

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

                    Text(NSLocalizedString("result_correction_text", comment: ""))
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.bodySmall)
                        .foregroundColor(AppColor.error)
                        .padding(.horizontal)
                }
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
            .background(AppColor.surface)
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

// MARK: - Team Result Sheet

struct GameTeamResultSheet: View {
    let teamUiModel: TeamUiModel
    let onSaveClicked: (TeamUiModel, Int) -> Void
    let onDismissed: () -> Void

    @State private var value: Int

    init(
        teamUiModel: TeamUiModel,
        onSaveClicked: @escaping (TeamUiModel, Int) -> Void,
        onDismissed: @escaping () -> Void
    ) {
        self.teamUiModel = teamUiModel
        self.onSaveClicked = onSaveClicked
        self.onDismissed = onDismissed
        _value = State(initialValue: teamUiModel.points)
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Team Info
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(teamUiModel.color.color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(teamUiModel.color == .white ? AppColor.surfaceVariant : Color.clear, lineWidth: 1)
                            )

                        Text(teamUiModel.name)
                            .font(.titleMedium)

                        Spacer()
                    }
                    .padding(.horizontal)

                    // Stat Type
                    Text(NSLocalizedString("points_short", comment: ""))
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

                    // Save Button
                    Button {
                        onSaveClicked(teamUiModel, value)
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

                    Text(NSLocalizedString("result_correction_text", comment: ""))
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.bodySmall)
                        .foregroundColor(AppColor.error)
                        .padding(.horizontal)
                }
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
            .background(AppColor.surface)
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
