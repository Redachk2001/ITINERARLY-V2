import Foundation
import MapKit
import CoreLocation

// MARK: - Service de Classification Intelligente
class IntelligentCategoryClassifier {
    
    // MARK: - Configuration IA
    private struct CategoryKeywords {
        let primary: [String: Double]
        let secondary: [String: Double]
        let negative: [String: Double]
        let context: [String: Double]
    }
    
    private let categoryKeywords: [LocationCategory: CategoryKeywords] = [
        .restaurant: CategoryKeywords(
            primary: [
                "restaurant": 15.0, "café": 12.0, "bistrot": 14.0, "brasserie": 14.0,
                "pizzeria": 13.0, "sushi": 13.0, "gastronomique": 16.0, "cuisine": 10.0,
                "menu": 8.0, "dîner": 10.0, "déjeuner": 10.0, "terrasse": 6.0,
                "chef": 12.0, "mets": 9.0, "plat": 8.0, "table": 7.0
            ],
            secondary: [
                "réservation": 5.0, "spécialité": 6.0, "local": 5.0, "traditionnel": 6.0,
                "fusion": 7.0, "bio": 5.0, "végétarien": 6.0, "vegan": 6.0
            ],
            negative: [
                "magasin": -8.0, "boutique": -8.0, "centre commercial": -10.0,
                "musée": -5.0, "théâtre": -5.0, "cinéma": -5.0
            ],
            context: [
                "dégustation": 8.0, "dîner": 10.0, "déjeuner": 10.0, "petit-déjeuner": 9.0,
                "apéritif": 7.0, "dessert": 6.0, "vin": 7.0, "cocktail": 6.0
            ]
        ),
        
        .cafe: CategoryKeywords(
            primary: [
                "café": 15.0, "coffee": 14.0, "salon de thé": 16.0, "thé": 12.0,
                "espresso": 13.0, "cappuccino": 12.0, "latte": 11.0, "pâtisserie": 8.0,
                "macchiato": 12.0, "americano": 11.0, "moka": 11.0
            ],
            secondary: [
                "wifi": 3.0, "terrasse": 5.0, "petit-déjeuner": 7.0, "pause": 6.0,
                "détente": 5.0, "lounge": 6.0, "espace de travail": 4.0
            ],
            negative: [
                "restaurant": -8.0, "bar": -6.0, "pub": -6.0, "nightclub": -8.0
            ],
            context: [
                "pause café": 8.0, "petit-déjeuner": 9.0, "goûter": 7.0, "détente": 6.0
            ]
        ),
        
        .bar: CategoryKeywords(
            primary: [
                "bar": 15.0, "pub": 14.0, "cocktail": 13.0, "whisky": 12.0,
                "bière": 11.0, "vin": 10.0, "happy hour": 12.0, "nightclub": 13.0,
                "disco": 12.0, "lounge": 11.0, "speakeasy": 13.0
            ],
            secondary: [
                "ambiance": 6.0, "soirée": 7.0, "musique": 6.0, "danse": 7.0,
                "tapas": 5.0, "apéritif": 6.0, "digestif": 6.0
            ],
            negative: [
                "restaurant": -8.0, "café": -6.0, "musée": -5.0, "théâtre": -5.0
            ],
            context: [
                "soirée": 8.0, "ambiance": 7.0, "musique live": 8.0, "danse": 7.0
            ]
        ),
        
        .museum: CategoryKeywords(
            primary: [
                "musée": 16.0, "museum": 16.0, "exposition": 13.0, "galerie": 11.0,
                "art": 9.0, "collection": 10.0, "histoire": 8.0, "archéologie": 12.0,
                "ethnographie": 13.0, "anthropologie": 13.0, "paléontologie": 14.0
            ],
            secondary: [
                "visite guidée": 6.0, "audioguide": 5.0, "temporaire": 6.0,
                "permanent": 5.0, "interactif": 6.0, "éducatif": 5.0
            ],
            negative: [
                "restaurant": -8.0, "bar": -6.0, "magasin": -7.0, "cinéma": -5.0
            ],
            context: [
                "culture": 8.0, "éducation": 7.0, "découverte": 7.0, "apprentissage": 6.0
            ]
        ),
        
        .culture: CategoryKeywords(
            primary: [
                "théâtre": 15.0, "cinéma": 14.0, "concert": 13.0, "spectacle": 12.0,
                "opéra": 15.0, "ballet": 14.0, "festival": 11.0, "culture": 8.0,
                "salle de spectacle": 13.0, "auditorium": 12.0, "amphithéâtre": 12.0
            ],
            secondary: [
                "réservation": 5.0, "billet": 5.0, "programme": 6.0, "saison": 5.0,
                "première": 6.0, "représentation": 6.0, "performance": 6.0
            ],
            negative: [
                "restaurant": -8.0, "bar": -6.0, "magasin": -7.0, "sport": -5.0
            ],
            context: [
                "spectacle": 9.0, "art": 8.0, "performance": 8.0, "divertissement": 7.0
            ]
        ),
        
        .sport: CategoryKeywords(
            primary: [
                "sport": 15.0, "gym": 14.0, "fitness": 14.0, "piscine": 13.0,
                "escalade": 13.0, "tennis": 12.0, "football": 11.0, "basketball": 11.0,
                "yoga": 12.0, "pilates": 12.0, "crossfit": 13.0, "boxing": 12.0,
                "musculation": 12.0, "cardio": 11.0, "spinning": 12.0
            ],
            secondary: [
                "entraînement": 7.0, "coaching": 7.0, "cours": 6.0, "séance": 6.0,
                "équipement": 5.0, "vestiaire": 4.0, "douche": 4.0
            ],
            negative: [
                "restaurant": -8.0, "bar": -6.0, "musée": -5.0, "shopping": -6.0
            ],
            context: [
                "entraînement": 8.0, "sport": 9.0, "fitness": 8.0, "bien-être": 7.0
            ]
        ),
        
        .swimmingPool: CategoryKeywords(
            primary: [
                "piscine": 16.0, "aquatique": 14.0, "natation": 13.0, "plongée": 12.0,
                "aquagym": 13.0, "hydrothérapie": 13.0, "bassin": 12.0, "nage": 11.0
            ],
            secondary: [
                "cours": 6.0, "niveaux": 5.0, "profondeur": 5.0, "température": 4.0,
                "vestiaire": 4.0, "douche": 4.0, "sauna": 5.0
            ],
            negative: [
                "restaurant": -8.0, "bar": -6.0, "musée": -5.0, "shopping": -6.0
            ],
            context: [
                "natation": 9.0, "aquatique": 8.0, "bien-être": 7.0, "détente": 6.0
            ]
        ),
        
        .climbingGym: CategoryKeywords(
            primary: [
                "escalade": 16.0, "mur d'escalade": 16.0, "bloc": 13.0, "voie": 13.0,
                "grimpe": 14.0, "boulder": 13.0, "salle d'escalade": 15.0
            ],
            secondary: [
                "niveaux": 6.0, "difficulté": 5.0, "équipement": 5.0, "assurance": 5.0,
                "initiation": 6.0, "cours": 6.0, "matériel": 4.0
            ],
            negative: [
                "restaurant": -8.0, "bar": -6.0, "musée": -5.0, "shopping": -6.0
            ],
            context: [
                "escalade": 9.0, "grimpe": 8.0, "sport": 7.0, "aventure": 7.0
            ]
        ),
        
        .nature: CategoryKeywords(
            primary: [
                "parc": 15.0, "jardin": 14.0, "nature": 13.0, "forêt": 13.0,
                "lac": 12.0, "rivière": 11.0, "montagne": 12.0, "sentier": 11.0,
                "botanique": 13.0, "arboretum": 14.0, "réserve": 12.0, "plage": 11.0
            ],
            secondary: [
                "promenade": 7.0, "randonnée": 8.0, "pique-nique": 6.0, "observation": 6.0,
                "faune": 6.0, "flore": 6.0, "paysage": 6.0, "vista": 6.0
            ],
            negative: [
                "restaurant": -6.0, "bar": -5.0, "musée": -4.0, "shopping": -7.0
            ],
            context: [
                "nature": 9.0, "détente": 7.0, "promenade": 8.0, "grand air": 7.0
            ]
        ),
        
        .shopping: CategoryKeywords(
            primary: [
                "centre commercial": 15.0, "magasin": 13.0, "boutique": 12.0,
                "shopping": 14.0, "mall": 14.0, "galerie": 11.0, "market": 10.0,
                "dépôt-vente": 11.0, "friperie": 10.0, "antiquités": 11.0
            ],
            secondary: [
                "marque": 5.0, "soldes": 6.0, "promotion": 5.0, "nouveauté": 5.0,
                "collection": 5.0, "mode": 6.0, "accessoires": 5.0
            ],
            negative: [
                "restaurant": -6.0, "bar": -5.0, "musée": -4.0, "sport": -5.0
            ],
            context: [
                "shopping": 8.0, "achats": 7.0, "mode": 7.0, "détente": 5.0
            ]
        ),
        
        .historical: CategoryKeywords(
            primary: [
                "historique": 15.0, "monument": 14.0, "château": 14.0, "fort": 13.0,
                "cité": 12.0, "ruines": 13.0, "archéologique": 14.0, "patrimoine": 12.0,
                "citadelle": 13.0, "donjon": 12.0, "remparts": 12.0
            ],
            secondary: [
                "visite guidée": 6.0, "audioguide": 5.0, "histoire": 7.0,
                "architecture": 6.0, "médiéval": 7.0, "antique": 7.0
            ],
            negative: [
                "restaurant": -6.0, "bar": -5.0, "magasin": -7.0, "sport": -5.0
            ],
            context: [
                "histoire": 8.0, "patrimoine": 7.0, "culture": 7.0, "découverte": 6.0
            ]
        ),
        
        .religious: CategoryKeywords(
            primary: [
                "église": 16.0, "cathédrale": 16.0, "temple": 15.0, "mosquée": 15.0,
                "synagogue": 15.0, "chapelle": 14.0, "basilique": 15.0, "sanctuaire": 14.0,
                "abbaye": 14.0, "monastère": 14.0, "couvent": 13.0
            ],
            secondary: [
                "culte": 6.0, "prière": 5.0, "messe": 6.0, "architecture": 6.0,
                "vitraux": 6.0, "orgue": 5.0, "clocher": 5.0
            ],
            negative: [
                "restaurant": -8.0, "bar": -7.0, "magasin": -8.0, "sport": -6.0
            ],
            context: [
                "spiritualité": 7.0, "paix": 6.0, "architecture": 7.0, "histoire": 6.0
            ]
        ),
        
        .entertainment: CategoryKeywords(
            primary: [
                "bowling": 16.0, "laser game": 16.0, "escape room": 16.0, "karting": 16.0,
                "trampoline": 16.0, "paintball": 16.0, "mini golf": 15.0, "arcade": 14.0,
                "jeux": 12.0, "divertissement": 11.0, "loisirs": 10.0
            ],
            secondary: [
                "jeu": 6.0, "compétition": 6.0, "équipe": 5.0, "score": 5.0,
                "niveau": 5.0, "challenge": 6.0, "fun": 5.0
            ],
            negative: [
                "restaurant": -6.0, "bar": -5.0, "musée": -4.0, "sport": -3.0
            ],
            context: [
                "divertissement": 8.0, "jeu": 7.0, "fun": 6.0, "loisirs": 6.0
            ]
        ),
        
        .iceRink: CategoryKeywords(
            primary: [
                "patinoire": 16.0, "patinage": 15.0, "glace": 13.0, "hockey": 12.0,
                "curling": 13.0, "figure skating": 13.0, "speed skating": 13.0
            ],
            secondary: [
                "location": 5.0, "cours": 6.0, "niveaux": 5.0, "équipement": 4.0,
                "vestiaire": 4.0, "température": 4.0
            ],
            negative: [
                "restaurant": -8.0, "bar": -6.0, "musée": -5.0, "shopping": -6.0
            ],
            context: [
                "patinage": 9.0, "glace": 8.0, "sport": 7.0, "hiver": 6.0
            ]
        ),
        
        .waterPark: CategoryKeywords(
            primary: [
                "parc aquatique": 16.0, "water park": 16.0, "toboggan": 13.0,
                "piscine à vagues": 13.0, "rivière sauvage": 13.0, "aquapark": 15.0
            ],
            secondary: [
                "attractions": 6.0, "toboggans": 7.0, "vagues": 6.0, "piscine": 5.0,
                "vestiaire": 4.0, "douche": 4.0, "température": 4.0
            ],
            negative: [
                "restaurant": -6.0, "bar": -5.0, "musée": -4.0, "sport": -3.0
            ],
            context: [
                "aquatique": 8.0, "attractions": 7.0, "détente": 6.0, "famille": 6.0
            ]
        ),
        
        .adventurePark: CategoryKeywords(
            primary: [
                "parc d'aventure": 16.0, "accrobranche": 16.0, "tyrolienne": 14.0,
                "parcours": 12.0, "aventure": 11.0, "via ferrata": 15.0,
                "adventure park": 16.0, "tree climbing": 15.0
            ],
            secondary: [
                "niveaux": 6.0, "difficulté": 6.0, "équipement": 5.0, "sécurité": 5.0,
                "moniteur": 6.0, "initiation": 6.0, "challenge": 6.0
            ],
            negative: [
                "restaurant": -6.0, "bar": -5.0, "musée": -4.0, "shopping": -6.0
            ],
            context: [
                "aventure": 9.0, "nature": 7.0, "challenge": 7.0, "adrénaline": 6.0
            ]
        ),
        
        .zoo: CategoryKeywords(
            primary: [
                "zoo": 16.0, "parc animalier": 16.0, "safari": 15.0, "réserve": 13.0,
                "faune": 12.0, "animaux": 11.0, "ménagerie": 14.0, "vivarium": 13.0
            ],
            secondary: [
                "espèces": 6.0, "conservation": 6.0, "éducation": 5.0, "visite": 5.0,
                "nourrissage": 6.0, "spectacle": 5.0, "enclos": 4.0
            ],
            negative: [
                "restaurant": -6.0, "bar": -5.0, "musée": -4.0, "shopping": -6.0
            ],
            context: [
                "animaux": 9.0, "nature": 7.0, "éducation": 6.0, "famille": 6.0
            ]
        ),
        
        .aquarium: CategoryKeywords(
            primary: [
                "aquarium": 16.0, "marin": 13.0, "poissons": 11.0, "océan": 12.0,
                "mer": 10.0, "corail": 12.0, "récif": 12.0, "piranha": 11.0
            ],
            secondary: [
                "espèces": 6.0, "conservation": 6.0, "éducation": 5.0, "visite": 5.0,
                "nourrissage": 6.0, "spectacle": 5.0, "bassin": 4.0
            ],
            negative: [
                "restaurant": -6.0, "bar": -5.0, "musée": -4.0, "shopping": -6.0
            ],
            context: [
                "marin": 8.0, "océan": 7.0, "éducation": 6.0, "découverte": 6.0
            ]
        )
    ]
    
