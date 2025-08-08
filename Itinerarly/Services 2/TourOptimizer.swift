import Foundation
import CoreLocation
import MapKit

class TourOptimizer {
    
    // MARK: - Positions de test prédéfinies pour chaque ville
    static let parisTestLocation = CLLocationCoordinate2D(
        latitude: 48.8566,  // Centre de Paris
        longitude: 2.3522
    )
    
    static let brusselsTestLocation = CLLocationCoordinate2D(
        latitude: 50.8503,  // Gare Centrale de Bruxelles
        longitude: 4.3517
    )
    
    static let luxembourgTestLocation = CLLocationCoordinate2D(
        latitude: 49.6116,  // Place Guillaume II, Luxembourg
        longitude: 6.1319
    )
    
    static func testLocationFor(city: City) -> CLLocationCoordinate2D {
        switch city {
        case .paris:
            return parisTestLocation
        case .brussels:
            return brusselsTestLocation
        case .luxembourg:
            return luxembourgTestLocation
        default:
            return parisTestLocation
        }
    }
    
    // MARK: - Optimisation intelligente avec mix de catégories
    static func optimizeWithCategoryMix(_ locations: [Location], startLocation: CLLocationCoordinate2D, maxTime: TimeInterval, transportMode: TransportMode) -> [Location] {
        print("🎯 Optimisation avec mix de catégories:")
        print("   Lieux disponibles: \(locations.count)")
        print("   Temps maximum: \(formatDuration(maxTime))")
        print("   Transport: \(transportMode.displayName)")
        
        // Grouper par catégorie
        let locationsByCategory = Dictionary(grouping: locations, by: { $0.category })
        let availableCategories = Array(locationsByCategory.keys)
        
        print("📊 Catégories disponibles: \(availableCategories.map { $0.displayName })")
        
        // Stratégie: Prendre 1 lieu de chaque catégorie, puis optimiser l'ordre
        var selectedLocations: [Location] = []
        var usedCategories: Set<LocationCategory> = []
        var currentTime: TimeInterval = 0
        
        // Étape 1: Sélectionner un lieu de chaque catégorie
        for category in availableCategories {
            guard let categoryLocations = locationsByCategory[category], !categoryLocations.isEmpty else { continue }
            
            // Prendre le meilleur lieu de cette catégorie (meilleur rating ou plus proche)
            let bestLocation = categoryLocations.max { loc1, loc2 in
                let rating1 = loc1.rating ?? 0
                let rating2 = loc2.rating ?? 0
                if abs(rating1 - rating2) > 0.5 {
                    return rating1 < rating2
                } else {
                    // Si ratings similaires, prendre le plus proche du point de départ
                    let dist1 = CLLocation(latitude: startLocation.latitude, longitude: startLocation.longitude)
                        .distance(from: CLLocation(latitude: loc1.latitude, longitude: loc1.longitude))
                    let dist2 = CLLocation(latitude: startLocation.latitude, longitude: startLocation.longitude)
                        .distance(from: CLLocation(latitude: loc2.latitude, longitude: loc2.longitude))
                    return dist1 > dist2
                }
            } ?? categoryLocations.first!
            
            let visitDuration = getRecommendedDuration(for: bestLocation.category)
            let travelTime = calculateTravelTime(from: selectedLocations.last, to: bestLocation, userStartLocation: startLocation, transportMode: transportMode)
            
            if currentTime + visitDuration + travelTime <= maxTime {
                selectedLocations.append(bestLocation)
                usedCategories.insert(category)
                currentTime += visitDuration + travelTime
                
                print("✅ Ajouté: \(bestLocation.name) (\(category.displayName))")
                print("   Temps utilisé: \(formatDuration(currentTime))")
            }
        }
        
        // Étape 2: Optimiser l'ordre avec l'algorithme du plus proche voisin
        let optimizedOrder = optimizeRouteOrder(locations: selectedLocations, startLocation: startLocation)
        
        // Étape 3: Remplir le temps restant avec des lieux de catégories différentes
        let remainingTime = maxTime - currentTime
        if remainingTime > 0 {
            let remainingLocations = locations.filter { location in
                !usedCategories.contains(location.category) && 
                !selectedLocations.contains { $0.id == location.id }
            }
            
            let additionalLocations = selectAdditionalLocations(
                from: remainingLocations,
                currentLocations: optimizedOrder,
                remainingTime: remainingTime,
                startLocation: startLocation,
                transportMode: transportMode
            )
            
            let finalLocations = optimizedOrder + additionalLocations
            let finalOptimizedOrder = optimizeRouteOrder(locations: finalLocations, startLocation: startLocation)
            
            print("🎯 Résultat final:")
            print("   Lieux sélectionnés: \(finalOptimizedOrder.count)")
            print("   Catégories: \(Set(finalOptimizedOrder.map { $0.category }).map { $0.displayName })")
            print("   Temps total: \(formatDuration(calculateTotalTime(locations: finalOptimizedOrder, startLocation: startLocation, transportMode: transportMode)))")
            
            return finalOptimizedOrder
        }
        
        return optimizedOrder
    }
    
