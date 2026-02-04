//
//  AudioManager.swift
//  doptep
//

import Foundation
import AVFoundation

final class AudioManager: ObservableObject {

    private var audioPlayer: AVAudioPlayer?
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var currentLanguage: String = "en-US"

    init() {
        setupAudioSession()
        loadLanguagePreference()
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
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "en"
        currentLanguage = savedLanguage == "ru" ? "ru-RU" : "en-US"
    }

    func setLanguage(_ languageCode: String) {
        currentLanguage = languageCode == "ru" ? "ru-RU" : "en-US"
        UserDefaults.standard.set(languageCode, forKey: "app_language")
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
        speechSynthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: currentLanguage)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        speechSynthesizer.speak(utterance)
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
}
