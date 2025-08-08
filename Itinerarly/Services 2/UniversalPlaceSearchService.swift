import Foundation
import CoreLocation
import Combine
import MapKit

// MARK: - Service de Recherche Universel (MapKit + Fallback)
class UniversalPlaceSearchService: ObservableObject {
    @Published var isSearching = false
    @Published var searchResults: [Location] = []
    
    // Services
    private let placeSearchService = PlaceSearchService()
    private let comprehensiveService = ComprehensivePlaceSearchService()
    
    // MARK: - Recherche universelle pour toutes les catégories
    func searchPlaces(
        for categories: [LocationCategory],
        near location: CLLocation,
        explorationRadius: Double, // Rayon d'exploration en km
        maxTime: TimeInterval, // Temps disponible en secondes
        completion: @escaping ([Location]) -> Void
    ) {
        print("🌍 UniversalPlaceSearch - Recherche mondiale pour \(categories.count) catégories")
        print("📍 Localisation: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("🎯 Rayon d'exploration: \(explorationRadius) km")
        print("⏰ Temps disponible: \(maxTime / 3600) heures")
        
        isSearching = true
        
        // Convertir le rayon d'exploration en mètres
        _ = explorationRadius * 1000
        
        // Utiliser directement les services MapKit
        print("🔍 Utilisation des services MapKit")
        performMapKitSearch(
            categories: categories,
            location: location,
            explorationRadius: explorationRadius,
            maxTime: maxTime,
            completion: completion
        )
    }
    
    // MARK: - Recherche avec MapKit
    private func performMapKitSearch(
        categories: [LocationCategory],
        location: CLLocation,
        explorationRadius: Double,
        maxTime: TimeInterval,
        completion: @escaping ([Location]) -> Void
    ) {
        print("🗺️ MapKit - Recherche avec services locaux")
        print("🎯 Rayon d'exploration: \(explorationRadius) km")
        print("⏰ Temps disponible: \(maxTime / 3600) heures")
        
        var allPlaces: [Location] = []
        let group = DispatchGroup()
        
        // Convertir le rayon d'exploration en mètres
        let radiusInMeters = explorationRadius * 1000
        
        // Recherche avec PlaceSearchService
        for category in categories {
            group.enter()
            
            placeSearchService.searchPlaces(
                category: category,
                near: location.coordinate,
                radius: radiusInMeters * 1.5 // Légèrement plus large pour avoir du choix
            ) { places in
                print("📍 PlaceSearchService - \(places.count) lieux pour \(category.displayName)")
                allPlaces.append(contentsOf: places)
                group.leave()
            }
        }
        
        // Recherche avec ComprehensivePlaceSearchService
        group.enter()
        comprehensiveService.searchPlaces(
            for: categories,
            near: location,
            maxDistance: explorationRadius
        ) { places in
            print("📍 ComprehensiveService - \(places.count) lieux trouvés")
            allPlaces.append(contentsOf: places)
            group.leave()
        }
        
        group.notify(queue: .main) {
            print("✅ MapKit - Total: \(allPlaces.count) lieux trouvés")
            
            // Optimiser les lieux selon le temps disponible
            let optimizedPlaces = self.optimizePlacesForTime(
                places: allPlaces,
                maxTime: maxTime,
                startLocation: location.coordinate
            )
            
            self.isSearching = false
            self.searchResults = optimizedPlaces
            completion(optimizedPlaces)
        }
    }
    
    // MARK: - Recherche spécifique pour une catégorie
    func searchPlacesForCategory(
        category: LocationCategory,
        near location: CLLocation,
        radius: Double = 5000,
        completion: @escaping ([Location]) -> Void
    ) {
        print("🎯 Recherche spécifique pour \(category.displayName)")
        
        // Requêtes spécialisées selon la catégorie
        let queries = getSpecializedQueries(for: category)
        var allPlaces: [Location] = []
        let group = DispatchGroup()
        
        for query in queries {
            group.enter()
            
            // Recherche MapKit directe avec requête spécialisée
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: radius * 3,
                longitudinalMeters: radius * 3
            )
            request.resultTypes = [.pointOfInterest, .address]
            
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Erreur recherche '\(query)': \(error.localizedDescription)")
                    } else {
                        let mapItems = response?.mapItems ?? []
                        print("🔍 Requête '\(query)': \(mapItems.count) résultats")
                        
                        let locations = mapItems.compactMap { mapItem -> Location? in
                            guard let name = mapItem.name, !name.isEmpty else { return nil }
                            
                            return Location(
                                id: UUID().uuidString,
                                name: name,
                                address: mapItem.placemark.formattedAddress,
                                latitude: mapItem.placemark.coordinate.latitude,
                                longitude: mapItem.placemark.coordinate.longitude,
                                category: category,
                                description: mapItem.pointOfInterestCategory?.rawValue,
                                imageURL: nil,
                                rating: Double.random(in: 3.5...4.5),
                                openingHours: self.generateOpeningHours(for: category),
                                recommendedDuration: self.getRecommendedDuration(for: category),
                                visitTips: self.generateTips(for: category)
                            )
                        }
                        
                        allPlaces.append(contentsOf: locations)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            let uniquePlaces = self.removeDuplicates(from: allPlaces)
            let limitedPlaces = Array(uniquePlaces.prefix(15))
            print("✅ Recherche spécifique: \(limitedPlaces.count) lieux pour \(category.displayName)")
            completion(limitedPlaces)
        }
    }
    
