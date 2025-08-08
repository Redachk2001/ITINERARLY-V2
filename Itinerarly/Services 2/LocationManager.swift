import Foundation
import CoreLocation
import Combine

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
        
        // Récupérer le statut actuel avant de demander une autorisation
        authorizationStatus = locationManager.authorizationStatus
        
        // Ne demander l'autorisation que si elle n'est pas encore déterminée
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func requestLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            errorMessage = "Location access denied. Please enable location services in Settings."
            return
        }
        
        isLoading = true
        errorMessage = nil
        locationManager.requestLocation()
        
        // Timeout de 10 secondes pour requestLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if self.isLoading {
                self.isLoading = false
                self.errorMessage = "Timeout: Unable to get location within 10 seconds"
            }
        }
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
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            errorMessage = "Location access denied. Please enable location services in Settings."
            return
        }
        
        isLoading = true
        errorMessage = nil
        locationManager.startUpdatingLocation()
        
        // Timeout de 15 secondes pour startUpdatingLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if self.isLoading {
                self.stopUpdatingLocation()
                self.errorMessage = "Timeout: Unable to get precise location within 15 seconds"
            }
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        isLoading = false
    }
    
    func geocodeAddress(_ address: String, completion: @escaping (Result<CLLocation, Error>) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                completion(.failure(LocationError.geocodingFailed))
                return
            }
            
            completion(.success(location))
        }
    }
    
    func reverseGeocode(_ location: CLLocation, completion: @escaping (Result<String, Error>) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let placemark = placemarks?.first else {
                completion(.failure(LocationError.reverseGeocodingFailed))
                return
            }
            
            // Essayer de construire une adresse complète
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
            if let postalCode = placemark.postalCode {
                addressComponents.append(postalCode)
            }
            
            let fullAddress = addressComponents.joined(separator: ", ")
            
            if !fullAddress.isEmpty {
                completion(.success(fullAddress))
            } else if let name = placemark.name, !name.isEmpty {
                completion(.success(name))
            } else if let areasOfInterest = placemark.areasOfInterest?.first {
                completion(.success(areasOfInterest))
            } else {
                let coordString = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
                completion(.success(coordString))
            }
        }
    }
    
    func calculateDistance(from: CLLocation, to: CLLocation) -> Double {
        return from.distance(from: to) / 1000.0 // Convert to kilometers
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.location = location
            self.isLoading = false
            self.errorMessage = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = "Failed to get location: \(error.localizedDescription)"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.errorMessage = nil
                self.isLoading = false
                
            case .denied, .restricted:
                self.errorMessage = "Location access denied. Please enable location services in Settings."
                self.isLoading = false
                
            case .notDetermined:
                break
                
            @unknown default:
                break
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