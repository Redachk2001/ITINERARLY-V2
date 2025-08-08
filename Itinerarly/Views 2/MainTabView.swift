import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int
    @StateObject private var audioService = AudioService()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var authManager = AuthManager()
    @EnvironmentObject var themeManager: ThemeManager
    
    init(initialTab: Int = 0) {
        self._selectedTab = State(initialValue: initialTab)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Planificateur de journée
            DayTripPlannerView()
                .tabItem {
                    Image(systemName: "calendar")
                    TranslatedText("Planifier")
                }
                .tag(0)
            
            // Tours guidés
            GuidedToursView()
                                    .tabItem {
                        Image(systemName: "headphones")
                        TranslatedText("Tours guidés")
                    }
                    .tag(1)
            
            // Suggestions
            SuggestionView()
                                    .tabItem {
                        Image(systemName: "lightbulb")
                        TranslatedText("Suggestions")
                    }
                    .tag(2)
            
            // Aventurier
            AdventurerView()
                .tabItem {
                    Image(systemName: "dice")
                    TranslatedText("Aventure")
                }
                .tag(3)
            
            // Profil
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    TranslatedText("Profil")
                }
                .tag(4)
        }
        .environmentObject(audioService)
        .environmentObject(locationManager)
        .environmentObject(authManager)
        .accentColor(Color(red: 0.31, green: 0.27, blue: 0.90)) // Couleur principale de l'app
        .onAppear {
            // Configuration de l'apparence des onglets
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
} 