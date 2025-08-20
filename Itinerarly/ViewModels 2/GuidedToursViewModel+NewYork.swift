import Foundation
import CoreLocation

extension GuidedToursViewModel {
	func buildNewYorkFixedVariants() -> [GuidedTour] {
		let city: City = .newYork
		func L(_ id: String, _ name: String, _ address: String, _ lat: Double, _ lon: Double, _ cat: LocationCategory) -> Location {
			Location(id: id, name: name, address: address, latitude: lat, longitude: lon, category: cat, description: nil, imageURL: nil, rating: 4.7, openingHours: nil, recommendedDuration: nil, visitTips: nil)
		}
		func S(_ i: Int, _ loc: Location) -> TourStop {
			TourStop(id: "nyc_fixed_\(i)_\(loc.id)", location: loc, order: i, audioGuideText: "", audioGuideURL: nil, visitDuration: 1200, tips: nil, distanceFromPrevious: nil, travelTimeFromPrevious: nil, estimatedArrivalTime: nil, estimatedDepartureTime: nil)
		}

		// Facile – 3 arrêts (Midtown)
		let t1Stops: [TourStop] = [
			S(1, L("times", "Times Square", "Times Square, New York, NY 10036, United States", 40.7580, -73.9855, .culture)),
			S(2, L("rock", "Rockefeller Center (Top of the Rock – vue)", "45 Rockefeller Plaza, New York, NY 10111, United States", 40.7587, -73.9787, .culture)),
			S(3, L("central", "Central Park – Gapstow Bridge (vue)", "Gapstow Bridge, New York, NY 10019, United States", 40.7644, -73.9746, .nature))
		]
		let t1 = GuidedTour(
			id: "nyc_fixed_easy_3",
			title: "Midtown express – Times, Rock, Central Park",
			city: city,
			description: "Icônes de Midtown (3 arrêts).",
			duration: t1Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .easy,
			stops: t1Stops,
			imageURL: nil,
			rating: 4.8,
			price: nil
		)

		// Modéré – 5 arrêts
		let t2Stops: [TourStop] = [
			S(1, L("grand", "Grand Central Terminal (ext.)", "89 E 42nd St, New York, NY 10017, United States", 40.7527, -73.9772, .historical)),
			S(2, L("bryant", "Bryant Park (vue)", "Bryant Park, New York, NY 10018, United States", 40.7536, -73.9832, .culture)),
			S(3, L("fifth", "Fifth Avenue (promenade)", "Fifth Ave, New York, NY, United States", 40.7589, -73.9786, .culture)),
			S(4, L("stpat", "Cathédrale St. Patrick (ext.)", "5th Ave, New York, NY 10022, United States", 40.7585, -73.9760, .religious)),
			S(5, L("moma", "MoMA (ext.)", "11 W 53rd St, New York, NY 10019, United States", 40.7614, -73.9776, .museum))
		]
		let t2 = GuidedTour(
			id: "nyc_fixed_moderate_5",
			title: "Midtown classique – Grand Central, Fifth, MoMA",
			city: city,
			description: "Gares, parcs et chefs‑d'œuvre (5 arrêts).",
			duration: t2Stops.reduce(TimeInterval(0)) { $0 + $1.visitDuration },
			difficulty: .moderate,
			stops: t2Stops,
			imageURL: nil,
			rating: 4.7,
			price: nil
		)

		// Difficile – 7 arrêts
		let t3Stops: [TourStop] = [
			S(1, L("battery", "Battery Park – Statue of Liberty (vue)", "Battery Park, New York, NY 10004, United States", 40.7033, -74.0170, .culture)),
			S(2, L("brooklyn", "Brooklyn Bridge (promenade)", "Brooklyn Bridge, New York, NY 10038, United States", 40.7061, -73.9969, .culture)),
			S(3, L("owtc", "One World Trade Center (vue)", "285 Fulton St, New York, NY 10007, United States", 40.7127, -74.0134, .historical)),
			S(4, L("memorial", "9/11 Memorial (ext.)", "180 Greenwich St, New York, NY 10007, United States", 40.7115, -74.0134, .historical)),
			S(5, L("met", "MET – The Met Fifth Avenue (ext.)", "1000 5th Ave, New York, NY 10028, United States", 40.7794, -73.9632, .museum)),
			S(6, L("central2", "Central Park – Belvedere Castle (vue)", "Belvedere Castle, New York, NY 10024, United States", 40.7794, -73.9690, .nature)),
			S(7, L("rock2", "Rockefeller Center (Top of the Rock – vue)", "45 Rockefeller Plaza, New York, NY 10111, United States", 40.7587, -73.9787, .culture))
		]
		let t3 = GuidedTour(
			id: "nyc_fixed_challenging_7",
			title: "New York intense – Downtown & Midtown panoramas",
			city: city,
			description: "De Downtown à Midtown: ponts, mémoriaux, musées et vues (7 arrêts).",
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
