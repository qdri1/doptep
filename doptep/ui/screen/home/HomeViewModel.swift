//
//  HomeViewModel.swift
//  doptep
//
//  Created by Kudaibergen Alimtayev on 30.12.2025.
//


import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {

    @Published var uiState = HomeUiState()

    private let repository: GameRepository

    init(repository: GameRepository) {
        self.repository = repository
        fetchGames()
    }

    // MARK: - Actions

    func send(_ action: HomeAction) {
        switch action {
        case .onRefreshed:
            fetchGames(isRefreshing: true)

        case .onRefreshIconClicked:
            fetchGames()

        case .onGameCardClicked(let id):
            uiState.effect = .openGameScreen(id)

        case .onAddGameButtonClicked:
            uiState.effect = .openAddGameScreen

        case .onInterceptionNavigationResult:
            fetchGames()
        }
    }

    // MARK: - Private

    private func fetchGames(isRefreshing: Bool = false) {
        Task {
            if isRefreshing {
                uiState.isRefreshing = true
            } else {
                uiState.isLoading = true
            }

            try? await Task.sleep(nanoseconds: 500_000_000)

            let games = (try? repository.getGames()) ?? []
            uiState.games = games.sorted { $0.modifiedTime > $1.modifiedTime }

            uiState.isLoading = false
            uiState.isRefreshing = false
        }
    }
}
