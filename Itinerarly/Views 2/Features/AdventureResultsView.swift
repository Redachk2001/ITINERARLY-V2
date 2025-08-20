import SwiftUI
import MapKit
import CoreLocation

struct AdventureResultsView: View {
    let adventure: AdventurerResult
    let userLocation: CLLocation?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var region = MKCoordinateRegion()
    @State private var showingRoutePreview = false
    @State private var showingNavigation = false
    @StateObject private var favoritesService = FavoritesService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header avec stats de l'aventure
                headerSection
                
                // Onglets Carte/Liste
                tabSection
                
                // Contenu selon l'onglet sélectionné
                if selectedTab == 0 {
                    mapSection
                } else {
                    listSection
                }
                
                // Boutons d'action en bas (comme dans le mode planification)
                actionButtonsSection
            }
            .navigationTitle("Aventure Surprise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ouvrir dans Plans") {
                        openInMaps()
                    }
                }
            }
        }
        .onAppear {
            setupMapRegion()
        }
        .fullScreenCover(isPresented: $showingNavigation) {
            if let dayTrip = convertToTmpDayTrip() {
                SimpleGPSNavigation(trip: dayTrip)
            }
        }
        .fullScreenCover(isPresented: $showingRoutePreview) {
            if let dayTrip = convertToTmpDayTrip() {
                RoutePreviewView(trip: dayTrip)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Nombre de lieux
                VStack {
                    Image(systemName: "location.circle.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                    Text("\(adventure.locations.count)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Lieux")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Durée estimée
                VStack {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text(formatDuration(adventure.totalDuration))
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Durée")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Distance totale
                VStack {
                    Image(systemName: "road.lanes")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("\(String(format: "%.1f", adventure.totalDistance)) km")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Description de l'aventure
            Text(adventure.surpriseDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Tab Section
    private var tabSection: some View {
        HStack {
            Button(action: { selectedTab = 0 }) {
                HStack {
                    Image(systemName: "map")
                    Text("Carte")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(selectedTab == 0 ? .white : .purple)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(selectedTab == 0 ? Color.purple : Color.clear)
                .cornerRadius(20)
            }
            
            Button(action: { selectedTab = 1 }) {
                HStack {
                    Image(systemName: "list.bullet")
                    Text("Liste")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(selectedTab == 1 ? .white : .purple)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(selectedTab == 1 ? Color.purple : Color.clear)
                .cornerRadius(20)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Map Section
    private var mapSection: some View {
        Map(coordinateRegion: $region, 
            interactionModes: [.pan, .zoom],
            annotationItems: adventure.optimizedRoute) { location in
            MapAnnotation(coordinate: CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )) {
                VStack {
                    ZStack {
                        if let index = adventure.optimizedRoute.firstIndex(of: location) {
                            Circle()
                                .fill(index == 0 ? Color.green : (index == adventure.optimizedRoute.count - 1 ? Color.red : Color.purple))
                                .frame(width: 32, height: 32)
                            
                            if index == 0 {
                                // Icône fusée pour le départ
                                Text("🚀")
                                    .font(.system(size: 16))
                            } else if index == adventure.optimizedRoute.count - 1 {
                                // Icône drapeau pour l'arrivée
                                Text("🏁")
                                    .font(.system(size: 16))
                            } else {
                                Text("\(index)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    Text(location.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white)
                        .cornerRadius(6)
                        .shadow(radius: 2)
                }
            }
        }
        .frame(height: 350)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onAppear {
            setupMapRegion()
        }
    }
    
    // MARK: - List Section
    private var listSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Point de départ
                if let userLocation = userLocation {
                    DepartureCard(location: userLocation)
                }
                
                // Lieux de l'aventure
                ForEach(Array(adventure.optimizedRoute.enumerated()), id: \.element.id) { index, location in
                    AdventureLocationCard(
                        location: location,
                        stepNumber: index + 1,
                        onReplace: {
                            // TODO: Implémenter le remplacement de lieu
                        }
                    )
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Bouton principal : Aperçu de la route complète
            Button(action: {
                showRoutePreview()
            }) {
                HStack {
                    Image(systemName: "map")
                        .font(.title3)
                        .foregroundColor(.white)
                    Text("Aperçu de la route complète")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
            }
            
            // Bouton secondaire : Navigation GPS temps réel
            Button(action: {
                startNavigation()
            }) {
                HStack {
                    Image(systemName: "location.north")
                        .font(.title3)
                        .foregroundColor(.white)
                    Text("Navigation GPS temps réel")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            // Boutons en bas : Plans et Partager
            HStack(spacing: 12) {
                Button(action: {
                    openInMaps()
                }) {
                    HStack {
                        Image(systemName: "map")
                            .font(.title3)
                            .foregroundColor(.white)
                        Text("Plans")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    shareAdventure()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(.white)
                        Text("Partager")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    private func setupMapRegion() {
        let coordinates = adventure.optimizedRoute.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        guard !coordinates.isEmpty else { return }
        
        let center = calculateCenterCoordinate(coordinates: coordinates)
        let span = calculateSpan(coordinates: coordinates)
        
        region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: span.latitudeDelta * 1.3,
                longitudeDelta: span.longitudeDelta * 1.3
            )
        )
    }
    
    private func calculateCenterCoordinate(coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        let totalLat = coordinates.reduce(0) { $0 + $1.latitude }
        let totalLon = coordinates.reduce(0) { $0 + $1.longitude }
        return CLLocationCoordinate2D(
            latitude: totalLat / Double(coordinates.count),
            longitude: totalLon / Double(coordinates.count)
        )
    }
    
    private func calculateSpan(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateSpan {
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        return MKCoordinateSpan(
            latitudeDelta: max(0.005, maxLat - minLat),
            longitudeDelta: max(0.005, maxLon - minLon)
        )
    }
    
    private func openInMaps() {
        let mapItems = adventure.optimizedRoute.map { location in
            let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            ))
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = location.name
            return mapItem
        }
        
        MKMapItem.openMaps(with: mapItems, launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    private func getCategoryIcon(for category: LocationCategory) -> String {
        switch category {
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer"
        case .museum: return "building.columns"
        case .culture: return "theatermasks"
        case .sport: return "figure.run"
        case .shopping: return "bag"
        case .nature: return "leaf"
        case .bar: return "wineglass"
        case .entertainment: return "gamecontroller"
        case .aquarium: return "fish"
        case .zoo: return "pawprint"
        default: return "mappin"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes > 0 ? " \(minutes)min" : "")"
        } else {
            return "\(minutes)min"
        }
    }
}

// MARK: - Supporting Views
struct DepartureCard: View {
    let location: CLLocation
    
    var body: some View {
        HStack {
            VStack {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.green)
                    .clipShape(Circle())
                
                Text("Départ")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Point de départ")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Votre localisation actuelle")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct AdventureLocationCard: View {
    let location: Location
    let stepNumber: Int
    let onReplace: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Numéro d'étape
                Text("\(stepNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.purple)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(location.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Bouton remplacer
                Button("Skip", action: onReplace)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
            }
            
            if let description = location.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Actions
            HStack {
                Button(action: {
                    let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                    let placemark = MKPlacemark(coordinate: coordinate)
                    let mapItem = MKMapItem(placemark: placemark)
                    mapItem.name = location.name
                    mapItem.openInMaps(launchOptions: [:])
                }) {
                    HStack {
                        Image(systemName: "map")
                        Text("Ouvrir")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                Button(action: {
                    openInTikTok(query: location.name)
                }) {
                    HStack {
                        Image(systemName: "video.fill")
                        Text("TikTok")
                    }
                    .font(.caption)
                    .foregroundColor(.pink)
                }
                
                Spacer()
                
                if let duration = location.recommendedDuration {
                    HStack {
                        Image(systemName: "clock")
                        Text("\(Int(duration / 60))min")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func openInTikTok(query: String) {
        guard !query.isEmpty else { return }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let appURL = URL(string: "tiktok://search?q=\(encoded)"), UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
            return
        }
        if let webURL = URL(string: "https://www.tiktok.com/search?q=\(encoded)") {
            UIApplication.shared.open(webURL)
        }
    }
}

// MARK: - Extension pour les fonctions d'action
extension AdventureResultsView {
    private func startNavigation() {
        showingNavigation = true
    }
    
    private func openInTikTok(query: String) {
        guard !query.isEmpty else { return }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let appURL = URL(string: "tiktok://search?q=\(encoded)"), UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
            return
        }
        if let webURL = URL(string: "https://www.tiktok.com/search?q=\(encoded)") {
            UIApplication.shared.open(webURL)
        }
    }
    
    private func showRoutePreview() {
        showingRoutePreview = true
    }
    
    private func shareAdventure() {
        var text = "🎲 Mon aventure surprise Itinerarly:\n\n"
        text += "🎯 \(adventure.surpriseDescription)\n\n"
        
        for (index, location) in adventure.optimizedRoute.enumerated() {
            if index == 0 {
                text += "📍 Départ: \(location.name)\n"
            } else {
                text += "🏃‍♂️ Aventure \(index): \(location.name)\n"
            }
            if !location.address.isEmpty {
                text += "   📧 \(location.address)\n"
            }
        }
        
        text += "\n⏱️ Durée totale: \(formatTime(adventure.totalDuration))\n"
        text += "📏 Distance: \(String(format: "%.1f", adventure.totalDistance / 1000)) km\n"
        text += "\n🚀 Généré avec Itinerarly"
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Helper Functions
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes > 0 ? " \(minutes)min" : "")"
        } else {
            return "\(minutes)min"
        }
    }
    
    // MARK: - Adaptateur temporaire pour DayTrip
    private func convertToTmpDayTrip() -> DayTrip? {
        guard let startLocation = adventure.startAddress else { return nil }
        
        return DayTrip(
            id: UUID().uuidString,
            startLocation: startLocation,
            locations: adventure.locations,
            optimizedRoute: adventure.optimizedRoute,
            totalDistance: adventure.totalDistance / 1000, // Convert to km
            estimatedDuration: adventure.totalDuration,
            transportMode: .walking, // Default for adventure
            createdAt: Date(),
            numberOfLocations: adventure.locations.count
        )
    }
}