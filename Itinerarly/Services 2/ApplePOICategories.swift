import Foundation
import MapKit

/// Regroupe toutes les catégories de POI exposées par Apple Plans (MKPointOfInterestCategory)
/// Cette liste vise la compatibilité iOS 14+ et couvre les types principaux documentés.
struct ApplePOICategories {
    /// Ensemble de toutes les catégories connues et largement supportées.
    static let all: Set<MKPointOfInterestCategory> = [
        .airport,
        .amusementPark,
        .aquarium,
        .atm,
        .bakery,
        .bank,
        .beach,
        .brewery,
        .cafe,
        .campground,
        .carRental,
        .evCharger,
        .fireStation,
        .fitnessCenter,
        .foodMarket,
        .gasStation,
        .hospital,
        .hotel,
        .laundry,
        .library,
        .marina,
        .movieTheater,
        .museum,
        .nationalPark,
        .nightlife,
        .park,
        .parking,
        .pharmacy,
        .police,
        .postOffice,
        .publicTransport,
        .restaurant,
        .restroom,
        .school,
        .stadium,
        .store,
        .theater,
        .university,
        .winery,
        .zoo
    ]

    /// Construit un filtre qui inclut toutes les catégories.
    static func includingAllFilter() -> MKPointOfInterestFilter {
        return MKPointOfInterestFilter(including: Array(all))
    }
}


