import Foundation
import CoreLocation

// MARK: - Modèles de Transport Partagés
struct AccessibilityInfo: Codable {
    let isWheelchairAccessible: Bool
    let hasElevator: Bool
    let hasRamp: Bool
    let notes: String
}

struct RealTimeInfo: Codable {
    let isRealTime: Bool
    let delay: Int // en minutes
    let reliability: Int // pourcentage
}

enum TransportType: String, Codable, CaseIterable {
    case walking = "walking"
    case bus = "bus"
    case train = "train"
    case metro = "metro"
    case tram = "tram"
    case car = "car"
    case bicycle = "bicycle"
    
    var displayName: String {
        switch self {
        case .walking: return "Marche"
        case .bus: return "Bus"
        case .train: return "Train"
        case .metro: return "Métro"
        case .tram: return "Tram"
        case .car: return "Voiture"
        case .bicycle: return "Vélo"
        }
    }
    
    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .bus: return "bus"
        case .train: return "train.side.front.car"
        case .metro: return "tram"
        case .tram: return "tram"
        case .car: return "car"
        case .bicycle: return "bicycle"
        }
    }
}

struct RealTransitRoute: Identifiable, Codable {
    let id: String
    let steps: [RealTransitStep]
    let totalDistance: CLLocationDistance
    let totalDuration: TimeInterval
    let departureTime: Date
    let arrivalTime: Date
    let totalFare: Double
    let accessibility: AccessibilityInfo
    let realTimeInfo: RealTimeInfo
}

struct RealTransitStep: Identifiable, Codable {
    let id: String
    let instruction: String
    let distance: CLLocationDistance
    let duration: TimeInterval
    let transportType: TransportType
    let lineName: String?
    let departureTime: Date
    let arrivalTime: Date
    let startLocation: CLLocationCoordinate2D
    let endLocation: CLLocationCoordinate2D
}

struct PublicTransportRoute: Identifiable, Codable {
    let id: String
    let steps: [PublicTransportStep]
    let totalDistance: CLLocationDistance
    let totalDuration: TimeInterval
    let departureTime: Date
    let arrivalTime: Date
    let fare: Double
    let accessibility: AccessibilityInfo
}

struct PublicTransportStep: Identifiable, Codable {
    let id: String
    let instruction: String
    let distance: CLLocationDistance
    let duration: TimeInterval
    let transportType: TransportType
    let lineName: String?
    let departureTime: Date
    let arrivalTime: Date
}

struct TransitRoute: Identifiable, Codable {
    let id: String
    let steps: [TransitStep]
    let totalDistance: CLLocationDistance
    let totalDuration: TimeInterval
    let departureTime: Date
    let arrivalTime: Date
    let fare: Double
    let accessibility: AccessibilityInfo
}

struct TransitStep: Identifiable, Codable {
    let id: String
    let instruction: String
    let distance: CLLocationDistance
    let duration: TimeInterval
    let transportType: TransportType
    let lineName: String?
    let departureTime: Date
    let arrivalTime: Date
} 