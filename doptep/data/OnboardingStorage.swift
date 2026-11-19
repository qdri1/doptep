//
//  OnboardingStorage.swift
//  doptep
//

import Foundation

final class OnboardingStorage {

    static let shared = OnboardingStorage()

    private let defaults = UserDefaults.standard
    private let completedKey = "onboarding_completed"
    private let startedKey = "onboarding_started"

    private init() {}

    var isCompleted: Bool {
        defaults.bool(forKey: completedKey)
    }

    func setCompleted() {
        defaults.set(true, forKey: completedKey)
    }

    /// Set once the language is picked, so an onboarding left halfway is shown again on the next launch
    /// (the language is already saved by then, so it can't be used to detect a fresh install).
    var isStarted: Bool {
        defaults.bool(forKey: startedKey)
    }

    func setStarted() {
        defaults.set(true, forKey: startedKey)
    }
}
