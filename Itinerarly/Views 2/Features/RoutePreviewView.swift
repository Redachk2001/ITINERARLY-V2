import SwiftUI
import MapKit
import CoreLocation

struct RoutePreviewView: View {
    let trip: DayTrip
    @Environment(\.dismiss) private var dismiss
    @StateObject private var routeCalculator = CompleteRouteCalculator()
    
    @State private var showingMap = true
    @State private var selectedStep: RouteStep?
    @State private var is3DView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header avec statistiques
                RouteStatsHeader(
                    totalDistance: routeCalculator.totalDistance,
                    totalDuration: routeCalculator.totalDuration,
                    stepsCount: routeCalculator.routeSteps.count,
                    is3DMode: is3DView
                )
                
                // Toggle Map/Liste
                Picker("Mode d'affichage", selection: $showingMap) {
                    Text("Carte").tag(true)
                    Text("Instructions").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if showingMap {
                    // Vue carte avec route complète
                    CompleteRouteMapView(
                        trip: trip,
                        routeSteps: routeCalculator.routeSteps,
                        selectedStep: $selectedStep,
                        is3DView: is3DView
                    )
                } else {
                    // Liste détaillée des instructions
                    RouteInstructionsList(
                        routeSteps: routeCalculator.routeSteps,
                        selectedStep: $selectedStep
                    )
                }
                
                // Boutons d'action
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            is3DView.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: is3DView ? "view.2d" : "view.3d")
                                .font(.title3)
                            Text(is3DView ? "Vue 2D" : "Aperçu 3D")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Group {
                            if is3DView {
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .purple.opacity(0.7)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue.opacity(0.8), .blue.opacity(0.6)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            }
                        }
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: is3DView ? .purple.opacity(0.3) : .blue.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    Button("Démarrer GPS") {
                        dismiss()
                        // Retourner au GPS
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle(is3DView ? "Aperçu 3D de la route" : "Aperçu de la route")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            calculateCompleteRoute()
        }
    }
    
    private func calculateCompleteRoute() {
        routeCalculator.calculateCompleteRoute(for: trip)
    }
}

// MARK: - Route Stats Header
struct RouteStatsHeader: View {
    let totalDistance: Double
    let totalDuration: TimeInterval
    let stepsCount: Int
    let is3DMode: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            VStack {
                Image(systemName: "road.lanes")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(String(format: "%.1f km", totalDistance))
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Distance")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack {
                Image(systemName: "clock")
                    .font(.title2)
                    .foregroundColor(.green)
                Text(formatDuration(totalDuration))
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Durée")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack {
                Image(systemName: "list.number")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("\(stepsCount)")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Étapes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Indicateur mode 3D
            if is3DMode {
                Divider()
                    .frame(height: 40)
                
                VStack {
                    Image(systemName: "view.3d")
                        .font(.title2)
                        .foregroundColor(.purple)
                    Text("3D")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    Text("Activé")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(is3DMode ? 
                   LinearGradient(gradient: Gradient(colors: [Color(.systemGray6), Color.purple.opacity(0.1)]), startPoint: .leading, endPoint: .trailing) : 
                   LinearGradient(gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray6)]), startPoint: .leading, endPoint: .trailing))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

// MARK: - Complete Route Map View
struct CompleteRouteMapView: UIViewRepresentable {
    let trip: DayTrip
    let routeSteps: [RouteStep]
    @Binding var selectedStep: RouteStep?
    let is3DView: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        mapView.mapType = .standard
        mapView.showsTraffic = true
        mapView.showsBuildings = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Nettoyer les anciens overlays et annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        // Ajouter les routes
        for step in routeSteps {
            if let polyline = step.polyline {
                mapView.addOverlay(polyline)
            }
        }
        
        // Ajouter les annotations pour chaque destination
        for (index, location) in trip.optimizedRoute.enumerated() {
            let annotation = RoutePointAnnotation(
                location: location,
                index: index,
                isStart: index == 0,
                isEnd: index == trip.optimizedRoute.count - 1
            )
            mapView.addAnnotation(annotation)
        }
        