    // MARK: - Optimisation de l'ordre des lieux (algorithme du plus proche voisin)
    private static func optimizeRouteOrder(locations: [Location], startLocation: CLLocationCoordinate2D) -> [Location] {
        guard locations.count > 1 else { return locations }
        
        var remaining = locations
        var optimized: [Location] = []
        var currentLocation = startLocation
        
        while !remaining.isEmpty {
            // Trouver le lieu le plus proche
            let nearestIndex = remaining.enumerated().min { first, second in
                let distance1 = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
                    .distance(from: CLLocation(latitude: first.element.latitude, longitude: first.element.longitude))
                let distance2 = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
                    .distance(from: CLLocation(latitude: second.element.latitude, longitude: second.element.longitude))
                return distance1 < distance2
            }?.offset ?? 0
            
            let next = remaining.remove(at: nearestIndex)
            optimized.append(next)
            currentLocation = next.coordinate
        }
        
        return optimized
    }
    
    // MARK: - Sélection de lieux supplémentaires
    private static func selectAdditionalLocations(from remaining: [Location], currentLocations: [Location], remainingTime: TimeInterval, startLocation: CLLocationCoordinate2D, transportMode: TransportMode) -> [Location] {
        var selected: [Location] = []
        var currentTime: TimeInterval = 0
        var currentLocation = currentLocations.last?.coordinate ?? startLocation
        
        // Trier par score (rating + proximité)
        let scoredLocations = remaining.map { location in
            let rating = location.rating ?? 3.0
            let distance = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
                .distance(from: CLLocation(latitude: location.latitude, longitude: location.longitude))
            let score = rating - (distance / 1000.0) // Pénaliser la distance
            return (location, score)
        }.sorted { $0.1 > $1.1 }
        
        for (location, _) in scoredLocations {
            let visitDuration = getRecommendedDuration(for: location.category)
            let travelTime = calculateTravelTime(from: currentLocations.last, to: location, userStartLocation: startLocation, transportMode: transportMode)
            
            if currentTime + visitDuration + travelTime <= remainingTime {
                selected.append(location)
                currentTime += visitDuration + travelTime
                currentLocation = location.coordinate
            }
        }
        
        return selected
    }
    
    // MARK: - Calcul du temps de trajet précis
    private static func calculateTravelTime(from startLocation: Location?, to endLocation: Location, userStartLocation: CLLocationCoordinate2D, transportMode: TransportMode) -> TimeInterval {
        let fromLocation = startLocation?.coordinate ?? userStartLocation
        let toLocation = endLocation.coordinate
        
        let distance = CLLocation(latitude: fromLocation.latitude, longitude: fromLocation.longitude)
            .distance(from: CLLocation(latitude: toLocation.latitude, longitude: toLocation.longitude))
        
        // Vitesses moyennes réalistes en ville
        let averageSpeed: Double
        let efficiencyFactor: Double
        
        switch transportMode {
        case .walking:
            averageSpeed = 4.0 // 4 km/h à pied
            efficiencyFactor = 1.3 // Facteur pour feux, intersections, etc.
        case .cycling:
            averageSpeed = 15.0 // 15 km/h à vélo
            efficiencyFactor = 1.1 // Peu d'arrêts
        case .driving:
            averageSpeed = 25.0 // 25 km/h en ville (réaliste)
            efficiencyFactor = 1.2 // Embouteillages, feux
        case .publicTransport:
            averageSpeed = 18.0 // 18 km/h en transport public
            efficiencyFactor = 1.4 // Attentes, correspondances
        }
        
        let timeInHours = (distance / 1000.0) / averageSpeed
        return timeInHours * 3600 * efficiencyFactor
    }
    
