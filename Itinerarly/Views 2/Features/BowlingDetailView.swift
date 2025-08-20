import SwiftUI
import MapKit

struct BowlingDetailView: View {
    let location: Location
    @StateObject private var bowlingService = BowlingAPIService.shared
    @State private var bowlingDetails: BowlingDetails?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingMap = false
    @State private var region: MKCoordinateRegion
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var languageManager: LanguageManager
    
    init(location: Location) {
        self.location = location
        self._region = State(initialValue: MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header avec image
                    headerSection
                    
                    // Informations principales
                    if let details = bowlingDetails {
                        mainInfoSection(details: details)
                        
                        // Horaires d'ouverture
                        openingHoursSection(details: details)
                        
                        // Tarifs
                        pricingSection(details: details)
                        
                        // Équipements
                        facilitiesSection(details: details)
                        
                        // Offres spéciales
                        specialOffersSection(details: details)
                    }
                    
                    // Carte
                    mapSection
                    
                    // Conseils de visite
                    tipsSection
                    
                    // Boutons d'action
                    actionButtonsSection
                }
                .padding()
            }
            .navigationTitle(location.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Fermer") {
                    dismiss()
                },
                trailing: Button(action: {
                    showingMap = true
                }) {
                    Image(systemName: "map")
                }
            )
            .onAppear {
                loadBowlingDetails()
            }
            .sheet(isPresented: $showingMap) {
                BowlingMapView(location: location, region: region)
            }
        }
    }
    
    // MARK: - Sections de la vue
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Image du bowling
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 200)
                
                VStack {
                    Image(systemName: "bowling.ball")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("🎳 Bowling")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // Informations de base
            VStack(alignment: .leading, spacing: 8) {
                Text(location.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text(location.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let rating = location.rating {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func mainInfoSection(details: BowlingDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Informations")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                BowlingInfoRow(icon: "phone.fill", title: "Téléphone", value: details.phoneNumber)
                BowlingInfoRow(icon: "globe", title: "Site web", value: details.website)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func openingHoursSection(details: BowlingDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Horaires d'ouverture")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                ForEach(Array(details.openingHours.keys.sorted()), id: \.self) { day in
                    HStack {
                        Text(day)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 80, alignment: .leading)
                        
                        Text(details.openingHours[day] ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func pricingSection(details: BowlingDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tarifs")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                ForEach(Array(details.prices.keys), id: \.self) { service in
                    HStack {
                        Text(service)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(details.prices[service] ?? "")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func facilitiesSection(details: BowlingDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Équipements")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(details.facilities, id: \.self) { facility in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(facility)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func specialOffersSection(details: BowlingDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Offres spéciales")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(details.specialOffers, id: \.self) { offer in
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text(offer)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Localisation")
                .font(.headline)
                .fontWeight(.bold)
            
            Map(coordinateRegion: $region, annotationItems: [location]) { location in
                MapMarker(coordinate: location.coordinate, tint: .blue)
            }
            .frame(height: 200)
            .cornerRadius(12)
        }
    }
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Conseils de visite")
                .font(.headline)
                .fontWeight(.bold)
            
            if let tips = location.visitTips {
                VStack(spacing: 8) {
                    ForEach(tips, id: \.self) { tip in
                        HStack(alignment: .top) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            
                            Text(tip)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Action pour réserver
                print("Réservation bowling")
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Réserver")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: {
                // Action pour appeler
                if let details = bowlingDetails {
                    callPhoneNumber(details.phoneNumber)
                }
            }) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Appeler")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: {
                // Action pour partager
                shareBowling()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Partager")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Méthodes
    
    private func loadBowlingDetails() {
        Task {
            do {
                let details = try await bowlingService.getBowlingDetails(for: location)
                await MainActor.run {
                    self.bowlingDetails = details
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func callPhoneNumber(_ phoneNumber: String) {
        let cleanNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "tel://\(cleanNumber)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareBowling() {
        let text = "🎳 Découvrez ce bowling: \(location.name) - \(location.address)"
        let activityController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
    }
}

// MARK: - Composants auxiliaires

struct BowlingInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct BowlingMapView: View {
    let location: Location
    let region: MKCoordinateRegion
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: .constant(region), annotationItems: [location]) { location in
                MapMarker(coordinate: location.coordinate, tint: .blue)
            }
            .navigationTitle("Carte")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Fermer") {
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    BowlingDetailView(location: Location(
        id: "preview-bowling",
        name: "Bowling City",
        address: "123 Rue du Bowling, Paris",
        latitude: 48.8566,
        longitude: 2.3522,
        category: .bowling,
        description: "Un bowling moderne avec 8 pistes",
        imageURL: nil,
        rating: 4.5,
        openingHours: "10:00-23:00",
        recommendedDuration: 7200,
        visitTips: [
            "Réservez à l'avance pour les heures de pointe",
            "Apportez des chaussettes propres"
        ]
    ))
}
