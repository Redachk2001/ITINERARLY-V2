import Foundation
import CoreLocation

extension GuidedToursViewModel {
	func buildBrugesFixedVariants() -> [GuidedTour] {
		let city: City = .bruges
		func L(_ id: String, _ name: String, _ address: String, _ lat: Double, _ lon: Double, _ cat: LocationCategory) -> Location {
			Location(id: id, name: name, address: address, latitude: lat, longitude: lon, category: cat, description: nil, imageURL: nil, rating: 4.7, openingHours: nil, recommendedDuration: nil, visitTips: nil)
		}
		func S(_ i: Int, _ loc: Location) -> TourStop {
			TourStop(id: "bruges_fixed_\(i)_\(loc.id)", location: loc, order: i, audioGuideText: "", audioGuideURL: nil, visitDuration: 1200, tips: nil, distanceFromPrevious: nil, travelTimeFromPrevious: nil, estimatedArrivalTime: nil, estimatedDepartureTime: nil)
		}

		// Facile – 3 arrêts
		let t1Stops: [TourStop] = [
			S(1, L("markt", "Markt & Beffroi (ext.)", "Markt, 8000 Brugge, Belgium", 51.2090, 3.2248, .historical)),
			S(2, L("burg", "Burg & Basilique du Saint‑Sang (ext.)", "Burg 15, 8000 Brugge, Belgium", 51.2085, 3.2263, .religious)),
			S(3, L("rozenhoedkaai", "Rozenhoedkaai (vue canaux)", "Rozenhoedkaai, 8000 Brugge, Belgium", 51.2076, 3.2262, .culture))
		]
		let t1 = GuidedTour(
			id: "bruges_fixed_easy_3",
			title: "Bruges express – Markt, Burg & canaux",
			city: city,
			description: "Icônes du centre (3 arrêts).",
			duration: t1Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .easy,
			stops: t1Stops,
			imageURL: nil,
			rating: 4.8,
			price: nil
		)

		// Modéré – 5 arrêts
		let t2Stops: [TourStop] = [
			S(1, L("markt2", "Markt & Beffroi (ext.)", "Markt, 8000 Brugge, Belgium", 51.2090, 3.2248, .historical)),
			S(2, L("burg2", "Burg & Basilique du Saint‑Sang (ext.)", "Burg 15, 8000 Brugge, Belgium", 51.2085, 3.2263, .religious)),
			S(3, L("groeninge", "Musée Groeninge (ext.)", "Dijver 12, 8000 Brugge, Belgium", 51.2059, 3.2269, .museum)),
			S(4, L("begijnhof", "Béguinage & Minnewater (vue)", "Begijnhof 30, 8000 Brugge, Belgium", 51.2017, 3.2242, .culture)),
			S(5, L("saint_sauveur", "Cathédrale Saint‑Sauveur (ext.)", "Sint‑Salvatorskoorstraat 8, 8000 Brugge, Belgium", 51.2058, 3.2202, .religious))
		]
		let t2 = GuidedTour(
			id: "bruges_fixed_moderate_5",
			title: "Classiques – Beffroi, musées & Béguinage",
			city: city,
			description: "Histoire, art et canaux (5 arrêts).",
			duration: t2Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .moderate,
			stops: t2Stops,
			imageURL: nil,
			rating: 4.7,
			price: nil
		)

		// Difficile – 7 arrêts
		let t3Stops: [TourStop] = [
			S(1, L("markt3", "Markt & Beffroi (ext.)", "Markt, 8000 Brugge, Belgium", 51.2090, 3.2248, .historical)),
			S(2, L("burg3", "Burg & Basilique du Saint‑Sang (ext.)", "Burg 15, 8000 Brugge, Belgium", 51.2085, 3.2263, .religious)),
			S(3, L("groeninge3", "Musée Groeninge (ext.)", "Dijver 12, 8000 Brugge, Belgium", 51.2059, 3.2269, .museum)),
			S(4, L("saint_jean", "Hôpital Saint‑Jean (ext.)", "Mariastraat 38, 8000 Brugge, Belgium", 51.2045, 3.2249, .historical)),
			S(5, L("begijnhof3", "Béguinage & Minnewater (vue)", "Begijnhof 30, 8000 Brugge, Belgium", 51.2017, 3.2242, .culture)),
			S(6, L("stadhuis", "Hôtel de Ville (Stadhuis) (ext.)", "Burg 12, 8000 Brugge, Belgium", 51.2087, 3.2269, .historical)),
			S(7, L("rozen3", "Rozenhoedkaai (vue canaux)", "Rozenhoedkaai, 8000 Brugge, Belgium", 51.2076, 3.2262, .culture))
		]
		let t3 = GuidedTour(
			id: "bruges_fixed_challenging_7",
			title: "Bruges intense – Beffroi, canaux & Béguinage",
			city: city,
			description: "Parcours complet au fil des canaux (7 arrêts).",
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
