//
//  SettingsScreen.swift
//  doptep
//

import SwiftUI
import RevenueCat
import RevenueCatUI

private let appStoreUrl = "https://apps.apple.com/app/id6758735315"

struct SettingsScreen: View {
    @StateObject private var viewModel = SettingsViewModel()

    @State private var showLanguageSelection = false
    @State private var showShareSheet = false
    @State private var navigateToActivation = false
    @State private var showPaywall = false
    @State private var showNoEntitlementAlert = false
    @State private var restoreFailureMessage: String?
    @State private var showActivationCodeDialog = false
    @State private var showActivationSuccessAlert = false
    @State private var showActivationErrorAlert = false
    @State private var versionTapCount = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(SettingsItemType.allCases, id: \.self) { item in
                    SettingsItemRow(item: item) {
                        viewModel.action(.onSettingsItemClicked(item: item))
                    }
                }

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
        .sheet(isPresented: $showPaywall) {
            RevenueCatUI.PaywallView()
                .onPurchaseCompleted { customerInfo in
                    let success = RevenueCatManager.shared.updateBillingType(from: customerInfo)
                    if success {
                        showPaywall = false
                        navigateToActivation = true
                    } else {
                        showNoEntitlementAlert = true
                    }
                }
                .onRestoreCompleted { customerInfo in
                    let success = RevenueCatManager.shared.updateBillingType(from: customerInfo)
                    if success {
                        showPaywall = false
                        navigateToActivation = true
                    } else {
                        showNoEntitlementAlert = true
                    }
                }
                .onRestoreFailure { error in
                    restoreFailureMessage = error.localizedDescription
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
        .alert(NSLocalizedString("no_active_entitlement", comment: ""), isPresented: $showNoEntitlementAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert(restoreFailureMessage ?? "", isPresented: Binding(
            get: { restoreFailureMessage != nil },
            set: { if !$0 { restoreFailureMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        }
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: item.iconName)
                    .font(.bodySmall)

                Text(item.displayName)
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

                if languageManager.currentLanguage == language {
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
