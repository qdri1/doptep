//
//  OnboardingModels.swift
//  doptep
//

import Foundation

enum OnboardingStep: Int, CaseIterable {
    case language
    case welcome
    case rotation
    case stats
    case sounds
    case notifications
}

enum OnboardingAction {
    case onContinueClicked
    case onBackClicked
    case onLanguageSelected(String)
    case onVoiceDemoClicked
    case onAllowNotificationsClicked
    case onSkipNotificationsClicked
}

enum OnboardingEffect: Equatable {
    case finish
}
