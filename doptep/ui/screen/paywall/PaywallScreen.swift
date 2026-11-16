//
//  PaywallScreen.swift
//  doptep
//
//  Custom paywall, same layout as the Android ActivationScreen.
//

import SwiftUI

private enum PaywallColor {
    static let green = Color(hex: "#1E7F2F")
    static let greenDark = Color(hex: "#0B3D16")
    static let gold = Color(hex: "#FFC83D")
}

enum PaywallLinks {
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyPolicy = URL(string: "https://sites.google.com/view/dop-tep")!
}

struct PaywallScreen: View {
    /// Called after a successful purchase or restore.
    let onPurchased: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: PaywallViewModel

    init(showOneDay: Bool = true, onPurchased: @escaping () -> Void) {
        self.onPurchased = onPurchased
        _viewModel = StateObject(wrappedValue: PaywallViewModel(showOneDay: showOneDay))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    hero

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("activation_plan_title")
                        plans
                        sectionTitle("activation_text_title")
                            .padding(.top, 12)
                        PaywallFeaturesCard()
                        legalSection
                            .padding(.top, 4)
                    }
                    .padding(16)
                }
            }
            .background(AppColor.background)

            bottomBar
        }
        // Root background is the hero color: it fills the status bar area and any gap
        // that appears while the full screen cover is animating in (safe area is applied late).
        // The scroll content and the bottom bar paint their own backgrounds.
        .background(PaywallColor.greenDark.ignoresSafeArea())
        .navigationBarHidden(true)
        .enableSwipeBack()
        .overlay {
            if viewModel.isPurchasing {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.4)
                }
            }
        }
        .onAppear { viewModel.onAppear() }
        .onChange(of: viewModel.effect) { _, effect in
            guard let effect else { return }
            viewModel.effect = nil
            switch effect {
            case .close:
                dismiss()
            case .purchased:
                onPurchased()
            }
        }
        .alert(viewModel.alertMessage ?? "", isPresented: Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 10) {
                Image("app_logo")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                Text(NSLocalizedString("paywall_title", comment: ""))
                    .font(.headlineMedium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(NSLocalizedString("paywall_subtitle", comment: ""))
                    .font(.bodySmall)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 24)

            Button {
                viewModel.onCloseClicked()
            } label: {
                Image(systemName: "xmark")
                    .font(.titleMedium)
                    .foregroundColor(.white.opacity(0.8))
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
        // Keeps the area above the hero green when the scroll view bounces at the top.
        .background(alignment: .top) {
            PaywallColor.greenDark
                .frame(height: 600)
                .offset(y: -600)
        }
    }

    // MARK: - Plans

    @ViewBuilder
    private var plans: some View {
        PaywallPlanCard(
            title: NSLocalizedString("activation_plan_2", comment: ""),
            subtitle: viewModel.yearlyPerMonth.map {
                String(format: NSLocalizedString("paywall_per_month", comment: ""), $0)
            } ?? NSLocalizedString("activation_plan_desc_subscribe", comment: ""),
            price: viewModel.price(for: .yearly),
            period: NSLocalizedString("paywall_period_year", comment: ""),
            badge: viewModel.yearlySavingsPercent.map {
                String(format: NSLocalizedString("paywall_badge_save", comment: ""), $0)
            } ?? NSLocalizedString("paywall_badge_best", comment: ""),
            badgeHighlighted: true,
            isSelected: viewModel.selectedPlan == .yearly,
            isLoading: viewModel.isLoadingProducts
        ) { viewModel.onPlanSelected(.yearly) }

        PaywallPlanCard(
            title: NSLocalizedString("activation_plan_3", comment: ""),
            subtitle: NSLocalizedString("activation_plan_desc_lifetime", comment: ""),
            price: viewModel.price(for: .unlimited),
            period: NSLocalizedString("paywall_period_forever", comment: ""),
            badge: NSLocalizedString("paywall_badge_one_time", comment: ""),
            badgeHighlighted: false,
            isSelected: viewModel.selectedPlan == .unlimited,
            isLoading: viewModel.isLoadingProducts
        ) { viewModel.onPlanSelected(.unlimited) }

        PaywallPlanCard(
            title: NSLocalizedString("activation_plan_1", comment: ""),
            subtitle: NSLocalizedString("activation_plan_desc_subscribe", comment: ""),
            price: viewModel.price(for: .monthly),
            period: NSLocalizedString("paywall_period_month", comment: ""),
            isSelected: viewModel.selectedPlan == .monthly,
            isLoading: viewModel.isLoadingProducts
        ) { viewModel.onPlanSelected(.monthly) }

        if viewModel.showOneDay {
            PaywallPlanCard(
                title: NSLocalizedString("activation_plan_4", comment: ""),
                subtitle: NSLocalizedString("activation_plan_desc_lifetime", comment: ""),
                price: viewModel.price(for: .oneday),
                period: NSLocalizedString("paywall_period_day", comment: ""),
                isSelected: viewModel.selectedPlan == .oneday,
                isLoading: viewModel.isLoadingProducts
            ) { viewModel.onPlanSelected(.oneday) }
        }
    }

    private func sectionTitle(_ key: String) -> some View {
        Text(NSLocalizedString(key, comment: ""))
            .font(.titleMedium)
            .foregroundColor(AppColor.onSurface)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 8) {
            Button {
                viewModel.onBuyClicked()
            } label: {
                Text(buyButtonTitle)
                    .font(.bodyLarge)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(PaywallColor.green)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(viewModel.isPurchasing)

            Text(NSLocalizedString(
                viewModel.isSubscriptionSelected ? "paywall_note_subscription" : "paywall_note_one_time",
                comment: ""
            ))
            .font(.custom("Montserrat-Medium", size: 12))
            .foregroundColor(AppColor.outline)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            footerLink("restore_purchases") { viewModel.onRestoreClicked() }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            AppColor.surface
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("paywall_legal_text", comment: ""))
                .font(.custom("Montserrat-Medium", size: 12))
                .foregroundColor(AppColor.outline)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                footerLink("paywall_terms") { openURL(PaywallLinks.termsOfUse) }
                footerDot
                footerLink("paywall_privacy") { openURL(PaywallLinks.privacyPolicy) }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 4)
    }

    private var buyButtonTitle: String {
        let activate = NSLocalizedString("activation_button", comment: "")
        guard let price = viewModel.selectedPrice else { return activate }
        return "\(activate) · \(price)"
    }

    private func footerLink(_ key: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(NSLocalizedString(key, comment: ""))
                .font(.custom("Montserrat-Medium", size: 12))
                .foregroundColor(AppColor.onSurfaceVariant)
                .underline()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .disabled(viewModel.isPurchasing)
    }

    private var footerDot: some View {
        Text("·")
            .font(.custom("Montserrat-Medium", size: 12))
            .foregroundColor(AppColor.outline)
    }
}

