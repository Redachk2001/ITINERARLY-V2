import Foundation
import CoreLocation
import MapKit

struct Location: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let category: LocationCategory
    let description: String?
    let imageURL: String?
    let rating: Double?
    let openingHours: String?
    let recommendedDuration: TimeInterval?
    let visitTips: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, latitude, longitude, category, description, rating
        case imageURL = "image_url"
        case openingHours = "opening_hours"
        case recommendedDuration = "recommended_duration"
        case visitTips = "visit_tips"
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

enum LocationCategory: String, CaseIterable, Codable {
    case restaurant = "restaurant"
    case culture = "culture"
    case sport = "sport"
    case shopping = "shopping"
    case nature = "nature"
    case entertainment = "entertainment"
    case historical = "historical"
    case museum = "museum"
    case bar = "bar"
    case cafe = "cafe"
    case religious = "religious"
    case adventurePark = "adventure_park"
    case iceRink = "ice_rink"
    case swimmingPool = "swimming_pool"
    case climbingGym = "climbing_gym"
    case escapeRoom = "escape_room"
    case laserTag = "laser_tag"
    case bowling = "bowling"
    case miniGolf = "mini_golf"
    case paintball = "paintball"
    case karting = "karting"
    case trampolinePark = "trampoline_park"
    case waterPark = "water_park"
    case zoo = "zoo"
    case aquarium = "aquarium"
    
    var displayName: String {
        switch self {
        case .restaurant: return "Restaurants"
        case .culture: return "Culture"
        case .sport: return "Sport"
        case .shopping: return "Shopping"
        case .nature: return "Nature"
        case .entertainment: return "Divertissement"
        case .historical: return "Historique"
        case .museum: return "Musées"
        case .bar: return "Bars"
        case .cafe: return "Cafés"
        case .religious: return "Religieux"
        case .adventurePark: return "Parcs d'Aventure"
        case .iceRink: return "Patinoires"
        case .swimmingPool: return "Piscines"
        case .climbingGym: return "Salles d'Escalade"
        case .escapeRoom: return "Jeux d'Évasion"
        case .laserTag: return "Laser Game"
        case .bowling: return "Bowling"
        case .miniGolf: return "Golf Miniature"
        case .paintball: return "Paintball"
        case .karting: return "Karting"
        case .trampolinePark: return "Parcs de Trampoline"
        case .waterPark: return "Parcs Aquatiques"
        case .zoo: return "Zoos"
        case .aquarium: return "Aquariums"
        }
    }
    
    var icon: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .culture: return "theatermasks"
        case .sport: return "figure.run"
        case .shopping: return "bag"
        case .nature: return "leaf"
        case .entertainment: return "party.popper"
        case .historical: return "building.columns"
        case .museum: return "building.2"
        case .bar: return "wineglass"
        case .cafe: return "cup.and.saucer"
        case .religious: return "cross"
        case .adventurePark: return "leaf.fill"
        case .iceRink: return "figure.skating"
        case .swimmingPool: return "figure.pool.swim"
        case .climbingGym: return "figure.climbing"
        case .escapeRoom: return "lock.rectangle"
        case .laserTag: return "gamecontroller"
        case .bowling: return "figure.bowling"
        case .miniGolf: return "figure.golf"
        case .paintball: return "target"
        case .karting: return "car.fill"
        case .trampolinePark: return "figure.jumprope"
        case .waterPark: return "drop.fill"
        case .zoo: return "hare.fill"
        case .aquarium: return "fish.fill"
        }
    }
}

enum TransportMode: String, CaseIterable, Codable {
    case walking = "walking"
    case driving = "driving"
    case cycling = "cycling"
    case publicTransport = "public_transport"
    
    var displayName: String {
        switch self {
        case .walking: return "À pied"
        case .driving: return "Voiture"
        case .cycling: return "Vélo"
        case .publicTransport: return "Transport public"
        }
    }
    
    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .driving: return "car"
        case .cycling: return "bicycle"
        case .publicTransport: return "bus"
        }
    }
    
    var mapKitTransportType: MKDirectionsTransportType {
        switch self {
        case .walking: return .walking
        case .driving: return .automobile
        case .cycling: return .walking // MapKit n'a pas de type vélo, utiliser walking
        case .publicTransport: return .transit
        }
    }
} 