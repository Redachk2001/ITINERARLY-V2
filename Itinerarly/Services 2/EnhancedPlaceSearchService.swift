import Foundation
import CoreLocation
import MapKit

class EnhancedPlaceSearchService: ObservableObject {
    @Published var isSearching = false
    @Published var searchResults: [Location] = []
    
    private let placeSearchService = PlaceSearchService()
    private let comprehensiveService = ComprehensivePlaceSearchService()
    
    // MARK: - Recherche complète pour toutes les catégories
    func searchPlaces(
        for categories: [LocationCategory],
        near location: CLLocation,
        radius: Double = 5000,
        completion: @escaping ([Location]) -> Void
    ) {
        print("🔍 EnhancedPlaceSearchService - Recherche pour \(categories.count) catégories")
        isSearching = true
        
        var allPlaces: [Location] = []
        let group = DispatchGroup()
        
        // 1. Recherche Apple Maps améliorée
        group.enter()
        searchWithEnhancedAppleMaps(for: categories, near: location, radius: radius) { places in
            allPlaces.append(contentsOf: places)
            print("🍎 Apple Maps Enhanced: \(places.count) lieux trouvés")
            group.leave()
        }
        
        // 2. Base de données locale enrichie
        group.enter()
        comprehensiveService.searchPlaces(for: categories, near: location, maxDistance: radius) { places in
            allPlaces.append(contentsOf: places)
            print("📚 Base locale enrichie: \(places.count) lieux trouvés")
            group.leave()
        }
        
        // 3. Recherche par termes spécifiques
        group.enter()
        searchWithSpecificTerms(for: categories, near: location, radius: radius) { places in
            allPlaces.append(contentsOf: places)
            print("🎯 Recherche spécifique: \(places.count) lieux trouvés")
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isSearching = false
            let uniquePlaces = self.removeDuplicatesAndOptimize(allPlaces)
            print("✅ Enhanced Search: \(uniquePlaces.count) lieux uniques et optimisés")
            self.searchResults = uniquePlaces
            completion(uniquePlaces)
        }
    }
    
    // MARK: - Recherche Apple Maps améliorée
    private func searchWithEnhancedAppleMaps(
        for categories: [LocationCategory],
        near location: CLLocation,
        radius: Double,
        completion: @escaping ([Location]) -> Void
    ) {
        var applePlaces: [Location] = []
        let group = DispatchGroup()
        
        for category in categories {
            group.enter()
            
            // Recherche avec requêtes multiples pour chaque catégorie
            let queries = getMultipleQueries(for: category)
            
            for query in queries {
                group.enter()
                searchWithQuery(query, near: location, radius: radius, category: category) { places in
                    applePlaces.append(contentsOf: places)
                    group.leave()
                }
            }
            
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(applePlaces)
        }
    }
    
    // MARK: - Requêtes multiples par catégorie
    private func getMultipleQueries(for category: LocationCategory) -> [String] {
        switch category {
        case .restaurant:
            return ["restaurant", "bistro", "café", "pizzeria", "brasserie", "gastronomique"]
        case .cafe:
            return ["café", "coffee", "tea", "boulangerie", "pâtisserie"]
        case .museum:
            return ["museum", "musée", "gallery", "exposition", "art"]
        case .culture:
            return ["cinema", "théâtre", "concert", "spectacle", "culture"]
        case .sport:
            return ["gym", "fitness", "sport", "entraînement", "salle de sport"]
        case .shopping:
            return ["shop", "store", "boutique", "centre commercial", "shopping"]
        case .entertainment:
            return ["entertainment", "divertissement", "loisirs", "amusement", "fun"]
        case .nature:
            return ["park", "parc", "jardin", "nature", "forêt", "sentier"]
        case .historical:
            return ["monument", "historique", "château", "église", "architecture"]
        case .bar:
            return ["bar", "pub", "nightclub", "discothèque", "cocktail"]
        case .religious:
            return ["church", "église", "mosquée", "synagogue", "temple", "religieux"]
        case .adventurePark:
            return ["adventure park", "parc d'aventure", "accrobranche", "escalade"]
        case .iceRink:
            return ["ice rink", "patinoire", "skating", "glace"]
        case .swimmingPool:
            return ["swimming pool", "piscine", "natation", "aquatique"]
        case .climbingGym:
            return ["climbing gym", "salle d'escalade", "escalade", "grimpe"]
        case .bowling:
            return ["bowling", "quilles", "bowl"]
        case .miniGolf:
            return ["mini golf", "golf miniature", "putt putt"]
        case .escapeRoom:
            return ["escape room", "escape game", "énigme", "mystère"]
        case .laserTag:
            return ["laser tag", "laser game", "lasertag"]
        case .paintball:
            return ["paintball", "airsoft", "tactique"]
        case .karting:
            return ["karting", "go kart", "kart", "course"]
        case .trampolinePark:
            return ["trampoline", "trampoline park", "rebond", "saut"]
        case .waterPark:
            return ["water park", "parc aquatique", "aquapark", "toboggan"]
        case .zoo:
            return ["zoo", "parc animalier", "animaux", "faune"]
        case .aquarium:
            return ["aquarium", "poissons", "marin", "océan"]
        }
    }
    
