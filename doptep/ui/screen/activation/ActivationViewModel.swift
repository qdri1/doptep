//
//  ActivationViewModel.swift
//  doptep
//

import Foundation

@MainActor
final class ActivationViewModel: ObservableObject {

    @Published var uiState = ActivationUiState()
    @Published var effect: ActivationEffect?

    private let billingManager: BillingManager

    init(billingManager: BillingManager = .shared) {
        self.billingManager = billingManager
        fetchActivation()
    }

    func action(_ action: ActivationAction) {
        switch action {
        case .onBackClicked:
            onBackClicked()
            
        case .manageSubscriptionsButtonClicked:
            setEffect(.openAppStoreSubscriptions)
        }
    }

    func clearEffect() {
        effect = nil
    }

    private func fetchActivation() {
        let billingType = billingManager.getCurrentBillingType()
        uiState = ActivationUiState(
            billingType: billingType,
            onedayExpirationDate: billingType == .oneday ? billingManager.onedayExpirationDate : nil
        )
    }

    private func onBackClicked() {
        setEffect(.closeScreen)
    }

    private func setEffect(_ effect: ActivationEffect) {
        self.effect = effect
    }
}
