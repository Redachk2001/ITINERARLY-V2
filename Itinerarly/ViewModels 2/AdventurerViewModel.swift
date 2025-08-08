import Foundation
import CoreLocation
import Combine
import SwiftUI

// MARK: - Modèles pour le Mode Adventurer
struct AdventurerFilter {
    var address: String = ""
    var radius: Double = 5.0 // km
    var availableTime: TimeInterval = 3600 // 1 heure par défaut
    var excludedCategory: LocationCategory?
}

struct AdventurerResult {
    let locations: [Location] // Seulement les lieux d'aventure (sans le point de départ)
    let startAddress: Location? // Le point de départ comme Location
    let totalDuration: TimeInterval
    let totalDistance: Double
    let surpriseDescription: String
    
    var optimizedRoute: [Location] {
        // Inclure le point de départ au début de la route
        if let startAddress = startAddress {
            return [startAddress] + locations
        }
        return locations
    }
}

@MainActor
class AdventurerViewModel: ObservableObject {
    @Published var filter = AdventurerFilter()
    @Published var result: AdventurerResult?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldShowResults = false
    @Published var userLocation: CLLocation?
    @Published var skippedLocationIndex: Int?
    
    private var cancellables = Set<AnyCancellable>()
    let locationManager = LocationManager()
    
    // MARK: - Catégories disponibles pour exclusion
    let availableCategories: [LocationCategory] = [
        .restaurant, .cafe, .museum, .culture, .sport, 
        .shopping, .nature, .bar, .entertainment, .aquarium, .zoo
    ]
    
    // MARK: - Temps disponibles (en minutes)
    let availableTimes: [TimeInterval] = [
        1800,   // 30 min
        3600,   // 1h
        5400,   // 1h30
        7200,   // 2h
        10800   // 3h
    ]
    