    // MARK: - Requêtes spécialisées par catégorie
    private func getSpecializedQueries(for category: LocationCategory) -> [String] {
        switch category {
        case .swimmingPool:
            return ["swimming pool", "piscine", "natation", "centre aquatique", "complexe nautique"]
        case .climbingGym:
            return ["climbing gym", "escalade", "mur d'escalade", "salle d'escalade", "centre d'escalade"]
        case .iceRink:
            return ["ice rink", "patinoire", "skating rink", "centre de glace"]
        case .bowling:
            return ["bowling", "bowling alley", "quilles", "centre de bowling"]
        case .miniGolf:
            return ["mini golf", "golf miniature", "parcours de golf mini"]
        case .escapeRoom:
            return ["escape room", "escape game", "salle d'énigmes", "jeu d'évasion"]
        case .laserTag:
            return ["laser tag", "laser game", "combat laser", "arène laser"]
        case .paintball:
            return ["paintball", "terrain de paintball", "centre de paintball"]
        case .karting:
            return ["karting", "go kart", "circuit de kart", "centre de karting"]
        case .trampolinePark:
            return ["trampoline park", "jump park", "centre de trampoline", "parc trampoline"]
        case .waterPark:
            return ["water park", "parc aquatique", "centre aquatique", "parc d'eau"]
        case .adventurePark:
            return ["adventure park", "parc d'aventure", "accrobranche", "parcours aventure"]
        case .zoo:
            return ["zoo", "parc animalier", "jardin zoologique", "réserve animalière"]
        case .aquarium:
            return ["aquarium", "centre marin", "aquarium public", "parc marin"]
        case .restaurant:
            return ["restaurant", "bistro", "brasserie", "gastronomie"]
        case .cafe:
            return ["cafe", "coffee shop", "salon de thé", "café"]
        case .bar:
            return ["bar", "pub", "cocktail bar", "wine bar"]
        case .museum:
            return ["museum", "musée", "exposition", "galerie d'art"]
        case .shopping:
            return ["shopping mall", "centre commercial", "boutique", "magasin"]
        case .sport:
            return ["gym", "fitness center", "sport center", "centre sportif"]
        case .nature:
            return ["park", "garden", "parc", "jardin public"]
        case .entertainment:
            return ["cinema", "theater", "cinéma", "théâtre"]
        case .historical:
            return ["historical landmark", "monument", "site historique", "patrimoine"]
        case .culture:
            return ["art gallery", "cultural center", "centre culturel", "galerie d'art"]
        default:
            return ["point of interest", "lieu d'intérêt", "activité"]
        }
    }
    
