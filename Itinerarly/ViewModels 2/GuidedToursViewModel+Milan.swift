import Foundation
import CoreLocation

extension GuidedToursViewModel {
	func buildMilanFixedVariants() -> [GuidedTour] {
		let city: City = .milan
		func L(_ id: String, _ name: String, _ address: String, _ lat: Double, _ lon: Double, _ cat: LocationCategory) -> Location {
			Location(id: id, name: name, address: address, latitude: lat, longitude: lon, category: cat, description: nil, imageURL: nil, rating: 4.7, openingHours: nil, recommendedDuration: nil, visitTips: nil)
		}
		func S(_ i: Int, _ loc: Location) -> TourStop {
			TourStop(id: "milan_fixed_\(i)_\(loc.id)", location: loc, order: i, audioGuideText: "", audioGuideURL: nil, visitDuration: 1200, tips: nil, distanceFromPrevious: nil, travelTimeFromPrevious: nil, estimatedArrivalTime: nil, estimatedDepartureTime: nil)
		}

		// Facile – 3 arrêts
		let t1Stops: [TourStop] = [
			S(1, L("duomo", "Duomo di Milano (ext.)", "P.za del Duomo, 20122 Milano MI, Italy", 45.4642, 9.1916, .religious)),
			S(2, L("vittorio", "Galerie Vittorio Emanuele II", "P.za del Duomo, 20123 Milano MI, Italy", 45.4659, 9.1900, .culture)),
			S(3, L("scala", "Teatro alla Scala (ext.)", "Piazza della Scala, 20121 Milano MI, Italy", 45.4679, 9.1893, .culture))
		]
		let t1 = GuidedTour(
			id: "milan_fixed_easy_3",
			title: "Milan express – Duomo & Vittorio Emanuele",
			city: city,
			description: "Icônes du centre historique (3 arrêts).",
			duration: t1Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .easy,
			stops: t1Stops,
			imageURL: nil,
			rating: 4.8,
			price: nil
		)

		// Modéré – 5 arrêts
		let t2Stops: [TourStop] = [
			S(1, L("duomo2", "Duomo di Milano (ext.)", "P.za del Duomo, 20122 Milano MI, Italy", 45.4642, 9.1916, .religious)),
			S(2, L("vittorio2", "Galerie Vittorio Emanuele II", "P.za del Duomo, 20123 Milano MI, Italy", 45.4659, 9.1900, .culture)),
			S(3, L("scala2", "Teatro alla Scala (ext.)", "Piazza della Scala, 20121 Milano MI, Italy", 45.4679, 9.1893, .culture)),
			S(4, L("sforzesco", "Château des Sforza (ext.)", "Piazza Castello, 20121 Milano MI, Italy", 45.4700, 9.1799, .historical)),
			S(5, L("brera", "Pinacothèque de Brera (ext.)", "Via Brera, 28, 20121 Milano MI, Italy", 45.4720, 9.1879, .museum))
		]
		let t2 = GuidedTour(
			id: "milan_fixed_moderate_5",
			title: "Classiques – Duomo, Scala & Chateau Sforza",
			city: city,
			description: "De la cathédrale aux musées (5 arrêts).",
			duration: t2Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .moderate,
			stops: t2Stops,
			imageURL: nil,
			rating: 4.7,
			price: nil
		)

		// Difficile – 7 arrêts
		let t3Stops: [TourStop] = [
			S(1, L("duomo3", "Duomo di Milano (ext.)", "P.za del Duomo, 20122 Milano MI, Italy", 45.4642, 9.1916, .religious)),
			S(2, L("vittorio3", "Galerie Vittorio Emanuele II", "P.za del Duomo, 20123 Milano MI, Italy", 45.4659, 9.1900, .culture)),
			S(3, L("scala3", "Teatro alla Scala (ext.)", "Piazza della Scala, 20121 Milano MI, Italy", 45.4679, 9.1893, .culture)),
			S(4, L("sforzesco3", "Château des Sforza (ext.)", "Piazza Castello, 20121 Milano MI, Italy", 45.4700, 9.1799, .historical)),
			S(5, L("cimitero", "Cimitero Monumentale (ext.)", "Piazzale Cimitero Monumentale, 20154 Milano MI, Italy", 45.4857, 9.1818, .historical)),
			S(6, L("santa", "Santa Maria delle Grazie (ext.)", "Piazza di Santa Maria delle Grazie, 20123 Milano MI, Italy", 45.4656, 9.1704, .religious)),
			S(7, L("navigli", "Navigli (vue)", "Alzaia Naviglio Grande, 20144 Milano MI, Italy", 45.4486, 9.1737, .culture))
		]
		let t3 = GuidedTour(
			id: "milan_fixed_challenging_7",
			title: "Milan intense – Duomo, Sforza, Navigli",
			city: city,
			description: "Itinéraire complet entre monuments et quartiers historiques (7 arrêts).",
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
