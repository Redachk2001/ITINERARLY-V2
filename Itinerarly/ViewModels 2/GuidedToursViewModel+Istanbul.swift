import Foundation
import CoreLocation

extension GuidedToursViewModel {
	func buildIstanbulFixedVariants() -> [GuidedTour] {
		let city: City = .istanbul
		func L(_ id: String, _ name: String, _ address: String, _ lat: Double, _ lon: Double, _ cat: LocationCategory) -> Location {
			Location(id: id, name: name, address: address, latitude: lat, longitude: lon, category: cat, description: nil, imageURL: nil, rating: 4.7, openingHours: nil, recommendedDuration: nil, visitTips: nil)
		}
		func S(_ i: Int, _ loc: Location) -> TourStop {
			TourStop(id: "istanbul_fixed_\(i)_\(loc.id)", location: loc, order: i, audioGuideText: "", audioGuideURL: nil, visitDuration: 1200, tips: nil, distanceFromPrevious: nil, travelTimeFromPrevious: nil, estimatedArrivalTime: nil, estimatedDepartureTime: nil)
		}

		// Facile – 3 arrêts (Sultanahmet)
		let t1Stops: [TourStop] = [
			S(1, L("ayasofya", "Sainte‑Sophie (ext.)", "Ayasofya Meydanı, Sultan Ahmet, 34122 Fatih/İstanbul, Türkiye", 41.0086, 28.9802, .religious)),
			S(2, L("sultanahmet", "Mosquée Bleue (ext.)", "Sultan Ahmet, Atmeydanı Cd. No:7, 34122 Fatih/İstanbul, Türkiye", 41.0054, 28.9768, .religious)),
			S(3, L("cistern", "Citerne Basilique (ext.)", "Alemdar, Yerebatan Cd. 1/3, 34110 Fatih/İstanbul, Türkiye", 41.0084, 28.9779, .historical))
		]
		let t1 = GuidedTour(
			id: "istanbul_fixed_easy_3",
			title: "Sultanahmet express – Sainte‑Sophie & Mosquée Bleue",
			city: city,
			description: "Trois icônes à quelques pas (3 arrêts).",
			duration: t1Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .easy,
			stops: t1Stops,
			imageURL: nil,
			rating: 4.8,
			price: nil
		)

		// Modéré – 5 arrêts
		let t2Stops: [TourStop] = [
			S(1, L("topkapi", "Palais de Topkapı (ext.)", "Cankurtaran, 34122 Fatih/İstanbul, Türkiye", 41.0115, 28.9834, .historical)),
			S(2, L("ayasofya2", "Sainte‑Sophie (ext.)", "Ayasofya Meydanı, Sultan Ahmet, 34122 Fatih/İstanbul, Türkiye", 41.0086, 28.9802, .religious)),
			S(3, L("sultanahmet2", "Mosquée Bleue (ext.)", "Sultan Ahmet, Atmeydanı Cd. No:7, 34122 Fatih/İstanbul, Türkiye", 41.0054, 28.9768, .religious)),
			S(4, L("hippodrome", "Hippodrome (Obélisque)", "Sultan Ahmet, 34122 Fatih/İstanbul, Türkiye", 41.0057, 28.9764, .historical)),
			S(5, L("cistern2", "Citerne Basilique (ext.)", "Alemdar, Yerebatan Cd. 1/3, 34110 Fatih/İstanbul, Türkiye", 41.0084, 28.9779, .historical))
		]
		let t2 = GuidedTour(
			id: "istanbul_fixed_moderate_5",
			title: "Topkapı & Sultanahmet – Palais, mosquées, citerne",
			city: city,
			description: "Parcours historique au cœur de l'empire (5 arrêts).",
			duration: t2Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .moderate,
			stops: t2Stops,
			imageURL: nil,
			rating: 4.7,
			price: nil
		)

		// Difficile – 7 arrêts
		let t3Stops: [TourStop] = [
			S(1, L("galata", "Tour de Galata (vue)", "Bereketzade, Galata Kulesi, 34421 Beyoğlu/İstanbul, Türkiye", 41.0257, 28.9744, .historical)),
			S(2, L("spice", "Bazar Égyptien (ext.)", "Rüstem Paşa, 34116 Fatih/İstanbul, Türkiye", 41.0161, 28.9706, .culture)),
			S(3, L("suleymaniye", "Mosquée Süleymaniye (ext.)", "Süleymaniye, 34116 Fatih/İstanbul, Türkiye", 41.0165, 28.9639, .religious)),
			S(4, L("topkapi3", "Palais de Topkapı (ext.)", "Cankurtaran, 34122 Fatih/İstanbul, Türkiye", 41.0115, 28.9834, .historical)),
			S(5, L("ayasofya3", "Sainte‑Sophie (ext.)", "Ayasofya Meydanı, 34122 Fatih/İstanbul, Türkiye", 41.0086, 28.9802, .religious)),
			S(6, L("sultanahmet3", "Mosquée Bleue (ext.)", "Sultan Ahmet, Atmeydanı Cd. No:7, 34122 Fatih/İstanbul, Türkiye", 41.0054, 28.9768, .religious)),
			S(7, L("cistern3", "Citerne Basilique (ext.)", "Alemdar, Yerebatan Cd. 1/3, 34110 Fatih/İstanbul, Türkiye", 41.0084, 28.9779, .historical))
		]
		let t3 = GuidedTour(
			id: "istanbul_fixed_challenging_7",
			title: "Istanbul intense – Galata, Sultanahmet & Bazar",
			city: city,
			description: "Des rives de la Corne d'Or à Sultanahmet (7 arrêts).",
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
