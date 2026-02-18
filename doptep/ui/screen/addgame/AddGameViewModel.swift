//
//  AddGameViewModel.swift
//  doptep
//

import Foundation
import SwiftUI

private let defaultTimeInMinutes = 7
private let defaultTabIndex = 0

enum ScreenStateType {
    case add
    case update
}

@MainActor
final class AddGameViewModel: ObservableObject {

    private let gameId: UUID?
    private let gameRepository: GameRepository
    private let liveGameRepository: LiveGameRepository
    private let teamRepository: TeamRepository
    private let teamHistoryRepository: TeamHistoryRepository
    private let playerRepository: PlayerRepository
    private let playerHistoryRepository: PlayerHistoryRepository

    @Published var screenStateType: ScreenStateType = .add
    @Published var gameNameFieldState: String = ""
    @Published var timeInMinuteFieldState: String = ""
    @Published var gameFormatState: GameFormat = .format5x5
    @Published var teamQuantityState: TeamQuantity = .team3
    @Published var gameRuleState: GameRule = GameRuleTeam3.only2Games
    @Published var selectedTeamTabIndex: Int = defaultTabIndex

    @Published var teamColors: [TeamColor] = []
    @Published var teamNameFields: [String] = []
    @Published var playersTextFields: [[String]] = []

    @Published var effect: AddGameEffect? = nil
    @Published var snackbarMessage: String? = nil

    private var gameUiModel: GameUiModel? = nil
    private var teamUiModelList: [TeamUiModel] = []
    private var playerUiModelList: [[PlayerUiModel]] = []

    init(
        gameId: UUID? = nil,
        gameRepository: GameRepository,
        liveGameRepository: LiveGameRepository,
        teamRepository: TeamRepository,
        teamHistoryRepository: TeamHistoryRepository,
        playerRepository: PlayerRepository,
        playerHistoryRepository: PlayerHistoryRepository
    ) {
        self.gameId = gameId
        self.gameRepository = gameRepository
        self.liveGameRepository = liveGameRepository
        self.teamRepository = teamRepository
        self.teamHistoryRepository = teamHistoryRepository
        self.playerRepository = playerRepository
        self.playerHistoryRepository = playerHistoryRepository

        screenStateType = gameId == nil ? .add : .update
        initializeTeamData()
        fetchGame()
    }

    private func initializeTeamData() {
        let quantity = teamQuantityState.rawValue
        teamColors = (0..<quantity).map { TeamColor.allCases[$0 % TeamColor.allCases.count] }
        teamNameFields = Array(repeating: "", count: quantity)
        playersTextFields = (0..<quantity).map { _ in
            Array(repeating: "", count: gameFormatState.playerQuantity)
        }
    }

    func send(_ action: AddGameAction) {
        switch action {
        case .closeScreen:
            effect = .closeScreen
        case .onGameTextValueChanged(let value):
            gameNameFieldState = value
        case .onTimeTextValueChanged(let value):
            timeInMinuteFieldState = value
        case .onGameFormatSelected(let format):
            onGameFormatSelected(format)
        case .onTeamQuantitySelected(let teamQuantity):
            onTeamQuantitySelected(teamQuantity)
        case .onGameRuleSelected(let rule):
            gameRuleState = rule
        case .onTeamTabClicked(let tabIndex):
            selectedTeamTabIndex = tabIndex
        case .onTeamColorClicked:
            effect = .showColorsBottomSheet
        case .onTeamColorSelected(let color):
            onTeamColorSelected(color)
        case .onTeamNameValueChanged(let tabIndex, let value):
            onTeamNameValueChanged(tabIndex: tabIndex, value: value)
        case .onPlayerNameValueChanged(let tabIndex, let fieldIndex, let value):
            onPlayerNameValueChanged(tabIndex: tabIndex, fieldIndex: fieldIndex, value: value)
        case .onAddPlayerClicked(let tabIndex):
            addPlayerFieldToTab(tabIndex: tabIndex)
        case .onFinishClicked:
            onFinishClicked()
        }
    }

    private func fetchGame() {
        guard let gameId = gameId else { return }

        Task {
            do {
                if let gameUiModel = try gameRepository.getGame(id: gameId) {
                    self.gameUiModel = gameUiModel
                    self.gameNameFieldState = gameUiModel.name
                    self.timeInMinuteFieldState = "\(gameUiModel.timeInMinutes)"
                    self.gameFormatState = gameUiModel.gameFormat
                    self.teamQuantityState = gameUiModel.teamQuantity
                    self.gameRuleState = gameUiModel.gameRule

                    let teams = try teamRepository.getTeams(gameId: gameUiModel.id).sorted { $0.name < $1.name }
                    self.teamUiModelList = teams
                    self.teamColors = teams.map { $0.color }
                    self.teamNameFields = teams.map { $0.name }

                    var allPlayers: [[PlayerUiModel]] = []
                    var allPlayerNames: [[String]] = []
                    for team in teams {
                        let players = try playerRepository.getPlayers(teamId: team.id).sorted { $0.name < $1.name }
                        allPlayers.append(players)
                        allPlayerNames.append(players.map { $0.name })
                    }
                    self.playerUiModelList = allPlayers
                    self.playersTextFields = allPlayerNames
                }
            } catch {
                snackbarMessage = "Error loading game"
            }
        }
    }

