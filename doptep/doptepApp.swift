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
    @State private var showLanguagePicker = false
    @State private var showUpdateDialog = false
    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase

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
        RevenueCatManager.shared.configure()
        RemoteConfigManager.shared.configureAndActivate()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
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
                    .onChange(of: scenePhase) { _, phase in
                        if phase == .active {
                            BillingManager.shared.checkAndUpdateOnedayExpiration()
                        }
                    }

                if showSplash {
                    SplashView(onFinished: finishSplash)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onChange(of: showLanguagePicker) { _, isShown in
                if !isShown {
                    AudioManager.shared.requestNotificationPermission()
                }
            }
        }
        .modelContainer(container)
    }

    private func finishSplash() {
        guard showSplash else { return }
        withAnimation(.easeOut(duration: 0.3)) {
            showSplash = false
        }

        let needsLanguage = UserDefaults.standard.string(forKey: "app_language") == nil
        if needsLanguage {
            showLanguagePicker = true
            return
        }

        AudioManager.shared.requestNotificationPermission()

        let currentBuild = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1") ?? 1
        showUpdateDialog = RemoteConfigManager.shared.isAppUpdateRequired
            && RemoteConfigManager.shared.appVersionCode > currentBuild
    }
}
