//
//  ActivationViewModel.swift
//  doptep
//

import Foundation
import RevenueCat

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
        if billingType == .subscribe {
            fetchSubscriptionPlan()
        }
    }

    private func fetchSubscriptionPlan() {
        Task { [weak self] in
            guard let customerInfo = try? await Purchases.shared.customerInfo() else { return }
            let active = customerInfo.activeSubscriptions
            let plan: ActivationPlan?
            if active.contains(ActivationPlan.yearly.productId) {
                plan = .yearly
            } else if active.contains(ActivationPlan.monthly.productId) {
                plan = .monthly
            } else {
                plan = nil
            }
            self?.uiState.subscriptionPlan = plan
        }
    }

    private func onBackClicked() {
        setEffect(.closeScreen)
    }

    private func setEffect(_ effect: ActivationEffect) {
        self.effect = effect
    }
}
