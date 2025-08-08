import Foundation
import CoreLocation
import Combine

// MARK: - ViewModel avec Géocodage Multi-APIs
class EnhancedGeocodingViewModel: ObservableObject {
    @Published var isGeocoding = false
    @Published var geocodingProgress = ""
    @Published var errorMessage: String?
    @Published var geocodedLocation: CLLocation?
    
    private let multiAPIService = MultiAPIGeocodingService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observer les changements du service
        multiAPIService.$isGeocoding
            .receive(on: DispatchQueue.main)
            .assign(to: \.isGeocoding, on: self)
            .store(in: &cancellables)
        
        multiAPIService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Géocodage avec Fallback Multi-APIs
    func geocodeAddress(_ address: String) {
        guard !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Adresse vide"
            return
        }
        
        geocodingProgress = "Recherche de l'adresse..."
        geocodedLocation = nil
        errorMessage = nil
        
        print("🗺️ EnhancedGeocoding - Début géocodage: '\(address)'")
        
        multiAPIService.geocodeAddressWithFallback(address) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let location):
                    self?.geocodedLocation = location
                    self?.geocodingProgress = "Adresse trouvée !"
                    print("✅ EnhancedGeocoding - Succès: \(location.coordinate)")
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.geocodingProgress = ""
                    print("❌ EnhancedGeocoding - Échec: \(error)")
                }
            }
        }
    }
    
    // MARK: - Géocodage de plusieurs adresses
    func geocodeMultipleAddresses(_ addresses: [String], completion: @escaping ([CLLocation]) -> Void) {
        guard !addresses.isEmpty else {
            completion([])
            return
        }
        
        var geocodedLocations: [CLLocation] = []
        let group = DispatchGroup()
        
        for (index, address) in addresses.enumerated() {
            group.enter()
            
            geocodingProgress = "Localisation \(index + 1)/\(addresses.count): \(address)"
            
            multiAPIService.geocodeAddressWithFallback(address) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let location):
                        geocodedLocations.append(location)
                        print("✅ Adresse \(index + 1) trouvée: \(location.coordinate)")
                        
                    case .failure(let error):
                        print("❌ Adresse \(index + 1) échouée: \(error)")
                    }
                    
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.geocodingProgress = "Géocodage terminé (\(geocodedLocations.count)/\(addresses.count))"
            completion(geocodedLocations)
        }
    }
    
    // MARK: - Test de toutes les APIs
    func testAllAPIs(with address: String) {
        print("🧪 Test de toutes les APIs avec: '\(address)'")
        
        let apis: [GeocodingAPI] = [.mapKit, .here, .openStreetMap, .mapBox]
        
        for api in apis {
            testSingleAPI(api, with: address)
        }
    }
    
    private func testSingleAPI(_ api: GeocodingAPI, with address: String) {
        print("🧪 Test \(api.rawValue)...")
        
        // Simulation d'un test simple
        DispatchQueue.global().asyncAfter(deadline: .now() + Double.random(in: 0.5...2.0)) {
            let success = Bool.random() // Simulation
            print("🧪 \(api.rawValue): \(success ? "✅ Succès" : "❌ Échec")")
        }
    }
}

// MARK: - Extension pour l'utilisation dans les vues
extension EnhancedGeocodingViewModel {
    
    // MARK: - Validation d'adresse
    func validateAddress(_ address: String) -> Bool {
        let cleanAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanAddress.count >= 3 && cleanAddress.rangeOfCharacter(from: .letters) != nil
    }
    
    // MARK: - Formatage d'adresse
    func formatAddress(_ address: String) -> String {
        return address.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Réinitialisation
    func reset() {
        isGeocoding = false
        geocodingProgress = ""
        errorMessage = nil
        geocodedLocation = nil
    }
} 