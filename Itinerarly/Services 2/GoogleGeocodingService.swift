import Foundation
import CoreLocation

/// Service léger pour consommer l'API Google Geocoding (forward et reverse)
/// Nécessite la clé `GOOGLE_MAPS_API_KEY` dans Info.plist
class GoogleGeocodingService {
    private let session: URLSession
    private let apiKey: String?
    
    init(session: URLSession = .shared) {
        self.session = session
        self.apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String
    }
    
    // Reverse geocoding: coords -> adresse lisible
    func reverseGeocode(location: CLLocation, completion: @escaping (Result<String, Error>) -> Void) {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "GoogleGeocoding", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing GOOGLE_MAPS_API_KEY"])));
            return
        }
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let urlString = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(lat),\(lon)&key=\(apiKey)&language=fr"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "GoogleGeocoding", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])));
            return
        }
        session.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error)); return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "GoogleGeocoding", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data"])));
                return
            }
            do {
                let decoded = try JSONDecoder().decode(GoogleGeocodeResponse.self, from: data)
                if let first = decoded.results.first, !first.formatted_address.isEmpty {
                    completion(.success(first.formatted_address))
                } else {
                    completion(.failure(NSError(domain: "GoogleGeocoding", code: -4, userInfo: [NSLocalizedDescriptionKey: "No results"])));
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Forward geocoding: adresse -> CLLocation
    func geocode(address: String, completion: @escaping (Result<CLLocation, Error>) -> Void) {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "GoogleGeocoding", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing GOOGLE_MAPS_API_KEY"])));
            return
        }
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        let urlString = "https://maps.googleapis.com/maps/api/geocode/json?address=\(encoded)&key=\(apiKey)&language=fr"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "GoogleGeocoding", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])));
            return
        }
        session.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error)); return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "GoogleGeocoding", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data"])));
                return
            }
            do {
                let decoded = try JSONDecoder().decode(GoogleGeocodeResponse.self, from: data)
                if let first = decoded.results.first, first.geometry.location.lat != 0 || first.geometry.location.lng != 0 {
                    let loc = CLLocation(latitude: first.geometry.location.lat, longitude: first.geometry.location.lng)
                    completion(.success(loc))
                } else {
                    completion(.failure(NSError(domain: "GoogleGeocoding", code: -4, userInfo: [NSLocalizedDescriptionKey: "No results"])));
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - DTOs
struct GoogleGeocodeResponse: Codable {
    let results: [GoogleGeocodeResult]
    let status: String
}

struct GoogleGeocodeResult: Codable {
    let formatted_address: String
    let geometry: GoogleGeometry
}

struct GoogleGeometry: Codable {
    let location: GoogleLatLng
}

struct GoogleLatLng: Codable {
    let lat: Double
    let lng: Double
}

