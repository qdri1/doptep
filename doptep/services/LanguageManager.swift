import Foundation

final class LanguageManager: ObservableObject {

    @Published private(set) var currentLanguage: String

    init() {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? "ru"
        currentLanguage = saved
        Bundle.setLanguage(saved)
    }

    func setLanguage(_ language: String) {
        UserDefaults.standard.set(language, forKey: "app_language")
        guard language != currentLanguage else { return }
        Bundle.setLanguage(language)
        currentLanguage = language
    }
}

// MARK: - Bundle swizzle

private var bundleLanguageKey: UInt8 = 0

extension Bundle {
    static func setLanguage(_ language: String) {
        objc_setAssociatedObject(Bundle.main, &bundleLanguageKey, language, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        object_setClass(Bundle.main, LanguageBundle.self)
    }
}

private final class LanguageBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard
            let language = objc_getAssociatedObject(self, &bundleLanguageKey) as? String,
            let path = super.path(forResource: language, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}
