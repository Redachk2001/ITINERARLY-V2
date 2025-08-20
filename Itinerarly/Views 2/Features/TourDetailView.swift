import SwiftUI
import MapKit

struct TourDetailView: View {
    let tour: GuidedTour
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var audioService: AudioService
    @State private var currentStopIndex = 0
    @State private var region = MKCoordinateRegion()
    @State private var showingMap = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                // Fond: même gradient animé que l'écran d'ouverture
                AnimatedBackground()
                    .ignoresSafeArea()
                    .frame(height: 0) // inséré comme fond via background ci-dessous
                VStack(spacing: 20) {
                    // Tour Header
                    VStack(alignment: .leading, spacing: 16) {
                        AsyncImage(url: URL(string: tour.imageURL ?? "")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.purple.opacity(0.3), .blue.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                )
                        }
                        .frame(height: ItinerarlyTheme.Sizes.tourDetailHeaderHeight)
                        .cornerRadius(16)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(tour.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                // Bouton test voix
                                Button(action: {
                                    audioService.speakText("Bienvenue sur le tour \(tour.title). Je suis \(audioService.selectedVoice.name), votre guide audio.")
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "speaker.wave.2")
                                        Text(audioService.selectedVoice.name)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                                }
                            }
                            
                            Text(tour.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .foregroundColor(.blue)
                                    Text(formatDuration(tour.duration))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Image(systemName: tour.difficulty.icon)
                                        .foregroundColor(.orange)
                                    Text(tour.difficulty.displayName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                if let rating = tour.rating {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                        Text(String(format: "%.1f", rating))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // Audio Controls
                    if !tour.stops.isEmpty && currentStopIndex < tour.stops.count {
                        AudioControlsCard(
                            currentStop: tour.stops[currentStopIndex],
                            isPlaying: audioService.isPlaying,
                            progress: audioService.currentProgress,
                            totalDuration: audioService.totalDuration,
                            onPlayPause: {
                                if audioService.isPlaying {
                                    audioService.stopSpeaking()
                                } else {
                                    audioService.speakText(tour.stops[currentStopIndex].audioGuideText)
                                }
                            },
                            onStop: {
                                audioService.stopSpeaking()
                            },
                            onForward: {
                                let next = min(audioService.currentProgress + 0.15, 1.0)
                                audioService.seekTo(progress: next)
                            }
                        )
                    } else {
                        Text("Aucun arrêt disponible")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Boutons d'action
                    VStack(spacing: 16) {
                        // Bouton Parcours Parfait
                        NavigationLink(destination: TourRouteMapView(tour: tour)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "map.fill")
                                            .foregroundColor(.white)
                                            .font(.title2)
                                        
                                        Text("🗺️ Parcours Parfait")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundColor(.white.opacity(0.8))
                                            .font(.title3)
                                    }
                                    
                                    Text("Suivez l'itinéraire optimisé étape par étape sur la carte interactive")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue,
                                        Color.purple
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Bouton Ouvrir dans Plans
                        Button(action: openInMaps) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "map.fill")
                                            .foregroundColor(.white)
                                            .font(.title2)
                                        
                                        Text("🗺️ Ouvrir dans Plans")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right.circle.fill")
                                            .foregroundColor(.white.opacity(0.8))
                                            .font(.title3)
                                    }
                                    
                                    Text("Ouvrir l'itinéraire complet dans l'application Plans d'Apple")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.orange,
                                        Color.red
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Informations d'itinéraire optimisé
                    if let startLocation = tour.startLocation {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("🗺️ Itinéraire optimisé")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("📍 Point de départ")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        if let startAddress = tour.startAddress, !startAddress.isEmpty {
                                            Text(startAddress)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("Position sélectionnée")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                                
                                HStack(spacing: 24) {
                                    VStack {
                                        Image(systemName: "figure.walk.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.green)
                                        Text(TourOptimizer.formatDistance(tour.totalDistance ?? calculateTotalDistance()))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        Text("Distance")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack {
                                        Image(systemName: "timer.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.orange)
                                        Text(TourOptimizer.formatDuration(tour.estimatedTravelTime ?? calculateTravelTime()))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        Text("Marche")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack {
                                        Image(systemName: "clock.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                        Text(TourOptimizer.formatDuration(tour.duration))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        Text("Total")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Stops Navigation
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Arrêts du parcours")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: { showingMap.toggle() }) {
                                Image(systemName: showingMap ? "list.bullet" : "map")
                                    .foregroundColor(.purple)
                            }
                        }
                        
                        if showingMap {
                            // Map View
                            let stopsToUse = tour.optimizedStops ?? tour.stops
                            Map(coordinateRegion: $region, annotationItems: stopsToUse) { stop in
                                MapAnnotation(coordinate: stop.location.coordinate) {
                                    StopMapPin(
                                        stop: stop,
                                        isSelected: currentStopIndex == max(0, min(stopsToUse.count - 1, stop.order - 1))
                                    ) {
                                        let target = stop.order - 1
                                        currentStopIndex = max(0, min(stopsToUse.count - 1, target))
                                        showingMap = false
                                    }
                                }
                            }
                            .frame(height: 300)
                            .cornerRadius(12)
                        } else {
                            // List View
                            let stopsToUse = tour.optimizedStops ?? tour.stops
                            LazyVStack(spacing: 12) {
                                ForEach(stopsToUse) { stop in
                                    TourStopDetailCard(
                                        stop: stop,
                                        index: max(0, min(stopsToUse.count - 1, stop.order - 1)),
                                        isSelected: currentStopIndex == max(0, min(stopsToUse.count - 1, stop.order - 1)),
                                        isLast: stop.order == stopsToUse.count
                                    ) {
                                        let target = stop.order - 1
                                        currentStopIndex = max(0, min(stopsToUse.count - 1, target))
                                        audioService.speakText(stop.audioGuideText)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Navigation Controls
                    if tour.stops.count > 1 {
                        HStack {
                            Button(action: previousStop) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Précédent")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color(.systemGray6))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                            }
                            .disabled(currentStopIndex == 0)
                            .opacity(currentStopIndex == 0 ? 0.5 : 1.0)
                            
                            Button(action: nextStop) {
                                HStack {
                                    Text("Suivant")
                                    Image(systemName: "chevron.right")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(currentStopIndex == tour.stops.count - 1)
                            .opacity(currentStopIndex == tour.stops.count - 1 ? 0.5 : 1.0)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(AnimatedBackground().ignoresSafeArea())
            .navigationTitle("Tour guidé")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Fermer") {
                    audioService.stopSpeaking()
                    dismiss()
                }
            )
            .onAppear { setupMapRegion() }
        }
    }
    
    private func setupMapRegion() {
        let coordinates = tour.stops.map { $0.location.coordinate }
        guard !coordinates.isEmpty else { return }
        
        let center = calculateCenterCoordinate(coordinates: coordinates)
        let span = calculateSpan(coordinates: coordinates)
        
        region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: max(span.latitudeDelta * 1.2, 0.01),
                longitudeDelta: max(span.longitudeDelta * 1.2, 0.01)
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
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        return MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.01),
            longitudeDelta: max(maxLon - minLon, 0.01)
        )
    }
    
    private func previousStop() {
        if currentStopIndex > 0 {
            currentStopIndex -= 1
            audioService.stopSpeaking()
        }
    }
    
    private func nextStop() {
        if currentStopIndex < tour.stops.count - 1 {
            currentStopIndex += 1
            audioService.stopSpeaking()
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)min"
    }
    
    // MARK: - Calculs dynamiques
    
    private func calculateTotalDistance() -> Double {
        guard let startLocation = tour.startLocation else { 
            print("❌ Pas de startLocation pour le calcul de distance")
            return 0 
        }
        
        let stopsToUse = tour.optimizedStops ?? tour.stops
        guard !stopsToUse.isEmpty else { 
            print("❌ Pas d'arrêts pour le calcul de distance")
            return 0 
        }
        
        print("🗺️ Calcul de distance:")
        print("   Point de départ: \(startLocation.latitude), \(startLocation.longitude)")
        print("   Arrêts à utiliser: \(stopsToUse.map { $0.location.name })")
        
        var totalDistance: Double = 0
        var currentLocation = startLocation
        
        // Calculer la distance du point de départ au premier arrêt
        if let firstStop = stopsToUse.first {
            let distance = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
                .distance(from: firstStop.location.clLocation)
            totalDistance += distance
            currentLocation = firstStop.location.coordinate
            print("   Distance vers premier arrêt (\(firstStop.location.name)): \(String(format: "%.0f", distance))m")
        }
        
        // Calculer les distances entre les arrêts
        for i in 0..<stopsToUse.count - 1 {
            let from = stopsToUse[i]
            let to = stopsToUse[i + 1]
            
            let distance = CLLocation(latitude: from.location.latitude, longitude: from.location.longitude)
                .distance(from: to.location.clLocation)
            totalDistance += distance
            print("   Distance \(from.location.name) → \(to.location.name): \(String(format: "%.0f", distance))m")
        }
        
        print("   Distance totale: \(String(format: "%.0f", totalDistance))m")
        return totalDistance
    }
    
    private func calculateTravelTime() -> TimeInterval {
        let totalDistance = calculateTotalDistance()
        // Estimation : 5 km/h pour la marche
        return totalDistance / (5000 / 3600) // 5000 mètres par heure
    }
    
    private func openInMaps() {
        var locations: [MKMapItem] = []
        
        // Ajouter le point de départ s'il existe
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

struct AudioControlsCard: View {
    let currentStop: TourStop
    let isPlaying: Bool
    let progress: Double
    let totalDuration: Double
    let onPlayPause: () -> Void
    let onStop: () -> Void
    let onForward: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🎧 Guide audio")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack {
                Text(currentStop.location.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            // Progress Bar dynamique
            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                HStack {
                    Text(formattedTime(progress * totalDuration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formattedTime(totalDuration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Controls
            HStack(spacing: 24) {
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)
                }
                
                Button(action: onForward) {
                    Image(systemName: "forward.end.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(16)
    }

    private func formattedTime(_ seconds: Double) -> String {
        guard seconds.isFinite && !seconds.isNaN else { return "--:--" }
        let s = Int(seconds)
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }
}

struct StopMapPin: View {
    let stop: TourStop
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.purple : Color.blue)
                        .frame(width: 30, height: 30)
                    
                    Text("\(stop.order)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text(stop.location.name)
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
}

struct TourStopDetailCard: View {
    let stop: TourStop
    let index: Int
    let isSelected: Bool
    let isLast: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Step indicator
                VStack {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.purple : Color.blue)
                            .frame(width: 30, height: 30)
                        
                        Text("\(stop.order)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    if !isLast {
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 2, height: 40)
                    }
                }
                
                // Location info
                VStack(alignment: .leading, spacing: 8) {
                    Text(stop.location.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(stop.location.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Informations de timing optimisé
                    if let arrivalTime = stop.estimatedArrivalTime,
                       let departureTime = stop.estimatedDepartureTime,
                       let distance = stop.distanceFromPrevious,
                       let travelTime = stop.travelTimeFromPrevious,
                       stop.order > 1 {
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 12) {
                                HStack(spacing: 2) {
                                    Image(systemName: "figure.walk")
                                        .foregroundColor(.green)
                                        .font(.caption2)
                                    Text(TourOptimizer.formatDistance(distance))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                }
                                
                                HStack(spacing: 2) {
                                    Image(systemName: "timer")
                                        .foregroundColor(.orange)
                                        .font(.caption2)
                                    Text(TourOptimizer.formatDuration(travelTime))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            Text("Arrivée: \(arrivalTime.timeString()) • Départ: \(departureTime.timeString())")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        Text(formatDuration(stop.visitDuration))
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("de visite")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.purple)
                                .font(.caption)
                        }
                    }
                    
                    if let tips = stop.tips {
                        Text("💡 \(tips)")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.purple.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)min"
    }
}

#Preview {
    TourDetailView(tour: GuidedTour(
        id: "preview",
        title: "Tour de démonstration",
        city: .paris,
        description: "Un tour exemple pour la prévisualisation",
        duration: 7200,
        difficulty: .easy,
        stops: [],
        imageURL: nil,
        rating: 4.5,
        price: nil
    ))
    .environmentObject(AudioService())
} 