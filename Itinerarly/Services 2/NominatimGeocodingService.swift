import Foundation
import CoreLocation

/// Nominatim (OpenStreetMap) geocoding service – no API key required.
/// Be mindful of rate limits; we set a custom User-Agent per guidelines.
class NominatimGeocodingService {
    private let session: URLSession
    private let base = "https://nominatim.openstreetmap.org"
    private let userAgent = "ItinerarlyApp/1.0 (contact: support@itinerarly.app)"
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func reverseGeocode(location: CLLocation, completion: @escaping (Result<String, Error>) -> Void) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let urlString = "\(base)/reverse?lat=\(lat)&lon=\(lon)&format=jsonv2&addressdetails=1&accept-language=fr"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Nominatim", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])));
            return
        }
        var req = URLRequest(url: url)
        req.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        session.dataTask(with: req) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else {
                completion(.failure(NSError(domain: "Nominatim", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data"]))); return
            }
            do {
                let decoded = try JSONDecoder().decode(NominatimReverseResponse.self, from: data)
                if let display = decoded.display_name, !display.isEmpty {
                    completion(.success(display))
                } else {
                    completion(.failure(NSError(domain: "Nominatim", code: -4, userInfo: [NSLocalizedDescriptionKey: "No results"])));
                }
            } catch { completion(.failure(error)) }
        }.resume()
    }
    
    func geocode(address: String, completion: @escaping (Result<CLLocation, Error>) -> Void) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        let urlString = "\(base)/search?q=\(encoded)&format=json&limit=1"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Nominatim", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])));
            return
        }
        var req = URLRequest(url: url)
        req.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        session.dataTask(with: req) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else {
                completion(.failure(NSError(domain: "Nominatim", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data"]))); return
            }
            do {
                let results = try JSONDecoder().decode([NominatimSearchResult].self, from: data)
                if let first = results.first,
                   let lat = Double(first.lat), let lon = Double(first.lon) {
                    completion(.success(CLLocation(latitude: lat, longitude: lon)))
                } else {
                    completion(.failure(NSError(domain: "Nominatim", code: -4, userInfo: [NSLocalizedDescriptionKey: "No results"])));
                }
            } catch { completion(.failure(error)) }
        }.resume()
    }
}

// MARK: - DTOs
struct NominatimReverseResponse: Codable {
    let display_name: String?
}

struct NominatimSearchResult: Codable {
    let lat: String
    let lon: String
    let display_name: String?
}

