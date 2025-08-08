import SwiftUI

// Composant Text qui se traduit automatiquement selon la langue sélectionnée
struct TranslatedText: View {
    let text: String
    let font: Font?
    let color: Color?
    
    @EnvironmentObject var languageManager: LanguageManager
    @State private var translatedText: String = ""
    @State private var isLoading: Bool = false
    
    init(_ text: String, font: Font? = nil, color: Color? = nil) {
        self.text = text
        self.font = font
        self.color = color
        self._translatedText = State(initialValue: text)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // N'applique la police/couleur que si elles sont fournies
            Group {
                if let font = font, let color = color {
                    Text(translatedText)
                        .font(font)
                        .foregroundColor(color)
                } else if let font = font {
                    Text(translatedText)
                        .font(font)
                } else if let color = color {
                    Text(translatedText)
                        .foregroundColor(color)
                } else {
                    Text(translatedText)
                }
            }

            if isLoading {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 12, height: 12)
            }
        }
        .onAppear {
            updateTranslation()
        }
        .onChange(of: languageManager.current) { _ in
            updateTranslation()
        }
        .onReceive(NotificationCenter.default.publisher(for: TranslationService.didUpdateNotification)) { notification in
            if let info = notification.object as? TranslationService.UpdateInfo,
               info.originalText == text,
               info.targetLanguage == languageManager.current.rawValue {
                DispatchQueue.main.async {
                    translatedText = info.translatedText
                    isLoading = false
                }
            }
        }
    }
    
    private func updateTranslation() {
        guard languageManager.current != .french else {
            translatedText = text
            isLoading = false
            return
        }
        
        // Check cache first
        if let cached = languageManager.translationCache.getCachedTranslation(for: text, to: languageManager.current) {
            translatedText = cached
            isLoading = false
        } else {
            // Show original text immediately, then translate
            translatedText = text
            isLoading = true
            
            // Trigger translation
            Task {
                let result = TranslationService.shared.translateInstant(
                    text: text,
                    from: "fr",
                    to: languageManager.current.rawValue
                )
                
                DispatchQueue.main.async {
                    translatedText = result
                    if result == text {
                        // Still original text, translation is pending
                        isLoading = true
                    } else {
                        // Got translation
                        isLoading = false
                    }
                }
            }
        }
    }
}

// Extensions pour faciliter l'usage
extension Text {
    func translated(font: Font? = nil, color: Color? = nil) -> some View {
        // Cette extension ne peut pas fonctionner directement car on ne peut pas accéder au text du Text
        // Il faut utiliser TranslatedText directement
        self
    }
}

// Helper pour créer du texte traduit avec style
struct StyledTranslatedText: View {
    let text: String
    let style: TextStyle
    
    @EnvironmentObject var languageManager: LanguageManager
    
    enum TextStyle {
        case title
        case headline
        case subheadline
        case body
        case caption
        case button
        
        var font: Font {
            switch self {
            case .title: return .title
            case .headline: return .headline
            case .subheadline: return .subheadline
            case .body: return .body
            case .caption: return .caption
            case .button: return .headline
            }
        }
        
        var color: Color? {
            switch self {
            case .button: return .white
            default: return nil
            }
        }
    }
    
    var body: some View {
        TranslatedText(text, font: style.font, color: style.color)
    }
}

// Convenience initializers
extension TranslatedText {
    static func title(_ text: String) -> some View {
        StyledTranslatedText(text: text, style: .title)
    }
    
    static func headline(_ text: String) -> some View {
        StyledTranslatedText(text: text, style: .headline)
    }
    
    static func subheadline(_ text: String) -> some View {
        StyledTranslatedText(text: text, style: .subheadline)
    }
    
    static func body(_ text: String) -> some View {
        StyledTranslatedText(text: text, style: .body)
    }
    
    static func caption(_ text: String) -> some View {
        StyledTranslatedText(text: text, style: .caption)
    }
}