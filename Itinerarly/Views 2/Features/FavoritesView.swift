import SwiftUI

struct FavoritesView: View {
    @StateObject private var favoritesService = FavoritesService()
    @State private var selectedCategory: LocationCategory? = nil
    
    var filteredFavorites: [Location] {
        if let category = selectedCategory {
            return favoritesService.getFavoritesByCategory(category)
        }
        return favoritesService.favoriteLocations
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if favoritesService.favoriteLocations.isEmpty {
                    // Vue vide
                    VStack(spacing: 20) {
                        Image(systemName: "heart")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Aucun favori")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Ajoutez des lieux à vos favoris pour les retrouver facilement")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Liste des favoris
                    VStack {
                        // Filtres par catégorie
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                CategoryFilterButton(
                                    title: "Tous",
                                    isSelected: selectedCategory == nil,
                                    action: { selectedCategory = nil }
                                )
                                
                                ForEach(LocationCategory.allCases, id: \.self) { category in
                                    if favoritesService.getFavoritesByCategory(category).count > 0 {
                                        CategoryFilterButton(
                                            title: category.displayName,
                                            isSelected: selectedCategory == category,
                                            action: { selectedCategory = category }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        
                        // Liste des favoris
                        List {
                            ForEach(filteredFavorites, id: \.id) { location in
                                FavoriteLocationRow(
                                    location: location,
                                    favoritesService: favoritesService
                                )
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Mes Favoris")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !favoritesService.favoriteLocations.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Effacer tout") {
                            // Action pour effacer tous les favoris
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FavoriteLocationRow: View {
    let location: Location
    @ObservedObject var favoritesService: FavoritesService
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône de catégorie
            Image(systemName: location.category.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            // Informations du lieu
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(location.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    if let rating = location.rating {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(location.category.displayName)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // Bouton favori
            FavoriteButton(
                location: location,
                favoritesService: favoritesService,
                size: 20
            )
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FavoritesView()
} 