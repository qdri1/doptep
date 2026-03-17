//
//  RemoteConfigManager.swift
//  doptep
//

import Foundation
import FirebaseRemoteConfig

final class RemoteConfigManager {

    static let shared = RemoteConfigManager()

    private let remoteConfig = RemoteConfig.remoteConfig()

    private init() {}

    func configureAndActivate() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 300
        remoteConfig.configSettings = settings
        remoteConfig.fetchAndActivate()
    }

    var telegramUrl: String {
        remoteConfig.configValue(forKey: "telegram_url").stringValue
    }

    var whatsappUrl: String {
        remoteConfig.configValue(forKey: "whatsapp_url").stringValue
    }

    var activationCode: String {
        let value = remoteConfig.configValue(forKey: "activation_code").stringValue
        return value.isEmpty ? "Dop-Tep" : value
    }
}
