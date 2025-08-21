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
    @State private var isGettingAddress = false
    @State private var wantsToUseCurrentLocation = false
    @State private var showingLocationAlert = false
    @State private var locationAlertMessage = ""
    
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
            .onReceive(viewModel.locationManager.$location) { location in
                guard FeatureFlags.enableUseCurrentLocation else { return }
                if let location = location, isGettingAddress {
                    viewModel.locationManager.reverseGeocode(location) { result in
                        DispatchQueue.main.async {
                            self.isGettingAddress = false
                            self.wantsToUseCurrentLocation = false
                            self.viewModel.locationManager.stopUpdatingLocation()
                            switch result {
                            case .success(let address):
                                self.viewModel.filter.address = address
                            case .failure(_):
                                let coordString = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
                                self.viewModel.filter.address = coordString
                            }
                        }
                    }
                }
            }
            .onChange(of: viewModel.locationManager.authorizationStatus) { newStatus in
                guard FeatureFlags.enableUseCurrentLocation else { return }
                if wantsToUseCurrentLocation, (newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways) {
                    isGettingAddress = true
                    viewModel.locationManager.startUpdatingLocation()
                }
                if wantsToUseCurrentLocation, (newStatus == .denied || newStatus == .restricted) {
                    wantsToUseCurrentLocation = false
                    isGettingAddress = false
                    showLocationError("Veuillez autoriser l'accès à la localisation dans les Réglages de votre iPhone.")
                }
            }
            .alert("Autorisation de localisation", isPresented: $showingLocationAlert) {
                Button("Annuler") { }
                Button("Ouvrir Réglages") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Réessayer") { getAddressFromCurrentLocation() }
            } message: {
                Text(locationAlertMessage)
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
        VStack(spacing: 10) {
            // Adresse
            addressSection
            
            // Catégories
            categoriesSection
            
            // Rayon + Temps déplacés sous Catégories
            radiusTimeRow
            
            // Mode de transport
            transportSection
        }
        .padding(ItinerarlyTheme.Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(ItinerarlyTheme.CornerRadius.sm)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    // MARK: - Rayon + Temps (2 colonnes)
    private var radiusTimeRow: some View {
        HStack(alignment: .top, spacing: ItinerarlyTheme.Spacing.sm) {
            radiusSection
                .frame(maxWidth: .infinity, alignment: .topLeading)
            timeSection
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
    
    // MARK: - Adresse Section
    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(languageManager.translate("Point de départ"), systemImage: "mappin.and.ellipse")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
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
                
                if FeatureFlags.enableUseCurrentLocation {
                    HStack(spacing: 12) {
                        Button(action: { getAddressFromCurrentLocation() }) {
                            HStack(spacing: 6) {
                                if isGettingAddress {
                                    ProgressView().scaleEffect(0.8)
                                } else {
                                    Image(systemName: "location.fill")
                                }
                                Text(isGettingAddress ? "Localisation..." : "Utiliser ma position")
                            }
                            .font(.caption)
                            .foregroundColor(isGettingAddress ? .gray : ItinerarlyTheme.ModeColors.suggestions)
                        }
                        .disabled(false)

                        Spacer(minLength: 12)

                        Button(action: { showingLocationPicker = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.and.ellipse")
                                Text("Choisir sur la carte")
                            }
                            .font(.caption)
                            .foregroundColor(ItinerarlyTheme.ModeColors.suggestions)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingLocationPicker) {
                MapPickerView(
                    cityName: viewModel.filter.address.isEmpty ? "" : viewModel.filter.address,
                    initialCoordinate: viewModel.locationManager.location?.coordinate,
                    onPicked: { loc, address in
                        viewModel.filter.address = address
                    }
                )
            }
            if FeatureFlags.enableUseCurrentLocation && isGettingAddress {
                HStack(spacing: 6) {
                    Image(systemName: (viewModel.locationManager.authorizationStatus == .authorizedWhenInUse || viewModel.locationManager.authorizationStatus == .authorizedAlways) ? "location.fill" : "location.slash")
                        .foregroundColor((viewModel.locationManager.authorizationStatus == .authorizedWhenInUse || viewModel.locationManager.authorizationStatus == .authorizedAlways) ? .green : .red)
                    Text(locationStatusText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Catégories Section
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.sm) {
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
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(height: 20, alignment: .leading)
            
            // Chips rapides supprimés pour un design plus compact
            
            // Slider simplifié sans boutons +/-
            VStack(spacing: ItinerarlyTheme.Spacing.sm) {
                HStack {
                    Text("1 km")
                        .font(ItinerarlyTheme.Typography.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.filter.maxRadius)) km")
                        .font(ItinerarlyTheme.Typography.caption1)
                        .fontWeight(.semibold)
                        .foregroundColor(ItinerarlyTheme.ModeColors.suggestions)
                    
                    Spacer()
                    
                    Text("30 km")
                        .font(ItinerarlyTheme.Typography.caption2)
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
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = max(0, min(trackWidth, value.location.x))
                                let newValue = 1 + (x / trackWidth) * 29
                                let steppedValue = round(newValue)
                                let clampedValue = max(1, min(30, steppedValue))
                                viewModel.updateMaxRadius(clampedValue)
                            }
                    )
                }
                .frame(height: 28)
            }
        }
    }
    
    // MARK: - Temps Section
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
            Label(languageManager.translate("Temps disponible"), systemImage: "clock")
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(height: 20, alignment: .leading)
            
            // Chips rapides supprimés pour un design plus compact
            
            // Slider simplifié sans boutons +/-
            VStack(spacing: ItinerarlyTheme.Spacing.sm) {
                HStack {
                    Text("30min")
                        .font(ItinerarlyTheme.Typography.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTime(viewModel.filter.availableTime))
                        .font(ItinerarlyTheme.Typography.caption1)
                        .fontWeight(.semibold)
                        .foregroundColor(ItinerarlyTheme.ModeColors.suggestions)
                    
                    Spacer()
                    
                    Text("12h")
                        .font(ItinerarlyTheme.Typography.caption2)
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
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = max(0, min(trackWidth, value.location.x))
                                let newValue = 1800 + (x / trackWidth) * 41400
                                let steppedValue = round(newValue / 1800) * 1800
                                let clampedValue = max(1800, min(43200, steppedValue))
                                viewModel.updateAvailableTime(clampedValue)
                            }
                    )
                }
                .frame(height: 28)
            }
        }
    }
    
    // MARK: - Transport Section
    private var transportSection: some View {
        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
            Label(languageManager.translate("Mode de transport"), systemImage: "car")
                .font(.headline)
                .foregroundColor(.primary)
            
            TransportModeRow(
                selectedMode: Binding(
                    get: { viewModel.filter.transportMode },
                    set: { viewModel.updateTransportMode($0) }
                ),
                modes: [.walking, .cycling, .driving]
            )
        }
    }
    
    // MARK: - Bouton de recherche
    private var searchButton: some View {
        Button(action: {
            print("🎯 Bouton cliqué ! Catégories sélectionnées: \(viewModel.selectedCategories)")
            print("🎯 Filtre adresse: '\(viewModel.filter.address)'")
            Task {
                await viewModel.findSuggestions()
            }
        }) {
            HStack(spacing: ItinerarlyTheme.Spacing.sm) {
                if viewModel.isLoading {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(viewModel.isLoading ? "Recherche..." : "Suggest me something cool!")
                    .font(ItinerarlyTheme.Typography.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(ItinerarlyTheme.Spacing.sm)
            .frame(height: 36)
            .background(ItinerarlyTheme.ModeColors.suggestions.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(ItinerarlyTheme.CornerRadius.sm)
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
    
    // MARK: - Localisation Helpers
    private func getAddressFromCurrentLocation() {
        guard FeatureFlags.enableUseCurrentLocation else { return }
        wantsToUseCurrentLocation = true
        isGettingAddress = true
        
        viewModel.locationManager.requestWhenInUseAuthorization()
        viewModel.locationManager.startUpdatingLocation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if self.isGettingAddress {
                self.isGettingAddress = false
                self.wantsToUseCurrentLocation = false
                self.viewModel.locationManager.stopUpdatingLocation()
                if let last = self.viewModel.locationManager.location {
                    self.viewModel.locationManager.reverseGeocode(last) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let address):
                                self.viewModel.filter.address = address
                            case .failure(_):
                                let coordString = String(format: "%.6f, %.6f", last.coordinate.latitude, last.coordinate.longitude)
                                self.viewModel.filter.address = coordString
                            }
                        }
                    }
                } else {
                    self.showLocationError("Impossible d'obtenir votre position. Vérifiez que la localisation est activée et que vous êtes à l'extérieur.")
                }
            }
        }
    }
    
    private func showLocationError(_ message: String) {
        locationAlertMessage = message
        showingLocationAlert = true
    }
    
    private var locationStatusText: String {
        switch viewModel.locationManager.authorizationStatus {
        case .notDetermined:
            return "Appuyez pour autoriser la localisation"
        case .denied, .restricted:
            return "Ouvrir Réglages → Confidentialité → Localisation"
        case .authorizedWhenInUse, .authorizedAlways:
            if let location = viewModel.locationManager.location {
                let accuracy = location.horizontalAccuracy
                if accuracy < 5 { return "🟢 GPS haute précision (\(Int(accuracy))m)" }
                if accuracy < 20 { return "🟡 GPS précis (\(Int(accuracy))m)" }
                return "🟠 GPS approximatif (\(Int(accuracy))m)"
            }
            return "🔍 Recherche du signal GPS..."
        @unknown default:
            return "❓ Statut GPS inconnu"
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

                Button("TikTok") {
                    openInTikTok()
                }
                .font(.caption)
                .foregroundColor(.pink)
                
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

    private func openInTikTok() {
        let query = suggestion.location.name
        guard !query.isEmpty else { return }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        // Essayer d'ouvrir l'app TikTok
        if let appURL = URL(string: "tiktok://search?q=\(encoded)"), UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
            return
        }
        // Fallback web
        if let webURL = URL(string: "https://www.tiktok.com/search?q=\(encoded)") {
            UIApplication.shared.open(webURL)
        }
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