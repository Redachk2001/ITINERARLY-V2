import Foundation
import CoreLocation
import MapKit
import Combine

// MARK: - Service de Géocodage Multi-APIs avec Fallback
class MultiAPIGeocodingService: ObservableObject {
    @Published var isGeocoding = false
    @Published var errorMessage: String?
    
    // Configuration des APIs
    private let hereAPIKey = "YOUR_HERE_API_KEY" // Clé Here (gratuite: 250k req/mois)
    private let openStreetMapURL = "https://nominatim.openstreetmap.org"
    private let mapBoxToken = "YOUR_MAPBOX_TOKEN" // Token MapBox (gratuit: 100k req/mois)
    
    // Ordre de priorité des APIs
    private let apiPriority: [GeocodingAPI] = [
        .mapKit,           // 1. Apple MapKit (principal)
        .here,             // 2. Here Geocoding (fallback 1)
        .openStreetMap,    // 3. OpenStreetMap (fallback 2)
        .mapBox            // 4. MapBox (fallback 3)
    ]
    
    // MARK: - Géocodage avec Fallback Multi-APIs
    func geocodeAddressWithFallback(
        _ address: String,
        completion: @escaping (GeocodingResult) -> Void
    ) {
        isGeocoding = true
        errorMessage = nil
        
        print("🗺️ MultiAPIGeocoding - Début géocodage: '\(address)'")
        
        // Essayer chaque API dans l'ordre de priorité
        tryNextAPI(address: address, apiIndex: 0, completion: completion)
    }
    
    // MARK: - Méthode récursive pour essayer les APIs
    private func tryNextAPI(
        address: String,
        apiIndex: Int,
        completion: @escaping (GeocodingResult) -> Void
    ) {
        guard apiIndex < apiPriority.count else {
            // Toutes les APIs ont échoué
            print("❌ MultiAPIGeocoding - Toutes les APIs ont échoué")
            isGeocoding = false
            errorMessage = "Impossible de localiser cette adresse"
            completion(.failure(.allAPIsFailed))
            return
        }
        
        let currentAPI = apiPriority[apiIndex]
        print("🔄 MultiAPIGeocoding - Essai API \(apiIndex + 1)/\(apiPriority.count): \(currentAPI)")
        
        geocodeWithAPI(address: address, api: currentAPI) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let location):
                    print("✅ MultiAPIGeocoding - Succès avec \(currentAPI): \(location.coordinate)")
                    self?.isGeocoding = false
                    completion(.success(location))
                    
