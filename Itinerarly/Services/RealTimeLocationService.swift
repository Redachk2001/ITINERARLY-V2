import Foundation
import CoreLocation
import Combine
import UIKit

class RealTimeLocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocation?
    @Published var heading: CLHeading?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationAccuracy: CLLocationAccuracy = 0
    @Published var isTracking = false
    
    private let locationManager = CLLocationManager()
    private let minimumDistance: CLLocationDistance = 5.0 // 5 mètres minimum
    private let maximumAge: TimeInterval = 10.0 // 10 secondes maximum
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = minimumDistance
        
        // Configuration pour la navigation
        if #available(iOS 14.0, *) {
            locationManager.activityType = .automotiveNavigation
        }
        
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func startTracking() {
        switch authorizationStatus {
        case .notDetermined:
            requestLocationPermission()
            return
        case .denied, .restricted:
            // Demander à l'utilisateur d'aller dans les réglages
            return
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            return
        }
        
        isTracking = true
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        // Configuration optimale pour la navigation
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 3.0 // Mise à jour tous les 3 mètres
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filtrer les anciennes locations
        let locationAge = -location.timestamp.timeIntervalSinceNow
        if locationAge > maximumAge {
            return
        }
        
        // Filtrer les locations imprécises
        if location.horizontalAccuracy > 50 {
            return
        }
        
        DispatchQueue.main.async {
            self.currentLocation = location
            self.locationAccuracy = location.horizontalAccuracy
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.heading = newHeading
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                if self.isTracking {
                    self.startTracking()
                }
            } else if status == .denied || status == .restricted {
                self.stopTracking()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}

// MARK: - Extensions pour la navigation
extension RealTimeLocationService {
    
    var isLocationAvailable: Bool {
        return currentLocation != nil && (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways)
    }
    
    var locationStatusText: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Appuyez pour autoriser la localisation"
        case .denied, .restricted:
            return "Ouvrir Réglages → Confidentialité → Localisation"
        case .authorizedWhenInUse, .authorizedAlways:
            if let accuracy = currentLocation?.horizontalAccuracy {
                if accuracy < 5 {
                    return "🟢 GPS haute précision (\(Int(accuracy))m)"
                } else if accuracy < 20 {
                    return "🟡 GPS précis (\(Int(accuracy))m)"
                } else {
                    return "🟠 GPS approximatif (\(Int(accuracy))m)"
                }
            } else {
                return "🔍 Recherche du signal GPS..."
            }
        @unknown default:
            return "❓ Statut GPS inconnu"
        }
    }
    
    func openLocationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
    
    func calculateDistanceFromRoute(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let currentLocation = currentLocation else { return nil }
        
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return currentLocation.distance(from: targetLocation)
    }
    
    func calculateBearing(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let currentLocation = currentLocation else { return nil }
        
        let lat1 = currentLocation.coordinate.latitude * .pi / 180
        let lat2 = coordinate.latitude * .pi / 180
        let deltaLon = (coordinate.longitude - currentLocation.coordinate.longitude) * .pi / 180
        
        let x = sin(deltaLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        let bearing = atan2(x, y) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
} 