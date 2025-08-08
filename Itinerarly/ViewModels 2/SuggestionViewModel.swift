import Foundation
import CoreLocation
import Combine
import SwiftUI

// MARK: - Modèles pour le Mode Suggestion
struct SuggestionFilter {
    var address: String = ""
    var categories: Set<LocationCategory> = []
    var maxRadius: Double = 5.0 // km
    var availableTime: TimeInterval = 3600 // 1 heure par défaut
    var transportMode: TransportMode = .walking
}

struct SuggestionResult {
    let location: Location
    let estimatedDuration: TimeInterval
    let distance: Double
    let interestScore: Double
    let description: String
}

@MainActor
class SuggestionViewModel: ObservableObject {
    @Published var filter = SuggestionFilter()
    @Published var suggestions: [SuggestionResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCategories: Set<LocationCategory> = []
    @Published var shouldShowItinerary = false
    @Published var userLocation: CLLocation?
    @Published var generatedTrip: SuggestionTrip?
    
    private var cancellables = Set<AnyCancellable>()
    let locationManager = LocationManager()
    
    // MARK: - Catégories disponibles
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
        10800,  // 3h
        14400   // 4h
    ]
    
    // MARK: - Recherche de suggestions
    func findSuggestions() async {
        isLoading = true
        errorMessage = nil
        suggestions = []
        shouldShowItinerary = false
        
        do {
            // 1. Obtenir la localisation
            let userLocation = try await getUserLocation()
            self.userLocation = userLocation
            
            print("📍 Localisation utilisée pour la recherche: \(userLocation.coordinate)")
            print("🗺️ Adresse du filtre: '\(filter.address)'")
            
            // 2. Rechercher des lieux avec l'API
            let places = try await searchPlaces(near: userLocation)
            
            // 3. Filtrer et trier les résultats
            let filteredPlaces = filterPlaces(places, userLocation: userLocation)
            
            // 4. Convertir en suggestions
            suggestions = createSuggestions(from: filteredPlaces, userLocation: userLocation)
            
            print("✅ \(suggestions.count) suggestions trouvées")
            
            // 5. Créer le voyage de suggestions et afficher l'itinéraire
            if !suggestions.isEmpty {
                print("🎉 Création de l'itinéraire avec \(suggestions.count) suggestions")
                
                // Calculer le temps total cumulé (temps de visite + temps de trajet)
                let totalVisitTime = suggestions.reduce(0) { $0 + $1.estimatedDuration }
                let travelTime = calculateTravelTime(from: userLocation, suggestions: suggestions, transportMode: filter.transportMode)
                let totalDuration = totalVisitTime + travelTime
                
                // Calculer la distance totale du trajet complet
                let totalDistance = calculateTotalDistance(from: userLocation, suggestions: suggestions)
                
                print("⏱️ Temps total calculé:")
                print("   - Temps de visite: \(totalVisitTime/3600) h")
                print("   - Temps de trajet: \(travelTime/3600) h")
                print("   - Temps total: \(totalDuration/3600) h")
                print("🗺️ Distance totale: \(String(format: "%.2f", totalDistance)) km")
                
                // Créer le point de départ comme Location
                let startAddressLocation = await createStartLocation(from: userLocation)
                
                // Créer le voyage
                generatedTrip = SuggestionTrip(
                    locations: suggestions.map { $0.location },
                    startLocation: userLocation,
                    startAddress: startAddressLocation,
                    estimatedDuration: totalDuration,
                    totalDistance: totalDistance,
                    transportMode: filter.transportMode
                )
                
                shouldShowItinerary = true
            } else {
                print("❌ Aucune suggestion trouvée")
            }
            
        } catch {
            errorMessage = "Erreur lors de la recherche : \(error.localizedDescription)"
            print("❌ Erreur suggestion: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Obtenir la localisation utilisateur
    private func getUserLocation() async throws -> CLLocation {
        let trimmedAddress = filter.address.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔍 Analyse de l'adresse:")
        print("   - Adresse brute: '\(filter.address)'")
        print("   - Adresse nettoyée: '\(trimmedAddress)'")
        print("   - Longueur: \(trimmedAddress.count)")
        print("   - Est vide?: \(filter.address.isEmpty)")
        
        if !filter.address.isEmpty && trimmedAddress.count > 2 {
            // Utiliser l'adresse saisie en priorité
            print("🏠 ✅ Utilisation de l'adresse: '\(trimmedAddress)'")
            
            // Validation basique de l'adresse
            if isValidAddress(trimmedAddress) {
                return try await geocodeAddressWithRetry(trimmedAddress)
            } else {
                print("⚠️ Adresse potentiellement invalide, tentative quand même...")
                return try await geocodeAddressWithRetry(trimmedAddress)
            }
        } else {
            // Utiliser la géolocalisation actuelle en fallback
            print("📍 ⚠️ Utilisation de la géolocalisation actuelle (adresse insuffisante)")
            return try await withCheckedThrowingContinuation { continuation in
                locationManager.requestLocation()
                
                // Attendre la réponse avec un timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                    if let location = self?.locationManager.location {
                        continuation.resume(returning: location)
                    } else {
                        continuation.resume(throwing: SuggestionError.noLocationFound)
                    }
                }
            }
        }
    }
    
    // MARK: - Validation d'adresse
    private func isValidAddress(_ address: String) -> Bool {
        let minLength = 3
        let hasLetters = address.rangeOfCharacter(from: .letters) != nil
        let hasValidChars = address.rangeOfCharacter(from: .alphanumerics.union(.whitespaces).union(.punctuationCharacters)) != nil
        
        return address.count >= minLength && hasLetters && hasValidChars
    }
    
    // MARK: - Geocoder avec retry
    private func geocodeAddressWithRetry(_ address: String, attempt: Int = 1, maxAttempts: Int = 2) async throws -> CLLocation {
        do {
            return try await geocodeAddress(address)
        } catch {
            print("❌ Tentative \(attempt) échouée pour '\(address)': \(error.localizedDescription)")
            
            if attempt < maxAttempts {
                print("🔄 Retry dans 1 seconde...")
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
                return try await geocodeAddressWithRetry(address, attempt: attempt + 1, maxAttempts: maxAttempts)
            } else {
                print("❌ Échec définitif après \(maxAttempts) tentatives")
                throw error
            }
        }
    }
    
    // MARK: - Geocoder une adresse
    private func geocodeAddress(_ address: String) async throws -> CLLocation {
        print("🏠 Geocoding de l'adresse: '\(address)'")
        
        // Nettoyage et validation de l'adresse
        let cleanAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanAddress.isEmpty else {
            print("❌ Adresse vide après nettoyage")
            throw SuggestionError.geocodingFailed
        }
        
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(cleanAddress)
            
            guard let placemark = placemarks.first,
                  let location = placemark.location else {
                print("❌ Aucun résultat de geocoding pour: '\(cleanAddress)'")
                throw SuggestionError.geocodingFailed
            }
            
            print("✅ Geocoding réussi: \(location.coordinate)")
            if let locality = placemark.locality, let country = placemark.country {
                print("📍 Ville trouvée: \(locality), \(country)")
            }
            
            return location
            
        } catch let error as CLError {
            print("❌ Erreur CLGeocoder pour '\(cleanAddress)': \(error.localizedDescription)")
            print("   Code d'erreur: \(error.code.rawValue)")
            
            // Gestion spécifique des erreurs CoreLocation
            switch error.code {
            case .geocodeFoundNoResult:
                throw SuggestionError.geocodingFailed
            case .geocodeCanceled:
                throw SuggestionError.geocodingFailed
            case .network:
                throw SuggestionError.networkError
            case .locationUnknown:
                throw SuggestionError.geocodingFailed
            default:
                throw SuggestionError.geocodingFailed
            }
        } catch {
            print("❌ Erreur générale de geocoding: \(error.localizedDescription)")
            throw SuggestionError.geocodingFailed
        }
    }
    
