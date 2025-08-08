import SwiftUI

struct FavoriteButton: View {
    let location: Location
    @ObservedObject var favoritesService: FavoritesService
    let size: CGFloat
    
    init(location: Location, favoritesService: FavoritesService, size: CGFloat = 24) {
        self.location = location
        self.favoritesService = favoritesService
        self.size = size
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                favoritesService.toggleFavorite(location)
            }
        }) {
            Image(systemName: favoritesService.isFavorite(location) ? "heart.fill" : "heart")
                .font(.system(size: size * 0.8))
                .foregroundColor(favoritesService.isFavorite(location) ? .red : .gray)
                .scaleEffect(favoritesService.isFavorite(location) ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: favoritesService.isFavorite(location))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FavoriteButton(
        location: Location(
            id: "1",
            name: "Test Location",
            address: "Test Address",
            latitude: 50.8503,
            longitude: 4.3517,
            category: .restaurant,
            description: "Test description",
            imageURL: nil,
            rating: 4.5,
            openingHours: "Ouvert",
            recommendedDuration: nil,
            visitTips: nil
        ),
        favoritesService: FavoritesService()
    )
} 