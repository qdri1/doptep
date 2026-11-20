//
//  ActivationScreen.swift
//  doptep
//
//  Shown when the user already has the full version.
//

import SwiftUI

struct ActivationScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ActivationViewModel()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ActivatedHero(
                    billingType: viewModel.uiState.billingType,
                    subscriptionPlan: viewModel.uiState.subscriptionPlan,
                    onBack: { viewModel.action(.onBackClicked) }
                )

                VStack(alignment: .leading, spacing: 12) {
                    ActivatedStatusCard(uiState: viewModel.uiState, onAction: viewModel.action)

                    Text(NSLocalizedString("activation_text_title", comment: ""))
                        .font(.titleMedium)
                        .foregroundColor(AppColor.onSurface)
                        .padding(.top, 12)

                    PaywallFeaturesCard()
                }
                .padding(16)
            }
        }
        .background(AppColor.background)
        .background(PaywallColor.greenDark.ignoresSafeArea())
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

// MARK: - Hero

private struct ActivatedHero: View {
    let billingType: BillingType
    let subscriptionPlan: ActivationPlan?
    let onBack: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 12) {
                Image("app_logo")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(PaywallColor.greenDark, PaywallColor.gold)
                            .background(Circle().fill(PaywallColor.greenDark).padding(2))
                            .offset(x: 10, y: 10)
                    }

                VStack(spacing: 4) {
                    Text(NSLocalizedString("paywall_title", comment: ""))
                        .font(.headlineMedium)
                        .foregroundColor(.white)
                    Text(NSLocalizedString("activation_plan_activated_text", comment: ""))
                        .font(.bodySmall)
                        .foregroundColor(.white.opacity(0.85))
                }
                .multilineTextAlignment(.center)
                .padding(.top, 4)

                if let planKey {
                    Text(NSLocalizedString(planKey, comment: ""))
                        .font(.labelLarge)
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(PaywallColor.gold)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 28)

            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.titleMedium)
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .contentShape(Circle())
            }
            .padding(8)
        }
        .background(
            LinearGradient(
                colors: [PaywallColor.greenDark, PaywallColor.green],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .background(alignment: .top) {
            PaywallColor.greenDark
                .frame(height: 600)
                .offset(y: -600)
        }
    }

    private var planKey: String? {
        switch billingType {
        case .lifetime: return "activation_plan_3"
        case .subscribe:
            switch subscriptionPlan {
            case .monthly: return "activation_plan_subscription_monthly"
            case .yearly: return "activation_plan_subscription_yearly"
            default: return "activation_plan_subscription"
            }
        case .oneday: return "activation_plan_4"
        default: return nil
        }
    }
}

// MARK: - Status card

private struct ActivatedStatusCard: View {
    let uiState: ActivationUiState
    let onAction: (ActivationAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch uiState.billingType {
            case .lifetime:
                statusHeader(
                    icon: "infinity",
                    title: "activation_lifetime_description",
                    subtitle: "activation_lifetime_subtitle"
                )

            case .subscribe:
                statusHeader(
                    icon: "arrow.triangle.2.circlepath",
                    title: "activation_subscribe_title",
                    subtitle: "activation_subscribe_subtitle"
                )
                Button {
                    onAction(.manageSubscriptionsButtonClicked)
                } label: {
                    Text(NSLocalizedString("activation_plan_activated_button", comment: ""))
                        .font(.bodyLarge)
                        .foregroundColor(AppColor.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(PaywallColor.green)
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableCardStyle())

            case .oneday:
                OnedayRemainingView(expirationDate: uiState.onedayExpirationDate)

            default:
                EmptyView()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func statusHeader(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(PaywallColor.green)
                .frame(width: 44, height: 44)
                .background(PaywallColor.green.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString(title, comment: ""))
                    .font(.bodyLarge)
                    .foregroundColor(AppColor.onSurface)
                Text(NSLocalizedString(subtitle, comment: ""))
                    .font(.labelSmall)
                    .foregroundColor(AppColor.outline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Oneday remaining

private struct OnedayRemainingView: View {
    let expirationDate: Date?

    @State private var now = Date()
    private let ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 14, weight: .semibold))
                Text(NSLocalizedString("activation_oneday_time_remaining", comment: ""))
                    .font(.labelLarge)
            }
            .foregroundColor(AppColor.onSurfaceVariant)

            Text(timeString)
                .font(.custom("Montserrat-Bold", size: 34))
                .foregroundColor(PaywallColor.green)
                .monospacedDigit()

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(PaywallColor.green.opacity(0.12))
                    Capsule()
                        .fill(PaywallColor.green)
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 8)

            Text(NSLocalizedString("activation_oneday_not_subscription", comment: ""))
                .font(.labelSmall)
                .foregroundColor(AppColor.outline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onReceive(ticker) { _ in
            now = Date()
        }
    }

    private var remaining: TimeInterval {
        guard let expiration = expirationDate else { return 0 }
        return max(0, expiration.timeIntervalSince(now))
    }

    private var progress: CGFloat {
        CGFloat(min(1, remaining / BillingManager.onedayDuration))
    }

    private var timeString: String {
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let h = NSLocalizedString("activation_oneday_hours_abbr", comment: "")
        let min = NSLocalizedString("activation_oneday_minutes_abbr", comment: "")
        return "\(hours) \(h) \(minutes) \(min)"
    }
}
