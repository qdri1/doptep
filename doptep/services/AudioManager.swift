//
//  AudioManager.swift
//  doptep
//

import Foundation
import AVFoundation
import UserNotifications

final class AudioManager: NSObject, AVSpeechSynthesizerDelegate {

    static let shared = AudioManager()

    private var audioPlayer: AVAudioPlayer?
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var currentLanguageCode: String = "en"
    private var completion: (() -> Void)?

    override init() {
        super.init()
        setupAudioSession()
        loadLanguagePreference()
        speechSynthesizer.delegate = self
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    private func loadLanguagePreference() {
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "ru"
        currentLanguageCode = ttsPrefix(for: savedLanguage)
    }

    func setLanguage(_ languageCode: String) {
        currentLanguageCode = ttsPrefix(for: languageCode)
    }

    private func ttsPrefix(for appLanguage: String) -> String {
        switch appLanguage {
        case "ru": return "ru"
        case "kk-KZ", "kk": return "ru"
        default: return "en"
        }
    }

    private func bestVoice(for prefix: String) -> AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice.speechVoices().first { $0.language.hasPrefix(prefix) }
    }

    func playSound(_ fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") ??
                        Bundle.main.url(forResource: fileName, withExtension: "wav") ??
                        Bundle.main.url(forResource: fileName, withExtension: "m4a") else {
            print("Sound file not found: \(fileName)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }

    func speak(text: String, completion: (() -> Void)? = nil) {
        self.completion = completion
        
        speechSynthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = bestVoice(for: currentLanguageCode)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        speechSynthesizer.speak(utterance)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        completion?()
        completion = nil
    }

    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }

    func stopAudio() {
        audioPlayer?.stop()
    }

    func stopAll() {
        stopAudio()
        stopSpeaking()
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert]) { _, _ in }
    }

    func scheduleTimerMilestoneSound(soundName: String, afterSeconds: TimeInterval, identifier: String) {
        guard afterSeconds > 0 else { return }
        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(soundName).caf"))
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: afterSeconds, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelTimerMilestoneSounds() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["timer_minuta", "timer_do_auta"])
    }
}
