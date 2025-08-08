import SwiftUI
import MapKit
import CoreLocation

struct TourRouteMapView: View {
    let tour: GuidedTour
    @State private var region = MKCoordinateRegion()
    @State private var currentStepIndex = 0
    @State private var showingStepDetail = false
    @State private var mapType = MKMapType.standard
    @StateObject private var routeService = TourRouteService()
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        ZStack {
            // Carte avec itinéraire
            RouteMapView(
                tour: tour,
                currentStep: currentStepIndex,
                region: $region,
                annotationItems: annotationItems,
                routeService: routeService,
                onPinTap: { index in
                    currentStepIndex = index
                    showingStepDetail = true
                }
            )
            
            // Indicateur de chargement
            if routeService.isLoading {
                VStack {
                    ProgressView("Calcul de l'itinéraire...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                }
            }
            
            // Message d'erreur
            if let error = routeService.error {
                VStack {
                    Text("⚠️ Erreur")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                }
            }
            
            // Interface de contrôle
            VStack {
                // Header avec infos du tour
                TourMapHeader(tour: tour, mapType: $mapType, routeService: routeService)
                
                Spacer()
                
                // Contrôles de navigation
                TourNavigationControls(
                    tour: tour,
                    currentStep: $currentStepIndex,
                    showingDetail: $showingStepDetail
                )
            }
        }
        .navigationTitle("Itinéraire")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupMapRegion()
            routeService.calculateRouteForTour(tour)
        }
        .sheet(isPresented: $showingStepDetail) {
            if currentStepIndex == 0 {
                StartPointDetailView(tour: tour, startAddress: tour.startAddress)
            } else if currentStepIndex <= tour.stops.count {
                let stop = tour.optimizedStops?[currentStepIndex - 1] ?? tour.stops[currentStepIndex - 1]
                StopDetailView(stop: stop, stepIndex: currentStepIndex)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var annotationItems: [RouteAnnotation] {
        var items: [RouteAnnotation] = []
        
        // Point de départ
        if let startLocation = tour.startLocation {
            items.append(RouteAnnotation(
                id: "start",
                coordinate: startLocation,
                isStartPoint: true,
                index: 0
            ))
        }
        
        // Arrêts optimisés du tour
        let stopsToUse = tour.optimizedStops ?? tour.stops
        for (index, stop) in stopsToUse.enumerated() {
            items.append(RouteAnnotation(
                id: stop.id,
                coordinate: stop.location.coordinate,
                stop: stop,
                isStartPoint: false,
                index: index + 1
            ))
        }
        
        return items
    }
    
    // MARK: - Functions
    
    private func setupMapRegion() {
        let stops = tour.optimizedStops ?? tour.stops
        let coordinates = [tour.startLocation].compactMap { $0 } + stops.map { $0.location.coordinate }
        
        if !coordinates.isEmpty {
            let minLat = coordinates.map { $0.latitude }.min() ?? 0
            let maxLat = coordinates.map { $0.latitude }.max() ?? 0
            let minLon = coordinates.map { $0.longitude }.min() ?? 0
            let maxLon = coordinates.map { $0.longitude }.max() ?? 0
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            
            let span = MKCoordinateSpan(
                latitudeDelta: max(maxLat - minLat, 0.01) * 1.2,
                longitudeDelta: max(maxLon - minLon, 0.01) * 1.2
            )
            
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
}

// MARK: - Route Annotation Model
struct RouteAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let stop: TourStop?
    let isStartPoint: Bool
    let index: Int
    
    init(id: String, coordinate: CLLocationCoordinate2D, stop: TourStop? = nil, isStartPoint: Bool = false, index: Int) {
        self.id = id
        self.coordinate = coordinate
        self.stop = stop
        self.isStartPoint = isStartPoint
        self.index = index
    }
}

// MARK: - Route Map View with Overlays
struct RouteMapView: UIViewRepresentable {
    let tour: GuidedTour
    let currentStep: Int
    @Binding var region: MKCoordinateRegion
    let annotationItems: [RouteAnnotation]
    let routeService: TourRouteService
    let onPinTap: (Int) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.mapType = .standard
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Mettre à jour la région
        mapView.setRegion(region, animated: true)
        
        // Supprimer les overlays et annotations existants
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        // Ajouter les annotations
        for item in annotationItems {
            let annotation = TourRouteAnnotation()
            annotation.coordinate = item.coordinate
            if item.isStartPoint {
                if let startAddress = tour.startAddress, !startAddress.isEmpty {
                    annotation.title = startAddress
                } else {
                    annotation.title = "Point de départ"
                }
            } else {
                annotation.title = item.stop?.location.name
            }
            annotation.routeItem = item
            mapView.addAnnotation(annotation)
        }
        
        // Ajouter les polylines de l'itinéraire calculé
        for (index, polyline) in routeService.routePolylines.enumerated() {
            polyline.title = index < currentStep ? "completed" : (index == currentStep ? "current" : "upcoming")
            mapView.addOverlay(polyline)
        }
        
        context.coordinator.onPinTap = onPinTap
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var onPinTap: ((Int) -> Void)?
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.lineWidth = 8
                renderer.lineCap = .round
                renderer.lineJoin = .round
                
                switch polyline.title {
                case "completed":
                    renderer.strokeColor = UIColor.systemGreen
                case "current":
                    renderer.strokeColor = UIColor.systemBlue
                default:
                    renderer.strokeColor = UIColor.systemGray3
                }
                
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let routeAnnotation = annotation as? TourRouteAnnotation else { return nil }
            
            let identifier = "RoutePin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Créer l'image du pin selon le type
            if let item = routeAnnotation.routeItem {
                if item.isStartPoint {
                    annotationView?.image = createStartPinImage()
                } else {
                    let isActive = item.index == routeAnnotation.routeItem?.index
                    let isCompleted = (routeAnnotation.routeItem?.index ?? 0) < item.index
                    annotationView?.image = createStopPinImage(number: item.index, isActive: isActive, isCompleted: isCompleted)
                }
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let routeAnnotation = view.annotation as? TourRouteAnnotation,
               let item = routeAnnotation.routeItem {
                onPinTap?(item.index)
            }
        }
        
        private func createStartPinImage() -> UIImage {
            let size = CGSize(width: 40, height: 40)
            return UIGraphicsImageRenderer(size: size).image { context in
                UIColor.systemGreen.setFill()
                context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
                
                // Ajouter l'icône
                if let icon = UIImage(systemName: "figure.walk") {
                    UIColor.white.setFill()
                    icon.draw(in: CGRect(x: 8, y: 8, width: 24, height: 24))
                }
            }
        }
        
        private func createStopPinImage(number: Int, isActive: Bool, isCompleted: Bool) -> UIImage {
            let size = CGSize(width: 40, height: 40)
            return UIGraphicsImageRenderer(size: size).image { context in
                // Couleur du fond
                if isCompleted {
                    UIColor.systemGreen.setFill()
                } else if isActive {
                    UIColor.systemBlue.setFill()
                } else {
                    UIColor.systemOrange.setFill()
                }
                
                context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
                
                // Texte ou icône
                UIColor.white.setFill()
                if isCompleted {
                    if let checkmark = UIImage(systemName: "checkmark") {
                        checkmark.draw(in: CGRect(x: 8, y: 8, width: 24, height: 24))
                    }
                } else {
                    let text = "\(number)" as NSString
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 16),
                        .foregroundColor: UIColor.white
                    ]
                    let textSize = text.size(withAttributes: attributes)
                    let textRect = CGRect(
                        x: (size.width - textSize.width) / 2,
                        y: (size.height - textSize.height) / 2,
                        width: textSize.width,
                        height: textSize.height
                    )
                    text.draw(in: textRect, withAttributes: attributes)
                }
            }
        }
    }
}

class TourRouteAnnotation: MKPointAnnotation {
    var routeItem: RouteAnnotation?
}

// MARK: - Supporting Views

struct TourMapHeader: View {
    let tour: GuidedTour
    @Binding var mapType: MKMapType
    @ObservedObject var routeService: TourRouteService
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tour.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.walk")
                            .foregroundColor(.white.opacity(0.8))
                        Text(routeService.isLoading ? "Calcul..." : TourOptimizer.formatDistance(routeService.totalDistance))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.white.opacity(0.8))
                        Text(routeService.isLoading ? "Calcul..." : TourOptimizer.formatDuration(routeService.totalDuration))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Bouton Ouvrir dans Plans
                Button(action: openInMaps) {
                    Image(systemName: "map.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                
                // Bouton Type de carte
                Button(action: {
                    mapType = mapType == .standard ? .satellite : .standard
                }) {
                    Image(systemName: mapType == .standard ? "map" : "map.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
    
    private func openInMaps() {
        var locations: [MKMapItem] = []
        
        // Ajouter le point de départ
        if let startLocation = tour.startLocation {
            let startMapItem = MKMapItem(placemark: MKPlacemark(coordinate: startLocation))
            if let startAddress = tour.startAddress, !startAddress.isEmpty {
                startMapItem.name = startAddress
            } else {
                startMapItem.name = "Point de départ"
            }
            locations.append(startMapItem)
        }
        
        // Ajouter tous les arrêts optimisés ou normaux
        let stops = tour.optimizedStops ?? tour.stops
        for stop in stops {
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: stop.location.coordinate))
            mapItem.name = stop.location.name
            locations.append(mapItem)
        }
        
        // Ouvrir dans Plans avec tous les points
        // Les tours guidés sont généralement à pied
        if !locations.isEmpty {
            MKMapItem.openMaps(with: locations, launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
            ])
        }
    }
}

struct TourNavigationControls: View {
    let tour: GuidedTour
    @Binding var currentStep: Int
    @Binding var showingDetail: Bool
    
