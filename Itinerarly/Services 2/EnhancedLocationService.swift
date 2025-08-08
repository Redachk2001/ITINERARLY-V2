import Foundation
import CoreLocation
import MapKit

class EnhancedLocationService: ObservableObject {
    
    // MARK: - Public Methods
    
    func enhanceLocation(_ location: Location, completion: @escaping (Location) -> Void) {
        // Créer une copie pour modification
        var enhancedLocation = location
        
        // 1. Améliorer l'adresse avec géocodage inverse
        enhanceAddress(location: enhancedLocation) { address in
            enhancedLocation = enhancedLocation.withUpdatedAddress(address)
            
            // 2. Déterminer le type d'activité précis
            let activityType = self.determineActivityType(from: enhancedLocation)
            enhancedLocation = enhancedLocation.withUpdatedDescription(activityType)
            
            // 3. Calculer la durée recommandée
            let recommendedDuration = self.calculateRecommendedDuration(for: enhancedLocation)
            enhancedLocation = enhancedLocation.withUpdatedRecommendedDuration(recommendedDuration)
            
            // 4. Générer des conseils de visite
            let visitTips = self.generateVisitTips(for: enhancedLocation)
            enhancedLocation = enhancedLocation.withUpdatedVisitTips(visitTips)
            
            completion(enhancedLocation)
        }
    }
    
    // MARK: - Address Enhancement
    
