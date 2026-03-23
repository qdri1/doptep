//
//  doptepApp.swift
//  doptep
//
//  Created by Kudaibergen Alimtayev on 30.12.2025.
//

import SwiftUI
import SwiftData
import RevenueCat
import FirebaseCore

@main
struct doptepApp: App {

    let container: ModelContainer
    @StateObject private var languageManager = LanguageManager()
    @State private var showLanguagePicker = UserDefaults.standard.string(forKey: "app_language") == nil

    init() {
        container = try! ModelContainer(
            for: GameModel.self,
            TeamModel.self,
            PlayerModel.self,
            LiveGameModel.self,
            TeamHistoryModel.self,
            PlayerHistoryModel.self
        )
        FirebaseApp.configure()
        RevenueCatManager.shared.configure()
        RemoteConfigManager.shared.configureAndActivate()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .id(languageManager.currentLanguage)
                .accentColor(AppColor.primary)
                .preferredColorScheme(.light)
                .environmentObject(languageManager)
                .onChange(of: languageManager.currentLanguage) { _, language in
                    RevenueCatManager.shared.updateLocale(language)
                    AudioManager.shared.setLanguage(language)
                }
                .sheet(isPresented: $showLanguagePicker) {
                    LanguageSelectionSheet(showCheckmark: false)
                        .environmentObject(languageManager)
                        .presentationDetents([.medium])
                }
        }
        .modelContainer(container)
    }
}
