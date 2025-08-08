import Foundation
import Combine

class UserStatisticsService: ObservableObject {
    @Published var statistics = UserStatistics()
    
    private let userDefaults = UserDefaults.standard
    private let statisticsKey = "user_statistics"
    
    init() {
        loadStatistics()
    }
    
    // MARK: - Statistics Management
    func incrementItineraries() {
        statistics.itinerariesCount += 1
        saveStatistics()
    }
    
    func incrementGuidedTours() {
        statistics.guidedToursCount += 1
        saveStatistics()
    }
    
    func incrementAdventures() {
        statistics.adventuresCount += 1
        saveStatistics()
    }
    
    func addCompletedTrip(_ trip: DayTrip) {
        statistics.itinerariesCount += 1
        statistics.totalDistance += trip.totalDistance
        statistics.totalDuration += trip.estimatedDuration
        saveStatistics()
    }
    
    func addCompletedTour(_ tour: GuidedTour) {
        statistics.guidedToursCount += 1
        if let distance = tour.totalDistance {
            statistics.totalDistance += distance / 1000.0 // Convert to km
        }
        statistics.totalDuration += tour.duration
        saveStatistics()
    }
    
    func addCompletedAdventure(_ adventure: Adventure) {
        statistics.adventuresCount += 1
        statistics.totalDistance += adventure.totalDistance
        statistics.totalDuration += adventure.estimatedDuration
        saveStatistics()
    }
    
    // MARK: - Data Persistence
    private func saveStatistics() {
        if let encoded = try? JSONEncoder().encode(statistics) {
            userDefaults.set(encoded, forKey: statisticsKey)
        }
    }
    
    private func loadStatistics() {
        if let data = userDefaults.data(forKey: statisticsKey),
           let decoded = try? JSONDecoder().decode(UserStatistics.self, from: data) {
            statistics = decoded
        }
    }
    
    // MARK: - Reset Statistics (for testing)
    func resetStatistics() {
        statistics = UserStatistics()
        saveStatistics()
    }
}

// MARK: - Data Models
struct UserStatistics: Codable {
    var itinerariesCount: Int = 0
    var guidedToursCount: Int = 0
    var adventuresCount: Int = 0
    var totalDistance: Double = 0.0 // in kilometers
    var totalDuration: TimeInterval = 0 // in seconds
    
    var formattedTotalDistance: String {
        if totalDistance >= 1.0 {
            return String(format: "%.1f km", totalDistance)
        } else {
            return String(format: "%.0f m", totalDistance * 1000)
        }
    }
    
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
} 