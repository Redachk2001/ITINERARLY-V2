import SwiftUI

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "darkModeEnabled")
            applyTheme()
        }
    }
    
    init() {
        // Charger la préférence sauvegardée ou utiliser le mode système par défaut
        self.isDarkMode = UserDefaults.standard.bool(forKey: "darkModeEnabled")
    }
    
    private func applyTheme() {
        // Appliquer le thème à toutes les fenêtres
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager.shared
    @State private var showSplash = true
    @State private var showWelcome = false
    
    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showSplash = false
                                showWelcome = true
                            }
                        }
                    }
            } else if showWelcome {
                WelcomePageView()
            } else if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .animation(.easeInOut(duration: 0.5), value: showWelcome)
        .animation(.easeInOut(duration: 0.5), value: authManager.isAuthenticated)
        .environmentObject(themeManager)
        .environmentObject(languageManager)
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(LocationManager())
} 