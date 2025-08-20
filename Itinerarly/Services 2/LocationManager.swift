import Foundation
import CoreLocation
import Combine
import UIKit
import MapKit
import Contacts

class LocationManager: NSObject, ObservableObject {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()

    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0 // Mettre à jour seulement si on bouge de 5m
        
        // Récupérer le statut actuel sans demander d'autorisation
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocation() {
        locationManager.requestLocation()
    }
    
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func checkAndRequestLocationPermission() -> Bool {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            return false
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable location services in Settings."
            return false
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        @unknown default:
            return false
        }
    }
    
    func startUpdatingLocation() {
        isLoading = true
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        isLoading = false
    }
    
    func geocodeAddress(_ address: String, completion: @escaping (Result<CLLocation, Error>) -> Void) {
        let service = MultiAPIGeocodingService()
        service.geocodeAddressWithFallback(address) { result in
            switch result {
            case .success(let location):
                completion(.success(location))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func reverseGeocode(_ location: CLLocation, completion: @escaping (Result<String, Error>) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    let coordString = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
                    print("❌ Apple Maps failed: \(error)")
                    completion(.success(coordString))
                    return
                }
                guard let placemark = placemarks?.first else {
                    let coordString = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
                    completion(.success(coordString))
                    return
                }
                let address = self.appleDisplayAddress(from: placemark)
                completion(.success(address))
            }
        }
    }
    
    private func appleDisplayAddress(from placemark: CLPlacemark) -> String {
        var parts: [String] = []
        if let name = placemark.name, !name.isEmpty { parts.append(name) }
        if let postal = placemark.postalAddress {
            var formatted = CNPostalAddressFormatter.string(from: postal, style: .mailingAddress)
            formatted = formatted.replacingOccurrences(of: "\n", with: ", ")
            parts.append(formatted)
        } else {
            if let sub = placemark.subThoroughfare { parts.append(sub) }
            if let thr = placemark.thoroughfare { parts.append(thr) }
            if let city = placemark.locality { parts.append(city) }
            if let zip = placemark.postalCode { parts.append(zip) }
            if let country = placemark.country { parts.append(country) }
        }
        return parts.joined(separator: ", ")
    }
    
    // MARK: - Apple Plans helpers
    func appleMapsURLFor(coordinate: CLLocationCoordinate2D, label: String? = nil) -> URL? {
        var comps = URLComponents(string: "http://maps.apple.com/")
        let ll = String(format: "%.6f,%.6f", coordinate.latitude, coordinate.longitude)
        var items: [URLQueryItem] = [URLQueryItem(name: "ll", value: ll)]
        if let label = label, !label.isEmpty { items.append(URLQueryItem(name: "q", value: label)) }
        comps?.queryItems = items
        return comps?.url
    }
    
    func appleMapsURLForAddress(_ address: String) -> URL? {
        var comps = URLComponents(string: "http://maps.apple.com/")
        comps?.queryItems = [URLQueryItem(name: "q", value: address)]
        return comps?.url
    }
    
    func openInAppleMaps(coordinate: CLLocationCoordinate2D, label: String? = nil) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = label
        item.openInMaps(launchOptions: [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinate),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        ])
    }
    
    func openInAppleMaps(address: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address
        MKLocalSearch(request: request).start { response, _ in
            if let mapItem = response?.mapItems.first {
                mapItem.openInMaps(launchOptions: [
                    MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: mapItem.placemark.coordinate),
                    MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
                ])
            } else if let url = self.appleMapsURLForAddress(address) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    func openAppleMapsAtCurrentLocation() {
        MKMapItem.forCurrentLocation().openInMaps(launchOptions: nil)
    }
    
    func calculateDistance(from: CLLocation, to: CLLocation) -> Double {
        return from.distance(from: to) / 1000.0
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let bestLocation = locations.last else { return }
        DispatchQueue.main.async {
            self.location = bestLocation
            self.isLoading = false
            self.errorMessage = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 Erreur de localisation ignorée: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.errorMessage = nil
                self.isLoading = false
                self.startUpdatingLocation()
            case .denied, .restricted:
                self.errorMessage = "Accès à la localisation refusé. Veuillez activer les services de localisation dans les Réglages → Confidentialité et sécurité → Service de localisation."
                self.isLoading = false
                self.stopUpdatingLocation()
            case .notDetermined:
                self.errorMessage = nil
                self.isLoading = false
            @unknown default:
                self.errorMessage = "Statut d'autorisation inconnu"
                self.isLoading = false
            }
        }
    }
}

enum LocationError: LocalizedError {
    case geocodingFailed
    case reverseGeocodingFailed
    case locationNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .geocodingFailed:
            return "Failed to find location for the given address"
        case .reverseGeocodingFailed:
            return "Failed to get address for the given location"
        case .locationNotAvailable:
            return "Location services not available"
        }
    }
} 