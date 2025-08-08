import SwiftUI
import MapKit
import CoreLocation

struct GPSNavigationView: View {
    let trip: DayTrip
    @Environment(\.dismiss) private var dismiss
    @StateObject private var navigationManager = NavigationManager()
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var region = MKCoordinateRegion()
    @State private var currentDestinationIndex = 0
    @State private var showingDirections = true
    @State private var trackingUser = true
    
    var currentDestination: Location? {
        guard currentDestinationIndex < trip.optimizedRoute.count else { return nil }
        return trip.optimizedRoute[currentDestinationIndex]
    }
    
    var nextDestination: Location? {
        let nextIndex = currentDestinationIndex + 1
        guard nextIndex < trip.optimizedRoute.count else { return nil }
        return trip.optimizedRoute[nextIndex]
    }
    
    var body: some View {
        ZStack {
            // Carte GPS principale
            GPSNavigationMapView(
                trip: trip,
                region: $region,
                trackingUser: $trackingUser,
                currentDestinationIndex: currentDestinationIndex,
                directions: navigationManager.currentDirections,
                userLocation: locationManager.location
            )
            .edgesIgnoringSafeArea(.all)
            
            // Interface de navigation overlay
            VStack {
                // Barre de statut en haut
                NavigationStatusBar(
                    currentDestination: currentDestination,
                    nextDestination: nextDestination,
                    progress: Double(currentDestinationIndex + 1) / Double(trip.optimizedRoute.count),
                    totalStops: trip.optimizedRoute.count
                )
                .padding(.horizontal)
                
                Spacer()
                
                // Instructions de navigation en bas
                if showingDirections {
                    NavigationInstructionsCard(
                        currentInstruction: navigationManager.currentInstruction,
                        nextInstruction: navigationManager.nextInstruction,
                        distanceToNextStep: navigationManager.distanceToNextStep,
                        estimatedTimeToDestination: navigationManager.estimatedTimeToDestination
                    )
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom))
                }
                
                // Contrôles de navigation
                NavigationControlsBar(
                    onToggleDirections: {
                        withAnimation(.easeInOut) {
                            showingDirections.toggle()
                        }
                    },
                    onRecenter: {
                        trackingUser = true
                        centerOnUserLocation()
                    },
                    onNextDestination: {
                        goToNextDestination()
                    },
                    onEndNavigation: {
                        dismiss()
                    },
                    canGoNext: currentDestinationIndex < trip.optimizedRoute.count - 1
                )
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            setupNavigation()
        }
        .onReceive(locationManager.$location) { location in
            if let location = location {
                updateNavigationForLocation(location)
            }
        }
    }
    
    private func setupNavigation() {
        // Démarrer le tracking de position
        locationManager.startUpdatingLocation()
        
        // Configurer la région initiale
        if let userLocation = locationManager.location {
            region = MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
        }
        
        // Calculer les directions vers la première destination
        if let destination = currentDestination {
            navigationManager.calculateDirections(to: destination, from: locationManager.location)
        }
    }
    
    private func updateNavigationForLocation(_ location: CLLocation) {
        guard let destination = currentDestination else { return }
        
        // Vérifier si on est arrivé à la destination actuelle
        let distanceToDestination = location.distance(from: destination.clLocation)
        
        if distanceToDestination < 50 { // 50 mètres de tolérance
            // Arrivé à destination
            goToNextDestination()
        } else {
            // Mettre à jour les instructions
            navigationManager.updateInstructions(for: location)
        }
    }
    
    private func goToNextDestination() {
        let nextIndex = currentDestinationIndex + 1
        guard nextIndex < trip.optimizedRoute.count else {
            // Fin du voyage
            navigationManager.completeNavigation()
            return
        }
        
        currentDestinationIndex = nextIndex
        
        let newDestination = trip.optimizedRoute[nextIndex]
        navigationManager.calculateDirections(to: newDestination, from: locationManager.location)
    }
    
    private func centerOnUserLocation() {
        guard let userLocation = locationManager.location else { return }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            region = MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
        }
    }
}

// MARK: - GPS Navigation Map View
struct GPSNavigationMapView: UIViewRepresentable {
    let trip: DayTrip
    @Binding var region: MKCoordinateRegion
    @Binding var trackingUser: Bool
    let currentDestinationIndex: Int
    let directions: MKDirections.Response?
    let userLocation: CLLocation?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.mapType = .standard
        
        // Configuration pour la navigation
        mapView.showsTraffic = true
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        
        // Configurer le tracking utilisateur
        if trackingUser {
            mapView.userTrackingMode = .followWithHeading
        } else {
            mapView.userTrackingMode = .none
        }
        
        // Mettre à jour les annotations
        updateAnnotations(mapView)
        
