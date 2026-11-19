//
//  OnboardingScreen.swift
//  doptep
//

import SwiftUI

struct OnboardingScreen: View {
    let onFinished: () -> Void

    @EnvironmentObject private var languageManager: LanguageManager
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ZStack {
                stepContent
                    .id(viewModel.step)
                    .transition(stepTransition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            bottomBar
        }
        .background(AppColor.background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.3), value: viewModel.step)
        .onChange(of: viewModel.effect) { _, effect in
            guard let effect else { return }
            viewModel.effect = nil
            switch effect {
            case .finish:
                onFinished()
            }
        }
    }

    private var stepTransition: AnyTransition {
        let insertion: Edge = viewModel.isMovingForward ? .trailing : .leading
        let removal: Edge = viewModel.isMovingForward ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: insertion).combined(with: .opacity),
            removal: .move(edge: removal).combined(with: .opacity)
        )
    }

    // MARK: - Top / Bottom bars

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.send(.onBackClicked)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.titleLarge)
                    .foregroundColor(AppColor.onSurface)
                    .frame(width: 32, height: 32)
            }
            .opacity(viewModel.step == .language ? 0 : 1)
            .disabled(viewModel.step == .language)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColor.surfaceVariant)
                    Capsule()
                        .fill(AppColor.primary)
                        .frame(width: proxy.size.width * viewModel.progress)
                }
            }
            .frame(height: 6)

            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var bottomBar: some View {
        VStack(spacing: 8) {
            if viewModel.step == .notifications {
                primaryButton(titleKey: "notification_rationale_allow") {
                    viewModel.send(.onAllowNotificationsClicked)
                }
                Button {
                    viewModel.send(.onSkipNotificationsClicked)
                } label: {
                    Text(NSLocalizedString("notification_rationale_later", comment: ""))
                        .font(.labelMedium)
                        .foregroundColor(AppColor.onSurfaceVariant)
                        .padding(.vertical, 8)
                }
            } else {
                primaryButton(
                    titleKey: viewModel.step == .welcome ? "onboarding_start_button" : "onboarding_continue_button"
                ) {
                    viewModel.send(.onContinueClicked)
                }
                .disabled(!viewModel.canContinue)
                .opacity(viewModel.canContinue ? 1 : 0.5)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func primaryButton(titleKey: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(NSLocalizedString(titleKey, comment: ""))
                .font(.bodyMedium)
                .foregroundColor(AppColor.onPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColor.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Steps

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.step {
        case .language: languageStep
        case .welcome: welcomeStep
        case .rotation: rotationStep
        case .sounds: soundsStep
        case .stats: statsStep
        case .notifications: notificationsStep
        }
    }

    private var languageStep: some View {
        StepScroll {
            // Shown in all three languages: the user hasn't picked one yet.
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: "Тілді таңдаңыз")
                    .font(.displayLarge)
                    .foregroundColor(AppColor.onBackground)
                Text(verbatim: "Выберите язык · Choose language")
                    .font(.bodySmall)
                    .foregroundColor(AppColor.onSurfaceVariant)
            }
            .padding(.bottom, 8)

            ForEach(Self.languages, id: \.code) { language in
                OptionCard(
                    leading: AnyView(
                        Text(language.flag)
                            .font(.system(size: 28))
                            .frame(width: 44, height: 44)
                            .background(AppColor.primaryContainer.opacity(0.5))
                            .clipShape(Circle())
                    ),
                    title: language.title,
                    subtitle: nil,
                    isSelected: viewModel.selectedLanguage == language.code,
                    isMultiSelect: false
                ) {
                    // Applied right away so the rest of the onboarding is in the chosen language.
                    languageManager.setLanguage(language.code)
                    viewModel.send(.onLanguageSelected(language.code))
                }
            }
        }
    }

    private static let languages: [(code: String, title: String, flag: String)] = [
        ("kk-KZ", "Қазақша", "🇰🇿"),
        ("ru", "Русский", "🇷🇺"),
        ("en", "English", "🇬🇧")
    ]

    private var welcomeStep: some View {
        // Same 24pt gap between the logo, the title and the description.
        CenteredStepScroll {
            Image("app_logo")
                .resizable()
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
            Text(NSLocalizedString("onboarding_welcome_title", comment: ""))
                .font(.displayLarge)
                .foregroundColor(AppColor.onBackground)
                .fixedSize(horizontal: false, vertical: true)
            Text(NSLocalizedString("onboarding_welcome_subtitle", comment: ""))
                .font(.bodySmall)
                .foregroundColor(AppColor.onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.center)
    }

    private var rotationStep: some View {
        StepScroll {
            header(titleKey: "onboarding_rotation_title", subtitleKey: "onboarding_rotation_subtitle")
            ScoreboardPreview(showNextTeams: true)
            FeatureBullet(icon: "list.bullet.rectangle", textKey: "onboarding_rotation_bullet_rules")
            FeatureBullet(icon: "stopwatch", textKey: "onboarding_rotation_bullet_timer")
            FeatureBullet(icon: "speaker.wave.2.fill", textKey: "onboarding_rotation_bullet_voice", isPro: true)
        }
    }

    private var soundsStep: some View {
        StepScroll {
            header(titleKey: "onboarding_sounds_title", subtitleKey: "onboarding_sounds_subtitle")

            Button {
                viewModel.send(.onVoiceDemoClicked)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.isVoicePlaying ? "waveform" : "play.fill")
                        .font(.titleMedium)
                        .foregroundColor(AppColor.onPrimary)
                        .frame(width: 48, height: 48)
                        .background(AppColor.primary)
                        .clipShape(Circle())
                        .symbolEffect(.variableColor.iterative, isActive: viewModel.isVoicePlaying)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("onboarding_sounds_demo_button", comment: ""))
                            .font(.bodyMedium)
                            .foregroundColor(AppColor.onSurface)
                        Text(String(
                            format: NSLocalizedString("text_to_speech_goal", comment: ""),
                            NSLocalizedString("onboarding_sample_player_1", comment: "")
                        ))
                        .font(.labelSmall)
                        .foregroundColor(AppColor.onSurfaceVariant)
                    }
                    Spacer()
                }
                .padding(16)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            FeatureBullet(icon: "person.wave.2.fill", textKey: "activation_text_1", isPro: true)
            FeatureBullet(icon: "music.note.list", textKey: "activation_text_4", isPro: true)
        }
    }

    private var statsStep: some View {
        StepScroll {
            header(titleKey: "onboarding_stats_title", subtitleKey: "onboarding_stats_subtitle")
            TeamsLeaderboardPreview()
            LeaderboardPreview()
            FeatureBullet(icon: "tablecells", textKey: "onboarding_stats_bullet_teams")
            FeatureBullet(icon: "crown.fill", textKey: "onboarding_stats_bullet_best", isPro: true)
            FeatureBullet(icon: "trophy.fill", textKey: "onboarding_stats_bullet_champions", isPro: true)
        }
    }

    private var notificationsStep: some View {
        CenteredStepScroll {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(AppColor.primary)
                .frame(width: 96, height: 96)
                .background(AppColor.primaryContainer.opacity(0.5))
                .clipShape(Circle())

            header(titleKey: "notification_rationale_title", subtitleKey: "notification_rationale_message")
                .multilineTextAlignment(.center)

            NotificationPreview()

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "gearshape")
                    .font(.labelSmall)
                    .foregroundColor(AppColor.onSurfaceVariant)
                    .padding(.top, 1)
                Text(NSLocalizedString("onboarding_notifications_hint", comment: ""))
                    .font(.labelSmall)
                    .foregroundColor(AppColor.onSurfaceVariant)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var isCenteredStep: Bool {
        viewModel.step == .notifications
    }

    private func header(titleKey: String, subtitleKey: String) -> some View {
        VStack(alignment: isCenteredStep ? .center : .leading, spacing: 8) {
            Text(NSLocalizedString(titleKey, comment: ""))
                .font(.displayLarge)
                .foregroundColor(AppColor.onBackground)
                .fixedSize(horizontal: false, vertical: true)
            Text(NSLocalizedString(subtitleKey, comment: ""))
                .font(.bodySmall)
                .foregroundColor(AppColor.onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: isCenteredStep ? .center : .leading)
        .padding(.bottom, 8)
    }
}

// MARK: - Building blocks

private struct StepScroll<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
}

