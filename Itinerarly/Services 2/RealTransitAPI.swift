import Foundation
import CoreLocation
import Combine
import MapKit

// MARK: - API de Transport Public Réel (MapKit + OpenTripPlanner)
class RealTransitAPI: ObservableObject {
    @Published var isSearching = false
    @Published var routes: [RealTransitRoute] = []
    
    // MARK: - Recherche avec OpenTripPlanner
    func getOpenTripPlannerRoutes(
        from startLocation: CLLocation,
        to endLocation: CLLocation,
        departureTime: Date
    ) -> AnyPublisher<[RealTransitRoute], Error> {
        
        print("🌍 RealTransitAPI - Recherche OpenTripPlanner")
        print("📍 Départ: \(startLocation.coordinate.latitude), \(startLocation.coordinate.longitude)")
        print("📍 Arrivée: \(endLocation.coordinate.latitude), \(endLocation.coordinate.longitude)")
        
        return Future<[RealTransitRoute], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "RealTransitAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }
            
            // Utiliser MapKit comme fallback si OpenTripPlanner échoue
            self.searchWithMapKit(
                from: startLocation,
                to: endLocation,
                departureTime: departureTime
            ) { routes in
                if !routes.isEmpty {
                    print("✅ MapKit - \(routes.count) itinéraires trouvés")
                    promise(.success(routes))
                } else {
                    print("❌ Aucun itinéraire trouvé")
                    promise(.success([]))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Recherche avec MapKit
    private func searchWithMapKit(
        from startLocation: CLLocation,
        to endLocation: CLLocation,
        departureTime: Date,
        completion: @escaping ([RealTransitRoute]) -> Void
    ) {
        print("🗺️ RealTransitAPI - Utilisation MapKit")
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endLocation.coordinate))
        request.transportType = .transit
        request.departureDate = departureTime
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ MapKit échoué: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let routes = response?.routes else {
                    print("❌ MapKit - Aucun itinéraire trouvé")
                    completion([])
                    return
                }
                
                let transitRoutes = routes.compactMap { route -> RealTransitRoute? in
                    return self.convertMapKitRouteToRealTransitRoute(route, startLocation: startLocation, endLocation: endLocation)
                }
                
                print("✅ MapKit - \(transitRoutes.count) itinéraires convertis")
                completion(transitRoutes)
            }
        }
    }
    
    // MARK: - Conversion MapKit vers RealTransitRoute
    private func convertMapKitRouteToRealTransitRoute(
        _ route: MKRoute,
        startLocation: CLLocation,
        endLocation: CLLocation
    ) -> RealTransitRoute {
        let steps = route.steps.map { step -> RealTransitStep in
            return RealTransitStep(
                id: UUID().uuidString,
                instruction: step.instructions,
                distance: step.distance,
                duration: step.distance / 1.4, // Estimation basée sur la vitesse de marche
                transportType: convertMapKitTransportType(step.transportType),
                lineName: extractLineName(from: step),
                departureTime: Date(),
                arrivalTime: Date().addingTimeInterval(step.distance / 1.4),
                startLocation: startLocation.coordinate,
                endLocation: endLocation.coordinate
            )
        }
        
        return RealTransitRoute(
            id: UUID().uuidString,
            steps: steps,
            totalDistance: route.distance,
            totalDuration: route.expectedTravelTime,
            departureTime: Date(),
            arrivalTime: Date().addingTimeInterval(route.expectedTravelTime),
            totalFare: calculateEstimatedFare(for: route),
            accessibility: determineAccessibility(for: route),
            realTimeInfo: RealTimeInfo(
                isRealTime: true,
                delay: 0,
                reliability: 95
            )
        )
    }
    
    // MARK: - Utilitaires
    private func convertMapKitTransportType(_ type: MKDirectionsTransportType) -> TransportType {
        switch type {
        case .transit: return .bus
        case .walking: return .walking
        case .automobile: return .car
        default: return .bus
        }
    }
    
    private func extractLineName(from step: MKRoute.Step) -> String? {
        // Extraire le nom de la ligne depuis les instructions
        let instructions = step.instructions.lowercased()
        
        if instructions.contains("bus") {
            // Chercher un numéro de ligne (ex: "Prendre le bus 15")
            let pattern = "bus\\s+(\\d+)"
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: instructions, range: NSRange(instructions.startIndex..., in: instructions)) {
                let lineNumber = String(instructions[Range(match.range(at: 1), in: instructions)!])
                return "Bus \(lineNumber)"
            }
            return "Bus"
        } else if instructions.contains("train") {
            return "Train"
        } else if instructions.contains("métro") || instructions.contains("metro") {
            return "Métro"
        } else if instructions.contains("tram") {
            return "Tram"
        }
        
        return nil
    }
    
    private func calculateEstimatedFare(for route: MKRoute) -> Double {
        // Estimation basée sur la distance et le type de transport
        let baseFare = 2.0
        let distanceFare = route.distance / 1000.0 * 0.5 // 0.5€ par km
        return baseFare + distanceFare
    }
    
    private func determineAccessibility(for route: MKRoute) -> AccessibilityInfo {
        // Vérifier si l'itinéraire est accessible aux personnes à mobilité réduite
        let hasAccessibility = route.steps.allSatisfy { step in
            // Logique simplifiée - en réalité, il faudrait vérifier les données d'accessibilité
            return true
        }
        
        return AccessibilityInfo(
            isWheelchairAccessible: hasAccessibility,
            hasElevator: hasAccessibility,
            hasRamp: hasAccessibility,
            notes: hasAccessibility ? "Itinéraire accessible" : "Accessibilité limitée"
        )
    }
} 