        // Mettre à jour les directions
        updateDirections(mapView)
    }
    
    private func updateAnnotations(_ mapView: MKMapView) {
        // Supprimer les anciennes annotations
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        // Ajouter les destinations
        for (index, location) in trip.optimizedRoute.enumerated() {
            let annotation = NavigationAnnotation(
                location: location,
                index: index,
                isCurrent: index == currentDestinationIndex,
                isCompleted: index < currentDestinationIndex
            )
            mapView.addAnnotation(annotation)
        }
    }
    
    private func updateDirections(_ mapView: MKMapView) {
        // Supprimer les anciens overlays
        mapView.removeOverlays(mapView.overlays)
        
        // Ajouter la route actuelle
        if let directions = directions,
           let route = directions.routes.first {
            let polyline = route.polyline
            mapView.addOverlay(polyline)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: GPSNavigationMapView
        
        init(_ parent: GPSNavigationMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let navAnnotation = annotation as? NavigationAnnotation else {
                return nil
            }
            
            let identifier = "NavigationPin"
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            annotationView.annotation = annotation
            annotationView.canShowCallout = true
            
            // Couleur selon l'état
            if navAnnotation.isCompleted {
                annotationView.markerTintColor = .systemGreen
                annotationView.glyphText = "✓"
            } else if navAnnotation.isCurrent {
                annotationView.markerTintColor = .systemRed
                annotationView.glyphText = "📍"
            } else {
                annotationView.markerTintColor = .systemBlue
                annotationView.glyphText = "\(navAnnotation.index + 1)"
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 6.0
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - Navigation Status Bar
struct NavigationStatusBar: View {
    let currentDestination: Location?
    let nextDestination: Location?
    let progress: Double
    let totalStops: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Barre de progression
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(y: 2)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Direction")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(currentDestination?.name ?? "Destination")
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Arrêt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(progress * Double(totalStops)))/\(totalStops)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Navigation Instructions Card
struct NavigationInstructionsCard: View {
    let currentInstruction: String?
    let nextInstruction: String?
    let distanceToNextStep: Double?
    let estimatedTimeToDestination: TimeInterval?
    
    var body: some View {
        VStack(spacing: 12) {
            // Instruction principale
            HStack {
                Image(systemName: "arrow.turn.up.right")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentInstruction ?? "Continuez tout droit")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let distance = distanceToNextStep {
                        Text("dans \(formatDistance(distance))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Prochaine instruction
            if let nextInstruction = nextInstruction {
                Divider()
                
                HStack {
                    Image(systemName: "arrow.turn.up.left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Puis: \(nextInstruction)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            // Temps estimé
            if let eta = estimatedTimeToDestination {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("Arrivée dans \(formatTime(eta))")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60)
        if minutes < 60 {
            return "\(minutes)min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h\(remainingMinutes)min"
        }
    }
}

// MARK: - Navigation Controls Bar
struct NavigationControlsBar: View {
    let onToggleDirections: () -> Void
    let onRecenter: () -> Void
    let onNextDestination: () -> Void
    let onEndNavigation: () -> Void
    let canGoNext: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Toggle directions
            Button(action: onToggleDirections) {
                Image(systemName: "text.bubble")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .frame(width: 44, height: 44)
            .background(Color(.systemBackground))
            .cornerRadius(22)
            .shadow(radius: 2)
            
            // Recenter
            Button(action: onRecenter) {
                Image(systemName: "location")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .frame(width: 44, height: 44)
            .background(Color(.systemBackground))
            .cornerRadius(22)
            .shadow(radius: 2)
            
            Spacer()
            
            // Next destination
            if canGoNext {
                Button(action: onNextDestination) {
                    HStack {
                        Text("Suivant")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(22)
                .shadow(radius: 2)
            }
            
            // End navigation
            Button(action: onEndNavigation) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            .frame(width: 44, height: 44)
            .background(Color(.systemBackground))
            .cornerRadius(22)
            .shadow(radius: 2)
        }
    }
}

// MARK: - Navigation Annotation
class NavigationAnnotation: NSObject, MKAnnotation {
    let location: Location
    let index: Int
    let isCurrent: Bool
    let isCompleted: Bool
    
    var coordinate: CLLocationCoordinate2D {
        return location.coordinate
    }
    
    var title: String? {
        return location.name
    }
    
    var subtitle: String? {
        if isCompleted {
            return "Terminé"
        } else if isCurrent {
            return "Destination actuelle"
        } else {
            return "Arrêt \(index + 1)"
        }
    }
    
    init(location: Location, index: Int, isCurrent: Bool, isCompleted: Bool) {
        self.location = location
        self.index = index
        self.isCurrent = isCurrent
        self.isCompleted = isCompleted
        super.init()
    }
} 