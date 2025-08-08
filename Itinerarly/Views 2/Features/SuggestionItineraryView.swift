import SwiftUI
import MapKit
import CoreLocation

struct SuggestionItineraryView: View {
    let suggestions: [SuggestionResult]
    let userLocation: CLLocation?
    @State private var region: MKCoordinateRegion
    @State private var selectedSuggestion: SuggestionResult?
    @State private var showingMap = false
    
    init(suggestions: [SuggestionResult], userLocation: CLLocation?) {
        self.suggestions = suggestions
        self.userLocation = userLocation
        
        // Calculer la région pour afficher tous les points
        if let firstLocation = suggestions.first?.location {
            let center = CLLocationCoordinate2D(
                latitude: firstLocation.latitude,
                longitude: firstLocation.longitude
            )
            self._region = State(initialValue: MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        } else {
            self._region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Carte simplifiée
                Map(coordinateRegion: $region)
                    .frame(height: 300)
                
                // Liste des étapes
                ScrollView {
                    VStack(spacing: 16) {
                        // Point de départ
                        if let userLocation = userLocation {
                            DepartureCard(location: userLocation)
                        }
                        
                        // Étapes de l'itinéraire
                        ForEach(Array(suggestions.enumerated()), id: \.element.location.id) { index, suggestion in
                            ItineraryStepCard(
                                suggestion: suggestion,
                                stepNumber: index + 1,
                                isSelected: selectedSuggestion?.location.id == suggestion.location.id
                            )
                            .onTapGesture {
                                selectedSuggestion = suggestion
                                // Centrer la carte sur cette étape
                                withAnimation {
                                    region.center = CLLocationCoordinate2D(
                                        latitude: suggestion.location.latitude,
                                        longitude: suggestion.location.longitude
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Itinéraire suggéré")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ouvrir dans Plans") {
                        openInMaps()
                    }
                }
            }
        }
    }
    
    private func getCategoryIcon(for category: LocationCategory) -> String {
        switch category {
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .museum: return "building.2"
        case .culture: return "theatermasks.fill"
        case .sport: return "figure.run"
        case .shopping: return "bag.fill"
        case .nature: return "leaf.fill"
        case .bar: return "wineglass.fill"
        case .entertainment: return "gamecontroller.fill"
        case .aquarium: return "fish.fill"
        case .zoo: return "pawprint.fill"
        default: return "mappin"
        }
    }
    
    private func openInMaps() {
        guard !suggestions.isEmpty else { return }
        
        var mapItems: [MKMapItem] = []
        
        // Ajouter le point de départ si disponible
        if let userLocation = userLocation {
            let departurePlacemark = MKPlacemark(coordinate: userLocation.coordinate)
            let departureMapItem = MKMapItem(placemark: departurePlacemark)
            departureMapItem.name = "Point de départ"
            mapItems.append(departureMapItem)
        }
        
        // Ajouter les étapes
        for suggestion in suggestions {
            let coordinate = CLLocationCoordinate2D(
                latitude: suggestion.location.latitude,
                longitude: suggestion.location.longitude
            )
            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = suggestion.location.name
            mapItems.append(mapItem)
        }
        
        // Ouvrir dans Apple Maps
        MKMapItem.openMaps(with: mapItems, launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}



// MARK: - Carte d'étape d'itinéraire
struct ItineraryStepCard: View {
    let suggestion: SuggestionResult
    let stepNumber: Int
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack {
                Image(systemName: getCategoryIcon(for: suggestion.location.category))
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color.blue : Color.orange)
                    .clipShape(Circle())
                
                Text("\(stepNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .blue : .orange)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(suggestion.location.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .blue : .primary)
                
                if let description = suggestion.location.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Label("\(formatDuration(suggestion.estimatedDuration))", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("\(String(format: "%.1f", suggestion.distance)) km", systemImage: "location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                openInMaps()
            }) {
                Image(systemName: "arrow.up.right.square")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    private func getCategoryIcon(for category: LocationCategory) -> String {
        switch category {
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .museum: return "building.2"
        case .culture: return "theatermasks.fill"
        case .sport: return "figure.run"
        case .shopping: return "bag.fill"
        case .nature: return "leaf.fill"
        case .bar: return "wineglass.fill"
        case .entertainment: return "gamecontroller.fill"
        case .aquarium: return "fish.fill"
        case .zoo: return "pawprint.fill"
        default: return "mappin"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes > 0 ? " \(minutes)min" : "")"
        } else {
            return "\(minutes)min"
        }
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: suggestion.location.latitude,
            longitude: suggestion.location.longitude
        )
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = suggestion.location.name
        mapItem.openInMaps(launchOptions: nil)
    }
}

#Preview {
    let mockSuggestions = [
        SuggestionResult(
            location: Location(
                id: "1",
                name: "Restaurant Le Gourmet",
                address: "123 Rue de la Gastronomie",
                latitude: 48.8566,
                longitude: 2.3522,
                category: .restaurant,
                description: "Restaurant gastronomique",
                imageURL: nil,
                rating: 4.5,
                openingHours: nil,
                recommendedDuration: 3600,
                visitTips: ["Réservez à l'avance"]
            ),
            estimatedDuration: 3600,
            distance: 1.2,
            interestScore: 8.5,
            description: "Délicieux restaurant gastronomique"
        )
    ]
    
    SuggestionItineraryView(suggestions: mockSuggestions, userLocation: CLLocation(latitude: 48.8566, longitude: 2.3522))
} 