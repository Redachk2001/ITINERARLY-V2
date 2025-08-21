import Foundation
import CoreData
import SwiftUI

// MARK: - Service de base de données locale
@MainActor
class LocalDatabaseService: ObservableObject {
    static let shared = LocalDatabaseService()
    
    // MARK: - Core Data Stack
    private let container: NSPersistentContainer
    
    @Published var savedFavorites: [FavoriteLocation] = []
    @Published var savedItineraries: [SavedItinerary] = []
    @Published var userPreferences: UserPreferences = UserPreferences()
    
    // MARK: - Initialisation
    init() {
        container = NSPersistentContainer(name: "ItinerarlyDataModel")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ Erreur chargement Core Data: \(error.localizedDescription)")
            } else {
                print("✅ Core Data chargé avec succès")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Charger les données existantes
        loadFavorites()
        loadItineraries()
        loadUserPreferences()
    }
    
    // MARK: - Gestion des favoris
    func saveFavorite(_ location: Location) {
        let context = container.viewContext
        let favorite = FavoriteLocationEntity(context: context)
        
        favorite.id = location.id
        favorite.name = location.name
        favorite.address = location.address
        favorite.latitude = location.latitude
        favorite.longitude = location.longitude
        favorite.category = location.category.rawValue
        favorite.locationDescription = location.description
        favorite.imageURL = location.imageURL
        favorite.rating = location.rating ?? 0.0
        favorite.openingHours = location.openingHours
        favorite.recommendedDuration = Int32(location.recommendedDuration ?? 0)
        favorite.visitTips = location.visitTips?.joined(separator: ", ") ?? ""
        favorite.dateAdded = Date()
        
        saveContext()
        loadFavorites()
    }
    
