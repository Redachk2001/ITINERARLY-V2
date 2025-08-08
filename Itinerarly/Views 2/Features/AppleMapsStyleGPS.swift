import SwiftUI
import MapKit
import CoreLocation

struct AppleMapsStyleGPS: View {
    let trip: DayTrip
    @Environment(\.dismiss) private var dismiss
    @StateObject private var realTimeLocation = RealTimeLocationService()
    @StateObject private var routeManager = AppleMapsRouteManager()
    
    @State private var currentStepIndex = 0
    @State private var showingInstructions = true
    @State private var mapRect: MKMapRect = MKMapRect.world
    @State private var showingLocationStatus = false
    
    var currentDestination: Location {
        guard currentStepIndex < trip.optimizedRoute.count else {
            return trip.optimizedRoute.last!
        }
        return trip.optimizedRoute[currentStepIndex]
    }
    
    var body: some View {
        ZStack {
            // Carte style Apple Maps
            AppleMapsView(
                trip: trip,
                userLocation: realTimeLocation.currentLocation,
                currentDestination: currentDestination,
                routePolylines: routeManager.routePolylines,
                heading: realTimeLocation.heading,
                onMapRectChange: { rect in
                    mapRect = rect
                }
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Statut GPS en haut
                if showingLocationStatus || !realTimeLocation.isLocationAvailable {
                    HStack {
                        Image(systemName: realTimeLocation.isLocationAvailable ? "location.fill" : "location.slash")
                            .foregroundColor(realTimeLocation.isLocationAvailable ? .green : .red)
                        Text(realTimeLocation.locationStatusText)
                            .font(.caption)
                        Spacer()
                        if !realTimeLocation.isLocationAvailable {
                            Button("Activer") {
                                if realTimeLocation.authorizationStatus == .notDetermined {
                                    realTimeLocation.requestLocationPermission()
                                } else {
                                    realTimeLocation.openLocationSettings()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        } else {
                            Button("Fermer") {
                                showingLocationStatus = false
                            }
                            .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 50)
                }
                
                Spacer()
                
                // Instructions style Apple Maps
                if showingInstructions && routeManager.currentInstruction != nil {
                    AppleMapsInstructionCard(
                        instruction: routeManager.currentInstruction!,
                        distanceToStep: routeManager.distanceToNextStep,
                        estimatedTime: routeManager.estimatedTime,
                        nextInstruction: routeManager.nextInstruction
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                
                // Contrôles en bas
                HStack {
                    // Statut GPS
                    Button(action: {
                        if !realTimeLocation.isLocationAvailable {
                            if realTimeLocation.authorizationStatus == .notDetermined {
                                realTimeLocation.requestLocationPermission()
                            } else {
                                realTimeLocation.openLocationSettings()
                            }
                        } else {
                            showingLocationStatus.toggle()
                        }
                    }) {
                        Image(systemName: realTimeLocation.isLocationAvailable ? "location.fill" : "location.slash")
                            .font(.title2)
                            .foregroundColor(realTimeLocation.isLocationAvailable ? .green : .red)
                    }
                    .frame(width: 50, height: 50)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(25)
                    
                    // Instructions toggle
                    Button(action: { showingInstructions.toggle() }) {
                        Image(systemName: showingInstructions ? "text.bubble.fill" : "text.bubble")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .frame(width: 50, height: 50)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(25)
                    
                    Spacer()
                    
                    // Destination suivante
                    if currentStepIndex < trip.optimizedRoute.count - 1 {
                        Button(action: goToNextDestination) {
                            HStack {
                                Text("Suivant")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(25)
                        }
                    }
                    
                    Spacer()
                    
                    // Fermer
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .frame(width: 50, height: 50)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(25)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            startNavigation()
        }
        .onReceive(realTimeLocation.$currentLocation) { location in
            if let location = location {
                updateNavigationForNewLocation(location)
            }
        }
    }
    
    private func startNavigation() {
        realTimeLocation.startTracking()
        calculateRouteToCurrentDestination()
    }
    
    private func calculateRouteToCurrentDestination() {
        guard let userLocation = realTimeLocation.currentLocation else { return }
        
        let destination = currentDestination
        routeManager.calculateRoute(
            from: userLocation.coordinate,
            to: destination.coordinate
        )
    }
    
    private func updateNavigationForNewLocation(_ location: CLLocation) {
        let destination = currentDestination
        let distanceToDestination = location.distance(from: destination.clLocation)
        
        // Si on est arrivé (moins de 50m)
        if distanceToDestination < 50 {
            goToNextDestination()
        } else {
            // Mettre à jour les instructions
            routeManager.updateInstructionsForLocation(location)
        }
    }
    
    private func goToNextDestination() {
        guard currentStepIndex < trip.optimizedRoute.count - 1 else {
            // Fin du voyage
            return
        }
        
        currentStepIndex += 1
        calculateRouteToCurrentDestination()
    }
}

// MARK: - Apple Maps Style Map View
struct AppleMapsView: UIViewRepresentable {
    let trip: DayTrip
    let userLocation: CLLocation?
    let currentDestination: Location
    let routePolylines: [MKPolyline]
    let heading: CLHeading?
    let onMapRectChange: (MKMapRect) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Configuration style Apple Maps
        mapView.mapType = .standard
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.showsTraffic = true
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
        
        // Style de navigation 3D comme Apple Maps
        mapView.camera.altitude = 800
        mapView.camera.pitch = 60 // Vue inclinée pour la navigation
        
        // Réglages pour un suivi fluide
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Nettoyer les anciens overlays
        mapView.removeOverlays(mapView.overlays)
        
        // Ajouter les nouvelles polylines (routes)
        for polyline in routePolylines {
            mapView.addOverlay(polyline)
        }
        
        // Mettre à jour les annotations
        updateAnnotations(mapView)
        
        // Mise à jour du suivi utilisateur en temps réel
        if let userLocation = userLocation {
            // Suivi continu comme Apple Maps
            let camera = MKMapCamera(
                lookingAtCenter: userLocation.coordinate,
                fromDistance: 800,
                pitch: 60,
                heading: heading?.trueHeading ?? 0
            )
            mapView.setCamera(camera, animated: true)
            
            // Activer le tracking automatique
            if mapView.userTrackingMode != .followWithHeading {
                mapView.setUserTrackingMode(.followWithHeading, animated: true)
            }
        }
    }
    
    private func updateAnnotations(_ mapView: MKMapView) {
        // Supprimer les anciennes annotations (sauf utilisateur)
        let oldAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(oldAnnotations)
        
        // Ajouter l'annotation de destination
        let destinationAnnotation = AppleMapsDestinationAnnotation(location: currentDestination)
        mapView.addAnnotation(destinationAnnotation)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: AppleMapsView
        
        init(_ parent: AppleMapsView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                
                // Style Apple Maps : ligne bleue épaisse avec bordure
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 12.0
                renderer.lineCap = .round
                renderer.lineJoin = .round
                
                // Effet de profondeur comme Apple Maps
                renderer.alpha = 0.9
                
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil // Utiliser le style par défaut
            }
            
            guard let destAnnotation = annotation as? AppleMapsDestinationAnnotation else {
                return nil
            }
            
            let identifier = "DestinationPin"
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            annotationView.annotation = annotation
            annotationView.markerTintColor = .systemRed
            annotationView.glyphText = "📍"
            annotationView.canShowCallout = true
            annotationView.subtitleVisibility = .adaptive
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.onMapRectChange(mapView.visibleMapRect)
        }
    }
}

// MARK: - Apple Maps Style Instruction Card
struct AppleMapsInstructionCard: View {
    let instruction: String
    let distanceToStep: Double?
    let estimatedTime: TimeInterval?
    let nextInstruction: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Instruction principale
            HStack(spacing: 15) {
                // Icône de direction
                Image(systemName: directionIcon)
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(instruction)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let distance = distanceToStep {
                        Text("dans \(formatDistance(distance))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Temps estimé
                if let eta = estimatedTime {
                    VStack {
                        Text(formatTime(eta))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            // Prochaine instruction
            if let nextInstruction = nextInstruction {
                Divider()
                HStack {
                    Image(systemName: "arrow.turn.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Puis \(nextInstruction)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    private var directionIcon: String {
        let lowercased = instruction.lowercased()
        if lowercased.contains("gauche") {
            return "arrow.turn.up.left"
        } else if lowercased.contains("droite") {
            return "arrow.turn.up.right"
        } else if lowercased.contains("tout droit") || lowercased.contains("continuez") {
            return "arrow.up"
        } else {
            return "arrow.up"
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance)) m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60)
        return "\(minutes)"
    }
}

// MARK: - Route Manager
class AppleMapsRouteManager: ObservableObject {
    @Published var routePolylines: [MKPolyline] = []
    @Published var currentInstruction: String?
    @Published var nextInstruction: String?
    @Published var distanceToNextStep: Double?
    @Published var estimatedTime: TimeInterval?
    
    private var currentRoute: MKRoute?
    private var routeSteps: [MKRoute.Step] = []
    private var currentStepIndex = 0
    
    func calculateRoute(from start: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.requestsAlternateRoutes = false
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self = self,
                      let response = response,
                      let route = response.routes.first else { return }
                
                self.currentRoute = route
                self.routeSteps = route.steps
                self.currentStepIndex = 0
                self.routePolylines = [route.polyline]
                
                self.updateInstructions()
            }
        }
    }
    
    func updateInstructionsForLocation(_ location: CLLocation) {
        guard let route = currentRoute,
              !routeSteps.isEmpty,
              currentStepIndex < routeSteps.count else { return }
        
        let currentStep = routeSteps[currentStepIndex]
        
        // Calculer la distance jusqu'à la prochaine étape
        let stepLocation = CLLocation(
            latitude: currentStep.polyline.coordinate.latitude,
            longitude: currentStep.polyline.coordinate.longitude
        )
        
        let distanceToStep = location.distance(from: stepLocation)
        
        // Si on est proche de l'étape suivante, passer à la suivante
        if distanceToStep < 30 && currentStepIndex < routeSteps.count - 1 {
            currentStepIndex += 1
            updateInstructions()
        } else {
            // Mettre à jour la distance
            distanceToNextStep = distanceToStep
            
            // Calculer le temps estimé
            if let route = currentRoute {
                let remainingDistance = route.distance - route.steps.prefix(currentStepIndex).reduce(0) { $0 + $1.distance }
                estimatedTime = remainingDistance / 1000 * 1.5 * 60 // ~40 km/h en ville
            }
        }
    }
    
    private func updateInstructions() {
        guard currentStepIndex < routeSteps.count else {
            currentInstruction = "Vous êtes arrivé à destination"
            nextInstruction = nil
            return
        }
        
        let currentStep = routeSteps[currentStepIndex]
        currentInstruction = translateInstruction(currentStep.instructions)
        
        // Prochaine instruction
        if currentStepIndex + 1 < routeSteps.count {
            let nextStep = routeSteps[currentStepIndex + 1]
            nextInstruction = translateInstruction(nextStep.instructions)
        } else {
            nextInstruction = "arriver à destination"
        }
        
        distanceToNextStep = currentStep.distance
    }
    
    private func translateInstruction(_ instruction: String) -> String {
        var translated = instruction
        
        // Traductions basiques anglais → français
        translated = translated.replacingOccurrences(of: "Turn left", with: "Tournez à gauche")
        translated = translated.replacingOccurrences(of: "Turn right", with: "Tournez à droite")
        translated = translated.replacingOccurrences(of: "Continue straight", with: "Continuez tout droit")
        translated = translated.replacingOccurrences(of: "Head", with: "Dirigez-vous")
        translated = translated.replacingOccurrences(of: "Arrive at", with: "Arrivez à")
        
        return translated.isEmpty ? "Continuez tout droit" : translated
    }
}

// MARK: - Destination Annotation
class AppleMapsDestinationAnnotation: NSObject, MKAnnotation {
    let location: Location
    
    var coordinate: CLLocationCoordinate2D {
        return location.coordinate
    }
    
    var title: String? {
        return location.name
    }
    
    var subtitle: String? {
        return location.address
    }
    
    init(location: Location) {
        self.location = location
        super.init()
    }
} 