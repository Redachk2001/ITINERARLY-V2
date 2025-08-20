import Foundation
import CoreLocation
import MapKit

// MARK: - Service de Recherche Apple Plans UNIQUEMENT
class UniversalPlaceSearchService: ObservableObject {
    @Published var isSearching = false
    @Published var searchResults: [Location] = []
    
    // MARK: - Recherche spécifique pour une catégorie (Apple Plans uniquement)
    func searchPlacesForCategory(
        category: LocationCategory,
        near location: CLLocation,
        radius: Double = 5000,
        completion: @escaping ([Location]) -> Void
    ) {
        // Utiliser uniquement la recherche Apple Plans
        performDirectAppleMapsSearch(category: category, near: location, radius: radius, completion: completion)
    }
    
    // MARK: - Recherche automatique avec sélection intelligente (comme Apple Plans)
    func searchAndSelectBestPlace(
        category: LocationCategory,
        from startAddress: String,
        completion: @escaping (Location?) -> Void
    ) {
        let searchTerm = getSearchTerm(for: category)
        print("🎯 Recherche Apple Plans: '\(searchTerm)' depuis '\(startAddress)'")
        
        // 1. Géocoder l'adresse de départ
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(startAddress) { placemarks, error in
            if let error = error {
                print("❌ Erreur géocodage: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?.first,
                  let startLocation = placemark.location else {
                print("❌ Impossible de géocoder l'adresse: \(startAddress)")
                completion(nil)
                return
            }
            
            print("✅ Adresse géocodée: \(startLocation.coordinate)")
            
            // 2. Rechercher exactement comme dans Apple Plans
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = searchTerm
            request.region = MKCoordinateRegion(
                center: startLocation.coordinate,
                latitudinalMeters: 20000, // 20km de rayon
                longitudinalMeters: 20000
            )
            request.resultTypes = [.pointOfInterest, .address]
            
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                guard let response = response else {
                    print("❌ Erreur Apple Plans: \(error?.localizedDescription ?? "Inconnu")")
                    completion(nil)
                    return
                }
                
                print("🎯 Apple Plans a trouvé \(response.mapItems.count) résultats pour '\(searchTerm)'")
                
                // 3. Convertir les résultats et trier par distance
                let places = response.mapItems.compactMap { (mapItem: MKMapItem) -> Location? in
                    guard let name = mapItem.name, !name.isEmpty else { return nil }
                    
                    return Location(
                        id: UUID().uuidString,
                        name: name,
                        address: mapItem.placemark.formattedAddress ?? "Adresse non disponible",
                        latitude: mapItem.placemark.coordinate.latitude,
                        longitude: mapItem.placemark.coordinate.longitude,
                        category: category,
                        description: "Trouvé via Apple Plans",
                        imageURL: nil,
                        rating: 4.0,
                        openingHours: "Voir Apple Plans",
                        recommendedDuration: self.getRecommendedDuration(for: category),
                        visitTips: self.generateTips(for: category)
                    )
                }.sorted { place1, place2 in
                    let distance1 = startLocation.distance(from: CLLocation(latitude: place1.latitude, longitude: place1.longitude))
                    let distance2 = startLocation.distance(from: CLLocation(latitude: place2.latitude, longitude: place2.longitude))
                    return distance1 < distance2
                }
                
                // 4. Sélectionner le premier (le plus proche)
                if let bestPlace = places.first {
                    let distance = startLocation.distance(from: CLLocation(latitude: bestPlace.latitude, longitude: bestPlace.longitude))
                    print("✅ Lieu sélectionné: \(bestPlace.name) à \(Int(distance))m")
                    completion(bestPlace)
                } else {
                    print("❌ Aucun lieu trouvé pour '\(searchTerm)'")
                    completion(nil)
                }
            }
        }
    }
    

    
    private func performDirectAppleMapsSearch(
        category: LocationCategory,
        near location: CLLocation,
        radius: Double,
        completion: @escaping ([Location]) -> Void
    ) {
        print("🎯 Recherche directe Apple Plans pour \(category.displayName)")
        
        // Utiliser MKLocalSearch avec une requête textuelle (comme quand on tape dans Apple Plans)
        let searchTerm = getSearchTerm(for: category)
        print("🔍 Recherche dans Apple Plans: '\(searchTerm)' près de \(location.coordinate)")
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchTerm
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )
        request.resultTypes = [.pointOfInterest, .address]
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                print("❌ Erreur de recherche Apple Plans: \(error?.localizedDescription ?? "Inconnu")")
                completion([])
                return
            }
            
            print("🎯 Apple Plans a trouvé \(response.mapItems.count) résultats pour '\(searchTerm)'")
            