    func removeFavorite(withId id: String) {
        let context = container.viewContext
        let request: NSFetchRequest<FavoriteLocationEntity> = FavoriteLocationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let favorites = try context.fetch(request)
            favorites.forEach { context.delete($0) }
            saveContext()
            loadFavorites()
        } catch {
            print("❌ Erreur suppression favori: \(error)")
        }
    }
    
    func isFavorite(_ location: Location) -> Bool {
        return savedFavorites.contains { $0.id == location.id }
    }
    
    private func loadFavorites() {
        let context = container.viewContext
        let request: NSFetchRequest<FavoriteLocationEntity> = FavoriteLocationEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FavoriteLocationEntity.dateAdded, ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            savedFavorites = entities.map { entity in
                FavoriteLocation(
                    id: entity.id ?? "",
                    name: entity.name ?? "",
                    address: entity.address ?? "",
                    latitude: entity.latitude,
                    longitude: entity.longitude,
                    category: LocationCategory(rawValue: entity.category ?? "") ?? .restaurant,
                    description: entity.locationDescription ?? "",
                    imageURL: entity.imageURL,
                    rating: entity.rating,
                    openingHours: entity.openingHours ?? "",
                    recommendedDuration: Int(entity.recommendedDuration),
                    visitTips: entity.visitTips ?? "",
                    dateAdded: entity.dateAdded ?? Date()
                )
            }
        } catch {
            print("❌ Erreur chargement favoris: \(error)")
        }
    }
    
    // MARK: - Gestion des itinéraires sauvegardés
    func saveItinerary(_ trip: DayTrip, name: String) {
        let context = container.viewContext
        let savedItinerary = SavedItineraryEntity(context: context)
        
        savedItinerary.id = UUID().uuidString
        savedItinerary.name = name
        savedItinerary.tripData = try? JSONEncoder().encode(trip)
        savedItinerary.dateCreated = Date()
        savedItinerary.isFavorite = false
        
        saveContext()
        loadItineraries()
    }
    
    func removeItinerary(withId id: String) {
        let context = container.viewContext
        let request: NSFetchRequest<SavedItineraryEntity> = SavedItineraryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let itineraries = try context.fetch(request)
            itineraries.forEach { context.delete($0) }
            saveContext()
            loadItineraries()
        } catch {
            print("❌ Erreur suppression itinéraire: \(error)")
        }
    }
    
    private func loadItineraries() {
        let context = container.viewContext
        let request: NSFetchRequest<SavedItineraryEntity> = SavedItineraryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedItineraryEntity.dateCreated, ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            savedItineraries = entities.compactMap { entity in
                guard let tripData = entity.tripData,
                      let trip = try? JSONDecoder().decode(DayTrip.self, from: tripData) else {
                    return nil
                }
                
                return SavedItinerary(
                    id: entity.id ?? "",
                    name: entity.name ?? "",
                    trip: trip,
                    dateCreated: entity.dateCreated ?? Date(),
                    isFavorite: entity.isFavorite
                )
            }
        } catch {
            print("❌ Erreur chargement itinéraires: \(error)")
        }
    }
    
    // MARK: - Gestion des préférences utilisateur
    func saveUserPreferences(_ preferences: UserPreferences) {
        let context = container.viewContext
        let request: NSFetchRequest<UserPreferencesEntity> = UserPreferencesEntity.fetchRequest()
        
        do {
            let existingPreferences = try context.fetch(request)
            let preferencesEntity: UserPreferencesEntity
            
            if let existing = existingPreferences.first {
                preferencesEntity = existing
            } else {
                preferencesEntity = UserPreferencesEntity(context: context)
            }
            
            preferencesEntity.language = preferences.language
            preferencesEntity.theme = preferences.theme
            preferencesEntity.transportMode = preferences.transportMode.rawValue
            preferencesEntity.searchRadius = preferences.searchRadius
            preferencesEntity.notificationsEnabled = preferences.notificationsEnabled
            preferencesEntity.audioEnabled = preferences.audioEnabled
            preferencesEntity.autoSaveItineraries = preferences.autoSaveItineraries
            
            saveContext()
            loadUserPreferences()
        } catch {
            print("❌ Erreur sauvegarde préférences: \(error)")
        }
    }
    
    private func loadUserPreferences() {
        let context = container.viewContext
        let request: NSFetchRequest<UserPreferencesEntity> = UserPreferencesEntity.fetchRequest()
        
        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                userPreferences = UserPreferences(
                    language: entity.language ?? "fr",
                    theme: entity.theme ?? "system",
                    transportMode: TransportMode(rawValue: entity.transportMode ?? "walking") ?? .walking,
                    searchRadius: entity.searchRadius,
                    notificationsEnabled: entity.notificationsEnabled,
                    audioEnabled: entity.audioEnabled,
                    autoSaveItineraries: entity.autoSaveItineraries
                )
            }
        } catch {
            print("❌ Erreur chargement préférences: \(error)")
        }
    }
    
    // MARK: - Cache des données
    func cacheSearchResults(_ results: [Location], for query: String) {
        let context = container.viewContext
        let cacheEntity = SearchCacheEntity(context: context)
        
        cacheEntity.query = query
        cacheEntity.results = try? JSONEncoder().encode(results)
        cacheEntity.timestamp = Date()
        
        // Supprimer les anciens caches (plus de 24h)
        cleanupOldCache()
        
        saveContext()
    }
    
    func getCachedResults(for query: String) -> [Location]? {
        let context = container.viewContext
        let request: NSFetchRequest<SearchCacheEntity> = SearchCacheEntity.fetchRequest()
        request.predicate = NSPredicate(format: "query == %@", query)
        
        do {
            let caches = try context.fetch(request)
            guard let cache = caches.first,
                  let results = cache.results,
                  let locations = try? JSONDecoder().decode([Location].self, from: results),
                  let timestamp = cache.timestamp,
                  Date().timeIntervalSince(timestamp) < 86400 // 24h
            else {
                return nil
            }
            
            return locations
        } catch {
            print("❌ Erreur récupération cache: \(error)")
            return nil
        }
    }
    
    private func cleanupOldCache() {
        let context = container.viewContext
        let request: NSFetchRequest<SearchCacheEntity> = SearchCacheEntity.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp < %@", Date().addingTimeInterval(-86400) as NSDate)
        
        do {
            let oldCaches = try context.fetch(request)
            oldCaches.forEach { context.delete($0) }
        } catch {
            print("❌ Erreur nettoyage cache: \(error)")
        }
    }
    
    // MARK: - Utilitaires
    private func saveContext() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Contexte sauvegardé")
            } catch {
                print("❌ Erreur sauvegarde contexte: \(error)")
            }
        }
    }
    
    func clearAllData() {
        let context = container.viewContext
        
        // Supprimer tous les favoris
        let favoritesRequest: NSFetchRequest<NSFetchRequestResult> = FavoriteLocationEntity.fetchRequest()
        let favoritesDeleteRequest = NSBatchDeleteRequest(fetchRequest: favoritesRequest)
        
        // Supprimer tous les itinéraires
        let itinerariesRequest: NSFetchRequest<NSFetchRequestResult> = SavedItineraryEntity.fetchRequest()
        let itinerariesDeleteRequest = NSBatchDeleteRequest(fetchRequest: itinerariesRequest)
        
        // Supprimer toutes les préférences
        let preferencesRequest: NSFetchRequest<NSFetchRequestResult> = UserPreferencesEntity.fetchRequest()
        let preferencesDeleteRequest = NSBatchDeleteRequest(fetchRequest: preferencesRequest)
        
        // Supprimer tout le cache
        let cacheRequest: NSFetchRequest<NSFetchRequestResult> = SearchCacheEntity.fetchRequest()
        let cacheDeleteRequest = NSBatchDeleteRequest(fetchRequest: cacheRequest)
        
        do {
            try context.execute(favoritesDeleteRequest)
            try context.execute(itinerariesDeleteRequest)
            try context.execute(preferencesDeleteRequest)
            try context.execute(cacheDeleteRequest)
            try context.save()
            
            // Recharger les données
            loadFavorites()
            loadItineraries()
            loadUserPreferences()
            
            print("✅ Toutes les données supprimées")
        } catch {
            print("❌ Erreur suppression données: \(error)")
        }
    }
}

// MARK: - Modèles de données
struct FavoriteLocation: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let category: LocationCategory
    let description: String
    let imageURL: String?
    let rating: Double
    let openingHours: String
    let recommendedDuration: Int
    let visitTips: String
    let dateAdded: Date
}

struct SavedItinerary: Identifiable, Codable {
    let id: String
    let name: String
    let trip: DayTrip
    let dateCreated: Date
    let isFavorite: Bool
}

struct UserPreferences: Codable {
    var language: String = "fr"
    var theme: String = "system"
    var transportMode: TransportMode = .walking
    var searchRadius: Double = 10000.0
    var notificationsEnabled: Bool = true
    var audioEnabled: Bool = true
    var autoSaveItineraries: Bool = true
}
