import Foundation
import CoreLocation

/// LocationIQ geocoding service – gratuit sans clé API (10k/jour)
/// Version optimisée de Nominatim avec de meilleures performances
class LocationIQService {
    private let session: URLSession
    private let base = "https://us1.locationiq.com/v1"
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func reverseGeocode(location: CLLocation, completion: @escaping (Result<String, Error>) -> Void) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let urlString = "\(base)/reverse.php?lat=\(lat)&lon=\(lon)&format=json&addressdetails=1&accept-language=fr"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "LocationIQ", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])));
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
                completion(.failure(NSError(domain: "LocationIQ", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data"]))); 
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(LocationIQResponse.self, from: data)
                if let display = decoded.display_name, !display.isEmpty {
                    completion(.success(display))
                } else {
                    completion(.failure(NSError(domain: "LocationIQ", code: -4, userInfo: [NSLocalizedDescriptionKey: "No results"])));
                }
            } catch { 
                completion(.failure(error)) 
            }
        }.resume()
    }
}

struct LocationIQResponse: Codable {
    let display_name: String?
    let address: LocationIQAddress?
}

struct LocationIQAddress: Codable {
    let house_number: String?
    let road: String?
    let city: String?
    let postcode: String?
    let country: String?
}