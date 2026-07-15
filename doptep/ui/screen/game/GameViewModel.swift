//
//  GameViewModel.swift
//  doptep
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import SwiftData
import UIKit

@MainActor
final class GameViewModel: ObservableObject {

    let gameId: UUID
    private let gameRepository: GameRepository
    private let liveGameRepository: LiveGameRepository
    private let teamRepository: TeamRepository
    private let teamHistoryRepository: TeamHistoryRepository
    private let playerRepository: PlayerRepository
    private let playerHistoryRepository: PlayerHistoryRepository
    private let gameHistoryRepository: GameHistoryRepository
    private let audioManager: AudioManager

    @Published var uiState = GameUiState()
    @Published var effect: GameEffect? = nil
    @Published var snackbarMessage: String? = nil
    @Published var timerValue: String = "00:00"

    private var timer: Timer? = nil
    private var timerMillis: Int = 0
    private var oldTeamId: UUID = UUID()
    private var backgroundDate: Date? = nil
    private var lifecycleObservers: [NSObjectProtocol] = []

    private var pendingGameDurationSeconds: Int = 0
    private var currentGameActions: [PendingGameAction] = []

    private struct PendingGameAction {
        let teamName: String
        let teamColor: String
        let playerName: String
        let playerNumber: Int?
        let actionType: String
        let elapsedSeconds: Int
    }

    private var isLive: Bool {
        uiState.liveGameUiModel?.isLive ?? false
    }

    private var timeInMinutes: Int {
        uiState.gameUiModel?.timeInMinutes ?? 7
    }

    init(
        gameId: UUID,
        gameRepository: GameRepository,
        liveGameRepository: LiveGameRepository,
        teamRepository: TeamRepository,
        teamHistoryRepository: TeamHistoryRepository,
        playerRepository: PlayerRepository,
        playerHistoryRepository: PlayerHistoryRepository,
        gameHistoryRepository: GameHistoryRepository,
        audioManager: AudioManager
    ) {
        self.gameId = gameId
        self.gameRepository = gameRepository
        self.liveGameRepository = liveGameRepository
        self.teamRepository = teamRepository
        self.teamHistoryRepository = teamHistoryRepository
        self.playerRepository = playerRepository
        self.playerHistoryRepository = playerHistoryRepository
        self.gameHistoryRepository = gameHistoryRepository
        self.audioManager = audioManager

        fetchGame()
        setupLifecycleObservers()
    }

    deinit {
        lifecycleObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    private func setupLifecycleObservers() {
        let didEnterBackground = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                if self.timer != nil {
                    self.backgroundDate = Date()
                    self.timer?.invalidate()
                    self.timer = nil
                }
            }
        }

