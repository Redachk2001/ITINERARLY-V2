import Foundation
import MapKit
import CoreLocation
import Combine

class TourRouteService: ObservableObject {
    @Published var routePolylines: [MKPolyline] = []
    @Published var routeSteps: [MKRoute.Step] = []
    @Published var totalDistance: Double = 0
    @Published var totalDuration: TimeInterval = 0
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func calculateRouteForTour(_ tour: GuidedTour) {
        isLoading = true
        error = nil
        
        let stops = tour.optimizedStops ?? tour.stops
        guard !stops.isEmpty else {
            error = "Aucun arrêt dans ce tour"
            isLoading = false
            return
        }
        
        // Utiliser le startLocation du tour ou le premier arrêt comme point de départ
        let startLocation = tour.startLocation ?? stops.first!.location.coordinate
        
        // Si tous les arrêts sont au même endroit, afficher une erreur claire
        let uniqueCoords = Set(stops.map { "\($0.location.latitude),\($0.location.longitude)" })
        if uniqueCoords.count < 2 {
            error = "Impossible de calculer un itinéraire : tous les arrêts sont au même endroit."
            isLoading = false
            return
        }
        
        calculateCompleteRoute(
            start: startLocation,
            stops: stops.map { $0.location.coordinate }
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let routeData):
                    self?.routePolylines = routeData.polylines
                    self?.routeSteps = routeData.steps
                    self?.totalDistance = routeData.totalDistance
                    self?.totalDuration = routeData.totalDuration
                case .failure(let error):
                    self?.error = "Directions Not Available : " + error.localizedDescription
                }
            }
        }
    }
    
    private func calculateCompleteRoute(
        start: CLLocationCoordinate2D,
        stops: [CLLocationCoordinate2D],
        completion: @escaping (Result<RouteData, Error>) -> Void
    ) {
        var allPolylines: [MKPolyline] = []
        var allSteps: [MKRoute.Step] = []
        var totalDistance: Double = 0
        var totalDuration: TimeInterval = 0
        
        let dispatchGroup = DispatchGroup()
        var hasError = false
        var lastError: Error?
        
        // Calculer l'itinéraire du point de départ au premier arrêt
        if let firstStop = stops.first {
            dispatchGroup.enter()
            calculateRouteSegment(from: start, to: firstStop) { result in
                defer { dispatchGroup.leave() }
                
                switch result {
                case .success(let segment):
                    allPolylines.append(segment.polyline)
                    allSteps.append(contentsOf: segment.steps)
                    totalDistance += segment.distance
                    totalDuration += segment.duration
                    
                case .failure(let error):
                    hasError = true
                    lastError = error
                }
            }
        }
        
        // Calculer les itinéraires entre les arrêts
        for i in 0..<stops.count - 1 {
            let from = stops[i]
            let to = stops[i + 1]
            
            dispatchGroup.enter()
            calculateRouteSegment(from: from, to: to) { result in
                defer { dispatchGroup.leave() }
                
                switch result {
                case .success(let segment):
                    allPolylines.append(segment.polyline)
                    allSteps.append(contentsOf: segment.steps)
                    totalDistance += segment.distance
                    totalDuration += segment.duration
                    
                case .failure(let error):
                    hasError = true
                    lastError = error
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if hasError {
                completion(.failure(lastError ?? NSError(domain: "TourRouteService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Erreur lors du calcul de l'itinéraire"])))
            } else {
                let routeData = RouteData(
                    polylines: allPolylines,
                    steps: allSteps,
                    totalDistance: totalDistance,
                    totalDuration: totalDuration
                )
                completion(.success(routeData))
            }
        }
    }
    
    private func calculateRouteSegment(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        completion: @escaping (Result<RouteSegment, Error>) -> Void
    ) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = .walking // Pour les tours guidés à pied
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let response = response,
                  let route = response.routes.first else {
                completion(.failure(NSError(domain: "TourRouteService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Aucun itinéraire trouvé"])))
                return
            }
            
            let segment = RouteSegment(
                polyline: route.polyline,
                steps: route.steps,
                distance: route.distance,
                duration: route.expectedTravelTime
            )
            
            completion(.success(segment))
        }
    }
    
    func clearRoute() {
        routePolylines.removeAll()
        routeSteps.removeAll()
        totalDistance = 0
        totalDuration = 0
        error = nil
    }
}

// MARK: - Data Models
struct RouteData {
    let polylines: [MKPolyline]
    let steps: [MKRoute.Step]
    let totalDistance: Double
    let totalDuration: TimeInterval
}

struct RouteSegment {
    let polyline: MKPolyline
    let steps: [MKRoute.Step]
    let distance: Double
    let duration: TimeInterval
} 