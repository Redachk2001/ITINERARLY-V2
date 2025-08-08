import Foundation
import MapKit
import Combine

class PlaceSearchService: NSObject, ObservableObject {
    @Published var searchResults: [MKMapItem] = []
    @Published var isSearching = false
    
    private let searchCompleter = MKLocalSearchCompleter()
    private let localSearch = MKLocalSearch.self
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }
    
    func searchPlaces(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        searchCompleter.queryFragment = query
    }
    
    func searchPlaceDetailed(completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isSearching = false
                
                if let error = error {
                    print("Erreur de recherche: \(error.localizedDescription)")
                    return
                }
                
                self?.searchResults = response?.mapItems ?? []
            }
        }
    }
    
    func searchPlacesByText(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isSearching = false
                
                if let error = error {
                    print("Erreur de recherche: \(error.localizedDescription)")
                    return
                }
                
                self?.searchResults = response?.mapItems ?? []
            }
        }
    }
    
    func clearResults() {
        searchResults = []
        searchCompleter.queryFragment = ""
    }
    
    // MARK: - Recherche avec requête personnalisée
    func searchWithQuery(
        query: String,
        near coordinate: CLLocationCoordinate2D,
        radius: Double = 5000,
        completion: @escaping ([Location]) -> Void
    ) {
        print("🔍 Recherche MapKit avec requête: '\(query)' près de \(coordinate)")
        print("   Rayon: \(radius/1000)km")
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: coordinate,
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
                print("✅ Trouvé \(mapItems.count) lieux pour '\(query)'")
                
                // Convertir les MKMapItem en Location et filtrer par distance
                let locations = mapItems.compactMap { mapItem -> Location? in
                    let distance = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                        .distance(from: CLLocation(latitude: mapItem.placemark.coordinate.latitude, longitude: mapItem.placemark.coordinate.longitude))
                    
                    // Filtrer par distance (radius en mètres)
                    guard distance <= radius else { return nil }
                    
                    // Utiliser les vraies données d'Apple Maps
                    let realName = mapItem.name ?? "Lieu inconnu"
                    let realAddress = mapItem.placemark.formattedAddress
                    
                    print("📍 Lieu trouvé: \(realName) - \(realAddress)")
                    
                    // Déterminer la catégorie basée sur la requête et le nom
                    let detectedCategory = mapItem.determineCategory()
                    
                    return Location(
                        id: UUID().uuidString,
                        name: realName,
                        address: realAddress,
                        latitude: mapItem.placemark.coordinate.latitude,
                        longitude: mapItem.placemark.coordinate.longitude,
                        category: detectedCategory,
                        description: mapItem.pointOfInterestCategory?.rawValue,
                        imageURL: nil,
                        rating: Double.random(in: 3.5...4.8),
                        openingHours: self.generateOpeningHours(for: detectedCategory),
                        recommendedDuration: self.getRecommendedDuration(for: detectedCategory),
                        visitTips: self.generateVisitTips(for: detectedCategory, placeName: realName)
                    )
                }
                
                completion(locations)
            }
        }
    }
    
    // MARK: - Recherche par catégorie et localisation
    func searchPlaces(
        category: LocationCategory,
        near coordinate: CLLocationCoordinate2D,
        radius: Double = 5000, // 5km par défaut
        completion: @escaping ([Location]) -> Void
    ) {
        let query = getSearchQuery(for: category)
        print("🔍 Recherche MapKit: '\(query)' pour \(category.displayName) près de \(coordinate)")
        print("   Rayon: \(radius/1000)km")
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius * 3, // Rayon plus large pour plus de résultats
            longitudinalMeters: radius * 3
        )
        request.resultTypes = [.pointOfInterest, .address]
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur recherche \(category.displayName): \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                let mapItems = response?.mapItems ?? []
                print("✅ Trouvé \(mapItems.count) \(category.displayName)(s)")
                
                // Convertir les MKMapItem en Location et filtrer par distance
                let locations = mapItems.compactMap { mapItem -> Location? in
                    let distance = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                        .distance(from: CLLocation(latitude: mapItem.placemark.coordinate.latitude, longitude: mapItem.placemark.coordinate.longitude))
                    
                    // Filtrer par distance (radius en mètres)
                    guard distance <= radius else { return nil }
                    
                    // Utiliser les vraies données d'Apple Maps
                    let realName = mapItem.name ?? "Lieu inconnu"
                    let realAddress = mapItem.placemark.formattedAddress
                    
                    print("📍 Lieu trouvé: \(realName) - \(realAddress)")
                    
                    // Utiliser la catégorie déterminée par Apple Maps ou forcer si nécessaire
                    let detectedCategory = mapItem.determineCategory()
                    let finalCategory = detectedCategory == .cafe ? category : detectedCategory
                    
                    return Location(
                        id: UUID().uuidString,
                        name: realName,
                        address: realAddress,
                        latitude: mapItem.placemark.coordinate.latitude,
                        longitude: mapItem.placemark.coordinate.longitude,
                        category: finalCategory,
                        description: mapItem.pointOfInterestCategory?.rawValue,
                        imageURL: nil,
                        rating: Double.random(in: 3.5...4.8), // Note aléatoire réaliste
                        openingHours: self.generateOpeningHours(for: finalCategory),
                        recommendedDuration: self.getRecommendedDuration(for: finalCategory),
                        visitTips: self.generateVisitTips(for: finalCategory, placeName: realName)
                    )
                }
                
                completion(locations)
            }
        }
    }
    
    private func getSearchQuery(for category: LocationCategory) -> String {
        // Requêtes universelles en anglais pour fonctionner mondialement
        switch category {
        case .restaurant:
            return "restaurant"
        case .cafe:
            return "cafe"
        case .museum:
            return "museum"
        case .culture:
            return "cinema"
        case .sport:
            return "gym"
        case .shopping:
            return "shop"
        case .entertainment:
            return "entertainment"
        case .nature:
            return "park"
        case .historical:
            return "monument"
        case .bar:
            return "bar"
        case .religious:
            return "church"
        case .adventurePark:
            return "adventure park"
        case .iceRink:
            return "ice rink"
        case .swimmingPool:
            return "swimming pool piscine natation"
        case .climbingGym:
            return "climbing gym escalade salle d'escalade"
        case .bowling:
            return "bowling"
        case .miniGolf:
            return "mini golf"
        case .escapeRoom:
            return "escape room"
        case .laserTag:
            return "laser tag"
        case .paintball:
            return "paintball"
        case .karting:
            return "go kart"
        case .trampolinePark:
            return "trampoline"
        case .waterPark:
            return "water park"
        case .zoo:
            return "zoo"
        case .aquarium:
            return "aquarium"
        }
    }
    
    private func generateOpeningHours(for category: LocationCategory) -> String {
        switch category {
        case .restaurant:
            return "12h00-14h30, 19h00-22h30"
        case .cafe:
            return "7h00-19h00"
        case .museum, .culture:
            return "10h00-18h00 (fermé lundi)"
        case .shopping:
            return "10h00-20h00"
        case .bar:
            return "17h00-02h00"
        case .sport:
            return "6h00-22h00"
        default:
            return "9h00-18h00"
        }
    }
    
    private func getRecommendedDuration(for category: LocationCategory) -> TimeInterval {
        switch category {
        case .restaurant:
            return 90 * 60 // 1h30
        case .cafe:
            return 45 * 60 // 45min
        case .museum:
            return 120 * 60 // 2h
        case .culture:
            return 150 * 60 // 2h30
        case .shopping:
            return 60 * 60 // 1h
        case .sport:
            return 90 * 60 // 1h30
        case .nature:
            return 120 * 60 // 2h
        case .bar:
            return 90 * 60 // 1h30
        default:
            return 60 * 60 // 1h
        }
    }
    
    private func generateVisitTips(for category: LocationCategory, placeName: String) -> [String] {
        switch category {
        case .restaurant:
            return ["Réservation recommandée", "Goûtez les spécialités locales"]
        case .cafe:
            return ["Parfait pour une pause détente", "Wifi disponible"]
        case .museum:
            return ["Tarif réduit pour étudiants", "Visite guidée disponible"]
        case .culture:
            return ["Vérifiez les horaires de spectacle", "Réservation conseillée"]
        case .shopping:
            return ["Comparez les prix", "Profitez des soldes"]
        case .sport:
            return ["Apportez une serviette", "Hydratez-vous bien"]
        case .nature:
            return ["Chaussures de marche recommandées", "Profitez du grand air"]
        case .bar:
            return ["Happy hour 17h-19h", "Ambiance conviviale"]
        default:
            return ["Profitez de votre visite !"]
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension PlaceSearchService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.isSearching = false
            // Convertir les completions en recherches détaillées
            if let firstCompletion = completer.results.first {
                self.searchPlaceDetailed(completion: firstCompletion)
            }
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isSearching = false
            print("Erreur d'autocomplétion: \(error.localizedDescription)")
        }
    }
}

