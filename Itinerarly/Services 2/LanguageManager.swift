import SwiftUI

// Cache et gestion des traductions
class TranslationCache: ObservableObject {
    @Published var translations: [String: String] = [:]
    @Published var isLoading: Set<String> = []
    
    func getCachedTranslation(for key: String, to language: AppLanguage) -> String? {
        return translations["\(key)_\(language.rawValue)"]
    }
    
    func setCachedTranslation(_ translation: String, for key: String, to language: AppLanguage) {
        DispatchQueue.main.async {
            self.translations["\(key)_\(language.rawValue)"] = translation
        }
    }
    
    func isTranslating(_ key: String, to language: AppLanguage) -> Bool {
        return isLoading.contains("\(key)_\(language.rawValue)")
    }
    
    func setLoading(_ key: String, to language: AppLanguage, loading: Bool) {
        DispatchQueue.main.async {
            let translationKey = "\(key)_\(language.rawValue)"
            if loading {
                self.isLoading.insert(translationKey)
            } else {
                self.isLoading.remove(translationKey)
            }
        }
    }
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    @Published var current: AppLanguage {
        didSet {
            print("🚀 Language changed from \(oldValue.rawValue) to \(current.rawValue)")
            UserDefaults.standard.set(current.rawValue, forKey: "app_language")
            // RTL support for Arabic
            if current == .arabic {
                UIView.appearance().semanticContentAttribute = .forceRightToLeft
            } else {
                UIView.appearance().semanticContentAttribute = .unspecified
            }
            
            // Pré-charger les traductions courantes
            preloadCommonTranslations()
        }
    }
    
    @Published var translationCache = TranslationCache()
    
    var locale: Locale { Locale(identifier: current.localeId) }
    var isRTL: Bool { current == .arabic }
    
    init() {
        if let code = UserDefaults.standard.string(forKey: "app_language"), let lang = AppLanguage(rawValue: code) {
            self.current = lang
        } else {
            self.current = .french
        }
        preloadCommonTranslations()
    }
    
    private func preloadCommonTranslations() {
        guard current != .french else { return }
        
        let commonTexts = [
            "Planifier", "Tours guidés", "Suggestions", "Aventure", "Profil",
            "Point de départ", "Rayon de recherche", "Temps disponible", "Mode de transport",
            "Paramètres", "Langue", "Historique", "Aide", "À propos", "Fermer",
            "Notifications", "Services de localisation", "Sauvegarde automatique", "Mode sombre",
            "Unités", "Créez un itinéraire optimisé pour votre journée"
        ]
        
        TranslationService.shared.warmup(strings: commonTexts, from: "fr", to: current.rawValue)
    }
    
    func translate(_ text: String) -> String {
        guard current != .french else { 
            print("🔄 Language is French, returning original: \(text)")
            return text 
        }
        
        print("🌍 Translating '\(text)' from fr to \(current.rawValue)")
        
        // Retour instant avec cache ou texte original
        let result = TranslationService.shared.translateInstant(text: text, from: "fr", to: current.rawValue)
        print("📝 Translation result: \(result)")
        return result
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case french = "fr"
    case english = "en"
    case german = "de"
    case spanish = "es"
    case chinese = "zh-Hans"
    case arabic = "ar"
    
    var id: String { rawValue }
    var localeId: String { rawValue }
    
    var displayName: String {
        switch self {
        case .french: return "Français"
        case .english: return "English"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        case .chinese: return "中文"
        case .arabic: return "العربية"
        }
    }
}

