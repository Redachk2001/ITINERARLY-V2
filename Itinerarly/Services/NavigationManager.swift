import Foundation
import MapKit
import CoreLocation
import Combine

class NavigationManager: NSObject, ObservableObject {
    @Published var currentDirections: MKDirections.Response?
    @Published var currentInstruction: String?
    @Published var nextInstruction: String?
    @Published var distanceToNextStep: Double?
    @Published var estimatedTimeToDestination: TimeInterval?
    @Published var isNavigating = false
    
    private var currentRoute: MKRoute?
    private var routeSteps: [MKRoute.Step] = []
    private var currentStepIndex = 0
    private var destination: Location?
    
    // Calcul des directions vers une destination
    func calculateDirections(to destination: Location, from userLocation: CLLocation?) {
        self.destination = destination
        
        guard let userLocation = userLocation else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        request.requestsAlternateRoutes = false
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur calcul directions: \(error.localizedDescription)")
                    return
                }
                
                guard let response = response,
                      let route = response.routes.first else {
                    print("❌ Aucune route trouvée")
                    return
                }
                
                self?.currentDirections = response
                self?.currentRoute = route
                self?.routeSteps = route.steps
                self?.currentStepIndex = 0
                self?.isNavigating = true
                
                self?.updateNavigationInstructions()
                
                print("✅ Route calculée: \(route.steps.count) étapes, \(String(format: "%.1f", route.distance/1000))km")
            }
        }
    }
    
    // Mise à jour des instructions selon la position
    func updateInstructions(for userLocation: CLLocation) {
        guard isNavigating,
              let route = currentRoute,
              !routeSteps.isEmpty else { return }
        
        // Trouver l'étape actuelle
        let currentStep = routeSteps[currentStepIndex]
        let distanceToStep = userLocation.distance(from: CLLocation(
            latitude: currentStep.polyline.coordinate.latitude,
            longitude: currentStep.polyline.coordinate.longitude
        ))
        
        // Si on est proche de l'étape suivante, passer à l'étape suivante
        if distanceToStep < 50 && currentStepIndex < routeSteps.count - 1 {
            currentStepIndex += 1
            updateNavigationInstructions()
        } else {
            // Mettre à jour la distance restante
            distanceToNextStep = distanceToStep
            
            // Calculer le temps estimé
            if let destination = destination {
                let distanceToDestination = userLocation.distance(from: destination.clLocation)
                estimatedTimeToDestination = estimateTime(for: distanceToDestination)
            }
        }
    }
    
    // Mettre à jour les instructions de navigation
    private func updateNavigationInstructions() {
        guard currentStepIndex < routeSteps.count else {
            // Arrivé à destination
            currentInstruction = "Vous êtes arrivé à destination"
            nextInstruction = nil
            distanceToNextStep = nil
            estimatedTimeToDestination = nil
            return
        }
        
        let currentStep = routeSteps[currentStepIndex]
        currentInstruction = formatInstruction(currentStep.instructions)
        
        // Prochaine instruction
        if currentStepIndex + 1 < routeSteps.count {
            let nextStep = routeSteps[currentStepIndex + 1]
            nextInstruction = formatInstruction(nextStep.instructions)
        } else {
            nextInstruction = "Arriver à destination"
        }
        
        // Distance jusqu'à la prochaine étape
        distanceToNextStep = currentStep.distance
    }
    
    // Formater les instructions pour l'affichage
    private func formatInstruction(_ instruction: String) -> String {
        var formatted = instruction
        
        // Remplacer les termes anglais par du français
        formatted = formatted.replacingOccurrences(of: "Turn left", with: "Tournez à gauche")
        formatted = formatted.replacingOccurrences(of: "Turn right", with: "Tournez à droite")
        formatted = formatted.replacingOccurrences(of: "Continue straight", with: "Continuez tout droit")
        formatted = formatted.replacingOccurrences(of: "Head", with: "Dirigez-vous")
        formatted = formatted.replacingOccurrences(of: "Arrive at", with: "Arrivez à")
        formatted = formatted.replacingOccurrences(of: "on the left", with: "sur la gauche")
        formatted = formatted.replacingOccurrences(of: "on the right", with: "sur la droite")
        
        return formatted.isEmpty ? "Continuez tout droit" : formatted
    }
    
    // Estimer le temps de trajet
    private func estimateTime(for distance: Double) -> TimeInterval {
        let speedKmH = 40.0 // Vitesse moyenne en ville
        let timeInHours = (distance / 1000.0) / speedKmH
        return timeInHours * 3600 // Convertir en secondes
    }
    
    // Terminer la navigation
    func completeNavigation() {
        currentDirections = nil
        currentRoute = nil
        routeSteps = []
        currentStepIndex = 0
        isNavigating = false
        currentInstruction = "Navigation terminée"
        nextInstruction = nil
        distanceToNextStep = nil
        estimatedTimeToDestination = nil
        destination = nil
    }
    
    // Obtenir des instructions détaillées pour le debug
    func getDetailedInstructions() -> [String] {
        guard let route = currentRoute else { return [] }
        
        return route.steps.enumerated().map { index, step in
            let status = index == currentStepIndex ? "➡️" : 
                        index < currentStepIndex ? "✅" : "⏳"
            return "\(status) Étape \(index + 1): \(step.instructions) (\(String(format: "%.0f", step.distance))m)"
        }
    }
}

