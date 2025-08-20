import Foundation
import CoreLocation

extension GuidedToursViewModel {
	func buildRomeFixedVariants() -> [GuidedTour] {
		let city: City = .rome
		func L(_ id: String, _ name: String, _ address: String, _ lat: Double, _ lon: Double, _ cat: LocationCategory) -> Location {
			Location(id: id, name: name, address: address, latitude: lat, longitude: lon, category: cat, description: nil, imageURL: nil, rating: 4.7, openingHours: nil, recommendedDuration: nil, visitTips: nil)
		}
		func S(_ i: Int, _ loc: Location) -> TourStop {
			TourStop(id: "rome_fixed_\(i)_\(loc.id)", location: loc, order: i, audioGuideText: "", audioGuideURL: nil, visitDuration: 1200, tips: nil, distanceFromPrevious: nil, travelTimeFromPrevious: nil, estimatedArrivalTime: nil, estimatedDepartureTime: nil)
		}

		// Facile – 3 arrêts
		let t1Stops: [TourStop] = [
			S(1, L("colosseum", "Colisée (ext.)", "Piazza del Colosseo, 1, 00184 Roma RM, Italy", 41.8902, 12.4922, .historical)),
			S(2, L("forum", "Forum Romain (vue)", "Via della Salara Vecchia, 5/6, 00186 Roma RM, Italy", 41.8925, 12.4853, .historical)),
			S(3, L("trevi", "Fontaine de Trevi", "Piazza di Trevi, 00187 Roma RM, Italy", 41.9009, 12.4833, .culture))
		]
		let t1 = GuidedTour(
			id: "rome_fixed_easy_3",
			title: "Rome express – Colisée, Forum & Trevi",
			city: city,
			description: "Icônes antiques et baroques (3 arrêts).",
			duration: t1Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .easy,
			stops: t1Stops,
			imageURL: nil,
			rating: 4.8,
			price: nil
		)

		// Modéré – 5 arrêts
		let t2Stops: [TourStop] = [
			S(1, L("colosseum2", "Colisée (ext.)", "Piazza del Colosseo, 1, 00184 Roma RM, Italy", 41.8902, 12.4922, .historical)),
			S(2, L("forum2", "Forum Romain (vue)", "Via della Salara Vecchia, 5/6, 00186 Roma RM, Italy", 41.8925, 12.4853, .historical)),
			S(3, L("pantheon", "Panthéon (ext.)", "Piazza della Rotonda, 00186 Roma RM, Italy", 41.8986, 12.4768, .historical)),
			S(4, L("navona", "Piazza Navona", "Piazza Navona, 00186 Roma RM, Italy", 41.8992, 12.4731, .culture)),
			S(5, L("trevi2", "Fontaine de Trevi", "Piazza di Trevi, 00187 Roma RM, Italy", 41.9009, 12.4833, .culture))
		]
		let t2 = GuidedTour(
			id: "rome_fixed_moderate_5",
			title: "Antique & baroque – Panthéon, Navona & Trevi",
			city: city,
			description: "Du Colisée aux places baroques (5 arrêts).",
			duration: t2Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .moderate,
			stops: t2Stops,
			imageURL: nil,
			rating: 4.7,
			price: nil
		)

		// Difficile – 7 arrêts
		let t3Stops: [TourStop] = [
			S(1, L("colosseum3", "Colisée (ext.)", "Piazza del Colosseo, 1, 00184 Roma RM, Italy", 41.8902, 12.4922, .historical)),
			S(2, L("forum3", "Forum Romain (vue)", "Via della Salara Vecchia, 5/6, 00186 Roma RM, Italy", 41.8925, 12.4853, .historical)),
			S(3, L("palatine", "Mont Palatin (vue)", "Via di San Gregorio, 30, 00184 Roma RM, Italy", 41.8892, 12.4884, .historical)),
			S(4, L("pantheon3", "Panthéon (ext.)", "Piazza della Rotonda, 00186 Roma RM, Italy", 41.8986, 12.4768, .historical)),
			S(5, L("navona3", "Piazza Navona", "Piazza Navona, 00186 Roma RM, Italy", 41.8992, 12.4731, .culture)),
			S(6, L("vatican", "Place Saint‑Pierre (vue)", "Piazza San Pietro, 00120 Città del Vaticano", 41.9022, 12.4539, .religious)),
			S(7, L("trastevere", "Belvédère du Janicule & Trastevere (vue)", "Piazzale Giuseppe Garibaldi, 00165 Roma RM, Italy", 41.8933, 12.4663, .culture))
		]
		let t3 = GuidedTour(
			id: "rome_fixed_challenging_7",
			title: "Rome intense – Colisée, Panthéon & Saint‑Pierre",
			city: city,
			description: "Parcours complet antique et baroque (7 arrêts).",
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
