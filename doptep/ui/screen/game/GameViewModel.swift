//
//  GameViewModel.swift
//  doptep
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import SwiftData

@MainActor
final class GameViewModel: ObservableObject {

    private let gameId: UUID
    private let gameRepository: GameRepository
    private let liveGameRepository: LiveGameRepository
    private let teamRepository: TeamRepository
    private let teamHistoryRepository: TeamHistoryRepository
    private let playerRepository: PlayerRepository
    private let playerHistoryRepository: PlayerHistoryRepository
    private let audioManager: AudioManager

    @Published var uiState = GameUiState()
    @Published var effect: GameEffect? = nil
    @Published var snackbarMessage: String? = nil
    @Published var timerValue: String = "00:00"

    private var timer: Timer? = nil
    private var timerMillis: Int = 0
    private var oldTeamId: UUID = UUID()

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
        audioManager: AudioManager
    ) {
        self.gameId = gameId
        self.gameRepository = gameRepository
        self.liveGameRepository = liveGameRepository
        self.teamRepository = teamRepository
        self.teamHistoryRepository = teamHistoryRepository
        self.playerRepository = playerRepository
        self.playerHistoryRepository = playerHistoryRepository
        self.audioManager = audioManager

        fetchGame()
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
                    if lhs.teamPoints != rhs.teamPoints { return lhs.teamPoints > rhs.teamPoints }
                    if lhs.teamGoalsDifference != rhs.teamGoalsDifference { return lhs.teamGoalsDifference > rhs.teamGoalsDifference }
                    if lhs.teamName != rhs.teamName { return lhs.teamName < rhs.teamName }
                    return lhs.name < rhs.name
                }

                let liveGameUiModel = try liveGameRepository.getLiveGame(gameId: gameId)

                uiState.gameUiModel = gameUiModel
                uiState.teamUiModelList = teamList
                uiState.playerUiModelList = playerList
                uiState.liveGameUiModel = liveGameUiModel

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
                            passes: 0, shots: 0, saves: 0
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
        startTimer()

        Task {
            do {
                let updatedLiveGame = liveGame.updating(isLive: true)
                try liveGameRepository.updateLiveGame(updatedLiveGame)
                uiState.liveGameUiModel = updatedLiveGame
            } catch {
                snackbarMessage = "Error starting game"
            }
        }
    }

    private func finishGame() {
        audioManager.playSound("finish")
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
            } catch {
                snackbarMessage = "Error finishing game"
            }
        }
    }

    private func finishTeam2Game(gameUiModel: GameUiModel, liveGame: LiveGameUiModel) async throws {
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
            }
        }
    }

    private func updateLiveGameBlock() async throws {
        uiState.liveGameUiModel = try liveGameRepository.getLiveGame(gameId: gameId)
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
            if lhs.teamPoints != rhs.teamPoints { return lhs.teamPoints > rhs.teamPoints }
            if lhs.teamGoalsDifference != rhs.teamGoalsDifference { return lhs.teamGoalsDifference > rhs.teamGoalsDifference }
            if lhs.teamName != rhs.teamName { return lhs.teamName < rhs.teamName }
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
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.timerMillis -= 1000
                if self.timerMillis <= 0 {
                    self.timerMillis = 0
                }
                self.timerValue = self.formatTime(self.timerMillis)
            }
        }
    }

    private func stopTimer() {
        uiState.isTimerPlay = false
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        stopTimer()
        timerMillis = timeInMinutes * 60 * 1000
        timerValue = formatTime(timerMillis)
        liveGameRepository.clearTimerValue()
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
            .sorted { $0.name < $1.name }

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
            .sorted { $0.name < $1.name }

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
                    rightTeamGoals: 0,
                    rightTeamWinCount: 0,
                    gameCount: liveGame.gameCount,
                    isLive: liveGame.isLive
                )
                try liveGameRepository.updateLiveGame(updated)
                uiState.liveGameUiModel = updated
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
                    leftTeamGoals: 0,
                    leftTeamWinCount: 0,
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
                        passes: playerUiModel.passes, shots: playerUiModel.shots, saves: playerUiModel.saves
                    )
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

                case .assist:
                    updatedPlayer = PlayerUiModel(
                        id: playerUiModel.id, teamId: playerUiModel.teamId,
                        teamColor: playerUiModel.teamColor, teamName: playerUiModel.teamName,
                        teamPoints: playerUiModel.teamPoints, teamGoalsDifference: playerUiModel.teamGoalsDifference,
                        name: playerUiModel.name,
                        goals: playerUiModel.goals,
                        assists: playerUiModel.assists + 1, dribbles: playerUiModel.dribbles,
                        passes: playerUiModel.passes, shots: playerUiModel.shots, saves: playerUiModel.saves
                    )
                    audioManager.speak(
                        text: String(format: NSLocalizedString("text_to_speech_assist", comment: ""), playerUiModel.name),
                        completion: { self.audioManager.playSound(GameSounds.girlsApplause.fileName) }
                    )

                case .save:
                    updatedPlayer = PlayerUiModel(
                        id: playerUiModel.id, teamId: playerUiModel.teamId,
                        teamColor: playerUiModel.teamColor, teamName: playerUiModel.teamName,
                        teamPoints: playerUiModel.teamPoints, teamGoalsDifference: playerUiModel.teamGoalsDifference,
                        name: playerUiModel.name,
                        goals: playerUiModel.goals,
                        assists: playerUiModel.assists, dribbles: playerUiModel.dribbles,
                        passes: playerUiModel.passes, shots: playerUiModel.shots, saves: playerUiModel.saves + 1
                    )
                    audioManager.speak(
                        text: String(format: NSLocalizedString("text_to_speech_save", comment: ""), playerUiModel.name),
                        completion: { self.audioManager.playSound(GameSounds.goalSave.fileName) }
                    )

                case .dribble:
                    updatedPlayer = PlayerUiModel(
                        id: playerUiModel.id, teamId: playerUiModel.teamId,
                        teamColor: playerUiModel.teamColor, teamName: playerUiModel.teamName,
                        teamPoints: playerUiModel.teamPoints, teamGoalsDifference: playerUiModel.teamGoalsDifference,
                        name: playerUiModel.name,
                        goals: playerUiModel.goals,
                        assists: playerUiModel.assists, dribbles: playerUiModel.dribbles + 1,
                        passes: playerUiModel.passes, shots: playerUiModel.shots, saves: playerUiModel.saves
                    )
                    audioManager.speak(
                        text: String(format: NSLocalizedString("text_to_speech_dribble", comment: ""), playerUiModel.name),
                        completion: { self.audioManager.playSound(GameSounds.bilgeninIstepJatyr.fileName) }
                    )
                    
                case .shot:
                    updatedPlayer = PlayerUiModel(
                        id: playerUiModel.id, teamId: playerUiModel.teamId,
                        teamColor: playerUiModel.teamColor, teamName: playerUiModel.teamName,
                        teamPoints: playerUiModel.teamPoints, teamGoalsDifference: playerUiModel.teamGoalsDifference,
                        name: playerUiModel.name,
                        goals: playerUiModel.goals,
                        assists: playerUiModel.assists, dribbles: playerUiModel.dribbles,
                        passes: playerUiModel.passes, shots: playerUiModel.shots + 1, saves: playerUiModel.saves
                    )
                    audioManager.speak(
                        text: String(format: NSLocalizedString("text_to_speech_shot", comment: ""), playerUiModel.name),
                        completion: { self.audioManager.playSound(GameSounds.suiii.fileName) }
                    )
                    
                case .pass:
                    updatedPlayer = PlayerUiModel(
                        id: playerUiModel.id, teamId: playerUiModel.teamId,
                        teamColor: playerUiModel.teamColor, teamName: playerUiModel.teamName,
                        teamPoints: playerUiModel.teamPoints, teamGoalsDifference: playerUiModel.teamGoalsDifference,
                        name: playerUiModel.name,
                        goals: playerUiModel.goals,
                        assists: playerUiModel.assists, dribbles: playerUiModel.dribbles,
                        passes: playerUiModel.passes + 1, shots: playerUiModel.shots, saves: playerUiModel.saves
                    )
                    audioManager.speak(
                        text: String(format: NSLocalizedString("text_to_speech_pass", comment: ""), playerUiModel.name),
                        completion: { self.audioManager.playSound(GameSounds.stadiumApplause.fileName) }
                    )
                }

                try playerRepository.updatePlayer(updatedPlayer)
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
                } else if teamId == liveGame.rightTeamId {
                    updated = liveGame.updating(rightTeamGoals: liveGame.rightTeamGoals + 1)
                }
                try liveGameRepository.updateLiveGame(updated)
                uiState.liveGameUiModel = updated
                audioManager.speak(text: NSLocalizedString("team_option_players_auto_goal", comment: ""))
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

    private func onFunctionClicked(_ function: GameFunction) {
        switch function {
        case .bestPlayers:
            onBestPlayersClicked()
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
            let lhsScore = (lhs.goals * 3) + (lhs.assists * 2) + (lhs.saves * 2) + lhs.dribbles + lhs.passes + lhs.shots
            let rhsScore = (rhs.goals * 3) + (rhs.assists * 2) + (rhs.saves * 2) + rhs.dribbles + rhs.passes + rhs.shots
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
                switch playerResultUiModel.option {
                case .goal:
                    player = PlayerUiModel(
                        id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                        teamName: player.teamName, teamPoints: player.teamPoints,
                        teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                        goals: value, assists: player.assists, dribbles: player.dribbles,
                        passes: player.passes, shots: player.shots, saves: player.saves
                    )
                case .assist:
                    player = PlayerUiModel(
                        id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                        teamName: player.teamName, teamPoints: player.teamPoints,
                        teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                        goals: player.goals, assists: value, dribbles: player.dribbles,
                        passes: player.passes, shots: player.shots, saves: player.saves
                    )
                case .save:
                    player = PlayerUiModel(
                        id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                        teamName: player.teamName, teamPoints: player.teamPoints,
                        teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                        goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                        passes: player.passes, shots: player.shots, saves: value
                    )
                case .dribble:
                    player = PlayerUiModel(
                        id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                        teamName: player.teamName, teamPoints: player.teamPoints,
                        teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                        goals: player.goals, assists: player.assists, dribbles: value,
                        passes: player.passes, shots: player.shots, saves: player.saves
                    )
                case .shot:
                    player = PlayerUiModel(
                        id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                        teamName: player.teamName, teamPoints: player.teamPoints,
                        teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                        goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                        passes: player.passes, shots: value, saves: player.saves
                    )
                case .pass:
                    player = PlayerUiModel(
                        id: player.id, teamId: player.teamId, teamColor: player.teamColor,
                        teamName: player.teamName, teamPoints: player.teamPoints,
                        teamGoalsDifference: player.teamGoalsDifference, name: player.name,
                        goals: player.goals, assists: player.assists, dribbles: player.dribbles,
                        passes: value, shots: player.shots, saves: player.saves
                    )
                }
                try playerRepository.updatePlayer(player)
                try await updatePlayersBlock()
                snackbarMessage = NSLocalizedString("save_success", comment: "")
            } catch {
                snackbarMessage = "Error saving player result"
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