    // MARK: - Optimisation selon le temps disponible
    private func optimizePlacesForTime(
        places: [Location],
        maxTime: TimeInterval,
        startLocation: CLLocationCoordinate2D
    ) -> [Location] {
        print("🎯 Optimisation pour \(maxTime / 3600) heures disponibles")
        
        var selectedPlaces: [Location] = []
        var currentTime: TimeInterval = 0
        
        // Trier les lieux par proximité et durée recommandée
        let sortedPlaces = places.sorted { place1, place2 in
            let startCLLocation = CLLocation(latitude: startLocation.latitude, longitude: startLocation.longitude)
            let place1Location = CLLocation(latitude: place1.coordinate.latitude, longitude: place1.coordinate.longitude)
            let place2Location = CLLocation(latitude: place2.coordinate.latitude, longitude: place2.coordinate.longitude)
            
            let distance1 = startCLLocation.distance(from: place1Location)
            let distance2 = startCLLocation.distance(from: place2Location)
            
            // Priorité: proximité puis durée
            if abs(distance1 - distance2) < 1000 { // Si distances similaires
                return (place1.recommendedDuration ?? 3600) < (place2.recommendedDuration ?? 3600)
            }
            return distance1 < distance2
        }
        
        // Sélectionner les lieux qui tiennent dans le temps disponible
        for place in sortedPlaces {
            let placeDuration = place.recommendedDuration ?? 3600 // 1h par défaut
            let travelTime = calculateTravelTime(
                from: selectedPlaces.last,
                to: place,
                userLocation: startLocation
            )
            
            let totalTimeForPlace = placeDuration + travelTime
            
            if currentTime + totalTimeForPlace <= maxTime {
                selectedPlaces.append(place)
                currentTime += totalTimeForPlace
                print("✅ Ajouté: \(place.name) (\(placeDuration / 3600)h + \(travelTime / 3600)h trajet)")
            } else {
                print("⏰ Temps dépassé pour: \(place.name)")
                break
            }
        }
        
        print("🎯 Sélection finalisée: \(selectedPlaces.count) lieux pour \(currentTime / 3600) heures")
        return selectedPlaces
    }
    
    private func calculateTravelTime(
        from startPlace: Location?,
        to endPlace: Location,
        userLocation: CLLocationCoordinate2D
    ) -> TimeInterval {
        let startCoord = startPlace?.coordinate ?? userLocation
        let endCoord = endPlace.coordinate
        
        let distance = CLLocation(latitude: startCoord.latitude, longitude: startCoord.longitude)
            .distance(from: CLLocation(latitude: endCoord.latitude, longitude: endCoord.longitude))
        
        // Vitesse moyenne: 4 km/h à pied, 15 km/h à vélo, 25 km/h en voiture
        let averageSpeed = 15.0 // km/h (moyenne vélo/voiture)
        let timeInHours = (distance / 1000.0) / averageSpeed
        
        return timeInHours * 3600 // Convertir en secondes
    }
    
    private func calculateTotalTime(places: [Location]) -> Double {
        let totalDuration = places.reduce(0.0) { total, place in
            total + (place.recommendedDuration ?? 3600)
        }
        return totalDuration / 3600 // Retourner en heures
    }
    
    // MARK: - Utilitaires
    private func removeDuplicates(from places: [Location]) -> [Location] {
        var seen = Set<String>()
        return places.filter { place in
            let key = "\(place.latitude),\(place.longitude)"
            if seen.contains(key) {
                return false
            } else {
                seen.insert(key)
                return true
            }
        }
    }
    
