import SwiftUI
import MapKit
import CoreLocation

struct AnnotatedLocation: Identifiable {
    let id = UUID()
    let location: Location
    let index: Int
}

struct SimpleGPSNavigation: View {
    let trip: DayTrip
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var region = MKCoordinateRegion()
    @State private var currentDestinationIndex = 0
    @State private var isNavigating = false
    
    var currentDestination: Location? {
        guard currentDestinationIndex < trip.optimizedRoute.count else { return nil }
        return trip.optimizedRoute[currentDestinationIndex]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Carte simple
                mapView
                
                // Interface de navigation
                navigationOverlay
            }
            .navigationTitle("Navigation GPS")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .onAppear {
            setupNavigation()
        }
        .onReceive(locationManager.$location) { location in
            if let location = location {
                updateForNewLocation(location)
            }
        }
    }
    
    private var mapView: some View {
        Map(coordinateRegion: $region, 
            showsUserLocation: true,
            userTrackingMode: .constant(.follow),
            annotationItems: Array(trip.optimizedRoute.enumerated().map { index, location in
                AnnotatedLocation(location: location, index: index)
            })) { annotatedLocation in
            MapAnnotation(coordinate: annotatedLocation.location.coordinate) {
                destinationPin(for: annotatedLocation.index)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private var navigationOverlay: some View {
        VStack {
            // En haut : informations sur la destination
            if let destination = currentDestination {
                destinationInfoCard(destination: destination)
            }
            
            Spacer()
            
            // En bas : contrôles
            controlsBar
        }
    }
    
    private func destinationPin(for index: Int) -> some View {
        ZStack {
            Circle()
                .fill(pinColor(for: index))
                .frame(width: 30, height: 30)
            
            Text("\(index + 1)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
    
    private func pinColor(for index: Int) -> Color {
        if index == currentDestinationIndex {
            return .red
        } else if index < currentDestinationIndex {
            return .green
        } else {
            return .blue
        }
    }
    
    private func destinationInfoCard(destination: Location) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "location.north.line")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("Direction:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(destination.name)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Arrêt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(currentDestinationIndex + 1)/\(trip.optimizedRoute.count)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            
            // Distance et temps estimé
            if let userLocation = locationManager.location {
                distanceAndTimeInfo(destination: destination, userLocation: userLocation)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .shadow(radius: 5)
    }
    
    private func distanceAndTimeInfo(destination: Location, userLocation: CLLocation) -> some View {
        let distance = userLocation.distance(from: destination.clLocation)
        let estimatedTime = Int(distance / 30) // 30 m/s = ~100 km/h
        
        return HStack {
            HStack {
                Image(systemName: "ruler")
                Text("\(Int(distance))m")
            }
            
            Spacer()
            
            HStack {
                Image(systemName: "clock")
                Text("\(estimatedTime)s")
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    
    private var controlsBar: some View {
        HStack(spacing: 16) {
            // Bouton destination suivante
            Button(action: goToNextDestination) {
                HStack {
                    Image(systemName: "arrow.right")
                    Text("Suivant")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(currentDestinationIndex >= trip.optimizedRoute.count - 1)
            
            // Bouton recentrer
            Button(action: recenterMap) {
                Image(systemName: "location")
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            // Bouton terminer
            Button(action: { dismiss() }) {
                HStack {
                    Image(systemName: "xmark")
                    Text("Terminer")
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 50)
    }
    
    private func setupNavigation() {
        // Démarrer le tracking de position
        locationManager.startUpdatingLocation()
        
        // Configurer la région initiale
        if let userLocation = locationManager.location {
            region = MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: 2000,
                longitudinalMeters: 2000
            )
        } else if let firstDestination = trip.optimizedRoute.first {
            region = MKCoordinateRegion(
                center: firstDestination.coordinate,
                latitudinalMeters: 2000,
                longitudinalMeters: 2000
            )
        }
        
        isNavigating = true
    }
    
    private func updateForNewLocation(_ location: CLLocation) {
        guard let destination = currentDestination else { return }
        
        // Vérifier si on est arrivé (moins de 100m)
        let distance = location.distance(from: destination.clLocation)
        if distance < 100 {
            // Arrivé à destination - passer au suivant automatiquement
            goToNextDestination()
        }
        
        // Recentrer la carte sur l'utilisateur
        withAnimation(.easeInOut(duration: 2.0)) {
            region.center = location.coordinate
        }
    }
    
    private func goToNextDestination() {
        guard currentDestinationIndex < trip.optimizedRoute.count - 1 else {
            // Fin du voyage
            return
        }
        
        currentDestinationIndex += 1
        
        // Animer vers la nouvelle destination
        if let newDestination = currentDestination {
            withAnimation(.easeInOut(duration: 1.0)) {
                region.center = newDestination.coordinate
            }
        }
    }
    
    private func recenterMap() {
        guard let userLocation = locationManager.location else { return }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            region.center = userLocation.coordinate
        }
    }
}

#Preview {
    SimpleGPSNavigation(trip: DayTrip(
        id: "test",
        startLocation: Location(
            id: "start",
            name: "Départ",
            address: "Position de départ",
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
        locations: [
            Location(
                id: "dest1",
                name: "Tour Eiffel",
                address: "Tour Eiffel, Paris",
                latitude: 48.8584,
                longitude: 2.2945,
                category: .culture,
                description: nil,
                imageURL: nil,
                rating: nil,
                openingHours: nil,
                recommendedDuration: nil,
                visitTips: nil
            )
        ],
        optimizedRoute: [
            Location(
                id: "start",
                name: "Départ",
                address: "Position de départ",
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
            Location(
                id: "dest1",
                name: "Tour Eiffel",
                address: "Tour Eiffel, Paris",
                latitude: 48.8584,
                longitude: 2.2945,
                category: .culture,
                description: nil,
                imageURL: nil,
                rating: nil,
                openingHours: nil,
                recommendedDuration: nil,
                visitTips: nil
            )
        ],
        totalDistance: 5.0,
        estimatedDuration: 900,
        transportMode: .driving,
        createdAt: Date(),
        numberOfLocations: 1
    ))
    .environmentObject(LocationManager())
} 