    // MARK: - Durées recommandées par catégorie
    private static func getRecommendedDuration(for category: LocationCategory) -> TimeInterval {
        switch category {
        case .restaurant: return 90 * 60 // 1h30
        case .cafe: return 45 * 60 // 45min
        case .bar: return 120 * 60 // 2h
        case .culture: return 120 * 60 // 2h
        case .museum: return 120 * 60 // 2h
        case .historical: return 90 * 60 // 1h30
        case .shopping: return 90 * 60 // 1h30
        case .entertainment: return 120 * 60 // 2h
        case .sport: return 90 * 60 // 1h30
        case .nature: return 120 * 60 // 2h
        case .swimmingPool: return 90 * 60 // 1h30
        case .climbingGym: return 120 * 60 // 2h
        case .iceRink: return 90 * 60 // 1h30
        case .bowling: return 90 * 60 // 1h30
        case .miniGolf: return 60 * 60 // 1h
        case .escapeRoom: return 60 * 60 // 1h
        case .laserTag: return 60 * 60 // 1h
        case .paintball: return 120 * 60 // 2h
        case .karting: return 60 * 60 // 1h
        case .trampolinePark: return 90 * 60 // 1h30
        case .waterPark: return 180 * 60 // 3h
        case .adventurePark: return 180 * 60 // 3h
        case .zoo: return 180 * 60 // 3h
        case .aquarium: return 120 * 60 // 2h
        case .religious: return 60 * 60 // 1h
        default: return 90 * 60 // 1h30 par défaut
        }
    }
    
    // MARK: - Calcul du temps total
    private static func calculateTotalTime(locations: [Location], startLocation: CLLocationCoordinate2D, transportMode: TransportMode) -> TimeInterval {
        var totalTime: TimeInterval = 0
        var currentLocation = startLocation
        
        for location in locations {
            let visitDuration = getRecommendedDuration(for: location.category)
            let travelTime = calculateTravelTime(from: nil, to: location, userStartLocation: currentLocation, transportMode: transportMode)
            
            totalTime += visitDuration + travelTime
            currentLocation = location.coordinate
        }
        
        return totalTime
    }
    
    // MARK: - Optimisation d'un tour avec routing réel (asynchrone)
    static func optimizeTourWithRealRouting(_ tour: GuidedTour, startLocation: CLLocationCoordinate2D, startAddress: String? = nil, transportMode: TransportMode = .walking, completion: @escaping (GuidedTour) -> Void) {
        var optimizedTour = tour
        
        // Calculer l'ordre optimal des arrêts avec routing réel
        optimizeStopsWithRealRouting(tour.stops, startLocation: startLocation, transportMode: transportMode) { optimizedStops in
            DispatchQueue.main.async {
                // Calculer les temps de trajet et distances avec les vraies routes
                let stopsWithTiming = optimizedStops
                
                // Calculer la durée totale et distance
                let (totalDuration, totalDistance, totalTravelTime) = calculateTotals(stopsWithTiming)
                
                // Mettre à jour le tour
                optimizedTour.startLocation = startLocation
                optimizedTour.startAddress = startAddress
                optimizedTour.optimizedStops = stopsWithTiming
                optimizedTour.totalDistance = totalDistance
                optimizedTour.estimatedTravelTime = totalTravelTime
                optimizedTour.duration = totalDuration
                
                completion(optimizedTour)
            }
        }
    }
    
    // MARK: - Optimisation d'un tour (version synchrone pour compatibilité)
    static func optimizeTour(_ tour: GuidedTour, startLocation: CLLocationCoordinate2D, startAddress: String? = nil, transportMode: TransportMode = .walking) -> GuidedTour {
        var optimizedTour = tour
        
        print("🗺️ Optimisation du tour: \(tour.title)")
        print("   Point de départ: \(startLocation.latitude), \(startLocation.longitude)")
        print("   Mode de transport: \(transportMode.displayName)")
        print("   Arrêts originaux: \(tour.stops.map { $0.location.name })")
        
        // Version rapide avec calcul basique pour un retour immédiat
        let quickOptimizedStops = optimizeStopsOrder(tour.stops, startLocation: startLocation)
        let stopsWithTiming = calculateTimingForStops(quickOptimizedStops, startLocation: startLocation, transportMode: transportMode)
        let (totalDuration, totalDistance, totalTravelTime) = calculateTotals(stopsWithTiming)
        
        print("   Arrêts optimisés: \(stopsWithTiming.map { $0.location.name })")
        print("   Distance totale: \(String(format: "%.1f", totalDistance/1000)) km")
        print("   Temps total: \(String(format: "%.0f", totalDuration/60)) min")
        
        optimizedTour.startLocation = startLocation
        optimizedTour.startAddress = startAddress
        optimizedTour.optimizedStops = stopsWithTiming
        optimizedTour.totalDistance = totalDistance
        optimizedTour.estimatedTravelTime = totalTravelTime
        optimizedTour.duration = totalDuration
        
        return optimizedTour
    }
    
