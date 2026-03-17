//
//  SettingsViewModel.swift
//  doptep
//

import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {

    @Published var effect: SettingsEffect?

    private let billingManager: BillingManager

    var telegramUrl: String { RemoteConfigManager.shared.telegramUrl }
    var whatsappUrl: String { RemoteConfigManager.shared.whatsappUrl }

    init(billingManager: BillingManager = .shared) {
        self.billingManager = billingManager
    }

    func action(_ action: SettingsAction) {
        switch action {
        case .onSettingsItemClicked(let item):
            onSettingsItemClicked(item)
        }
    }

    func clearEffect() {
        effect = nil
    }

    func onTelegramClicked() {
        setEffect(.openTelegram(url: RemoteConfigManager.shared.telegramUrl))
    }

    func onWhatsappClicked() {
        setEffect(.openWhatsapp(url: RemoteConfigManager.shared.whatsappUrl))
    }

    private func onSettingsItemClicked(_ item: SettingsItemType) {
        switch item {
        case .language:
            setEffect(.showSelectLanguage)
        case .share:
            setEffect(.share)
        case .evaluate:
            setEffect(.openAppStore)
        case .activation:
            if billingManager.billingType.isPremium {
                setEffect(.openActivationScreen)
            } else {
                setEffect(.showPaywall)
            }
        }
    }

    private func setEffect(_ effect: SettingsEffect) {
        self.effect = effect
    }
}
