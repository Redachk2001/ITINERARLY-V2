import SwiftUI

struct HomeView: View {
    let initialTab: AppMode?
    
    init(initialTab: AppMode? = nil) {
        self.initialTab = initialTab
    }
    
    var body: some View {
        TabView(selection: Binding(
            get: { 
                if let initialTab = initialTab {
                    switch initialTab {
                    case .planner: return 0
                    case .guidedTours: return 1
                    case .suggestions: return 2
                    case .adventure: return 3
                    }
                }
                return 0
            },
            set: { _ in }
        )) {
            // Planifier
            DayTripPlannerView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Planifier")
                }
                .tag(0)
            
            // Tours guidés
            GuidedToursView()
                .tabItem {
                    Image(systemName: "headphones")
                    Text("Tours guidés")
                }
                .tag(1)
            
            // Suggestions
            SuggestionView()
                .tabItem {
                    Image(systemName: "lightbulb.fill")
                    Text("Suggestions")
                }
                .tag(2)
            
            // Aventure
            AdventurerView()
                .tabItem {
                    Image(systemName: "dice.fill")
                    Text("Aventure")
                }
                .tag(3)
            
            // Profil
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profil")
                }
                .tag(4)
        }
        .accentColor(ItinerarlyTheme.ModeColors.planner)
    }
}