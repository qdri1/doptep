//
//  SettingsScreen.swift
//  doptep
//

import SwiftUI
import RevenueCat
import UserNotifications

private let appStoreUrl = "https://apps.apple.com/app/id6758735315"

struct SettingsScreen: View {
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var billingManager = BillingManager.shared

    @State private var showLanguageSelection = false
    @State private var showShareSheet = false
    @State private var navigateToActivation = false
    @State private var showPaywall = false
    @State private var pendingNavigationAfterPaywall = false
    @State private var showActivationCodeDialog = false
    @State private var showActivationSuccessAlert = false
    @State private var showActivationErrorAlert = false
    @State private var versionTapCount = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(SettingsItemType.allCases, id: \.self) { item in
                    SettingsItemRow(item: item, title: title(for: item)) {
                        viewModel.action(.onSettingsItemClicked(item: item))
                    }
                }

                NotificationSettingsRow()

                if !viewModel.telegramUrl.isEmpty {
                    SettingsCustomRow(
                        iconName: "paperplane",
                        title: "Telegram"
                    ) {
                        viewModel.onTelegramClicked()
                    }
                }

                if !viewModel.whatsappUrl.isEmpty {
                    SettingsCustomRow(
                        iconName: "message",
                        title: "WhatsApp"
                    ) {
                        viewModel.onWhatsappClicked()
                    }
                }

                // Version Info
                Text("\(NSLocalizedString("settings_version", comment: "")): \(Bundle.main.appVersion)")
                    .font(.labelSmall)
                    .foregroundColor(AppColor.outline)
                    .padding(.top, 12)
                    .onTapGesture {
                        versionTapCount += 1
                        if versionTapCount >= 7 {
                            versionTapCount = 0
                            showActivationCodeDialog = true
                        }
                    }
            }
            .padding(16)
        }
        .background(AppColor.background)
        .onChange(of: viewModel.effect) { _, effect in
            guard let effect = effect else { return }
            handleEffect(effect)
            viewModel.clearEffect()
        }
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionSheet()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [appStoreUrl])
        }
        .navigationDestination(isPresented: $navigateToActivation) {
            ActivationScreen()
                .toolbar(.hidden, for: .tabBar)
        }
        .navigationDestination(isPresented: $showPaywall) {
            PaywallScreen {
                pendingNavigationAfterPaywall = true
                showPaywall = false
            }
            .toolbar(.hidden, for: .tabBar)
        }
        .onChange(of: showPaywall) { _, isShown in
            // After a purchase the paywall is popped first, then the activation screen is pushed.
            if !isShown && pendingNavigationAfterPaywall {
                pendingNavigationAfterPaywall = false
                navigateToActivation = true
            }
        }
        .sheet(isPresented: $showActivationCodeDialog) {
            ActivationCodeSheet { code in
                showActivationCodeDialog = false
                viewModel.action(.onActivationCodeSubmitted(code: code))
            }
            .presentationDetents([.height(200)])
        }
        .alert(NSLocalizedString("activation_code_success", comment: ""), isPresented: $showActivationSuccessAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert(NSLocalizedString("activation_code_error", comment: ""), isPresented: $showActivationErrorAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    private func title(for item: SettingsItemType) -> String {
        if item == .activation && !billingManager.billingType.isPremium {
            return NSLocalizedString("settings_item_activate_full", comment: "")
        }
        return item.displayName
    }

    private func handleEffect(_ effect: SettingsEffect) {
        switch effect {
        case .showSelectLanguage:
            showLanguageSelection = true

        case .share:
            showShareSheet = true

        case .openAppStore:
            if let url = URL(string: appStoreUrl) {
                UIApplication.shared.open(url)
            }

        case .openTelegram(let url):
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }

        case .openWhatsapp(let url):
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }

        case .openActivationScreen:
            navigateToActivation = true

        case .showPaywall:
            showPaywall = true

        case .activationSuccess:
            showActivationSuccessAlert = true

        case .activationError:
            showActivationErrorAlert = true
        }
    }
}

