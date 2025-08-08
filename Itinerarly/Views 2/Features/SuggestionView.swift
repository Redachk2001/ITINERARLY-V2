import SwiftUI
import CoreLocation
import MapKit

// MARK: - Helper Functions
private func formatAddressFromMapItem(_ mapItem: MKMapItem) -> String {
    let placemark = mapItem.placemark
    
    var addressComponents: [String] = []
    
    if let name = mapItem.name, !name.isEmpty {
        addressComponents.append(name)
    }
    
    if let streetNumber = placemark.subThoroughfare {
        addressComponents.append(streetNumber)
    }
    
    if let street = placemark.thoroughfare {
        addressComponents.append(street)
    }
    
    if let city = placemark.locality {
        addressComponents.append(city)
    }
    
    if let postalCode = placemark.postalCode {
        addressComponents.append(postalCode)
    }
    
    if let country = placemark.country {
        addressComponents.append(country)
    }
    
    return addressComponents.joined(separator: ", ")
}

struct SuggestionView: View {
    @StateObject private var viewModel = SuggestionViewModel()
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showingLocationPicker = false
    @State private var selectedTimeIndex = 1 // 1h par défaut
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Filtres
                    filtersSection
                    
                    // MARK: - Bouton de recherche
                    searchButton
                    
                    // MARK: - Résultats
                    resultsSection
                }
                .padding(ItinerarlyTheme.Spacing.md)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .itinerarlyBackground(mode: .suggestions)
            .sheet(isPresented: $viewModel.shouldShowItinerary) {
                if let trip = viewModel.generatedTrip {
                    SuggestionResultsView(trip: trip)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: ItinerarlyTheme.Spacing.md) {
            // Titre en haut à gauche
            HStack {
                TranslatedText("Suggestions")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // Icône centrée
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(ItinerarlyTheme.ModeColors.suggestions)
                .padding(.top, ItinerarlyTheme.Spacing.sm)
            
            // Description centrée
            TranslatedText("Trouvez une activité sympa près de chez vous")
                .font(ItinerarlyTheme.Typography.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, ItinerarlyTheme.Spacing.sm)
        }
        .padding(.vertical)
    }
    
    // MARK: - Filtres Section
    private var filtersSection: some View {
        VStack(spacing: 20) {
            // Adresse
            addressSection
            
            // Catégories
            categoriesSection
            
            // Rayon
            radiusSection
            
            // Temps disponible
            timeSection
            
            // Mode de transport
            transportSection
        }
        .padding(ItinerarlyTheme.Spacing.lg)
        .background(Color(.systemBackground))
        .cornerRadius(ItinerarlyTheme.CornerRadius.md)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Adresse Section
    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(languageManager.translate("Point de départ"), systemImage: "mappin.and.ellipse")
                .font(.headline)
            
            HStack {
                LocationSearchField(
                    text: $viewModel.filter.address,
                    placeholder: "Votre adresse ou géolocalisation",
                    userLocation: viewModel.locationManager.location,
                    onSuggestionSelected: { mapItem in
                        // Mettre l'adresse formatée dans le champ
                        let formattedAddress = formatAddressFromMapItem(mapItem)
                        viewModel.filter.address = formattedAddress
                    }
                )
                
                Button(action: {
                    showingLocationPicker = true
                }) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - Catégories Section
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
            Label(languageManager.translate("Catégories d'activités"), systemImage: "grid.circle")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ItinerarlyTheme.Spacing.sm) {
                ForEach(viewModel.availableCategories, id: \.self) { category in
                    MinimalCategoryButton(
                        category: category,
                        isSelected: viewModel.selectedCategories.contains(category),
                        action: {
                            viewModel.toggleCategory(category)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Rayon Section
    private var radiusSection: some View {
        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
            Label(languageManager.translate("Rayon de recherche"), systemImage: "location.circle")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Boutons de sélection rapide - Design uniforme
            HStack(spacing: ItinerarlyTheme.Spacing.sm) {
                ForEach([2, 5, 10, 15, 20], id: \.self) { distance in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.updateMaxRadius(Double(distance))
                        }
                    }) {
                        Text("\(distance)km")
                            .font(ItinerarlyTheme.Typography.caption1)
                            .fontWeight(.medium)
                            .foregroundColor(viewModel.filter.maxRadius == Double(distance) ? .white : ItinerarlyTheme.ModeColors.suggestions)
                            .padding(.horizontal, ItinerarlyTheme.Spacing.md)
                            .padding(.vertical, ItinerarlyTheme.Spacing.sm)
                            .background(viewModel.filter.maxRadius == Double(distance) ? ItinerarlyTheme.ModeColors.suggestions : Color(.systemGray6))
                            .cornerRadius(ItinerarlyTheme.CornerRadius.sm)
                    }
                }
            }
            
            // Slider simplifié sans boutons +/-
            VStack(spacing: ItinerarlyTheme.Spacing.sm) {
                HStack {
                    Text("1 km")
                        .font(ItinerarlyTheme.Typography.caption1)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.filter.maxRadius)) km")
                        .font(ItinerarlyTheme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(ItinerarlyTheme.ModeColors.suggestions)
                    
                    Spacer()
                    
                    Text("30 km")
                        .font(ItinerarlyTheme.Typography.caption1)
                        .foregroundColor(.secondary)
                }
                
                // Slider personnalisé sans contrôles +/-
                GeometryReader { geometry in
                    let trackWidth = geometry.size.width
                    let normalizedValue = (viewModel.filter.maxRadius - 1) / 29 // 1 à 30
                    let thumbPosition = normalizedValue * trackWidth
                    
                    ZStack(alignment: .leading) {
                        // Track background
                        RoundedRectangle(cornerRadius: ItinerarlyTheme.CornerRadius.sm)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: ItinerarlyTheme.CornerRadius.sm)
                            .fill(ItinerarlyTheme.ModeColors.suggestions)
                            .frame(width: max(6, thumbPosition), height: 6)
                        
                        // Thumb
                        Circle()
                            .fill(ItinerarlyTheme.ModeColors.suggestions)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .shadow(color: ItinerarlyTheme.ModeColors.suggestions.opacity(0.3), radius: 4)
                            )
                            .offset(x: thumbPosition - 10, y: 0)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let newValue = 1 + (location.x / trackWidth) * 29
                        let steppedValue = round(newValue)
                        let clampedValue = max(1, min(30, steppedValue))
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.updateMaxRadius(clampedValue)
                        }
                    }
                }
                .frame(height: 40)
            }
        }
    }
    
    // MARK: - Temps Section
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
            Label(languageManager.translate("Temps disponible"), systemImage: "clock")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Boutons de sélection rapide - Design uniforme
            HStack(spacing: ItinerarlyTheme.Spacing.sm) {
                ForEach([30, 60, 90, 120, 180], id: \.self) { minutes in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.updateAvailableTime(TimeInterval(minutes * 60))
                        }
                    }) {
                        Text("\(minutes)min")
                            .font(ItinerarlyTheme.Typography.caption1)
                            .fontWeight(.medium)
                            .foregroundColor(viewModel.filter.availableTime == TimeInterval(minutes * 60) ? .white : ItinerarlyTheme.ModeColors.suggestions)
                            .padding(.horizontal, ItinerarlyTheme.Spacing.md)
                            .padding(.vertical, ItinerarlyTheme.Spacing.sm)
                            .background(viewModel.filter.availableTime == TimeInterval(minutes * 60) ? ItinerarlyTheme.ModeColors.suggestions : Color(.systemGray6))
                            .cornerRadius(ItinerarlyTheme.CornerRadius.sm)
                    }
                }
            }
            
            // Slider simplifié sans boutons +/-
            VStack(spacing: ItinerarlyTheme.Spacing.sm) {
                HStack {
                    Text("30min")
                        .font(ItinerarlyTheme.Typography.caption1)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTime(viewModel.filter.availableTime))
                        .font(ItinerarlyTheme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(ItinerarlyTheme.ModeColors.suggestions)
                    
                    Spacer()
                    
                    Text("12h")
                        .font(ItinerarlyTheme.Typography.caption1)
                        .foregroundColor(.secondary)
                }
                
                // Slider personnalisé sans contrôles +/-
                GeometryReader { geometry in
                    let trackWidth = geometry.size.width
                    let normalizedValue = (viewModel.filter.availableTime - 1800) / 41400 // 30min à 12h
                    let thumbPosition = normalizedValue * trackWidth
                    
                    ZStack(alignment: .leading) {
                        // Track background
                        RoundedRectangle(cornerRadius: ItinerarlyTheme.CornerRadius.sm)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: ItinerarlyTheme.CornerRadius.sm)
                            .fill(ItinerarlyTheme.ModeColors.suggestions)
                            .frame(width: max(6, thumbPosition), height: 6)
                        
                        // Thumb
                        Circle()
                            .fill(ItinerarlyTheme.ModeColors.suggestions)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .shadow(color: ItinerarlyTheme.ModeColors.suggestions.opacity(0.3), radius: 4)
                            )
                            .offset(x: thumbPosition - 10, y: 0)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let newValue = 1800 + (location.x / trackWidth) * 41400
                        let steppedValue = round(newValue / 1800) * 1800 // Pas de 30min
                        let clampedValue = max(1800, min(43200, steppedValue))
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.updateAvailableTime(clampedValue)
                        }
                    }
                }
                .frame(height: 40)
            }
        }
    }
    
    // MARK: - Transport Section
    private var transportSection: some View {
        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
            Label(languageManager.translate("Mode de transport"), systemImage: "car")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: ItinerarlyTheme.Spacing.sm) {
                Spacer()
                
                TransportModeButton(
                    mode: .walking,
                    isSelected: viewModel.filter.transportMode == .walking,
                    action: { viewModel.updateTransportMode(.walking) }
                )
                
                TransportModeButton(
                    mode: .cycling,
                    isSelected: viewModel.filter.transportMode == .cycling,
                    action: { viewModel.updateTransportMode(.cycling) }
                )
                
                TransportModeButton(
                    mode: .driving,
                    isSelected: viewModel.filter.transportMode == .driving,
                    action: { viewModel.updateTransportMode(.driving) }
                )
                
                Spacer()
            }
        }
    }
    
    // MARK: - Bouton de recherche
    private var searchButton: some View {
        Button(action: {
            Task {
                await viewModel.findSuggestions()
            }
        }) {
            HStack(spacing: ItinerarlyTheme.Spacing.md) {
                if viewModel.isLoading {
                    ItinerarlyLoadingView(mode: .suggestions, message: "Recherche...")
                        .scaleEffect(0.6)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(viewModel.isLoading ? "Recherche..." : "Suggest me something cool!")
                    .font(ItinerarlyTheme.Typography.buttonText)
            }
            .frame(maxWidth: .infinity)
            .padding(ItinerarlyTheme.Spacing.lg)
            .background(ItinerarlyTheme.ModeColors.suggestions)
            .foregroundColor(.white)
            .cornerRadius(ItinerarlyTheme.CornerRadius.md)
        }
        .disabled(viewModel.isLoading || viewModel.selectedCategories.isEmpty)
        .opacity(viewModel.selectedCategories.isEmpty ? 0.6 : 1.0)
    }
    
    // MARK: - Résultats Section
    private var resultsSection: some View {
        VStack(spacing: 16) {
            if !viewModel.suggestions.isEmpty {
                Text("🎉 Suggestions trouvées")
                    .font(.headline)
                    .padding(.top)
                
                ForEach(Array(viewModel.suggestions.enumerated()), id: \.element.location.id) { index, suggestion in
                    SuggestionCard(suggestion: suggestion, index: index + 1)
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                VStack(spacing: ItinerarlyTheme.Spacing.md) {
                    ErrorView(message: errorMessage) {
                        viewModel.clearSuggestions()
                    }
                    
                    // Message d'aide spécifique pour les erreurs d'adresse
                    if errorMessage.contains("localiser") || errorMessage.contains("adresse") {
                        VStack(spacing: ItinerarlyTheme.Spacing.sm) {
                            Text("💡 Conseils :")
                                .font(ItinerarlyTheme.Typography.caption1)
                                .fontWeight(.semibold)
                                .foregroundColor(ItinerarlyTheme.ModeColors.suggestions)
                            
                            Text("• Essayez une adresse plus simple (ex: \"Paris\", \"Lyon\")\n• Vérifiez l'orthographe\n• Ou laissez vide pour utiliser votre position")
                                .font(ItinerarlyTheme.Typography.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(ItinerarlyTheme.Spacing.md)
                        .background(ItinerarlyTheme.ModeColors.suggestions.opacity(0.05))
                        .cornerRadius(ItinerarlyTheme.CornerRadius.sm)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes > 0 ? " \(minutes)min" : "")"
        } else {
            return "\(minutes)min"
        }
    }
}

// MARK: - Minimal Category Button (Design épuré)
struct MinimalCategoryButton: View {
    let category: LocationCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ItinerarlyTheme.Spacing.sm) {
                // Icône simple
                Image(systemName: category.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : ItinerarlyTheme.ModeColors.suggestions)
                
                // Nom de la catégorie
                Text(category.displayName)
                    .font(ItinerarlyTheme.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                Spacer()
                
                // Indicateur de sélection minimal
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, ItinerarlyTheme.Spacing.md)
            .padding(.vertical, ItinerarlyTheme.Spacing.md)
            .background(
                isSelected 
                ? ItinerarlyTheme.ModeColors.suggestions
                : Color(.systemGray6)
            )
            .cornerRadius(ItinerarlyTheme.CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Legacy Category Button (pour compatibilité)
struct CategoryButton: View {
    let category: LocationCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: categoryIcon)
                    .font(.caption)
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(ItinerarlyTheme.CornerRadius.sm)
        }
    }
    
    private var categoryIcon: String {
        switch category {
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .museum: return "building.columns.fill"
        case .culture: return "theatermasks.fill"
        case .sport: return "figure.run"
        case .shopping: return "bag.fill"
        case .nature: return "leaf.fill"
        case .bar: return "wineglass.fill"
        case .entertainment: return "gamecontroller.fill"
        case .aquarium: return "fish.fill"
        case .zoo: return "pawprint.fill"
        case .historical: return "building.columns"
        case .religious: return "building.columns"
        case .adventurePark: return "figure.climbing"
        case .iceRink: return "snowflake"
        case .swimmingPool: return "drop.fill"
        case .climbingGym: return "figure.climbing"
        case .escapeRoom: return "lock.fill"
        case .laserTag: return "target"
        case .bowling: return "circle.fill"
        case .miniGolf: return "flag.fill"
        case .paintball: return "target"
        case .karting: return "car.fill"
        case .trampolinePark: return "figure.jumprope"
        case .waterPark: return "drop.fill"
        }
    }
}

// MARK: - Suggestion Card
struct SuggestionCard: View {
    let suggestion: SuggestionResult
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(index)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .frame(width: 30, height: 30)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.location.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(suggestion.location.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1f km", suggestion.distance))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDuration(suggestion.estimatedDuration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let description = suggestion.location.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            HStack {
                Button("Voir sur la carte") {
                    openInMaps()
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Spacer()
                
                if let rating = suggestion.location.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                    }
                }
            }
        }
        .padding(ItinerarlyTheme.Spacing.lg)
        .background(Color(.systemBackground))
        .cornerRadius(ItinerarlyTheme.CornerRadius.md)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes > 0 ? " \(minutes)min" : "")"
        } else {
            return "\(minutes)min"
        }
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: suggestion.location.latitude,
            longitude: suggestion.location.longitude
        )
        
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = suggestion.location.name
        mapItem.openInMaps(launchOptions: [:])
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: ItinerarlyTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundColor(ItinerarlyTheme.warning)
            
            Text(message)
                .font(ItinerarlyTheme.Typography.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            ItinerarlyButton("Réessayer", style: .secondary(.suggestions), icon: "arrow.clockwise", action: retryAction)
        }
        .padding(ItinerarlyTheme.Spacing.lg)
        .itinerarlyCard(mode: .suggestions)
    }
}





#Preview {
    SuggestionView()
} 