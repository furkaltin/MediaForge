import Foundation
import SwiftUI

/// Language options supported by the application
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system" // Use system language
    case english = "en"
    case turkish = "tr"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .english: return "English"
        case .turkish: return "Türkçe"
        }
    }
    
    var localizedDisplayName: String {
        switch self {
        case .system: return "System"
        case .english: return NSLocalizedString("language_english", comment: "English language name")
        case .turkish: return NSLocalizedString("language_turkish", comment: "Turkish language name")
        }
    }
    
    var languageCode: String {
        switch self {
        case .system:
            // Locale.current.languageCode bazen "tr-TR" gibi bir format dönebiliyor
            // Sadece ilk iki karakteri alarak ISO 639 formatına uygun hale getiriyoruz
            let systemCode = Locale.current.languageCode ?? "en"
            if systemCode.contains("-") {
                return String(systemCode.prefix(2))
            }
            return systemCode
        case .english: return "en"
        case .turkish: return "tr"
        }
    }
    
    var flagEmoji: String {
        switch self {
        case .system: return "🌐"
        case .english: return "🇺🇸"
        case .turkish: return "🇹🇷"
        }
    }
}

/// Manages application language and localization
class LocalizationManager {
    // Singleton instance
    static let shared = LocalizationManager()
    
    // Key for saving language in UserDefaults
    private let languageKey = "app_language"
    
    // Current application language
    private(set) var currentLanguage: AppLanguage
    
    // Publisher for language changes
    let languageChangePublisher = NotificationCenter.default.publisher(for: Notification.Name("LanguageChanged"))
    
    private init() {
        // Load saved language or use system default
        if let savedLanguageRaw = UserDefaults.standard.string(forKey: languageKey),
           let savedLanguage = AppLanguage(rawValue: savedLanguageRaw) {
            currentLanguage = savedLanguage
        } else {
            currentLanguage = .system
        }
        
        // Apply the language
        applyLanguage()
    }
    
    /// Changes the application language
    func setLanguage(_ language: AppLanguage) {
        // Save the new language preference
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
        
        // Update current language
        currentLanguage = language
        
        // Apply the language
        applyLanguage()
        
        // Notify about language change
        NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
    }
    
    /// Applies the selected language to the application
    private func applyLanguage() {
        // Set the preferred language for the app
        // This affects which .lproj folder is used for localization
        let languageCode = currentLanguage.languageCode
        
        // Dil kodunun ISO 639 formatına uygun olduğundan emin olalım (iki harf)
        let validLanguageCode = languageCode.contains("-") ? String(languageCode.prefix(2)) : languageCode
        
        // Dil ayarını UserDefaults'a kaydet ve uygulama genelinde bildir
        UserDefaults.standard.set([validLanguageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Bundle'ı sıfırlayarak yerelleştirme değişikliklerinin hemen etkili olmasını sağla
        Bundle.main.localizations.forEach { _ in
            // Bundle önbelleğini temizle
            if let path = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: validLanguageCode) {
                // Bu, mevcut yerelleştirme önbelleğini sıfırlar
                _ = Bundle.main.localizedString(forKey: "", value: "", table: nil)
            }
        }
        
        // Log işlemi
        print("Dil \(validLanguageCode) olarak ayarlandı")
    }
}

// MARK: - String Extension for Localization

extension String {
    /// Returns a localized version of the string
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Returns a localized version of the string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        let localizedFormat = NSLocalizedString(self, comment: "")
        return String(format: localizedFormat, arguments: arguments)
    }
} 