    private func onGameFormatSelected(_ format: GameFormat) {
        gameFormatState = format
        let quantity = teamQuantityState.rawValue
        playersTextFields = (0..<quantity).map { _ in
            Array(repeating: "", count: format.playerQuantity)
        }
    }

    private func onTeamQuantitySelected(_ teamQuantity: TeamQuantity) {
        if selectedTeamTabIndex >= teamQuantity.rawValue {
            selectedTeamTabIndex = defaultTabIndex
        }
        teamQuantityState = teamQuantity

        switch teamQuantity {
        case .team2:
            gameRuleState = GameRuleTeam2.afterTimeChangeSide
        case .team3:
            gameRuleState = GameRuleTeam3.only2Games
        case .team4:
            gameRuleState = GameRuleTeam4.only3Games
        }

        let quantity = teamQuantity.rawValue
        teamColors = (0..<quantity).map { TeamColor.allCases[$0 % TeamColor.allCases.count] }
        teamNameFields = Array(repeating: "", count: quantity)
        playersTextFields = (0..<quantity).map { _ in
            Array(repeating: "", count: gameFormatState.playerQuantity)
        }
    }

    private func onTeamColorSelected(_ color: TeamColor) {
        guard selectedTeamTabIndex < teamColors.count else { return }
        teamColors[selectedTeamTabIndex] = color
    }

    private func onTeamNameValueChanged(tabIndex: Int, value: String) {
        guard tabIndex < teamNameFields.count else { return }
        teamNameFields[tabIndex] = value
    }

    private func onPlayerNameValueChanged(tabIndex: Int, fieldIndex: Int, value: String) {
        guard tabIndex < playersTextFields.count,
              fieldIndex < playersTextFields[tabIndex].count else { return }
        playersTextFields[tabIndex][fieldIndex] = value
    }

    private func addPlayerFieldToTab(tabIndex: Int) {
        guard tabIndex < playersTextFields.count else { return }
        playersTextFields[tabIndex].append("")
    }

    private func onFinishClicked() {
        guard checkRequiredFields() else { return }

        Task {
            switch screenStateType {
            case .add:
                await addGame()
            case .update:
                await updateGame()
            }
        }
    }

    private func addGame() async {
        do {
            let ruleName: String
            switch gameRuleState {
            case let rule as GameRuleTeam2:
                ruleName = rule.rawValue
            case let rule as GameRuleTeam3:
                ruleName = rule.rawValue
            case let rule as GameRuleTeam4:
                ruleName = rule.rawValue
            default:
                ruleName = ""
            }

            let gameModel = GameModel(
                name: gameNameFieldState.trimmingCharacters(in: .whitespaces),
                format: gameFormatState.rawValue,
                teamQuantity: teamQuantityState.rawValue,
                rule: ruleName,
                timeInMinutes: Int(timeInMinuteFieldState) ?? defaultTimeInMinutes
            )
            gameRepository.saveGame(gameModel)
            let newGameId = gameModel.id

            var savedTeamIds: [UUID] = []

            for (index, teamName) in teamNameFields.enumerated() {
                let teamModel = TeamModel(
                    gameId: newGameId,
                    name: teamName.trimmingCharacters(in: .whitespaces),
                    color: teamColors[safe: index]?.rawValue ?? TeamColor.red.rawValue
                )
                let teamId = teamRepository.saveTeam(teamModel)
                savedTeamIds.append(teamId)

                let teamHistory = teamModel.toTeamHistoryModel()
                teamHistoryRepository.saveTeamHistory(teamHistory)

                if let players = playersTextFields[safe: index] {
                    for playerName in players where !playerName.isEmpty {
                        let playerModel = PlayerModel(
                            teamId: teamId,
                            name: playerName.trimmingCharacters(in: .whitespaces)
                        )
                        let _ = playerRepository.savePlayer(playerModel)
                        let playerHistory = playerModel.toPlayerHistoryModel()
                        playerHistoryRepository.savePlayerHistory(playerHistory)
                    }
                }
            }

            let teams = try teamRepository.getTeams(gameId: newGameId)
            let leftTeam = teams[safe: 0]
            let rightTeam = teams[safe: 1]

            let liveGameModel = LiveGameModel(
                gameId: newGameId,
                leftTeamId: leftTeam?.id ?? UUID(),
                leftTeamName: leftTeam?.name ?? "",
                leftTeamColor: leftTeam?.color.rawValue ?? TeamColor.red.rawValue,
                rightTeamId: rightTeam?.id ?? UUID(),
                rightTeamName: rightTeam?.name ?? "",
                rightTeamColor: rightTeam?.color.rawValue ?? TeamColor.blue.rawValue
            )
            let _ = liveGameRepository.saveLiveGame(liveGameModel)

            effect = .openGameScreen(gameId: newGameId)
        } catch {
            snackbarMessage = "Error creating game"
        }
    }