    private var totalSteps: Int {
        return (tour.optimizedStops ?? tour.stops).count + 1 // +1 pour le point de départ
    }
    
    private var currentStepInfo: String {
        if currentStep == 0 {
            if let startAddress = tour.startAddress, !startAddress.isEmpty {
                return startAddress
            } else {
                return "Votre point de départ"
            }
        } else {
            let stops = tour.optimizedStops ?? tour.stops
            if currentStep <= stops.count {
                return stops[currentStep - 1].location.name
            }
        }
        return "Arrivée"
    }
    
    private var currentStepDescription: String {
        if currentStep == 0 {
            return "D'ici, vous irez vers le premier lieu du tour"
        } else {
            let stops = tour.optimizedStops ?? tour.stops
            if currentStep <= stops.count {
                return stops[currentStep - 1].location.address
            }
        }
        return "Fin du tour"
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Indicateur de progression
            HStack {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    if index < totalSteps - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal)
            
            // Informations de l'étape actuelle
            VStack(spacing: 8) {
                if currentStep == 0 {
                    Text("Point de départ")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                } else {
                    Text("Étape \(currentStep) sur \(totalSteps - 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(currentStepInfo)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(currentStepDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    showingDetail = true
                }) {
                    Text(currentStep == 0 ? "Voir les informations" : "Voir les détails")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(currentStep == 0 ? Color.green : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            }
            
            // Contrôles de navigation
            HStack(spacing: 20) {
                Button(action: {
                    if currentStep > 0 {
                        currentStep -= 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Précédent")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(currentStep > 0 ? Color.gray.opacity(0.2) : Color.clear)
                    .foregroundColor(currentStep > 0 ? .primary : .secondary)
                    .cornerRadius(8)
                }
                .disabled(currentStep == 0)
                
                Button(action: {
                    if currentStep < totalSteps - 1 {
                        currentStep += 1
                    }
                }) {
                    HStack {
                        Text("Suivant")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(currentStep < totalSteps - 1 ? Color.blue : Color.clear)
                    .foregroundColor(currentStep < totalSteps - 1 ? .white : .secondary)
                    .cornerRadius(8)
                }
                .disabled(currentStep >= totalSteps - 1)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
}

// MARK: - Pin Views

struct StartPointPin: View {
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.green : Color.green.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                
                Image(systemName: "figure.walk")
                    .foregroundColor(.white)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text("Départ")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
        }
    }
}

struct StopPin: View {
    let stop: TourStop
    let index: Int
    let isActive: Bool
    let isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : (isActive ? Color.blue : Color.orange))
                        .frame(width: 40, height: 40)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.title2)
                            .fontWeight(.bold)
                    } else {
                        Text("\(index)")
                            .foregroundColor(.white)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                
                Text(stop.location.name)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(isActive ? .blue : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    .lineLimit(1)
                    .frame(maxWidth: 80)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Detail Views

struct StartPointDetailView: View {
    let tour: GuidedTour
    let startAddress: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // En-tête
                VStack(spacing: 12) {
                    Image(systemName: "figure.walk.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Votre point de départ")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let address = startAddress, !address.isEmpty {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else if let startLocation = tour.startLocation {
                        Text("Position sélectionnée")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Position actuelle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Informations du tour
                VStack(alignment: .leading, spacing: 16) {
                    Text("Informations du parcours")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if let distance = tour.totalDistance, let travelTime = tour.estimatedTravelTime {
                        VStack(spacing: 12) {
                            TourInfoRow(
                                icon: "figure.walk",
                                title: "Distance totale du parcours",
                                value: TourOptimizer.formatDistance(distance),
                                color: .green
                            )
                            
                            TourInfoRow(
                                icon: "timer",
                                title: "Temps de marche total",
                                value: TourOptimizer.formatDuration(travelTime),
                                color: .orange
                            )
                            
                            TourInfoRow(
                                icon: "clock",
                                title: "Durée totale avec visites",
                                value: TourOptimizer.formatDuration(tour.duration),
                                color: .blue
                            )
                            
                            TourInfoRow(
                                icon: "mappin.and.ellipse",
                                title: "Nombre de lieux à visiter",
                                value: "\(tour.stops.count) arrêts",
                                color: .purple
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Premier arrêt du tour
                if let firstStop = tour.optimizedStops?.first ?? tour.stops.first {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🎯 Premier lieu du tour")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(firstStop.location.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(firstStop.location.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Conseils de départ
                VStack(alignment: .leading, spacing: 12) {
                    Text("💡 Conseils avant de partir")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        TipRow(icon: "👟", text: "Portez des chaussures confortables")
                        TipRow(icon: "🎧", text: "Écouteurs recommandés pour les guides audio")
                        TipRow(icon: "📱", text: "Batterie chargée pour la navigation")
                        TipRow(icon: "💧", text: "Hydratez-vous régulièrement")
                        TipRow(icon: "🗺️", text: "Suivez l'itinéraire optimisé pour un parcours efficace")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Point de départ")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StopDetailView: View {
    let stop: TourStop
    let stepIndex: Int
    @EnvironmentObject var audioService: AudioService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // En-tête de l'arrêt
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 60, height: 60)
                            
                            Text("\(stepIndex)")
                                .foregroundColor(.white)
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        
                        Text(stop.location.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(stop.location.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Informations de timing
                    if let arrivalTime = stop.estimatedArrivalTime,
                       let departureTime = stop.estimatedDepartureTime,
                       let distance = stop.distanceFromPrevious,
                       let travelTime = stop.travelTimeFromPrevious {
                        
                        VStack(spacing: 12) {
                            TourInfoRow(
                                icon: "clock.arrow.circlepath",
                                title: "Arrivée prévue",
                                value: arrivalTime.timeString(),
                                color: .green
                            )
                            
                            TourInfoRow(
                                icon: "clock",
                                title: "Temps de visite",
                                value: TourOptimizer.formatDuration(stop.visitDuration),
                                color: .blue
                            )
                            
                            TourInfoRow(
                                icon: "clock.arrow.circlepath",
                                title: "Départ prévu",
                                value: departureTime.timeString(),
                                color: .orange
                            )
                            
                            if stepIndex > 1 {
                                Divider()
                                
                                TourInfoRow(
                                    icon: "figure.walk",
                                    title: "Distance depuis l'arrêt précédent",
                                    value: TourOptimizer.formatDistance(distance),
                                    color: .purple
                                )
                                
                                TourInfoRow(
                                    icon: "timer",
                                    title: "Temps de marche",
                                    value: TourOptimizer.formatDuration(travelTime),
                                    color: .red
                                )
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Guide audio
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🎧 Guide audio")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text(stop.audioGuideText)
                            .font(.body)
                            .lineSpacing(2)
                        
                        Button(action: {
                            audioService.speakText(stop.audioGuideText)
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Écouter le guide")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Conseils pratiques
                    if let tips = stop.tips {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("💡 Conseils pratiques")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Text(tips)
                                .font(.body)
                                .lineSpacing(2)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Arrêt \(stepIndex)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Helper Views

struct TourInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(icon)
                .font(.body)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    TourRouteMapView(tour: GuidedTour(
        id: "preview",
        title: "Tour de démonstration",
        city: .paris,
        description: "Un tour exemple",
        duration: 7200,
        difficulty: .easy,
        stops: [],
        imageURL: nil,
        rating: 4.5,
        price: nil
    ))
    .environmentObject(LocationManager())
    .environmentObject(AudioService())
} 