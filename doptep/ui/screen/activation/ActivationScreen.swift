//
//  ActivationScreen.swift
//  doptep
//

import SwiftUI

struct ActivationScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ActivationViewModel()

    @State private var snackbarMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack(spacing: 12) {
                Button {
                    viewModel.action(.onBackClicked)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }

                Spacer()
            }
            .padding(16)
            .background(Color(UIColor.systemBackground))

            // Content
            if viewModel.uiState.billingType == .limited {
                switch viewModel.uiState.pageIndex {
                case 0:
                    ActivationTextContent(onAction: viewModel.action)
                case 1:
                    ActivationPlanContent(
                        uiState: viewModel.uiState,
                        onAction: viewModel.action
                    )
                default:
                    EmptyView()
                }
            } else {
                ActivatedContent(
                    uiState: viewModel.uiState,
                    onAction: viewModel.action
                )
            }
        }
        .background(Color(UIColor.systemBackground))
        .navigationBarHidden(true)
        .onChange(of: viewModel.effect) { _, effect in
            guard let effect = effect else { return }
            handleEffect(effect)
            viewModel.clearEffect()
        }
        .snackbar(message: $snackbarMessage)
        .overlay {
            if viewModel.uiState.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }

    private func handleEffect(_ effect: ActivationEffect) {
        switch effect {
        case .closeScreen:
            dismiss()

        case .openAppStoreSubscriptions:
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                UIApplication.shared.open(url)
            }

        case .showSnackbar(let message):
            snackbarMessage = message

        case .buySelectedPlan:
            // Purchase is handled in ViewModel
            break
        }
    }
}

// MARK: - Activation Text Content

struct ActivationTextContent: View {
    let onAction: (ActivationAction) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(NSLocalizedString("activation_text_title", comment: ""))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)

                ActivationTextItem(text: NSLocalizedString("activation_text_1", comment: ""))
                ActivationTextItem(text: NSLocalizedString("activation_text_2", comment: ""))
                ActivationTextItem(text: NSLocalizedString("activation_text_3", comment: ""))
                ActivationTextItem(text: NSLocalizedString("activation_text_4", comment: ""))
                ActivationTextItem(text: NSLocalizedString("activation_text_5", comment: ""))
                ActivationTextItem(text: NSLocalizedString("activation_text_6", comment: ""))

                Button {
                    onAction(.showPriceButtonClicked)
                } label: {
                    Text(NSLocalizedString("activation_text_button", comment: ""))
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.top, 24)
            }
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Activation Plan Content

struct ActivationPlanContent: View {
    let uiState: ActivationUiState
    let onAction: (ActivationAction) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(NSLocalizedString("activation_plan_title", comment: ""))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)

                ActivationPlanItem(
                    plan: .monthly,
                    price: uiState.monthlyPrice ?? "---",
                    isSelected: uiState.selectedPlan == .monthly,
                    onAction: onAction
                )

                ActivationPlanItem(
                    plan: .yearly,
                    price: uiState.yearlyPrice ?? "---",
                    isSelected: uiState.selectedPlan == .yearly,
                    onAction: onAction
                )

                ActivationPlanItem(
                    plan: .unlimited,
                    price: uiState.unlimitedPrice ?? "---",
                    isSelected: uiState.selectedPlan == .unlimited,
                    onAction: onAction
                )

                Button {
                    onAction(.buyButtonClicked)
                } label: {
                    Text(NSLocalizedString("activation_plan_button", comment: ""))
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.top, 24)

                Button {
                    onAction(.restorePurchases)
                } label: {
                    Text(NSLocalizedString("restore_purchases", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Activated Content

struct ActivatedContent: View {
    let uiState: ActivationUiState
    let onAction: (ActivationAction) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(NSLocalizedString("activation_plan_activated_text", comment: ""))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                if uiState.billingType == .subscribe {
                    Button {
                        onAction(.manageSubscriptionsButtonClicked)
                    } label: {
                        Text(NSLocalizedString("activation_plan_activated_button", comment: ""))
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.top, 24)
                }
            }
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Activation Text Item

struct ActivationTextItem: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundColor(.orange)

            Text(text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Activation Plan Item

struct ActivationPlanItem: View {
    let plan: ActivationPlan
    let price: String
    let isSelected: Bool
    let onAction: (ActivationAction) -> Void

    var body: some View {
        Button {
            onAction(.onActivationPlanItemClicked(plan: plan))
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.displayName)
                        .font(.body)
                        .fontWeight(.medium)

                    Text(plan.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(price)
                    .font(.body)
                    .fontWeight(.medium)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.title2)
            }
            .foregroundColor(.primary)
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
        .padding(.horizontal, 16)
    }
}