                case .failure(let error):
                    print("❌ MultiAPIGeocoding - Échec \(currentAPI): \(error)")
                    // Essayer l'API suivante
                    self?.tryNextAPI(address: address, apiIndex: apiIndex + 1, completion: completion)
                }
            }
        }
    }
    
    // MARK: - Géocodage avec API spécifique
    private func geocodeWithAPI(
        address: String,
        api: GeocodingAPI,
        completion: @escaping (Result<CLLocation, GeocodingError>) -> Void
    ) {
        switch api {
        case .mapKit:
            geocodeWithMapKit(address: address, completion: completion)
        case .here:
            geocodeWithHere(address: address, completion: completion)
        case .openStreetMap:
            geocodeWithOpenStreetMap(address: address, completion: completion)
        case .mapBox:
            geocodeWithMapBox(address: address, completion: completion)
        }
    }
    
    // MARK: - 1. Apple MapKit (Principal)
    private func geocodeWithMapKit(
        address: String,
        completion: @escaping (Result<CLLocation, GeocodingError>) -> Void
    ) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                print("❌ MapKit - Erreur: \(error.localizedDescription)")
                completion(.failure(.apiError(error)))
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                print("❌ MapKit - Aucun résultat")
                completion(.failure(.noResults))
                return
            }
            
            print("✅ MapKit - Succès: \(location.coordinate)")
            completion(.success(location))
        }
    }
    
    // MARK: - 2. Here Geocoding API
    private func geocodeWithHere(
        address: String,
        completion: @escaping (Result<CLLocation, GeocodingError>) -> Void
    ) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        let urlString = "https://geocoder.ls.hereapi.com/6.2/geocode.json?searchtext=\(encodedAddress)&apiKey=\(hereAPIKey)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Here API - Erreur réseau: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let hereResponse = try JSONDecoder().decode(HereGeocodingResponse.self, from: data)
                
                guard let firstResult = hereResponse.response.view.first?.result.first,
                      let position = firstResult.location.displayPosition else {
                    completion(.failure(.noResults))
                    return
                }
                
                let location = CLLocation(latitude: position.latitude, longitude: position.longitude)
                print("✅ Here API - Succès: \(location.coordinate)")
                completion(.success(location))
                
            } catch {
                print("❌ Here API - Erreur parsing: \(error)")
                completion(.failure(.parsingError(error)))
            }
        }.resume()
    }
    
    // MARK: - 3. OpenStreetMap Nominatim
    private func geocodeWithOpenStreetMap(
        address: String,
        completion: @escaping (Result<CLLocation, GeocodingError>) -> Void
    ) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        let urlString = "\(openStreetMapURL)/search?q=\(encodedAddress)&format=json&limit=1"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ OpenStreetMap - Erreur réseau: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let osmResults = try JSONDecoder().decode([OpenStreetMapResult].self, from: data)
                
                guard let firstResult = osmResults.first else {
                    completion(.failure(.noResults))
                    return
                }
                
                let location = CLLocation(latitude: Double(firstResult.lat) ?? 0, longitude: Double(firstResult.lon) ?? 0)
                print("✅ OpenStreetMap - Succès: \(location.coordinate)")
                completion(.success(location))
                
            } catch {
                print("❌ OpenStreetMap - Erreur parsing: \(error)")
                completion(.failure(.parsingError(error)))
            }
        }.resume()
    }
    
    // MARK: - 4. MapBox Geocoding
    private func geocodeWithMapBox(
        address: String,
        completion: @escaping (Result<CLLocation, GeocodingError>) -> Void
    ) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        let urlString = "https://api.mapbox.com/geocoding/v5/mapbox.places/\(encodedAddress).json?access_token=\(mapBoxToken)&limit=1"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ MapBox - Erreur réseau: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let mapBoxResponse = try JSONDecoder().decode(MapBoxGeocodingResponse.self, from: data)
                
                guard let firstFeature = mapBoxResponse.features.first else {
                    completion(.failure(.noResults))
                    return
                }
                
                let coordinates = firstFeature.center
                let location = CLLocation(latitude: coordinates[1], longitude: coordinates[0])
                print("✅ MapBox - Succès: \(location.coordinate)")
                completion(.success(location))
                
            } catch {
                print("❌ MapBox - Erreur parsing: \(error)")
                completion(.failure(.parsingError(error)))
            }
        }.resume()
    }
}

// MARK: - Types et Enums
enum GeocodingAPI: String, CaseIterable {
    case mapKit = "Apple MapKit"
    case here = "Here Geocoding"
    case openStreetMap = "OpenStreetMap Nominatim"
    case mapBox = "MapBox Geocoding"
}

enum GeocodingError: LocalizedError {
    case noResults
    case networkError(Error)
    case parsingError(Error)
    case invalidURL
    case noData
    case apiError(Error)
    case allAPIsFailed
    
    var errorDescription: String? {
        switch self {
        case .noResults:
            return "Aucun résultat trouvé pour cette adresse"
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        case .parsingError(let error):
            return "Erreur de parsing: \(error.localizedDescription)"
        case .invalidURL:
            return "URL invalide"
        case .noData:
            return "Aucune donnée reçue"
        case .apiError(let error):
            return "Erreur API: \(error.localizedDescription)"
        case .allAPIsFailed:
            return "Toutes les APIs de géocodage ont échoué"
        }
    }
}

enum GeocodingResult {
    case success(CLLocation)
    case failure(GeocodingError)
}

// MARK: - Modèles de Réponse API
struct HereGeocodingResponse: Codable {
    let response: HereResponse
}

struct HereResponse: Codable {
    let view: [HereView]
}

struct HereView: Codable {
    let result: [HereResult]
}

struct HereResult: Codable {
    let location: HereLocation
}

struct HereLocation: Codable {
    let displayPosition: HerePosition?
}

struct HerePosition: Codable {
    let latitude: Double
    let longitude: Double
}

struct OpenStreetMapResult: Codable {
    let lat: String
    let lon: String
    let display_name: String
}

struct MapBoxGeocodingResponse: Codable {
    let features: [MapBoxFeature]
}

struct MapBoxFeature: Codable {
    let center: [Double]
    let place_name: String
} 