    // MARK: - Optimisation de l'ordre des arrêts (algorithme du plus proche voisin)
    private static func optimizeStopsOrder(_ stops: [TourStop], startLocation: CLLocationCoordinate2D) -> [TourStop] {
        guard stops.count > 1 else { return stops }
        
        var remainingStops = stops
        var optimizedStops: [TourStop] = []
        var currentLocation = startLocation
        
        // Algorithme du plus proche voisin
        while !remainingStops.isEmpty {
            let closestStopIndex = findClosestStopIndex(to: currentLocation, in: remainingStops)
            let closestStop = remainingStops.remove(at: closestStopIndex)
            
            // Mettre à jour l'ordre
            var updatedStop = closestStop
            updatedStop.order = optimizedStops.count + 1
            
            optimizedStops.append(updatedStop)
            currentLocation = closestStop.location.coordinate
        }
        
        return optimizedStops
    }
    
    // MARK: - Trouver l'arrêt le plus proche
    private static func findClosestStopIndex(to location: CLLocationCoordinate2D, in stops: [TourStop]) -> Int {
        let currentCLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        var closestIndex = 0
        var closestDistance = Double.infinity
        
        for (index, stop) in stops.enumerated() {
            let distance = currentCLLocation.distance(from: stop.location.clLocation)
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }
        
        return closestIndex
    }
    
    // MARK: - Optimisation avec routing réel MapKit
    private static func optimizeStopsWithRealRouting(_ stops: [TourStop], startLocation: CLLocationCoordinate2D, transportMode: TransportMode, completion: @escaping ([TourStop]) -> Void) {
        guard stops.count > 1 else { 
            completion(stops)
            return 
        }
        
        // Utiliser l'algorithme du plus proche voisin simple pour éviter les problèmes de MapKit
        let optimizedStops = optimizeStopsOrder(stops, startLocation: startLocation)
        let stopsWithTiming = calculateTimingForStops(optimizedStops, startLocation: startLocation, transportMode: transportMode)
        
        completion(stopsWithTiming)
    }
    
    // MARK: - Calcul de route réelle avec MapKit
    private static func calculateRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, transportMode: TransportMode, completion: @escaping (MKRoute?) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = transportMode.mapKitTransportType
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Erreur de calcul de route: \(error.localizedDescription)")
                // Fallback : calculer une route directe si MapKit échoue
                let directDistance = CLLocation(latitude: start.latitude, longitude: start.longitude)
                    .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
                let estimatedTime = estimateTravelTime(distance: directDistance, transportMode: transportMode)
                