    private func updateGame() async {
        guard let gameId = gameId, let gameUiModel = gameUiModel else { return }

        do {
            // Update game name and time
            let updatedGame = GameUiModel(
                id: gameUiModel.id,
                name: gameNameFieldState.trimmingCharacters(in: .whitespaces),
                gameFormat: gameUiModel.gameFormat,
                teamQuantity: gameUiModel.teamQuantity,
                gameRule: gameUiModel.gameRule,
                timeInMinutes: Int(timeInMinuteFieldState) ?? defaultTimeInMinutes,
                modifiedTime: gameUiModel.modifiedTime
            )
            try gameRepository.updateGame(updatedGame)

            // Update teams and players
            for (teamIndex, teamName) in teamNameFields.enumerated() {
                guard let teamUiModel = teamUiModelList[safe: teamIndex] else { continue }

                let updatedTeam = TeamUiModel(
                    id: teamUiModel.id,
                    gameId: teamUiModel.gameId,
                    name: teamName.trimmingCharacters(in: .whitespaces),
                    color: teamColors[safe: teamIndex] ?? .red,
                    games: teamUiModel.games,
                    wins: teamUiModel.wins,
                    draws: teamUiModel.draws,
                    loses: teamUiModel.loses,
                    goals: teamUiModel.goals,
                    conceded: teamUiModel.conceded,
                    points: teamUiModel.points
                )
                try teamRepository.updateTeam(updatedTeam)

                if let historyTeam = try teamHistoryRepository.getTeamHistory(teamId: teamUiModel.id) {
                    let updatedHistory = TeamUiModel(
                        id: historyTeam.id,
                        gameId: historyTeam.gameId,
                        name: teamName.trimmingCharacters(in: .whitespaces),
                        color: teamColors[safe: teamIndex] ?? .red,
                        games: historyTeam.games,
                        wins: historyTeam.wins,
                        draws: historyTeam.draws,
                        loses: historyTeam.loses,
                        goals: historyTeam.goals,
                        conceded: historyTeam.conceded,
                        points: historyTeam.points
                    )
                    try teamHistoryRepository.updateTeamHistory(updatedHistory)
                }

                // Update existing players
                let existingPlayers = playerUiModelList[safe: teamIndex] ?? []
                let newPlayerNames = playersTextFields[safe: teamIndex] ?? []

                for (playerIndex, playerName) in newPlayerNames.enumerated() {
                    let trimmedName = playerName.trimmingCharacters(in: .whitespaces)

                    if let existingPlayer = existingPlayers[safe: playerIndex] {
                        // Update existing player
                        
                        if trimmedName.isEmpty {
                            try playerRepository.deletePlayer(id: existingPlayer.id)
                        } else {
                            if trimmedName != existingPlayer.name {
                                try playerRepository.deletePlayer(id: existingPlayer.id)
                                
                                let newPlayer = PlayerModel(
                                    teamId: teamUiModel.id,
                                    name: trimmedName,
                                    goals: existingPlayer.goals,
                                    assists: existingPlayer.assists,
                                    dribbles: existingPlayer.dribbles,
                                    passes: existingPlayer.passes,
                                    shots: existingPlayer.shots,
                                    saves: existingPlayer.saves
                                )
                                let _ = playerRepository.savePlayer(newPlayer)
                                
                                if let historyPlayer = try playerHistoryRepository.getPlayerHistory(teamId: newPlayer.teamId, playerName: newPlayer.name) {
                                    try playerHistoryRepository.deletePlayerHistory(playerId: historyPlayer.id)
                                    
                                    let newPlayerHistory = PlayerModel(
                                        id: newPlayer.id,
                                        teamId: newPlayer.teamId,
                                        name: newPlayer.name,
                                        goals: historyPlayer.goals,
                                        assists: historyPlayer.assists,
                                        dribbles: historyPlayer.dribbles,
                                        passes: historyPlayer.passes,
                                        shots: historyPlayer.shots,
                                        saves: historyPlayer.saves
                                    )
                                    playerHistoryRepository.savePlayerHistory(newPlayerHistory.toPlayerHistoryModel())
                                } else {
                                    let newPlayerHistory = PlayerModel(
                                        id: newPlayer.id,
                                        teamId: newPlayer.teamId,
                                        name: newPlayer.name,
                                        goals: 0,
                                        assists: 0,
                                        dribbles: 0,
                                        passes: 0,
                                        shots: 0,
                                        saves: 0
                                    )
                                    playerHistoryRepository.savePlayerHistory(newPlayerHistory.toPlayerHistoryModel())
                                }
                            }
                        }
                    } else {
                        // Add new player
                        let newPlayer = PlayerModel(
                            teamId: teamUiModel.id,
                            name: trimmedName
                        )
                        let _ = playerRepository.savePlayer(newPlayer)
                        
                        if let historyPlayer = try playerHistoryRepository.getPlayerHistory(teamId: newPlayer.teamId, playerName: newPlayer.name) {
                            try playerHistoryRepository.deletePlayerHistory(playerId: historyPlayer.id)
                            
                            let newPlayerHistory = PlayerModel(
                                id: newPlayer.id,
                                teamId: newPlayer.teamId,
                                name: newPlayer.name,
                                goals: historyPlayer.goals,
                                assists: historyPlayer.assists,
                                dribbles: historyPlayer.dribbles,
                                passes: historyPlayer.passes,
                                shots: historyPlayer.shots,
                                saves: historyPlayer.saves
                            )
                            playerHistoryRepository.savePlayerHistory(newPlayerHistory.toPlayerHistoryModel())
                        } else {
                            let newPlayerHistory = PlayerModel(
                                id: newPlayer.id,
                                teamId: newPlayer.teamId,
                                name: newPlayer.name,
                                goals: 0,
                                assists: 0,
                                dribbles: 0,
                                passes: 0,
                                shots: 0,
                                saves: 0
                            )
                            playerHistoryRepository.savePlayerHistory(newPlayerHistory.toPlayerHistoryModel())
                        }
                    }
                }
            }

            // Update live game with new team names and colors
            if let liveGame = try liveGameRepository.getLiveGame(gameId: gameId) {
                let teams = try teamRepository.getTeams(gameId: gameId)
                let leftTeam = teams.first { $0.id == liveGame.leftTeamId }
                let rightTeam = teams.first { $0.id == liveGame.rightTeamId }

                let updatedLiveGame = LiveGameUiModel(
                    id: liveGame.id,
                    gameId: liveGame.gameId,
                    leftTeamId: liveGame.leftTeamId,
                    leftTeamName: leftTeam?.name ?? liveGame.leftTeamName,
                    leftTeamColor: leftTeam?.color ?? liveGame.leftTeamColor,
                    leftTeamGoals: liveGame.leftTeamGoals,
                    leftTeamWinCount: liveGame.leftTeamWinCount,
                    rightTeamId: liveGame.rightTeamId,
                    rightTeamName: rightTeam?.name ?? liveGame.rightTeamName,
                    rightTeamColor: rightTeam?.color ?? liveGame.rightTeamColor,
                    rightTeamGoals: liveGame.rightTeamGoals,
                    rightTeamWinCount: liveGame.rightTeamWinCount,
                    gameCount: liveGame.gameCount,
                    isLive: liveGame.isLive
                )
                try liveGameRepository.updateLiveGame(updatedLiveGame)
            }

            effect = .closeScreenWithResult
        } catch {
            snackbarMessage = "Error updating game"
        }
    }

    private func checkRequiredFields() -> Bool {
        if gameNameFieldState.isEmpty {
            snackbarMessage = NSLocalizedString("game_name_empty_text", comment: "")
            return false
        }
        if timeInMinuteFieldState.isEmpty {
            snackbarMessage = NSLocalizedString("game_time_empty_text", comment: "")
            return false
        }
        if teamNameFields.contains(where: { $0.isEmpty }) {
            snackbarMessage = NSLocalizedString("team_name_empty_text", comment: "")
            return false
        }
        return true
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension GameUiModel {
    func toGameModel() -> GameModel {
        let ruleName: String
        switch gameRule {
        case let rule as GameRuleTeam2:
            ruleName = rule.rawValue
        case let rule as GameRuleTeam3:
            ruleName = rule.rawValue
        case let rule as GameRuleTeam4:
            ruleName = rule.rawValue
        default:
            ruleName = ""
        }

        return GameModel(
            name: name,
            format: gameFormat.rawValue,
            teamQuantity: teamQuantity.rawValue,
            rule: ruleName,
            timeInMinutes: timeInMinutes
        )
    }
}