// MARK: - Settings Item Row

struct SettingsItemRow: View {
    let item: SettingsItemType
    var title: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: item.iconName)
                    .font(.bodySmall)

                Text(title ?? item.displayName)
                    .font(.bodySmall)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.labelMedium)
                    .foregroundColor(AppColor.onSurfaceVariant)
            }
            .foregroundColor(AppColor.onSurface)
            .padding(16)
            .background(AppColor.surface)
            .cornerRadius(16)
        }
    }
}

// MARK: - Notification Settings Row

struct NotificationSettingsRow: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var status: UNAuthorizationStatus = .notDetermined

    private var isEnabled: Bool {
        status == .authorized || status == .provisional || status == .ephemeral
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell")
                .font(.bodySmall)

            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString("settings_item_notifications", comment: ""))
                    .font(.bodySmall)

                Text(NSLocalizedString("settings_notifications_desc", comment: ""))
                    .font(.labelSmall)
                    .foregroundColor(AppColor.outline)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { _ in onToggleClicked() }
            ))
            .labelsHidden()
            .tint(AppColor.primary)
        }
        .foregroundColor(AppColor.onSurface)
        .padding(16)
        .background(AppColor.surface)
        .cornerRadius(16)
        .onAppear {
            refreshStatus()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refreshStatus()
            }
        }
    }

    private func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                status = settings.authorizationStatus
            }
        }
    }

    private func onToggleClicked() {
        if status == .notDetermined {
            UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert]) { _, _ in
                refreshStatus()
            }
        } else if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Custom Settings Row

struct SettingsCustomRow: View {
    let iconName: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.bodySmall)

                Text(title)
                    .font(.bodySmall)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.labelMedium)
                    .foregroundColor(AppColor.onSurfaceVariant)
            }
            .foregroundColor(AppColor.onSurface)
            .padding(16)
            .background(AppColor.surface)
            .cornerRadius(16)
        }
    }
}

// MARK: - Activation Code Sheet

struct ActivationCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    let onConfirm: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(NSLocalizedString("activation_code_dialog_title", comment: ""))
                .font(.bodyMedium)
                .foregroundColor(AppColor.onSurface)
                .padding(.top, 16)

            TextField(NSLocalizedString("activation_code_dialog_hint", comment: ""), text: $code)
                .font(.bodySmall)
                .padding(12)
                .background(AppColor.background)
                .cornerRadius(12)
                .padding(.horizontal, 16)

            HStack(spacing: 12) {
                Button(NSLocalizedString("activation_code_button_cancel", comment: "")) {
                    dismiss()
                }
                .font(.bodySmall)
                .foregroundColor(AppColor.onSurfaceVariant)
                .frame(maxWidth: .infinity)

                Button(NSLocalizedString("activation_code_button_confirm", comment: "")) {
                    onConfirm(code)
                }
                .font(.bodySmall)
                .foregroundColor(AppColor.primary)
                .frame(maxWidth: .infinity)
                .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(AppColor.surface)
    }
}

// MARK: - Language Selection Sheet

struct LanguageSelectionSheet: View {
    var showCheckmark: Bool = true
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(NSLocalizedString("choose_language", comment: ""))
                    .font(.bodyMedium)
                    .foregroundColor(AppColor.onSurface)
            }
            .padding(16)

            Divider()
                .frame(height: 1)
                .overlay(AppColor.background)

            languageRow(title: "Қазақша", language: "kk-KZ")
            languageRow(title: "Русский", language: "ru")
            languageRow(title: "English", language: "en")

            Spacer()
        }
        .background(AppColor.surface)
    }

    private func languageRow(title: String, language: String) -> some View {
        Button {
            languageManager.setLanguage(language)
            dismiss()
        } label: {
            HStack {
                Text(title)
                    .font(.bodySmall)
                    .foregroundColor(AppColor.onSurface)

                Spacer()

                if showCheckmark && languageManager.currentLanguage == language {
                    Image(systemName: "checkmark")
                        .foregroundColor(AppColor.primary)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
