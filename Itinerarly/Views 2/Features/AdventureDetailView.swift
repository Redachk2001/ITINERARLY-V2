import SwiftUI
import MapKit

struct AdventureDetailView: View {
    let adventure: Adventure
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion()
    @State private var showingMap = true
    @State private var currentLocationIndex = 0
    @State private var routeOverlay: MKPolyline?
    @State private var startLocation: CLLocationCoordinate2D?
    @StateObject private var favoritesService = FavoritesService()
    @StateObject private var enhancedLocationService = EnhancedLocationService()
    @State private var enhancedLocations: [Location] = []
    
    // Structure pour les annotations de la carte
    struct MapAnnotationItem: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let isStartPoint: Bool
        let location: Location
        let index: Int
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    AdventureHeaderView(adventure: adventure)
                    
                    MissingCategoriesView(missingCategories: adventure.missingCategories)
                    
                    SurpriseElementView(surpriseElement: adventure.surpriseElement)
                    
                    // Map/List Toggle
                    Picker("View Mode", selection: $showingMap) {
                        Text("Carte").tag(true)
                        Text("Liste").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    if showingMap {
                        AdventureMapView(adventure: adventure, region: $region, currentLocationIndex: $currentLocationIndex)
                    } else {
                        AdventureListView(adventure: adventure, favoritesService: favoritesService, currentLocationIndex: $currentLocationIndex, enhancedLocations: enhancedLocations)
                    }
                    
                    AdventureActionButtons(adventure: adventure)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Votre aventure")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Fermer") {
                    dismiss()
                }
            )
        }
        .onAppear {
            setupMapRegion()
            enhanceLocations()
        }
    }
    
    private func enhanceLocations() {
        let group = DispatchGroup()
        var enhancedLocations: [Location] = []
        
        for location in adventure.locations {
            group.enter()
            enhancedLocationService.enhanceLocation(location) { enhancedLocation in
                enhancedLocations.append(enhancedLocation)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.enhancedLocations = enhancedLocations
        }
    }
    
    private func setupMapRegion() {
        guard !adventure.locations.isEmpty else { return }
        
        // Utiliser le point de départ de l'aventure
        startLocation = adventure.startLocation?.coordinate
        
        // Créer le trajet optimisé
        createOptimizedRoute()
        
        // Calculer la région pour inclure le point de départ et tous les lieux
        var allCoordinates = adventure.locations.map { $0.coordinate }
        if let startLocation = startLocation {
            allCoordinates.insert(startLocation, at: 0)
        }
        
        let center = calculateCenterCoordinate(coordinates: allCoordinates)
        let span = calculateSpan(coordinates: allCoordinates)
        
        region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: max(span.latitudeDelta * 1.3, 0.01),
                longitudeDelta: max(span.longitudeDelta * 1.3, 0.01)
            )
        )
    }
    
    private func createOptimizedRoute() {
        guard !adventure.locations.isEmpty else { return }
        
        // Créer un trajet optimisé qui commence par le point de départ
        var routeCoordinates: [CLLocationCoordinate2D] = []
        
        // Ajouter le point de départ
        if let startLocation = adventure.startLocation {
            routeCoordinates.append(startLocation.coordinate)
        }
        
        // Ajouter tous les lieux de l'aventure dans l'ordre optimisé
        for location in adventure.locations {
            routeCoordinates.append(location.coordinate)
        }
        
        // Créer la ligne de trajet
        routeOverlay = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
    }
    
    private func createMapAnnotations() -> [MapAnnotationItem] {
        var annotations: [MapAnnotationItem] = []
        
        // Ajouter le point de départ
        if let startLocation = adventure.startLocation {
            annotations.append(MapAnnotationItem(
                coordinate: startLocation.coordinate,
                isStartPoint: true,
                location: startLocation,
                index: -1
            ))
        }
        
        // Ajouter les lieux de l'aventure
        for (index, location) in adventure.locations.enumerated() {
            annotations.append(MapAnnotationItem(
                coordinate: location.coordinate,
                isStartPoint: false,
                location: location,
                index: index
            ))
        }
        
        return annotations
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
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        return MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.01),
            longitudeDelta: max(maxLon - minLon, 0.01)
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
    
    private func openInMaps() {
        guard !adventure.locations.isEmpty else { return }
        
        // Créer un itinéraire complet depuis le point de départ
        var allLocations: [Location] = []
        
        // Ajouter le point de départ s'il existe
        if let startLocation = adventure.startLocation {
            allLocations.append(startLocation)
        }
        
        // Ajouter tous les lieux de l'aventure dans l'ordre optimisé
        allLocations.append(contentsOf: adventure.locations)
        
        // Créer les MKMapItem pour tous les points
        let mapItems = allLocations.map { location in
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
            mapItem.name = location.name
            return mapItem
        }
        
        // Pour les aventures, utiliser le mode à pied par défaut
        // car les aventures sont généralement conçues pour être parcourues à pied
        MKMapItem.openMaps(with: mapItems, launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
    
    private func shareAdventure() {
        let text = "Découvrez mon aventure \"\(adventure.title)\" avec Itinerarly!"
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

// MARK: - Separated Views

struct AdventureHeaderView: View {
    let adventure: Adventure
    
    var body: some View {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(adventure.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(adventure.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Stats
                        HStack {
                            StatChip(
                                icon: "clock",
                                text: formatDuration(adventure.estimatedDuration),
                                color: .blue
                            )
                            
                            StatChip(
                                icon: "route",
                                text: String(format: "%.1f km", adventure.totalDistance),
                                color: .green
                            )
                            
                            StatChip(
                                icon: adventure.difficulty.icon,
                                text: adventure.difficulty.displayName,
                                color: .orange
                            )
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.red.opacity(0.1), Color.orange.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

struct MissingCategoriesView: View {
    let missingCategories: [LocationCategory]
    
    var body: some View {
        if !missingCategories.isEmpty {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                Text("Pas de \(missingCategories.map { $0.displayName.lowercased() }.joined(separator: ", ")) dans votre rayon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct SurpriseElementView: View {
    let surpriseElement: String
    
    var body: some View {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.red)
                            Text("Élément surprise")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        
            Text(surpriseElement)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(12)
        }
    }
}

struct AdventureMapView: View {
    let adventure: Adventure
    @Binding var region: MKCoordinateRegion
    @Binding var currentLocationIndex: Int
    
    var body: some View {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Parcours de votre aventure")
                                .font(.headline)
                                .fontWeight(.bold)
                            
            Map(coordinateRegion: $region, annotationItems: createMapAnnotations()) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    if item.isStartPoint {
                        // Point de départ
                        VStack(spacing: 2) {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 24, height: 24)
                                
                                Image(systemName: "location.fill")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                            
                            Text("Départ")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.white)
                                .cornerRadius(4)
                        }
                    } else {
                        // Points de l'aventure
                                    AdventureLocationPin(
                            location: item.location,
                            index: item.index,
                            isSelected: currentLocationIndex == item.index
                        ) {
                            currentLocationIndex = item.index
                        }
                                    }
                                }
                            }
                            .frame(height: 300)
                            .cornerRadius(12)
        }
    }
    
    private func createMapAnnotations() -> [AdventureDetailView.MapAnnotationItem] {
        var annotations: [AdventureDetailView.MapAnnotationItem] = []
        
        // Ajouter le point de départ
        if let startLocation = adventure.startLocation {
            annotations.append(AdventureDetailView.MapAnnotationItem(
                coordinate: startLocation.coordinate,
                isStartPoint: true,
                location: startLocation,
                index: -1
            ))
        }
        
        // Ajouter les lieux de l'aventure
        for (index, location) in adventure.locations.enumerated() {
            annotations.append(AdventureDetailView.MapAnnotationItem(
                coordinate: location.coordinate,
                isStartPoint: false,
                location: location,
                index: index
            ))
        }
        
        return annotations
    }
}

struct AdventureListView: View {
    let adventure: Adventure
    @ObservedObject var favoritesService: FavoritesService
    @Binding var currentLocationIndex: Int
    let enhancedLocations: [Location]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Lieux à découvrir")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(adventure.locations.enumerated()), id: \.element.id) { index, location in
                    let enhancedLocation = enhancedLocations.first { $0.id == location.id } ?? location
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(index + 1)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .frame(width: 30, height: 30)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(enhancedLocation.name)
                                    .font(.headline)
                                    .lineLimit(2)
                                
                                Text(enhancedLocation.category.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            FavoriteButton(
                                location: enhancedLocation,
                                favoritesService: favoritesService,
                                size: 16
                            )
                        }
                        
                        if let description = enhancedLocation.description, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                    }
                    .padding()
                    .background(currentLocationIndex == index ? Color.blue.opacity(0.1) : Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .onTapGesture {
                        currentLocationIndex = index
                    }
                }
            }
        }
    }
}
                    
