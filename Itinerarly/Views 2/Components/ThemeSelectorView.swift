import SwiftUI

struct ThemeSelectorView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Titre
            HStack {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(ItinerarlyTheme.ModeColors.profile)
                TranslatedText("Apparence")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Options de thème
            VStack(spacing: 12) {
                // Mode système
                ThemeOptionCard(
                    title: languageManager.translate("Suivre le système"),
                    subtitle: languageManager.translate("Automatique"),
                    icon: "iphone",
                    iconColor: .blue,
                    isSelected: themeManager.useSystemTheme,
                    action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            themeManager.useSystemTheme = true
                        }
                    }
                )
                
                // Mode clair
                ThemeOptionCard(
                    title: languageManager.translate("Mode clair"),
                    subtitle: languageManager.translate("Toujours clair"),
                    icon: "sun.max.fill",
                    iconColor: .orange,
                    isSelected: !themeManager.useSystemTheme && !themeManager.isDarkMode,
                    action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            themeManager.useSystemTheme = false
                            themeManager.isDarkMode = false
                        }
                    }
                )
                
                // Mode sombre
                ThemeOptionCard(
                    title: languageManager.translate("Mode sombre"),
                    subtitle: languageManager.translate("Toujours sombre"),
                    icon: "moon.fill",
                    iconColor: .purple,
                    isSelected: !themeManager.useSystemTheme && themeManager.isDarkMode,
                    action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            themeManager.useSystemTheme = false
                            themeManager.isDarkMode = true
                        }
                    }
                )
            }
        }
        .padding()
        .background(ItinerarlyTheme.Backgrounds.card)
        .cornerRadius(ItinerarlyTheme.CornerRadius.lg)
    }
}

struct ThemeOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icône
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.1))
                    .cornerRadius(8)
                
                // Texte
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Indicateur de sélection
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ItinerarlyTheme.ModeColors.profile)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? ItinerarlyTheme.ModeColors.profile.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? ItinerarlyTheme.ModeColors.profile : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ThemeSelectorView()
        .environmentObject(ThemeManager())
        .environmentObject(LanguageManager.shared)
        .padding()
}
