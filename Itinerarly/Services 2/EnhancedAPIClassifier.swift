import Foundation
import MapKit
import CoreLocation

// MARK: - Service d'API Amélioré pour Classification
class EnhancedAPIClassifier {
    
    // MARK: - Configuration des APIs
    private let classifier = IntelligentCategoryClassifier()
    private let placeSearchService = PlaceSearchService()
    
    // MARK: - Classification Multi-Sources
    func classifyWithMultipleSources(_ mapItem: MKMapItem, query: String = "") async -> LocationCategory {
        
        // 1. Classification IA locale
        let aiCategory = classifier.classifyLocation(mapItem, query: query)
        
        // 2. Classification par Point of Interest
        let poiCategory = classifier.classifyByPointOfInterest(mapItem.pointOfInterestCategory)
        
        // 3. Classification par recherche API enrichie
        let apiCategory = await classifyWithAPIEnrichment(mapItem, query: query)
        
        // 4. Analyse de confiance et fusion
        let finalCategory = mergeClassifications(
            aiCategory: aiCategory,
            poiCategory: poiCategory,
            apiCategory: apiCategory,
            mapItem: mapItem,
            query: query
        )
        
        print("🔍 Classification Multi-Sources - \(mapItem.name ?? "Inconnu")")
        print("   IA: \(aiCategory.rawValue)")
        print("   POI: \(poiCategory.rawValue)")
        print("   API: \(apiCategory.rawValue)")
        print("   Final: \(finalCategory.rawValue)")
        
        return finalCategory
    }
    
    // MARK: - Enrichissement par API
    private func classifyWithAPIEnrichment(_ mapItem: MKMapItem, query: String) async -> LocationCategory {
        guard let name = mapItem.name else { return .cafe }
        
        // Recherche enrichie avec des termes spécifiques
        let enrichedQueries = generateEnrichedQueries(for: name, originalQuery: query)
        
        for enrichedQuery in enrichedQueries {
            do {
                let searchResults = try await performEnrichedSearch(query: enrichedQuery, near: mapItem.placemark.coordinate)
                
                if let bestMatch = findBestMatch(in: searchResults, for: mapItem) {
                    return bestMatch
                }
            } catch {
                print("⚠️ Erreur recherche enrichie: \(error.localizedDescription)")
            }
        }
        
        return .cafe // Fallback
    }
    
    // MARK: - Génération de requêtes enrichies
    private func generateEnrichedQueries(for name: String, originalQuery: String) -> [String] {
        var queries: [String] = []
        let lowercasedName = name.lowercased()
        
        // Requêtes spécifiques basées sur le nom
        if lowercasedName.contains("piscine") || lowercasedName.contains("swimming") {
            queries.append("piscine natation aquatique")
            queries.append("swimming pool aquatic center")
        }
        
        if lowercasedName.contains("escalade") || lowercasedName.contains("climbing") {
            queries.append("escalade mur d'escalade salle d'escalade")
            queries.append("climbing gym boulder wall")
        }
        
        if lowercasedName.contains("patinoire") || lowercasedName.contains("ice") {
            queries.append("patinoire patinage glace")
            queries.append("ice rink skating")
        }
        
        if lowercasedName.contains("bowling") {
            queries.append("bowling quilles")
        }
        
        if lowercasedName.contains("mini golf") {
            queries.append("mini golf putting")
        }
        
        if lowercasedName.contains("escape") {
            queries.append("escape room escape game énigme")
        }
        
        if lowercasedName.contains("laser") {
            queries.append("laser game laser tag")
        }
        
        if lowercasedName.contains("paintball") {
            queries.append("paintball")
        }
        
        if lowercasedName.contains("kart") {
            queries.append("karting kart")
        }
        
        if lowercasedName.contains("trampoline") {
            queries.append("trampoline rebond")
        }
        
        if lowercasedName.contains("parc aquatique") {
            queries.append("parc aquatique water park aquapark")
        }
        
        if lowercasedName.contains("parc d'aventure") {
            queries.append("parc d'aventure adventure park accrobranche")
        }
        
        if lowercasedName.contains("zoo") {
            queries.append("zoo parc animalier")
        }
        
        if lowercasedName.contains("aquarium") {
            queries.append("aquarium marin")
        }
        
        // Requêtes génériques si aucune correspondance spécifique
        if queries.isEmpty {
            queries.append(originalQuery)
            queries.append(name)
        }
        
        return queries
    }
    
    // MARK: - Recherche enrichie
    private func performEnrichedSearch(query: String, near coordinate: CLLocationCoordinate2D) async throws -> [MKMapItem] {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        searchRequest.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )
        
        let search = MKLocalSearch(request: searchRequest)
        let response = try await search.start()
        
