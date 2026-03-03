//
//  SettingsViewModel.swift
//  doptep
//

import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {

    @Published var effect: SettingsEffect?

    private let billingManager: BillingManager

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

    private func onSettingsItemClicked(_ item: SettingsItemType) {
        switch item {
        case .language:
            setEffect(.showSelectLanguage)
        case .share:
            setEffect(.share)
        case .evaluate:
            setEffect(.openAppStore)
//        case .activation:
//            if billingManager.billingType.isPremium {
//                setEffect(.openActivationScreen)
//            } else {
//                setEffect(.showPaywall)
//            }
        }
    }

    private func setEffect(_ effect: SettingsEffect) {
        self.effect = effect
    }
}