    // MARK: - Générer une aventure surprise
    func generateSurpriseAdventure() async {
        isLoading = true
        errorMessage = nil
        result = nil
        skippedLocationIndex = nil
        
        do {
            // 1. Obtenir la localisation
            let userLocation = try await getUserLocation()
            self.userLocation = userLocation
            
            // 2. Rechercher des lieux insolites
            let allPlaces = try await searchUnusualPlaces(near: userLocation)
            
            // 3. Filtrer selon les contraintes
            let filteredPlaces = filterPlaces(allPlaces, userLocation: userLocation)
            
            // 4. Créer un parcours surprise
            let adventure = await createSurpriseAdventure(from: filteredPlaces, userLocation: userLocation)
            
            result = adventure
            
            // 5. Ouvrir la vue de résultats si l'aventure est générée
            if !adventure.locations.isEmpty {
                shouldShowResults = true
            }
            
            print("🎲 Aventure surprise générée avec \(adventure.locations.count) lieux")
            
        } catch {
            errorMessage = "Erreur lors de la génération : \(error.localizedDescription)"
            print("❌ Erreur aventure: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Remplacer un lieu
    func replaceLocation(at index: Int) async {
        guard let currentResult = result else { return }
        
        isLoading = true
        
        do {
            let userLocation = try await getUserLocation()
            let allPlaces = try await searchUnusualPlaces(near: userLocation)
            let filteredPlaces = filterPlaces(allPlaces, userLocation: userLocation)
            
            // Créer une nouvelle liste sans le lieu à remplacer
            var newLocations = currentResult.locations
            newLocations.remove(at: index)
            
            // Trouver un nouveau lieu qui s'intègre bien
            let remainingTime = filter.availableTime - newLocations.reduce(0) { $0 + getEstimatedDuration(for: $1.category) }
            
            let newPlace = findBestReplacement(
                from: filteredPlaces,
                existingLocations: newLocations,
                remainingTime: remainingTime,
                userLocation: userLocation
            )
            
            if let newPlace = newPlace {
                newLocations.append(newPlace)
                
                let newAdventure = await createAdventureResult(
                    locations: newLocations,
                    userLocation: userLocation
                )
                
                result = newAdventure
                skippedLocationIndex = index
            }
            
        } catch {
            errorMessage = "Erreur lors du remplacement : \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Obtenir la localisation utilisateur
    private func getUserLocation() async throws -> CLLocation {
        if filter.address.isEmpty {
            return try await withCheckedThrowingContinuation { continuation in
                locationManager.requestLocation()
                
                // Attendre la réponse avec un timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                    if let location = self?.locationManager.location {
                        continuation.resume(returning: location)
                    } else {
                        continuation.resume(throwing: AdventurerError.noLocationFound)
                    }
                }
            }
        } else {
            return try await geocodeAddress(filter.address)
        }
    }
    
    // MARK: - Geocoder une adresse
    private func geocodeAddress(_ address: String) async throws -> CLLocation {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(address)
        
        guard let placemark = placemarks.first,
              let location = placemark.location else {
            throw AdventurerError.geocodingFailed
        }
        
        return location
    }
    
    // MARK: - Rechercher des lieux insolites
    private func searchUnusualPlaces(near location: CLLocation) async throws -> [Location] {
        let searchService = OpenTripMapService()
        
        // Rechercher des lieux insolites et originaux
        let unusualCategories: [LocationCategory] = [
            .culture, .museum, .nature, .entertainment, .aquarium, .zoo
        ]
        
        var allPlaces: [Location] = []
        
        for category in unusualCategories {
            // Exclure la catégorie choisie par l'utilisateur
            if category == filter.excludedCategory {
                continue
            }
            
            let places = try await searchService.searchPlaces(
                categories: [category],
                near: location,
                radius: filter.radius * 1000
            )
            
            allPlaces.append(contentsOf: places)
        }
        
        return allPlaces
    }
    
    // MARK: - Filtrer les lieux
    private func filterPlaces(_ places: [Location], userLocation: CLLocation) -> [Location] {
        return places.filter { place in
            // Vérifier la distance individuelle
            let distance = userLocation.distance(from: CLLocation(
                latitude: place.latitude, 
                longitude: place.longitude
            ))
            
            guard distance <= filter.radius * 1000 else { return false } // Convertir km en mètres
            
            // Vérifier la durée individuelle
            let estimatedDuration = getEstimatedDuration(for: place.category)
            guard estimatedDuration <= filter.availableTime else { return false }
            
            // Exclure la catégorie choisie
            if place.category == filter.excludedCategory {
                return false
            }
            
            return true
        }
    }
    
    // MARK: - Créer une aventure surprise
    private func createSurpriseAdventure(from places: [Location], userLocation: CLLocation) async -> AdventurerResult {
        var selectedLocations: [Location] = []
        var remainingTime = filter.availableTime
        var remainingDistance = filter.radius * 1000 // Convertir en mètres
        
        // Sélectionner 2-3 lieux maximum en respectant les contraintes strictes
        let maxLocations = min(3, places.count)
        
        // Trier par distance pour optimiser le parcours
        let sortedPlaces = places.sorted { place1, place2 in
            let distance1 = userLocation.distance(from: CLLocation(latitude: place1.latitude, longitude: place1.longitude))
            let distance2 = userLocation.distance(from: CLLocation(latitude: place2.latitude, longitude: place2.longitude))
            return distance1 < distance2
        }
        
        for place in sortedPlaces {
            let duration = getEstimatedDuration(for: place.category)
            let distance = userLocation.distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
            
            // Vérifier les contraintes strictes de temps et distance cumulées
            if duration <= remainingTime && 
               distance <= remainingDistance && 
               selectedLocations.count < maxLocations {
                
                selectedLocations.append(place)
                remainingTime -= duration
                remainingDistance -= distance
                
                print("✅ Lieu d'aventure ajouté: \(place.name) - Durée: \(duration/60)min, Distance: \(distance/1000)km")
            }
            
            if selectedLocations.count >= maxLocations {
                break
            }
        }
        
        let result = await createAdventureResult(locations: selectedLocations, userLocation: userLocation)
        
        // Vérifier les limites finales
        let totalTime = result.totalDuration
        let totalDistance = result.totalDistance * 1000 // Convertir en mètres
        
        print("🎲 Aventure créée - Temps: \(totalTime/60)min/\(filter.availableTime/60)min, Distance: \(totalDistance/1000)km/\(filter.radius)km")
        
        return result
    }
    
    // MARK: - Trouver le meilleur remplacement
    private func findBestReplacement(
        from places: [Location],
        existingLocations: [Location],
        remainingTime: TimeInterval,
        userLocation: CLLocation
    ) -> Location? {
        
        // Éviter les doublons
        let existingCategories = Set(existingLocations.map { $0.category })
        
        return places.first { place in
            let duration = getEstimatedDuration(for: place.category)
            return duration <= remainingTime && !existingCategories.contains(place.category)
        }
    }
    
    // MARK: - Créer le résultat d'aventure
    private func createAdventureResult(locations: [Location], userLocation: CLLocation) async -> AdventurerResult {
        let totalDuration = locations.reduce(0) { $0 + getEstimatedDuration(for: $1.category) }
        
        let totalDistance = calculateTotalDistance(locations: locations, userLocation: userLocation)
        
        let surpriseDescription = generateSurpriseDescription(locations: locations)
        
        // Créer le point de départ comme Location
        let startAddressLocation = await createStartLocation(from: userLocation)
        
        return AdventurerResult(
            locations: locations,
            startAddress: startAddressLocation,
            totalDuration: totalDuration,
            totalDistance: totalDistance,
            surpriseDescription: surpriseDescription
        )
    }
    
    // MARK: - Calculer la distance totale
    private func calculateTotalDistance(locations: [Location], userLocation: CLLocation) -> Double {
        guard !locations.isEmpty else { return 0 }
        
        var totalDistance = userLocation.distance(from: CLLocation(
            latitude: locations[0].latitude,
            longitude: locations[0].longitude
        )) / 1000
        
        for i in 0..<(locations.count - 1) {
            let location1 = CLLocation(
                latitude: locations[i].latitude,
                longitude: locations[i].longitude
            )
            let location2 = CLLocation(
                latitude: locations[i + 1].latitude,
                longitude: locations[i + 1].longitude
            )
            totalDistance += location1.distance(from: location2) / 1000
        }
        
        return totalDistance
    }
    
    // MARK: - Générer une description surprise
    private func generateSurpriseDescription(locations: [Location]) -> String {
        guard !locations.isEmpty else { return "Aucune aventure trouvée" }
        
        let categories = locations.map { $0.category.displayName }
        let uniqueCategories = Array(Set(categories))
        
        if locations.count == 1 {
            return "Une découverte unique : \(locations[0].name)"
        } else if uniqueCategories.count == 1 {
            return "Une immersion \(uniqueCategories[0].lowercased()) avec \(locations.count) lieux"
        } else {
            return "Un parcours varié : \(uniqueCategories.joined(separator: ", "))"
        }
    }
    
    // MARK: - Calculer la durée estimée (durées adaptées aux temps recommandés pour aventure)
    private func getEstimatedDuration(for category: LocationCategory) -> TimeInterval {
        switch category {
        case .restaurant:
            return 4500 // 1h15 - temps réaliste pour un repas
        case .cafe, .bar:
            return 2400 // 40min - pause café/apéro
        case .museum:
            return 5400 // 1h30 - visite approfondie
        case .culture:
            return 4500 // 1h15 - spectacle, exposition
        case .sport:
            return 3600 // 1h - activité sportive
        case .shopping:
            return 3600 // 1h - shopping tranquille
        case .nature:
            return 4500 // 1h15 - balade, détente
        case .entertainment:
            return 5400 // 1h30 - film, jeu
        case .aquarium, .zoo:
            return 7200 // 2h - visite complète
        case .historical, .religious:
            return 2700 // 45min - visite guidée
        case .adventurePark:
            return 7200 // 2h - parcours aventure
        case .iceRink, .swimmingPool:
            return 3600 // 1h - session sport
        case .climbingGym:
            return 4500 // 1h15 - escalade
        case .escapeRoom:
            return 3600 // 1h - durée standard
        case .laserTag, .paintball:
            return 4500 // 1h15 - plusieurs parties
        case .bowling:
            return 3600 // 1h - quelques parties
        case .miniGolf:
            return 2700 // 45min - parcours complet
        case .karting:
            return 2700 // 45min - sessions de course
        case .trampolinePark:
            return 3600 // 1h - session trampoline
        case .waterPark:
            return 10800 // 3h - journée détente
        }
    }
    
    // MARK: - Actions utilisateur
    func updateRadius(_ radius: Double) {
        filter.radius = radius
    }
    
    func updateAvailableTime(_ time: TimeInterval) {
        filter.availableTime = time
    }
    
    func updateExcludedCategory(_ category: LocationCategory?) {
        filter.excludedCategory = category
    }
    
    func clearResult() {
        result = nil
        errorMessage = nil
        skippedLocationIndex = nil
    }
    
    // MARK: - Créer le point de départ comme Location
    private func createStartLocation(from userLocation: CLLocation) async -> Location? {
        do {
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.reverseGeocodeLocation(userLocation)
            
            guard let placemark = placemarks.first else {
                print("❌ Impossible de géocoder la position de départ")
                return nil
            }
            
            // Utiliser l'adresse saisie par l'utilisateur si disponible, sinon l'adresse géocodée
            let formattedAddress = [placemark.thoroughfare, placemark.locality, placemark.country]
                .compactMap { $0 }
                .joined(separator: ", ")
            let addressToUse = !filter.address.isEmpty ? filter.address : (!formattedAddress.isEmpty ? formattedAddress : "Point de départ")
            let nameToUse = !filter.address.isEmpty ? filter.address : (placemark.name ?? "Point de départ")
            
            let startLocation = Location(
                id: "start_location",
                name: nameToUse,
                address: addressToUse,
                latitude: userLocation.coordinate.latitude,
                longitude: userLocation.coordinate.longitude,
                category: .cafe,
                description: "Point de départ de votre aventure",
                imageURL: nil,
                rating: nil,
                openingHours: nil,
                recommendedDuration: 0,
                visitTips: nil
            )
            
            print("🏠 Point de départ créé: \(nameToUse) à \(addressToUse)")
            return startLocation
            
        } catch {
            print("❌ Erreur lors du géocodage du point de départ: \(error)")
            // Créer un point de départ simple en cas d'erreur
            let fallbackName = !filter.address.isEmpty ? filter.address : "Point de départ"
            return Location(
                id: "start_location",
                name: fallbackName,
                address: fallbackName,
                latitude: userLocation.coordinate.latitude,
                longitude: userLocation.coordinate.longitude,
                category: .cafe,
                description: "Point de départ de votre aventure",
                imageURL: nil,
                rating: nil,
                openingHours: nil,
                recommendedDuration: 0,
                visitTips: nil
            )
        }
    }
}

// MARK: - Erreurs
enum AdventurerError: LocalizedError {
    case geocodingFailed
    case noLocationFound
    case apiError
    
    var errorDescription: String? {
        switch self {
        case .geocodingFailed:
            return "Impossible de localiser cette adresse"
        case .noLocationFound:
            return "Aucune aventure trouvée dans cette zone"
        case .apiError:
            return "Erreur lors de la génération"
        }
    }
} 