        let willEnterForeground = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                if let bg = self.backgroundDate {
                    let elapsed = Int(Date().timeIntervalSince(bg)) * 1000
                    self.timerMillis = max(0, self.timerMillis - elapsed)
                    self.timerValue = self.formatTime(self.timerMillis)
                    self.backgroundDate = nil
                    self.cancelTimerMilestoneSounds()
                    self.resumeTimer()
                }
            }
        }

        lifecycleObservers = [didEnterBackground, willEnterForeground]
    }

    func send(_ action: GameAction) {
        switch action {
        case .onBackClicked:
            onBackClicked()
        case .onGoBackConfirmationClicked:
            effect = .closeScreen
        case .onDeleteGameConfirmationClicked:
            onDeleteGameConfirmationClicked()
        case .onClearResultsConfirmationClicked:
            onClearResultsConfirmationClicked()
        case .onStartFinishButtonClicked:
            onStartFinishButtonClicked()
        case .onFinishGameConfirmationClicked:
            finishGame()
        case .onTimerClicked:
            onTimerClicked()
        case .onLeftTeamClicked:
            onLeftTeamClicked()
        case .onRightTeamClicked:
            onRightTeamClicked()
        case .onLeftTeamOptionSelected(let option):
            onLeftTeamOptionSelected(option)
        case .onRightTeamOptionSelected(let option):
            onRightTeamOptionSelected(option)
        case .onTeamChangeIconClicked:
            onTeamChangeIconClicked()
        case .onLeftTeamChangeClicked(let teamId):
            onLeftTeamChangeClicked(teamId)
        case .onRightTeamChangeClicked(let teamId):
            onRightTeamChangeClicked(teamId)
        case .onOptionPlayersSelected(let teamId, let playerUiModel, let option):
            onOptionPlayersSelected(teamId: teamId, playerUiModel: playerUiModel, option: option)
        case .onOptionPlayersAutoGoalSelected(let teamId):
            onOptionPlayersAutoGoalSelected(teamId: teamId)
        case .onStayTeamSelectionBottomSheetDismissed:
            onStayTeamSelectionBottomSheetDismissed()
        case .onLeftTeamStayClicked:
            onLeftTeamStayClicked()
        case .onRightTeamStayClicked:
            onRightTeamStayClicked()
        case .onSoundClicked(let sound):
            audioManager.playSound(sound.fileName)
        case .onFunctionClicked(let function):
            onFunctionClicked(function)
        case .onPlayerResultClicked(let playerResultUiModel):
            effect = .showPlayerResultBottomSheet(playerResultUiModel: playerResultUiModel)
        case .onSavePlayerResultClicked(let playerResultUiModel, let playerResultValue):
            onSavePlayerResultClicked(playerResultUiModel: playerResultUiModel, value: playerResultValue)
        case .onTeamResultClicked(let teamUiModel):
            effect = .showTeamResultBottomSheet(teamUiModel: teamUiModel)
        case .onSaveTeamResultClicked(let teamUiModel, let pointsValue):
            onSaveTeamResultClicked(teamUiModel: teamUiModel, value: pointsValue)
        case .onLiveGameResultClicked(let liveGameResultUiModel):
            if isLive {
                effect = .showLiveGameResultBottomSheet(liveGameResultUiModel: liveGameResultUiModel)
            }
        case .onSaveLiveGameResultClicked(let liveGameResultUiModel, let teamGoalsValue):
            onSaveLiveGameResultClicked(liveGameResultUiModel: liveGameResultUiModel, value: teamGoalsValue)
        case .onActivateClicked:
            if isLive {
                snackbarMessage = NSLocalizedString("open_activation_screen_snackbar_text", comment: "")
            } else {
                effect = .openActivationScreen
            }
        }
    }

    private func fetchGame() {
        Task {
            do {
                guard let gameUiModel = try gameRepository.getGame(id: gameId) else { return }

                let teamList = try teamRepository.getTeams(gameId: gameId)
                    .sorted { lhs, rhs in
                        if lhs.points != rhs.points { return lhs.points > rhs.points }
                        if lhs.goalsDifference != rhs.goalsDifference { return lhs.goalsDifference > rhs.goalsDifference }
                        return lhs.name < rhs.name
                    }

                var playerList: [PlayerUiModel] = []
                for team in teamList {
                    let players = try playerRepository.getPlayers(teamId: team.id)
                    playerList.append(contentsOf: players)
                }
                playerList.sort { lhs, rhs in
                    if lhs.goals != rhs.goals { return lhs.goals > rhs.goals }
                    if lhs.assists != rhs.assists { return lhs.assists > rhs.assists }
                    if lhs.saves != rhs.saves { return lhs.saves > rhs.saves }
                    let lhsOther = lhs.dribbles + lhs.shots + lhs.passes
                    let rhsOther = rhs.dribbles + rhs.shots + rhs.passes
                    if lhsOther != rhsOther { return lhsOther > rhsOther }
                    if lhs.redCards != rhs.redCards { return lhs.redCards < rhs.redCards }
                    if lhs.yellowCards != rhs.yellowCards { return lhs.yellowCards < rhs.yellowCards }
                    if lhs.teamPoints != rhs.teamPoints { return lhs.teamPoints > rhs.teamPoints }
                    if lhs.teamGoalsDifference != rhs.teamGoalsDifference { return lhs.teamGoalsDifference > rhs.teamGoalsDifference }
                    if lhs.teamName != rhs.teamName { return lhs.teamName < rhs.teamName }
                    let lhsNumber = lhs.number ?? Int.min
                    let rhsNumber = rhs.number ?? Int.min
                    if lhsNumber != rhsNumber { return lhsNumber < rhsNumber }
                    return lhs.name < rhs.name
                }

                let liveGameUiModel = try liveGameRepository.getLiveGame(gameId: gameId)

                uiState.gameUiModel = gameUiModel
                uiState.teamUiModelList = teamList
                uiState.playerUiModelList = playerList
                uiState.liveGameUiModel = liveGameUiModel
                setNextPlayingTeamsUiModelList()

                updateBillingState()
                setTimerValue()
            } catch {
                snackbarMessage = "Error loading game"
            }
        }
    }

    private func setTimerValue() {
        if isLive {
            let savedValue = liveGameRepository.getTimerValue()
            timerMillis = savedValue > 0 ? savedValue : timeInMinutes * 60 * 1000
        } else {
            timerMillis = timeInMinutes * 60 * 1000
        }
        timerValue = formatTime(timerMillis)
    }

    private func formatTime(_ millis: Int) -> String {
        let totalSeconds = millis / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func onBackClicked() {
        if isLive {
            effect = .showGoBackConfirmationBottomSheet
        } else {
            effect = .closeScreen
        }
    }

    private func onDeleteGameConfirmationClicked() {
        Task {
            do {
                try gameHistoryRepository.deleteGameHistory(gameId: gameId)
                try gameRepository.deleteGame(id: gameId)
                effect = .closeScreenWithResult
            } catch {
                snackbarMessage = "Error deleting game"
            }
        }
    }

    private func onClearResultsConfirmationClicked() {
        Task {
            do {
                let teams = try teamRepository.getTeams(gameId: gameId)
                for team in teams {
                    let clearedTeam = TeamUiModel(
                        id: team.id,
                        gameId: team.gameId,
                        name: team.name,
                        color: team.color,
                        games: 0, wins: 0, draws: 0, loses: 0,
                        goals: 0, conceded: 0, points: 0
                    )
                    try teamRepository.updateTeam(clearedTeam)

                    let players = try playerRepository.getPlayers(teamId: team.id)
                    for player in players {
                        let clearedPlayer = PlayerUiModel(
                            id: player.id,
                            teamId: player.teamId,
                            teamColor: player.teamColor,
                            teamName: player.teamName,
                            teamPoints: 0,
                            teamGoalsDifference: 0,
                            name: player.name,
                            goals: 0, assists: 0, dribbles: 0,
                            passes: 0, shots: 0, saves: 0,
                            yellowCards: 0, redCards: 0,
                            number: player.number
                        )
                        try playerRepository.updatePlayer(clearedPlayer)
                    }
                }

                if let liveGame = uiState.liveGameUiModel {
                    let clearedLiveGame = liveGame.updating(
                        leftTeamGoals: 0,
                        leftTeamWinCount: 0,
                        rightTeamGoals: 0,
                        rightTeamWinCount: 0,
                        gameCount: 0,
                        isLive: false
                    )
                    try liveGameRepository.updateLiveGame(clearedLiveGame)
                }

                try gameHistoryRepository.deleteGameHistory(gameId: gameId)
                currentGameActions.removeAll()
                fetchGame()
            } catch {
                snackbarMessage = "Error clearing results"
            }
        }
    }

    private func onStartFinishButtonClicked() {
        guard let liveGame = uiState.liveGameUiModel else { return }

        if !liveGame.isLive {
            startGame(liveGame)
        } else {
            effect = .showFinishGameConfirmationBottomSheet
        }
    }

    private func startGame(_ liveGame: LiveGameUiModel) {
        audioManager.playSound("start_match")
        currentGameActions.removeAll()
        startTimer()

        Task {
            do {
                let updatedLiveGame = liveGame.updating(isLive: true)
                try liveGameRepository.updateLiveGame(updatedLiveGame)
                try gameRepository.updateModifiedTime(id: gameId)
                uiState.liveGameUiModel = updatedLiveGame
            } catch {
                snackbarMessage = "Error starting game"
            }
        }
    }

    private func finishGame() {
        audioManager.playSound("finish")
        pendingGameDurationSeconds = currentElapsedSeconds()
        resetTimer()

        guard let gameUiModel = uiState.gameUiModel,
              let liveGame = uiState.liveGameUiModel else { return }

        Task {
            do {
                switch gameUiModel.teamQuantity {
                case .team2:
                    try await finishTeam2Game(gameUiModel: gameUiModel, liveGame: liveGame)
                case .team3:
                    try await finishTeam3Game(gameUiModel: gameUiModel, liveGame: liveGame)
                case .team4:
                    try await finishTeam4Game(gameUiModel: gameUiModel, liveGame: liveGame)
                }
                try await updateTeamsBlock()
                try await updatePlayersBlock()
                try await updateLiveGameBlock()
                try gameRepository.saveContext()
            } catch {
                snackbarMessage = "Error finishing game"
            }
        }
    }

    private func finishTeam2Game(gameUiModel: GameUiModel, liveGame: LiveGameUiModel) async throws {
        saveGameHistory(liveGame)
        guard let rule = gameUiModel.gameRule as? GameRuleTeam2 else { return }

        switch rule {
        case .afterTimeChangeSide:
            let updatedLiveGame = LiveGameUiModel(
                id: liveGame.id,
                gameId: liveGame.gameId,
                leftTeamId: liveGame.rightTeamId,
                leftTeamName: liveGame.rightTeamName,
                leftTeamColor: liveGame.rightTeamColor,
                leftTeamGoals: liveGame.rightTeamGoals,
                leftTeamWinCount: 0,
                rightTeamId: liveGame.leftTeamId,
                rightTeamName: liveGame.leftTeamName,
                rightTeamColor: liveGame.leftTeamColor,
                rightTeamGoals: liveGame.leftTeamGoals,
                rightTeamWinCount: 0,
                gameCount: liveGame.gameCount + 1,
                isLive: false
            )
            try liveGameRepository.updateLiveGame(updatedLiveGame)

        case .afterTimeStaySide:
            let updatedLiveGame = liveGame.updating(
                gameCount: liveGame.gameCount + 1,
                isLive: false
            )
            try liveGameRepository.updateLiveGame(updatedLiveGame)
        }
    }

    private func finishTeam3Game(gameUiModel: GameUiModel, liveGame: LiveGameUiModel) async throws {
        saveGameHistory(liveGame)
        guard let rule = gameUiModel.gameRule as? GameRuleTeam3 else { return }
        let ids = [liveGame.leftTeamId, liveGame.rightTeamId]

        switch rule {
        case .only2Games:
            if liveGame.isLeftTeamWin {
                try await updateLeftTeamWin(liveGame: liveGame)
            } else if liveGame.isRightTeamWin {
                try await updateRightTeamWin(liveGame: liveGame)
            } else {
                try await updateTeamsDraw(liveGame: liveGame)
            }
            if let nextTeam = findNextTeam(excludingIds: ids) {
                if liveGame.leftTeamWinCount > liveGame.rightTeamWinCount {
                    try await updateLiveGameLeftTeam(nextTeam: nextTeam, liveGame: liveGame)
                } else {
                    try await updateLiveGameRightTeam(nextTeam: nextTeam, liveGame: liveGame)
                }
            }

        case .winnerStay2:
            try await finishGameRuleTeam3WinnerStay(liveGame: liveGame, ids: ids, winCount: 1)
        case .winnerStay3:
            try await finishGameRuleTeam3WinnerStay(liveGame: liveGame, ids: ids, winCount: 2)
        case .winnerStay4:
            try await finishGameRuleTeam3WinnerStay(liveGame: liveGame, ids: ids, winCount: 3)
        case .winnerStayUnlimited:
            if liveGame.isLeftTeamWin {
                try await updateLeftTeamWin(liveGame: liveGame)
                if let nextTeam = findNextTeam(excludingIds: ids) {
                    try await updateLiveGameRightTeam(nextTeam: nextTeam, liveGame: liveGame)
                }
            } else if liveGame.isRightTeamWin {
                try await updateRightTeamWin(liveGame: liveGame)
                if let nextTeam = findNextTeam(excludingIds: ids) {
                    try await updateLiveGameLeftTeam(nextTeam: nextTeam, liveGame: liveGame)
                }
            } else {
                try await updateTeamsDraw(liveGame: liveGame)
                try await updateLiveGameRuleTeam3WhenDraw(liveGame: liveGame, ids: ids)
            }
        }
    }

    private func finishTeam4Game(gameUiModel: GameUiModel, liveGame: LiveGameUiModel) async throws {
        saveGameHistory(liveGame)
        guard let rule = gameUiModel.gameRule as? GameRuleTeam4 else { return }
        let ids = [liveGame.leftTeamId, liveGame.rightTeamId, oldTeamId]

        switch rule {
        case .only3Games:
            if liveGame.isLeftTeamWin {
                try await updateLeftTeamWin(liveGame: liveGame)
            } else if liveGame.isRightTeamWin {
                try await updateRightTeamWin(liveGame: liveGame)
            } else {
                try await updateTeamsDraw(liveGame: liveGame)
            }
            if let nextTeam = findNextTeam(excludingIds: ids) {
                if liveGame.leftTeamWinCount == 0 && liveGame.rightTeamWinCount == 0 {
                    oldTeamId = liveGame.rightTeamId
                    try await updateLiveGameRightTeam(nextTeam: nextTeam, liveGame: liveGame)
                } else if liveGame.leftTeamWinCount == 1 {
                    oldTeamId = liveGame.rightTeamId
                    try await updateLiveGameRightTeam(nextTeam: nextTeam, liveGame: liveGame)
                } else if liveGame.leftTeamWinCount == 2 {
                    oldTeamId = liveGame.leftTeamId
                    try await updateLiveGameLeftTeam(nextTeam: nextTeam, liveGame: liveGame)
                } else if liveGame.rightTeamWinCount == 1 {
                    oldTeamId = liveGame.leftTeamId
                    try await updateLiveGameLeftTeam(nextTeam: nextTeam, liveGame: liveGame)
                } else if liveGame.rightTeamWinCount == 2 {
                    oldTeamId = liveGame.rightTeamId
                    try await updateLiveGameRightTeam(nextTeam: nextTeam, liveGame: liveGame)
                }
            }

        case .winnerStay3:
            try await finishGameRuleTeam4WinnerStay(liveGame: liveGame, ids: ids, winCount: 2)
        case .winnerStay4:
            try await finishGameRuleTeam4WinnerStay(liveGame: liveGame, ids: ids, winCount: 3)
        case .winnerStay5:
            try await finishGameRuleTeam4WinnerStay(liveGame: liveGame, ids: ids, winCount: 4)
        case .winnerStay6:
            try await finishGameRuleTeam4WinnerStay(liveGame: liveGame, ids: ids, winCount: 5)
        case .winnerStayUnlimited:
            if liveGame.isLeftTeamWin {
                try await updateLeftTeamWin(liveGame: liveGame)
                if let nextTeam = findNextTeam(excludingIds: ids) {
                    oldTeamId = liveGame.rightTeamId
                    try await updateLiveGameRightTeam(nextTeam: nextTeam, liveGame: liveGame)
                }
            } else if liveGame.isRightTeamWin {
                try await updateRightTeamWin(liveGame: liveGame)
                if let nextTeam = findNextTeam(excludingIds: ids) {
                    oldTeamId = liveGame.leftTeamId
                    try await updateLiveGameLeftTeam(nextTeam: nextTeam, liveGame: liveGame)
                }
            } else {
                try await updateTeamsDraw(liveGame: liveGame)
                try await updateLiveGameRuleTeam4WhenDraw(liveGame: liveGame)
            }
        }
    }

    private func finishGameRuleTeam3WinnerStay(liveGame: LiveGameUiModel, ids: [UUID], winCount: Int) async throws {
        if liveGame.isLeftTeamWin {
            try await updateLeftTeamWin(liveGame: liveGame)
            if let nextTeam = findNextTeam(excludingIds: ids) {
                if liveGame.leftTeamWinCount >= winCount {
                    try await updateLiveGameLeftTeam(nextTeam: nextTeam, liveGame: liveGame)
                } else {
                    try await updateLiveGameRightTeam(nextTeam: nextTeam, liveGame: liveGame)
                }
            }
        } else if liveGame.isRightTeamWin {
            try await updateRightTeamWin(liveGame: liveGame)
            if let nextTeam = findNextTeam(excludingIds: ids) {
                if liveGame.rightTeamWinCount >= winCount {
                    try await updateLiveGameRightTeam(nextTeam: nextTeam, liveGame: liveGame)
                } else {
                    try await updateLiveGameLeftTeam(nextTeam: nextTeam, liveGame: liveGame)
                }
            }
        } else {
            try await updateTeamsDraw(liveGame: liveGame)
            try await updateLiveGameRuleTeam3WhenDraw(liveGame: liveGame, ids: ids)
        }
    }

    private func finishGameRuleTeam4WinnerStay(liveGame: LiveGameUiModel, ids: [UUID], winCount: Int) async throws {
        if liveGame.isLeftTeamWin {
            try await updateLeftTeamWin(liveGame: liveGame)
            if let nextTeam = findNextTeam(excludingIds: ids) {
                if liveGame.leftTeamWinCount >= winCount {
                    oldTeamId = liveGame.leftTeamId
                    try await updateLiveGameLeftTeam(nextTeam: nextTeam, liveGame: liveGame)
                } else {
                    oldTeamId = liveGame.rightTeamId
                    try await updateLiveGameRightTeam(nextTeam: nextTeam, liveGame: liveGame)
                }
            }
        } else if liveGame.isRightTeamWin {
            try await updateRightTeamWin(liveGame: liveGame)
            if let nextTeam = findNextTeam(excludingIds: ids) {
                if liveGame.rightTeamWinCount >= winCount {
                    oldTeamId = liveGame.rightTeamId
                    try await updateLiveGameRightTeam(nextTeam: nextTeam, liveGame: liveGame)
                } else {
                    oldTeamId = liveGame.leftTeamId
                    try await updateLiveGameLeftTeam(nextTeam: nextTeam, liveGame: liveGame)
                }
            }
        } else {
            try await updateTeamsDraw(liveGame: liveGame)
            try await updateLiveGameRuleTeam4WhenDraw(liveGame: liveGame)
        }
    }

    private func updateLiveGameRuleTeam3WhenDraw(liveGame: LiveGameUiModel, ids: [UUID]) async throws {
        if let nextTeam = findNextTeam(excludingIds: ids) {
            if liveGame.leftTeamWinCount > liveGame.rightTeamWinCount {
                try await updateLiveGameLeftTeam(nextTeam: nextTeam, liveGame: liveGame)
            } else if liveGame.leftTeamWinCount < liveGame.rightTeamWinCount {
                try await updateLiveGameRightTeam(nextTeam: nextTeam, liveGame: liveGame)
            } else {
                effect = .showStayTeamSelectionBottomSheet
            }
        }
    }

    private func updateLiveGameRuleTeam4WhenDraw(liveGame: LiveGameUiModel) async throws {
        let nextTeams = uiState.teamUiModelList.filter {
            $0.id != liveGame.leftTeamId && $0.id != liveGame.rightTeamId
        }

        let newTeam: TeamUiModel?
        let oldTeam: TeamUiModel?

        if oldTeamId == nextTeams.first?.id {
            newTeam = nextTeams.count > 1 ? nextTeams[1] : nil
            oldTeam = nextTeams.first
        } else if oldTeamId == (nextTeams.count > 1 ? nextTeams[1] : nil)?.id {
            newTeam = nextTeams.first
            oldTeam = nextTeams.count > 1 ? nextTeams[1] : nil
        } else {
            newTeam = nextTeams.first
            oldTeam = nextTeams.count > 1 ? nextTeams[1] : nil
        }

        if let newTeam, let oldTeam {
            oldTeamId = liveGame.leftTeamWinCount > liveGame.rightTeamWinCount
                ? liveGame.leftTeamId
                : liveGame.rightTeamId
            try await updateLiveGameBothTeam(newTeam: newTeam, oldTeam: oldTeam, liveGame: liveGame)
        }
    }

    private func updateLiveGameBothTeam(newTeam: TeamUiModel, oldTeam: TeamUiModel, liveGame: LiveGameUiModel) async throws {
        let updated = LiveGameUiModel(
            id: liveGame.id,
            gameId: liveGame.gameId,
            leftTeamId: newTeam.id,
            leftTeamName: newTeam.name,
            leftTeamColor: newTeam.color,
            leftTeamGoals: 0,
            leftTeamWinCount: 0,
            rightTeamId: oldTeam.id,
            rightTeamName: oldTeam.name,
            rightTeamColor: oldTeam.color,
            rightTeamGoals: 0,
            rightTeamWinCount: 1,
            gameCount: liveGame.gameCount + 1,
            isLive: false
        )
        try liveGameRepository.updateLiveGame(updated)
    }

    private func findNextTeam(excludingIds: [UUID]) -> TeamUiModel? {
        uiState.teamUiModelList.first { !excludingIds.contains($0.id) }
    }

    private func updateLiveGameLeftTeam(nextTeam: TeamUiModel, liveGame: LiveGameUiModel) async throws {
        let updated = LiveGameUiModel(
            id: liveGame.id,
            gameId: liveGame.gameId,
            leftTeamId: nextTeam.id,
            leftTeamName: nextTeam.name,
            leftTeamColor: nextTeam.color,
            leftTeamGoals: 0,
            leftTeamWinCount: 0,
            rightTeamId: liveGame.rightTeamId,
            rightTeamName: liveGame.rightTeamName,
            rightTeamColor: liveGame.rightTeamColor,
            rightTeamGoals: 0,
            rightTeamWinCount: liveGame.rightTeamWinCount + 1,
            gameCount: liveGame.gameCount + 1,
            isLive: false
        )
        try liveGameRepository.updateLiveGame(updated)
    }

    private func updateLiveGameRightTeam(nextTeam: TeamUiModel, liveGame: LiveGameUiModel) async throws {
        let updated = LiveGameUiModel(
            id: liveGame.id,
            gameId: liveGame.gameId,
            leftTeamId: liveGame.leftTeamId,
            leftTeamName: liveGame.leftTeamName,
            leftTeamColor: liveGame.leftTeamColor,
            leftTeamGoals: 0,
            leftTeamWinCount: liveGame.leftTeamWinCount + 1,
            rightTeamId: nextTeam.id,
            rightTeamName: nextTeam.name,
            rightTeamColor: nextTeam.color,
            rightTeamGoals: 0,
            rightTeamWinCount: 0,
            gameCount: liveGame.gameCount + 1,
            isLive: false
        )
        try liveGameRepository.updateLiveGame(updated)
    }

    private func updateLeftTeamWin(liveGame: LiveGameUiModel) async throws {
        if let winnerTeam = uiState.teamUiModelList.first(where: { $0.id == liveGame.leftTeamId }) {
            let updated = TeamUiModel(
                id: winnerTeam.id,
                gameId: winnerTeam.gameId,
                name: winnerTeam.name,
                color: winnerTeam.color,
                games: winnerTeam.games + 1,
                wins: winnerTeam.wins + 1,
                draws: winnerTeam.draws,
                loses: winnerTeam.loses,
                goals: winnerTeam.goals + liveGame.leftTeamGoals,
                conceded: winnerTeam.conceded + liveGame.rightTeamGoals,
                points: winnerTeam.points + 3
            )
            try teamRepository.updateTeam(updated)
            
            if let model = try teamHistoryRepository.getTeamHistoryEntity(teamId: updated.id) {
                model.games = model.games + 1
                model.wins = model.wins + 1
                model.goals = model.goals + liveGame.leftTeamGoals
                model.conceded = model.conceded + liveGame.rightTeamGoals
                model.points = model.points + 3
            }
        }
        if let loserTeam = uiState.teamUiModelList.first(where: { $0.id == liveGame.rightTeamId }) {
            let updated = TeamUiModel(
                id: loserTeam.id,
                gameId: loserTeam.gameId,
                name: loserTeam.name,
                color: loserTeam.color,
                games: loserTeam.games + 1,
                wins: loserTeam.wins,
                draws: loserTeam.draws,
                loses: loserTeam.loses + 1,
                goals: loserTeam.goals + liveGame.rightTeamGoals,
                conceded: loserTeam.conceded + liveGame.leftTeamGoals,
                points: loserTeam.points
            )
            try teamRepository.updateTeam(updated)
            
            if let model = try teamHistoryRepository.getTeamHistoryEntity(teamId: updated.id) {
                model.games = model.games + 1
                model.loses = model.loses + 1
                model.goals = model.goals + liveGame.rightTeamGoals
                model.conceded = model.conceded + liveGame.leftTeamGoals
            }
        }
    }

    private func updateRightTeamWin(liveGame: LiveGameUiModel) async throws {
        if let winnerTeam = uiState.teamUiModelList.first(where: { $0.id == liveGame.rightTeamId }) {
            let updated = TeamUiModel(
                id: winnerTeam.id,
                gameId: winnerTeam.gameId,
                name: winnerTeam.name,
                color: winnerTeam.color,
                games: winnerTeam.games + 1,
                wins: winnerTeam.wins + 1,
                draws: winnerTeam.draws,
                loses: winnerTeam.loses,
                goals: winnerTeam.goals + liveGame.rightTeamGoals,
                conceded: winnerTeam.conceded + liveGame.leftTeamGoals,
                points: winnerTeam.points + 3
            )
            try teamRepository.updateTeam(updated)
            
            if let model = try teamHistoryRepository.getTeamHistoryEntity(teamId: updated.id) {
                model.games = model.games + 1
                model.wins = model.wins + 1
                model.goals = model.goals + liveGame.rightTeamGoals
                model.conceded = model.conceded + liveGame.leftTeamGoals
                model.points = model.points + 3
            }
        }
        if let loserTeam = uiState.teamUiModelList.first(where: { $0.id == liveGame.leftTeamId }) {
            let updated = TeamUiModel(
                id: loserTeam.id,
                gameId: loserTeam.gameId,
                name: loserTeam.name,
                color: loserTeam.color,
                games: loserTeam.games + 1,
                wins: loserTeam.wins,
                draws: loserTeam.draws,
                loses: loserTeam.loses + 1,
                goals: loserTeam.goals + liveGame.leftTeamGoals,
                conceded: loserTeam.conceded + liveGame.rightTeamGoals,
                points: loserTeam.points
            )
            try teamRepository.updateTeam(updated)
            
            if let model = try teamHistoryRepository.getTeamHistoryEntity(teamId: updated.id) {
                model.games = model.games + 1
                model.loses = model.loses + 1
                model.goals = model.goals + liveGame.leftTeamGoals
                model.conceded = model.conceded + liveGame.rightTeamGoals
            }
        }
    }

    private func updateTeamsDraw(liveGame: LiveGameUiModel) async throws {
        for teamId in [liveGame.leftTeamId, liveGame.rightTeamId] {
            if let team = uiState.teamUiModelList.first(where: { $0.id == teamId }) {
                let isLeft = teamId == liveGame.leftTeamId
                let updated = TeamUiModel(
                    id: team.id,
                    gameId: team.gameId,
                    name: team.name,
                    color: team.color,
                    games: team.games + 1,
                    wins: team.wins,
                    draws: team.draws + 1,
                    loses: team.loses,
                    goals: team.goals + (isLeft ? liveGame.leftTeamGoals : liveGame.rightTeamGoals),
                    conceded: team.conceded + (isLeft ? liveGame.rightTeamGoals : liveGame.leftTeamGoals),
                    points: team.points + 1
                )
                try teamRepository.updateTeam(updated)
                
                if let model = try teamHistoryRepository.getTeamHistoryEntity(teamId: updated.id) {
                    model.games = model.games + 1
                    model.draws = model.draws + 1
                    model.goals = model.goals + (isLeft ? liveGame.leftTeamGoals : liveGame.rightTeamGoals)
                    model.conceded = model.conceded + (isLeft ? liveGame.rightTeamGoals : liveGame.leftTeamGoals)
                    model.points = model.points + 1
                }
            }
        }
    }

    private func updateLiveGameBlock() async throws {
        uiState.liveGameUiModel = try liveGameRepository.getLiveGame(gameId: gameId)
        setNextPlayingTeamsUiModelList()
        updateBillingState()
    }

    func updateBillingState() {
        let billingType = BillingManager.shared.getCurrentBillingType()
        let teamQuantity = uiState.gameUiModel?.teamQuantity
        let gameCount = uiState.liveGameUiModel?.gameCount ?? 0
        uiState.billingType = billingType
        let uiLimited: Bool
        if billingType == .limited {
            if teamQuantity == .team2 {
                uiLimited = gameCount >= 1
            } else {
                uiLimited = gameCount >= 5
            }
        } else {
            uiLimited = false
        }
        uiState.uiLimited = uiLimited
    }

    private func setNextPlayingTeamsUiModelList() {
        guard let gameUiModel = uiState.gameUiModel else { return }

        switch gameUiModel.teamQuantity {
        case .team2:
            break
        case .team3:
            guard let rule = gameUiModel.gameRule as? GameRuleTeam3 else { return }
            switch rule {
            case .only2Games:
                setTeam3Only2GamesNextPlayingTeams()
            case .winnerStay2:
                setTeam3WinnerStayNextPlayingTeams(winCount: 1)
            case .winnerStay3:
                uiState.nextPlayingTeamsUiModelList = []
            case .winnerStay4:
                uiState.nextPlayingTeamsUiModelList = []
            case .winnerStayUnlimited:
                uiState.nextPlayingTeamsUiModelList = []
            }
        case .team4:
            guard let liveGame = uiState.liveGameUiModel else { break }
            let restTeams = uiState.teamUiModelList.filter {
                $0.id != liveGame.leftTeamId && $0.id != liveGame.rightTeamId
            }
            uiState.restTeamUiModelList = restTeams.sorted { ($0.id == oldTeamId ? 1 : 0) < ($1.id == oldTeamId ? 1 : 0) }
        }
    }

    private func setTeam3Only2GamesNextPlayingTeams() {
        guard let liveGame = uiState.liveGameUiModel else { return }
        let teamList = uiState.teamUiModelList

        let currentLeftTeam = teamList.first { $0.id == liveGame.leftTeamId }
        let currentRightTeam = teamList.first { $0.id == liveGame.rightTeamId }
        let restTeam = teamList.first { $0.id != liveGame.leftTeamId && $0.id != liveGame.rightTeamId }

        let firstNextPlayingTeams: NextPlayingTeamsUiModel
        let secondNextPlayingTeams: NextPlayingTeamsUiModel

        if liveGame.leftTeamWinCount > liveGame.rightTeamWinCount {
            firstNextPlayingTeams = NextPlayingTeamsUiModel(leftTeam: restTeam, rightTeam: currentRightTeam)
            secondNextPlayingTeams = NextPlayingTeamsUiModel(leftTeam: restTeam, rightTeam: currentLeftTeam)
        } else {
            firstNextPlayingTeams = NextPlayingTeamsUiModel(leftTeam: currentLeftTeam, rightTeam: restTeam)
            secondNextPlayingTeams = NextPlayingTeamsUiModel(leftTeam: currentRightTeam, rightTeam: restTeam)
        }

        uiState.nextPlayingTeamsUiModelList = [firstNextPlayingTeams, secondNextPlayingTeams]
    }

    private func setTeam3WinnerStayNextPlayingTeams(winCount: Int) {
        guard let liveGame = uiState.liveGameUiModel else { return }
        let teamList = uiState.teamUiModelList

        let currentLeftTeam = teamList.first { $0.id == liveGame.leftTeamId }
        let currentRightTeam = teamList.first { $0.id == liveGame.rightTeamId }
        let restTeam = teamList.first { $0.id != liveGame.leftTeamId && $0.id != liveGame.rightTeamId }

        let nextPlayingTeams: NextPlayingTeamsUiModel

        if liveGame.leftTeamWinCount >= winCount {
            nextPlayingTeams = NextPlayingTeamsUiModel(leftTeam: restTeam, rightTeam: currentRightTeam)
        } else if liveGame.rightTeamWinCount >= winCount {
            nextPlayingTeams = NextPlayingTeamsUiModel(leftTeam: currentLeftTeam, rightTeam: restTeam)
        } else {
            nextPlayingTeams = NextPlayingTeamsUiModel(leftTeam: restTeam, rightTeam: nil)
        }

        uiState.nextPlayingTeamsUiModelList = [nextPlayingTeams]
    }

    private func updateTeamsBlock() async throws {
        uiState.teamUiModelList = try teamRepository.getTeams(gameId: gameId)
            .sorted { lhs, rhs in
                if lhs.points != rhs.points { return lhs.points > rhs.points }
                if lhs.goalsDifference != rhs.goalsDifference { return lhs.goalsDifference > rhs.goalsDifference }
                return lhs.name < rhs.name
            }
    }

    private func updatePlayersBlock() async throws {
        var players: [PlayerUiModel] = []
        for team in uiState.teamUiModelList {
            players.append(contentsOf: try playerRepository.getPlayers(teamId: team.id))
        }
        uiState.playerUiModelList = players.sorted { lhs, rhs in
            if lhs.goals != rhs.goals { return lhs.goals > rhs.goals }
            if lhs.assists != rhs.assists { return lhs.assists > rhs.assists }
            if lhs.saves != rhs.saves { return lhs.saves > rhs.saves }
            let lhsOther = lhs.dribbles + lhs.shots + lhs.passes
            let rhsOther = rhs.dribbles + rhs.shots + rhs.passes
            if lhsOther != rhsOther { return lhsOther > rhsOther }
            if lhs.redCards != rhs.redCards { return lhs.redCards < rhs.redCards }
            if lhs.yellowCards != rhs.yellowCards { return lhs.yellowCards < rhs.yellowCards }
            if lhs.teamPoints != rhs.teamPoints { return lhs.teamPoints > rhs.teamPoints }
            if lhs.teamGoalsDifference != rhs.teamGoalsDifference { return lhs.teamGoalsDifference > rhs.teamGoalsDifference }
            if lhs.teamName != rhs.teamName { return lhs.teamName < rhs.teamName }
            let lhsNumber = lhs.number ?? Int.min
            let rhsNumber = rhs.number ?? Int.min
            if lhsNumber != rhsNumber { return lhsNumber < rhsNumber }
            return lhs.name < rhs.name
        }
    }

    private func onTimerClicked() {
        guard isLive else { return }
        if timer != nil {
            stopTimer()
        } else {
            startTimer()
        }
    }

    private func startTimer() {
        uiState.isTimerPlay = true
        resumeTimer()
    }

    private func resumeTimer() {
        guard timer == nil else { return }
        scheduleTimerMilestoneSound()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.timerMillis -= 1000
                if self.timerMillis <= 0 {
                    self.timerMillis = 0
                }
                self.timerValue = self.formatTime(self.timerMillis)

                if self.timerMillis == 60000 {
                    if !self.uiState.uiLimited {
                        self.audioManager.playSound("minuta")
                    }
                } else if self.timerMillis == 10000 {
                    if !self.uiState.uiLimited {
                        self.audioManager.playSound("do_auta")
                    }
                }
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        uiState.isTimerPlay = false
        timer?.invalidate()
        timer = nil
        cancelTimerMilestoneSounds()
    }

    private func resetTimer() {
        stopTimer()
        timerMillis = timeInMinutes * 60 * 1000
        timerValue = formatTime(timerMillis)
        liveGameRepository.clearTimerValue()
    }
    
    private func scheduleTimerMilestoneSound() {
        if !uiState.uiLimited {
            let minutaDelay = Double(max(0, timerMillis - 60000)) / 1000.0
            let doAutaDelay = Double(max(0, timerMillis - 10000)) / 1000.0
            audioManager.scheduleTimerMilestoneSound(
                soundName: "minuta_caf",
                afterSeconds: minutaDelay,
                identifier: "timer_minuta",
                title: NSLocalizedString("notification_title_minuta", comment: "")
            )
            audioManager.scheduleTimerMilestoneSound(
                soundName: "do_auta_caf",
                afterSeconds: doAutaDelay,
                identifier: "timer_do_auta",
                title: NSLocalizedString("notification_title_do_auta", comment: "")
            )
        }
    }
    
    private func cancelTimerMilestoneSounds() {
        if !uiState.uiLimited {
            audioManager.cancelTimerMilestoneSounds()
        }
    }

    private func onLeftTeamClicked() {
        if isLive {
            uiState.showLeftTeamOptionsDropdown = true
        } else if uiState.teamUiModelList.count > 2 {
            uiState.showLeftTeamChangeDropdown = true
        }
    }

    private func onRightTeamClicked() {
        if isLive {
            uiState.showRightTeamOptionsDropdown = true
        } else if uiState.teamUiModelList.count > 2 {
            uiState.showRightTeamChangeDropdown = true
        }
    }

    private func onLeftTeamOptionSelected(_ option: TeamOption?) {
        uiState.showLeftTeamOptionsDropdown = false
        guard let option = option, let liveGame = uiState.liveGameUiModel else { return }

        let players = uiState.playerUiModelList
            .filter { $0.teamId == liveGame.leftTeamId }
            .sorted { lhs, rhs in
                if (lhs.number == nil) != (rhs.number == nil) {
                    return lhs.number != nil
                }
                if let lhsNumber = lhs.number, let rhsNumber = rhs.number, lhsNumber != rhsNumber {
                    return lhsNumber < rhsNumber
                }
                return lhs.name < rhs.name
            }

        let optionPlayers = OptionPlayersUiModel(
            option: option,
            teamId: liveGame.leftTeamId,
            playerUiModelList: players
        )
        effect = .showOptionPlayersBottomSheet(optionPlayersUiModel: optionPlayers)
    }

    private func onRightTeamOptionSelected(_ option: TeamOption?) {
        uiState.showRightTeamOptionsDropdown = false
        guard let option = option, let liveGame = uiState.liveGameUiModel else { return }

        let players = uiState.playerUiModelList
            .filter { $0.teamId == liveGame.rightTeamId }
            .sorted { lhs, rhs in
                if (lhs.number == nil) != (rhs.number == nil) {
                    return lhs.number != nil
                }
                if let lhsNumber = lhs.number, let rhsNumber = rhs.number, lhsNumber != rhsNumber {
                    return lhsNumber < rhsNumber
                }
                return lhs.name < rhs.name
            }

        let optionPlayers = OptionPlayersUiModel(
            option: option,
            teamId: liveGame.rightTeamId,
            playerUiModelList: players
        )
        effect = .showOptionPlayersBottomSheet(optionPlayersUiModel: optionPlayers)
    }

    private func onLeftTeamChangeClicked(_ teamId: UUID?) {
        uiState.showLeftTeamChangeDropdown = false
        guard let teamId = teamId,
              let liveGame = uiState.liveGameUiModel,
              let nextTeam = uiState.teamUiModelList.first(where: { $0.id == teamId }) else { return }

        Task {
            do {
                let updated = LiveGameUiModel(
                    id: liveGame.id,
                    gameId: liveGame.gameId,
                    leftTeamId: nextTeam.id,
                    leftTeamName: nextTeam.name,
                    leftTeamColor: nextTeam.color,
                    leftTeamGoals: 0,
                    leftTeamWinCount: 0,
                    rightTeamId: liveGame.rightTeamId,
                    rightTeamName: liveGame.rightTeamName,
                    rightTeamColor: liveGame.rightTeamColor,
                    rightTeamGoals: liveGame.rightTeamGoals,
                    rightTeamWinCount: liveGame.rightTeamWinCount,
                    gameCount: liveGame.gameCount,
                    isLive: liveGame.isLive
                )
                try liveGameRepository.updateLiveGame(updated)
                uiState.liveGameUiModel = updated
                setNextPlayingTeamsUiModelList()
            } catch {
                snackbarMessage = "Error changing team"
            }
        }
    }

    private func onRightTeamChangeClicked(_ teamId: UUID?) {
        uiState.showRightTeamChangeDropdown = false
        guard let teamId = teamId,
              let liveGame = uiState.liveGameUiModel,
              let nextTeam = uiState.teamUiModelList.first(where: { $0.id == teamId }) else { return }

        Task {
            do {
                let updated = LiveGameUiModel(
                    id: liveGame.id,
                    gameId: liveGame.gameId,
                    leftTeamId: liveGame.leftTeamId,
                    leftTeamName: liveGame.leftTeamName,
                    leftTeamColor: liveGame.leftTeamColor,
                    leftTeamGoals: liveGame.leftTeamGoals,
                    leftTeamWinCount: liveGame.leftTeamWinCount,
                    rightTeamId: nextTeam.id,
                    rightTeamName: nextTeam.name,
                    rightTeamColor: nextTeam.color,
                    rightTeamGoals: 0,
                    rightTeamWinCount: 0,
                    gameCount: liveGame.gameCount,
                    isLive: liveGame.isLive
                )
                try liveGameRepository.updateLiveGame(updated)
                uiState.liveGameUiModel = updated
                setNextPlayingTeamsUiModelList()
            } catch {
                snackbarMessage = "Error changing team"
            }
        }
    }

    private func onTeamChangeIconClicked() {
        guard let liveGame = uiState.liveGameUiModel else { return }

        Task {
            do {
                let swapped = LiveGameUiModel(
                    id: liveGame.id,
                    gameId: liveGame.gameId,
                    leftTeamId: liveGame.rightTeamId,
                    leftTeamName: liveGame.rightTeamName,
                    leftTeamColor: liveGame.rightTeamColor,
                    leftTeamGoals: liveGame.rightTeamGoals,
                    leftTeamWinCount: liveGame.rightTeamWinCount,
                    rightTeamId: liveGame.leftTeamId,
                    rightTeamName: liveGame.leftTeamName,
                    rightTeamColor: liveGame.leftTeamColor,
                    rightTeamGoals: liveGame.leftTeamGoals,
                    rightTeamWinCount: liveGame.leftTeamWinCount,
                    gameCount: liveGame.gameCount,
                    isLive: liveGame.isLive
                )
                try liveGameRepository.updateLiveGame(swapped)
                uiState.liveGameUiModel = swapped
                setNextPlayingTeamsUiModelList()
            } catch {
                snackbarMessage = "Error swapping teams"
            }
        }
    }

    private func onOptionPlayersSelected(teamId: UUID, playerUiModel: PlayerUiModel, option: TeamOption) {
        Task {
            do {
                var updatedPlayer = playerUiModel

                switch option {
                case .goal:
                    if let liveGame = uiState.liveGameUiModel {
                        var updated = liveGame
                        if teamId == liveGame.leftTeamId {
                            updated = liveGame.updating(leftTeamGoals: liveGame.leftTeamGoals + 1)
                        } else if teamId == liveGame.rightTeamId {
                            updated = liveGame.updating(rightTeamGoals: liveGame.rightTeamGoals + 1)
                        }
                        try liveGameRepository.updateLiveGame(updated)
                        uiState.liveGameUiModel = updated
                    }
                    updatedPlayer = PlayerUiModel(
                        id: playerUiModel.id, teamId: playerUiModel.teamId,
                        teamColor: playerUiModel.teamColor, teamName: playerUiModel.teamName,
                        teamPoints: playerUiModel.teamPoints, teamGoalsDifference: playerUiModel.teamGoalsDifference,
                        name: playerUiModel.name,
                        goals: playerUiModel.goals + 1,
                        assists: playerUiModel.assists, dribbles: playerUiModel.dribbles,
                        passes: playerUiModel.passes, shots: playerUiModel.shots, saves: playerUiModel.saves,
                        yellowCards: playerUiModel.yellowCards, redCards: playerUiModel.redCards,
                        number: playerUiModel.number
                    )
                    if !uiState.uiLimited {
                        audioManager.speak(
                            text: String(format: NSLocalizedString("text_to_speech_goal", comment: ""), playerUiModel.name),
                            completion: {
                                switch Int.random(in: 0..<3) {
                                case 0:
                                    self.audioManager.playSound("oooi_kandai_gol")
                                case 1:
                                    self.audioManager.playSound("suiii_full")
                                case 2:
                                    self.audioManager.playSound("gol_gol_gol")
                                default:
                                    break
                                }
                            }
                        )
                    }

                case .assist:
                    updatedPlayer = PlayerUiModel(
                        id: playerUiModel.id, teamId: playerUiModel.teamId,
                        teamColor: playerUiModel.teamColor, teamName: playerUiModel.teamName,
                        teamPoints: playerUiModel.teamPoints, teamGoalsDifference: playerUiModel.teamGoalsDifference,
                        name: playerUiModel.name,
                        goals: playerUiModel.goals,
                        assists: playerUiModel.assists + 1, dribbles: playerUiModel.dribbles,
                        passes: playerUiModel.passes, shots: playerUiModel.shots, saves: playerUiModel.saves,
                        yellowCards: playerUiModel.yellowCards, redCards: playerUiModel.redCards,
                        number: playerUiModel.number
                    )
                    if !uiState.uiLimited {
                        audioManager.speak(
                            text: String(format: NSLocalizedString("text_to_speech_assist", comment: ""), playerUiModel.name),
                            completion: { self.audioManager.playSound(GameSounds.girlsApplause.fileName) }
                        )
                    }

                case .save:
                    updatedPlayer = PlayerUiModel(
                        id: playerUiModel.id, teamId: playerUiModel.teamId,
                        teamColor: playerUiModel.teamColor, teamName: playerUiModel.teamName,
                        teamPoints: playerUiModel.teamPoints, teamGoalsDifference: playerUiModel.teamGoalsDifference,
                        name: playerUiModel.name,
                        goals: playerUiModel.goals,
                        assists: playerUiModel.assists, dribbles: playerUiModel.dribbles,
                        passes: playerUiModel.passes, shots: playerUiModel.shots, saves: playerUiModel.saves + 1,
                        yellowCards: playerUiModel.yellowCards, redCards: playerUiModel.redCards,
                        number: playerUiModel.number
                    )
                    if !uiState.uiLimited {
                        audioManager.speak(
                            text: String(format: NSLocalizedString("text_to_speech_save", comment: ""), playerUiModel.name),
                            completion: { self.audioManager.playSound(GameSounds.goalSave.fileName) }
                        )
                    }

                case .dribble:
                    updatedPlayer = PlayerUiModel(
                        id: playerUiModel.id, teamId: playerUiModel.teamId,
                        teamColor: playerUiModel.teamColor, teamName: playerUiModel.teamName,
                        teamPoints: playerUiModel.teamPoints, teamGoalsDifference: playerUiModel.teamGoalsDifference,
                        name: playerUiModel.name,
                        goals: playerUiModel.goals,
                        assists: playerUiModel.assists, dribbles: playerUiModel.dribbles + 1,
                        passes: playerUiModel.passes, shots: playerUiModel.shots, saves: playerUiModel.saves,
                        yellowCards: playerUiModel.yellowCards, redCards: playerUiModel.redCards,
                        number: playerUiModel.number
                    )
                    if !uiState.uiLimited {
                        audioManager.speak(
                            text: String(format: NSLocalizedString("text_to_speech_dribble", comment: ""), playerUiModel.name),
                            completion: { self.audioManager.playSound(GameSounds.bilgeninIstepJatyr.fileName) }
                        )
                    }

                case .shot:
                    updatedPlayer = PlayerUiModel(
                        id: playerUiModel.id, teamId: playerUiModel.teamId,
                        teamColor: playerUiModel.teamColor, teamName: playerUiModel.teamName,
                        teamPoints: playerUiModel.teamPoints, teamGoalsDifference: playerUiModel.teamGoalsDifference,
                        name: playerUiModel.name,
                        goals: playerUiModel.goals,
                        assists: playerUiModel.assists, dribbles: playerUiModel.dribbles,
                        passes: playerUiModel.passes, shots: playerUiModel.shots + 1, saves: playerUiModel.saves,
                        yellowCards: playerUiModel.yellowCards, redCards: playerUiModel.redCards,
                        number: playerUiModel.number
                    )
                    if !uiState.uiLimited {
                        audioManager.speak(
                            text: String(format: NSLocalizedString("text_to_speech_shot", comment: ""), playerUiModel.name),
                            completion: { self.audioManager.playSound(GameSounds.suiii.fileName) }
                        )
                    }
                    
                case .pass:
                    updatedPlayer = PlayerUiModel(
                        id: playerUiModel.id, teamId: playerUiModel.teamId,
                        teamColor: playerUiModel.teamColor, teamName: playerUiModel.teamName,
                        teamPoints: playerUiModel.teamPoints, teamGoalsDifference: playerUiModel.teamGoalsDifference,
                        name: playerUiModel.name,
                        goals: playerUiModel.goals,
                        assists: playerUiModel.assists, dribbles: playerUiModel.dribbles,
                        passes: playerUiModel.passes + 1, shots: playerUiModel.shots, saves: playerUiModel.saves,
                        yellowCards: playerUiModel.yellowCards, redCards: playerUiModel.redCards,
                        number: playerUiModel.number
                    )
                    if !uiState.uiLimited {
                        audioManager.speak(
                            text: String(format: NSLocalizedString("text_to_speech_pass", comment: ""), playerUiModel.name),
                            completion: { self.audioManager.playSound(GameSounds.stadiumApplause.fileName) }
                        )
                    }

                case .yellowCard:
                    updatedPlayer = PlayerUiModel(
                        id: playerUiModel.id, teamId: playerUiModel.teamId,
                        teamColor: playerUiModel.teamColor, teamName: playerUiModel.teamName,
                        teamPoints: playerUiModel.teamPoints, teamGoalsDifference: playerUiModel.teamGoalsDifference,
                        name: playerUiModel.name,
                        goals: playerUiModel.goals,
                        assists: playerUiModel.assists, dribbles: playerUiModel.dribbles,
                        passes: playerUiModel.passes, shots: playerUiModel.shots, saves: playerUiModel.saves,
                        yellowCards: playerUiModel.yellowCards + 1, redCards: playerUiModel.redCards,
                        number: playerUiModel.number
                    )
                    if !uiState.uiLimited {
                        audioManager.speak(
                            text: String(format: NSLocalizedString("text_to_speech_yellow_card", comment: ""), playerUiModel.name),
                            completion: { self.audioManager.playSound(GameSounds.penaltyRealMadrid.fileName) }
                        )
                    }

                case .redCard:
                    updatedPlayer = PlayerUiModel(
                        id: playerUiModel.id, teamId: playerUiModel.teamId,
                        teamColor: playerUiModel.teamColor, teamName: playerUiModel.teamName,
                        teamPoints: playerUiModel.teamPoints, teamGoalsDifference: playerUiModel.teamGoalsDifference,
                        name: playerUiModel.name,
                        goals: playerUiModel.goals,
                        assists: playerUiModel.assists, dribbles: playerUiModel.dribbles,
                        passes: playerUiModel.passes, shots: playerUiModel.shots, saves: playerUiModel.saves,
                        yellowCards: playerUiModel.yellowCards, redCards: playerUiModel.redCards + 1,
                        number: playerUiModel.number
                    )
                    if !uiState.uiLimited {
                        audioManager.speak(
                            text: String(format: NSLocalizedString("text_to_speech_red_card", comment: ""), playerUiModel.name),
                            completion: { self.audioManager.playSound(GameSounds.penaltyRealMadrid.fileName) }
                        )
                    }
                }

                try playerRepository.updatePlayer(updatedPlayer)
                try playerHistoryRepository.updatePlayerHistory(playerId: updatedPlayer.id, option: option, value: 1)
                currentGameActions.append(PendingGameAction(
                    teamName: playerUiModel.teamName,
                    teamColor: playerUiModel.teamColor.rawValue,
                    playerName: playerUiModel.name,
                    playerNumber: playerUiModel.number,
                    actionType: option.rawValue,
                    elapsedSeconds: currentElapsedSeconds()
                ))
                try await updatePlayersBlock()
            } catch {
                snackbarMessage = "Error updating player"
            }
        }
    }

    private func onOptionPlayersAutoGoalSelected(teamId: UUID) {
        guard let liveGame = uiState.liveGameUiModel else { return }

        Task {
            do {
                var updated = liveGame
                if teamId == liveGame.leftTeamId {
                    updated = liveGame.updating(leftTeamGoals: liveGame.leftTeamGoals + 1)
                    
                    currentGameActions.append(PendingGameAction(
                        teamName: liveGame.leftTeamName,
                        teamColor: liveGame.leftTeamColor.rawValue,
                        playerName: NSLocalizedString("auto_goal", comment: ""),
                        playerNumber: nil,
                        actionType: TeamOption.goal.rawValue,
                        elapsedSeconds: currentElapsedSeconds()
                    ))
                } else if teamId == liveGame.rightTeamId {
                    updated = liveGame.updating(rightTeamGoals: liveGame.rightTeamGoals + 1)
                    
                    currentGameActions.append(PendingGameAction(
                        teamName: liveGame.rightTeamName,
                        teamColor: liveGame.rightTeamColor.rawValue,
                        playerName: NSLocalizedString("auto_goal", comment: ""),
                        playerNumber: nil,
                        actionType: TeamOption.goal.rawValue,
                        elapsedSeconds: currentElapsedSeconds()
                    ))
                }
                try liveGameRepository.updateLiveGame(updated)
                uiState.liveGameUiModel = updated
                
                
                
                if !uiState.uiLimited {
                    audioManager.speak(
                        text: NSLocalizedString("team_option_players_auto_goal", comment: ""),
                        completion: {
                            switch Int.random(in: 0..<3) {
                            case 0:
                                self.audioManager.playSound("oooi_kandai_gol")
                            case 1:
                                self.audioManager.playSound("suiii_full")
                            case 2:
                                self.audioManager.playSound("gol_gol_gol")
                            default:
                                break
                            }
                        }
                    )
                }
            } catch {
                snackbarMessage = "Error recording auto goal"
            }
        }
    }

    private func onStayTeamSelectionBottomSheetDismissed() {
        guard let liveGame = uiState.liveGameUiModel else { return }
        let ids = [liveGame.leftTeamId, liveGame.rightTeamId]

        Task {
            do {
                if let nextTeam = findNextTeam(excludingIds: ids) {
                    try await updateLiveGameRightTeam(nextTeam: nextTeam, liveGame: liveGame)
                    try await updateLiveGameBlock()
                }
            } catch {
                snackbarMessage = "Error updating game"
            }
        }
    }

    private func onLeftTeamStayClicked() {
        guard let liveGame = uiState.liveGameUiModel else { return }
        let ids = [liveGame.leftTeamId, liveGame.rightTeamId]

        Task {
            do {
                if let nextTeam = findNextTeam(excludingIds: ids) {
                    try await updateLiveGameRightTeam(nextTeam: nextTeam, liveGame: liveGame)
                    try await updateLiveGameBlock()
                }
            } catch {
                snackbarMessage = "Error updating game"
            }
        }
    }

    private func onRightTeamStayClicked() {
        guard let liveGame = uiState.liveGameUiModel else { return }
        let ids = [liveGame.leftTeamId, liveGame.rightTeamId]

        Task {
            do {
                if let nextTeam = findNextTeam(excludingIds: ids) {
                    try await updateLiveGameLeftTeam(nextTeam: nextTeam, liveGame: liveGame)
                    try await updateLiveGameBlock()
                }
            } catch {
                snackbarMessage = "Error updating game"
            }
        }
    }

    private func currentElapsedSeconds() -> Int {
        let totalSeconds = timeInMinutes * 60
        let remaining = timerMillis / 1000
        return max(0, totalSeconds - remaining)
    }

    private func saveGameHistory(_ liveGame: LiveGameUiModel) {
        let winnerTeamName: String
        if liveGame.isLeftTeamWin {
            winnerTeamName = liveGame.leftTeamName
        } else if liveGame.isRightTeamWin {
            winnerTeamName = liveGame.rightTeamName
        } else {
            winnerTeamName = ""
        }
        let entry = GameHistoryEntryModel(
            gameId: gameId,
            gameNumber: liveGame.gameCount + 1,
            leftTeamName: liveGame.leftTeamName,
            leftTeamColor: liveGame.leftTeamColor.rawValue,
            leftTeamGoals: liveGame.leftTeamGoals,
            rightTeamName: liveGame.rightTeamName,
            rightTeamColor: liveGame.rightTeamColor.rawValue,
            rightTeamGoals: liveGame.rightTeamGoals,
            winnerTeamName: winnerTeamName,
            durationSeconds: pendingGameDurationSeconds
        )
        let entryId = gameHistoryRepository.saveEntry(entry)
        for action in currentGameActions {
            let event = GameHistoryActionEventModel(
                historyEntryId: entryId,
                teamName: action.teamName,
                teamColor: action.teamColor,
                playerName: action.playerName,
                playerNumber: action.playerNumber,
                actionType: action.actionType,
                elapsedSeconds: action.elapsedSeconds
            )
            gameHistoryRepository.saveActionEvent(event)
        }
        currentGameActions.removeAll()
    }

    private func onHistoryClicked() {
        Task {
            do {
                let history = try gameHistoryRepository.getGameHistory(gameId: gameId)
                effect = .showGameHistorySheet(history: history.reversed())
            } catch {
                snackbarMessage = "Error loading history"
            }
        }
    }

    private func onFunctionClicked(_ function: GameFunction) {
        switch function {
        case .bestPlayers:
            onBestPlayersClicked()
        case .history:
            onHistoryClicked()
        case .edit:
            onEditGameClicked()
        case .clearResults:
            onClearResultsClicked()
        case .info:
            effect = .showGameInfoBottomSheet
        case .allResults:
            onAllResultsClicked()
        case .delete:
            onDeleteGameClicked()
        }
    }

    private func onBestPlayersClicked() {
        var bestPlayers: [BestPlayerUiModel] = []
        let players = uiState.playerUiModelList

        if let best = players.max(by: { lhs, rhs in
            let lhsScore = (lhs.goals * 3) + (lhs.assists * 2) + (lhs.saves * 2) + lhs.dribbles + lhs.passes + lhs.shots - lhs.yellowCards - (lhs.redCards * 3)
            let rhsScore = (rhs.goals * 3) + (rhs.assists * 2) + (rhs.saves * 2) + rhs.dribbles + rhs.passes + rhs.shots - rhs.yellowCards - (rhs.redCards * 3)
            return lhsScore < rhsScore
        }) {
            bestPlayers.append(BestPlayerUiModel(option: .bestPlayer, playerUiModel: best))
        }

        let statOptions: [(BestPlayerOption, (PlayerUiModel) -> Bool, (PlayerUiModel) -> Int)] = [
            (.goals, { $0.goals > 0 }, { $0.goals }),
            (.assists, { $0.assists > 0 }, { $0.assists }),
            (.saves, { $0.saves > 0 }, { $0.saves }),
            (.dribbles, { $0.dribbles > 0 }, { $0.dribbles }),
            (.passes, { $0.passes > 0 }, { $0.passes }),
            (.shots, { $0.shots > 0 }, { $0.shots }),
        ]

        for (option, filter, selector) in statOptions {
            if let best = players.filter(filter).max(by: { selector($0) < selector($1) }) {
                bestPlayers.append(BestPlayerUiModel(option: option, playerUiModel: best))
            }
        }

        if let aggressive = players.filter({ $0.yellowCards > 0 || $0.redCards > 0 })
            .reversed()
            .max(by: { ($0.yellowCards + ($0.redCards * 3)) < ($1.yellowCards + ($1.redCards * 3)) }) {
            bestPlayers.append(BestPlayerUiModel(option: .aggressivePlayer, playerUiModel: aggressive))
        }

        effect = .showBestPlayersBottomSheet(bestPlayers: bestPlayers)
    }

    private func onEditGameClicked() {
        if isLive {
            snackbarMessage = NSLocalizedString("update_game_snackbar_text", comment: "")
        } else {
            effect = .openUpdateGame(gameId: gameId)
        }
    }

    private func onClearResultsClicked() {
        if isLive {
            snackbarMessage = NSLocalizedString("finish_game_snackbar_text", comment: "")
        } else {
            effect = .showClearResultsConfirmationBottomSheet
        }
    }

    private func onAllResultsClicked() {
        if isLive {
            snackbarMessage = NSLocalizedString("open_game_results_snackbar_text", comment: "")
        } else {
            effect = .openGameResultsScreen(gameId: gameId)
        }
    }

    private func onDeleteGameClicked() {
        if isLive {
            snackbarMessage = NSLocalizedString("delete_game_snackbar_text", comment: "")
        } else {
            effect = .showDeleteGameConfirmationBottomSheet
        }
    }

    private func onSavePlayerResultClicked(playerResultUiModel: PlayerResultUiModel, value: Int) {
        Task {
            do {
                var player = playerResultUiModel.playerUiModel
                
                var diffs = 0
                
                switch playerResultUiModel.option {
                case .goal:
                    diffs = value - player.goals
                    player = PlayerUiModel(
                        id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                        teamName: player.teamName, teamPoints: player.teamPoints,
                        teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                        goals: value, assists: player.assists, dribbles: player.dribbles,
                        passes: player.passes, shots: player.shots, saves: player.saves,
                        yellowCards: player.yellowCards, redCards: player.redCards,
                        number: player.number
                    )
                case .assist:
                    diffs = value - player.assists
                    player = PlayerUiModel(
                        id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                        teamName: player.teamName, teamPoints: player.teamPoints,
                        teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                        goals: player.goals, assists: value, dribbles: player.dribbles,
                        passes: player.passes, shots: player.shots, saves: player.saves,
                        yellowCards: player.yellowCards, redCards: player.redCards,
                        number: player.number
                    )
                case .save:
                    diffs = value - player.saves
                    player = PlayerUiModel(
                        id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                        teamName: player.teamName, teamPoints: player.teamPoints,
                        teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                        goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                        passes: player.passes, shots: player.shots, saves: value,
                        yellowCards: player.yellowCards, redCards: player.redCards,
                        number: player.number
                    )
                case .dribble:
                    diffs = value - player.dribbles
                    player = PlayerUiModel(
                        id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                        teamName: player.teamName, teamPoints: player.teamPoints,
                        teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                        goals: player.goals, assists: player.assists, dribbles: value,
                        passes: player.passes, shots: player.shots, saves: player.saves,
                        yellowCards: player.yellowCards, redCards: player.redCards,
                        number: player.number
                    )
                case .shot:
                    diffs = value - player.shots
                    player = PlayerUiModel(
                        id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                        teamName: player.teamName, teamPoints: player.teamPoints,
                        teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                        goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                        passes: player.passes, shots: value, saves: player.saves,
                        yellowCards: player.yellowCards, redCards: player.redCards,
                        number: player.number
                    )
                case .pass:
                    diffs = value - player.passes
                    player = PlayerUiModel(
                        id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                        teamName: player.teamName, teamPoints: player.teamPoints,
                        teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                        goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                        passes: value, shots: player.shots, saves: player.saves,
                        yellowCards: player.yellowCards, redCards: player.redCards,
                        number: player.number
                    )
                case .yellowCard:
                    diffs = value - player.yellowCards
                    player = PlayerUiModel(
                        id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                        teamName: player.teamName, teamPoints: player.teamPoints,
                        teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                        goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                        passes: player.passes, shots: player.shots, saves: player.saves,
                        yellowCards: value, redCards: player.redCards,
                        number: player.number
                    )
                case .redCard:
                    diffs = value - player.redCards
                    player = PlayerUiModel(
                        id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                        teamName: player.teamName, teamPoints: player.teamPoints,
                        teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                        goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                        passes: player.passes, shots: player.shots, saves: player.saves,
                        yellowCards: player.yellowCards, redCards: value,
                        number: player.number
                    )
                }
                try playerRepository.updatePlayer(player)
                try playerHistoryRepository.updatePlayerHistory(playerId: player.id, option: playerResultUiModel.option, value: diffs)
                try await updatePlayersBlock()
                snackbarMessage = NSLocalizedString("save_success", comment: "")
            } catch {
                snackbarMessage = "Error saving player result"
            }
        }
    }

    private func onSaveTeamResultClicked(teamUiModel: TeamUiModel, value: Int) {
        Task {
            do {
                let diff = value - teamUiModel.points
                let updated = TeamUiModel(
                    id: teamUiModel.id,
                    gameId: teamUiModel.gameId,
                    name: teamUiModel.name,
                    color: teamUiModel.color,
                    games: teamUiModel.games,
                    wins: teamUiModel.wins,
                    draws: teamUiModel.draws,
                    loses: teamUiModel.loses,
                    goals: teamUiModel.goals,
                    conceded: teamUiModel.conceded,
                    points: value
                )
                try teamRepository.updateTeam(updated)
                if let model = try teamHistoryRepository.getTeamHistoryEntity(teamId: updated.id) {
                    model.points = model.points + diff
                }
                try await updateTeamsBlock()
                snackbarMessage = NSLocalizedString("save_success", comment: "")
            } catch {
                snackbarMessage = "Error saving team result"
            }
        }
    }

    private func onSaveLiveGameResultClicked(liveGameResultUiModel: LiveGameResultUiModel, value: Int) {
        guard var liveGame = uiState.liveGameUiModel else { return }

        if liveGameResultUiModel.isLeftTeam {
            liveGame = liveGame.updating(leftTeamGoals: value)
        } else {
            liveGame = liveGame.updating(rightTeamGoals: value)
        }
        uiState.liveGameUiModel = liveGame

        Task {
            do {
                try liveGameRepository.updateLiveGame(liveGame)
                snackbarMessage = NSLocalizedString("save_success", comment: "")
            } catch {
                snackbarMessage = "Error saving result"
            }
        }
    }

    func saveTimerOnExit() {
        if isLive {
            liveGameRepository.saveTimerValue(timerMillis)
        }
        stopTimer()
        backgroundDate = nil
    }

    func createAddGameViewModel(gameId: UUID) -> AddGameViewModel {
        AddGameViewModel(
            gameId: gameId,
            gameRepository: gameRepository,
            liveGameRepository: liveGameRepository,
            teamRepository: teamRepository,
            teamHistoryRepository: teamHistoryRepository,
            playerRepository: playerRepository,
            playerHistoryRepository: playerHistoryRepository
        )
    }

    func refreshData() {
        fetchGame()
    }

    func createGameResultsViewModel(gameId: UUID, modelContext: ModelContext) -> GameResultsViewModel {
        GameResultsViewModel(
            gameId: gameId,
            modelContext: modelContext
        )
    }
}
