import Foundation
import CoreLocation

extension GuidedToursViewModel {
	func buildMadridFixedVariants() -> [GuidedTour] {
		let city: City = .madrid
		func L(_ id: String, _ name: String, _ address: String, _ lat: Double, _ lon: Double, _ cat: LocationCategory) -> Location {
			Location(id: id, name: name, address: address, latitude: lat, longitude: lon, category: cat, description: nil, imageURL: nil, rating: 4.7, openingHours: nil, recommendedDuration: nil, visitTips: nil)
		}
		func S(_ i: Int, _ loc: Location) -> TourStop {
			TourStop(id: "madrid_fixed_\(i)_\(loc.id)", location: loc, order: i, audioGuideText: "", audioGuideURL: nil, visitDuration: 1200, tips: nil, distanceFromPrevious: nil, travelTimeFromPrevious: nil, estimatedArrivalTime: nil, estimatedDepartureTime: nil)
		}

		// Facile – 3 arrêts
		let t1Stops: [TourStop] = [
			S(1, L("plaza_mayor", "Plaza Mayor", "Plaza Mayor, 28012 Madrid, Spain", 40.4154, -3.7074, .historical)),
			S(2, L("sol", "Puerta del Sol", "Puerta del Sol, 28013 Madrid, Spain", 40.4169, -3.7035, .historical)),
			S(3, L("palacio", "Palais Royal (extérieur)", "C. de Bailén, s/n, 28071 Madrid, Spain", 40.4179, -3.7143, .historical))
		]
		let t1 = GuidedTour(
			id: "madrid_fixed_easy_3",
			title: "Madrid express – Plaza Mayor & Sol",
			city: city,
			description: "Parcours express du centre historique (3 arrêts).",
			duration: t1Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .easy,
			stops: t1Stops,
			imageURL: nil,
			rating: 4.8,
			price: nil
		)

		// Modéré – 5 arrêts
		let t2Stops: [TourStop] = [
			S(1, L("plaza_mayor2", "Plaza Mayor", "Plaza Mayor, 28012 Madrid, Spain", 40.4154, -3.7074, .historical)),
			S(2, L("sol2", "Puerta del Sol", "Puerta del Sol, 28013 Madrid, Spain", 40.4169, -3.7035, .historical)),
			S(3, L("prado", "Musée du Prado (ext.)", "P.º del Prado, s/n, 28014 Madrid, Spain", 40.4138, -3.6921, .museum)),
			S(4, L("retiro", "Parc du Retiro – Estanque", "Plaza de la Independencia, 7, 28001 Madrid, Spain", 40.4153, -3.6883, .culture)),
			S(5, L("cibeles", "Plaza de Cibeles", "Plaza de Cibeles, 28014 Madrid, Spain", 40.4190, -3.6934, .culture))
		]
		let t2 = GuidedTour(
			id: "madrid_fixed_moderate_5",
			title: "Classiques – Sol, Prado & Retiro",
			city: city,
			description: "Centre historique, Triangle de l'art et parc du Retiro (5 arrêts).",
			duration: t2Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .moderate,
			stops: t2Stops,
			imageURL: nil,
			rating: 4.7,
			price: nil
		)

		// Difficile – 7 arrêts
		let t3Stops: [TourStop] = [
			S(1, L("plaza_mayor3", "Plaza Mayor", "Plaza Mayor, 28012 Madrid, Spain", 40.4154, -3.7074, .historical)),
			S(2, L("sol3", "Puerta del Sol", "Puerta del Sol, 28013 Madrid, Spain", 40.4169, -3.7035, .historical)),
			S(3, L("catedral", "Cathédrale de l'Almudena", "C. de Bailén, 10, 28013 Madrid, Spain", 40.4153, -3.7149, .religious)),
			S(4, L("palacio3", "Palais Royal (esplanade)", "C. de Bailén, s/n, 28071 Madrid, Spain", 40.4179, -3.7143, .historical)),
			S(5, L("prado3", "Musée du Prado (ext.)", "P.º del Prado, s/n, 28014 Madrid, Spain", 40.4138, -3.6921, .museum)),
			S(6, L("retiro3", "Parc du Retiro – Palais de Cristal", "P.º de Cuba, 4, 28009 Madrid, Spain", 40.4159, -3.6838, .culture)),
			S(7, L("granvia", "Gran Vía (vue panoramique)", "Gran Vía, 28013 Madrid, Spain", 40.4203, -3.7058, .culture))
		]
		let t3 = GuidedTour(
			id: "madrid_fixed_challenging_7",
			title: "Madrid intense – Sol, Prado, Retiro & panoramas",
			city: city,
			description: "Itinéraire complet au cœur de Madrid (7 arrêts).",
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