        return response.mapItems
    }
    
    // MARK: - Recherche du meilleur match
    private func findBestMatch(in searchResults: [MKMapItem], for originalMapItem: MKMapItem) -> LocationCategory? {
        guard let originalName = originalMapItem.name else { return nil }
        
        // Trouver le résultat le plus proche du nom original
        let bestMatch = searchResults.first { mapItem in
            guard let name = mapItem.name else { return false }
            
            // Correspondance exacte ou très proche
            let similarity = calculateNameSimilarity(originalName, name)
            return similarity > 0.7
        }
        
        if let bestMatch = bestMatch {
            return classifier.classifyLocation(bestMatch)
        }
        
        return nil
    }
    
    // MARK: - Calcul de similarité de noms
    private func calculateNameSimilarity(_ name1: String, _ name2: String) -> Double {
        let lower1 = name1.lowercased()
        let lower2 = name2.lowercased()
        
        // Correspondance exacte
        if lower1 == lower2 {
            return 1.0
        }
        
        // Correspondance partielle
        if lower1.contains(lower2) || lower2.contains(lower1) {
            return 0.8
        }
        
        // Correspondance de mots-clés
        let words1 = lower1.components(separatedBy: .whitespacesAndNewlines)
        let words2 = lower2.components(separatedBy: .whitespacesAndNewlines)
        
        let commonWords = words1.filter { word in
            words2.contains(word)
        }
        
        if !commonWords.isEmpty {
            return Double(commonWords.count) / Double(max(words1.count, words2.count))
        }
        
        return 0.0
    }
    
    // MARK: - Fusion des classifications
    private func mergeClassifications(
        aiCategory: LocationCategory,
        poiCategory: LocationCategory,
        apiCategory: LocationCategory,
        mapItem: MKMapItem,
        query: String
    ) -> LocationCategory {
        
        var scores: [LocationCategory: Double] = [:]
        
        // Score pour la classification IA
        scores[aiCategory, default: 0] += 10.0
        
        // Score pour la classification POI
        scores[poiCategory, default: 0] += 8.0
        
        // Score pour la classification API
        scores[apiCategory, default: 0] += 12.0
        
        // Bonus pour les correspondances exactes
        if aiCategory == poiCategory {
            scores[aiCategory, default: 0] += 5.0
        }
        
        if aiCategory == apiCategory {
            scores[aiCategory, default: 0] += 5.0
        }
        
        if poiCategory == apiCategory {
            scores[poiCategory, default: 0] += 5.0
        }
        
        // Bonus pour les catégories spécifiques détectées
        if let specificBonus = getSpecificCategoryBonus(mapItem: mapItem, query: query) {
            scores[specificBonus.category, default: 0] += specificBonus.score
        }
        
        // Retourner la catégorie avec le score le plus élevé
        return scores.max(by: { $0.value < $1.value })?.key ?? aiCategory
    }
    
    // MARK: - Bonus pour catégories spécifiques
    private func getSpecificCategoryBonus(mapItem: MKMapItem, query: String) -> (category: LocationCategory, score: Double)? {
        guard let name = mapItem.name?.lowercased() else { return nil }
        
        let specificCategories: [(keywords: [String], category: LocationCategory, score: Double)] = [
            (["piscine", "swimming", "aquatique"], .swimmingPool, 15.0),
            (["escalade", "climbing", "mur d'escalade"], .climbingGym, 15.0),
            (["patinoire", "ice", "patinage"], .iceRink, 15.0),
            (["bowling", "quilles"], .bowling, 15.0),
            (["mini golf", "putting"], .miniGolf, 15.0),
            (["escape", "énigme"], .escapeRoom, 15.0),
            (["laser", "tag"], .laserTag, 15.0),
            (["paintball"], .paintball, 15.0),
            (["kart", "karting"], .karting, 15.0),
            (["trampoline", "rebond"], .trampolinePark, 15.0),
            (["parc aquatique", "water park"], .waterPark, 15.0),
            (["parc d'aventure", "adventure park"], .adventurePark, 15.0),
            (["zoo", "animal"], .zoo, 15.0),
            (["aquarium", "marin"], .aquarium, 15.0)
        ]
        
        for (keywords, category, score) in specificCategories {
            for keyword in keywords {
                if name.contains(keyword) {
                    return (category, score)
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Classification rapide pour performance
    func quickClassify(_ mapItem: MKMapItem, query: String = "") -> LocationCategory {
        return classifier.classifyLocation(mapItem, query: query)
    }
    
    // MARK: - Classification avec validation
    func classifyWithValidation(_ mapItem: MKMapItem, query: String = "") async -> (category: LocationCategory, confidence: Double) {
        let aiCategory = classifier.classifyLocation(mapItem, query: query)
        let poiCategory = classifier.classifyByPointOfInterest(mapItem.pointOfInterestCategory)
        
        let confidence: Double
        if aiCategory == poiCategory {
            confidence = 0.9
        } else {
            confidence = 0.7
        }
        
        return (aiCategory, confidence)
    }
} 