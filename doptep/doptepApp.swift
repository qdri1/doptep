//
//  doptepApp.swift
//  doptep
//
//  Created by Kudaibergen Alimtayev on 30.12.2025.
//

import SwiftUI
import SwiftData
import RevenueCat

@main
struct doptepApp: App {

    let container: ModelContainer
    @StateObject private var languageManager = LanguageManager()

    init() {
        container = try! ModelContainer(
            for: GameModel.self,
            TeamModel.self,
            PlayerModel.self,
            LiveGameModel.self,
            TeamHistoryModel.self,
            PlayerHistoryModel.self
        )
        RevenueCatManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .id(languageManager.currentLanguage)
                .accentColor(AppColor.primary)
                .preferredColorScheme(.light)
                .environmentObject(languageManager)
        }
        .modelContainer(container)
    }
}
