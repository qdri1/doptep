//
//  ActivationScreen.swift
//  doptep
//

import SwiftUI

struct ActivationScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ActivationViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack(spacing: 12) {
                Button {
                    viewModel.action(.onBackClicked)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.titleLarge)
                        .foregroundColor(AppColor.onSurface)
                }

                Spacer()
            }
            .padding(16)
            .background(AppColor.surface)

            ActivatedContent(
                uiState: viewModel.uiState,
                onAction: viewModel.action
            )
        }
        .background(AppColor.surface)
        .navigationBarHidden(true)
        .enableSwipeBack()
        .onChange(of: viewModel.effect) { _, effect in
            guard let effect = effect else { return }
            handleEffect(effect)
            viewModel.clearEffect()
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
        }
    }
}

// MARK: - Oneday Remaining View

private struct OnedayRemainingView: View {
    let expirationDate: Date?

    @State private var now = Date()
    private let ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("activation_oneday_time_remaining", comment: ""))
                .font(.titleMedium)
                .foregroundColor(AppColor.onSurfaceVariant)

            Text(timeString)
                .font(.displayLarge)
                .foregroundColor(AppColor.primary)

            Text(NSLocalizedString("activation_oneday_not_subscription", comment: ""))
                .font(.bodyMedium)
                .foregroundColor(AppColor.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.top, 4)
        }
        .onReceive(ticker) { _ in
            now = Date()
        }
    }

    private var timeString: String {
        guard let expiration = expirationDate else { return "0 h 0 min" }
        let remaining = max(0, expiration.timeIntervalSince(now))
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let h = NSLocalizedString("activation_oneday_hours_abbr", comment: "")
        let min = NSLocalizedString("activation_oneday_minutes_abbr", comment: "")
        return "\(hours) \(h) \(minutes) \(min)"
    }
}

// MARK: - Activated Content

struct ActivatedContent: View {
    let uiState: ActivationUiState
    let onAction: (ActivationAction) -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Text(NSLocalizedString("activation_plan_activated_text", comment: ""))
                    .font(.displayLarge)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                if uiState.billingType == .lifetime {
                    Text(NSLocalizedString("activation_lifetime_description", comment: ""))
                        .font(.bodyMedium)
                        .foregroundColor(AppColor.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }

                if uiState.billingType == .oneday {
                    OnedayRemainingView(expirationDate: uiState.onedayExpirationDate)
                        .padding(.top, 8)
                }

                if uiState.billingType == .subscribe {
                    Button {
                        onAction(.manageSubscriptionsButtonClicked)
                    } label: {
                        Text(NSLocalizedString("activation_plan_activated_button", comment: ""))
                            .font(.titleMedium)
                            .foregroundColor(AppColor.onPrimary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 24)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer()
        }
    }
}
