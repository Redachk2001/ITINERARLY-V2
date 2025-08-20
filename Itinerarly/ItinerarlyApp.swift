import SwiftUI

@main
struct ItinerarlyApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(locationManager)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.useSystemTheme ? nil : (themeManager.isDarkMode ? .dark : .light))
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    themeManager.updateForSystemTheme()
                }
        }
    }
} 