import Foundation
import CoreLocation

// MARK: - Configuration des APIs
struct APIConfig {
    // MARK: - MapKit (Principal)
    static let useMapKit = true
    
    // MARK: - APIs Alternatives (Fallback)
    static let openTripPlannerURL = "https://api.opentripplanner.org"
    static let transitLandURL = "https://transit.land/api/v2"
    
    // MARK: - Configuration des Services
    static let maxSearchRadius = 50000.0 // 50km en mètres
    static let defaultSearchRadius = 10000.0 // 10km en mètres
    static let maxResultsPerCategory = 20
    
    // MARK: - Sélection du Service de Transport Public
    static func getBestTransitService() -> TransitServiceType {
        // Priorité: MapKit > OpenTripPlanner > TransitLand
        if hasMapKitAccess() {
            print("🗺️ APIConfig - MapKit disponible")
            return .mapKit
        } else if hasOpenTripPlannerAccess() {
            print("🌍 APIConfig - OpenTripPlanner disponible")
            return .openTripPlanner
        } else if hasTransitLandAccess() {
            print("🌍 APIConfig - TransitLand disponible")
            return .transitLand
        } else {
            print("⚠️ APIConfig - Aucun service de transport public disponible")
            return .mapKit // Fallback sur MapKit
        }
    }
    
    // MARK: - Vérification de l'accès aux services
    static func hasMapKitAccess() -> Bool {
        // MapKit est toujours disponible sur iOS
        return true
    }
    
    static func hasOpenTripPlannerAccess() -> Bool {
        // Vérifier si l'URL est accessible
        guard let url = URL(string: openTripPlannerURL) else { return false }
        return true // Simplifié pour l'exemple
    }
    
    static func hasTransitLandAccess() -> Bool {
        // Vérifier si l'URL est accessible
        guard let url = URL(string: transitLandURL) else { return false }
        return true // Simplifié pour l'exemple
    }
    
    // MARK: - Validation de la Configuration
    static func validateConfiguration() -> [String] {
        var issues: [String] = []
        
        // Vérifier MapKit (toujours disponible)
        if !hasMapKitAccess() {
            issues.append("MapKit non disponible")
        }
        
        // Vérifier les services de fallback
        if !hasOpenTripPlannerAccess() {
            issues.append("OpenTripPlanner non accessible")
        }
        
        if !hasTransitLandAccess() {
            issues.append("TransitLand non accessible")
        }
        
        return issues
    }
    
    // MARK: - Types de Services
    enum TransitServiceType: String, CaseIterable {
        case mapKit = "MapKit"
        case openTripPlanner = "OpenTripPlanner"
        case transitLand = "TransitLand"
        
        var displayName: String {
            switch self {
            case .mapKit: return "Apple Maps"
            case .openTripPlanner: return "OpenTripPlanner"
            case .transitLand: return "TransitLand"
            }
        }
        
        var reliabilityScore: Int {
            switch self {
            case .mapKit: return 95
            case .openTripPlanner: return 80
            case .transitLand: return 75
            }
        }
    }
    
    // MARK: - Documentation des APIs
    static let mapKitDocumentation = """
    MapKit est le service de cartographie natif d'Apple :
    1. Toujours disponible sur iOS
    2. Intégration native parfaite
    3. Données Apple Maps
    4. Pas de clé API requise
    5. Limites généreuses
    """
    
    static let openTripPlannerDocumentation = """
    Pour utiliser OpenTripPlanner :
    1. Service gratuit et open source
    2. Données GTFS publiques
    3. Pas de clé API requise
    4. Limites d'usage généreuses
    5. Documentation: https://docs.opentripplanner.org
    """
    
    static let transitLandDocumentation = """
    Pour utiliser TransitLand :
    1. Service gratuit pour usage basique
    2. Données de transport en temps réel
    3. Pas de clé API requise
    4. Limites d'usage généreuses
    5. Documentation: https://transit.land/documentation
    """
} 