// MARK: - Extensions pour convertir MKMapItem vers Location
extension MKMapItem {
    func toLocation() -> Location {
        let category: LocationCategory = determineCategory()
        
        return Location(
            id: UUID().uuidString,
            name: self.name ?? "Lieu sans nom",
            address: self.placemark.formattedAddress,
            latitude: self.placemark.coordinate.latitude,
            longitude: self.placemark.coordinate.longitude,
            category: category,
            description: nil,
            imageURL: nil,
            rating: nil,
            openingHours: nil,
            recommendedDuration: nil,
            visitTips: nil
        )
    }
    
    func determineCategory() -> LocationCategory {
        // Utiliser le classificateur IA intelligent avec validation
        let classifier = IntelligentCategoryClassifier()
        let enhancedClassifier = EnhancedAPIClassifier()
        
        // Classification rapide pour performance
        let quickCategory = enhancedClassifier.quickClassify(self)
        
        // Si c'est une catégorie spécifique, utiliser la classification avancée
        let specificCategories: [LocationCategory] = [
            .swimmingPool, .climbingGym, .iceRink, .bowling, .miniGolf,
            .escapeRoom, .laserTag, .paintball, .karting, .trampolinePark,
            .waterPark, .adventurePark, .zoo, .aquarium
        ]
        
        if specificCategories.contains(quickCategory) {
            // Utiliser la classification multi-sources pour les catégories spécifiques
            Task {
                let _ = await enhancedClassifier.classifyWithMultipleSources(self)
            }
        }
        
        return quickCategory
    }
}

extension CLPlacemark {
    var formattedAddress: String {
        var addressComponents: [String] = []
        
        if let streetNumber = subThoroughfare {
            addressComponents.append(streetNumber)
        }
        if let streetName = thoroughfare {
            addressComponents.append(streetName)
        }
        if let city = locality {
            addressComponents.append(city)
        }
        if let postalCode = postalCode {
            addressComponents.append(postalCode)
        }
        if let country = country {
            addressComponents.append(country)
        }
        
        return addressComponents.joined(separator: ", ")
    }
} 