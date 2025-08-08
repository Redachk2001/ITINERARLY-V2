import SwiftUI
import MapKit

#if DEBUG
struct NavigationPreview: PreviewProvider {
    static var previews: some View {
        GPSNavigationView(trip: mockTrip)
            .environmentObject(LocationManager())
    }
    
    static var mockTrip: DayTrip {
        let startLocation = Location(
            id: "start",
            name: "16A Rue des Dahlias",
            address: "16A Rue des Dahlias, Luxembourg, 1411",
            latitude: 49.6116,
            longitude: 6.1319,
            category: .cafe,
            description: nil,
            imageURL: nil,
            rating: nil,
            openingHours: nil,
            recommendedDuration: nil,
            visitTips: nil
        )
        
        let destination1 = Location(
            id: "dest1",
            name: "Auchan",
            address: "Centre Commercial Auchan, Luxembourg",
            latitude: 49.6200,
            longitude: 6.1400,
            category: .shopping,
            description: nil,
            imageURL: nil,
            rating: nil,
            openingHours: nil,
            recommendedDuration: nil,
            visitTips: nil
        )
        
        let destination2 = Location(
            id: "dest2",
            name: "Stade Emil Bintner",
            address: "Stade Emil Bintner, Luxembourg",
            latitude: 49.6050,
            longitude: 6.1250,
            category: .sport,
            description: nil,
            imageURL: nil,
            rating: nil,
            openingHours: nil,
            recommendedDuration: nil,
            visitTips: nil
        )
        
        return DayTrip(
            id: "mock_trip",
            startLocation: startLocation,
            locations: [destination1, destination2],
            optimizedRoute: [startLocation, destination1, destination2],
            totalDistance: 7.1,
            estimatedDuration: 3180, // 53 minutes
            transportMode: .driving,
            createdAt: Date(),
            numberOfLocations: 2
        )
    }
}
#endif 