    // MARK: - Recherche avec requête spécifique
    private func searchWithQuery(
        _ query: String,
        near location: CLLocation,
        radius: Double,
        category: LocationCategory,
        completion: @escaping ([Location]) -> Void
    ) {
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
                    completion([])
                    return
                }
                
                let mapItems = response?.mapItems ?? []
                let locations = mapItems.compactMap { mapItem -> Location? in
                    return self.convertMapItemToLocation(mapItem, category: category)
                }
                
                completion(locations)
            }
        }
    }
    
    // MARK: - Recherche par termes spécifiques
    private func searchWithSpecificTerms(
        for categories: [LocationCategory],
        near location: CLLocation,
        radius: Double,
        completion: @escaping ([Location]) -> Void
    ) {
        var specificPlaces: [Location] = []
        let group = DispatchGroup()
        
        // Termes spécifiques pour des lieux populaires
        let specificTerms = [
            "piscine", "swimming", "pool",
            "escalade", "climbing", "grimpe",
            "bowling", "quilles",
            "laser", "paintball", "karting",
            "trampoline", "aquapark", "zoo", "aquarium"
        ]
        
        for term in specificTerms {
            group.enter()
            searchWithQuery(term, near: location, radius: radius, category: .entertainment) { places in
                specificPlaces.append(contentsOf: places)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(specificPlaces)
        }
    }
    
    // MARK: - Conversion MapItem vers Location
    private func convertMapItemToLocation(_ mapItem: MKMapItem, category: LocationCategory) -> Location? {
        guard let name = mapItem.name, !name.isEmpty else { return nil }
        
        // Vérifier si le lieu correspond à la catégorie
        let nameLower = name.lowercased()
        if !isRelevantForCategory(nameLower, category: category) {
            return nil
        }
        
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
            openingHours: generateOpeningHours(for: category),
            recommendedDuration: getRecommendedDuration(for: category),
            visitTips: generateVisitTips(for: category, placeName: name)
        )
    }
    
    // MARK: - Vérification de pertinence
    private func isRelevantForCategory(_ name: String, category: LocationCategory) -> Bool {
        switch category {
        case .restaurant:
            return name.contains("restaurant") || name.contains("bistro") || name.contains("café") || name.contains("pizzeria")
        case .cafe:
            return name.contains("café") || name.contains("coffee") || name.contains("tea") || name.contains("boulangerie")
        case .museum:
            return name.contains("museum") || name.contains("musée") || name.contains("gallery")
        case .sport:
            return name.contains("gym") || name.contains("fitness") || name.contains("sport")
        case .shopping:
            return name.contains("shop") || name.contains("store") || name.contains("boutique")
        case .nature:
            return name.contains("park") || name.contains("parc") || name.contains("jardin")
        case .bar:
            return name.contains("bar") || name.contains("pub") || name.contains("nightclub")
        case .swimmingPool:
            return name.contains("piscine") || name.contains("swimming") || name.contains("pool")
        case .climbingGym:
            return name.contains("escalade") || name.contains("climbing") || name.contains("grimpe")
        case .bowling:
            return name.contains("bowling") || name.contains("quilles")
        case .laserTag:
            return name.contains("laser") || name.contains("tag")
        case .paintball:
            return name.contains("paintball") || name.contains("airsoft")
        case .karting:
            return name.contains("kart") || name.contains("karting")
        case .trampolinePark:
            return name.contains("trampoline") || name.contains("rebond")
        case .waterPark:
            return name.contains("aquatique") || name.contains("aquapark") || name.contains("toboggan")
        case .zoo:
            return name.contains("zoo") || name.contains("animalier")
        case .aquarium:
            return name.contains("aquarium") || name.contains("poisson")
        default:
            return true
        }
    }
    
    // MARK: - Optimisation des résultats
    private func removeDuplicatesAndOptimize(_ places: [Location]) -> [Location] {
        var seen = Set<String>()
        var optimizedPlaces: [Location] = []
        
        // Trier par qualité
        let sortedPlaces = places.sorted { place1, place2 in
            let quality1 = getPlaceQuality(place1)
            let quality2 = getPlaceQuality(place2)
            return quality1 > quality2
        }
        
        for place in sortedPlaces {
            let key = "\(place.name)-\(place.latitude)-\(place.longitude)"
            if !seen.contains(key) {
                seen.insert(key)
                optimizedPlaces.append(place)
            }
        }
        
        // Limiter à 100 lieux maximum
        return Array(optimizedPlaces.prefix(100))
    }
    
    private func getPlaceQuality(_ place: Location) -> Int {
        var quality = 0
        
        // Qualité basée sur la catégorie et les données
        if let openingHours = place.openingHours, !openingHours.isEmpty && openingHours != "Horaires non disponibles" { quality += 3 }
        if let visitTips = place.visitTips, !visitTips.isEmpty { quality += 2 }
        if let rating = place.rating, rating > 0 { quality += 1 }
        
        return quality
    }
    
    // MARK: - Utilitaires
    private func generateOpeningHours(for category: LocationCategory) -> String {
        switch category {
        case .restaurant: return "12h00-14h30, 19h00-22h30"
        case .cafe: return "7h00-19h00"
        case .museum, .culture: return "10h00-18h00 (fermé lundi)"
        case .shopping: return "10h00-20h00"
        case .bar: return "17h00-02h00"
        case .sport: return "6h00-22h00"
        case .swimmingPool: return "7h00-21h00"
        case .climbingGym: return "8h00-23h00"
        case .bowling: return "10h00-00h00"
        case .entertainment: return "10h00-22h00"
        default: return "9h00-18h00"
        }
    }
    
    private func getRecommendedDuration(for category: LocationCategory) -> TimeInterval {
        switch category {
        case .restaurant: return 90 * 60 // 1h30
        case .cafe: return 45 * 60 // 45min
        case .museum: return 120 * 60 // 2h
        case .culture: return 150 * 60 // 2h30
        case .shopping: return 60 * 60 // 1h
        case .sport: return 90 * 60 // 1h30
        case .nature: return 60 * 60 // 1h
        case .entertainment: return 180 * 60 // 3h
        case .bar: return 120 * 60 // 2h
        case .swimmingPool: return 90 * 60 // 1h30
        case .climbingGym: return 120 * 60 // 2h
        case .bowling: return 120 * 60 // 2h
        case .laserTag: return 90 * 60 // 1h30
        case .paintball: return 180 * 60 // 3h
        case .karting: return 60 * 60 // 1h
        case .trampolinePark: return 120 * 60 // 2h
        case .waterPark: return 300 * 60 // 5h
        case .zoo: return 180 * 60 // 3h
        case .aquarium: return 120 * 60 // 2h
        default: return 60 * 60 // 1h
        }
    }
    
    private func generateVisitTips(for category: LocationCategory, placeName: String) -> [String] {
        switch category {
        case .restaurant:
            return ["Réservez à l'avance", "Vérifiez les horaires", "Découvrez les spécialités locales"]
        case .museum:
            return ["Vérifiez les expositions temporaires", "Tarifs réduits disponibles", "Visite guidée recommandée"]
        case .sport:
            return ["Équipement disponible sur place", "Cours pour débutants", "Horaires d'affluence"]
        case .swimmingPool:
            return ["Maillot de bain obligatoire", "Horaires de natation", "Cours disponibles"]
        case .climbingGym:
            return ["Équipement fourni", "Cours d'initiation", "Niveaux variés"]
        case .bowling:
            return ["Chaussures spéciales", "Réservation conseillée", "Activité familiale"]
        case .laserTag:
            return ["Vêtements confortables", "Équipes de 2-8 joueurs", "Durée 15-30 min"]
        case .paintball:
            return ["Équipement fourni", "Vêtements de rechange", "Activité physique"]
        case .karting:
            return ["Casque fourni", "Permis non requis", "Activité pour tous âges"]
        case .trampolinePark:
            return ["Chaussettes obligatoires", "Activités pour tous niveaux", "Sécurité prioritaire"]
        case .waterPark:
            return ["Maillot de bain", "Serviette", "Activités pour toute la famille"]
        case .zoo:
            return ["Visite guidée disponible", "Horaires d'alimentation", "Activités pour enfants"]
        case .aquarium:
            return ["Visite guidée", "Horaires de nourrissage", "Expositions temporaires"]
        default:
            return ["À découvrir", "Activité populaire", "Bonne expérience"]
        }
    }
} 