    // MARK: - Classification Intelligente
    func classifyLocation(_ mapItem: MKMapItem, query: String = "") -> LocationCategory {
        let name = mapItem.name?.lowercased() ?? ""
        let category = mapItem.pointOfInterestCategory?.rawValue.lowercased() ?? ""
        let address = mapItem.placemark.formattedAddress.lowercased()
        
        // Combiner toutes les informations
        let combinedText = "\(name) \(category) \(address) \(query.lowercased())"
        
        // Classification IA avec score de confiance
        let categoryScores = analyzeWithAI(combinedText)
        
        // Retourner la catégorie avec le score le plus élevé
        let bestCategory = categoryScores.max(by: { $0.value < $1.value })
        
        print("🧠 Classification IA - \(name)")
        print("   Score le plus élevé: \(bestCategory?.key.rawValue ?? "inconnu") (\(bestCategory?.value ?? 0))")
        
        return bestCategory?.key ?? .cafe
    }
    
    // MARK: - Analyse IA
    private func analyzeWithAI(_ text: String) -> [LocationCategory: Double] {
        var scores: [LocationCategory: Double] = [:]
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        
        for (category, keywords) in categoryKeywords {
            var categoryScore = 0.0
            
            // Analyse des mots primaires (poids élevé)
            for word in words {
                let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
                if let score = keywords.primary[cleanWord] {
                    categoryScore += score
                }
            }
            
            // Analyse des mots secondaires (poids moyen)
            for word in words {
                let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
                if let score = keywords.secondary[cleanWord] {
                    categoryScore += score * 0.7
                }
            }
            
            // Analyse des mots négatifs (pénalisation)
            for word in words {
                let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
                if let score = keywords.negative[cleanWord] {
                    categoryScore += score
                }
            }
            
            // Analyse contextuelle (bonus)
            for word in words {
                let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
                if let score = keywords.context[cleanWord] {
                    categoryScore += score * 0.5
                }
            }
            
            // Bonus pour les correspondances exactes
            if let exactMatch = findExactMatch(text: text, category: category) {
                categoryScore += exactMatch
            }
            
            scores[category] = categoryScore
        }
        
        return scores
    }
    
