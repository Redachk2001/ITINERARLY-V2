import Foundation
import CoreLocation
import Combine

// MARK: - AI Activity Service
class AIActivityService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Configuration des APIs IA gratuites
    private let huggingFaceAPIKey = "hf_YOUR_API_KEY" // Remplacer par votre clé Hugging Face
    private let openAIAPIKey = "sk-YOUR_API_KEY" // Remplacer par votre clé OpenAI (optionnel)
    
    private let session = URLSession.shared
    
    // MARK: - Generate AI-Powered Activity Suggestions
    func generateActivitySuggestions(
        filter: ActivityFilter,
        userLocation: CLLocation,
        availableActivities: [Location]
    ) -> AnyPublisher<[ActivitySuggestion], Error> {
        print("🤖 AIActivityService - Génération de suggestions IA")
        
        isLoading = true
        errorMessage = nil
        
        // Créer le prompt pour l'IA
        let prompt = createActivityPrompt(filter: filter, userLocation: userLocation, activities: availableActivities)
        
        // Essayer d'abord Hugging Face (gratuit)
        return generateWithHuggingFace(prompt: prompt, filter: filter, activities: availableActivities)
            .catch { error -> AnyPublisher<[ActivitySuggestion], Error> in
                print("❌ Hugging Face échoué: \(error), fallback vers suggestions intelligentes")
                // Fallback vers suggestions intelligentes sans API
                return self.generateSmartSuggestions(filter: filter, userLocation: userLocation, activities: availableActivities)
            }
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    self?.isLoading = false
                }
            )
            .eraseToAnyPublisher()
    }
    
    // MARK: - Hugging Face API (Gratuit)
    private func generateWithHuggingFace(
        prompt: String,
        filter: ActivityFilter,
        activities: [Location]
    ) -> AnyPublisher<[ActivitySuggestion], Error> {
        print("🤖 AIActivityService - Utilisation Hugging Face")
        
        // URL de l'API Hugging Face pour la génération de texte
        let url = URL(string: "https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(huggingFaceAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "inputs": prompt,
            "parameters": [
                "max_length": 500,
                "temperature": 0.7,
                "return_full_text": false
            ] as [String: Any]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: HuggingFaceResponse.self, decoder: JSONDecoder())
            .map { response in
                // Parser la réponse et créer des suggestions
                return self.parseAIResponse(response.generated_text ?? "", filter: filter, activities: activities)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Smart Suggestions (Fallback sans API)
    private func generateSmartSuggestions(
        filter: ActivityFilter,
        userLocation: CLLocation,
        activities: [Location]
    ) -> AnyPublisher<[ActivitySuggestion], Error> {
        print("🧠 AIActivityService - Génération de suggestions intelligentes")
        
        // Analyser le contexte utilisateur
        let context = analyzeUserContext(filter: filter, userLocation: userLocation)
        
        // Filtrer et scorer les activités
        let scoredActivities = activities.compactMap { (activity: Location) in
            return scoreActivity(activity, context: context, userLocation: userLocation, filter: filter)
        }
        .sorted { (first: AIActivityScoredActivity, second: AIActivityScoredActivity) in
            first.score > second.score
        }
        .prefix(10)
        
        // Créer les suggestions avec IA locale
        let suggestions = scoredActivities.map { (scoredActivity: AIActivityScoredActivity) in
            createEnhancedSuggestion(scoredActivity: scoredActivity, context: context, filter: filter)
        }
        
        return Just(suggestions)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Context Analysis
    private func analyzeUserContext(filter: ActivityFilter, userLocation: CLLocation) -> UserContext {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let isWeekend = Calendar.current.isDateInWeekend(Date())
        
        // Analyser le profil temporel
        let timeProfile: TimeProfile
        if filter.availableTime < 3600 { // < 1h
            timeProfile = .quick
        } else if filter.availableTime < 7200 { // < 2h
            timeProfile = .moderate
        } else {
            timeProfile = .extended
        }
        
        // Analyser le profil de mobilité
        let mobilityProfile: MobilityProfile
        switch filter.transportMode {
        case .walking:
            mobilityProfile = .pedestrian
        case .cycling:
            mobilityProfile = .active
        case .driving:
            mobilityProfile = .motorized
        case .publicTransport:
            mobilityProfile = .eco
        }
        
        // Analyser le profil d'activité
        let activityProfile: ActivityProfile
        if let category = filter.category {
            switch category {
            case .restaurant, .cafe, .bar:
                activityProfile = .social
            case .sport, .nature:
                activityProfile = .active
            case .culture, .museum, .historical:
                activityProfile = .cultural
            case .shopping:
                activityProfile = .commercial
            case .entertainment:
                activityProfile = .entertainment
            default:
                activityProfile = .explorer
            }
        } else {
            activityProfile = .explorer
        }
        
        return UserContext(
            timeProfile: timeProfile,
            mobilityProfile: mobilityProfile,
            activityProfile: activityProfile,
            currentHour: currentHour,
            isWeekend: isWeekend,
            maxDistance: filter.maxDistance,
            availableTime: filter.availableTime
        )
    }
    
    // MARK: - Activity Scoring
    private func scoreActivity(_ activity: Location, context: UserContext, userLocation: CLLocation, filter: ActivityFilter) -> AIActivityScoredActivity? {
        let distance = userLocation.distance(from: activity.clLocation) / 1000.0
        
        // Vérifier la distance
        guard distance <= filter.maxDistance else { return nil }
        
        var score: Double = 0.0
        
        // Score de base selon la catégorie
        score += categoryScore(activity.category, profile: context.activityProfile)
        
        // Score de distance (plus proche = mieux)
        score += distanceScore(distance, maxDistance: filter.maxDistance)
        
        // Score temporel
        score += timeScore(activity, context: context)
        
        // Score de mobilité
        score += mobilityScore(distance, profile: context.mobilityProfile)
        
        // Score de qualité (rating)
        if let rating = activity.rating {
            score += (rating - 3.0) / 2.0 * 0.15 // Normaliser 3-5 vers 0-0.15
        }
        
        // Score de pertinence contextuelle
        score += contextualScore(activity, context: context)
        
        return AIActivityScoredActivity(location: activity, score: score, distance: distance)
    }
    
    private func categoryScore(_ category: LocationCategory, profile: ActivityProfile) -> Double {
        let categoryScores: [ActivityProfile: [LocationCategory: Double]] = [
            .social: [
                .restaurant: 0.9, .cafe: 0.8, .bar: 0.85, .entertainment: 0.7, .culture: 0.6
            ],
            .active: [
                .sport: 0.95, .nature: 0.9, .entertainment: 0.6, .historical: 0.4
            ],
            .cultural: [
                .culture: 0.95, .museum: 0.9, .historical: 0.85, .restaurant: 0.6
            ],
            .commercial: [
                .shopping: 0.95, .cafe: 0.7, .restaurant: 0.6
            ],
            .entertainment: [
                .entertainment: 0.95, .bar: 0.8, .culture: 0.7, .restaurant: 0.6
            ],
            .explorer: [
                .historical: 0.8, .nature: 0.8, .culture: 0.75, .museum: 0.7, .religious: 0.85,
            .adventurePark: 0.95, .iceRink: 0.9, .swimmingPool: 0.85, .climbingGym: 0.9,
            .escapeRoom: 0.85, .laserTag: 0.9, .bowling: 0.8, .miniGolf: 0.75,
            .paintball: 0.95, .karting: 0.9, .trampolinePark: 0.85, .waterPark: 0.9,
            .zoo: 0.8, .aquarium: 0.8
            ]
        ]
        
        return categoryScores[profile]?[category] ?? 0.5
    }
    
    private func distanceScore(_ distance: Double, maxDistance: Double) -> Double {
        return (maxDistance - distance) / maxDistance * 0.2
    }
    
    private func timeScore(_ activity: Location, context: UserContext) -> Double {
        let estimatedDuration = estimateActivityDuration(activity.category)
        
        // Vérifier si l'activité peut se faire dans le temps disponible
        guard estimatedDuration <= context.availableTime else { return -0.5 }
        
        // Bonus si l'activité utilise bien le temps disponible (70-90% du temps)
        let timeUtilization = estimatedDuration / context.availableTime
        if timeUtilization >= 0.7 && timeUtilization <= 0.9 {
            return 0.15
        } else if timeUtilization >= 0.5 {
            return 0.1
        }
        return 0.05
    }
    
    private func mobilityScore(_ distance: Double, profile: MobilityProfile) -> Double {
        switch profile {
        case .pedestrian:
            return distance <= 1.0 ? 0.15 : (distance <= 2.0 ? 0.05 : -0.1)
        case .active:
            return distance <= 5.0 ? 0.15 : (distance <= 10.0 ? 0.1 : 0.0)
        case .motorized:
            return distance >= 2.0 ? 0.1 : 0.05
        case .eco:
            return distance <= 15.0 ? 0.1 : 0.0
        }
    }
    
    private func contextualScore(_ activity: Location, context: UserContext) -> Double {
        var score: Double = 0.0
        
        // Score selon l'heure
        switch activity.category {
        case .restaurant:
            if (context.currentHour >= 12 && context.currentHour <= 14) || 
               (context.currentHour >= 19 && context.currentHour <= 22) {
                score += 0.2
            }
        case .cafe:
            if context.currentHour >= 8 && context.currentHour <= 18 {
                score += 0.15
            }
        case .bar:
            if context.currentHour >= 17 {
                score += 0.15
            }
        case .museum, .culture:
            if context.currentHour >= 10 && context.currentHour <= 17 {
                score += 0.1
            }
        default:
            break
        }
        
        // Score selon le weekend
        if context.isWeekend {
            switch activity.category {
            case .entertainment, .nature, .culture:
                score += 0.1
            default:
                break
            }
        }
        
        return score
    }
    
    // MARK: - Enhanced Suggestion Creation
    private func createEnhancedSuggestion(scoredActivity: AIActivityScoredActivity, context: UserContext, filter: ActivityFilter) -> ActivitySuggestion {
        let activity = scoredActivity.location
        let estimatedDuration = estimateActivityDuration(activity.category)
        
        // Générer des raisons personnalisées avec IA
        let reasons = generatePersonalizedReasons(activity: activity, context: context)
        
        // Estimer si c'est ouvert
        let isOpen = estimateOpenStatus(activity: activity, currentHour: context.currentHour)
        
        return ActivitySuggestion(
            id: "ai_suggestion_\(activity.id)",
            location: activity,
            estimatedDuration: estimatedDuration,
            distanceFromUser: scoredActivity.distance,
            matchScore: scoredActivity.score,
            reasonsToVisit: reasons,
            currentlyOpen: isOpen
        )
    }
    
    // MARK: - Personalized Reasons Generation
    private func generatePersonalizedReasons(activity: Location, context: UserContext) -> [String] {
        var reasons: [String] = []
        
        // Raisons basées sur le profil d'activité
        switch context.activityProfile {
        case .social:
            reasons.append("Parfait pour socialiser")
            if activity.category == .restaurant {
                reasons.append("Idéal pour un repas convivial")
            }
        case .active:
            if activity.category == .sport {
                reasons.append("Excellent pour rester en forme")
            } else if activity.category == .nature {
                reasons.append("Parfait pour une activité en plein air")
            }
        case .cultural:
            reasons.append("Enrichissant culturellement")
            if activity.category == .museum {
                reasons.append("Collections remarquables")
            }
        case .commercial:
            reasons.append("Large choix disponible")
        case .entertainment:
            reasons.append("Divertissement garanti")
        case .explorer:
            reasons.append("Découverte authentique")
        }
        
        // Raisons basées sur le temps disponible
        switch context.timeProfile {
        case .quick:
            reasons.append("Parfait pour une pause rapide")
        case .moderate:
            reasons.append("Durée idéale pour votre temps libre")
        case .extended:
            reasons.append("Vous avez le temps de profiter pleinement")
        }
        
        // Raisons basées sur la mobilité
        switch context.mobilityProfile {
        case .pedestrian:
            reasons.append("Accessible à pied facilement")
        case .active:
            reasons.append("Parfait pour une sortie active")
        case .motorized:
            reasons.append("Stationnement disponible")
        case .eco:
            reasons.append("Accessible en transport public")
        }
        
        // Raisons contextuelles
        if context.isWeekend {
            reasons.append("Idéal pour le weekend")
        }
        
        if let rating = activity.rating, rating >= 4.5 {
            reasons.append("Très bien noté par les visiteurs")
        }
        
        return Array(reasons.prefix(3))
    }
    
    // MARK: - Helper Methods
    private func createActivityPrompt(filter: ActivityFilter, userLocation: CLLocation, activities: [Location]) -> String {
        let categoryText = filter.category?.displayName ?? "toute activité"
        let timeText = formatDuration(filter.availableTime)
        let distanceText = String(format: "%.1f km", filter.maxDistance)
        let transportText = filter.transportMode.displayName
        
        return """
        Utilisateur cherche \(categoryText) avec les contraintes suivantes:
        - Temps disponible: \(timeText)
        - Distance maximale: \(distanceText)
        - Transport: \(transportText)
        - Heure actuelle: \(Date())
        
        Activités disponibles: \(activities.map { $0.name }.joined(separator: ", "))
        
        Recommande les 5 meilleures activités avec des raisons personnalisées.
        """
    }
    
    private func parseAIResponse(_ response: String, filter: ActivityFilter, activities: [Location]) -> [ActivitySuggestion] {
        // Parser la réponse de l'IA (simplifiée pour cet exemple)
        // En production, utiliser un parser plus sophistiqué
        return []
    }
    
    private func estimateActivityDuration(_ category: LocationCategory) -> TimeInterval {
        let durations: [LocationCategory: TimeInterval] = [
            .restaurant: 3600, // 1h
            .culture: 5400, // 1h30
            .sport: 7200, // 2h
            .shopping: 4800, // 1h20
            .nature: 6000, // 1h40
            .entertainment: 9000, // 2h30
            .historical: 4500, // 1h15
            .museum: 5400, // 1h30
            .bar: 7200, // 2h
            .cafe: 1800, // 30min
            .religious: 2700, // 45min
            .adventurePark: 14400, // 4h
            .iceRink: 5400, // 1h30
            .swimmingPool: 7200, // 2h
            .climbingGym: 5400, // 1h30
            .escapeRoom: 3600, // 1h
            .laserTag: 3600, // 1h
            .bowling: 5400, // 1h30
            .miniGolf: 3600, // 1h
            .paintball: 7200, // 2h
            .karting: 3600, // 1h
            .trampolinePark: 5400, // 1h30
            .waterPark: 14400, // 4h
            .zoo: 10800, // 3h
            .aquarium: 7200 // 2h
        ]
        
        return durations[category] ?? 3600
    }
    
    private func estimateOpenStatus(activity: Location, currentHour: Int) -> Bool {
        switch activity.category {
        case .restaurant:
            return (currentHour >= 12 && currentHour <= 14) || (currentHour >= 19 && currentHour <= 23)
        case .cafe:
            return currentHour >= 7 && currentHour <= 19
        case .bar:
            return currentHour >= 17 || currentHour <= 2
        case .museum, .culture:
            return currentHour >= 10 && currentHour <= 18
        case .shopping:
            return currentHour >= 10 && currentHour <= 19
        default:
            return currentHour >= 9 && currentHour <= 18
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes > 0 ? " \(minutes)min" : "")"
        } else {
            return "\(minutes)min"
        }
    }
}

// MARK: - Data Models
struct UserContext {
    let timeProfile: TimeProfile
    let mobilityProfile: MobilityProfile
    let activityProfile: ActivityProfile
    let currentHour: Int
    let isWeekend: Bool
    let maxDistance: Double
    let availableTime: TimeInterval
}

enum TimeProfile {
    case quick      // < 1h
    case moderate   // 1-2h
    case extended   // > 2h
}

enum MobilityProfile {
    case pedestrian // À pied
    case active     // Vélo
    case motorized  // Voiture
    case eco        // Transport public
}

enum ActivityProfile {
    case social       // Restaurant, café, bar
    case active       // Sport, nature
    case cultural     // Culture, musée
    case commercial   // Shopping
    case entertainment // Divertissement
    case explorer     // Découverte
}

struct AIActivityScoredActivity {
    let location: Location
    let score: Double
    let distance: Double
}

struct HuggingFaceResponse: Codable {
    let generated_text: String?
}

// MARK: - AI Activity Errors
enum AIActivityError: Error, LocalizedError {
    case apiKeyMissing
    case networkError
    case parsingError
    case noSuggestions
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "Clé API manquante"
        case .networkError:
            return "Erreur de connexion"
        case .parsingError:
            return "Erreur de traitement des données"
        case .noSuggestions:
            return "Aucune suggestion disponible"
        }
    }
} 