    // MARK: - Rechercher des lieux avec l'API
    private func searchPlaces(near location: CLLocation) async throws -> [Location] {
        print("🔍 Recherche de lieux pour \(filter.categories.count) catégories")
        print("📍 Localisation: \(location.coordinate)")
        print("📏 Rayon: \(filter.maxRadius) km")
        
        let searchService = OpenTripMapService()
        
        let places = try await searchService.searchPlaces(
            categories: Array(filter.categories),
            near: location,
            radius: filter.maxRadius * 1000 // Convertir en mètres
        )
        
        print("✅ \(places.count) lieux trouvés par l'API")
        return places
    }
    
    // MARK: - Filtrer les lieux
    private func filterPlaces(_ places: [Location], userLocation: CLLocation) -> [Location] {
        print("🔍 Début du filtrage de \(places.count) lieux")
        print("📏 Rayon max: \(filter.maxRadius) km")
        print("⏰ Temps disponible: \(filter.availableTime/3600) heures")
        
        let filteredPlaces = places.filter { place in
            // Vérifier la distance
            let distance = userLocation.distance(from: CLLocation(
                latitude: place.latitude, 
                longitude: place.longitude
            )) / 1000 // Convertir en km
            
            if distance > filter.maxRadius {
                print("❌ \(place.name) rejeté - distance: \(String(format: "%.1f", distance)) km > \(filter.maxRadius) km")
                return false
            }
            
            // Vérifier la durée - être plus tolérant
            let estimatedDuration = getEstimatedDuration(for: place.category)
            // Permettre des activités jusqu'à 1.5x le temps disponible (on peut adapter la durée)
            if estimatedDuration > filter.availableTime * 1.5 {
                print("❌ \(place.name) rejeté - durée: \(estimatedDuration/3600)h > \(filter.availableTime * 1.5/3600)h")
                return false
            }
            
            print("✅ \(place.name) accepté - distance: \(String(format: "%.1f", distance)) km, durée: \(estimatedDuration/3600)h")
            return true
        }
        
        print("🎯 \(filteredPlaces.count) lieux filtrés sur \(places.count)")
        return filteredPlaces
    }
    
