import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var audioService: AudioService
    @StateObject private var statisticsService = UserStatisticsService()
    @State private var showingLogoutAlert = false
    @State private var showingAudioSettings = false
    @State private var showingSubscription = false
    @State private var showingFavorites = false
    @State private var showingHistory = false
    @State private var showingSettings = false
    @State private var showingHelp = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                            
                            Text(authManager.currentUser?.name.first?.uppercased() ?? "U")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text(authManager.currentUser?.name ?? "Utilisateur")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(authManager.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top)
                    
                    // Stats Card
                    VStack(spacing: 16) {
                        Text("Vos statistiques")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        HStack {
                            StatCard(
                                icon: "map",
                                title: "Itinéraires",
                                value: "\(statisticsService.statistics.itinerariesCount)",
                                color: .blue
                            )
                            
                            StatCard(
                                icon: "headphones",
                                title: "Tours guidés",
                                value: "\(statisticsService.statistics.guidedToursCount)",
                                color: .purple
                            )
                            
                            StatCard(
                                icon: "location",
                                title: "Aventures",
                                value: "\(statisticsService.statistics.adventuresCount)",
                                color: .red
                            )
                        }
                        
                        // Additional Stats
                        VStack(spacing: 12) {
                            HStack {
                                StatChip(
                                    icon: "route",
                                    text: statisticsService.statistics.formattedTotalDistance,
                                    color: .green
                                )
                                
                                StatChip(
                                    icon: "clock",
                                    text: statisticsService.statistics.formattedTotalDuration,
                                    color: .orange
                                )
                            }
                            
                            if statisticsService.statistics.itinerariesCount + statisticsService.statistics.guidedToursCount + statisticsService.statistics.adventuresCount == 0 {
                                Text("Commencez à explorer pour voir vos statistiques !")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    // Menu Options
                    VStack(spacing: 12) {
                        ProfileMenuRow(
                            icon: "clock.arrow.circlepath",
                            title: "Historique des activités",
                            subtitle: "Consultez vos sorties passées"
                        ) {
                            showingHistory = true
                        }
                        
                        ProfileMenuRow(
                            icon: "heart",
                            title: "Lieux favoris",
                            subtitle: "Vos découvertes préférées"
                        ) {
                            showingFavorites = true
                        }
                        
                        ProfileMenuRow(
                            icon: "gear",
                            title: "Paramètres",
                            subtitle: "Notifications et préférences"
                        ) {
                            showingSettings = true
                        }
                        
                        ProfileMenuRow(
                            icon: "speaker.wave.2",
                            title: "Paramètres Audio",
                            subtitle: "Voix d'audio guide et préférences"
                        ) {
                            showingAudioSettings = true
                        }
                        
                        ProfileMenuRow(
                            icon: "questionmark.circle",
                            title: "Aide et support",
                            subtitle: "FAQ et assistance"
                        ) {
                            showingHelp = true
                        }
                        
                        ProfileMenuRow(
                            icon: "crown",
                            title: "Abonnement Premium",
                            subtitle: "Débloquez toutes les fonctionnalités"
                        ) {
                            showingSubscription = true
                        }
                        
                        ProfileMenuRow(
                            icon: "info.circle",
                            title: "À propos",
                            subtitle: "Version et informations"
                        ) {
                            showingAbout = true
                        }
                        
                        // Bouton de test pour réinitialiser les statistiques (à supprimer en production)
                        ProfileMenuRow(
                            icon: "arrow.clockwise",
                            title: "Réinitialiser les statistiques",
                            subtitle: "Remettre à zéro (test uniquement)"
                        ) {
                            statisticsService.resetStatistics()
                        }
                    }
                    
                    // Logout Button
                    Button(action: { showingLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Se déconnecter")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingAudioSettings) {
            AudioSettingsView()
                .environmentObject(audioService)
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
        .sheet(isPresented: $showingFavorites) {
            FavoritesView()
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert("Déconnexion", isPresented: $showingLogoutAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Déconnexion", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir vous déconnecter ?")
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}

// MARK: - Temporary Views for Profile Options

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var statisticsService = UserStatisticsService()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Statistiques récapitulatives
                    VStack(spacing: 16) {
                        Text("Récapitulatif de vos activités")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        HStack {
                            StatCard(
                                icon: "map",
                                title: "Itinéraires",
                                value: "\(statisticsService.statistics.itinerariesCount)",
                                color: .blue
                            )
                            
                            StatCard(
                                icon: "headphones",
                                title: "Tours guidés",
                                value: "\(statisticsService.statistics.guidedToursCount)",
                                color: .purple
                            )
                        }
                        
                        HStack {
                            StatCard(
                                icon: "location",
                                title: "Aventures",
                                value: "\(statisticsService.statistics.adventuresCount)",
                                color: .red
                            )
                            
                            StatCard(
                                icon: "heart",
                                title: "Favoris",
                                value: "12",
                                color: .pink
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Activités récentes
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Activités récentes")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            ActivityRow(
                                icon: "map",
                                title: "Itinéraire Paris - Louvre",
                                subtitle: "Il y a 2 jours",
                                color: .blue
                            )
                            
                            ActivityRow(
                                icon: "headphones",
                                title: "Tour guidé - Montmartre",
                                subtitle: "Il y a 1 semaine",
                                color: .purple
                            )
                            
                            ActivityRow(
                                icon: "location",
                                title: "Aventure - Découverte insolite",
                                subtitle: "Il y a 2 semaines",
                                color: .red
                            )
                            
                            ActivityRow(
                                icon: "heart",
                                title: "Restaurant Le Petit Bistrot",
                                subtitle: "Ajouté aux favoris",
                                color: .pink
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Historique")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Fermer") { dismiss() })
        }
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @State private var notificationsEnabled = true
    @State private var locationServicesEnabled = true
    @State private var autoSaveEnabled = true
    @State private var language = "Français"
    @State private var units = "Métrique"
    
    @State private var showingLanguageSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Notifications
                    VStack(alignment: .leading, spacing: 16) {
                        TranslatedText("Notifications")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            Toggle(languageManager.translate("Notifications push"), isOn: $notificationsEnabled)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            Toggle(languageManager.translate("Nouvelles fonctionnalités"), isOn: $notificationsEnabled)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            Toggle(languageManager.translate("Rappels d'activités"), isOn: $notificationsEnabled)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Services
                    VStack(alignment: .leading, spacing: 16) {
                        TranslatedText("Services")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            Toggle(languageManager.translate("Services de localisation"), isOn: $locationServicesEnabled)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            Toggle(languageManager.translate("Sauvegarde automatique"), isOn: $autoSaveEnabled)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Apparence
                    VStack(alignment: .leading, spacing: 16) {
                        TranslatedText("Apparence")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Toggle(languageManager.translate("Mode sombre"), isOn: $themeManager.isDarkMode)
                                
                                Spacer()
                                
                                Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                                    .foregroundColor(themeManager.isDarkMode ? .purple : .orange)
                                    .font(.title3)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            Button(action: { 
                                print("Bouton Langue appuyé!")
                                showingLanguageSheet = true 
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        TranslatedText("Langue")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        Text(languageManager.current.displayName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(flagEmoji(for: languageManager.current))
                                        .font(.title3)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .sheet(isPresented: $showingLanguageSheet) {
                                NavigationView {
                                    LanguageSelectionView()
                                        .environmentObject(languageManager)
                                }
                            }
                            
                            HStack {
                                TranslatedText("Unités")
                                Spacer()
                                Text(units)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle(languageManager.translate("Paramètres"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(languageManager.translate("Fermer")) { dismiss() })
        }
        .onChange(of: languageManager.current) { newValue in
            // pré-traduire des libellés fréquents pour accélérer l'UI
            let common = [
                "Planifier","Tours guidés","Suggestions","Aventure","Profil",
                "Point de départ","Rayon de recherche","Temps disponible","Mode de transport",
                "Paramètres","Langue","Fermer","Notifications","Services","Apparence",
                "Mode sombre","Unités","Services de localisation","Sauvegarde automatique",
                "Notifications push","Nouvelles fonctionnalités","Rappels d'activités"
            ]
            TranslationService.shared.warmup(strings: common, from: "fr", to: newValue.rawValue)
            
            // Force UI refresh
            DispatchQueue.main.async {
                // Trigger a view refresh by changing a dummy state
            }
        }
    }
    
    private func flagEmoji(for language: AppLanguage) -> String {
        switch language {
        case .french: return "🇫🇷"
        case .english: return "🇺🇸"
        case .german: return "🇩🇪"
        case .spanish: return "🇪🇸"
        case .chinese: return "🇨🇳"
        case .arabic: return "🇸🇦"
        }
    }
}

// Sélection de langue (liste à checkmark)
struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var languageManager: LanguageManager
    @State private var isTranslating = false
    
    var body: some View {
        VStack {
                if isTranslating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        TranslatedText("Mise à jour de l'interface...", font: .caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                List {
                    ForEach(AppLanguage.allCases) { lang in
                        HStack {
                            Text(lang.displayName)
                                .font(.body)
                            Spacer()
                            
                            // Drapeau emoji (optionnel)
                            Text(flagEmoji(for: lang))
                                .font(.title2)
                            
                            if lang == languageManager.current {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            changeLanguage(to: lang)
                        }
                    }
                }
        }
        .navigationTitle(languageManager.translate("Langue"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { 
            ToolbarItem(placement: .cancellationAction) { 
                Button(languageManager.translate("Fermer")) { dismiss() }
            } 
        }
    }
    
    private func changeLanguage(to language: AppLanguage) {
        guard language != languageManager.current else { return }
        
        isTranslating = true
        
        // Délai pour montrer l'indicateur
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            languageManager.current = language
            
            // Fermer après changement
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isTranslating = false
                dismiss()
            }
        }
    }
    
    private func flagEmoji(for language: AppLanguage) -> String {
        switch language {
        case .french: return "🇫🇷"
        case .english: return "🇺🇸"
        case .german: return "🇩🇪"
        case .spanish: return "🇪🇸"
        case .chinese: return "🇨🇳"
        case .arabic: return "🇸🇦"
        }
    }
}

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    let faqItems = [
        FAQItem(
            question: "Comment créer un itinéraire ?",
            answer: "Allez dans l'onglet 'Planifier', choisissez votre point de départ, ajoutez vos destinations et générez votre itinéraire optimisé."
        ),
        FAQItem(
            question: "Comment utiliser les tours guidés ?",
            answer: "Sélectionnez une ville dans l'onglet 'Tours guidés', choisissez un tour et suivez le guide audio détaillé."
        ),
        FAQItem(
            question: "Comment fonctionne le mode Aventure ?",
            answer: "Le mode Aventure vous propose des lieux insolites et surprenants basés sur vos préférences et votre localisation."
        ),
        FAQItem(
            question: "Comment ajouter des lieux aux favoris ?",
            answer: "Tapez sur l'icône cœur à côté d'un lieu pour l'ajouter à vos favoris et le retrouver facilement."
        ),
        FAQItem(
            question: "Comment modifier mes paramètres audio ?",
            answer: "Allez dans votre profil > Paramètres Audio pour ajuster la voix, la vitesse et les préférences de lecture."
        ),
        FAQItem(
            question: "L'application utilise-t-elle mes données ?",
            answer: "Nous utilisons uniquement votre localisation pour optimiser vos itinéraires. Vos données personnelles restent privées."
        )
    ]
    
    var filteredFAQItems: [FAQItem] {
        if searchText.isEmpty {
            return faqItems
        } else {
            return faqItems.filter { $0.question.localizedCaseInsensitiveContains(searchText) || $0.answer.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Barre de recherche
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Rechercher dans l'aide...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // FAQ
                VStack(alignment: .leading, spacing: 16) {
                    Text("Questions fréquentes")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(filteredFAQItems.indices, id: \.self) { index in
                            FAQRow(item: filteredFAQItems[index])
                        }
                    }
                }
                
                // Contact
                VStack(alignment: .leading, spacing: 16) {
                    Text("Nous contacter")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 12) {
                        ContactRow(
                            icon: "envelope",
                            title: "Email",
                            subtitle: "support@itinerarly.com",
                            color: .blue
                        )
                        
                        ContactRow(
                            icon: "message",
                            title: "Chat en ligne",
                            subtitle: "Disponible 24h/24",
                            color: .green
                        )
                        
                        ContactRow(
                            icon: "phone",
                            title: "Téléphone",
                            subtitle: "+33 1 23 45 67 89",
                            color: .orange
                        )
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Aide")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Fermer") { dismiss() })
        }
    }
}

struct FAQItem {
    let question: String
    let answer: String
}

struct FAQRow: View {
    let item: FAQItem
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(item.question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(item.answer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ContactRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo et version
                    VStack(spacing: 16) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Itinerarly")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("v1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("À propos")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("Itinerarly est votre compagnon de voyage intelligent qui vous aide à découvrir le monde de manière unique et personnalisée. Notre application combine planification d'itinéraires, tours guidés audio et découvertes insolites pour créer des expériences inoubliables.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Fonctionnalités
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Fonctionnalités principales")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            ProfileFeatureRow(
                                icon: "map",
                                title: "Planification intelligente",
                                description: "Itinéraires optimisés selon vos préférences"
                            )
                            
                            ProfileFeatureRow(
                                icon: "headphones",
                                title: "Tours guidés audio",
                                description: "Guides détaillés pour 80+ villes européennes"
                            )
                            
                            ProfileFeatureRow(
                                icon: "location",
                                title: "Découvertes insolites",
                                description: "Lieux uniques et expériences surprenantes"
                            )
                            
                            ProfileFeatureRow(
                                icon: "sparkles",
                                title: "IA personnalisée",
                                description: "Recommandations adaptées à vos goûts"
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Informations techniques
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Informations techniques")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            InfoRow(title: "Version", value: "1.0.0")
                            InfoRow(title: "Développeur", value: "Itinerarly Team")
                            InfoRow(title: "Plateforme", value: "iOS 15.0+")
                            InfoRow(title: "Taille", value: "45.2 MB")
                            InfoRow(title: "Dernière mise à jour", value: "15 décembre 2024")
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Liens
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Liens utiles")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            LinkRow(
                                icon: "globe",
                                title: "Site web",
                                url: "https://itinerarly.com"
                            )
                            
                            LinkRow(
                                icon: "doc.text",
                                title: "Conditions d'utilisation",
                                url: "https://itinerarly.com/terms"
                            )
                            
                            LinkRow(
                                icon: "hand.raised",
                                title: "Politique de confidentialité",
                                url: "https://itinerarly.com/privacy"
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("À propos")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Fermer") { dismiss() })
        }
    }
}

struct ProfileFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct LinkRow: View {
    let icon: String
    let title: String
    let url: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Image(systemName: "arrow.up.right.square")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
} 