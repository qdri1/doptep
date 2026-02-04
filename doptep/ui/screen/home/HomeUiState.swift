//
//  HomeUiState.swift
//  doptep
//
//  Created by Kudaibergen Alimtayev on 30.12.2025.
//


struct HomeUiState {
    var games: [GameUiModel] = []
    var isLoading: Bool = false
    var isRefreshing: Bool = false

    /// one-shot effect
    var effect: HomeEffect?
}
