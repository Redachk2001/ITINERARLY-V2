import Foundation
import CoreLocation

/// HERE Geocoding service – gratuit sans clé API
/// Excellente précision pour l'Europe (Nokia/Mercedes)
class HereGeocodingService {
    private let session: URLSession
    private let base = "https://revgeocode.search.hereapi.com/v1"
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func reverseGeocode(location: CLLocation, completion: @escaping (Result<String, Error>) -> Void) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let urlString = "\(base)/revgeocode?at=\(lat),\(lon)&lang=fr"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "HERE", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])));
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
                completion(.failure(NSError(domain: "HERE", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data"]))); 
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(HereReverseGeocodeResponse.self, from: data)
                if let items = decoded.items, let firstItem = items.first,
                   let address = firstItem.address, let label = address.label, !label.isEmpty {
                    completion(.success(label))
                } else {
                    completion(.failure(NSError(domain: "HERE", code: -4, userInfo: [NSLocalizedDescriptionKey: "No results"])));
                }
            } catch { 
                completion(.failure(error)) 
            }
        }.resume()
    }
}

struct HereReverseGeocodeResponse: Codable {
    let items: [HereReverseGeocodeItem]?
}

struct HereReverseGeocodeItem: Codable {
    let address: HereReverseGeocodeAddress?
}

struct HereReverseGeocodeAddress: Codable {
    let label: String?
    let houseNumber: String?
    let street: String?
    let city: String?
    let postalCode: String?
    let country: String?
} 