    private func generateOpeningHours(for category: LocationCategory) -> String {
        switch category {
        case .restaurant: return "12:00-22:00"
        case .cafe: return "07:00-19:00"
        case .bar: return "17:00-02:00"
        case .museum: return "10:00-18:00"
        case .shopping: return "09:00-20:00"
        case .sport: return "06:00-22:00"
        case .nature: return "24h/24"
        case .entertainment: return "14:00-23:00"
        case .swimmingPool: return "06:00-22:00"
        case .climbingGym: return "08:00-22:00"
        case .iceRink: return "10:00-21:00"
        case .bowling: return "12:00-23:00"
        case .miniGolf: return "10:00-20:00"
        case .escapeRoom: return "10:00-22:00"
        case .laserTag: return "14:00-23:00"
        case .paintball: return "09:00-18:00"
        case .karting: return "10:00-20:00"
        case .trampolinePark: return "10:00-21:00"
        case .waterPark: return "10:00-19:00"
        case .adventurePark: return "09:00-18:00"
        case .zoo: return "09:00-18:00"
        case .aquarium: return "10:00-18:00"
        default: return "09:00-18:00"
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
    
    // MARK: - Conversion avec Classification Améliorée
    private func convertMapItemToLocationWithEnhancedClassification(_ mapItem: MKMapItem, originalCategory: LocationCategory) -> Location {
        // Utiliser la classification améliorée
        let enhancedClassifier = EnhancedAPIClassifier()
        let finalCategory = enhancedClassifier.quickClassify(mapItem)
        
        return Location(
            id: UUID().uuidString,
            name: mapItem.name ?? "Lieu sans nom",
            address: mapItem.placemark.formattedAddress,
            latitude: mapItem.placemark.coordinate.latitude,
            longitude: mapItem.placemark.coordinate.longitude,
            category: finalCategory,
            description: generateDescription(for: finalCategory),
            imageURL: nil,
            rating: Double.random(in: 3.5...4.8),
            openingHours: generateOpeningHours(for: finalCategory),
            recommendedDuration: getRecommendedDuration(for: finalCategory),
            visitTips: generateTips(for: finalCategory)
        )
    }
    
    private func generateDescription(for category: LocationCategory) -> String {
        switch category {
        case .restaurant: return "Découvrez une expérience culinaire exceptionnelle"
        case .cafe: return "Parfait pour une pause détente et conviviale"
        case .bar: return "Ambiance conviviale pour vos soirées"
        case .museum: return "Plongez dans l'histoire et la culture"
        case .shopping: return "Trouvez des trésors uniques et variés"
        case .sport: return "Bougez et restez actif dans un environnement moderne"
        case .nature: return "Reconnectez-vous avec la nature et la tranquillité"
        case .entertainment: return "Divertissements et spectacles pour tous"
        case .historical: return "Découvrez le patrimoine et l'histoire locale"
        case .culture: return "Enrichissez votre esprit avec l'art et la culture"
        case .swimmingPool: return "Profitez d'activités aquatiques dans un cadre moderne"
        case .climbingGym: return "Défiez-vous sur des murs d'escalade variés"
        case .iceRink: return "Glissez sur la glace dans une ambiance conviviale"
        case .bowling: return "Amusez-vous avec des parties de bowling entre amis"
        case .miniGolf: return "Parcours de mini-golf pour toute la famille"
        case .escapeRoom: return "Résolvez des énigmes passionnantes en équipe"
        case .laserTag: return "Combat laser dans une arène futuriste"
        case .paintball: return "Stratégie et adrénaline sur des terrains variés"
        case .karting: return "Courses de karting pour tous les niveaux"
        case .trampolinePark: return "Rebondissez dans un parc de trampolines"
        case .waterPark: return "Attractions aquatiques pour toute la famille"
        case .adventurePark: return "Parcours d'aventure dans la nature"
        case .zoo: return "Découvrez des animaux fascinants du monde entier"
        case .aquarium: return "Explorez les merveilles du monde marin"
        default: return "Une expérience unique vous attend"
        }
    }
    

} 