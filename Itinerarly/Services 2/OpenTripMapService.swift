import Foundation
import CoreLocation
import MapKit

// MARK: - Service de recherche de lieux
class OpenTripMapService {
    // Utilisation de MapKit pour la recherche de lieux (pas besoin de clé API)
    
    // MARK: - Rechercher des lieux
    func searchPlaces(
        categories: [LocationCategory],
        near location: CLLocation,
        radius: Double
    ) async throws -> [Location] {
        
        var allPlaces: [Location] = []
        
        for category in categories {
            let places = try await searchPlacesForCategory(
                category: category,
                near: location,
                radius: radius
            )
            allPlaces.append(contentsOf: places)
        }
        
        // Supprimer les doublons et trier par distance
        return Array(Set(allPlaces)).sorted { place1, place2 in
            let distance1 = location.distance(from: CLLocation(
                latitude: place1.latitude, 
                longitude: place1.longitude
            ))
            let distance2 = location.distance(from: CLLocation(
                latitude: place2.latitude, 
                longitude: place2.longitude
            ))
            return distance1 < distance2
        }
    }
    
    // MARK: - Rechercher pour une catégorie spécifique
    private func searchPlacesForCategory(
        category: LocationCategory,
        near location: CLLocation,
        radius: Double
    ) async throws -> [Location] {
        
        let searchTerm = getSearchTerm(for: category)
        print("🔍 Recherche MapKit: \(searchTerm) près de \(location.coordinate)")
        
        let request = MKLocalSearch.Request()
        // Ajouter une recherche plus spécifique en utilisant le geocoder reverse
        let geocoder = CLGeocoder()
        if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
            let locationQuery = [placemark.locality, placemark.country].compactMap { $0 }.joined(separator: ", ")
            request.naturalLanguageQuery = "\(searchTerm) near \(locationQuery)"
            print("🔍 Requête spécifique: \(searchTerm) near \(locationQuery)")
        } else {
            request.naturalLanguageQuery = searchTerm
            print("🔍 Requête générale: \(searchTerm)")
        }
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: radius * 1000, // Réduire le rayon pour être plus précis
            longitudinalMeters: radius * 1000
        )
        request.resultTypes = .pointOfInterest
        
        // Forcer la recherche dans la région spécifiée uniquement (iOS 18.0+)
        if #available(iOS 18.0, *) {
            request.regionPriority = .required
        }
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        print("✅ Found \(response.mapItems.count) places for category \(category)")
        print("📍 Search region: \(request.region)")
        print("🔍 Search term: \(searchTerm)")
        
        let locations: [Location] = response.mapItems.compactMap { mapItem in
            guard let name = mapItem.name, !name.isEmpty else { 
                print("❌ Skipping place without name")
                return nil 
            }
            
            // Vérifier que le lieu est vraiment dans la région demandée
            let placeLocation = CLLocation(
                latitude: mapItem.placemark.coordinate.latitude,
                longitude: mapItem.placemark.coordinate.longitude
            )
            let distanceFromCenter = location.distance(from: placeLocation) / 1000 // en km
            
            if distanceFromCenter > radius {
                print("❌ Lieu trop loin: \(name) - Distance: \(String(format: "%.1f", distanceFromCenter)) km > \(radius) km")
                return nil
            }
            
            let createdLocation = Location(
                id: mapItem.placemark.title ?? UUID().uuidString,
                name: name,
                address: mapItem.placemark.formattedAddress,
                latitude: mapItem.placemark.coordinate.latitude,
                longitude: mapItem.placemark.coordinate.longitude,
                category: category,
                description: mapItem.placemark.title ?? "Point d'intérêt",
                imageURL: nil,
                rating: nil,
                openingHours: nil,
                recommendedDuration: getRecommendedDuration(for: category),
                visitTips: [generateVisitTips(for: category)]
            )
            
            print("✅ Lieu accepté: \(name) - Distance: \(String(format: "%.1f", distanceFromCenter)) km")
            return createdLocation
        }
        
        print("🎯 Total locations created for \(category): \(locations.count)")
        return locations
    }
    
    // MARK: - Convertir LocationCategory vers termes de recherche MapKit
    private func getSearchTerm(for category: LocationCategory) -> String {
        switch category {
        case .restaurant:
            return "restaurant"
        case .cafe:
            return "cafe"
        case .museum:
            return "museum"
        case .culture:
            return "theater"
        case .sport:
            return "gym"
        case .shopping:
            return "shopping"
        case .nature:
            return "park"
        case .bar:
            return "bar"
        case .entertainment:
            return "cinema"
        case .aquarium:
            return "aquarium"
        case .zoo:
            return "zoo"
        case .historical, .religious, .adventurePark, .iceRink, .swimmingPool, .climbingGym, .escapeRoom, .laserTag, .bowling, .miniGolf, .paintball, .karting, .trampolinePark, .waterPark:
            return "activity"
        }
    }
    
    // MARK: - Durée recommandée par catégorie
    private func getRecommendedDuration(for category: LocationCategory) -> TimeInterval {
        switch category {
        case .restaurant, .cafe, .bar:
            return 3600 // 1h
        case .museum, .culture:
            return 7200 // 2h
        case .sport:
            return 5400 // 1h30
        case .shopping:
            return 3600 // 1h
        case .nature:
            return 5400 // 1h30
        case .entertainment:
            return 7200 // 2h
        case .aquarium, .zoo:
            return 10800 // 3h
        case .historical, .religious, .adventurePark, .iceRink, .swimmingPool, .climbingGym, .escapeRoom, .laserTag, .bowling, .miniGolf, .paintball, .karting, .trampolinePark, .waterPark:
            return 5400 // 1h30 par défaut
        }
    }
    
    // MARK: - Générer des conseils de visite
    private func generateVisitTips(for category: LocationCategory) -> String {
        switch category {
        case .restaurant:
            return "Réservez à l'avance pour les heures de pointe"
        case .cafe:
            return "Parfait pour une pause détente"
        case .museum:
            return "Vérifiez les horaires d'ouverture"
        case .culture:
            return "Idéal pour découvrir l'histoire locale"
        case .sport:
            return "Prévoyez une tenue adaptée"
        case .shopping:
            return "Profitez des soldes saisonnières"
        case .nature:
            return "Parfait pour une balade en plein air"
        case .bar:
            return "Ambiance conviviale garantie"
        case .entertainment:
            return "Réservation recommandée"
        case .aquarium:
            return "Visite idéale en famille"
        case .zoo:
            return "Prévoyez une journée complète"
        case .historical, .religious, .adventurePark, .iceRink, .swimmingPool, .climbingGym, .escapeRoom, .laserTag, .bowling, .miniGolf, .paintball, .karting, .trampolinePark, .waterPark:
            return "Découvrez ce lieu unique"
        }
    }
}

// MARK: - Modèles de réponse OpenTripMap
struct OpenTripMapResponse: Codable {
    let features: [OpenTripMapFeature]
}

struct OpenTripMapFeature: Codable {
    let type: String
    let properties: OpenTripMapProperties?
    let geometry: OpenTripMapGeometry
}

struct OpenTripMapProperties: Codable {
    let xid: String?
    let name: String?
    let kinds: String?
    let address: OpenTripMapAddress?
    let wikipedia_extracts: OpenTripMapWikipedia?
}

struct OpenTripMapAddress: Codable {
    let road: String?
    let city: String?
    let country: String?
}

struct OpenTripMapWikipedia: Codable {
    let text: String?
}

struct OpenTripMapGeometry: Codable {
    let type: String
    let coordinates: [Double]
}

// MARK: - Erreurs
enum OpenTripMapError: LocalizedError {
    case invalidURL
    case apiError(String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .apiError(let message):
            return "Erreur API: \(message)"
        case .decodingError:
            return "Erreur de décodage des données"
        }
    }
} 