// MARK: - Plan card

private struct PaywallPlanCard: View {
    let title: String
    let subtitle: String
    let price: String?
    let period: String
    var badge: String? = nil
    var badgeHighlighted: Bool = false
    let isSelected: Bool
    let isLoading: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 12) {
                    PaywallRadio(isSelected: isSelected)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.bodyLarge)
                            .foregroundColor(AppColor.onSurface)
                        Text(subtitle)
                            .font(.labelSmall)
                            .foregroundColor(isSelected ? PaywallColor.green : AppColor.outline)
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 2) {
                        if price == nil && isLoading {
                            ProgressView()
                                .frame(height: 20)
                        } else {
                            Text(price ?? "—")
                                .font(.bodyLarge)
                                .foregroundColor(AppColor.onSurface)
                        }
                        Text(period)
                            .font(.labelSmall)
                            .foregroundColor(AppColor.outline)
                    }
                }
                .padding(16)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? PaywallColor.green : AppColor.surfaceVariant, lineWidth: isSelected ? 2 : 1)
                )
                .padding(.top, badge != nil ? 10 : 0)

                if let badge {
                    Text(badge)
                        .font(.custom("Montserrat-Bold", size: 12))
                        .foregroundColor(badgeHighlighted ? .black : .white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(badgeHighlighted ? PaywallColor.gold : PaywallColor.green)
                        .clipShape(Capsule())
                        .padding(.trailing, 16)
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

private struct PaywallRadio: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? PaywallColor.green : Color.clear)
            Circle()
                .stroke(isSelected ? PaywallColor.green : AppColor.outline, lineWidth: 2)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 22, height: 22)
    }
}

// MARK: - Features

private struct PaywallFeaturesCard: View {
    private let features: [(title: String, desc: String)] = [
        ("paywall_feature_results", "paywall_feature_results_desc"),
        ("paywall_feature_best_players", "paywall_feature_best_players_desc"),
        ("paywall_feature_champions", "paywall_feature_champions_desc"),
        ("paywall_feature_history", "paywall_feature_history_desc"),
        ("paywall_feature_voice", "paywall_feature_voice_desc"),
        ("paywall_feature_phrases", "paywall_feature_phrases_desc"),
        ("paywall_feature_sounds", "paywall_feature_sounds_desc")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                if index > 0 {
                    Rectangle()
                        .fill(AppColor.background)
                        .frame(height: 1)
                        .padding(.leading, 52)
                }
                HStack(spacing: 12) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(PaywallColor.green)
                        .frame(width: 24, height: 24)
                        .background(PaywallColor.green.opacity(0.12))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString(feature.title, comment: ""))
                            .font(.bodyMedium)
                            .foregroundColor(AppColor.onSurface)
                        Text(NSLocalizedString(feature.desc, comment: ""))
                            .font(.labelSmall)
                            .foregroundColor(AppColor.outline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