/// Content centred vertically on the screen; scrolls when it doesn't fit
/// (small screens, large Dynamic Type, long Kazakh texts).
private struct CenteredStepScroll<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    content
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
        }
    }
}

private struct OptionCard: View {
    let leading: AnyView
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let isMultiSelect: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                leading
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.bodyMedium)
                        .foregroundColor(AppColor.onSurface)
                    if let subtitle {
                        Text(subtitle)
                            .font(.labelSmall)
                            .foregroundColor(AppColor.onSurfaceVariant)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: selectionIcon)
                    .font(.titleMedium)
                    .foregroundColor(isSelected ? AppColor.primary : AppColor.outline)
            }
            .padding(16)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? AppColor.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private var selectionIcon: String {
        if isMultiSelect {
            return isSelected ? "checkmark.square.fill" : "square"
        }
        return isSelected ? "checkmark.circle.fill" : "circle"
    }
}

/// Mock of the lock-screen notification the timer sends.
private struct NotificationPreview: View {
    var body: some View {
        HStack(spacing: 12) {
            Image("app_logo")
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "Dop Tep")
                    .font(.labelMedium)
                    .foregroundColor(AppColor.onSurface)
                Text(NSLocalizedString("notification_title_minuta", comment: ""))
                    .font(.labelSmall)
                    .foregroundColor(AppColor.onSurfaceVariant)
            }
            Spacer(minLength: 0)
            Image(systemName: "speaker.wave.2.fill")
                .font(.labelSmall)
                .foregroundColor(AppColor.outline)
        }
        .padding(14)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