    private func enhanceAddress(location: Location, completion: @escaping (String) -> Void) {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let clLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    let enhancedAddress = self.buildCompleteAddress(from: placemark)
                    completion(enhancedAddress)
                } else {
                    // Fallback vers l'adresse existante
                    completion(location.address)
                }
            }
        }
    }
    
    private func buildCompleteAddress(from placemark: CLPlacemark) -> String {
        var addressComponents: [String] = []
        
        if let thoroughfare = placemark.thoroughfare {
            addressComponents.append(thoroughfare)
        }
        
        if let subThoroughfare = placemark.subThoroughfare {
            addressComponents.append(subThoroughfare)
        }
        
        if let locality = placemark.locality {
            addressComponents.append(locality)
        }
        
        if let postalCode = placemark.postalCode {
            addressComponents.append(postalCode)
        }
        
        if let country = placemark.country {
            addressComponents.append(country)
        }
        
        return addressComponents.joined(separator: ", ")
    }
    
    // MARK: - Activity Type Determination
    
    private func determineActivityType(from location: Location) -> String {
        let name = location.name.lowercased()
        let category = location.category
        
        // Règles spécifiques basées sur le nom et la catégorie
        switch category {
        case .restaurant:
            if name.contains("pizza") || name.contains("pizzeria") {
                return "🍕 Pizzeria - Restaurant italien"
            } else if name.contains("sushi") || name.contains("japonais") {
                return "🍣 Restaurant japonais"
            } else if name.contains("burger") || name.contains("fast") {
                return "🍔 Fast-food / Burger"
            } else if name.contains("café") || name.contains("cafe") {
                return "☕ Café-Restaurant"
            } else {
                return "🍽️ Restaurant gastronomique"
            }
            
        case .cafe:
            if name.contains("boulangerie") || name.contains("patisserie") {
                return "🥐 Boulangerie-Pâtisserie"
            } else if name.contains("glace") || name.contains("ice cream") {
                return "🍦 Glacier"
            } else {
                return "☕ Café"
            }
            
        case .bar:
            if name.contains("pub") || name.contains("irish") {
                return "🍺 Pub irlandais"
            } else if name.contains("cocktail") || name.contains("mixology") {
                return "🍸 Bar à cocktails"
            } else {
                return "🍺 Bar"
            }
            
        case .museum:
            if name.contains("art") || name.contains("contemporain") {
                return "🎨 Musée d'art contemporain"
            } else if name.contains("histoire") || name.contains("historique") {
                return "🏛️ Musée d'histoire"
            } else if name.contains("science") || name.contains("technique") {
                return "🔬 Musée des sciences"
            } else {
                return "🏛️ Musée"
            }
            
        case .nature:
            if name.contains("jardin") || name.contains("botanique") {
                return "🌺 Jardin botanique"
            } else if name.contains("forêt") || name.contains("bois") {
                return "🌲 Parc forestier"
            } else {
                return "🌳 Parc public"
            }
            
        case .shopping:
            if name.contains("centre") || name.contains("mall") {
                return "🛍️ Centre commercial"
            } else if name.contains("boutique") || name.contains("magasin") {
                return "👕 Boutique"
            } else {
                return "🛒 Centre commercial"
            }
            
        case .swimmingPool:
            return "🏊 Piscine"
            
        case .climbingGym:
            return "🧗 Salle d'escalade"
            
        case .bowling:
            return "🎳 Bowling"
            
        case .laserTag:
            return "🎯 Laser Game"
            
        case .escapeRoom:
            return "🔐 Salle d'évasion"
            
        case .paintball:
            return "🎨 Paintball"
            
        case .karting:
            return "🏎️ Karting"
            
        case .miniGolf:
            return "⛳ Mini-golf"
            
        case .trampolinePark:
            return "🤸 Parc de trampolines"
            
        case .adventurePark:
            return "🌿 Parc d'aventure"
            
        case .zoo:
            return "🦁 Zoo"
            
        case .aquarium:
            return "🐠 Aquarium"
            
        case .waterPark:
            return "🌊 Parc aquatique"
            
        case .iceRink:
            return "⛸️ Patinoire"
            
        case .entertainment:
            return "🎪 Divertissement"
            
        case .historical:
            return "🏛️ Site historique"
            
        case .religious:
            return "⛪ Lieu de culte"
            
        case .culture:
            return "🎭 Centre culturel"
            
        case .sport:
            return "🏃 Centre sportif"
            
        default:
            return "📍 Lieu d'intérêt"
        }
    }
    
    // MARK: - Duration Calculation
    
    private func calculateRecommendedDuration(for location: Location) -> TimeInterval {
        let category = location.category
        let name = location.name.lowercased()
        
        // Durées de base par catégorie (en minutes)
        let baseDuration: TimeInterval
        
        switch category {
        case .restaurant:
            if name.contains("fast") || name.contains("burger") {
                baseDuration = 30 // 30 minutes pour fast-food
            } else {
                baseDuration = 90 // 1h30 pour restaurant
            }
            
        case .cafe:
            if name.contains("boulangerie") || name.contains("patisserie") {
                baseDuration = 20 // 20 minutes pour boulangerie
            } else {
                baseDuration = 45 // 45 minutes pour café
            }
            
        case .bar:
            baseDuration = 60 // 1 heure pour bar
            
        case .museum:
            if name.contains("art") || name.contains("contemporain") {
                baseDuration = 120 // 2 heures pour musée d'art
            } else {
                baseDuration = 90 // 1h30 pour autres musées
            }
            
        case .nature:
            if name.contains("jardin") || name.contains("botanique") {
                baseDuration = 60 // 1 heure pour jardin
            } else {
                baseDuration = 45 // 45 minutes pour parc
            }
            
        case .shopping:
            if name.contains("centre") || name.contains("mall") {
                baseDuration = 180 // 3 heures pour centre commercial
            } else {
                baseDuration = 60 // 1 heure pour boutique
            }
            
        case .swimmingPool:
            baseDuration = 120 // 2 heures pour piscine
            
        case .climbingGym:
            baseDuration = 150 // 2h30 pour escalade
            
        case .bowling:
            baseDuration = 90 // 1h30 pour bowling
            
        case .laserTag:
            baseDuration = 60 // 1 heure pour laser game
            
        case .escapeRoom:
            baseDuration = 75 // 1h15 pour escape room
            
        case .paintball:
            baseDuration = 180 // 3 heures pour paintball
            
        case .karting:
            baseDuration = 60 // 1 heure pour karting
            
        case .miniGolf:
            baseDuration = 45 // 45 minutes pour mini-golf
            
        case .trampolinePark:
            baseDuration = 90 // 1h30 pour trampoline
            
        case .adventurePark:
            baseDuration = 240 // 4 heures pour parc d'aventure
            
        case .zoo:
            baseDuration = 180 // 3 heures pour zoo
            
        case .aquarium:
            baseDuration = 120 // 2 heures pour aquarium
            
        case .waterPark:
            baseDuration = 240 // 4 heures pour parc aquatique
            
        case .iceRink:
            baseDuration = 90 // 1h30 pour patinoire
            
        case .entertainment:
            baseDuration = 120 // 2 heures pour divertissement
            
        case .historical:
            baseDuration = 60 // 1 heure pour site historique
            
        case .religious:
            baseDuration = 30 // 30 minutes pour lieu de culte
            
        case .culture:
            baseDuration = 90 // 1h30 pour centre culturel
            
        case .sport:
            baseDuration = 120 // 2 heures pour centre sportif
            
        default:
            baseDuration = 60 // 1 heure par défaut
        }
        
        return baseDuration * 60 // Convertir en secondes
    }
    
    // MARK: - Visit Tips Generation
    
    private func generateVisitTips(for location: Location) -> [String] {
        let category = location.category
        let name = location.name.lowercased()
        var tips: [String] = []
        
        switch category {
        case .restaurant:
            tips.append("Réservez à l'avance pour éviter l'attente")
            tips.append("Vérifiez les horaires d'ouverture")
            if name.contains("pizza") {
                tips.append("Essayez leurs pizzas maison")
            }
            
        case .cafe:
            tips.append("Parfait pour une pause détente")
            if name.contains("boulangerie") {
                tips.append("Dégustez leurs viennoiseries fraîches")
            }
            
        case .museum:
            tips.append("Vérifiez les expositions temporaires")
            tips.append("Prenez votre temps pour apprécier les œuvres")
            
        case .nature:
            tips.append("Idéal pour une promenade relaxante")
            tips.append("Profitez de la nature et du calme")
            
        case .swimmingPool:
            tips.append("Apportez votre maillot et serviette")
            tips.append("Vérifiez les horaires de cours")
            
        case .climbingGym:
            tips.append("Équipement disponible sur place")
            tips.append("Cours pour débutants disponibles")
            
        case .bowling:
            tips.append("Réservation recommandée le weekend")
            tips.append("Chaussures fournies sur place")
            
        case .laserTag:
            tips.append("Équipement fourni sur place")
            tips.append("Parfait pour un groupe d'amis")
            
        case .escapeRoom:
            tips.append("Réservation obligatoire")
            tips.append("Équipe de 2-6 personnes recommandée")
            
        case .shopping:
            if name.contains("centre") {
                tips.append("Planifiez votre visite")
                tips.append("Parking disponible")
            }
            
        case .culture:
            tips.append("Vérifiez la programmation")
            tips.append("Réservation recommandée")
            
        case .sport:
            tips.append("Équipement disponible")
            tips.append("Cours pour tous niveaux")
            
        default:
            tips.append("Profitez de votre visite !")
        }
        
        return tips
    }
}

