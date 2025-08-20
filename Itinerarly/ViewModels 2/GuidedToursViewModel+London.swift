import Foundation
import CoreLocation

extension GuidedToursViewModel {
	func buildLondonFixedVariants() -> [GuidedTour] {
		let city: City = .london
		func L(_ id: String, _ name: String, _ address: String, _ lat: Double, _ lon: Double, _ cat: LocationCategory) -> Location {
			Location(id: id, name: name, address: address, latitude: lat, longitude: lon, category: cat, description: nil, imageURL: nil, rating: 4.7, openingHours: nil, recommendedDuration: nil, visitTips: nil)
		}
		func S(_ i: Int, _ loc: Location) -> TourStop {
			TourStop(id: "london_fixed_\(i)_\(loc.id)", location: loc, order: i, audioGuideText: "", audioGuideURL: nil, visitDuration: 1200, tips: nil, distanceFromPrevious: nil, travelTimeFromPrevious: nil, estimatedArrivalTime: nil, estimatedDepartureTime: nil)
		}

		// Facile – 3 arrêts
		let t1Stops: [TourStop] = [
			S(1, L("bigben", "Big Ben & Parliament", "Westminster, London SW1A 0AA, United Kingdom", 51.5007, -0.1246, .historical)),
			S(2, L("abbey", "Westminster Abbey (ext.)", "20 Deans Yd, London SW1P 3PA, United Kingdom", 51.4993, -0.1273, .religious)),
			S(3, L("eye", "London Eye (vue)", "Riverside Building, County Hall, London SE1 7PB, United Kingdom", 51.5033, -0.1196, .culture))
		]
		let t1 = GuidedTour(
			id: "london_fixed_easy_3",
			title: "Westminster express – Parlement & Abbey",
			city: city,
			description: "Cœur institutionnel et icônes de Westminster (3 arrêts).",
			duration: t1Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .easy,
			stops: t1Stops,
			imageURL: nil,
			rating: 4.8,
			price: nil
		)

		// Modéré – 5 arrêts
		let t2Stops: [TourStop] = [
			S(1, L("trafalgar", "Trafalgar Square", "Trafalgar Sq, London WC2N 5DN, United Kingdom", 51.5080, -0.1281, .culture)),
			S(2, L("national", "National Gallery (ext.)", "Trafalgar Sq, London WC2N 5DN, United Kingdom", 51.5089, -0.1283, .museum)),
			S(3, L("buckingham", "Buckingham Palace (ext.)", "Westminster, London SW1A 1AA, United Kingdom", 51.5014, -0.1419, .historical)),
			S(4, L("stjames", "St James's Park (vue)", "London SW1A 2BJ, United Kingdom", 51.5027, -0.1346, .culture)),
			S(5, L("piccadilly", "Piccadilly Circus", "Piccadilly Circus, London W1D 7ET, United Kingdom", 51.5101, -0.1340, .culture))
		]
		let t2 = GuidedTour(
			id: "london_fixed_moderate_5",
			title: "Classiques – Trafalgar, Buckingham & St James's",
			city: city,
			description: "Places, palais et parc royal (5 arrêts).",
			duration: t2Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .moderate,
			stops: t2Stops,
			imageURL: nil,
			rating: 4.7,
			price: nil
		)

		// Difficile – 7 arrêts
		let t3Stops: [TourStop] = [
			S(1, L("tower", "Tower of London (ext.)", "London EC3N 4AB, United Kingdom", 51.5081, -0.0759, .historical)),
			S(2, L("bridge", "Tower Bridge (vue)", "Tower Bridge Rd, London SE1 2UP, United Kingdom", 51.5055, -0.0754, .culture)),
			S(3, L("stpauls", "St Paul's Cathedral (ext.)", "St. Paul's Churchyard, London EC4M 8AD, United Kingdom", 51.5138, -0.0984, .religious)),
			S(4, L("millennium", "Millennium Bridge (vue)", "Thames Embankment, London, United Kingdom", 51.5107, -0.0984, .culture)),
			S(5, L("tate", "Tate Modern (ext.)", "Bankside, London SE1 9TG, United Kingdom", 51.5076, -0.0994, .museum)),
			S(6, L("covent", "Covent Garden", "Covent Garden, London WC2E 8RF, United Kingdom", 51.5120, -0.1225, .culture)),
			S(7, L("westminster", "Parliament Square (vue)", "Parliament Square, London SW1P 3BD, United Kingdom", 51.5008, -0.1265, .culture))
		]
		let t3 = GuidedTour(
			id: "london_fixed_challenging_7",
			title: "Londres intense – Tower, St Paul's, Tate & Westminster",
			city: city,
			description: "Des rives de la Tamise aux icônes historiques (7 arrêts).",
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
