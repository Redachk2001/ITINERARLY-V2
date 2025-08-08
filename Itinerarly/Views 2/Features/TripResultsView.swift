import SwiftUI
import MapKit

struct TripResultsView: View {
    let trip: DayTrip
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion()
    @State private var showingMap = true
    @State private var showingNavigation = false
    @State private var showingRoutePreview = false
    @StateObject private var favoritesService = FavoritesService()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Stats
                    VStack(spacing: 16) {
                        HStack {
                            VStack {
                                Image(systemName: "clock")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text(formatDuration(trip.estimatedDuration))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Durée totale")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Image(systemName: "route")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                Text(String(format: "%.1f km", trip.totalDistance))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Distance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Image(systemName: trip.transportMode.icon)
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                Text("\(trip.numberOfLocations)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Arrêts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Map/List Toggle
                    Picker("View Mode", selection: $showingMap) {
                        Text("Carte").tag(true)
                        Text("Liste").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    if showingMap {
                        // Map View simplifiée et stable
                        Map(coordinateRegion: $region, 
                            interactionModes: [.pan, .zoom],
                            annotationItems: trip.optimizedRoute) { location in
                            MapAnnotation(coordinate: location.coordinate) {
                                VStack {
                                    ZStack {
                                        Circle()
                                            .fill(annotationColor(for: location))
                                            .frame(width: 32, height: 32)
                                        
                                        if location == trip.optimizedRoute.first {
                                            Text("🚀")
                                                .font(.caption)
                                        } else if location == trip.optimizedRoute.last {
                                            Text("🏁")
                                                .font(.caption)
                                        } else {
                                            Text("\(trip.optimizedRoute.firstIndex(of: location)! + 1)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    Text(location.name)
                                        .font(.caption2)
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
                            print("🗺️ TripResultsView - Affichage carte:")
                            print("   Nombre d'arrêts: \(trip.numberOfLocations)")
                            print("   Itinéraire optimisé: \(trip.optimizedRoute.map { $0.name })")
                            print("   Destinations: \(trip.locations.map { $0.name })")
                        }
                    } else {
                        // List View
                        VStack(spacing: 12) {
                            ForEach(Array(trip.optimizedRoute.enumerated()), id: \.element.id) { index, location in
                                TripStopCard(
                                    location: location,
                                    index: index,
                                    isLast: index == trip.optimizedRoute.count - 1,
                                    favoritesService: favoritesService
                                )
                            }
                        }
                    }
                    
                    // Informations de transport public (si applicable)
                    if trip.transportMode == .publicTransport {
                        PublicTransportInfoView(trip: trip)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Bouton Aperçu Route - Principal
                        Button(action: showRoutePreview) {
                            HStack {
                                Image(systemName: "map")
                                Text("Aperçu de la route complète")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        
                        // Bouton Navigation GPS - Secondaire
                        Button(action: startNavigation) {
                            HStack {
                                Image(systemName: "location.north.line")
                                Text("Navigation GPS temps réel")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        
                        HStack(spacing: 12) {
                            // Ouvrir dans Plans
                            Button(action: openInMaps) {
                                HStack {
                                    Image(systemName: "map.fill")
                                    Text("Plans")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            
                            // Partager
                            Button(action: shareTrip) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Partager")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Votre itinéraire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            setupMapRegion()
        }
        .fullScreenCover(isPresented: $showingNavigation) {
            SimpleGPSNavigation(trip: trip)
        }
        .fullScreenCover(isPresented: $showingRoutePreview) {
            RoutePreviewView(trip: trip)
        }
    }
    
    private func setupMapRegion() {
        let coordinates = trip.optimizedRoute.map { $0.coordinate }
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
    
    private func annotationColor(for location: Location) -> Color {
        if location == trip.optimizedRoute.first {
            return .green
        } else if location == trip.optimizedRoute.last {
            return .red
        } else {
            return .blue
        }
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
        guard !trip.optimizedRoute.isEmpty else { return }
        
        let locations = trip.optimizedRoute.map { location in
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
            mapItem.name = location.name
            return mapItem
        }
        
        // Déterminer le mode de transport approprié
        let directionsMode: String
        switch trip.transportMode {
        case .walking:
            directionsMode = MKLaunchOptionsDirectionsModeWalking
        case .driving:
            directionsMode = MKLaunchOptionsDirectionsModeDriving
        case .cycling:
            directionsMode = MKLaunchOptionsDirectionsModeWalking // Apple Maps n'a pas de mode vélo spécifique
        case .publicTransport:
            directionsMode = MKLaunchOptionsDirectionsModeTransit
        }
        
        MKMapItem.openMaps(with: locations, launchOptions: [
            MKLaunchOptionsDirectionsModeKey: directionsMode
        ])
    }
    
    private func startNavigation() {
        showingNavigation = true
    }
    
    private func showRoutePreview() {
        showingRoutePreview = true
    }
    
    private func shareTrip() {
        // Créer un texte de partage plus détaillé avec l'itinéraire
        var text = "🗺️ Mon itinéraire Itinerarly:\n\n"
        text += "📍 Départ: \(trip.optimizedRoute.first?.name ?? "Position de départ")\n"
        
        for (index, location) in trip.optimizedRoute.dropFirst().enumerated() {
            text += "🎯 Arrêt \(index + 1): \(location.name)\n"
        }
        
        text += "\n📊 Distance totale: \(String(format: "%.1f", trip.totalDistance))km"
        text += "\n⏰ Durée estimée: \(formatDuration(trip.estimatedDuration))"
        text += "\n🚗 Mode: \(trip.transportMode.displayName)"
        text += "\n\n📱 Créé avec Itinerarly - Planifiez vos sorties intelligemment!"
        
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



struct LocationPin: View {
    let location: Location
    let index: Int
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.blue)
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
        }
    }
}

struct TripStopCard: View {
    let location: Location
    let index: Int
    let isLast: Bool
    @ObservedObject var favoritesService: FavoritesService
    
    private var isStart: Bool { index == 0 }
    private var isEnd: Bool { isLast }
    
    private var stepColor: Color {
        if isStart {
            return .green
        } else if isEnd {
            return .red
        } else {
            return .blue
        }
    }
    
    private var lineColor: Color {
        return .blue.opacity(0.4)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Step indicator avec icônes cohérentes avec la carte
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(stepColor)
                        .frame(width: 36, height: 36)
                    
                    if isStart {
                        Text("🚀")
                            .font(.body)
                    } else if isEnd {
                        Text("🏁")
                            .font(.body)
                    } else {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                if !isLast {
                    Rectangle()
                        .fill(lineColor)
                        .frame(width: 3, height: 50)
                }
            }
            
            // Location info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(location.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if isStart {
                        Text("DÉPART")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    } else if isEnd {
                        Text("ARRIVÉE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    } else {
                        Text("ÉTAPE \(index + 1)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Text(location.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: location.category.icon)
                        .foregroundColor(.blue)
                        .frame(width: 16)
                    
                    Text(location.category.displayName)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    // Bouton favori
                    FavoriteButton(
                        location: location,
                        favoritesService: favoritesService,
                        size: 16
                    )
                    
                    // Distance depuis le point précédent (simulation)
                    if index > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "location.arrow")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("~\(String(format: "%.1f", Double.random(in: 0.5...5.0)))km")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Public Transport Info View
struct PublicTransportInfoView: View {
    let trip: DayTrip
    @StateObject private var publicTransportService = PublicTransportService()
    @State private var transportRoutes: [RealTransitRoute] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bus.fill")
                    .foregroundColor(.blue)
                Text("Transport Public")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Récupération des horaires...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if !transportRoutes.isEmpty {
                VStack(spacing: 12) {
                    ForEach(Array(transportRoutes.enumerated()), id: \.element.id) { index, route in
                        PublicTransportRouteCard(route: route, segmentIndex: index + 1)
                    }
                }
            } else {
                Text("Aucune information de transport public disponible")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            loadPublicTransportInfo()
        }
    }
    
    private func loadPublicTransportInfo() {
        // Simuler le chargement des informations de transport public
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Créer des routes simulées pour la démo
            let mockRoutes = createMockPublicTransportRoutes()
            self.transportRoutes = mockRoutes
            self.isLoading = false
        }
    }
    
    private func createMockPublicTransportRoutes() -> [RealTransitRoute] {
        // TODO: Corriger cette fonction de test pour utiliser RealTransitRoute
        return []
        /*
        // Créer des routes simulées basées sur l'itinéraire
        guard trip.optimizedRoute.count >= 2 else { return [] }
        
        var routes: [RealTransitRoute] = []
        
        for i in 0..<(trip.optimizedRoute.count - 1) {
            let start = trip.optimizedRoute[i]
            let end = trip.optimizedRoute[i + 1]
            
            let steps = [
                PublicTransportStep(
                    id: UUID().uuidString,
                    instruction: "Marchez vers l'arrêt de bus",
                    distance: 200,
                    duration: 180,
                    transportType: .walking,
                    lineName: nil,
                    departureTime: Date(),
                    arrivalTime: Date().addingTimeInterval(180)
                ),
                PublicTransportStep(
                    id: UUID().uuidString,
                    instruction: "Prenez le bus vers \(end.name)",
                    distance: CLLocation(latitude: start.latitude, longitude: start.longitude)
                        .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude)),
                    duration: 600,
                    transportType: .bus,
                    lineName: "Bus \(Int.random(in: 1...30))",
                    departureTime: Date().addingTimeInterval(180),
                    arrivalTime: Date().addingTimeInterval(780)
                )
            ]
            
            let route = PublicTransportRoute(
                id: UUID().uuidString,
                steps: steps,
                totalDistance: steps.reduce(0) { $0 + $1.distance },
                totalDuration: steps.reduce(0) { $0 + $1.duration },
                departureTime: Date(),
                arrivalTime: Date().addingTimeInterval(steps.reduce(0) { $0 + $1.duration }),
                fare: 2.0,
                accessibility: AccessibilityInfo(
                    isWheelchairAccessible: true,
                    hasElevator: true,
                    hasRamp: true,
                    notes: "Transport accessible"
                )
            )
            
            routes.append(route)
        }
        
        return routes
        */
    }
}

struct PublicTransportRouteCard: View {
    let route: RealTransitRoute
    let segmentIndex: Int
    
    var body: some View {
        // TODO: Corriger cette vue pour utiliser RealTransitRoute
        VStack {
            Text("Route de transport \(segmentIndex)")
            Text("Distance: \(String(format: "%.1f", route.totalDistance / 1000))km")
            Text("Durée: \(String(format: "%.0f", route.totalDuration / 60))min")
            Text("Prix: \(String(format: "%.2f", route.totalFare))€")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    TripResultsView(trip: DayTrip(
        id: "1",
        startLocation: Location(
            id: "start",
            name: "Point de départ",
                            address: "Champ de Mars, 5 Avenue Anatole France, 75007 Paris",
            latitude: 48.8566,
            longitude: 2.3522,
            category: .cafe,
            description: nil,
            imageURL: nil,
            rating: nil,
            openingHours: nil,
            recommendedDuration: nil,
            visitTips: nil
        ),
        locations: [],
        optimizedRoute: [],
        totalDistance: 12.5,
        estimatedDuration: 3600,
        transportMode: .driving,
        createdAt: Date(),
        numberOfLocations: 0
    ))
} 
