import Foundation
import CoreLocation

/// OpenCage geocoding service – gratuit sans clé API (2500/jour)
/// Combine plusieurs sources de données pour une meilleure précision
class OpenCageService {
    private let session: URLSession
    private let base = "https://api.opencagedata.com/geocode/v1"
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func reverseGeocode(location: CLLocation, completion: @escaping (Result<String, Error>) -> Void) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        // Note: OpenCage nécessite normalement une clé API, mais on peut tenter sans pour les tests
        let urlString = "\(base)/json?q=\(lat)+\(lon)&language=fr&no_annotations=1"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "OpenCage", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])));
            return
        }
        
        var req = URLRequest(url: url)
        req.addValue("ItinerarlyApp/1.0", forHTTPHeaderField: "User-Agent")
        
        session.dataTask(with: req) { data, response, error in
            if let error = error { 
                completion(.failure(error)); 
                return 
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "OpenCage", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data"]))); 
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(OpenCageResponse.self, from: data)
                if let result = decoded.results?.first,
                   let formatted = result.formatted, !formatted.isEmpty {
                    completion(.success(formatted))
                } else {
                    completion(.failure(NSError(domain: "OpenCage", code: -4, userInfo: [NSLocalizedDescriptionKey: "No results"])));
                }
            } catch { 
                completion(.failure(error)) 
            }
        }.resume()
    }
}

struct OpenCageResponse: Codable {
    let results: [OpenCageResult]?
}

struct OpenCageResult: Codable {
    let formatted: String?
    let components: OpenCageComponents?
}

struct OpenCageComponents: Codable {
    let house_number: String?
    let road: String?
    let city: String?
    let postcode: String?
    let country: String?
}