// MARK: - Extensions pour la navigation avancée
extension NavigationManager {
    
    // Calculer une route alternative
    func calculateAlternativeRoute(to destination: Location, from userLocation: CLLocation?) {
        guard let userLocation = userLocation else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                if let response = response, response.routes.count > 1 {
                    // Utiliser la route alternative
                    let alternativeRoute = response.routes[1]
                    self?.currentRoute = alternativeRoute
                    self?.routeSteps = alternativeRoute.steps
                    self?.currentStepIndex = 0
                    self?.updateNavigationInstructions()
                    
                    print("✅ Route alternative calculée: \(alternativeRoute.steps.count) étapes")
                }
            }
        }
    }
    
    // Recalculer la route si nécessaire
    func recalculateIfNeeded(userLocation: CLLocation) {
        guard let destination = destination,
              let route = currentRoute else { return }
        
        // Vérifier si l'utilisateur s'est trop écarté de la route
        let distanceFromRoute = distanceFromCurrentRoute(userLocation: userLocation)
        
        if distanceFromRoute > 100 { // 100 mètres de tolérance
            print("🔄 Recalcul de la route nécessaire (écart: \(String(format: "%.0f", distanceFromRoute))m)")
            calculateDirections(to: destination, from: userLocation)
        }
    }
    
    // Calculer la distance par rapport à la route actuelle
    private func distanceFromCurrentRoute(userLocation: CLLocation) -> Double {
        guard let route = currentRoute else { return 0 }
        
        // Simplified calculation - in a real app, you'd use more sophisticated route matching
        let routeCoordinate = route.polyline.coordinate
        let routeLocation = CLLocation(latitude: routeCoordinate.latitude, longitude: routeCoordinate.longitude)
        
        return userLocation.distance(from: routeLocation)
    }
}

// MARK: - Navigation Audio Instructions
extension NavigationManager {
    
    // Déclencher les instructions vocales
    func speakInstruction() {
        guard let instruction = currentInstruction else { return }
        
        // Utiliser le service audio existant pour les instructions vocales
        // Cette partie pourrait être intégrée avec AudioService
        print("🔊 Instruction vocale: \(instruction)")
    }
    
    // Vérifier si une instruction vocale est nécessaire
    func shouldSpeakInstruction(for userLocation: CLLocation) -> Bool {
        guard let distance = distanceToNextStep else { return false }
        
        // Déclencher l'instruction à 200m, 100m, et 50m
        return distance <= 200 && distance > 150 ||
               distance <= 100 && distance > 80 ||
               distance <= 50 && distance > 30
    }
} 