    // MARK: - Créer les suggestions
    private func createSuggestions(from places: [Location], userLocation: CLLocation) -> [SuggestionResult] {
        print("🎯 Création de suggestions à partir de \(places.count) lieux filtrés")
        print("🎯 Catégories sélectionnées: \(selectedCategories)")
        
        guard !places.isEmpty else {
            print("❌ Aucun lieu filtré disponible pour créer des suggestions")
            return []
        }
        
        // 1. Grouper les lieux par catégorie
        let placesByCategory = Dictionary(grouping: places) { $0.category }
        print("📊 Lieux groupés par catégorie:")
        for (category, categoryPlaces) in placesByCategory {
            print("   - \(category.displayName): \(categoryPlaces.count) lieux")
        }
        
        var finalSuggestions: [SuggestionResult] = []
        var remainingTime = filter.availableTime
        var remainingDistance = filter.maxRadius * 1000 // Convertir en mètres
        var usedCategories: Set<LocationCategory> = []
        
        // 2. S'assurer d'avoir EXACTEMENT un lieu par catégorie sélectionnée
        for category in selectedCategories {
            guard let categoryPlaces = placesByCategory[category], !categoryPlaces.isEmpty else {
                print("⚠️ Aucun lieu trouvé pour la catégorie: \(category.displayName)")
                continue
            }
            
            // Prendre le meilleur lieu de cette catégorie qui respecte les contraintes
            let sortedPlaces = categoryPlaces.sorted { place1, place2 in
                let distance1 = userLocation.distance(from: CLLocation(latitude: place1.latitude, longitude: place1.longitude))
                let distance2 = userLocation.distance(from: CLLocation(latitude: place2.latitude, longitude: place2.longitude))
                return distance1 < distance2
            }
            
            // Trouver le premier lieu qui respecte les contraintes de temps et distance
            if let bestPlace = sortedPlaces.first(where: { place in
                let estimatedDuration = getEstimatedDuration(for: place.category)
                let distance = userLocation.distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
                return estimatedDuration <= remainingTime && distance <= remainingDistance
            }) {
                let distance = userLocation.distance(from: CLLocation(
                    latitude: bestPlace.latitude, 
                    longitude: bestPlace.longitude
                ))
                let estimatedDuration = getEstimatedDuration(for: bestPlace.category)
                
                let interestScore = calculateInterestScore(for: bestPlace, distance: distance / 1000)
                
                let suggestion = SuggestionResult(
                    location: bestPlace,
                    estimatedDuration: estimatedDuration,
                    distance: distance / 1000,
                    interestScore: interestScore,
                    description: generateDescription(for: bestPlace, duration: estimatedDuration)
                )
                
                finalSuggestions.append(suggestion)
                remainingTime -= estimatedDuration
                remainingDistance -= distance
                usedCategories.insert(category)
                
                print("✅ Ajouté pour \(category.displayName): \(bestPlace.name) - Durée: \(estimatedDuration/60)min, Distance: \(distance/1000)km")
            } else {
                print("⚠️ Aucun lieu trouvé pour \(category.displayName) respectant les contraintes de temps (\(remainingTime/60)min) et distance (\(remainingDistance/1000)km)")
            }
        }
        
        // Vérification finale: s'assurer qu'on a une suggestion par catégorie sélectionnée
        if finalSuggestions.count < selectedCategories.count {
            print("⚠️ Seulement \(finalSuggestions.count) suggestions trouvées sur \(selectedCategories.count) catégories demandées")
            print("💡 Conseil: Augmentez le rayon de recherche ou le temps disponible")
        }
        
        // 3. Ne PAS compléter avec d'autres lieux - respecter exactement les catégories sélectionnées
        
        // 4. Trier par score d'intérêt final
        finalSuggestions.sort { $0.interestScore > $1.interestScore }
        
        let totalTime = finalSuggestions.reduce(0) { $0 + $1.estimatedDuration }
        let totalDistance = finalSuggestions.reduce(0) { $0 + $1.distance }
        
        print("🎉 \(finalSuggestions.count) suggestions finales créées")
        print("⏱️ Temps total: \(totalTime/60)min sur \(filter.availableTime/60)min disponible")
        print("📏 Distance totale: \(String(format: "%.1f", totalDistance))km sur \(filter.maxRadius)km disponible")
        
        return finalSuggestions
    }
    
