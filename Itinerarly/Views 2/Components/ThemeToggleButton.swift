import SwiftUI

struct ThemeToggleButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingThemeSheet = false
    
    var body: some View {
        Button(action: {
            showingThemeSheet = true
        }) {
            Image(systemName: currentThemeIcon)
                .font(.title3)
                .foregroundColor(currentThemeColor)
        }
        .sheet(isPresented: $showingThemeSheet) {
            NavigationView {
                VStack(spacing: 20) {
                    ThemeSelectorView()
                        .padding()
                    
                    Spacer()
                }
                .navigationTitle("Apparence")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button("Fermer") {
                    showingThemeSheet = false
                })
            }
        }
    }
    
    private var currentThemeIcon: String {
        if themeManager.useSystemTheme {
            return "iphone"
        } else if themeManager.isDarkMode {
            return "moon.fill"
        } else {
            return "sun.max.fill"
        }
    }
    
    private var currentThemeColor: Color {
        if themeManager.useSystemTheme {
            return .blue
        } else if themeManager.isDarkMode {
            return .purple
        } else {
            return .orange
        }
    }
}

#Preview {
    ThemeToggleButton()
        .environmentObject(ThemeManager())
        .environmentObject(LanguageManager.shared)
}
