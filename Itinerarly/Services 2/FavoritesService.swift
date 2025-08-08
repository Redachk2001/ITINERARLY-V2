import Foundation
import SwiftUI

class FavoritesService: ObservableObject {
    @Published var favoriteLocations: [Location] = []
    
    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "favoriteLocations"
    
    init() {
        loadFavorites()
    }
    
    // MARK: - Public Methods
    
    func toggleFavorite(_ location: Location) {
        if isFavorite(location) {
            removeFavorite(location)
        } else {
            addFavorite(location)
        }
    }
    
    func isFavorite(_ location: Location) -> Bool {
        return favoriteLocations.contains { $0.id == location.id }
    }
    
    func addFavorite(_ location: Location) {
        guard !isFavorite(location) else { return }
        favoriteLocations.append(location)
        saveFavorites()
    }
    
    func removeFavorite(_ location: Location) {
        favoriteLocations.removeAll { $0.id == location.id }
        saveFavorites()
    }
    
    func getFavoritesByCategory(_ category: LocationCategory) -> [Location] {
        return favoriteLocations.filter { $0.category == category }
    }
    
    func clearAllFavorites() {
        favoriteLocations.removeAll()
        saveFavorites()
    }
    
    // MARK: - Private Methods
    
    private func saveFavorites() {
        do {
            let data = try JSONEncoder().encode(favoriteLocations)
            userDefaults.set(data, forKey: favoritesKey)
        } catch {
            print("Erreur lors de la sauvegarde des favoris: \(error)")
        }
    }
    
    private func loadFavorites() {
        guard let data = userDefaults.data(forKey: favoritesKey) else { return }
        
        do {
            favoriteLocations = try JSONDecoder().decode([Location].self, from: data)
        } catch {
            print("Erreur lors du chargement des favoris: \(error)")
            favoriteLocations = []
        }
    }
} 