//
//  GameScreen.swift
//  doptep
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct GameScreen: View {
    private enum TeamActionSide { case left, right }
    private enum TeamActionPage {
        case options
        case players(OptionPlayersUiModel)
    }

    @StateObject private var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    init(viewModel: GameViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    @State private var showTeamActionSheet = false
    @State private var teamActionSide: TeamActionSide = .left
    @State private var teamActionPage: TeamActionPage = .options
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
    @State private var showActivationScreen = false
    @State private var showPaywall = false
    @State private var pendingActivationAfterPaywall = false
    @State private var showNoEntitlementAlert = false
    @State private var gameResultsGameId: UUID?
    @State private var showLeftTeamChangeDropdown = false
    @State private var showRightTeamChangeDropdown = false
    @State private var restoreFailureMessage: String?

    @State private var currentPlayerResult: PlayerResultUiModel?
    @State private var showTeamResultSheet = false
    @State private var currentTeamResult: TeamUiModel?
    @State private var currentLiveGameResult: LiveGameResultUiModel?
    @State private var currentBestPlayers: [BestPlayerUiModel] = []
    @State private var showGameHistorySheet = false
    @State private var currentGameHistory: [GameHistoryEntryUiModel] = []
    @State private var showCustomizeColumnsSheet = false
    @State private var hiddenStatOptions: Set<TeamOption> = []

    var body: some View {
        withConfirmationDialogs(
            withAlerts(
                withNavigationDestinations(
                    withSheets(
                        withOnChangeHandlers(mainContent)
                    )
                )
            )
        )
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    if viewModel.uiState.billingType == .limited {
                        activationInfoBlock
                    }
                    infoSection
                    if viewModel.uiState.gameUiModel == nil {
                        scoreboardSkeleton
                    } else if let liveGame = viewModel.uiState.liveGameUiModel {
                        scoreboardSection(liveGame: liveGame)
                    }
                    timerSection
                    soundsSection
                    if viewModel.uiState.teamUiModelList.count > 2 {
                        teamsLeaderboard
                    }
                    playersLeaderboard
                    functionsSection
                }
                .padding(.vertical, 16)
            }
        }
        .background(AppColor.background)
        .navigationBarHidden(true)
        .enableSwipeBack()
        .snackbar(message: $viewModel.snackbarMessage)
        .onAppear {
            hiddenStatOptions = HiddenColumnsStorage.load(gameId: viewModel.gameId)
        }
        .onDisappear {
            viewModel.saveTimerOnExit()
        }
        .fullScreenCover(isPresented: $showActivationScreen, onDismiss: { viewModel.updateBillingState() }) {
            ActivationScreen()
        }
    }

    // MARK: - onChange

    private func withOnChangeHandlers<Content: View>(_ content: Content) -> some View {
        content
            .onChange(of: viewModel.effect) { _, effect in
                handleEffect(effect)
            }
            .onChange(of: viewModel.uiState.showLeftTeamOptionsDropdown) { _, newValue in
                if newValue {
                    teamActionSide = .left
                    teamActionPage = .options
                    showTeamActionSheet = true
                }
            }
            .onChange(of: viewModel.uiState.showRightTeamOptionsDropdown) { _, newValue in
                if newValue {
                    teamActionSide = .right
                    teamActionPage = .options
                    showTeamActionSheet = true
                }
            }
            .onChange(of: viewModel.uiState.showLeftTeamChangeDropdown) { _, newValue in
                showLeftTeamChangeDropdown = newValue
            }
            .onChange(of: viewModel.uiState.showRightTeamChangeDropdown) { _, newValue in
                showRightTeamChangeDropdown = newValue
            }
            .onChange(of: hiddenStatOptions) { _, newValue in
                HiddenColumnsStorage.save(newValue, gameId: viewModel.gameId)
            }
            .onChange(of: showAddGameScreen) { _, newValue in
                if !newValue { viewModel.refreshData() }
            }
    }

    // MARK: - sheet

    private func withSheets<Content: View>(_ content: Content) -> some View {
        content
            .sheet(isPresented: $showTeamActionSheet, onDismiss: {
                if case .options = teamActionPage {
                    if teamActionSide == .left {
                        viewModel.send(.onLeftTeamOptionSelected(option: nil))
                    } else {
                        viewModel.send(.onRightTeamOptionSelected(option: nil))
                    }
                }
                teamActionPage = .options
            }) {
                teamActionSheetContent
            }
            .sheet(isPresented: $showBestPlayersSheet) {
                BestPlayersSheet(bestPlayers: currentBestPlayers)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showGameHistorySheet) {
                GameHistorySheet(gameHistory: currentGameHistory)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showCustomizeColumnsSheet) {
                CustomizeColumnsSheet(hiddenOptions: $hiddenStatOptions)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showGameInfoSheet) {
                GameInfoSheet()
                    .presentationDetents([.large])
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
            .sheet(isPresented: $showTeamResultSheet) {
                if let teamResult = currentTeamResult {
                    GameTeamResultSheet(
                        teamUiModel: teamResult,
                        onSaveClicked: { team, value in
                            viewModel.send(.onSaveTeamResultClicked(
                                teamUiModel: team,
                                pointsValue: value
                            ))
                            showTeamResultSheet = false
                        },
                        onDismissed: { showTeamResultSheet = false }
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
            .sheet(isPresented: $showPaywall, onDismiss: {
                if pendingActivationAfterPaywall {
                    pendingActivationAfterPaywall = false
                    showActivationScreen = true
                }
            }) {
                RevenueCatUI.PaywallView()
                    .onPurchaseCompleted { customerInfo in
                        let success = RevenueCatManager.shared.updateBillingType(from: customerInfo)
                        if success {
                            pendingActivationAfterPaywall = true
                            showPaywall = false
                        } else {
                            showNoEntitlementAlert = true
                        }
                    }
                    .onRestoreCompleted { customerInfo in
                        let success = RevenueCatManager.shared.updateBillingType(from: customerInfo)
                        if success {
                            pendingActivationAfterPaywall = true
                            showPaywall = false
                        } else {
                            showNoEntitlementAlert = true
                        }
                    }
                    .onRestoreFailure { error in
                        restoreFailureMessage = error.localizedDescription
                    }
            }
            .sheet(isPresented: $showStayTeamSheet) {
                if let liveGame = viewModel.uiState.liveGameUiModel {
                    VStack(spacing: 0) {
                        Text(NSLocalizedString("choose_staying_team", comment: ""))
                            .font(.bodyMedium)
                            .foregroundColor(AppColor.onSurface)
                            .padding(.vertical, 20)

                        Divider()

                        Button {
                            showStayTeamSheet = false
                            viewModel.send(.onLeftTeamStayClicked)
                        } label: {
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(liveGame.leftTeamColor.color)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(liveGame.leftTeamColor.color == .white ? AppColor.surfaceVariant : Color.clear, lineWidth: 1)
                                    )
                                Text(liveGame.leftTeamName)
                                    .font(.bodySmall)
                                    .foregroundColor(AppColor.onSurface)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }

                        Divider()

                        Button {
                            showStayTeamSheet = false
                            viewModel.send(.onRightTeamStayClicked)
                        } label: {
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(liveGame.rightTeamColor.color)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(liveGame.rightTeamColor.color == .white ? AppColor.surfaceVariant : Color.clear, lineWidth: 1)
                                    )
                                Text(liveGame.rightTeamName)
                                    .font(.bodySmall)
                                    .foregroundColor(AppColor.onSurface)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                    }
                    .background(AppColor.surface)
                    .interactiveDismissDisabled(true)
                    .presentationDetents([.height(180)])
                }
            }
    }

    // MARK: - navigationDestination

    private func withNavigationDestinations<Content: View>(_ content: Content) -> some View {
        content
            .navigationDestination(isPresented: $showAddGameScreen) {
                if let gameId = updateGameId {
                    AddGameScreen(viewModel: viewModel.createAddGameViewModel(gameId: gameId))
                }
            }
            .navigationDestination(isPresented: $showGameResultsScreen) {
                if let gameId = gameResultsGameId {
                    GameResultsScreen(viewModel: viewModel.createGameResultsViewModel(gameId: gameId, modelContext: modelContext))
                }
            }
    }

    // MARK: - alert

    private func withAlerts<Content: View>(_ content: Content) -> some View {
        content
            .alert(NSLocalizedString("no_active_entitlement", comment: ""), isPresented: $showNoEntitlementAlert) {
                Button("OK", role: .cancel) {}
            }
            .alert(restoreFailureMessage ?? "", isPresented: Binding(
                get: { restoreFailureMessage != nil },
                set: { if !$0 { restoreFailureMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            }
    }

    // MARK: - confirmationDialog

    private func withConfirmationDialogs<Content: View>(_ content: Content) -> some View {
        content
            .confirmationDialog("", isPresented: $showDeleteConfirmation) {
                Button(NSLocalizedString("delete", comment: ""), role: .destructive) {
                    viewModel.send(.onDeleteGameConfirmationClicked)
                }
            } message: {
                Text(NSLocalizedString("delete_game_confirmation", comment: ""))
                    .font(.bodySmall)
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
                    .font(.bodySmall)
            }
            .confirmationDialog("", isPresented: $showGoBackConfirmation) {
                Button(NSLocalizedString("leave", comment: ""), role: .destructive) {
                    viewModel.send(.onGoBackConfirmationClicked)
                }
            } message: {
                Text(NSLocalizedString("go_back_confirmation", comment: ""))
                    .font(.bodySmall)
            }
    }

    private var topBar: some View {
        HStack {
            Button {
                viewModel.send(.onBackClicked)
            } label: {
                Image(systemName: "arrow.left")
                    .font(.titleLarge)
                    .foregroundColor(AppColor.onSurface)
            }

            Text(viewModel.uiState.gameUiModel?.name ?? "")
                .font(.titleMedium)
                .foregroundColor(AppColor.onSurface)
                .frame(maxWidth: .infinity)

            Spacer()
                .frame(width: 24)
        }
        .padding()
        .background(AppColor.surface)
    }

    /// Shared pitch-card shell (gradient, grass stripes, rounded border,
    /// shadow) so the scoreboard, timer and start/finish sections all read
    /// as one visual family while staying separate, independently spaced
    /// blocks in the layout.
    private func pitchCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 16) {
            content()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(ScoreboardBackground())
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color(hex: "#0A2818").opacity(0.4), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 16)
    }

    /// Placeholder shown while the initial game/live-game data is still
    /// loading, sized to match the real scoreboard card so it doesn't pop
    /// in and shove the rest of the screen down once data arrives.
    private var scoreboardSkeleton: some View {
        pitchCard {
            Capsule()
                .fill(Color.white.opacity(0.10))
                .frame(width: 70, height: 22)
                .shimmering()

            HStack(spacing: 4) {
                skeletonTeamColumn

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 52, height: 52)
                    .shimmering()

                skeletonTeamColumn
            }
        }
    }

    private var skeletonTeamColumn: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 38, height: 38)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.10))
                .frame(width: 44, height: 40)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.08))
                .frame(width: 70, height: 12)
        }
        .frame(maxWidth: .infinity)
        .shimmering()
    }

    private func scoreboardSection(liveGame: LiveGameUiModel) -> some View {
        pitchCard {
            matchStatusBadge(liveGame: liveGame)

            HStack(spacing: 4) {
                teamScoreView(
                    name: liveGame.leftTeamName,
                    color: liveGame.leftTeamColor.color,
                    goals: liveGame.leftTeamGoals,
                    winCount: liveGame.leftTeamWinCount,
                    isWinning: liveGame.isLeftTeamWin,
                    isLeft: true
                )
                .contentShape(Rectangle())
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

                centerDivider(liveGame: liveGame)
                    .padding(.horizontal, 2)

                teamScoreView(
                    name: liveGame.rightTeamName,
                    color: liveGame.rightTeamColor.color,
                    goals: liveGame.rightTeamGoals,
                    winCount: liveGame.rightTeamWinCount,
                    isWinning: liveGame.isRightTeamWin,
                    isLeft: false
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.send(.onRightTeamClicked)
                }
                .onLongPressGesture {
                    if let liveGame = viewModel.uiState.liveGameUiModel {
                        viewModel.send(
                            .onLiveGameResultClicked(
                                liveGameResultUiModel: LiveGameResultUiModel(
                                    liveGameUiModel: liveGame,
                                    isLeftTeam: false
                                )
                            )
                        )
                    }
                }
            }
            .background(PitchCenterMark())

            if shouldShowStreak {
                streakRow(liveGame: liveGame)
            }

            if !viewModel.uiState.nextPlayingTeamsUiModelList.isEmpty {
                nextPlayingFooter
            } else if !viewModel.uiState.restTeamUiModelList.isEmpty {
                restFooter
            }
        }
    }

    private var shouldShowStreak: Bool {
        guard let gameUiModel = viewModel.uiState.gameUiModel else { return false }
        if gameUiModel.teamQuantity == .team4 { return true }
        guard gameUiModel.teamQuantity == .team3, let rule = gameUiModel.gameRule as? GameRuleTeam3 else { return false }
        return rule == .winnerStay3 || rule == .winnerStay4 || rule == .winnerStayUnlimited
    }

    private func matchStatusBadge(liveGame: LiveGameUiModel) -> some View {
        Group {
            if liveGame.isLive {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "#FF4B4B"))
                        .frame(width: 7, height: 7)
                        .phaseAnimator([false, true]) { view, phase in
                            view
                                .scaleEffect(phase ? 1.6 : 1.0)
                                .opacity(phase ? 0.4 : 1.0)
                        } animation: { _ in
                            .easeInOut(duration: 0.9)
                        }
                    Text("LIVE")
                        .font(.labelSmall)
                        .tracking(1.2)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color(hex: "#FF4B4B").opacity(0.22)))
                .overlay(Capsule().stroke(Color(hex: "#FF4B4B").opacity(0.5), lineWidth: 1))
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#FFD54A"))
                    Text(matchStatusText(liveGame: liveGame))
                        .font(.labelSmall)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.08)))
            }
        }
    }

    private func matchStatusText(liveGame: LiveGameUiModel) -> String {
        if viewModel.uiState.gameUiModel?.teamQuantity == .team2 {
            return String(format: NSLocalizedString("half_count", comment: ""), "\(liveGame.gameCount)")
        } else {
            return String(format: NSLocalizedString("game_count", comment: ""), "\(liveGame.gameCount)")
        }
    }

    private func centerDivider(liveGame: LiveGameUiModel) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 52, height: 52)
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: 52, height: 52)

            if liveGame.isLive {
                Image(systemName: "soccerball")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.9))
            } else {
                Button {
                    viewModel.send(.onTeamChangeIconClicked)
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
    }

    private func streakRow(liveGame: LiveGameUiModel) -> some View {
        HStack(spacing: 8) {
            streakPill(count: liveGame.leftTeamWinCount)
                .frame(maxWidth: .infinity)
            streakPill(count: liveGame.rightTeamWinCount)
                .frame(maxWidth: .infinity)
        }
    }

    private func streakPill(count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#FFB020"))
            Text(String(format: NSLocalizedString("win_streak", comment: ""), "\(count)"))
                .font(.labelSmall)
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.white.opacity(0.08)))
    }

    private func scoreboardDivider(title: String) -> some View {
        HStack(spacing: 12) {
            Rectangle().frame(maxWidth: .infinity, maxHeight: 1).foregroundColor(.white.opacity(0.12))
            Text(title.uppercased())
                .font(.labelSmall)
                .foregroundColor(Color(hex: "#FFD54A").opacity(0.85))
                .tracking(0.8)
                .fixedSize()
            Rectangle().frame(maxWidth: .infinity, maxHeight: 1).foregroundColor(.white.opacity(0.12))
        }
    }

    private func scoreboardTeamChip(_ color: Color?) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color ?? Color.clear)
            .frame(width: 12, height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(color == .white ? 0.6 : 0.15), lineWidth: 1)
            )
    }

    private var nextPlayingFooter: some View {
        VStack(spacing: 10) {
            scoreboardDivider(title: NSLocalizedString("next_playing_teams", comment: ""))

            ForEach(viewModel.uiState.nextPlayingTeamsUiModelList.indices, id: \.self) { index in
                let nextTeams = viewModel.uiState.nextPlayingTeamsUiModelList[index]
                HStack(spacing: 6) {
                    if let leftTeam = nextTeams.leftTeam {
                        Text(leftTeam.name)
                            .font(.labelSmall)
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        scoreboardTeamChip(leftTeam.color.color)
                    } else {
                        scoreboardTeamChip(nil)
                        Text("?")
                            .font(.labelSmall)
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    Text("–")
                        .font(.labelSmall)
                        .foregroundColor(.white.opacity(0.4))

                    if let rightTeam = nextTeams.rightTeam {
                        scoreboardTeamChip(rightTeam.color.color)
                        Text(rightTeam.name)
                            .font(.labelSmall)
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("?")
                            .font(.labelSmall)
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        scoreboardTeamChip(nil)
                    }
                }
            }
        }
    }

    private var restFooter: some View {
        VStack(spacing: 10) {
            scoreboardDivider(title: NSLocalizedString("next_playing_teams", comment: ""))

            ForEach(viewModel.uiState.restTeamUiModelList, id: \.id) { teamUiModel in
                HStack(spacing: 6) {
                    scoreboardTeamChip(teamUiModel.color.color)
                    Text(teamUiModel.name)
                        .font(.labelSmall)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func jerseyBadge(color: Color) -> some View {
        Image("ic_jersey")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundColor(color)
            .frame(width: 38, height: 38)
            .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
    }

    private func teamScoreView(name: String, color: Color, goals: Int, winCount: Int, isWinning: Bool, isLeft: Bool) -> some View {
        VStack(spacing: 10) {
            jerseyBadge(color: color)
                .overlay(alignment: .topTrailing) {
                    if winCount > 2 {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "#FFB020"))
                            .padding(4)
                            .background(Circle().fill(Color(hex: "#123D22")))
                            .offset(x: 8, y: -6)
                    }
                }

            Text("\(goals)")
                .font(.custom("Montserrat-Bold", size: 52))
                .foregroundColor(.white)
                .monospacedDigit()
                .shadow(color: isWinning ? Color(hex: "#FFD54A").opacity(0.6) : .clear, radius: 12)

            Text(name)
                .font(.labelMedium)
                .foregroundColor(.white.opacity(0.85))
                .tracking(0.6)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var timerSection: some View {
        pitchCard {
            Button {
                viewModel.send(.onTimerClicked)
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.10))
                            .frame(width: 44, height: 44)
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            .frame(width: 44, height: 44)
                        Image(systemName: viewModel.uiState.isTimerPlay ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text(viewModel.timerValue)
                        .font(.custom("Montserrat-Bold", size: 34))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .padding(.trailing, 58)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(height: 1)

            let isLive = viewModel.uiState.liveGameUiModel?.isLive == true
            let accentColor = isLive ? Color(hex: "#EC7063") : AppColor.primary

            Button {
                viewModel.send(.onStartFinishButtonClicked)
            } label: {
                HStack(spacing: 8) {
                    Text(isLive
                         ? NSLocalizedString("finish_game", comment: "")
                         : NSLocalizedString("start_game", comment: ""))
                        .font(.titleMedium)
                        .tracking(0.4)
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: isLive
                            ? [Color(hex: "#EC7063"), Color(hex: "#C0392B")]
                            : [AppColor.primary, Color(hex: "#155A22")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: accentColor.opacity(0.4), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
    }

    private var soundsSection: some View {
        let uiLimited = viewModel.uiState.uiLimited
        return VStack(alignment: .leading, spacing: 8) {

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(GameSounds.allCases, id: \.self) { sound in
                        let isLocked = uiLimited && sound != .whistle && sound != .startMatch
                        Button {
                            if isLocked {
                                viewModel.send(.onActivateClicked)
                            } else {
                                viewModel.send(.onSoundClicked(sound: sound))
                            }
                        } label: {
                            Text(NSLocalizedString(sound.localizationKey, comment: ""))
                                .font(.labelSmall)
                                .foregroundColor(isLocked ? AppColor.outline : AppColor.onSurface)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(AppColor.surface)
                                .cornerRadius(8)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: true, vertical: false)
                                .overlay(alignment: .topTrailing) {
                                    if isLocked {
                                        Image(systemName: "lock.fill")
                                            .font(.caption2)
                                            .foregroundColor(AppColor.outline)
                                            .padding(4)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var functionsSection: some View {
        let uiLimited = viewModel.uiState.uiLimited
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(GameFunction.allCases, id: \.self) { function in
                let isLocked = (function == .bestPlayers || function == .history) && uiLimited
                Button {
                    if isLocked {
                        viewModel.send(.onActivateClicked)
                    } else {
                        viewModel.send(.onFunctionClicked(function: function))
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: function.systemImage)
                            .frame(width: 24, height: 24)
                            .font(.titleLarge)
                        Text(NSLocalizedString(function.localizationKey, comment: ""))
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
                .foregroundColor(isLocked ? AppColor.outline : (function == .delete ? Color(hex: "#EC7063") : AppColor.onSurface))
            }
        }
        .padding(.horizontal, 16)
    }

    private var activationInfoBlock: some View {
        VStack {
            VStack(alignment: .trailing, spacing: 12) {
                Text(NSLocalizedString("activation_orange_text", comment: ""))
                    .font(.bodySmall)
                    .foregroundColor(AppColor.onSurface)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(NSLocalizedString("activation_button", comment: ""))
                    .font(.bodyMedium)
                    .foregroundColor(AppColor.onSurface)
                    .padding(12)
                    .onTapGesture {
                        viewModel.send(.onActivateClicked)
                    }
                Text(viewModel.uiState.gameUiModel?.teamQuantity == .team2
                     ? NSLocalizedString("activation_green_text_team2", comment: "")
                     : NSLocalizedString("activation_green_text", comment: ""))
                    .font(.custom("Montserrat-Medium", size: 12))
                    .foregroundColor(AppColor.onSurface)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color(hex: "#FFA500"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 16)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {

            if let game = viewModel.uiState.gameUiModel {
                VStack(alignment: .leading, spacing: 6) {
                    row(
                        title: NSLocalizedString("home_game_format", comment: ""),
                        value: game.gameFormat.rawValue
                    )

                    row(
                        title: NSLocalizedString("home_game_team_quantity", comment: ""),
                        value: "\(game.teamQuantity.rawValue)"
                    )

                    row(
                        title: NSLocalizedString("home_game_time", comment: ""),
                        value: "\(game.timeInMinutes) минут"
                    )

                    row(
                        title: NSLocalizedString("home_game_rule", comment: ""),
                        value: NSLocalizedString(game.gameRule.localizationKey, comment: "")
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(0..<4, id: \.self) { _ in
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColor.surfaceVariant)
                                .frame(width: 120, height: 14)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColor.surfaceVariant)
                                .frame(width: 60, height: 12)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shimmering()
            }
        }
        .padding(.horizontal, 16)
    }

    private func row(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(title)
                .font(.labelMedium)
                .foregroundColor(AppColor.onSurface)

            Text(value)
                .font(.labelSmall)
                .foregroundColor(AppColor.onSurface)
        }
    }

    // MARK: - Teams Leaderboard
    
    private var teamsLeaderboard: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack(alignment: .top, spacing: 8) {
                // Place
                statColumn(
                    header: "#",
                    values: viewModel.uiState.teamUiModelList.enumerated().map { ("\($0.offset + 1)", nil) }
                )

                // Team name (flexible)
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("team", comment: ""))
                        .font(.labelSmall)
                        .foregroundColor(AppColor.outline)

                    ForEach(viewModel.uiState.teamUiModelList, id: \.id) { team in
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
                statColumn(
                    header: NSLocalizedString("games_short", comment: ""),
                    values: viewModel.uiState.teamUiModelList.map { ("\($0.games)", nil) }
                )
                statColumn(
                    header: NSLocalizedString("wins_short", comment: ""),
                    values: viewModel.uiState.teamUiModelList.map { ("\($0.wins)", nil) }
                )
                statColumn(
                    header: NSLocalizedString("draws_short", comment: ""),
                    values: viewModel.uiState.teamUiModelList.map { ("\($0.draws)", nil) }
                )
                statColumn(
                    header: NSLocalizedString("loses_short", comment: ""),
                    values: viewModel.uiState.teamUiModelList.map { ("\($0.loses)", nil) }
                )
                statColumn(
                    header: NSLocalizedString("goals_short", comment: ""),
                    values: viewModel.uiState.teamUiModelList.map { ("\($0.goals)-\($0.conceded)", nil) }
                )
                statColumn(
                    header: NSLocalizedString("goal_difference_short", comment: ""),
                    values: viewModel.uiState.teamUiModelList.map {
                        ($0.goalsDifference > 0 ? "+\($0.goalsDifference)" : "\($0.goalsDifference)", nil)
                    }
                )
                teamPointsColumn(
                    teams: viewModel.uiState.teamUiModelList
                )
            }
            .padding(12)
            .background(AppColor.surface)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
    }

    private func teamPointsColumn(teams: [TeamUiModel]) -> some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("points_short", comment: ""))
                .font(.labelSmall)
                .foregroundColor(AppColor.outline)

            ForEach(teams, id: \.id) { team in
                Text("\(team.points)")
                    .font(.labelLarge)
                    .foregroundColor(AppColor.onSurface)
                    .onTapGesture {
                        viewModel.send(.onTeamResultClicked(teamUiModel: team))
                    }
            }
        }
    }

    private func statColumn(header: String, values: [(String, Font?)]) -> some View {
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

    private func playerStatColumn(
        header: String,
        players: [PlayerUiModel],
        valuePath: KeyPath<PlayerUiModel, Int>,
        option: TeamOption
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
                        viewModel.send(
                            .onPlayerResultClicked(
                                playerResultUiModel: PlayerResultUiModel(
                                    playerUiModel: player,
                                    option: option
                                )
                            )
                        )
                    }
            }
        }
    }
    
    // MARK: - Players Leaderboard

    private var playersLeaderboard: some View {
        VStack(alignment: .leading) {
            
            HStack(alignment: .top, spacing: 12) {
                // Place
                statColumn(
                    header: "#",
                    values: viewModel.uiState.playerUiModelList.enumerated().map { ("\($0.offset + 1)", nil) }
                )

                // Player name (flexible)
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("player", comment: ""))
                        .font(.labelSmall)
                        .foregroundColor(AppColor.outline)

                    ForEach(viewModel.uiState.playerUiModelList, id: \.id) { player in
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
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Stat columns (tappable)
                playerStatColumn(
                    header: NSLocalizedString("goals_icon", comment: ""),
                    players: viewModel.uiState.playerUiModelList,
                    valuePath: \.goals,
                    option: .goal
                )
                playerStatColumn(
                    header: NSLocalizedString("assists_icon", comment: ""),
                    players: viewModel.uiState.playerUiModelList,
                    valuePath: \.assists,
                    option: .assist
                )
                if !hiddenStatOptions.contains(.save) {
                    playerStatColumn(
                        header: NSLocalizedString("saves_icon", comment: ""),
                        players: viewModel.uiState.playerUiModelList,
                        valuePath: \.saves,
                        option: .save
                    )
                }
                if !hiddenStatOptions.contains(.dribble) {
                    playerStatColumn(
                        header: NSLocalizedString("dribbles_icon", comment: ""),
                        players: viewModel.uiState.playerUiModelList,
                        valuePath: \.dribbles,
                        option: .dribble
                    )
                }
                if !hiddenStatOptions.contains(.shot) {
                    playerStatColumn(
                        header: NSLocalizedString("shots_icon", comment: ""),
                        players: viewModel.uiState.playerUiModelList,
                        valuePath: \.shots,
                        option: .shot
                    )
                }
                if !hiddenStatOptions.contains(.pass) {
                    playerStatColumn(
                        header: NSLocalizedString("passes_icon", comment: ""),
                        players: viewModel.uiState.playerUiModelList,
                        valuePath: \.passes,
                        option: .pass
                    )
                }
                if !hiddenStatOptions.contains(.yellowCard) {
                    playerStatColumn(
                        header: NSLocalizedString("player_result_yellow_card", comment: ""),
                        players: viewModel.uiState.playerUiModelList,
                        valuePath: \.yellowCards,
                        option: .yellowCard
                    )
                }
                if !hiddenStatOptions.contains(.redCard) {
                    playerStatColumn(
                        header: NSLocalizedString("player_result_red_card", comment: ""),
                        players: viewModel.uiState.playerUiModelList,
                        valuePath: \.redCards,
                        option: .redCard
                    )
                }
            }
            .padding(12)

            Button {
                showCustomizeColumnsSheet = true
            } label: {
                Text(NSLocalizedString("customize_columns", comment: ""))
                    .font(.labelSmall)
                    .foregroundColor(AppColor.outline)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 12)
        }
        .background(AppColor.surface)
        .cornerRadius(12)
        .overlay {
            if viewModel.uiState.uiLimited {
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
                    viewModel.send(.onActivateClicked)
                }
            }
        }
        .padding(.horizontal, 16)
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
            teamActionPage = .players(optionPlayers)
            if !showTeamActionSheet {
                showTeamActionSheet = true
            }
        case .showPlayerResultBottomSheet(let playerResult):
            currentPlayerResult = playerResult
            showPlayerResultSheet = true
        case .showTeamResultBottomSheet(let teamResult):
            currentTeamResult = teamResult
            showTeamResultSheet = true
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
            showPaywall = true
        case .showBestPlayersBottomSheet(let bestPlayers):
            currentBestPlayers = bestPlayers
            showBestPlayersSheet = true
        case .showGameHistorySheet(let history):
            currentGameHistory = history
            showGameHistorySheet = true
        case .showSnackbar(let message):
            viewModel.snackbarMessage = message
        }
    }

    @ViewBuilder
    private var teamActionSheetContent: some View {
        if let liveGame = viewModel.uiState.liveGameUiModel {
            switch teamActionPage {
            case .options:
                TeamOptionsDropdown(
                    teamName: teamActionSide == .left ? liveGame.leftTeamName : liveGame.rightTeamName,
                    teamColor: (teamActionSide == .left ? liveGame.leftTeamColor : liveGame.rightTeamColor).color,
                    hiddenOptions: hiddenStatOptions,
                    onOptionSelected: { option in
                        if teamActionSide == .left {
                            viewModel.send(.onLeftTeamOptionSelected(option: option))
                        } else {
                            viewModel.send(.onRightTeamOptionSelected(option: option))
                        }
                    },
                    onDismiss: {
                        if teamActionSide == .left {
                            viewModel.send(.onLeftTeamOptionSelected(option: nil))
                        } else {
                            viewModel.send(.onRightTeamOptionSelected(option: nil))
                        }
                        showTeamActionSheet = false
                    }
                )
                .presentationDetents([.medium])
            case .players(let optionPlayers):
                OptionPlayersSheet(
                    optionPlayers: optionPlayers,
                    onPlayerSelected: { player in
                        viewModel.send(.onOptionPlayersSelected(
                            teamId: optionPlayers.teamId,
                            playerUiModel: player,
                            option: optionPlayers.option
                        ))
                        showTeamActionSheet = false
                    },
                    onAutoGoalSelected: {
                        viewModel.send(.onOptionPlayersAutoGoalSelected(teamId: optionPlayers.teamId))
                        showTeamActionSheet = false
                    },
                    onDismiss: { showTeamActionSheet = false }
                )
                .presentationDetents([.medium])
            }
        }
    }
}

/// A short-sleeve football kit silhouette: rounded V-collar, softly curved
/// sleeve ends, gently tapered torso — traced clockwise from the neckline.
private struct ScoreboardBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0B2F1B"), Color(hex: "#123D22"), Color(hex: "#0A2818")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geo in
                let stripeCount = 8
                let stripeWidth = geo.size.width / CGFloat(stripeCount)
                HStack(spacing: 0) {
                    ForEach(0..<stripeCount, id: \.self) { index in
                        Rectangle()
                            .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.025 : 0))
                            .frame(width: stripeWidth)
                    }
                }
            }
        }
    }
}

/// Decorative pitch halfway-line + center circle, meant to sit behind the
/// score row only so it always stays centered on `centerDivider` regardless
/// of which optional sections (streak row, next/rest team footers) render
/// below it and change the card's overall height.
/// Sweeps a soft highlight across `content`, masked to its own shape so the
/// glow only travels over the placeholder bars themselves. Driven off
/// `TimelineView` rather than a toggled `@State` value, so — unlike a
/// `.animation(_:value:)`-based loop — it can't get stuck mid-cycle if the
/// view is torn down and rebuilt while already mid-animation.
private struct ShimmerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay {
                TimelineView(.animation) { timeline in
                    GeometryReader { geo in
                        let cycle = 1.4
                        let phase = timeline.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: cycle) / cycle
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.35), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.5)
                        .offset(x: -geo.size.width * 0.5 + CGFloat(phase) * geo.size.width * 1.5)
                    }
                }
                .mask(content)
            }
    }
}

private extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

private struct PitchCenterMark: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 1.5)
                .frame(width: 130, height: 130)

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1.5)
        }
    }
}
