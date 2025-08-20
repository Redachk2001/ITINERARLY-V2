import Foundation
import CoreLocation

extension GuidedToursViewModel {
	func buildAmsterdamFixedVariants() -> [GuidedTour] {
		let city: City = .amsterdam
		func L(_ id: String, _ name: String, _ address: String, _ lat: Double, _ lon: Double, _ cat: LocationCategory) -> Location {
			Location(id: id, name: name, address: address, latitude: lat, longitude: lon, category: cat, description: nil, imageURL: nil, rating: 4.7, openingHours: nil, recommendedDuration: nil, visitTips: nil)
		}
		func S(_ i: Int, _ loc: Location) -> TourStop {
			TourStop(id: "ams_fixed_\(i)_\(loc.id)", location: loc, order: i, audioGuideText: "", audioGuideURL: nil, visitDuration: 1200, tips: nil, distanceFromPrevious: nil, travelTimeFromPrevious: nil, estimatedArrivalTime: nil, estimatedDepartureTime: nil)
		}

		// Facile – 3 arrêts
		let t1Stops: [TourStop] = [
			S(1, L("dam", "Dam Square & Palais Royal (ext.)", "Dam, 1012 JS Amsterdam, Netherlands", 52.3731, 4.8922, .historical)),
			S(2, L("oude", "Oude Kerk (ext.)", "Oudekerksplein 23, 1012 GX Amsterdam, Netherlands", 52.3745, 4.8997, .religious)),
			S(3, L("jordaan", "Canaux du Jordaan (vue)", "Prinsengracht 2, 1015 DV Amsterdam, Netherlands", 52.3773, 4.8839, .culture))
		]
		let t1 = GuidedTour(
			id: "ams_fixed_easy_3",
			title: "Amsterdam express – Dam & canaux",
			city: city,
			description: "Places et canaux (3 arrêts).",
			duration: t1Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .easy,
			stops: t1Stops,
			imageURL: nil,
			rating: 4.8,
			price: nil
		)

		// Modéré – 5 arrêts
		let t2Stops: [TourStop] = [
			S(1, L("dam2", "Dam Square & Palais Royal (ext.)", "Dam, 1012 JS Amsterdam, Netherlands", 52.3731, 4.8922, .historical)),
			S(2, L("anne", "Maison d'Anne Frank (ext.)", "Westermarkt 20, 1016 GV Amsterdam, Netherlands", 52.3752, 4.8839, .historical)),
			S(3, L("rijks", "Rijksmuseum (ext.)", "Museumstraat 1, 1071 XX Amsterdam, Netherlands", 52.3600, 4.8852, .museum)),
			S(4, L("vondel", "Vondelpark (vue)", "Vondelpark, Amsterdam, Netherlands", 52.3584, 4.8686, .culture)),
			S(5, L("heineken", "Heineken Experience (ext.)", "Stadhouderskade 78, 1072 AE Amsterdam, Netherlands", 52.3579, 4.8910, .culture))
		]
		let t2 = GuidedTour(
			id: "ams_fixed_moderate_5",
			title: "Classiques – Anne Frank, Rijksmuseum & Vondelpark",
			city: city,
			description: "Histoire, art et parcs (5 arrêts).",
			duration: t2Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .moderate,
			stops: t2Stops,
			imageURL: nil,
			rating: 4.7,
			price: nil
		)

		// Difficile – 7 arrêts
		let t3Stops: [TourStop] = [
			S(1, L("dam3", "Dam Square & Palais Royal (ext.)", "Dam, 1012 JS Amsterdam, Netherlands", 52.3731, 4.8922, .historical)),
			S(2, L("anne3", "Maison d'Anne Frank (ext.)", "Westermarkt 20, 1016 GV Amsterdam, Netherlands", 52.3752, 4.8839, .historical)),
			S(3, L("rijks3", "Rijksmuseum (ext.)", "Museumstraat 1, 1071 XX Amsterdam, Netherlands", 52.3600, 4.8852, .museum)),
			S(4, L("vanGogh", "Musée Van Gogh (ext.)", "Museumplein 6, 1071 DJ Amsterdam, Netherlands", 52.3584, 4.8811, .museum)),
			S(5, L("begijnhof", "Begijnhof (ext.)", "Begijnhof 8-9, 1012 AB Amsterdam, Netherlands", 52.3691, 4.8897, .historical)),
			S(6, L("magere", "Magere Brug (vue)", "Magere Brug, 1018 EG Amsterdam, Netherlands", 52.3654, 4.9018, .culture)),
			S(7, L("canaux", "Ceintures de canaux (vue)", "Keizersgracht 123, 1015 CJ Amsterdam, Netherlands", 52.3722, 4.8881, .culture))
		]
		let t3 = GuidedTour(
			id: "ams_fixed_challenging_7",
			title: "Amsterdam intense – Musées & canaux",
			city: city,
			description: "Des musées aux ceintures de canaux (7 arrêts).",
			duration: t3Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .challenging,
			stops: t3Stops,
			imageURL: nil,
			rating: 4.7,
			price: nil
		)

		return [t1, t2, t3]
	}
}
