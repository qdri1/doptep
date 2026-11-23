//
//  OnboardingViewModel.swift
//  doptep
//

import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {

    @Published private(set) var step: OnboardingStep = .language
    /// Language code picked on the first step ("kk-KZ", "ru", "en").
    @Published private(set) var selectedLanguage: String?
    @Published private(set) var isMovingForward = true
    @Published private(set) var isVoicePlaying = false
    @Published var effect: OnboardingEffect?

    private let storage: OnboardingStorage
    /// Guards against a double tap on "Allow" / "Not now" finishing the onboarding twice.
    private var isFinished = false
    private let audioManager: AudioManager

    init(storage: OnboardingStorage = .shared, audioManager: AudioManager = .shared) {
        self.storage = storage
        self.audioManager = audioManager
        // "Started" is saved when the language is picked, so reopening the onboarding doesn't count it twice.
        if !storage.isStarted {
            Analytics.shared.track(AnalyticsEvent.onboardingStarted)
            trackStepViewed(step)
        }
    }

    private func trackStepViewed(_ step: OnboardingStep) {
        Analytics.shared.track(AnalyticsEvent.onboardingStepViewed, [
            AnalyticsParam.step: analyticsValue(step),
            AnalyticsParam.index: step.rawValue,
        ])
    }

    var progress: Double {
        Double(step.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }

    var canContinue: Bool {
        switch step {
        case .language: return selectedLanguage != nil
        default: return true
        }
    }

    func send(_ action: OnboardingAction) {
        switch action {
        case .onContinueClicked:
            goForward()
        case .onBackClicked:
            goBack()
        case .onLanguageSelected(let language):
            selectedLanguage = language
            audioManager.setLanguage(language)
            storage.setStarted()
            Analytics.shared.trackLanguageSelected(language, source: AnalyticsSource.onboarding)
        case .onVoiceDemoClicked:
            playVoiceDemo()
        case .onAllowNotificationsClicked:
            guard !isFinished else { return }
            // The system dialog is shown on top; onboarding ends once the user answers it.
            audioManager.requestNotificationPermission { [weak self] granted in
                Analytics.shared.track(AnalyticsEvent.notificationPermissionResult, [AnalyticsParam.granted: granted])
                self?.finish()
            }
        case .onSkipNotificationsClicked:
            Analytics.shared.track(AnalyticsEvent.notificationPermissionResult, [AnalyticsParam.granted: false])
            finish()
        }
    }

    private func finish() {
        guard !isFinished else { return }
        isFinished = true
        stopAudio()
        storage.setCompleted()
        Analytics.shared.track(AnalyticsEvent.onboardingCompleted)
        Analytics.shared.setOnboardingCompleted(true)
        effect = .finish
    }

    private func goForward() {
        guard canContinue,
              let next = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        move(to: next, forward: true)
        trackStepViewed(next)
    }

    private func goBack() {
        guard let previous = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        move(to: previous, forward: false)
    }

    /// SwiftUI animates the removal of the outgoing step with the transition it had on its last render.
    /// If the direction and the step changed in the same update, the outgoing step would still slide
    /// the old way. So the direction is applied first and the step changes on the next run loop.
    private func move(to newStep: OnboardingStep, forward: Bool) {
        stopAudio()
        isMovingForward = forward
        DispatchQueue.main.async { [weak self] in
            self?.step = newStep
        }
    }

    private func playVoiceDemo() {
        guard !isVoicePlaying else { return }
        isVoicePlaying = true
        let name = NSLocalizedString("onboarding_sample_player_1", comment: "")
        let text = String(format: NSLocalizedString("text_to_speech_goal", comment: ""), name)
        audioManager.speak(text: text) { [weak self] in
            Task { @MainActor in
                guard let self, self.isVoicePlaying else { return }
                self.audioManager.playSound("suiii_full")
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                self.isVoicePlaying = false
            }
        }
    }

    private func stopAudio() {
        guard isVoicePlaying else { return }
        isVoicePlaying = false
        audioManager.stopAll()
    }
}
