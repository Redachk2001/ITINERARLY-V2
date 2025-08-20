import Foundation
import CoreLocation

extension GuidedToursViewModel {
	func buildMarrakechFixedVariants() -> [GuidedTour] {
		let city: City = .marrakech
		func L(_ id: String, _ name: String, _ address: String, _ lat: Double, _ lon: Double, _ cat: LocationCategory) -> Location {
			Location(id: id, name: name, address: address, latitude: lat, longitude: lon, category: cat, description: nil, imageURL: nil, rating: 4.7, openingHours: nil, recommendedDuration: nil, visitTips: nil)
		}
		func S(_ i: Int, _ loc: Location) -> TourStop {
			TourStop(id: "marrakech_fixed_\(i)_\(loc.id)", location: loc, order: i, audioGuideText: "", audioGuideURL: nil, visitDuration: 1200, tips: nil, distanceFromPrevious: nil, travelTimeFromPrevious: nil, estimatedArrivalTime: nil, estimatedDepartureTime: nil)
		}

		// Facile – 3 arrêts
		let t1Stops: [TourStop] = [
			S(1, L("jemaa", "Jemaa el-Fna", "Jemaa el-Fna, Marrakech 40000, Morocco", 31.6258, -7.9891, .culture)),
			S(2, L("koutoubia", "Mosquée Koutoubia (ext.)", "Avenue Mohammed V, Marrakech 40000, Morocco", 31.6248, -7.9933, .religious)),
			S(3, L("medersa", "Medersa Ben Youssef (ext.)", "Rue Assouel, Marrakech 40000, Morocco", 31.6338, -7.9891, .historical))
		]
		let t1 = GuidedTour(
			id: "marrakech_fixed_easy_3",
			title: "Marrakech express – Jemaa el-Fna & Koutoubia",
			city: city,
			description: "Cœur vibrant et monuments majeurs (3 arrêts).",
			duration: t1Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .easy,
			stops: t1Stops,
			imageURL: nil,
			rating: 4.8,
			price: nil
		)

		// Modéré – 5 arrêts
		let t2Stops: [TourStop] = [
			S(1, L("jemaa2", "Jemaa el-Fna", "Jemaa el-Fna, Marrakech 40000, Morocco", 31.6258, -7.9891, .culture)),
			S(2, L("koutoubia2", "Mosquée Koutoubia (jardins)", "Avenue Mohammed V, Marrakech 40000, Morocco", 31.6248, -7.9933, .culture)),
			S(3, L("bahia", "Palais de la Bahia (ext.)", "Avenue Imam El Ghazali, Marrakech 40000, Morocco", 31.6219, -7.9836, .historical)),
			S(4, L("saadiens", "Tombeaux Saadiens (ext.)", "Rue de la Kasbah, Marrakech 40000, Morocco", 31.6175, -7.9893, .historical)),
			S(5, L("majorelle", "Jardin Majorelle (ext.)", "Rue Yves St Laurent, Marrakech 40000, Morocco", 31.6413, -8.0033, .culture))
		]
		let t2 = GuidedTour(
			id: "marrakech_fixed_moderate_5",
			title: "Classiques – Bahia, Saadiens & Majorelle",
			city: city,
			description: "Monuments et jardins emblématiques (5 arrêts).",
			duration: t2Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .moderate,
			stops: t2Stops,
			imageURL: nil,
			rating: 4.7,
			price: nil
		)

		// Difficile – 7 arrêts
		let t3Stops: [TourStop] = [
			S(1, L("jemaa3", "Jemaa el-Fna", "Jemaa el-Fna, Marrakech 40000, Morocco", 31.6258, -7.9891, .culture)),
			S(2, L("koutoubia3", "Mosquée Koutoubia (ext.)", "Avenue Mohammed V, Marrakech 40000, Morocco", 31.6248, -7.9933, .religious)),
			S(3, L("bahia3", "Palais de la Bahia (ext.)", "Avenue Imam El Ghazali, Marrakech 40000, Morocco", 31.6219, -7.9836, .historical)),
			S(4, L("saadiens3", "Tombeaux Saadiens (ext.)", "Rue de la Kasbah, Marrakech 40000, Morocco", 31.6175, -7.9893, .historical)),
			S(5, L("badi", "Palais El Badi (ext.)", "Ksibat Nhass, Marrakech 40000, Morocco", 31.6202, -7.9892, .historical)),
			S(6, L("majorelle3", "Jardin Majorelle (ext.)", "Rue Yves St Laurent, Marrakech 40000, Morocco", 31.6413, -8.0033, .culture)),
			S(7, L("menara", "Jardins de la Ménara (vue)", "Avenue de la Ménara, Marrakech 40000, Morocco", 31.6130, -8.0210, .culture))
		]
		let t3 = GuidedTour(
			id: "marrakech_fixed_challenging_7",
			title: "Marrakech intense – Médina, palais & jardins",
			city: city,
			description: "Itinéraire complet entre monuments et jardins (7 arrêts).",
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