    // MARK: - Correspondances exactes
    private func findExactMatch(text: String, category: LocationCategory) -> Double? {
        let exactMatches: [LocationCategory: [String]] = [
            .swimmingPool: ["piscine", "swimming pool", "aquatique"],
            .climbingGym: ["escalade", "climbing gym", "mur d'escalade", "salle d'escalade"],
            .iceRink: ["patinoire", "ice rink", "patinage"],
            .waterPark: ["parc aquatique", "water park", "aquapark"],
            .adventurePark: ["parc d'aventure", "adventure park", "accrobranche"],
            .bowling: ["bowling", "quilles"],
            .miniGolf: ["mini golf", "putting"],
            .escapeRoom: ["escape room", "escape game", "énigme"],
            .laserTag: ["laser game", "laser tag"],
            .paintball: ["paintball"],
            .karting: ["karting", "kart"],
            .trampolinePark: ["trampoline", "rebond"]
        ]
        
        guard let matches = exactMatches[category] else { return nil }
        
        for match in matches {
            if text.contains(match.lowercased()) {
                return 20.0 // Bonus élevé pour correspondance exacte
            }
        }
        
        return nil
    }
    
    // MARK: - Classification par défaut basée sur MKPointOfInterestCategory
    func classifyByPointOfInterest(_ pointOfInterestCategory: MKPointOfInterestCategory?) -> LocationCategory {
        guard let category = pointOfInterestCategory else { return .cafe }
        
        switch category {
        case .restaurant, .bakery, .brewery, .foodMarket:
            return .restaurant
        case .cafe:
            return .cafe
        case .museum, .library:
            return .museum
        case .theater, .movieTheater:
            return .culture
        case .fitnessCenter, .stadium:
            return .sport
        case .store, .gasStation, .atm:
            return .shopping
        case .park, .beach, .nationalPark:
            return .nature
        case .nightlife:
            return .bar
        case .amusementPark:
            return .entertainment
        case .aquarium:
            return .aquarium
        case .zoo:
            return .zoo
        default:
            return .cafe
        }
    }
} 