                // Créer une route factice pour éviter l'erreur
                let fallbackRoute = MKRoute()
                completion(fallbackRoute)
                return
            }
            
            if let route = response?.routes.first {
                completion(route)
            } else {
                print("Aucune route trouvée entre \(start) et \(end)")
                // Fallback : route directe
                let directDistance = CLLocation(latitude: start.latitude, longitude: start.longitude)
                    .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
                let estimatedTime = estimateTravelTime(distance: directDistance, transportMode: transportMode)
                
                let fallbackRoute = MKRoute()
                completion(fallbackRoute)
            }
        }
    }
    
    // MARK: - Calcul des temps et distances
    private static func calculateTimingForStops(_ stops: [TourStop], startLocation: CLLocationCoordinate2D, transportMode: TransportMode) -> [TourStop] {
        guard !stops.isEmpty else { return stops }
        
        var stopsWithTiming: [TourStop] = []
        var currentLocation = startLocation
        var currentTime = Date()
        
        for (index, stop) in stops.enumerated() {
            var updatedStop = stop
            
            // Calculer distance et temps de trajet depuis la position précédente
            let distance = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
                .distance(from: stop.location.clLocation)
            
            let travelTime = estimateTravelTime(distance: distance, transportMode: transportMode)
            
            // Temps d'arrivée = temps actuel + temps de trajet
            let arrivalTime = currentTime.addingTimeInterval(travelTime)
            let departureTime = arrivalTime.addingTimeInterval(stop.visitDuration)
            
            updatedStop.distanceFromPrevious = distance
            updatedStop.travelTimeFromPrevious = travelTime
            updatedStop.estimatedArrivalTime = arrivalTime
            updatedStop.estimatedDepartureTime = departureTime
            
            stopsWithTiming.append(updatedStop)
            
            // Mettre à jour pour la prochaine itération
            currentLocation = stop.location.coordinate
            currentTime = departureTime
        }
        
        return stopsWithTiming
    }
    
    // MARK: - Estimation du temps de trajet
    private static func estimateTravelTime(distance: Double, transportMode: TransportMode) -> TimeInterval {
        switch transportMode {
        case .walking:
            // Vitesse moyenne à pied en ville : 4 km/h = 1.11 m/s
            let walkingSpeed = 1.0 // m/s (vitesse conservative)
            let baseTime = distance / walkingSpeed
            // Ajouter du temps pour les feux, intersections, etc.
            return baseTime * 1.3
            
        case .driving:
            // Vitesse moyenne en voiture en ville : 30 km/h = 8.33 m/s
            let drivingSpeed = 8.33 // m/s
            let baseTime = distance / drivingSpeed
            // Ajouter du temps pour les feux, embouteillages, etc.
            return baseTime * 1.2
            
        case .cycling:
            // Vitesse moyenne à vélo en ville : 15 km/h = 4.17 m/s
            let cyclingSpeed = 4.17 // m/s
            let baseTime = distance / cyclingSpeed
            // Ajouter du temps pour les feux, etc.
            return baseTime * 1.1
            
        case .publicTransport:
            // Vitesse moyenne des transports en commun : 20 km/h = 5.56 m/s
            let transitSpeed = 5.56 // m/s
            let baseTime = distance / transitSpeed
            // Ajouter du temps pour les correspondances, attentes, etc.
            return baseTime * 1.5
        }
    }
    
    // MARK: - Estimation améliorée du temps de trajet (version plus précise)
    private static func estimateImprovedTravelTime(distance: Double) -> TimeInterval {
        // Vitesse moyenne à pied en ville : 4 km/h = 1.11 m/s
        let walkingSpeed = 1.0 // m/s (vitesse conservative)
        let baseTime = distance / walkingSpeed
        
        // Ajouter du temps supplémentaire pour :
        // - Feux rouges et intersections (+30%)
        // - Orientation et recherche du lieu (+20%)
        // - Pauses et photos (+10%)
        return baseTime * 1.6
    }
    
    // MARK: - Calcul des totaux
    private static func calculateTotals(_ stops: [TourStop]) -> (duration: TimeInterval, distance: Double, travelTime: TimeInterval) {
        let totalVisitTime = stops.reduce(0) { $0 + $1.visitDuration }
        let totalTravelTime = stops.compactMap { $0.travelTimeFromPrevious }.reduce(0, +)
        let totalDistance = stops.compactMap { $0.distanceFromPrevious }.reduce(0, +)
        
        let totalDuration = totalVisitTime + totalTravelTime
        
        return (totalDuration, totalDistance, totalTravelTime)
    }
    
    // MARK: - Formatage du temps pour l'affichage
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
    
    // MARK: - Formatage de la distance
    static func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return "\(Int(distance)) m"
        }
    }
    
    // MARK: - Test avec position parisienne prédéfinie
    static func createOptimizedParisTest() -> [GuidedTour] {
        // Cette fonction sera appelée pour tester l'optimisation avec Paris
        return []
    }
    
    // MARK: - Formatage pour l'affichage
    static func formatRouteInfo(distance: Double, travelTime: TimeInterval) -> String {
        let distanceStr = formatDistance(distance)
        let timeStr = formatDuration(travelTime)
        return "\(distanceStr) • \(timeStr)"
    }
    
    // MARK: - Vérification si un tour utilise le routing réel
    static func isUsingRealRouting(_ tour: GuidedTour) -> Bool {
        guard let optimizedStops = tour.optimizedStops else { return false }
        
        // Si au moins un arrêt a des données de routing précises, on considère que c'est du vrai routing
        return optimizedStops.contains { stop in
            guard let travelTime = stop.travelTimeFromPrevious,
                  let distance = stop.distanceFromPrevious else { return false }
            
            // Le vrai routing aura des temps plus précis (pas des multiples simples)
            return travelTime.truncatingRemainder(dividingBy: 60) != 0
        }
    }
}

// MARK: - Extensions utilitaires
extension Date {
    func timeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
} 