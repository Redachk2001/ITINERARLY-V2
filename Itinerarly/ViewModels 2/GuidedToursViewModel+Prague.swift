import Foundation
import CoreLocation

extension GuidedToursViewModel {
	func buildPragueFixedVariants() -> [GuidedTour] {
		let city: City = .prague
		func L(_ id: String, _ name: String, _ address: String, _ lat: Double, _ lon: Double, _ cat: LocationCategory) -> Location {
			Location(id: id, name: name, address: address, latitude: lat, longitude: lon, category: cat, description: nil, imageURL: nil, rating: 4.7, openingHours: nil, recommendedDuration: nil, visitTips: nil)
		}
		func S(_ i: Int, _ loc: Location) -> TourStop {
			TourStop(id: "prague_fixed_\(i)_\(loc.id)", location: loc, order: i, audioGuideText: "", audioGuideURL: nil, visitDuration: 1200, tips: nil, distanceFromPrevious: nil, travelTimeFromPrevious: nil, estimatedArrivalTime: nil, estimatedDepartureTime: nil)
		}

		// Facile – 3 arrêts
		let t1Stops: [TourStop] = [
			S(1, L("castle", "Château de Prague (ext.)", "Hradčany, 119 08 Prague, Czechia", 50.0909, 14.4005, .historical)),
			S(2, L("stvitus", "Cathédrale Saint‑Guy (ext.)", "III. nádvoří 48/2, 119 01 Praha 1, Czechia", 50.0903, 14.4009, .religious)),
			S(3, L("charles", "Pont Charles (vue)", "Karlův most, 110 00 Praha 1, Czechia", 50.0865, 14.4114, .culture))
		]
		let t1 = GuidedTour(
			id: "prague_fixed_easy_3",
			title: "Prague express – Château & Pont Charles",
			city: city,
			description: "Panorama du Hradčany et traversée historique (3 arrêts).",
			duration: t1Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .easy,
			stops: t1Stops,
			imageURL: nil,
			rating: 4.8,
			price: nil
		)

		// Modéré – 5 arrêts
		let t2Stops: [TourStop] = [
			S(1, L("oldtown", "Place de la Vieille‑Ville & Horloge astronomique", "Staroměstské nám., 110 00 Praha 1, Czechia", 50.0870, 14.4208, .historical)),
			S(2, L("charles2", "Pont Charles (vue)", "Karlův most, 110 00 Praha 1, Czechia", 50.0865, 14.4114, .culture)),
			S(3, L("mala", "Malá Strana (ruelles historiques)", "Malá Strana, 118 00 Praha 1, Czechia", 50.0878, 14.4046, .historical)),
			S(4, L("castle2", "Château de Prague (ext.)", "Hradčany, 119 08 Prague, Czechia", 50.0909, 14.4005, .historical)),
			S(5, L("stvitus2", "Cathédrale Saint‑Guy (ext.)", "III. nádvoří 48/2, 119 01 Praha 1, Czechia", 50.0903, 14.4009, .religious))
		]
		let t2 = GuidedTour(
			id: "prague_fixed_moderate_5",
			title: "Vieille‑Ville, Malá Strana & Hradčany",
			city: city,
			description: "Quartiers emblématiques et monuments (5 arrêts).",
			duration: t2Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .moderate,
			stops: t2Stops,
			imageURL: nil,
			rating: 4.7,
			price: nil
		)

		// Difficile – 7 arrêts
		let t3Stops: [TourStop] = [
			S(1, L("castle3", "Château de Prague (ext.)", "Hradčany, 119 08 Prague, Czechia", 50.0909, 14.4005, .historical)),
			S(2, L("stvitus3", "Cathédrale Saint‑Guy (ext.)", "III. nádvoří 48/2, 119 01 Praha 1, Czechia", 50.0903, 14.4009, .religious)),
			S(3, L("charles3", "Pont Charles (vue)", "Karlův most, 110 00 Praha 1, Czechia", 50.0865, 14.4114, .culture)),
			S(4, L("oldtown3", "Place de la Vieille‑Ville & Horloge", "Staroměstské nám., 110 00 Praha 1, Czechia", 50.0870, 14.4208, .historical)),
			S(5, L("wenceslas", "Place Venceslas (vue)", "Václavské nám., 110 00 Praha 1, Czechia", 50.0810, 14.4266, .culture)),
			S(6, L("jewish", "Quartier juif – Josefov (ext.)", "Maiselova 38/18, 110 00 Praha 1, Czechia", 50.0905, 14.4195, .historical)),
			S(7, L("petrin", "Colline de Petřín (belvédère)", "Petřínské sady, 118 00 Praha 1, Czechia", 50.0836, 14.3957, .culture))
		]
		let t3 = GuidedTour(
			id: "prague_fixed_challenging_7",
			title: "Prague intense – Château, Pont & Vieille‑Ville",
			city: city,
			description: "Panorama complet entre Hradčany, Malá Strana et Staré Město (7 arrêts).",
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