private struct FeatureBullet: View {
    let icon: String
    let textKey: String
    var isPro: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.bodyMedium)
                .foregroundColor(AppColor.primary)
                .frame(width: 24)
            Text(NSLocalizedString(textKey, comment: ""))
                .font(.labelSmall)
                .foregroundColor(AppColor.onSurface)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if isPro {
                ProBadge()
            }
        }
        .padding(.horizontal, 4)
    }
}

private struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.custom("Montserrat-Bold", size: 11))
            .foregroundColor(AppColor.onPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppColor.primary)
            .clipShape(Capsule())
    }
}

private struct ScoreboardPreview: View {
    let showNextTeams: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                teamChip(name: NSLocalizedString("onboarding_sample_team_1", comment: ""), color: AppColor.primary)
                Spacer()
                Text("2 : 1")
                    .font(.custom("Montserrat-Bold", size: 34))
                    .foregroundColor(AppColor.onSurface)
                Spacer()
                teamChip(name: NSLocalizedString("onboarding_sample_team_2", comment: ""), color: AppColor.tertiary)
            }
            HStack(spacing: 6) {
                Image(systemName: "stopwatch")
                Text("06:59")
                    .monospacedDigit()
            }
            .font(.titleMedium)
            .foregroundColor(AppColor.primary)

            if showNextTeams {
                Divider()
                HStack {
                    Text(NSLocalizedString("next_playing_teams", comment: ""))
                        .font(.labelSmall)
                        .foregroundColor(AppColor.onSurfaceVariant)
                    Spacer()
                    Text(NSLocalizedString("onboarding_sample_next_teams", comment: ""))
                        .font(.labelMedium)
                        .foregroundColor(AppColor.onSurface)
                }
            }
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func teamChip(name: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image("ic_jersey")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(color)
            Text(name)
                .font(.labelMedium)
                .foregroundColor(AppColor.onSurface)
        }
        .frame(width: 80)
    }
}

private struct TeamsLeaderboardPreview: View {
    private struct Row {
        let number: Int
        let games: Int
        let wins: Int
        let draws: Int
        let losses: Int
        var points: Int { wins * 3 + draws }
    }

    // 3 teams, 9 matches: 8 decided + 1 draw between T-1 and T-2.
    private let rows = [
        Row(number: 1, games: 6, wins: 4, draws: 1, losses: 1),
        Row(number: 2, games: 6, wins: 3, draws: 1, losses: 2),
        Row(number: 3, games: 6, wins: 1, draws: 0, losses: 5)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(NSLocalizedString("team", comment: ""))
                    .frame(maxWidth: .infinity, alignment: .leading)
                statHeader("games_short")
                statHeader("wins_short")
                statHeader("draws_short")
                statHeader("loses_short")
                statHeader("points_short")
            }
            .font(.labelMedium)
            .foregroundColor(AppColor.onSurfaceVariant)
            .padding(.bottom, 8)

            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                Divider()
                HStack(spacing: 0) {
                    HStack(spacing: 6) {
                        if index == 0 {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.orange)
                        }
                        Text(String(format: NSLocalizedString("team_number", comment: ""), "\(row.number)"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    statValue(row.games)
                    statValue(row.wins)
                    statValue(row.draws)
                    statValue(row.losses)
                    statValue(row.points)
                        .fontWeight(.bold)
                }
                .font(.labelSmall)
                .foregroundColor(AppColor.onSurface)
                .padding(.vertical, 10)
            }
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func statHeader(_ key: String) -> some View {
        Text(NSLocalizedString(key, comment: "")).frame(width: 36)
    }

    private func statValue(_ value: Int) -> some View {
        Text("\(value)").monospacedDigit().frame(width: 36)
    }
}

private struct LeaderboardPreview: View {
    private struct Row {
        let nameKey: String
        let goals: Int
        let assists: Int
        let saves: Int
    }

    private let rows = [
        Row(nameKey: "onboarding_sample_player_1", goals: 5, assists: 2, saves: 0),
        Row(nameKey: "onboarding_sample_player_2", goals: 3, assists: 4, saves: 1),
        Row(nameKey: "onboarding_sample_player_3", goals: 1, assists: 1, saves: 6)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(NSLocalizedString("player", comment: ""))
                    .frame(maxWidth: .infinity, alignment: .leading)
                statHeader("goals_icon")
                statHeader("assists_icon")
                statHeader("saves_icon")
            }
            .font(.labelMedium)
            .foregroundColor(AppColor.onSurfaceVariant)
            .padding(.bottom, 8)

            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                Divider()
                HStack {
                    HStack(spacing: 6) {
                        if index == 0 {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.orange)
                        }
                        Text(NSLocalizedString(row.nameKey, comment: ""))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    statValue(row.goals)
                    statValue(row.assists)
                    statValue(row.saves)
                }
                .font(.labelSmall)
                .foregroundColor(AppColor.onSurface)
                .padding(.vertical, 10)
            }
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func statHeader(_ key: String) -> some View {
        Text(NSLocalizedString(key, comment: "")).frame(width: 40)
    }

    private func statValue(_ value: Int) -> some View {
        Text("\(value)").monospacedDigit().frame(width: 40)
    }
}
