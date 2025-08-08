import Foundation
import Combine
import CoreLocation

class DayTripPlannerViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var generatedTrip: DayTrip?
    @Published var userTrips: [DayTrip] = []
    @Published var isGeocodingLocation = false
    @Published var foundLocations: [Location] = []
    @Published var geocodingProgress: String = ""
    @Published var geocodingStep: Int = 0
    @Published var totalGeocodingSteps: Int = 0
    @Published var publicTransportRoutes: [RealTransitRoute] = []
    
    private let apiService = APIService.shared
    private let placeSearchService = PlaceSearchService()
    private let publicTransportService = PublicTransportService()
    private let statisticsService = UserStatisticsService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadUserTrips()
    }
    
    func planTrip(request: TripPlanRequest) {
        isLoading = true
        errorMessage = nil
        
        apiService.planTrip(request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] trip in
                    self?.generatedTrip = trip
                    self?.userTrips.insert(trip, at: 0)
                }
            )
            .store(in: &cancellables)
    }
    
    func loadUserTrips() {
        apiService.getUserTrips()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to load user trips: \(error)")
                    }
                },
                receiveValue: { [weak self] trips in
                    self?.userTrips = trips
                }
            )
            .store(in: &cancellables)
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func clearGeneratedTrip() {
        generatedTrip = nil
    }
    
    // MARK: - Géolocalisation et recherche de lieux
    
    func getCurrentLocationAddress(from location: CLLocation, completion: @escaping (String) -> Void) {
        isGeocodingLocation = true
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isGeocodingLocation = false
                
                if let error = error {
                    self?.errorMessage = "Erreur de géolocalisation: \(error.localizedDescription)"
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    self?.errorMessage = "Impossible de déterminer l'adresse"
                    return
                }
                
                var addressComponents: [String] = []
                
                if let streetNumber = placemark.subThoroughfare {
                    addressComponents.append(streetNumber)
                }
                if let streetName = placemark.thoroughfare {
                    addressComponents.append(streetName)
                }
                if let city = placemark.locality {
                    addressComponents.append(city)
                }
                
                let address = addressComponents.joined(separator: " ")
                completion(address.isEmpty ? "Position actuelle" : address)
            }
        }
    }
    
    func searchPlaces(query: String) {
        guard !query.isEmpty else {
            foundLocations = []
            return
        }
        
        placeSearchService.searchPlacesByText(query)
        
        // Observer les résultats
        placeSearchService.$searchResults
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mapItems in
                self?.foundLocations = mapItems.map { $0.toLocation() }
            }
            .store(in: &cancellables)
    }
    
    func planTripWithRealLocations(startAddress: String, destinations: [String], transportMode: TransportMode, numberOfLocations: Int) {
        isLoading = true
        errorMessage = nil
        geocodingStep = 0
        
        // Créer une liste ordonnée de toutes les adresses
        let filteredDestinations = destinations.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let allAddresses = [startAddress] + filteredDestinations
        totalGeocodingSteps = allAddresses.count
        geocodingProgress = "Localisation des adresses..."
        

        
        // Géocoder séquentiellement pour maintenir l'ordre
        geocodeAddressesSequentially(addresses: allAddresses) { [weak self] geocodedLocations in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                print("🗺️ Debug géocodage:")
                print("   Adresses demandées: \(allAddresses)")
                print("   Adresses trouvées: \(geocodedLocations.count)")
                print("   Adresses trouvées: \(geocodedLocations.map { $0.name })")
                
                if geocodedLocations.count < 2 {
                    self.isLoading = false
                    self.geocodingProgress = ""
                    self.geocodingStep = 0
                    self.totalGeocodingSteps = 0
                    self.errorMessage = "Impossible de localiser suffisamment d'adresses (\(geocodedLocations.count)/\(allAddresses.count) trouvées). Vérifiez vos saisies ou utilisez des noms de lieux plus simples."
                    return
                }
                
                // Message informatif si certaines adresses n'ont pas pu être localisées
                if geocodedLocations.count < allAddresses.count {
                    let missing = allAddresses.count - geocodedLocations.count
                    print("⚠️ \(missing) adresse(s) n'ont pas pu être localisées")
                    // Optionnel: afficher un message à l'utilisateur
                }
                
                // Créer un voyage avec les vraies coordonnées dans le bon ordre
                self.createOptimizedTrip(
                    locations: geocodedLocations,
                    transportMode: transportMode,
                    numberOfLocations: numberOfLocations
                )
            }
        }
    }
    
    private func geocodeAddressesSequentially(addresses: [String], completion: @escaping ([Location]) -> Void) {
        var geocodedLocations: [Location] = []
        
        func geocodeNext(at index: Int) {
            guard index < addresses.count else {
                // Terminé - retourner les résultats
                DispatchQueue.main.async { [weak self] in
                    self?.geocodingProgress = "Optimisation de l'itinéraire..."
                }
                completion(geocodedLocations)
                return
            }
            
            let address = addresses[index]
            
            // Mettre à jour le progrès
            DispatchQueue.main.async { [weak self] in
                self?.geocodingStep = index + 1
                self?.geocodingProgress = "Localisation: \(address.prefix(30))..."
            }
            
            // Vérifier si c'est des coordonnées GPS (format lat,long)
            if let coordinates = parseCoordinates(from: address) {
                print("📍 Géocodage coordonnées: \(address)")
                geocodeCoordinates(coordinates: coordinates) { location in
                    if let location = location {
                        print("✅ Coordonnées trouvées: \(location.name)")
                        geocodedLocations.append(location)
                    } else {
                        print("❌ Échec géocodage coordonnées: \(address)")
                    }
                    // Continuer avec l'adresse suivante
                    geocodeNext(at: index + 1)
                }
            } else {
                // Géocodage normal pour une adresse
                print("📍 Géocodage adresse: \(address)")
                geocodeAddress(address: address) { location in
                    if let location = location {
                        print("✅ Adresse trouvée: \(location.name)")
                        geocodedLocations.append(location)
                    } else {
                        print("❌ Échec géocodage adresse: \(address)")
                    }
                    // Continuer avec l'adresse suivante
                    geocodeNext(at: index + 1)
                }
            }
        }
        
        // Commencer le géocodage séquentiel
        geocodeNext(at: 0)
    }
    
    private func geocodeCoordinates(coordinates: (latitude: Double, longitude: Double), completion: @escaping (Location?) -> Void) {
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            if placemarks == nil {
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?.first else {
                completion(nil)
                return
            }
            
            let formattedAddress = placemark.formattedAddressFromComponents
            let geocodedLocation = Location(
                id: UUID().uuidString,
                name: placemark.name ?? "Position GPS",
                address: formattedAddress.isEmpty ? "Position actuelle" : formattedAddress,
                latitude: coordinates.latitude,
                longitude: coordinates.longitude,
                category: self.determineCategory(from: placemark),
                description: nil,
                imageURL: nil,
                rating: nil,
                openingHours: nil,
                recommendedDuration: nil,
                visitTips: nil
            )
            
            completion(geocodedLocation)
        }
    }
    
    private func geocodeAddress(address: String, completion: @escaping (Location?) -> Void) {
        // Stratégie de géocodage multiple pour maximiser les chances de succès
        geocodeWithFallback(address: address, attempt: 1, completion: completion)
    }
    
    private func geocodeWithFallback(address: String, attempt: Int, completion: @escaping (Location?) -> Void) {
        var searchAddress = address
        
        // Modifier la recherche selon l'attempt
        switch attempt {
        case 1:
            // Première tentative : adresse complète
            searchAddress = address
        case 2:
            // Deuxième tentative : retirer le code postal si présent
            searchAddress = address.replacingOccurrences(of: #"\b\d{4,5}\b"#, with: "", options: .regularExpression)
        case 3:
            // Troisième tentative : extraire l'adresse si c'est un POI avec adresse
            if address.contains(",") {
                // Si c'est "Lidl, 9 Route d'Arlon, Strassen, 8009, Luxembourg"
                // Prendre seulement la partie adresse
                let components = address.components(separatedBy: ",")
                if components.count > 1 {
                    // Ignorer le premier composant (nom du POI) et prendre le reste
                    let addressPart = components.dropFirst().joined(separator: ",").trimmingCharacters(in: .whitespaces)
                    searchAddress = addressPart
                } else {
                    searchAddress = address
                }
            } else {
                // Si pas de virgule, garder tel quel
                searchAddress = address
            }
        case 4:
            // Quatrième tentative : essayer avec juste la ville
            if let city = extractCityFromAddress(address) {
                searchAddress = city
            } else {
                searchAddress = address
            }
        case 5:
            // Cinquième tentative : créer une location approximative
            print("🔄 Création location approximative pour: \(address)")
            let fallbackLocation = createFallbackLocation(for: address)
            completion(fallbackLocation)
            return
        default:
            // Échec après 5 tentatives
            print("❌ Échec définitif pour: \(address)")
            completion(nil)
            return
        }
        

        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchAddress.trimmingCharacters(in: .whitespaces)) { placemarks, _ in
            if placemarks == nil {
                // Essayer la stratégie suivante
                self.geocodeWithFallback(address: address, attempt: attempt + 1, completion: completion)
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                // Essayer la stratégie suivante
                self.geocodeWithFallback(address: address, attempt: attempt + 1, completion: completion)
                return
            }
            
            // Score de pertinence plus strict
            let relevanceScore = self.calculateRelevanceScore(
                searchTerm: address,
                placemark: placemark
            )
            
            print("📊 Score de pertinence pour '\(address)': \(relevanceScore)")
            
            // Accepter seulement les résultats avec un score suffisant
            if relevanceScore < 0.3 && attempt < 4 {
                print("🔄 Score trop faible (\(relevanceScore)), tentative suivante...")
                self.geocodeWithFallback(address: address, attempt: attempt + 1, completion: completion)
                return
            }
            
            let formattedAddress = placemark.formattedAddressFromComponents
            let displayName = placemark.name ?? address
            
            let geocodedLocation = Location(
                id: UUID().uuidString,
                name: displayName,
                address: formattedAddress.isEmpty ? address : formattedAddress,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                category: self.determineCategory(from: placemark),
                description: nil,
                imageURL: nil,
                rating: nil,
                openingHours: nil,
                recommendedDuration: nil,
                visitTips: nil
            )
            

            completion(geocodedLocation)
        }
    }
    
    private func calculateRelevanceScore(searchTerm: String, placemark: CLPlacemark) -> Double {
        let searchLower = searchTerm.lowercased()
        var score: Double = 0.0
        
        // Vérifier le nom exact (match parfait)
        if let name = placemark.name?.lowercased() {
            if name == searchLower {
                score += 1.0
            } else if name.contains(searchLower) {
                score += 0.8
            } else if searchLower.contains(name) {
                score += 0.6
            }
        }
        
        // Vérifier l'adresse exacte
        if let thoroughfare = placemark.thoroughfare?.lowercased() {
            if thoroughfare == searchLower {
                score += 0.9
            } else if thoroughfare.contains(searchLower) || searchLower.contains(thoroughfare) {
                score += 0.4
            }
        }
        
        // Vérifier la ville exacte
        if let locality = placemark.locality?.lowercased() {
            if locality == searchLower {
                score += 0.7
            } else if locality.contains(searchLower) || searchLower.contains(locality) {
                score += 0.3
            }
        }
        
        // Vérifier le pays
        if let country = placemark.country?.lowercased() {
            if country.contains(searchLower) || searchLower.contains(country) {
                score += 0.2
            }
        }
        
        // Bonus pour les POI avec adresse complète
        if placemark.name != nil && placemark.thoroughfare != nil && placemark.locality != nil {
            score += 0.3
        }
        
        // Pénalité si la ville ne correspond pas du tout
        if let locality = placemark.locality?.lowercased() {
            let searchWords = searchLower.components(separatedBy: " ")
            let hasCityMatch = searchWords.contains { word in
                locality.contains(word) || word.contains(locality)
            }
            if !hasCityMatch {
                score -= 0.2
            }
        }
        
        return max(0.0, min(score, 1.0))
    }
    
    private func determineCategory(from placemark: CLPlacemark) -> LocationCategory {
        // Logique simple pour déterminer la catégorie
        if let name = placemark.name?.lowercased() {
            if name.contains("restaurant") || name.contains("café") || name.contains("bar") {
                return .restaurant
            } else if name.contains("musée") || name.contains("museum") {
                return .culture
            } else if name.contains("parc") || name.contains("park") {
                return .nature
            } else if name.contains("magasin") || name.contains("shop") || name.contains("store") {
                return .shopping
            } else if name.contains("hôtel") || name.contains("hotel") {
                return .cafe
            }
        }
        
        return .cafe
    }
    
    private func createOptimizedTrip(locations: [Location], transportMode: TransportMode, numberOfLocations: Int) {
        guard locations.count >= 2 else {
            isLoading = false
            geocodingProgress = ""
            geocodingStep = 0
            totalGeocodingSteps = 0
            errorMessage = "Il faut au moins 2 lieux pour créer un itinéraire"
            return
        }
        
        let startLocation = locations[0]
        let destinations = Array(locations.dropFirst())
        
        print("🗺️ Création itinéraire:")
        print("   Point de départ: \(startLocation.name)")
        print("   Destinations: \(destinations.map { $0.name })")
        
        // Optimiser l'ordre des destinations (algorithme simple du plus proche voisin)
        let optimizedRoute = optimizeRoute(start: startLocation, destinations: destinations)
        
        print("   Itinéraire optimisé: \(optimizedRoute.map { $0.name })")
        
        // Pour le transport public, utiliser les vraies données
        if transportMode == .publicTransport {
            planPublicTransportRoute(optimizedRoute: optimizedRoute, transportMode: transportMode, numberOfLocations: numberOfLocations)
            return
        }
        
        // Pour les autres modes, calculer distance et durée estimées
        let totalDistance = calculateTotalDistance(route: optimizedRoute)
        let estimatedDuration = calculateEstimatedDuration(distance: totalDistance, mode: transportMode)
        
        let trip = DayTrip(
            id: UUID().uuidString,
            startLocation: startLocation,
            locations: destinations,
            optimizedRoute: optimizedRoute,
            totalDistance: totalDistance,
            estimatedDuration: estimatedDuration,
            transportMode: transportMode,
            createdAt: Date(),
            numberOfLocations: numberOfLocations
        )
        
        isLoading = false
        geocodingProgress = ""
        geocodingStep = 0
        totalGeocodingSteps = 0
        generatedTrip = trip
        userTrips.insert(trip, at: 0)
        
        // Incrémenter les statistiques
        statisticsService.addCompletedTrip(trip)
    }
    
    private func optimizeRoute(start: Location, destinations: [Location]) -> [Location] {
        print("🔄 Optimisation de l'itinéraire:")
        print("   Départ: \(start.name)")
        print("   Destinations à optimiser: \(destinations.map { $0.name })")
        
        var route = [start]
        var remaining = destinations
        var current = start
        
        while !remaining.isEmpty {
            // Trouver la destination la plus proche
            let nearest = remaining.min { loc1, loc2 in
                let dist1 = CLLocation(latitude: current.latitude, longitude: current.longitude)
                    .distance(from: CLLocation(latitude: loc1.latitude, longitude: loc1.longitude))
                let dist2 = CLLocation(latitude: current.latitude, longitude: current.longitude)
                    .distance(from: CLLocation(latitude: loc2.latitude, longitude: loc2.longitude))
                return dist1 < dist2
            }
            
            if let next = nearest {
                let distance = CLLocation(latitude: current.latitude, longitude: current.longitude)
                    .distance(from: CLLocation(latitude: next.latitude, longitude: next.longitude))
                print("   Prochaine destination: \(next.name) (distance: \(String(format: "%.1f", distance/1000))km)")
                route.append(next)
                current = next
                remaining.removeAll { $0.id == next.id }
            }
        }
        
        print("   Itinéraire final: \(route.map { $0.name })")
        return route
    }
    
    private func calculateTotalDistance(route: [Location]) -> Double {
        var totalDistance: Double = 0
        
        for i in 0..<route.count - 1 {
            let from = CLLocation(latitude: route[i].latitude, longitude: route[i].longitude)
            let to = CLLocation(latitude: route[i + 1].latitude, longitude: route[i + 1].longitude)
            totalDistance += from.distance(from: to)
        }
        
        return totalDistance / 1000.0 // Convertir en kilomètres
    }
    
    private func calculateEstimatedDuration(distance: Double, mode: TransportMode) -> TimeInterval {
        let speedKmH: Double
        
        switch mode {
        case .walking:
            speedKmH = 5.0 // 5 km/h
        case .cycling:
            speedKmH = 15.0 // 15 km/h
        case .driving:
            speedKmH = 40.0 // 40 km/h en ville
        case .publicTransport:
            speedKmH = 25.0 // 25 km/h avec arrêts
        }
        
        let travelTime = (distance / speedKmH) * 3600 // en secondes
        let visitTime = 30.0 * 60.0 * Double(max(1, distance / 5)) // 30 min par lieu approximativement
        
        return travelTime + visitTime
    }
    
    // MARK: - Méthodes auxiliaires
    
    private func createFallbackLocation(for address: String) -> Location {
        // Créer une location approximative basée sur la ville détectée
        let (latitude, longitude) = detectCityCoordinates(from: address)
        
        // Extraire le nom du lieu de l'adresse complète
        let name = extractLocationName(from: address)
        
        let fallbackLocation = Location(
            id: UUID().uuidString,
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            category: .cafe,
            description: "Location approximative - géocodage échoué",
            imageURL: nil,
            rating: nil,
            openingHours: nil,
            recommendedDuration: nil,
            visitTips: nil
        )
        return fallbackLocation
    }
    
    private func extractLocationName(from address: String) -> String {
        // Essayer d'extraire le nom du lieu de l'adresse
        let components = address.components(separatedBy: ",")
        if let firstComponent = components.first?.trimmingCharacters(in: .whitespaces) {
            return firstComponent
        }
        return address
    }
    
    private func detectCityCoordinates(from address: String) -> (latitude: Double, longitude: Double) {
        let addressLower = address.lowercased()
        
        // Détecter la ville basée sur l'adresse
        if addressLower.contains("paris") || addressLower.contains("france") {
            return (48.8566, 2.3522) // Paris
        } else if addressLower.contains("lyon") {
            return (45.7578, 4.8320) // Lyon
        } else if addressLower.contains("marseille") {
            return (43.2965, 5.3698) // Marseille
        } else if addressLower.contains("toulouse") {
            return (43.6047, 1.4442) // Toulouse
        } else if addressLower.contains("nice") {
            return (43.7102, 7.2620) // Nice
        } else if addressLower.contains("nantes") {
            return (47.2184, -1.5536) // Nantes
        } else if addressLower.contains("strasbourg") {
            return (48.5734, 7.7521) // Strasbourg
        } else if addressLower.contains("montpellier") {
            return (43.6108, 3.8767) // Montpellier
        } else if addressLower.contains("bordeaux") {
            return (44.8378, -0.5792) // Bordeaux
        } else if addressLower.contains("lille") {
            return (50.6292, 3.0573) // Lille
        } else if addressLower.contains("reims") {
            return (49.2583, 4.0317) // Reims
        } else if addressLower.contains("saint-étienne") || addressLower.contains("saint etienne") {
            return (45.4397, 4.3872) // Saint-Étienne
        } else if addressLower.contains("toulon") {
            return (43.1242, 5.9280) // Toulon
        } else if addressLower.contains("le havre") {
            return (49.4944, 0.1079) // Le Havre
        } else if addressLower.contains("grenoble") {
            return (45.1885, 5.7245) // Grenoble
        } else if addressLower.contains("dijon") {
            return (47.3220, 5.0415) // Dijon
        } else if addressLower.contains("angers") {
            return (47.4784, -0.5632) // Angers
        } else if addressLower.contains("saint-denis") {
            return (48.9362, 2.3574) // Saint-Denis
        } else if addressLower.contains("nîmes") || addressLower.contains("nimes") {
            return (43.8367, 4.3601) // Nîmes
        } else if addressLower.contains("bruxelles") || addressLower.contains("brussels") {
            return (50.8503, 4.3517) // Bruxelles
        } else if addressLower.contains("antwerpen") || addressLower.contains("antwerp") {
            return (51.2194, 4.4025) // Anvers
        } else if addressLower.contains("gent") || addressLower.contains("ghent") {
            return (51.0500, 3.7303) // Gand
        } else if addressLower.contains("charleroi") {
            return (50.4108, 4.4446) // Charleroi
        } else if addressLower.contains("liège") || addressLower.contains("liege") {
            return (50.6326, 5.5797) // Liège
        } else if addressLower.contains("brugge") || addressLower.contains("bruges") {
            return (51.2093, 3.2247) // Bruges
        } else if addressLower.contains("namur") {
            return (50.4674, 4.8719) // Namur
        } else if addressLower.contains("luxembourg") {
            return (49.6116, 6.1319) // Luxembourg
        } else if addressLower.contains("zurich") {
            return (47.3769, 8.5417) // Zurich
        } else if addressLower.contains("genève") || addressLower.contains("geneva") {
            return (46.2044, 6.1432) // Genève
        } else if addressLower.contains("basel") {
            return (47.5596, 7.5886) // Bâle
        } else if addressLower.contains("bern") {
            return (46.9479, 7.4474) // Berne
        } else if addressLower.contains("lausanne") {
            return (46.5197, 6.6323) // Lausanne
        } else if addressLower.contains("berlin") {
            return (52.5200, 13.4050) // Berlin
        } else if addressLower.contains("hamburg") {
            return (53.5511, 9.9937) // Hambourg
        } else if addressLower.contains("münchen") || addressLower.contains("munich") {
            return (48.1351, 11.5820) // Munich
        } else if addressLower.contains("köln") || addressLower.contains("cologne") {
            return (50.9375, 6.9603) // Cologne
        } else if addressLower.contains("frankfurt") {
            return (50.1109, 8.6821) // Francfort
        } else if addressLower.contains("stuttgart") {
            return (48.7758, 9.1829) // Stuttgart
        } else if addressLower.contains("düsseldorf") || addressLower.contains("dusseldorf") {
            return (51.2277, 6.7735) // Düsseldorf
        } else if addressLower.contains("istanbul") {
            return (41.0082, 28.9784) // Istanbul
        } else if addressLower.contains("ankara") {
            return (39.9334, 32.8597) // Ankara
        } else if addressLower.contains("tokyo") {
            return (35.6762, 139.6503) // Tokyo
        } else if addressLower.contains("osaka") {
            return (34.6937, 135.5023) // Osaka
        } else if addressLower.contains("kyoto") {
            return (35.0116, 135.7681) // Kyoto
        } else if addressLower.contains("beijing") {
            return (39.9042, 116.4074) // Beijing
        } else if addressLower.contains("shanghai") {
            return (31.2304, 121.4737) // Shanghai
        } else if addressLower.contains("tanger") || addressLower.contains("tangier") {
            return (35.7595, -5.8340) // Tanger
        } else if addressLower.contains("casablanca") {
            return (33.5731, -7.5898) // Casablanca
        } else if addressLower.contains("ain sebaa") || addressLower.contains("aïn sebaâ") || addressLower.contains("ain sebaâ") || addressLower.contains("aïn sebaa") {
            return (33.5957, -7.6328) // Aïn Sebaâ, Casablanca
        } else if addressLower.contains("marrakech") {
            return (31.6295, -7.9811) // Marrakech
        } else if addressLower.contains("fès") || addressLower.contains("fez") {
            return (34.0181, -5.0078) // Fès
        } else if addressLower.contains("rabat") {
            return (34.0209, -6.8416) // Rabat
        } else if addressLower.contains("agadir") {
            return (30.4278, -9.5981) // Agadir
        }
        
        // Par défaut, utiliser Luxembourg
        return (49.6116, 6.1319)
    }
    
    private func extractCityFromAddress(_ address: String) -> String? {
        let addressLower = address.lowercased()
        
        // Liste des villes principales avec leurs variations
        let cities = [
            "paris", "lyon", "marseille", "toulouse", "nice", "nantes", "strasbourg", "montpellier", "bordeaux", "lille", "reims", "saint-étienne", "saint etienne", "toulon", "le havre", "grenoble", "dijon", "angers", "saint-denis", "nîmes", "nimes",
            "bruxelles", "brussels", "antwerpen", "antwerp", "gent", "ghent", "charleroi", "liège", "liege", "brugge", "bruges", "namur",
            "luxembourg", "zurich", "genève", "geneva", "basel", "bern", "lausanne",
            "berlin", "hamburg", "münchen", "munich", "köln", "cologne", "frankfurt", "stuttgart", "düsseldorf", "dusseldorf",
            "istanbul", "ankara", "tokyo", "osaka", "kyoto", "beijing", "shanghai",
            "tanger", "tangier", "casablanca", "ain sebaa", "aïn sebaâ", "marrakech", "fès", "fez", "rabat", "agadir"
        ]
        
        for city in cities {
            if addressLower.contains(city) {
                return city.capitalized
            }
        }
        
        return nil
    }
    
    // MARK: - Public Transport Planning
    private func planPublicTransportRoute(optimizedRoute: [Location], transportMode: TransportMode, numberOfLocations: Int) {
        print("🚌 Planification transport public...")
        print("   Nombre de lieux: \(optimizedRoute.count)")
        print("   Lieux: \(optimizedRoute.map { $0.name })")
        
        // Convertir les locations en coordonnées
        let coordinates = optimizedRoute.map { $0.coordinate }
        print("   Coordonnées: \(coordinates.map { "\($0.latitude), \($0.longitude)" })")
        
        // Planifier l'itinéraire de transport public avec MapKit
        if coordinates.count >= 2 {
            let startLocation = CLLocation(latitude: coordinates.first!.latitude, longitude: coordinates.first!.longitude)
            let endLocation = CLLocation(latitude: coordinates.last!.latitude, longitude: coordinates.last!.longitude)
            
            publicTransportService.findRoutes(
                from: startLocation,
                to: endLocation,
                departureTime: Date(),
                transportMode: .publicTransport
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    self?.geocodingProgress = ""
                    self?.geocodingStep = 0
                    self?.totalGeocodingSteps = 0
                    
                    if case .failure(let error) = completion {
                        print("❌ Erreur transport public: \(error)")
                        // Ne pas afficher l'erreur technique à l'utilisateur
                        // L'erreur est déjà gérée par le service avec les routes simulées
                    }
                },
                receiveValue: { [weak self] transportRoutes in
                    guard let self = self else { return }
                    
                    print("✅ Itinéraire transport public planifié: \(transportRoutes.count) segments")
                    
                    // Calculer les totaux
                    let totalDistance = transportRoutes.reduce(0) { $0 + $1.totalDistance }
                    let totalDuration = transportRoutes.reduce(0) { $0 + $1.totalDuration }
                    let totalFare = transportRoutes.reduce(0) { $0 + $1.totalFare }
                    
                    print("   Distance totale: \(String(format: "%.1f", totalDistance/1000))km")
                    print("   Durée totale: \(String(format: "%.0f", totalDuration/60))min")
                    print("   Tarif total: \(String(format: "%.2f", totalFare))€")
                    
                    // Créer le voyage avec les informations de transport public
                    let startLocation = optimizedRoute[0]
                    let destinations = Array(optimizedRoute.dropFirst())
                    
                    let trip = DayTrip(
                        id: UUID().uuidString,
                        startLocation: startLocation,
                        locations: destinations,
                        optimizedRoute: optimizedRoute,
                        totalDistance: totalDistance / 1000.0, // Convertir en km
                        estimatedDuration: totalDuration,
                        transportMode: transportMode,
                        createdAt: Date(),
                        numberOfLocations: numberOfLocations
                    )
                    
                    self.generatedTrip = trip
                    self.userTrips.insert(trip, at: 0)
                    
                    // Stocker les routes de transport public pour l'affichage détaillé
                    self.publicTransportRoutes = transportRoutes
                }
            )
            .store(in: &cancellables)
        } else {
            // Pas assez de coordonnées pour un itinéraire de transport public
            print("⚠️ Pas assez de coordonnées pour planifier un itinéraire de transport public")
            
            // Créer le voyage sans transport public détaillé
            let startLocation = optimizedRoute.first!
            let destinations = Array(optimizedRoute.dropFirst())
            
            let trip = DayTrip(
                id: UUID().uuidString,
                startLocation: startLocation,
                locations: destinations,
                optimizedRoute: optimizedRoute,
                totalDistance: 0, // Distance non calculée sans transport public
                estimatedDuration: 0,
                transportMode: transportMode,
                createdAt: Date(),
                numberOfLocations: numberOfLocations
            )
            
            self.generatedTrip = trip
            self.userTrips.insert(trip, at: 0)
            self.isLoading = false
            self.geocodingProgress = ""
            self.geocodingStep = 0
            self.totalGeocodingSteps = 0
        }
    }
    
    private func parseCoordinates(from string: String) -> (latitude: Double, longitude: Double)? {
        let components = string.components(separatedBy: ",")
        guard components.count == 2,
              let lat = Double(components[0].trimmingCharacters(in: .whitespaces)),
              let lon = Double(components[1].trimmingCharacters(in: .whitespaces)) else {
            return nil
        }
        return (latitude: lat, longitude: lon)
    }
}

// MARK: - Extensions
extension CLPlacemark {
    var formattedAddressFromComponents: String {
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
        
        return addressComponents.joined(separator: ", ")
    }
} 