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

        case .showPriceButtonClicked:
            onShowPriceButtonClicked()

        case .buyButtonClicked:
            onBuyButtonClicked()

        case .manageSubscriptionsButtonClicked:
            setEffect(.openAppStoreSubscriptions)

        case .onActivationPlanItemClicked(let plan):
            onActivationPlanItemClicked(plan)

        case .restorePurchases:
            restorePurchases()
        }
    }

    func clearEffect() {
        effect = nil
    }

    private func fetchActivation() {
        let billingType = billingManager.getCurrentBillingType()
        uiState = ActivationUiState(
            billingType: billingType,
            pageIndex: 0,
            selectedPlan: nil,
            monthlyPrice: billingManager.monthlyPrice,
            yearlyPrice: billingManager.yearlyPrice,
            unlimitedPrice: billingManager.unlimitedPrice
        )
    }

    private func onBackClicked() {
        if uiState.billingType == .limited {
            if uiState.pageIndex > 0 {
                uiState.pageIndex = 0
            } else {
                setEffect(.closeScreen)
            }
        } else {
            setEffect(.closeScreen)
        }
    }

    private func onShowPriceButtonClicked() {
        uiState.pageIndex = 1
    }

    private func onBuyButtonClicked() {
        guard let selectedPlan = uiState.selectedPlan else {
            setEffect(.showSnackbar(message: NSLocalizedString("activation_plan_select_error_text", comment: "")))
            return
        }

        Task {
            uiState.isLoading = true
            do {
                let success = try await billingManager.purchase(selectedPlan)
                if success {
                    fetchActivation()
                    setEffect(.showSnackbar(message: NSLocalizedString("purchase_success", comment: "")))
                }
            } catch {
                setEffect(.showSnackbar(message: NSLocalizedString("purchase_failed", comment: "")))
            }
            uiState.isLoading = false
        }
    }

    private func onActivationPlanItemClicked(_ plan: ActivationPlan) {
        uiState.selectedPlan = plan
    }

    private func restorePurchases() {
        Task {
            uiState.isLoading = true
            await billingManager.restorePurchases()
            fetchActivation()
            uiState.isLoading = false
            setEffect(.showSnackbar(message: NSLocalizedString("restore_success", comment: "")))
        }
    }

    private func setEffect(_ effect: ActivationEffect) {
        self.effect = effect
    }
}
