//
//  doptepApp.swift
//  doptep
//
//  Created by Kudaibergen Alimtayev on 30.12.2025.
//

import SwiftUI
import SwiftData

@main
struct doptepApp: App {
    
    let container: ModelContainer

    init() {
        container = try! ModelContainer(
            for: GameModel.self,
            TeamModel.self,
            PlayerModel.self,
            LiveGameModel.self,
            TeamHistoryModel.self,
            PlayerHistoryModel.self
        )
    }
    
    var body: some Scene {
        WindowGroup {
            HomeScreen(viewModel: HomeViewModel(repository: GameRepository(context: container.mainContext)))
                .accentColor(AppColor.primary)
        }
        .modelContainer(container)
    }
}