struct AdventureActionButtons: View {
    let adventure: Adventure
    
    var body: some View {
                    VStack(spacing: 12) {
                        Button(action: openInMaps) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Ouvrir dans Plans")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: shareAdventure) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Partager l'aventure")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
    }
    
    private func openInMaps() {
        guard !adventure.locations.isEmpty else { return }
        
        // Créer un itinéraire complet depuis le point de départ
        var allLocations: [Location] = []
        
        // Ajouter le point de départ s'il existe
        if let startLocation = adventure.startLocation {
            allLocations.append(startLocation)
        }
        
        // Ajouter tous les lieux de l'aventure dans l'ordre optimisé
        allLocations.append(contentsOf: adventure.locations)
        
        // Créer les MKMapItem pour tous les points
        let mapItems = allLocations.map { location in
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
            mapItem.name = location.name
            return mapItem
        }
        
        // Pour les aventures, utiliser le mode à pied par défaut
        MKMapItem.openMaps(with: mapItems, launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
    
    private func shareAdventure() {
        let text = "Découvrez mon aventure \"\(adventure.title)\" avec Itinerarly!"
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



struct AdventureLocationPin: View {
    let location: Location
    let index: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.red : Color.orange)
                        .frame(width: 30, height: 30)
                    
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text(location.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    AdventureDetailView(adventure: Adventure(
        id: "preview",
        title: "Aventure de démonstration",
        description: "Une aventure exemple pour la prévisualisation",
        startLocation: Location(
            id: "start",
            name: "Point de départ",
            address: "16A Rue des Dahlias, Luxembourg",
            latitude: 49.6116,
            longitude: 6.1319,
            category: .cafe,
            description: "Votre point de départ",
            imageURL: nil,
            rating: nil,
            openingHours: nil,
            recommendedDuration: nil,
            visitTips: nil
        ),
        locations: [],
        surpriseElement: "Une surprise vous attend !",
        estimatedDuration: 7200,
        totalDistance: 5.5,
        difficulty: .moderate,
        createdAt: Date(),
        missingCategories: []
    ))
} 