        // Centrer sur la route complète
        if !routeSteps.isEmpty {
            let coordinates = trip.optimizedRoute.map { $0.coordinate }
            
            if is3DView {
                // Mode 3D - Vue perspective inclinée
                setupCamera3D(mapView: mapView, coordinates: coordinates)
            } else {
                // Mode 2D - Vue standard
                setup2DView(mapView: mapView, coordinates: coordinates)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func setup2DView(mapView: MKMapView, coordinates: [CLLocationCoordinate2D]) {
        var region = MKCoordinateRegion()
        let mapRect = MKMapRect(coordinates: coordinates)
        region = MKCoordinateRegion(mapRect)
        
        // Ajouter du padding
        region.span.latitudeDelta *= 1.4
        region.span.longitudeDelta *= 1.4
        
        // Vue 2D standard
        mapView.camera.pitch = 0
        mapView.setRegion(region, animated: true)
    }
    
    private func setupCamera3D(mapView: MKMapView, coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }
        
        // Calculer le centre de la route
        let centerLat = coordinates.map { $0.latitude }.reduce(0, +) / Double(coordinates.count)
        let centerLon = coordinates.map { $0.longitude }.reduce(0, +) / Double(coordinates.count)
        let centerCoordinate = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        
        // Calculer la distance maximale pour ajuster l'altitude
        let distances = coordinates.map { coord in
            let location1 = CLLocation(latitude: centerLat, longitude: centerLon)
            let location2 = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            return location1.distance(from: location2)
        }
        let maxDistance = distances.max() ?? 1000
        
        // Créer une caméra 3D
        let camera = MKMapCamera()
        camera.centerCoordinate = centerCoordinate
        camera.altitude = max(maxDistance * 3, 800) // Minimum 800m d'altitude
        camera.pitch = 60 // Inclinaison 3D
        camera.heading = 0 // Direction nord
        
        // Appliquer la caméra 3D avec animation
        mapView.setCamera(camera, animated: true)
        
        // Activer les fonctionnalités 3D
        mapView.showsBuildings = true
        mapView.mapType = .standard
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CompleteRouteMapView
        
        init(_ parent: CompleteRouteMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                
                // Ligne plus épaisse en mode 3D pour une meilleure visibilité
                renderer.lineWidth = parent.is3DView ? 10.0 : 6.0
                renderer.lineCap = .round
                renderer.lineJoin = .round
                
                // Effet de profondeur en mode 3D
                if parent.is3DView {
                    renderer.alpha = 0.9
                }
                
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let routeAnnotation = annotation as? RoutePointAnnotation else { return nil }
            
            let identifier = "RoutePoint"
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            annotationView.annotation = annotation
            
            if routeAnnotation.isStart {
                annotationView.markerTintColor = .systemGreen
                annotationView.glyphText = "🚀"
            } else if routeAnnotation.isEnd {
                annotationView.markerTintColor = .systemRed
                annotationView.glyphText = "🏁"
            } else {
                annotationView.markerTintColor = .systemBlue
                annotationView.glyphText = "\(routeAnnotation.index)"
            }
            
            // Annotations plus visibles en mode 3D
            if parent.is3DView {
                annotationView.displayPriority = .required
                annotationView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            } else {
                annotationView.transform = CGAffineTransform.identity
            }
            
            annotationView.canShowCallout = true
            return annotationView
        }
    }
}

// MARK: - Route Instructions List
struct RouteInstructionsList: View {
    let routeSteps: [RouteStep]
    @Binding var selectedStep: RouteStep?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(routeSteps.indices, id: \.self) { index in
                    let step = routeSteps[index]
                    RouteInstructionCard(
                        step: step,
                        stepNumber: index + 1,
                        isSelected: selectedStep?.id == step.id
                    )
                    .onTapGesture {
                        selectedStep = step
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Route Instruction Card
struct RouteInstructionCard: View {
    let step: RouteStep
    let stepNumber: Int
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            // Numéro d'étape
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : Color(.systemGray4))
                    .frame(width: 40, height: 40)
                
                Text("\(stepNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Instruction principale
                HStack {
                    Image(systemName: step.directionIcon)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text(step.instruction)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                
                // Détails
                HStack {
                    if step.distance > 0 {
                        Label(formatDistance(step.distance), systemImage: "road.lanes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if step.duration > 0 {
                        Label(formatDuration(step.duration), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                if let street = step.streetName, !street.isEmpty {
                    Text("via \(street)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                )
        )
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes)min"
    }
}

// MARK: - Data Models
struct RouteStep: Identifiable {
    let id = UUID()
    let instruction: String
    let distance: Double
    let duration: TimeInterval
    let streetName: String?
    let coordinate: CLLocationCoordinate2D
    let polyline: MKPolyline?
    
    var directionIcon: String {
        let instruction = instruction.lowercased()
        if instruction.contains("gauche") {
            return "arrow.turn.up.left"
        } else if instruction.contains("droite") {
            return "arrow.turn.up.right"
        } else if instruction.contains("tout droit") || instruction.contains("continuez") {
            return "arrow.up"
        } else if instruction.contains("rond-point") {
            return "arrow.clockwise"
        } else if instruction.contains("demi-tour") {
            return "arrow.uturn.left"
        } else {
            return "arrow.up"
        }
    }
}

class RoutePointAnnotation: NSObject, MKAnnotation {
    let location: Location
    let index: Int
    let isStart: Bool
    let isEnd: Bool
    
    var coordinate: CLLocationCoordinate2D {
        return location.coordinate
    }
    
    var title: String? {
        if isStart {
            return "🚀 Départ: \(location.name)"
        } else if isEnd {
            return "🏁 Arrivée: \(location.name)"
        } else {
            return "📍 Étape \(index): \(location.name)"
        }
    }
    
    var subtitle: String? {
        return location.address
    }
    
    init(location: Location, index: Int, isStart: Bool, isEnd: Bool) {
        self.location = location
        self.index = index
        self.isStart = isStart
        self.isEnd = isEnd
        super.init()
    }
}

// MARK: - Complete Route Calculator
class CompleteRouteCalculator: ObservableObject {
    @Published var routeSteps: [RouteStep] = []
    @Published var totalDistance: Double = 0
    @Published var totalDuration: TimeInterval = 0
    @Published var isCalculating = false
    
    func calculateCompleteRoute(for trip: DayTrip) {
        isCalculating = true
        routeSteps = []
        totalDistance = 0
        totalDuration = 0
        
        calculateRouteSegments(for: trip.optimizedRoute) { [weak self] steps in
            DispatchQueue.main.async {
                self?.routeSteps = steps
                self?.totalDistance = steps.reduce(0) { $0 + $1.distance } / 1000.0 // en km
                self?.totalDuration = steps.reduce(0) { $0 + $1.duration }
                self?.isCalculating = false
            }
        }
    }
    
    private func calculateRouteSegments(for locations: [Location], completion: @escaping ([RouteStep]) -> Void) {
        var allSteps: [RouteStep] = []
        let dispatchGroup = DispatchGroup()
        
        for i in 0..<locations.count - 1 {
            let start = locations[i]
            let end = locations[i + 1]
            
            dispatchGroup.enter()
            
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: start.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end.coordinate))
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                defer { dispatchGroup.leave() }
                
                guard let route = response?.routes.first else { return }
                
                for (stepIndex, step) in route.steps.enumerated() {
                    let routeStep = RouteStep(
                        instruction: self.translateInstruction(step.instructions),
                        distance: step.distance,
                        duration: step.transportType == .automobile ? step.distance / 13.9 : 0, // ~50 km/h
                        streetName: step.instructions.components(separatedBy: " ").last,
                        coordinate: step.polyline.coordinate,
                        polyline: step.polyline
                    )
                    allSteps.append(routeStep)
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            // Trier par ordre logique
            let sortedSteps = allSteps.sorted { step1, step2 in
                return false // Garder l'ordre d'ajout
            }
            completion(sortedSteps)
        }
    }
    
    private func translateInstruction(_ instruction: String) -> String {
        var translated = instruction
        
        // Traductions
        translated = translated.replacingOccurrences(of: "Turn left", with: "Tournez à gauche")
        translated = translated.replacingOccurrences(of: "Turn right", with: "Tournez à droite")
        translated = translated.replacingOccurrences(of: "Continue straight", with: "Continuez tout droit")
        translated = translated.replacingOccurrences(of: "Head", with: "Dirigez-vous")
        translated = translated.replacingOccurrences(of: "Arrive at", with: "Arrivez à")
        translated = translated.replacingOccurrences(of: "on the left", with: "sur la gauche")
        translated = translated.replacingOccurrences(of: "on the right", with: "sur la droite")
        
        return translated.isEmpty ? "Continuez tout droit" : translated
    }
}

// Extension pour créer MKMapRect à partir de coordonnées
extension MKMapRect {
    init(coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else {
            self = MKMapRect.world
            return
        }
        
        let mapPoints = coordinates.map { MKMapPoint($0) }
        let minX = mapPoints.map { $0.x }.min()!
        let maxX = mapPoints.map { $0.x }.max()!
        let minY = mapPoints.map { $0.y }.min()!
        let maxY = mapPoints.map { $0.y }.max()!
        
        self = MKMapRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
} 