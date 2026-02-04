//
//  GameScreen.swift
//  doptep
//

import SwiftUI

struct GameScreen: View {
    @StateObject private var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    init(viewModel: GameViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    @State private var showOptionPlayersSheet = false
    @State private var showPlayerResultSheet = false
    @State private var showLiveGameResultSheet = false
    @State private var showStayTeamSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showClearResultsConfirmation = false
    @State private var showFinishGameConfirmation = false
    @State private var showGoBackConfirmation = false
    @State private var showGameInfoSheet = false
    @State private var showBestPlayersSheet = false
    @State private var showAddGameScreen = false
    @State private var updateGameId: UUID?
    @State private var showGameResultsScreen = false
    @State private var gameResultsGameId: UUID?
    @State private var showLeftTeamOptionsDropdown = false
    @State private var showRightTeamOptionsDropdown = false
    @State private var showLeftTeamChangeDropdown = false
    @State private var showRightTeamChangeDropdown = false

    @State private var currentOptionPlayers: OptionPlayersUiModel?
    @State private var currentPlayerResult: PlayerResultUiModel?
    @State private var currentLiveGameResult: LiveGameResultUiModel?
    @State private var currentBestPlayers: [BestPlayerUiModel] = []

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    if let liveGame = viewModel.uiState.liveGameUiModel {
                        scoreboardSection(liveGame: liveGame)
                    }
                    timerSection
                    startFinishButton
                    soundsSection
                    teamsLeaderboard
                    playersLeaderboard
                    functionsSection
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .snackbar(message: $viewModel.snackbarMessage)
        .onChange(of: viewModel.effect) { _, effect in
            handleEffect(effect)
        }
        .onChange(of: viewModel.uiState.showLeftTeamOptionsDropdown) { _, newValue in
            showLeftTeamOptionsDropdown = newValue
        }
        .onChange(of: viewModel.uiState.showRightTeamOptionsDropdown) { _, newValue in
            showRightTeamOptionsDropdown = newValue
        }
        .onChange(of: viewModel.uiState.showLeftTeamChangeDropdown) { _, newValue in
            showLeftTeamChangeDropdown = newValue
        }
        .onChange(of: viewModel.uiState.showRightTeamChangeDropdown) { _, newValue in
            showRightTeamChangeDropdown = newValue
        }
        .onDisappear {
            viewModel.saveTimerOnExit()
        }
        .sheet(isPresented: $showOptionPlayersSheet) {
            if let optionPlayers = currentOptionPlayers {
                OptionPlayersSheet(
                    optionPlayers: optionPlayers,
                    onPlayerSelected: { player in
                        viewModel.send(.onOptionPlayersSelected(
                            teamId: optionPlayers.teamId,
                            playerUiModel: player,
                            option: optionPlayers.option
                        ))
                        showOptionPlayersSheet = false
                    },
                    onAutoGoalSelected: {
                        viewModel.send(.onOptionPlayersAutoGoalSelected(teamId: optionPlayers.teamId))
                        showOptionPlayersSheet = false
                    },
                    onDismiss: { showOptionPlayersSheet = false }
                )
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showBestPlayersSheet) {
            BestPlayersSheet(bestPlayers: currentBestPlayers)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showGameInfoSheet) {
            GameInfoSheet()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPlayerResultSheet) {
            if let playerResult = currentPlayerResult {
                PlayerResultSheet(
                    playerResult: playerResult,
                    onSave: { option, value in
                        let updatedResult = PlayerResultUiModel(
                            playerUiModel: playerResult.playerUiModel,
                            option: option
                        )
                        viewModel.send(.onSavePlayerResultClicked(
                            playerResultUiModel: updatedResult,
                            playerResultValue: value
                        ))
                        showPlayerResultSheet = false
                    },
                    onDismiss: { showPlayerResultSheet = false }
                )
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showLiveGameResultSheet) {
            if let liveGameResult = currentLiveGameResult {
                LiveGameResultSheet(
                    liveGameResult: liveGameResult,
                    onSave: { value in
                        viewModel.send(.onSaveLiveGameResultClicked(
                            liveGameResultUiModel: liveGameResult,
                            teamGoalsValue: value
                        ))
                        showLiveGameResultSheet = false
                    },
                    onDismiss: { showLiveGameResultSheet = false }
                )
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showLeftTeamOptionsDropdown, onDismiss: {
            viewModel.send(.onLeftTeamOptionSelected(option: nil))
            showLeftTeamOptionsDropdown = false
        }) {
            if let liveGame = viewModel.uiState.liveGameUiModel {
                TeamOptionsDropdown(
                    teamName: liveGame.leftTeamName,
                    teamColor: liveGame.leftTeamColor.color,
                    onOptionSelected: { option in
                        viewModel.send(.onLeftTeamOptionSelected(option: option))
                        showLeftTeamOptionsDropdown = false
                    },
                    onDismiss: {
                        viewModel.send(.onLeftTeamOptionSelected(option: nil))
                        showLeftTeamOptionsDropdown = false
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showRightTeamOptionsDropdown, onDismiss: {
            viewModel.send(.onRightTeamOptionSelected(option: nil))
            showRightTeamOptionsDropdown = false
        }) {
            if let liveGame = viewModel.uiState.liveGameUiModel {
                TeamOptionsDropdown(
                    teamName: liveGame.rightTeamName,
                    teamColor: liveGame.rightTeamColor.color,
                    onOptionSelected: { option in
                        viewModel.send(.onRightTeamOptionSelected(option: option))
                        showRightTeamOptionsDropdown = false
                    },
                    onDismiss: {
                        viewModel.send(.onRightTeamOptionSelected(option: nil))
                        showRightTeamOptionsDropdown = false
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showLeftTeamChangeDropdown, onDismiss: {
            viewModel.send(.onLeftTeamChangeClicked(teamId: nil))
            showLeftTeamChangeDropdown = false
        }) {
            if let liveGame = viewModel.uiState.liveGameUiModel {
                TeamChangeDropdown(
                    teams: viewModel.uiState.teamUiModelList,
                    excludeTeamIds: [liveGame.leftTeamId, liveGame.rightTeamId],
                    onTeamSelected: { teamId in
                        viewModel.send(.onLeftTeamChangeClicked(teamId: teamId))
                        showLeftTeamChangeDropdown = false
                    },
                    onDismiss: {
                        viewModel.send(.onLeftTeamChangeClicked(teamId: nil))
                        showLeftTeamChangeDropdown = false
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showRightTeamChangeDropdown, onDismiss: {
            viewModel.send(.onRightTeamChangeClicked(teamId: nil))
            showRightTeamChangeDropdown = false
        }) {
            if let liveGame = viewModel.uiState.liveGameUiModel {
                TeamChangeDropdown(
                    teams: viewModel.uiState.teamUiModelList,
                    excludeTeamIds: [liveGame.leftTeamId, liveGame.rightTeamId],
                    onTeamSelected: { teamId in
                        viewModel.send(.onRightTeamChangeClicked(teamId: teamId))
                        showRightTeamChangeDropdown = false
                    },
                    onDismiss: {
                        viewModel.send(.onRightTeamChangeClicked(teamId: nil))
                        showRightTeamChangeDropdown = false
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .fullScreenCover(isPresented: $showAddGameScreen, onDismiss: {
            viewModel.refreshData()
        }) {
            if let gameId = updateGameId {
                AddGameScreen(viewModel: viewModel.createAddGameViewModel(gameId: gameId))
            }
        }
        .fullScreenCover(isPresented: $showGameResultsScreen) {
            if let gameId = gameResultsGameId {
                GameResultsScreen(viewModel: viewModel.createGameResultsViewModel(gameId: gameId, modelContext: modelContext))
            }
        }
        .confirmationDialog("", isPresented: $showDeleteConfirmation) {
            Button(NSLocalizedString("delete", comment: ""), role: .destructive) {
                viewModel.send(.onDeleteGameConfirmationClicked)
            }
        } message: {
            Text(NSLocalizedString("delete_game_confirmation", comment: ""))
        }
        .confirmationDialog("", isPresented: $showClearResultsConfirmation) {
            Button(NSLocalizedString("clear", comment: ""), role: .destructive) {
                viewModel.send(.onClearResultsConfirmationClicked)
            }
        } message: {
            Text(NSLocalizedString("clear_results_confirmation", comment: ""))
        }
        .confirmationDialog("", isPresented: $showFinishGameConfirmation) {
            Button(NSLocalizedString("finish", comment: ""), role: .destructive) {
                viewModel.send(.onFinishGameConfirmationClicked)
            }
        } message: {
            Text(NSLocalizedString("finish_game_confirmation", comment: ""))
        }
        .confirmationDialog("", isPresented: $showGoBackConfirmation) {
            Button(NSLocalizedString("leave", comment: ""), role: .destructive) {
                viewModel.send(.onGoBackConfirmationClicked)
            }
        } message: {
            Text(NSLocalizedString("go_back_confirmation", comment: ""))
        }
        .confirmationDialog(NSLocalizedString("choose_staying_team", comment: ""), isPresented: $showStayTeamSheet) {
            if let liveGame = viewModel.uiState.liveGameUiModel {
                Button(liveGame.leftTeamName) {
                    viewModel.send(.onLeftTeamStayClicked)
                }
                Button(liveGame.rightTeamName) {
                    viewModel.send(.onRightTeamStayClicked)
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                viewModel.send(.onBackClicked)
            } label: {
                Image(systemName: "arrow.left")
                    .font(.title3)
                    .foregroundColor(.primary)
            }

            Text(viewModel.uiState.gameUiModel?.name ?? "")
                .font(.headline)
                .frame(maxWidth: .infinity)

            Spacer()
                .frame(width: 24)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private func scoreboardSection(liveGame: LiveGameUiModel) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(NSLocalizedString("game_number", comment: "") + ": \(liveGame.gameCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 0) {
                teamScoreView(
                    name: liveGame.leftTeamName,
                    color: liveGame.leftTeamColor.color,
                    goals: liveGame.leftTeamGoals,
                    winCount: liveGame.leftTeamWinCount,
                    isWinning: liveGame.isLeftTeamWin,
                    isLeft: true
                )
                .onTapGesture {
                    viewModel.send(.onLeftTeamClicked)
                }
                .onLongPressGesture {
                    if let liveGame = viewModel.uiState.liveGameUiModel {
                        viewModel.send(
                            .onLiveGameResultClicked(
                                liveGameResultUiModel: LiveGameResultUiModel(
                                    liveGameUiModel: liveGame,
                                    isLeftTeam: true
                                )
                            )
                        )
                    }
                }

                Button {
                    viewModel.send(.onTeamChangeIconClicked)
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                }

                teamScoreView(
                    name: liveGame.rightTeamName,
                    color: liveGame.rightTeamColor.color,
                    goals: liveGame.rightTeamGoals,
                    winCount: liveGame.rightTeamWinCount,
                    isWinning: liveGame.isRightTeamWin,
                    isLeft: false
                )
                .onTapGesture {
                    viewModel.send(.onRightTeamClicked)
                }
                .onLongPressGesture {
                    if let liveGame = viewModel.uiState.liveGameUiModel {
                        viewModel.send(
                            .onLiveGameResultClicked(
                                liveGameResultUiModel: LiveGameResultUiModel(
                                    liveGameUiModel: liveGame,
                                    isLeftTeam: true
                                )
                            )
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private func teamScoreView(name: String, color: Color, goals: Int, winCount: Int, isWinning: Bool, isLeft: Bool) -> some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text("\(goals)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(isWinning ? color : .primary)

            HStack(spacing: 2) {
                ForEach(0..<winCount, id: \.self) { _ in
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
            }
            .frame(height: 12)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }

    private var timerSection: some View {
        Button {
            viewModel.send(.onTimerClicked)
        } label: {
            HStack {
                if viewModel.uiState.isTimerPlay {
                    Image(systemName: "pause.fill")
                        .foregroundColor(.primary)
                } else {
                    Image(systemName: "play.fill")
                        .foregroundColor(.primary)
                }

                Text(viewModel.timerValue)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }

    private var startFinishButton: some View {
        Button {
            viewModel.send(.onStartFinishButtonClicked)
        } label: {
            Text(viewModel.uiState.liveGameUiModel?.isLive == true
                 ? NSLocalizedString("finish_game", comment: "")
                 : NSLocalizedString("start_game", comment: ""))
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(viewModel.uiState.liveGameUiModel?.isLive == true ? Color.red : Color.green)
                .cornerRadius(16)
        }
    }

    private var soundsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("sounds", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(GameSounds.allCases, id: \.self) { sound in
                        Button {
                            viewModel.send(.onSoundClicked(sound: sound))
                        } label: {
                            Text(NSLocalizedString(sound.localizationKey, comment: ""))
                                .font(.caption)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var functionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("functions", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(GameFunction.allCases, id: \.self) { function in
                    Button {
                        viewModel.send(.onFunctionClicked(function: function))
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: function.systemImage)
                                .frame(width: 24, height: 24)
                                .font(.title3)
                            Text(NSLocalizedString(function.localizationKey, comment: ""))
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(function == .delete ? .red : .primary)
                }
            }
        }
    }

    private var teamsLeaderboard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("teams_leaderboard", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                // Header Row
                HStack(spacing: 0) {
                    Text("#")
                        .frame(width: 24, alignment: .center)
                    Text(NSLocalizedString("team", comment: ""))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(NSLocalizedString("games_short", comment: ""))
                        .frame(width: 24, alignment: .center)
                    Text(NSLocalizedString("wins_short", comment: ""))
                        .frame(width: 24, alignment: .center)
                    Text(NSLocalizedString("draws_short", comment: ""))
                        .frame(width: 24, alignment: .center)
                    Text(NSLocalizedString("loses_short", comment: ""))
                        .frame(width: 24, alignment: .center)
                    Text(NSLocalizedString("goals_short", comment: ""))
                        .frame(width: 40, alignment: .center)
                    Text(NSLocalizedString("goal_difference_short", comment: ""))
                        .frame(width: 28, alignment: .center)
                    Text(NSLocalizedString("points_short", comment: ""))
                        .frame(width: 24, alignment: .center)
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)

                Divider()

                // Team Rows
                ForEach(Array(viewModel.uiState.teamUiModelList.enumerated()), id: \.element.id) { index, team in
                    HStack(spacing: 0) {
                        Text("\(index + 1)")
                            .frame(width: 24, alignment: .center)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(team.color.color)
                                .frame(width: 10, height: 10)
                            Text(team.name)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text("\(team.games)")
                            .frame(width: 24, alignment: .center)
                        Text("\(team.wins)")
                            .frame(width: 24, alignment: .center)
                        Text("\(team.draws)")
                            .frame(width: 24, alignment: .center)
                        Text("\(team.loses)")
                            .frame(width: 24, alignment: .center)
                        Text("\(team.goals)-\(team.conceded)")
                            .frame(width: 40, alignment: .center)
                        Text(team.goalsDifference > 0 ? "+\(team.goalsDifference)" : "\(team.goalsDifference)")
                            .frame(width: 28, alignment: .center)
                        Text("\(team.points)")
                            .frame(width: 24, alignment: .center)
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)

                    if index < viewModel.uiState.teamUiModelList.count - 1 {
                        Divider()
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }

    private var playersLeaderboard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("players_leaderboard", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                // Header Row
                HStack(spacing: 0) {
                    Text("#")
                        .frame(width: 24, alignment: .center)
                    Text(NSLocalizedString("player", comment: ""))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(NSLocalizedString("goals_icon", comment: ""))
                        .frame(width: 28, alignment: .center)
                    Text(NSLocalizedString("assists_icon", comment: ""))
                        .frame(width: 28, alignment: .center)
                    Text(NSLocalizedString("saves_icon", comment: ""))
                        .frame(width: 28, alignment: .center)
                    Text(NSLocalizedString("dribbles_icon", comment: ""))
                        .frame(width: 28, alignment: .center)
                    Text(NSLocalizedString("shots_icon", comment: ""))
                        .frame(width: 28, alignment: .center)
                    Text(NSLocalizedString("passes_icon", comment: ""))
                        .frame(width: 28, alignment: .center)
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)

                Divider()

                // Player Rows
                ForEach(Array(viewModel.uiState.playerUiModelList.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: 0) {
                        Text("\(index + 1)")
                            .frame(width: 24, alignment: .center)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(player.teamColor.color)
                                .frame(width: 10, height: 10)
                            Text(player.name)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text("\(player.goals)")
                            .frame(width: 28, alignment: .center)
                        Text("\(player.assists)")
                            .frame(width: 28, alignment: .center)
                        Text("\(player.saves)")
                            .frame(width: 28, alignment: .center)
                        Text("\(player.dribbles)")
                            .frame(width: 28, alignment: .center)
                        Text("\(player.shots)")
                            .frame(width: 28, alignment: .center)
                        Text("\(player.passes)")
                            .frame(width: 28, alignment: .center)
                    }
                    .font(.caption)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.send(
                            .onPlayerResultClicked(
                                playerResultUiModel: PlayerResultUiModel(
                                    playerUiModel: player,
                                    option: .goal
                                )
                            )
                        )
                    }

                    if index < viewModel.uiState.playerUiModelList.count - 1 {
                        Divider()
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }

    private func handleEffect(_ effect: GameEffect?) {
        guard let effect = effect else { return }
        viewModel.effect = nil

        switch effect {
        case .closeScreen:
            dismiss()
        case .closeScreenWithResult:
            dismiss()
        case .openUpdateGame(let gameId):
            updateGameId = gameId
            showAddGameScreen = true
        case .openGameResultsScreen(let gameId):
            gameResultsGameId = gameId
            showGameResultsScreen = true
        case .showOptionPlayersBottomSheet(let optionPlayers):
            currentOptionPlayers = optionPlayers
            showOptionPlayersSheet = true
        case .showPlayerResultBottomSheet(let playerResult):
            currentPlayerResult = playerResult
            showPlayerResultSheet = true
        case .showLiveGameResultBottomSheet(let liveGameResult):
            currentLiveGameResult = liveGameResult
            showLiveGameResultSheet = true
        case .showStayTeamSelectionBottomSheet:
            showStayTeamSheet = true
        case .showDeleteGameConfirmationBottomSheet:
            showDeleteConfirmation = true
        case .showClearResultsConfirmationBottomSheet:
            showClearResultsConfirmation = true
        case .showFinishGameConfirmationBottomSheet:
            showFinishGameConfirmation = true
        case .showGoBackConfirmationBottomSheet:
            showGoBackConfirmation = true
        case .showGameInfoBottomSheet:
            showGameInfoSheet = true
        case .openActivationScreen:
            break
        case .showBestPlayersBottomSheet(let bestPlayers):
            currentBestPlayers = bestPlayers
            showBestPlayersSheet = true
        case .showSnackbar(let message):
            viewModel.snackbarMessage = message
        }
    }
}

struct OptionPlayersSheet: View {
    let optionPlayers: OptionPlayersUiModel
    let onPlayerSelected: (PlayerUiModel) -> Void
    let onAutoGoalSelected: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(optionPlayers.playerUiModelList) { player in
                    Button {
                        onPlayerSelected(player)
                    } label: {
                        Text(player.name)
                    }
                }
                
                if optionPlayers.option == .goal {
                    Button {
                        onAutoGoalSelected()
                    } label: {
                        Text(NSLocalizedString("auto_goal", comment: ""))
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle(NSLocalizedString(optionPlayers.option.localizationKey, comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("cancel", comment: "")) {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct BestPlayersSheet: View {
    let bestPlayers: [BestPlayerUiModel]

    var body: some View {
        NavigationView {
            List {
                ForEach(bestPlayers, id: \.option) { bestPlayer in
                    
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString(bestPlayer.option.localizationKey, comment: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Circle()
                                .fill(bestPlayer.playerUiModel.teamColor.color)
                                .frame(width: 12, height: 12)
                            
                            Text(bestPlayer.playerUiModel.name)
                                .font(.headline)
                            
                            Spacer()
                            
                            switch bestPlayer.option {
                            case .bestPlayer:
                                let result = [
                                    stat(bestPlayer.playerUiModel.goals, "text_goal"),
                                    stat(bestPlayer.playerUiModel.assists, "text_assist"),
                                    stat(bestPlayer.playerUiModel.saves, "text_save"),
                                    stat(bestPlayer.playerUiModel.dribbles, "text_dribble"),
                                    stat(bestPlayer.playerUiModel.passes, "text_pass"),
                                    stat(bestPlayer.playerUiModel.shots, "text_shot")
                                ]
                                .compactMap { $0 }
                                .joined(separator: ", ")
                                
                                Text(result)
                                    .font(.body)
                                    .padding(.leading, 32)
                            case .goals:
                                Text("\(bestPlayer.playerUiModel.goals) \(NSLocalizedString("text_goal", comment: ""))")
                                    .font(.body)
                            case .assists:
                                Text("\(bestPlayer.playerUiModel.assists) \(NSLocalizedString("text_assist", comment: ""))")
                                    .font(.body)
                            case .saves:
                                Text("\(bestPlayer.playerUiModel.saves) \(NSLocalizedString("text_save", comment: ""))")
                                    .font(.body)
                            case .dribbles:
                                Text("\(bestPlayer.playerUiModel.dribbles) \(NSLocalizedString("text_dribble", comment: ""))")
                                    .font(.body)
                            case .passes:
                                Text("\(bestPlayer.playerUiModel.passes) \(NSLocalizedString("text_pass", comment: ""))")
                                    .font(.body)
                            case .shots:
                                Text("\(bestPlayer.playerUiModel.shots) \(NSLocalizedString("text_shot", comment: ""))")
                                    .font(.body)
                            }
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("best_players", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func stat(_ value: Int, _ key: String) -> String? {
        value > 0 ? "\(value) \(NSLocalizedString(key, comment: ""))" : nil
    }
}

struct GameInfoSheet: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Live Game Block Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.left.arrow.right")
                                .foregroundColor(.accentColor)
                            Text(NSLocalizedString("live_game_info_replace_teams", comment: ""))
                                .font(.caption)
                        }
                        HStack(spacing: 12) {
                            Image(systemName: "pause.circle")
                                .foregroundColor(.primary)
                            Text(NSLocalizedString("live_game_info_pause_timer", comment: ""))
                                .font(.caption)
                        }
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle")
                                .foregroundColor(.primary)
                            Text(NSLocalizedString("live_game_info_play_timer", comment: ""))
                                .font(.caption)
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
                        InfoRow(symbol: NSLocalizedString("dribbles_icon", comment: ""), description: NSLocalizedString("players_block_info_dribbles", comment: ""))
                        InfoRow(symbol: NSLocalizedString("shots_icon", comment: ""), description: NSLocalizedString("players_block_info_shots", comment: ""))
                        InfoRow(symbol: NSLocalizedString("passes_icon", comment: ""), description: NSLocalizedString("players_block_info_passes", comment: ""))
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("game_info", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct InfoRow: View {
    let symbol: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Text(symbol)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
            Text(description)
                .font(.caption)
        }
    }
}

struct PlayerResultSheet: View {
    let playerResult: PlayerResultUiModel
    let onSave: (TeamOption, Int) -> Void
    let onDismiss: () -> Void

    @State private var selectedOption: TeamOption
    @State private var valueText: String

    init(playerResult: PlayerResultUiModel, onSave: @escaping (TeamOption, Int) -> Void, onDismiss: @escaping () -> Void) {
        self.playerResult = playerResult
        self.onSave = onSave
        self.onDismiss = onDismiss
        self._selectedOption = State(initialValue: playerResult.option)
        self._valueText = State(initialValue: "\(Self.getValue(for: playerResult.option, player: playerResult.playerUiModel))")
    }

    private static func getValue(for option: TeamOption, player: PlayerUiModel) -> Int {
        switch option {
        case .goal: return player.goals
        case .assist: return player.assists
        case .save: return player.saves
        case .dribble: return player.dribbles
        case .shot: return player.shots
        case .pass: return player.passes
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HStack {
                    Circle()
                        .fill(playerResult.playerUiModel.teamColor.color)
                        .frame(width: 16, height: 16)
                    Text(playerResult.playerUiModel.name)
                        .font(.headline)
                }
                .padding(.top)

                Picker(NSLocalizedString("stat_type", comment: ""), selection: $selectedOption) {
                    ForEach(TeamOption.allCases, id: \.self) { option in
                        Text(NSLocalizedString(option.localizationKey, comment: "")).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedOption) { _, newOption in
                    valueText = "\(Self.getValue(for: newOption, player: playerResult.playerUiModel))"
                }

                TextField(NSLocalizedString("value", comment: ""), text: $valueText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button {
                    if let value = Int(valueText) {
                        onSave(selectedOption, value)
                    }
                } label: {
                    Text(NSLocalizedString("save", comment: ""))
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle(NSLocalizedString("edit_player_stats", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("cancel", comment: "")) {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct LiveGameResultSheet: View {
    let liveGameResult: LiveGameResultUiModel
    let onSave: (Int) -> Void
    let onDismiss: () -> Void

    @State private var goalsText: String

    init(liveGameResult: LiveGameResultUiModel, onSave: @escaping (Int) -> Void, onDismiss: @escaping () -> Void) {
        self.liveGameResult = liveGameResult
        self.onSave = onSave
        self.onDismiss = onDismiss
        let goals = liveGameResult.isLeftTeam
            ? liveGameResult.liveGameUiModel.leftTeamGoals
            : liveGameResult.liveGameUiModel.rightTeamGoals
        self._goalsText = State(initialValue: "\(goals)")
    }

    private var teamName: String {
        liveGameResult.isLeftTeam
            ? liveGameResult.liveGameUiModel.leftTeamName
            : liveGameResult.liveGameUiModel.rightTeamName
    }

    private var teamColor: Color {
        (liveGameResult.isLeftTeam
            ? liveGameResult.liveGameUiModel.leftTeamColor
            : liveGameResult.liveGameUiModel.rightTeamColor).color
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HStack {
                    Circle()
                        .fill(teamColor)
                        .frame(width: 16, height: 16)
                    Text(teamName)
                        .font(.headline)
                }
                .padding(.top)

                Text(NSLocalizedString("goals", comment: ""))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField(NSLocalizedString("goals", comment: ""), text: $goalsText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button {
                    if let value = Int(goalsText) {
                        onSave(value)
                    }
                } label: {
                    Text(NSLocalizedString("save", comment: ""))
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle(NSLocalizedString("edit_team_goals", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("cancel", comment: "")) {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct TeamOptionsDropdown: View {
    let teamName: String
    let teamColor: Color
    let onOptionSelected: (TeamOption) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(TeamOption.allCases, id: \.self) { option in
                    Button {
                        onOptionSelected(option)
                    } label: {
                        Text(NSLocalizedString(option.localizationKey, comment: ""))
                    }
                }
            }
            .navigationTitle(teamName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("cancel", comment: "")) {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct TeamChangeDropdown: View {
    let teams: [TeamUiModel]
    let excludeTeamIds: [UUID]
    let onTeamSelected: (UUID) -> Void
    let onDismiss: () -> Void

    var availableTeams: [TeamUiModel] {
        teams.filter { !excludeTeamIds.contains($0.id) }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(availableTeams) { team in
                    Button {
                        onTeamSelected(team.id)
                    } label: {
                        HStack {
                            Circle()
                                .fill(team.color.color)
                                .frame(width: 12, height: 12)
                            Text(team.name)
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("choose_team", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("cancel", comment: "")) {
                        onDismiss()
                    }
                }
            }
        }
    }
}
