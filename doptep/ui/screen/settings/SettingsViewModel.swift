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
        case .onActivationCodeSubmitted(let code):
            onActivationCodeSubmitted(code)
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

    private func onActivationCodeSubmitted(_ code: String) {
        if code.trimmingCharacters(in: .whitespaces) == RemoteConfigManager.shared.activationCode {
            if billingManager.getCurrentBillingType() == .lifetime && billingManager.isSecretActivated() {
                billingManager.setBillingType(.limited)
                billingManager.setSecretActivated(false)
            } else {
                billingManager.setBillingType(.lifetime)
                billingManager.setSecretActivated(true)
            }
            setEffect(.activationSuccess)
        } else {
            setEffect(.activationError)
        }
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
