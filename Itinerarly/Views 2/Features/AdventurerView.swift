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
        VStack(spacing: 16) {
            // Adresse
            addressSection
            
            // Catégorie à exclure
            excludedCategorySection
            
            // Rayon + Temps sous la catégorie et au-dessus du transport
            HStack(alignment: .top, spacing: ItinerarlyTheme.Spacing.sm) {
                radiusSection
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                timeSection
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            
            // Mode de transport
            transportSection
        }
        .padding(ItinerarlyTheme.Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(ItinerarlyTheme.CornerRadius.sm)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
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
                            .foregroundColor(isGettingAddress ? .gray : ItinerarlyTheme.ModeColors.adventure)
                        }
                        .disabled(false)

                        Spacer(minLength: 12)

                        Button(action: { showingLocationPicker = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.and.ellipse")
                                Text("Choisir sur la carte")
                            }
                            .font(.caption)
                            .foregroundColor(ItinerarlyTheme.ModeColors.adventure)
                        }
                    }
                }
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
        .sheet(isPresented: $showingLocationPicker) {
            MapPickerView(
                cityName: viewModel.filter.address.isEmpty ? "" : viewModel.filter.address,
                initialCoordinate: viewModel.locationManager.location?.coordinate,
                onPicked: { loc, address in
                    viewModel.filter.address = address
                }
            )
        }
    }
    
    // MARK: - Rayon Section
    private var radiusSection: some View {
        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.sm) {
            Label("Rayon de recherche", systemImage: "location.circle")
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(height: 20, alignment: .leading)
            
            // Chips supprimés
            
            VStack(spacing: ItinerarlyTheme.Spacing.sm) {
                HStack {
                    Text("1 km")
                        .font(ItinerarlyTheme.Typography.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.filter.radius)) km")
                        .font(ItinerarlyTheme.Typography.caption1)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    
                    Spacer()
                    
                    Text("30 km")
                        .font(ItinerarlyTheme.Typography.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Slider personnalisé sans contrôles +/−
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
                        let stepped = round(newValue)
                        let clamped = max(1, min(30, stepped))
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.updateRadius(clamped)
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = max(0, min(trackWidth, value.location.x))
                                let newValue = 1 + (x / trackWidth) * 29
                                let stepped = round(newValue)
                                let clamped = max(1, min(30, stepped))
                                viewModel.updateRadius(clamped)
                            }
                    )
                }
                .frame(height: 28)
            }
        }
    }
    
    // MARK: - Temps Section
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.sm) {
            Label(languageManager.translate("Temps disponible"), systemImage: "clock")
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(height: 20, alignment: .leading)
            
            // Chips supprimés
            
            VStack(spacing: ItinerarlyTheme.Spacing.sm) {
                HStack {
                    Text("30min")
                        .font(ItinerarlyTheme.Typography.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTime(viewModel.filter.availableTime))
                        .font(ItinerarlyTheme.Typography.caption1)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    
                    Spacer()
                    
                    Text("12h")
                        .font(ItinerarlyTheme.Typography.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Slider personnalisé pour le temps sans contrôles +/−
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
                        let steppedValue = round(newValue / 1800) * 1800
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
    
    // MARK: - Catégorie exclue Section
    private var excludedCategorySection: some View {
        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.sm) {
            Label("Catégorie à exclure", systemImage: "xmark.circle")
                .font(.headline)
            
            Text("Choisissez ce que vous ne voulez PAS faire")
                .font(ItinerarlyTheme.Typography.caption1)
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
    
    // MARK: - Mode de transport
    private var transportSection: some View {
        let modes: [TransportMode] = [.walking, .cycling, .driving]
        return VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.sm) {
            Label("Mode de transport", systemImage: "car")
                .font(.subheadline)
            HStack(spacing: ItinerarlyTheme.Spacing.sm) {
                ForEach(modes, id: \.self) { mode in
                    let isSelected = (viewModel.filter.transportMode == mode)
                    Button(action: { viewModel.updateTransportMode(mode) }) {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                            Text(mode.displayName)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, ItinerarlyTheme.Spacing.sm)
                    .padding(.vertical, 6)
                    .background(isSelected ? Color.purple : Color(.systemGray6))
                    .foregroundColor(isSelected ? .white : .primary)
                    .cornerRadius(8)
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
            HStack(spacing: ItinerarlyTheme.Spacing.sm) {
                if viewModel.isLoading {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(viewModel.isLoading ? "Génération..." : "Surprise me!")
                    .font(.system(size: 14, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(ItinerarlyTheme.Spacing.sm)
            .frame(height: 36)
            .background(ItinerarlyTheme.ModeColors.adventure.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(ItinerarlyTheme.CornerRadius.sm)
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