//
//  Analytics.swift
//  doptep
//
//  Product analytics (Amplitude). Event names and properties are the same on iOS and Android —
//  keep them in sync with the Android `Analytics` when adding new ones.
//  No personal data: never send player names or team names.
//

import Foundation
#if canImport(AmplitudeSwift)
import AmplitudeSwift
#endif

final class Analytics {

    static let shared = Analytics()

    private let apiKey = "e02088d75933e61d44da927f590b7edb"

    #if canImport(AmplitudeSwift)
    private var amplitude: Amplitude?
    #endif

    private init() {}

    /// Call once at app start, so sessions and app opens are counted from the very first screen.
    func configure() {
        #if canImport(AmplitudeSwift)
        guard amplitude == nil else { return }
        amplitude = Amplitude(configuration: Configuration(
            apiKey: apiKey,
            autocapture: [.sessions, .appLifecycles]
        ))
        #endif
    }

    func track(_ event: String, _ properties: [String: Any?] = [:]) {
        #if canImport(AmplitudeSwift)
        let props = properties.compactMapValues { $0 }
        amplitude?.track(eventType: event, eventProperties: props.isEmpty ? nil : props)
        #endif
    }

    /// RevenueCat App User ID: lets the RevenueCat → Amplitude integration match purchases to the same user.
    func setUserId(_ userId: String?) {
        #if canImport(AmplitudeSwift)
        guard let userId, !userId.isEmpty, amplitude?.getUserId() != userId else { return }
        amplitude?.setUserId(userId: userId)
        #endif
    }

    func setBillingType(_ billingType: BillingType) {
        setUserProperty(AnalyticsUserProperty.billingType, billingType.analyticsValue)
    }

    func setLanguage(_ languageCode: String) {
        setUserProperty(AnalyticsUserProperty.language, languageCode)
    }

    func trackLanguageSelected(_ language: String, source: String) {
        let code = analyticsLanguageCode(language)
        setLanguage(code)
        track(AnalyticsEvent.languageSelected, [AnalyticsParam.language: code, AnalyticsParam.source: source])
    }

    func setOnboardingCompleted(_ completed: Bool) {
        setUserProperty(AnalyticsUserProperty.onboardingCompleted, completed)
    }

    private func setUserProperty(_ name: String, _ value: Any) {
        #if canImport(AmplitudeSwift)
        let identify = Identify()
        identify.set(property: name, value: value)
        amplitude?.identify(identify: identify)
        #endif
    }
}

enum AnalyticsEvent {
    // Onboarding
    static let onboardingStarted = "onboarding_started"
    static let onboardingStepViewed = "onboarding_step_viewed"
    static let onboardingCompleted = "onboarding_completed"
    static let languageSelected = "language_selected"
    static let languageRequested = "language_requested"
    static let notificationPermissionResult = "notification_permission_result"

    // Games
    static let gameCreated = "game_created"
    static let gameOpened = "game_opened"
    static let matchStarted = "match_started"
    static let matchFinished = "match_finished"
    static let gameActionRecorded = "game_action_recorded"
    static let soundPlayed = "sound_played"
    static let functionOpened = "function_opened"
    static let resultsViewed = "results_viewed"

    // Monetization
    static let limitReached = "limit_reached"
    static let paywallViewed = "paywall_viewed"
    static let planSelected = "plan_selected"
    static let purchaseStarted = "purchase_started"
    static let purchaseCompleted = "purchase_completed"
    static let purchaseCancelled = "purchase_cancelled"
    static let purchaseFailed = "purchase_failed"
    static let purchasePending = "purchase_pending"
    static let restorePurchasesTapped = "restore_purchases_tapped"
    static let manageSubscriptionTapped = "manage_subscription_tapped"
}

enum AnalyticsParam {
    static let step = "step"
    static let index = "index"
    static let language = "language"
    static let source = "source"
    static let granted = "granted"
    static let teamQuantity = "team_quantity"
    static let gameFormat = "game_format"
    static let matchMinutes = "match_minutes"
    static let rule = "rule"
    static let pitchSurface = "pitch_surface"
    static let matchesPlayed = "matches_played"
    static let matchNumber = "match_number"
    static let result = "result"
    static let durationSec = "duration_sec"
    static let type = "type"
    static let sound = "sound"
    static let function = "function"
    static let locked = "locked"
    /// match_started / match_finished: the free limit of this game is used up and the user has no full version.
    static let limited = "limited"
    static let plan = "plan"
    static let reason = "reason"
}

/// Values of the `source` param of `paywall_viewed`, `function_opened`, `language_selected`.
enum AnalyticsSource {
    static let onboarding = "onboarding"
    static let settings = "settings"
    static let limit = "limit"
    static let game = "game"
    static let results = "results"
}

private enum AnalyticsUserProperty {
    static let billingType = "billing_type"
    static let language = "language"
    static let onboardingCompleted = "onboarding_completed"
}

extension BillingType {
    var analyticsValue: String {
        switch self {
        case .limited: return "free"
        case .subscribe: return "subscribe"
        case .lifetime: return "lifetime"
        case .oneday: return "one_day"
        }
    }
}

extension ActivationPlan {
    var analyticsValue: String {
        switch self {
        case .monthly: return "monthly"
        case .yearly: return "yearly"
        case .unlimited: return "lifetime"
        case .oneday: return "one_day"
        }
    }
}

/// "kk-KZ" → "kk": the same language codes as on Android (kk / ru / en).
func analyticsLanguageCode(_ language: String) -> String {
    String(language.prefix { $0 != "-" && $0 != "_" })
}

/// Enum case name in snake_case: `penaltyRealMadrid` → "penalty_real_madrid", `only2Games` → "only_2_games".
/// Matches the Android values (built from the Kotlin enum names), so both platforms chart together.
func analyticsValue<T>(_ value: T) -> String {
    var name = String(describing: value)
    if let parenthesis = name.firstIndex(of: "(") { name = String(name[..<parenthesis]) } // cases with associated values
    name = name.replacingOccurrences(of: "([a-z])([0-9])", with: "$1_$2", options: .regularExpression)
    name = name.replacingOccurrences(of: "([a-z0-9])([A-Z])", with: "$1_$2", options: .regularExpression)
    return name.lowercased()
}
