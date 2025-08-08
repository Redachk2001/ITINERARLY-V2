import SwiftUI

@main
struct ItinerarlyApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var locationManager = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(locationManager)
                .preferredColorScheme(.light)
        }
    }
} 