// MARK: - Location Extensions

extension Location {
    func withUpdatedAddress(_ newAddress: String) -> Location {
        return Location(
            id: self.id,
            name: self.name,
            address: newAddress,
            latitude: self.latitude,
            longitude: self.longitude,
            category: self.category,
            description: self.description,
            imageURL: self.imageURL,
            rating: self.rating,
            openingHours: self.openingHours,
            recommendedDuration: self.recommendedDuration,
            visitTips: self.visitTips
        )
    }
    
    func withUpdatedDescription(_ newDescription: String) -> Location {
        return Location(
            id: self.id,
            name: self.name,
            address: self.address,
            latitude: self.latitude,
            longitude: self.longitude,
            category: self.category,
            description: newDescription,
            imageURL: self.imageURL,
            rating: self.rating,
            openingHours: self.openingHours,
            recommendedDuration: self.recommendedDuration,
            visitTips: self.visitTips
        )
    }
    
    func withUpdatedRecommendedDuration(_ newDuration: TimeInterval) -> Location {
        return Location(
            id: self.id,
            name: self.name,
            address: self.address,
            latitude: self.latitude,
            longitude: self.longitude,
            category: self.category,
            description: self.description,
            imageURL: self.imageURL,
            rating: self.rating,
            openingHours: self.openingHours,
            recommendedDuration: newDuration,
            visitTips: self.visitTips
        )
    }
    
    func withUpdatedVisitTips(_ newTips: [String]) -> Location {
        return Location(
            id: self.id,
            name: self.name,
            address: self.address,
            latitude: self.latitude,
            longitude: self.longitude,
            category: self.category,
            description: self.description,
            imageURL: self.imageURL,
            rating: self.rating,
            openingHours: self.openingHours,
            recommendedDuration: self.recommendedDuration,
            visitTips: newTips
        )
    }
} 