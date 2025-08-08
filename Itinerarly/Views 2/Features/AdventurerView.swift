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

struct AdventurerView: View {
    @StateObject private var viewModel = AdventurerViewModel()
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showingLocationPicker = false
    @State private var selectedTimeIndex = 1 // 1h par défaut
    @State private var selectedExcludedCategory: LocationCategory?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Filtres
                    filtersSection
                    
                    // MARK: - Bouton de génération
                    generateButton
                    
                    // MARK: - Résultats
                    resultsSection
                }
                .padding(ItinerarlyTheme.Spacing.md)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .itinerarlyBackground(mode: .adventure)
            .sheet(isPresented: $viewModel.shouldShowResults) {
                if let result = viewModel.result {
                    AdventureResultsView(
                        adventure: result,
                        userLocation: viewModel.userLocation
                    )
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: ItinerarlyTheme.Spacing.md) {
            // Titre en haut à gauche
            HStack {
                TranslatedText("Aventure")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // Icône centrée
            Image(systemName: "dice.fill")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.purple)
                .padding(.top, ItinerarlyTheme.Spacing.sm)
            
            // Description centrée
            TranslatedText("Découvrez des lieux insolites et surprenants")
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
            
            // Rayon
            radiusSection
            
            // Temps disponible
            timeSection
            
            // Catégorie à exclure
            excludedCategorySection
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
                        .foregroundColor(.purple)
                }
            }
        }
    }
    
    // MARK: - Rayon Section
    private var radiusSection: some View {
        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
            Label("Rayon de recherche", systemImage: "location.circle")
                .font(.headline)
            
            // Boutons de sélection rapide pour la distance
            HStack(spacing: ItinerarlyTheme.Spacing.sm) {
                ForEach([2, 5, 10, 15, 20], id: \.self) { distance in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.updateRadius(Double(distance))
                        }
                    }) {
                        Text("\(distance)km")
                            .font(ItinerarlyTheme.Typography.caption1)
                            .fontWeight(.medium)
                            .foregroundColor(viewModel.filter.radius == Double(distance) ? .white : .purple)
                            .padding(.horizontal, ItinerarlyTheme.Spacing.md)
                            .padding(.vertical, ItinerarlyTheme.Spacing.sm)
                            .background(viewModel.filter.radius == Double(distance) ? Color.purple : Color.purple.opacity(0.1))
                            .cornerRadius(ItinerarlyTheme.CornerRadius.sm)
                    }
                }
            }
            
            VStack(spacing: ItinerarlyTheme.Spacing.sm) {
                HStack {
                    Text("1 km")
                        .font(ItinerarlyTheme.Typography.caption1)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.filter.radius)) km")
                        .font(ItinerarlyTheme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    
                    Spacer()
                    
                    Text("30 km")
                        .font(ItinerarlyTheme.Typography.caption1)
                        .foregroundColor(.secondary)
                }
                
                // Slider personnalisé sans contrôles +/-
                GeometryReader { geometry in
                    let trackWidth = geometry.size.width
                    let normalizedValue = (viewModel.filter.radius - 1) / 29 // 1 à 30
                    let thumbPosition = normalizedValue * trackWidth
                    
                    ZStack(alignment: .leading) {
                        // Track background
                        RoundedRectangle(cornerRadius: ItinerarlyTheme.CornerRadius.sm)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: ItinerarlyTheme.CornerRadius.sm)
                            .fill(.purple)
                            .frame(width: max(6, thumbPosition), height: 6)
                        
                        // Thumb
                        Circle()
                            .fill(.purple)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .shadow(color: .purple.opacity(0.3), radius: 4)
                            )
                            .offset(x: thumbPosition - 10, y: 0)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let newValue = 1 + (location.x / trackWidth) * 29
                        let steppedValue = round(newValue)
                        let clampedValue = max(1, min(30, steppedValue))
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.updateRadius(clampedValue)
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
            
            // Boutons de sélection rapide pour le temps
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
                            .foregroundColor(viewModel.filter.availableTime == TimeInterval(minutes * 60) ? .white : .purple)
                            .padding(.horizontal, ItinerarlyTheme.Spacing.md)
                            .padding(.vertical, ItinerarlyTheme.Spacing.sm)
                            .background(viewModel.filter.availableTime == TimeInterval(minutes * 60) ? Color.purple : Color.purple.opacity(0.1))
                            .cornerRadius(ItinerarlyTheme.CornerRadius.sm)
                    }
                }
            }
            
            VStack(spacing: ItinerarlyTheme.Spacing.sm) {
                HStack {
                    Text("30min")
                        .font(ItinerarlyTheme.Typography.caption1)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTime(viewModel.filter.availableTime))
                        .font(ItinerarlyTheme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    
                    Spacer()
                    
                    Text("12h")
                        .font(ItinerarlyTheme.Typography.caption1)
                        .foregroundColor(.secondary)
                }
                
                // Slider personnalisé pour le temps sans contrôles +/-
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
                            .fill(.purple)
                            .frame(width: max(6, thumbPosition), height: 6)
                        
                        // Thumb
                        Circle()
                            .fill(.purple)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .shadow(color: .purple.opacity(0.3), radius: 4)
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
    
    // MARK: - Catégorie exclue Section
    private var excludedCategorySection: some View {
        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
            Label("Catégorie à exclure", systemImage: "xmark.circle")
                .font(.headline)
            
            Text("Choisissez ce que vous ne voulez PAS faire")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ItinerarlyTheme.Spacing.sm) {
                ForEach(viewModel.availableCategories, id: \.self) { category in
                    ExcludedCategoryButton(
                        category: category,
                        isSelected: selectedExcludedCategory == category,
                        action: {
                            if selectedExcludedCategory == category {
                                selectedExcludedCategory = nil
                                viewModel.updateExcludedCategory(nil)
                            } else {
                                selectedExcludedCategory = category
                                viewModel.updateExcludedCategory(category)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Bouton de génération
    private var generateButton: some View {
        Button(action: {
            Task {
                await viewModel.generateSurpriseAdventure()
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "dice.fill")
                }
                
                Text(viewModel.isLoading ? "Génération..." : "Surprise me!")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(ItinerarlyTheme.CornerRadius.md)
        }
        .disabled(viewModel.isLoading)
    }
    
    // MARK: - Résultats Section
    private var resultsSection: some View {
        VStack(spacing: 16) {
            if let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage) {
                    viewModel.clearResult()
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
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes > 0 ? " \(minutes)min" : "")"
        } else {
            return "\(minutes)min"
        }
    }
}

// MARK: - Excluded Category Button
struct ExcludedCategoryButton: View {
    let category: LocationCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ItinerarlyTheme.Spacing.sm) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .purple)
                
                Text(category.displayName)
                    .font(ItinerarlyTheme.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, ItinerarlyTheme.Spacing.md)
            .padding(.vertical, ItinerarlyTheme.Spacing.md)
            .background(isSelected ? Color.red : Color(.systemGray6))
            .cornerRadius(ItinerarlyTheme.CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
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



#Preview {
    AdventurerView()
} 