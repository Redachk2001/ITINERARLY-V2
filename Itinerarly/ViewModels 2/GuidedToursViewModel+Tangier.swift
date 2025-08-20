import Foundation
import CoreLocation

extension GuidedToursViewModel {
	func buildTangierFixedVariants() -> [GuidedTour] {
		let city: City = .tangier
		func L(_ id: String, _ name: String, _ address: String, _ lat: Double, _ lon: Double, _ cat: LocationCategory) -> Location {
			Location(id: id, name: name, address: address, latitude: lat, longitude: lon, category: cat, description: nil, imageURL: nil, rating: 4.7, openingHours: nil, recommendedDuration: nil, visitTips: nil)
		}
		func S(_ i: Int, _ loc: Location) -> TourStop {
			TourStop(id: "tangier_fixed_\(i)_\(loc.id)", location: loc, order: i, audioGuideText: "", audioGuideURL: nil, visitDuration: 1200, tips: nil, distanceFromPrevious: nil, travelTimeFromPrevious: nil, estimatedArrivalTime: nil, estimatedDepartureTime: nil)
		}

		// Facile – 3 arrêts
		let t1Stops: [TourStop] = [
			S(1, L("kasbah", "Kasbah de Tanger", "Place du Mechouar, Tanger 90030, Morocco", 35.7891, -5.8104, .historical)),
			S(2, L("medina", "Médina & Grand Socco", "Grand Socco, Tanger 90000, Morocco", 35.7806, -5.8129, .culture)),
			S(3, L("cap_spartel", "Cap Spartel (vue)", "Cap Spartel, Tanger 90000, Morocco", 35.7793, -5.9350, .culture))
		]
		let t1 = GuidedTour(
			id: "tangier_fixed_easy_3",
			title: "Tanger express – Kasbah & Grand Socco",
			city: city,
			description: "Cœur historique et panorama océan (3 arrêts).",
			duration: t1Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .easy,
			stops: t1Stops,
			imageURL: nil,
			rating: 4.8,
			price: nil
		)

		// Modéré – 5 arrêts
		let t2Stops: [TourStop] = [
			S(1, L("kasbah2", "Kasbah de Tanger", "Place du Mechouar, Tanger 90030, Morocco", 35.7891, -5.8104, .historical)),
			S(2, L("medina2", "Médina & Petit Socco", "Petit Socco, Tanger 90000, Morocco", 35.7845, -5.8113, .culture)),
			S(3, L("americain", "Légations américaines (musée)", "8 Rue d'Amerique, Tanger 90000, Morocco", 35.7855, -5.8126, .museum)),
			S(4, L("hercule", "Grottes d'Hercule (site)", "Grottes d'Hercule, Tanger 90000, Morocco", 35.7665, -5.9362, .historical)),
			S(5, L("cap_spartel2", "Cap Spartel (phare)", "Phare Cap Spartel, Tanger 90000, Morocco", 35.7793, -5.9350, .culture))
		]
		let t2 = GuidedTour(
			id: "tangier_fixed_moderate_5",
			title: "Kasbah, Médina & légendes – jusqu'à Cap Spartel",
			city: city,
			description: "Patrimoine, musées et panoramas (5 arrêts).",
			duration: t2Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .moderate,
			stops: t2Stops,
			imageURL: nil,
			rating: 4.7,
			price: nil
		)

		// Difficile – 7 arrêts
		let t3Stops: [TourStop] = [
			S(1, L("kasbah3", "Kasbah de Tanger", "Place du Mechouar, Tanger 90030, Morocco", 35.7891, -5.8104, .historical)),
			S(2, L("medina3", "Médina – rues historiques", "Rue Siaghine, Tanger 90000, Morocco", 35.7856, -5.8120, .culture)),
			S(3, L("americain3", "Légations américaines (musée)", "8 Rue d'Amerique, Tanger 90000, Morocco", 35.7855, -5.8126, .museum)),
			S(4, L("hercule3", "Grottes d'Hercule (site)", "Grottes d'Hercule, Tanger 90000, Morocco", 35.7665, -5.9362, .historical)),
			S(5, L("cap_spartel3", "Cap Spartel (phare)", "Phare Cap Spartel, Tanger 90000, Morocco", 35.7793, -5.9350, .culture)),
			S(6, L("parc_perdicaris", "Parc Perdicaris (vue)", "Parc Perdicaris, Tanger 90000, Morocco", 35.7576, -5.8572, .culture)),
			S(7, L("marshan", "Quartier Marshan & nécropole punique (vue)", "Place du Marshan, Tanger 90000, Morocco", 35.7899, -5.8177, .historical))
		]
		let t3 = GuidedTour(
			id: "tangier_fixed_challenging_7",
			title: "Tanger panoramas – Kasbah, Grottes & Cap Spartel",
			city: city,
			description: "Itinéraire complet entre histoire et Océan (7 arrêts).",
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
