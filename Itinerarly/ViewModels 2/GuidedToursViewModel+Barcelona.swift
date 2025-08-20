import Foundation
import CoreLocation

extension GuidedToursViewModel {
	func buildBarcelonaFixedVariants() -> [GuidedTour] {
		let city: City = .barcelona
		func L(_ id: String, _ name: String, _ address: String, _ lat: Double, _ lon: Double, _ cat: LocationCategory) -> Location {
			Location(id: id, name: name, address: address, latitude: lat, longitude: lon, category: cat, description: nil, imageURL: nil, rating: 4.7, openingHours: nil, recommendedDuration: nil, visitTips: nil)
		}
		func S(_ i: Int, _ loc: Location) -> TourStop {
			TourStop(id: "barcelona_fixed_\(i)_\(loc.id)", location: loc, order: i, audioGuideText: "", audioGuideURL: nil, visitDuration: 1200, tips: nil, distanceFromPrevious: nil, travelTimeFromPrevious: nil, estimatedArrivalTime: nil, estimatedDepartureTime: nil)
		}

		// Facile – 3 arrêts
		let t1Stops: [TourStop] = [
			S(1, L("sagrada", "Sagrada Família", "Carrer de Mallorca, 401, 08013 Barcelona, Spain", 41.4036, 2.1744, .religious)),
			S(2, L("batllo", "Casa Batlló", "Passeig de Gràcia, 43, 08007 Barcelona, Spain", 41.3916, 2.1649, .culture)),
			S(3, L("pedrera", "Casa Milà – La Pedrera", "Passeig de Gràcia, 92, 08008 Barcelona, Spain", 41.3953, 2.1619, .culture))
		]
		let t1 = GuidedTour(
			id: "barcelona_fixed_easy_3",
			title: "Barcelone express – Gaudí sur le Passeig de Gràcia",
			city: city,
			description: "Parcours express autour des icônes modernistes (3 arrêts).",
			duration: t1Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .easy,
			stops: t1Stops,
			imageURL: nil,
			rating: 4.8,
			price: nil
		)

		// Modéré – 5 arrêts
		let t2Stops: [TourStop] = [
			S(1, L("sagrada2", "Sagrada Família", "Carrer de Mallorca, 401, 08013 Barcelona, Spain", 41.4036, 2.1744, .religious)),
			S(2, L("batllo2", "Casa Batlló", "Passeig de Gràcia, 43, 08007 Barcelona, Spain", 41.3916, 2.1649, .culture)),
			S(3, L("pedrera2", "Casa Milà – La Pedrera", "Passeig de Gràcia, 92, 08008 Barcelona, Spain", 41.3953, 2.1619, .culture)),
			S(4, L("barri_gotic", "Barri Gòtic", "Carrer del Bisbe, 08002 Barcelona, Spain", 41.3839, 2.1763, .historical)),
			S(5, L("cathedral", "Cathédrale de Barcelone", "Pla de la Seu, s/n, 08002 Barcelona, Spain", 41.3839, 2.1760, .religious))
		]
		let t2 = GuidedTour(
			id: "barcelona_fixed_moderate_5",
			title: "Modernisme & Gothique – Du Passeig de Gràcia à la Cathédrale",
			city: city,
			description: "Gaudí, quartier gothique et cathédrale (5 arrêts).",
			duration: t2Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .moderate,
			stops: t2Stops,
			imageURL: nil,
			rating: 4.7,
			price: nil
		)

		// Difficile – 7 arrêts
		let t3Stops: [TourStop] = [
			S(1, L("sagrada3", "Sagrada Família", "Carrer de Mallorca, 401, 08013 Barcelona, Spain", 41.4036, 2.1744, .religious)),
			S(2, L("batllo3", "Casa Batlló", "Passeig de Gràcia, 43, 08007 Barcelona, Spain", 41.3916, 2.1649, .culture)),
			S(3, L("pedrera3", "Casa Milà – La Pedrera", "Passeig de Gràcia, 92, 08008 Barcelona, Spain", 41.3953, 2.1619, .culture)),
			S(4, L("barri_gotic3", "Barri Gòtic", "Carrer del Bisbe, 08002 Barcelona, Spain", 41.3839, 2.1763, .historical)),
			S(5, L("cathedral3", "Cathédrale de Barcelone", "Pla de la Seu, s/n, 08002 Barcelona, Spain", 41.3839, 2.1760, .religious)),
			S(6, L("park_guell", "Parc Güell", "Carrer d'Olot, 5, 08024 Barcelona, Spain", 41.4145, 2.1527, .culture)),
			S(7, L("mnac", "MNAC – Musée National d'Art de Catalogne (vue)", "Palau Nacional, Parc de Montjuïc, s/n, 08038 Barcelona, Spain", 41.3689, 2.1532, .museum))
		]
		let t3 = GuidedTour(
			id: "barcelona_fixed_challenging_7",
			title: "Gaudí, Gothique & panoramas – Parc Güell & Montjuïc",
			city: city,
			description: "Itinéraire complet entre modernisme, vieux Barcelone et belvédères (7 arrêts).",
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