    // MARK: - Calculer la durée estimée (durées adaptées aux temps recommandés)
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
    
    // MARK: - Calculer le score d'intérêt
    private func calculateInterestScore(for place: Location, distance: Double) -> Double {
        var score = 100.0
        
        // Bonus pour les lieux avec une bonne note
        if let rating = place.rating {
            score += rating * 10
        }
        
        // Malus pour la distance
        score -= distance * 5
        
        // Bonus pour les lieux originaux
        if let description = place.description,
           description.contains("unique") || description.contains("original") {
            score += 20
        }
        
        return max(0, score)
    }
    
    // MARK: - Générer une description
    private func generateDescription(for place: Location, duration: TimeInterval) -> String {
        let durationText = formatDuration(duration)
        let distanceText = String(format: "%.1f km", 0) // Distance calculée séparément
        
        return "\(place.name) • \(durationText) • \(distanceText)"
    }
    
    // MARK: - Formater la durée
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes > 0 ? " \(minutes)min" : "")"
        } else {
            return "\(minutes)min"
        }
    }
    
    // MARK: - Actions utilisateur
    func toggleCategory(_ category: LocationCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
        filter.categories = selectedCategories
        print("📝 Catégories sélectionnées: \(selectedCategories.count) - \(selectedCategories)")
    }
    
    func updateMaxRadius(_ radius: Double) {
        filter.maxRadius = radius
    }
    
    func updateAvailableTime(_ time: TimeInterval) {
        filter.availableTime = time
    }
    
    func updateTransportMode(_ mode: TransportMode) {
        filter.transportMode = mode
    }
    
    func clearSuggestions() {
        suggestions = []
        errorMessage = nil
        generatedTrip = nil
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
                description: "Point de départ de votre itinéraire",
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
                description: "Point de départ de votre itinéraire",
                imageURL: nil,
                rating: nil,
                openingHours: nil,
                recommendedDuration: 0,
                visitTips: nil
            )
        }
    }
    
    // MARK: - Calcul de distance totale du trajet
    private func calculateTotalDistance(from startLocation: CLLocation, suggestions: [SuggestionResult]) -> Double {
        guard !suggestions.isEmpty else { return 0 }
        
        print("🗺️ Calcul de la distance totale du trajet:")
        print("   Point de départ: \(startLocation.coordinate)")
        
        var totalDistance: Double = 0
        var currentLocation = startLocation
        
        // Parcourir tous les lieux dans l'ordre pour calculer la distance du trajet complet
        for (index, suggestion) in suggestions.enumerated() {
            let suggestionLocation = CLLocation(
                latitude: suggestion.location.latitude,
                longitude: suggestion.location.longitude
            )
            
            let segmentDistance = currentLocation.distance(from: suggestionLocation) / 1000 // en km
            totalDistance += segmentDistance
            
            let fromName = index == 0 ? "Point de départ" : suggestions[index - 1].location.name
            print("   Segment \(index + 1): \(fromName) → \(suggestion.location.name): \(String(format: "%.2f", segmentDistance)) km")
            
            currentLocation = suggestionLocation
        }
        
        print("   🏁 Distance totale du trajet: \(String(format: "%.2f", totalDistance)) km")
        return totalDistance
    }
    
    // MARK: - Calcul du temps de trajet
    private func calculateTravelTime(from startLocation: CLLocation, suggestions: [SuggestionResult], transportMode: TransportMode) -> TimeInterval {
        guard !suggestions.isEmpty else { return 0 }
        
        let totalDistance = calculateTotalDistance(from: startLocation, suggestions: suggestions) * 1000 // en mètres
        
        // Vitesses moyennes selon le mode de transport
        let speedInMetersPerSecond: Double
        switch transportMode {
        case .walking:
            speedInMetersPerSecond = 5000.0 / 3600.0 // 5 km/h
        case .cycling:
            speedInMetersPerSecond = 15000.0 / 3600.0 // 15 km/h
        case .driving:
            speedInMetersPerSecond = 30000.0 / 3600.0 // 30 km/h (en ville)
        case .publicTransport:
            speedInMetersPerSecond = 20000.0 / 3600.0 // 20 km/h (transport public)
        }
        
        let travelTime = totalDistance / speedInMetersPerSecond
        
        print("🚶 Temps de trajet calculé:")
        print("   Mode: \(transportMode)")
        print("   Distance: \(String(format: "%.2f", totalDistance/1000)) km")
        print("   Vitesse: \(String(format: "%.1f", speedInMetersPerSecond * 3.6)) km/h")
        print("   Temps: \(String(format: "%.1f", travelTime/60)) min")
        
        return travelTime
    }
}

// MARK: - Modèle pour les résultats de suggestions
struct SuggestionTrip {
    let locations: [Location] // Seulement les suggestions (sans le point de départ)
    let startLocation: CLLocation
    let startAddress: Location? // Le point de départ comme Location
    let estimatedDuration: TimeInterval
    let totalDistance: Double
    let transportMode: TransportMode
    
    var optimizedRoute: [Location] {
        // Inclure le point de départ au début de la route
        if let startAddress = startAddress {
            return [startAddress] + locations
        }
        return locations
    }
}

// MARK: - Erreurs
enum SuggestionError: LocalizedError {
    case geocodingFailed
    case noLocationFound
    case apiError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .geocodingFailed:
            return "Impossible de localiser cette adresse. Vérifiez votre saisie."
        case .noLocationFound:
            return "Aucun lieu trouvé dans cette zone"
        case .apiError:
            return "Erreur lors de la recherche"
        case .networkError:
            return "Problème de connexion. Vérifiez votre connexion internet."
        }
    }
} 