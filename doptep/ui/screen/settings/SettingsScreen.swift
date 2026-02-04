//
//  SettingsScreen.swift
//  doptep
//

import SwiftUI

private let appStoreUrl = "https://apps.apple.com/app/id0000000000" // TODO: Replace with actual App Store ID
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
                Text("\(NSLocalizedString("settings_version", comment: "")): \(Bundle.main.appVersion) - \(Bundle.main.buildNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 12)
            }
            .padding(16)
        }
        .background(Color(UIColor.systemGroupedBackground))
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
                    .font(.body)

                Text(item.displayName)
                    .font(.subheadline)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.primary)
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
}

// MARK: - Language Selection Sheet

struct LanguageSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("app_language") private var appLanguage: String = "en"

    var body: some View {
        NavigationView {
            List {
                Button {
                    appLanguage = "en"
                    dismiss()
                } label: {
                    HStack {
                        Text("English")
                        Spacer()
                        if appLanguage == "en" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)

                Button {
                    appLanguage = "ru"
                    dismiss()
                } label: {
                    HStack {
                        Text("Русский")
                        Spacer()
                        if appLanguage == "ru" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            .navigationTitle(NSLocalizedString("settings_item_language", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("done", comment: "")) {
                        dismiss()
                    }
                }
            }
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
