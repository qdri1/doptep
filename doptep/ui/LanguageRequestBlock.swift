//
//  LanguageRequestBlock.swift
//  doptep
//
//  "Missing your language? Request it" at the bottom of a language list.
//  Opens an alert with a text field; the entered language only goes to analytics.
//

import SwiftUI

struct LanguageRequestTexts {
    let question: String
    let button: String
    let dialogTitle: String
    let hint: String
    let send: String
    let cancel: String
    let thanks: String

    /// Texts in the app language (settings: the language is already chosen).
    static var localized: LanguageRequestTexts {
        LanguageRequestTexts(
            question: NSLocalizedString("language_request_question", comment: ""),
            button: NSLocalizedString("language_request_button", comment: ""),
            dialogTitle: NSLocalizedString("language_request_dialog_title", comment: ""),
            hint: NSLocalizedString("language_request_hint", comment: ""),
            send: NSLocalizedString("language_request_send", comment: ""),
            cancel: NSLocalizedString("language_request_cancel", comment: ""),
            thanks: NSLocalizedString("language_request_thanks", comment: "")
        )
    }

    /// Onboarding: no language is chosen yet, so Russian and English together (like the step subtitle).
    static let onboarding = LanguageRequestTexts(
        question: "Нет вашего языка? · Missing your language?",
        button: "Попросить добавить · Request it",
        dialogTitle: "Какой язык добавить? · Which language should we add?",
        hint: "Например, Узбекский · e.g. Uzbek",
        send: "Отправить · Send",
        cancel: "Отмена · Cancel",
        thanks: "Отправлено · Sent"
    )
}

struct LanguageRequestBlock: View {
    let texts: LanguageRequestTexts
    /// Where the block is shown (AnalyticsSource).
    let source: String

    /// Longest text sent to analytics: a language name, not a message.
    private let maxLength = 40

    @State private var showDialog = false
    @State private var showThanks = false
    @State private var value = ""

    private var language: String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(verbatim: texts.question)
                .font(.labelSmall)
                .foregroundColor(AppColor.onSurfaceVariant)
                .multilineTextAlignment(.center)

            Button {
                value = ""
                showDialog = true
            } label: {
                Text(verbatim: texts.button)
                    .font(.labelLarge)
                    .foregroundColor(AppColor.primary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .alert(Text(verbatim: texts.dialogTitle), isPresented: $showDialog) {
            TextField(texts.hint, text: $value)
                .textInputAutocapitalization(.sentences)
                .onChange(of: value) { _, newValue in
                    if newValue.count > maxLength { value = String(newValue.prefix(maxLength)) }
                }
            Button(texts.send) {
                Analytics.shared.track(AnalyticsEvent.languageRequested, [
                    AnalyticsParam.language: language,
                    AnalyticsParam.source: source,
                ])
                showThanks = true
            }
            .disabled(language.isEmpty)
            Button(texts.cancel, role: .cancel) {}
        }
        .alert(Text(verbatim: texts.thanks), isPresented: $showThanks) {
            Button("OK", role: .cancel) {}
        }
    }
}
