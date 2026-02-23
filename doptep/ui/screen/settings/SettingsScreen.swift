//
//  SettingsScreen.swift
//  doptep
//

import SwiftUI

private let appStoreUrl = "https://apps.apple.com/app/id6758735315"
private let telegramUrl = "https://t.me/+_Ur1Ixp_1bNhNTc6"

struct SettingsScreen: View {
    @StateObject private var viewModel = SettingsViewModel()

    @State private var showLanguageSelection = false
    @State private var showShareSheet = false
    @State private var navigateToActivation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(SettingsItemType.allCases, id: \.self) { item in
                    SettingsItemRow(item: item) {
                        viewModel.action(.onSettingsItemClicked(item: item))
                    }
                }

                // Version Info
                Text("\(NSLocalizedString("settings_version", comment: "")): \(Bundle.main.appVersion)")
                    .font(.labelSmall)
                    .foregroundColor(AppColor.outline)
                    .padding(.top, 12)
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

        case .openTelegram:
            if let url = URL(string: telegramUrl) {
                UIApplication.shared.open(url)
            }

        case .openActivationScreen:
            navigateToActivation = true
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
                    .font(.bodyMedium)

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

// MARK: - Language Selection Sheet

struct LanguageSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("app_language") private var appLanguage: String = "en"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(NSLocalizedString("choose_language", comment: ""))
                    .font(.bodyMedium)
                    .foregroundColor(AppColor.onSurface)

                Spacer()

                Button(NSLocalizedString("done", comment: "")) {
                    dismiss()
                }
                .font(.bodySmall)
                .foregroundColor(AppColor.primary)
            }
            .padding(16)

            Divider()

            languageRow(title: "English", language: "en")
            languageRow(title: "Русский", language: "ru")

            Spacer()
        }
        .background(AppColor.surface)
    }

    private func languageRow(title: String, language: String) -> some View {
        Button {
            appLanguage = language
            dismiss()
        } label: {
            HStack {
                Text(title)
                    .font(.bodySmall)
                    .foregroundColor(AppColor.onSurface)

                Spacer()

                if appLanguage == language {
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
