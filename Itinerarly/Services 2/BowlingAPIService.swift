import Foundation
import CoreLocation
import MapKit

// MARK: - Service API Bowling
class BowlingAPIService: ObservableObject {
    static let shared = BowlingAPIService()
    
    // MARK: - Recherche de bowling
    func searchBowlingAlleys(
        near location: CLLocation,
        radius: Double = 5000,
        limit: Int = 20
    ) async throws -> [Location] {
        
        print("🎳 Recherche de bowling près de \(location.coordinate)")
        
        // Utiliser le service de recherche universel existant
        let searchService = UniversalPlaceSearchService()
        
        return await withCheckedContinuation { continuation in
            searchService.searchPlacesForCategory(
                category: .bowling,
                near: location,
                radius: radius
            ) { locations in
                let limitedLocations = Array(locations.prefix(limit))
                print("🎳 Trouvé \(limitedLocations.count) bowling")
                continuation.resume(returning: limitedLocations)
            }
        }
    }
    
    // MARK: - Recherche par ville
    func searchBowlingAlleysInCity(_ city: String) async throws -> [Location] {
        // Géocoder la ville pour obtenir ses coordonnées
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(city)
        
        guard let placemark = placemarks.first,
              let location = placemark.location else {
            throw BowlingAPIError.geocodingFailed
        }
        
        return try await searchBowlingAlleys(near: location, radius: 10000, limit: 30)
    }
    
    // MARK: - Informations détaillées sur un bowling
    func getBowlingDetails(for location: Location) async throws -> BowlingDetails {
        // Simuler des détails détaillés
        return BowlingDetails(
            id: location.id,
            name: location.name,
            address: location.address,
            phoneNumber: "+33 1 23 45 67 89",
            website: "https://example-bowling.com",
            openingHours: [
                "Lundi": "14:00-23:00",
                "Mardi": "14:00-23:00",
                "Mercredi": "10:00-23:00",
                "Jeudi": "14:00-23:00",
                "Vendredi": "14:00-01:00",
                "Samedi": "10:00-01:00",
                "Dimanche": "10:00-22:00"
            ],
            prices: [
                "Partie adulte": "8€",
                "Partie étudiant": "6€",
                "Partie enfant": "5€",
                "Location chaussures": "2€"
            ],
            facilities: [
                "8 pistes de bowling",
                "Bar et restaurant",
                "Billard",
                "Fléchettes",
                "Parking gratuit",
                "Accessible aux personnes à mobilité réduite"
            ],
            specialOffers: [
                "Happy Hour: -20% de 14h à 17h",
                "Soirée étudiant: -30% le mardi",
                "Pack famille: 4 parties + boissons à 25€"
            ]
        )
    }
}

// MARK: - Modèles de données
struct BowlingDetails {
    let id: String
    let name: String
    let address: String
    let phoneNumber: String
    let website: String
    let openingHours: [String: String]
    let prices: [String: String]
    let facilities: [String]
    let specialOffers: [String]
}

// MARK: - Erreurs spécifiques au bowling
enum BowlingAPIError: Error {
    case geocodingFailed
    case noData
    case invalidLocation
}
