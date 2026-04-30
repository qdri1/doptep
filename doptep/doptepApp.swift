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
import FirebaseCrashlytics

@main
struct doptepApp: App {

    let container: ModelContainer
    @StateObject private var languageManager = LanguageManager()
    @State private var showLanguagePicker = UserDefaults.standard.string(forKey: "app_language") == nil
    @State private var showUpdateDialog = false

    init() {
        container = try! ModelContainer(
            for: GameModel.self,
            TeamModel.self,
            PlayerModel.self,
            LiveGameModel.self,
            TeamHistoryModel.self,
            PlayerHistoryModel.self,
            GameHistoryEntryModel.self,
            GameHistoryActionEventModel.self
        )
        FirebaseApp.configure()
        AudioManager.shared.requestNotificationPermission()
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
                .alert(NSLocalizedString("update_required_title", comment: ""), isPresented: $showUpdateDialog) {
                    Button(NSLocalizedString("update_button_update", comment: "")) {
                        if let url = URL(string: "https://apps.apple.com/app/id6758735315") {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button(NSLocalizedString("update_button_skip", comment: ""), role: .cancel) {}
                }
                .onAppear {
                    let currentBuild = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1") ?? 1
                    showUpdateDialog = !showLanguagePicker && RemoteConfigManager.shared.isAppUpdateRequired
                        && RemoteConfigManager.shared.appVersionCode > currentBuild
                }
        }
        .modelContainer(container)
    }
}