            let mappedLocations = response.mapItems.compactMap { (mapItem: MKMapItem) -> Location? in
                guard let name = mapItem.name, !name.isEmpty else { return nil }
                
                print("📍 Lieu trouvé: \(name) - \(mapItem.placemark.formattedAddress ?? "Pas d'adresse")")
                
                return Location(
                    id: UUID().uuidString,
                    name: name,
                    address: mapItem.placemark.formattedAddress ?? "Adresse non disponible",
                    latitude: mapItem.placemark.coordinate.latitude,
                    longitude: mapItem.placemark.coordinate.longitude,
                    category: category,
                    description: "Trouvé via Apple Plans",
                    imageURL: nil,
                    rating: 4.0,
                    openingHours: "Voir Apple Plans",
                    recommendedDuration: self.getRecommendedDuration(for: category),
                    visitTips: self.generateTips(for: category)
                )
            }
            
            let sortedPlaces = mappedLocations.sorted { place1, place2 in
                let distance1 = location.distance(from: CLLocation(latitude: place1.latitude, longitude: place1.longitude))
                let distance2 = location.distance(from: CLLocation(latitude: place2.latitude, longitude: place2.longitude))
                return distance1 < distance2
            }
            
            print("✅ Apple Plans: \(sortedPlaces.count) lieux trouvés et triés par distance")
            completion(sortedPlaces)
        }
    }
    

    
    // MARK: - Termes de recherche Apple Plans (universels pour le monde entier)
    private func getSearchTerm(for category: LocationCategory) -> String {
        switch category {
        case .swimmingPool:
            return "swimming pool"
        case .bowling:
            return "bowling"
        case .climbingGym:
            return "climbing gym"
        case .iceRink:
            return "ice rink"
        case .miniGolf:
            return "mini golf"
        case .escapeRoom:
            return "escape room"
        case .laserTag:
            return "laser tag"
        case .paintball:
            return "paintball"
        case .karting:
            return "karting"
        case .trampolinePark:
            return "trampoline park"
        case .waterPark:
            return "water park"
        case .adventurePark:
            return "adventure park"
        case .zoo:
            return "zoo"
        case .aquarium:
            return "aquarium"
        case .restaurant:
            return "restaurant"
        case .cafe:
            return "cafe"
        case .bar:
            return "bar"
        case .museum:
            return "museum"
        case .shopping:
            return "shopping"
        case .sport:
            return "gym"
        case .nature:
            return "park"
        case .entertainment:
            return "entertainment"
        case .historical:
            return "monument"
        case .culture:
            return "cultural center"
        default:
            return category.displayName.lowercased()
        }
    }
    

    

    

    

    

    
    private func getRecommendedDuration(for category: LocationCategory) -> TimeInterval {
        switch category {
        case .restaurant: return 90 * 60
        case .cafe: return 45 * 60
        case .bar: return 120 * 60
        case .museum: return 120 * 60
        case .shopping: return 90 * 60
        case .sport: return 90 * 60
        case .nature: return 120 * 60
        case .entertainment: return 120 * 60
        case .historical: return 90 * 60
        case .culture: return 120 * 60
        case .swimmingPool: return 90 * 60
        case .climbingGym: return 120 * 60
        case .iceRink: return 90 * 60
        case .bowling: return 90 * 60
        case .miniGolf: return 60 * 60
        case .escapeRoom: return 60 * 60
        case .laserTag: return 60 * 60
        case .paintball: return 120 * 60
        case .karting: return 60 * 60
        case .trampolinePark: return 90 * 60
        case .waterPark: return 180 * 60
        case .adventurePark: return 180 * 60
        case .zoo: return 180 * 60
        case .aquarium: return 120 * 60
        default: return 90 * 60
        }
    }
    
    private func generateTips(for category: LocationCategory) -> [String] {
        switch category {
        case .swimmingPool: return ["Maillot obligatoire", "Douche disponible", "Casiers disponibles"]
        case .climbingGym: return ["Équipement fourni", "Cours disponibles", "Niveaux variés"]
        case .iceRink: return ["Gants recommandés", "Location de patins", "Équipement fourni"]
        case .bowling: return ["Chaussures spéciales", "Réservation conseillée", "Équipement fourni"]
        case .miniGolf: return ["Club fourni", "Parcours variés", "Idéal en famille"]
        case .escapeRoom: return ["Équipe de 2-6 personnes", "Réservation obligatoire", "Défis variés"]
        case .laserTag: return ["Équipement fourni", "Parties rapides", "Ambiance fun"]
        case .paintball: return ["Équipement de sécurité", "Terrain extérieur", "Équipes formées"]
        case .karting: return ["Casque fourni", "Courses rapides", "Niveaux de difficulté"]
        case .trampolinePark: return ["Chaussettes spéciales", "Zones variées", "Activités pour tous"]
        case .waterPark: return ["Maillot obligatoire", "Casiers disponibles", "Activités aquatiques"]
        case .adventurePark: return ["Équipement fourni", "Niveaux variés", "Sécurité assurée"]
        case .zoo: return ["Visite guidée disponible", "Animaux actifs", "Parcours variés"]
        case .aquarium: return ["Visite guidée disponible", "Spectacles disponibles", "Espèces variées"]
        default: return ["Profitez de votre visite!", "Activité recommandée"]
        }
    }
    

    

} 