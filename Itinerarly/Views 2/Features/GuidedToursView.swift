import SwiftUI
import CoreLocation
import MapKit

struct GuidedToursView: View {
    @StateObject private var viewModel = GuidedToursViewModel()
    @EnvironmentObject var audioService: AudioService
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedCity: City = .paris
    @State private var showingTourDetail = false
    @State private var showingTourRoute = false
    @State private var selectedTour: GuidedTour?
    @State private var transportMode: TransportMode = .walking
    @State private var selectedCountry: String = "France"
    @State private var filteredCities: [City] = []
    
    // Location Selection
    @State private var useCurrentLocation = false
    @State private var startAddress = ""
    @State private var isGettingAddress = false
    @State private var showingMapPicker = false
    @State private var wantsToUseCurrentLocation = false
    @State private var geocodedLocation: CLLocation?
    @State private var confirmedAddress = ""
    @State private var isAddressConfirmed = false
    @State private var addressTimer: Timer?
    
    // Location Alert
    @State private var showingLocationAlert = false
    @State private var locationAlertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header - Design épuré
                    VStack(spacing: ItinerarlyTheme.Spacing.sm) {
                        // Titre en haut à gauche
                        HStack {
                            TranslatedText("Tours guidés")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        // Icône centrée
                        Image(systemName: "headphones")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(ItinerarlyTheme.ModeColors.guidedTours)
                            .padding(.top, ItinerarlyTheme.Spacing.sm)
                        
                        // Description centrée
                        Text("Découvrez 80+ villes à travers le monde avec des tours guidés générés par IA")
                            .font(ItinerarlyTheme.Typography.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, ItinerarlyTheme.Spacing.sm)
                        
                        // Indicateurs d'optimisation et mode aléatoire
                        VStack(spacing: ItinerarlyTheme.Spacing.xs) {
                            if viewModel.isLocationOptimized {
                                HStack {
                                    Image(systemName: "flag.filled")
                                        .foregroundColor(ItinerarlyTheme.success)
                                    Text("Tour personnalisé depuis votre point de départ")
                                        .font(ItinerarlyTheme.Typography.caption1)
                                        .foregroundColor(ItinerarlyTheme.success)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            if viewModel.isRandomMode {
                                HStack {
                                    Image(systemName: "dice.fill")
                                        .foregroundColor(ItinerarlyTheme.warning)
                                    Text("Tour sélectionné aléatoirement pour vous !")
                                        .font(ItinerarlyTheme.Typography.caption1)
                                        .foregroundColor(ItinerarlyTheme.warning)
                                }
                            }
                        }
                        .padding(.top, ItinerarlyTheme.Spacing.xs)
                    }
                    .padding(.top)
                    .onAppear {
                        // Initialiser la short‑list de villes dès l'apparition
                        filteredCities = getCitiesForCountry(selectedCountry)
                        if let first = filteredCities.first { selectedCity = first }
                    }
                    
                    // Section info supprimée
                    
                    // Location Selection Card
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Point de départ", systemImage: "mappin.and.ellipse")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if useCurrentLocation {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.orange)
                                Text("Position actuelle")
                                    .foregroundColor(.orange)
                                Spacer()
                                Button("Modifier") {
                                    useCurrentLocation = false
                                    isAddressConfirmed = false
                                    confirmedAddress = ""
                                }
                                .font(.caption)
                                .foregroundColor(.orange)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        } else if isAddressConfirmed && !confirmedAddress.isEmpty {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Adresse confirmée")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                    Text(confirmedAddress)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Button("Modifier") {
                                    isAddressConfirmed = false
                                    confirmedAddress = ""
                                    startAddress = ""
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            VStack(spacing: 8) {
                                LocationSearchField(
                                    text: $startAddress,
                                    placeholder: "Adresse de départ",
                                    userLocation: locationManager.location,
                                    onSuggestionSelected: { mapItem in
                                        // Mettre l'adresse formatée dans le champ
                                        let formattedAddress = formatAddressFromMapItem(mapItem)
                                        startAddress = formattedAddress
                                        // Valider automatiquement l'adresse sélectionnée
                                        confirmedAddress = formattedAddress
                                        isAddressConfirmed = true
                                    }
                                )
                                .simultaneousGesture(TapGesture().onEnded {
                                    if FeatureFlags.enableUseCurrentLocation && startAddress.trimmingCharacters(in: .whitespaces).isEmpty {
                                        getAddressFromCurrentLocation()
                                    }
                                })
                                // Validation manuelle supprimée pour un flux plus fluide
                            }
                            .overlay(alignment: .trailing) {
                                Button(action: { showingMapPicker = true }) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .padding(8)
                                }
                            }
                            .onChange(of: startAddress) { oldValue, newValue in
                                if newValue.isEmpty {
                                    isAddressConfirmed = false
                                    confirmedAddress = ""
                                    // Recharger sans adresse
                                    loadToursWithLocation(for: selectedCity)
                                } else if newValue.count > 5 {
                                    // Auto-confirmer l'adresse si elle fait plus de 5 caractères
                                    confirmedAddress = newValue
                                    isAddressConfirmed = true
                                    // Géocoder l'adresse pour obtenir les coordonnées
                                    geocodeAddress(newValue)
                                }
                            }
                                
                                if FeatureFlags.enableUseCurrentLocation {
                                Button(action: {
                                    getAddressFromCurrentLocation()
                                }) {
                                    HStack {
                                        if isGettingAddress {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "location.fill")
                                        }
                                        Text(isGettingAddress ? "Récupération de l'adresse..." : "Utiliser ma position")
                                    }
                                    .font(.caption)
                                        .foregroundColor(isGettingAddress ? .gray : ItinerarlyTheme.ModeColors.guidedTours)
                                }
                                .disabled(isGettingAddress)
                                }
                                
                                // Afficher le statut GPS si on utilise la position actuelle
                                if FeatureFlags.enableUseCurrentLocation && (useCurrentLocation || isGettingAddress) {
                                    HStack {
                                        Image(systemName: locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways ? "location.fill" : "location.slash")
                                            .foregroundColor(locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways ? .green : .red)
                                        Text(locationStatusText)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 4)
                                }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    

                    
                    // City Selector (menus déroulants stylés)
                    VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.sm) {
                        Text("Destination")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // Menu Pays
                        Menu {
                                ForEach(getUniqueCountries(), id: \.self) { country in
                                Button(country) {
                                        selectedCountry = country
                                        filteredCities = getCitiesForCountry(country)
                                    if let first = filteredCities.first {
                                        selectedCity = first
                                        loadToursWithLocation(for: first)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedCountry)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }

                        // Menu Ville
                        Menu {
                                ForEach(filteredCities, id: \.self) { city in
                                Button(city.displayName) {
                                        selectedCity = city
                                        loadToursWithLocation(for: city)
                                    }
                                }
                        } label: {
                            HStack {
                                Text(selectedCity.displayName)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                        .tint(ItinerarlyTheme.ModeColors.guidedTours)
                    }
                    
                    // Mode de transport
                    VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
                        TranslatedText("Mode de transport")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 10) {
                                ForEach(TransportMode.allCases, id: \.self) { mode in
                                GTTransportModeButton(
                                        mode: mode,
                                        isSelected: transportMode == mode
                                    ) {
                                        transportMode = mode
                                        if !viewModel.tours.isEmpty {
                                            loadToursWithLocation(for: selectedCity)
                                        }
                                    }
                                }
                        }
                    }
                    
                    // Mode aléatoire pour la ville sélectionnée
                    VStack(spacing: 16) {
                        Button(action: {
                            loadRandomTourWithLocation(for: selectedCity)
                        }) {
                            HStack(spacing: ItinerarlyTheme.Spacing.sm) {
                                Image(systemName: "dice.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(ItinerarlyTheme.ModeColors.guidedTours)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Mode Surprise - \(selectedCity.displayName)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Text("Tour aléatoire pour cette ville")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(ItinerarlyTheme.Spacing.md)
                            .frame(height: 48)
                            .background(Color(.systemBackground))
                            .cornerRadius(ItinerarlyTheme.CornerRadius.sm)
                            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Tours List
                    if viewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.2)
                            Text("Chargement des tours...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 200)
                    } else if viewModel.tours.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "map")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("Aucun tour disponible")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("pour cette ville pour le moment")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 200)
                    } else {
                        VStack(spacing: 16) {
                            // Bouton pour revenir au mode normal depuis le mode aléatoire
                            if viewModel.isRandomMode {
                                Button(action: {
                                    loadToursWithLocation(for: selectedCity)
                                }) {
                                    HStack {
                                        Image(systemName: "list.bullet")
                                        Text("Voir tous les tours de \(selectedCity.displayName)")
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                            
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.tours) { tour in
                                    // Optimiser le tour avec la position actuelle avant de l'afficher
                                    let optimizedTour = optimizeTourForDisplay(tour)
                                    
                                    TourCard(
                                        tour: optimizedTour,
                                        onDetailsTap: {
                                            // Mettre à jour le tour avec l'adresse actuelle du point de départ
                                            var updatedTour = tour
                                            let effectiveStartAddress = useCurrentLocation ? confirmedAddress : (isAddressConfirmed ? confirmedAddress : nil)
                                            updatedTour.startAddress = effectiveStartAddress
                                            
                                            // S'assurer que le tour est optimisé avec la position actuelle
                                            if let effectiveStartLocation = useCurrentLocation ? locationManager.location?.coordinate : geocodedLocation?.coordinate {
                                                updatedTour = TourOptimizer.optimizeTour(updatedTour, startLocation: effectiveStartLocation, startAddress: effectiveStartAddress, transportMode: transportMode)
                                            }
                                            
                                            selectedTour = updatedTour
                                            showingTourDetail = true
                                        },
                                        onRouteTap: {
                                            // Mettre à jour le tour avec l'adresse actuelle du point de départ
                                            var updatedTour = tour
                                            let effectiveStartAddress = useCurrentLocation ? confirmedAddress : (isAddressConfirmed ? confirmedAddress : nil)
                                            updatedTour.startAddress = effectiveStartAddress
                                            
                                            // S'assurer que le tour est optimisé avec la position actuelle
                                            if let effectiveStartLocation = useCurrentLocation ? locationManager.location?.coordinate : geocodedLocation?.coordinate {
                                                updatedTour = TourOptimizer.optimizeTour(updatedTour, startLocation: effectiveStartLocation, startAddress: effectiveStartAddress, transportMode: transportMode)
                                            }
                                            
                                            selectedTour = updatedTour
                                            showingTourRoute = true
                                        }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(ItinerarlyTheme.Spacing.md)
            }
            .navigationBarHidden(true)
            .itinerarlyBackground(mode: .guidedTours)
            .sheet(isPresented: $showingTourDetail) {
                if let tour = selectedTour {
                    TourDetailView(tour: tour)
                        .environmentObject(audioService)
                }
            }
            .sheet(isPresented: $showingTourRoute) {
                if let tour = selectedTour {
                    NavigationView {
                        TourRouteMapView(tour: tour)
                            .environmentObject(audioService)
                    }
                }
            }
        }
        .sheet(isPresented: $showingMapPicker) {
            MapPickerView(
                cityName: selectedCity.displayName,
                initialCoordinate: geocodedLocation?.coordinate,
                onPicked: { loc, address in
                    self.startAddress = address
                    self.confirmedAddress = address
                    self.isAddressConfirmed = true
                    self.geocodedLocation = loc
                    loadToursWithLocation(for: selectedCity)
                }
            )
        }
        .onAppear {
            if viewModel.tours.isEmpty {
                loadToursWithLocation(for: selectedCity)
            }
        }
        .onReceive(locationManager.$location) { location in
            guard FeatureFlags.enableUseCurrentLocation else { return }
            // Observer pour le bouton "Utiliser ma position"
            if let location = location, isGettingAddress {
                // Dès qu'on a une position et qu'on attend, on l'utilise
                locationManager.reverseGeocode(location) { result in
                    DispatchQueue.main.async {
                        self.isGettingAddress = false
                        self.locationManager.stopUpdatingLocation()
                        
                        switch result {
                        case .success(let address):
                            self.startAddress = address
                            self.confirmedAddress = address
                            self.isAddressConfirmed = true
                            self.geocodedLocation = location
                            self.useCurrentLocation = true
                            // Recharger les tours avec la nouvelle position
                            self.loadToursWithLocation(for: self.selectedCity)
                        case .failure(_):
                            // Utiliser les coordonnées en cas d'échec
                            let coordString = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
                            self.startAddress = coordString
                            self.confirmedAddress = coordString
                            self.isAddressConfirmed = true
                            self.geocodedLocation = location
                            self.useCurrentLocation = true
                            // Recharger les tours avec la nouvelle position
                            self.loadToursWithLocation(for: self.selectedCity)
                        }
                    }
                }
            }
        }
        .onChange(of: locationManager.authorizationStatus) { _ in }
        .alert("Autorisation de localisation", isPresented: $showingLocationAlert) {
            Button("Annuler") { }
            Button("Ouvrir Réglages") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Réessayer") {
                getAddressFromCurrentLocation()
            }
        } message: {
            Text(locationAlertMessage)
        }
    }
    
    // MARK: - Location Methods
    
    private func getAddressFromCurrentLocation() {
        guard FeatureFlags.enableUseCurrentLocation else { return }
        isGettingAddress = true
        wantsToUseCurrentLocation = true
        
        // Demander/rafraîchir l'autorisation sans vérifs bloquantes
        locationManager.requestWhenInUseAuthorization()
        
        // Démarrer la récupération de position immédiatement
        locationManager.startUpdatingLocation()
        
        // Timeout de sécurité
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if self.isGettingAddress {
                self.isGettingAddress = false
                self.wantsToUseCurrentLocation = false
                self.locationManager.stopUpdatingLocation()
                if let last = self.locationManager.location {
                    self.locationManager.reverseGeocode(last) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let address):
                                self.startAddress = address
                                self.confirmedAddress = address
                                self.isAddressConfirmed = true
                                self.geocodedLocation = last
                            case .failure(_):
                                let coordString = String(format: "%.6f, %.6f", last.coordinate.latitude, last.coordinate.longitude)
                                self.startAddress = coordString
                                self.confirmedAddress = coordString
                                self.isAddressConfirmed = true
                                self.geocodedLocation = last
                            }
                        }
                    }
                } else {
                    self.showLocationError("Impossible d'obtenir votre position. Vérifiez que la localisation est activée et que vous êtes à l'extérieur.")
                }
            }
        }
    }
    
    private func geocodeAddress(_ address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur de géocodage: \(error.localizedDescription)")
                    return
                }
                
                if let placemark = placemarks?.first {
                    geocodedLocation = placemark.location
                    print("✅ Adresse géocodée: \(address) -> \(placemark.location?.coordinate.latitude ?? 0), \(placemark.location?.coordinate.longitude ?? 0)")
                    
                    // Charger les tours avec la nouvelle position
                    loadToursWithLocation(for: selectedCity)
                }
            }
        }
    }
    
    private func formatAddressFromMapItem(_ mapItem: MKMapItem) -> String {
        var components: [String] = []
        
        // Ajouter le nom du POI s'il existe
        if let name = mapItem.name, !name.isEmpty {
            components.append(name)
        }
        
        // Ajouter l'adresse complète
        var addressComponents: [String] = []
        
        if let number = mapItem.placemark.subThoroughfare {
            addressComponents.append(number)
        }
        
        if let street = mapItem.placemark.thoroughfare {
            addressComponents.append(street)
        }
        
        if let city = mapItem.placemark.locality {
            addressComponents.append(city)
        }
        
        if let postalCode = mapItem.placemark.postalCode {
            addressComponents.append(postalCode)
        }
        
        // Si on a une adresse complète, l'utiliser
        if !addressComponents.isEmpty {
            let fullAddress = addressComponents.joined(separator: ", ")
            components.append(fullAddress)
        }
        
        // Joindre le nom et l'adresse
        let result = components.joined(separator: ", ")
        
        // Si on n'a rien, utiliser le titre ou le nom
        if result.isEmpty {
            return mapItem.name ?? mapItem.placemark.title ?? "Adresse sélectionnée"
        }
        
        return result
    }
    
    private func loadToursWithLocation(for city: City) {
        // Priorité 1: Utiliser la position actuelle si activée
        let effectiveStartLocation: CLLocation?
        let effectiveStartAddress: String?
        
        if useCurrentLocation {
            effectiveStartLocation = locationManager.location
            effectiveStartAddress = confirmedAddress
        } else if isAddressConfirmed && !confirmedAddress.isEmpty {
            // Priorité 2: Utiliser l'adresse confirmée géocodée
            effectiveStartLocation = geocodedLocation
            effectiveStartAddress = confirmedAddress
        } else {
            // Priorité 3: Utiliser la position actuelle comme fallback
            effectiveStartLocation = locationManager.location
            effectiveStartAddress = nil
        }
        
        print("📍 Point de départ utilisé: \(effectiveStartAddress ?? "Position GPS")")
        if let location = effectiveStartLocation {
            print("📍 Coordonnées: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
        
        viewModel.loadToursWithLocation(for: city, startLocation: effectiveStartLocation, startAddress: effectiveStartAddress)
    }
    
    private func loadRandomTourWithLocation(for city: City) {
        // Priorité 1: Utiliser la position actuelle si activée
        let effectiveStartLocation: CLLocation?
        let effectiveStartAddress: String?
        
        if useCurrentLocation {
            effectiveStartLocation = locationManager.location
            effectiveStartAddress = confirmedAddress
        } else if isAddressConfirmed && !confirmedAddress.isEmpty {
            // Priorité 2: Utiliser l'adresse confirmée géocodée
            effectiveStartLocation = geocodedLocation
            effectiveStartAddress = confirmedAddress
        } else {
            // Priorité 3: Utiliser la position actuelle comme fallback
            effectiveStartLocation = locationManager.location
            effectiveStartAddress = nil
        }
        
        print("🎲 Tour aléatoire - Point de départ: \(effectiveStartAddress ?? "Position GPS")")
        if let location = effectiveStartLocation {
            print("🎲 Coordonnées: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
        
        viewModel.loadRandomTourWithLocation(for: city, startLocation: effectiveStartLocation, startAddress: effectiveStartAddress)
    }
    
    private func optimizeTourForDisplay(_ tour: GuidedTour) -> GuidedTour {
        // Déterminer le point de départ selon la priorité
        let effectiveStartLocation: CLLocation?
        let effectiveStartAddress: String?
        
        if useCurrentLocation {
            effectiveStartLocation = locationManager.location
            effectiveStartAddress = confirmedAddress
        } else if isAddressConfirmed && !confirmedAddress.isEmpty {
            effectiveStartLocation = geocodedLocation
            effectiveStartAddress = confirmedAddress
        } else {
            effectiveStartLocation = locationManager.location
            effectiveStartAddress = nil
        }
        
        // Si on a une position de départ, optimiser le tour
        if let startLocation = effectiveStartLocation {
            return TourOptimizer.optimizeTour(tour, startLocation: startLocation.coordinate, startAddress: effectiveStartAddress, transportMode: transportMode)
        }
        
        // Sinon, retourner le tour original
        return tour
    }
    
    private func showLocationError(_ message: String) {
        locationAlertMessage = message
        showingLocationAlert = true
    }
    
    private var locationStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Appuyez pour autoriser la localisation"
        case .denied, .restricted:
            return "Ouvrir Réglages → Confidentialité → Localisation"
        case .authorizedWhenInUse, .authorizedAlways:
            if let location = locationManager.location {
                let accuracy = location.horizontalAccuracy
                if accuracy < 5 {
                    return "🟢 GPS haute précision (\(Int(accuracy))m)"
                } else if accuracy < 20 {
                    return "🟡 GPS précis (\(Int(accuracy))m)"
                } else {
                    return "🟠 GPS approximatif (\(Int(accuracy))m)"
                }
            } else {
                return "🔍 Recherche du signal GPS..."
            }
        @unknown default:
            return "❓ Statut GPS inconnu"
        }
    }
}

struct CitySelectionCard: View {
    let city: City
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: ItinerarlyTheme.Spacing.sm) {
                Text(city.flag)
                    .font(.system(size: 30))
                
                Text(city.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 120, height: 100)
            .background(
                isSelected ? 
                LinearGradient(gradient: Gradient(colors: [.purple, .purple.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                LinearGradient(gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray6)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TourCard: View {
    let tour: GuidedTour
    let onDetailsTap: () -> Void
    let onRouteTap: () -> Void
    
    // Système de suivi global des images utilisées
    @State private static var usedImages: Set<String> = []
    @State private static var imageAssignments: [String: String] = [:]
    
    // Fonction supprimée - on utilise maintenant les images fixes de Paris
    
    // Utiliser directement les images de Paris (sans API)
    private func getPreferredImageURL(for tour: GuidedTour) -> String {
        return getFallbackImageURL(for: tour)
    }
    
    // Images fixes par ville (sans API) - Système d'unicité garantie
    private func getFallbackImageURL(for tour: GuidedTour) -> String {
        // Vérifier si une image est déjà assignée à ce tour
        if let assignedImage = TourCard.imageAssignments[tour.id] {
            return assignedImage
        }
        
        switch tour.city {
        case .paris:
            let parisImages = [
                "https://cdn.pixabay.com/photo/2022/09/02/13/45/paris-7427636_1280.jpg",
                "https://cdn.pixabay.com/photo/2021/11/17/15/07/paris-6803796_1280.jpg",
                "https://cdn.pixabay.com/photo/2024/09/22/09/39/pantheon-paris-9065570_1280.jpg",
                "https://cdn.pixabay.com/photo/2021/08/14/01/58/museum-6544420_1280.jpg"
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: parisImages.count)
            return parisImages[index]
            
        case .marseille:
            let marseilleImages = [
                "https://cdn.pixabay.com/photo/2022/08/02/08/39/church-7359849_1280.jpg",
                "https://cdn.pixabay.com/photo/2019/11/10/13/13/marseille-4615791_1280.jpg",
                "https://cdn.pixabay.com/photo/2017/01/14/23/51/soldiers-1980666_1280.jpg",
                "https://cdn.pixabay.com/photo/2015/10/23/22/32/marseille-1003822_1280.jpg"
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: marseilleImages.count)
            return marseilleImages[index]
            
        case .nice:
            let niceImages = [
                "https://cdn.pixabay.com/photo/2018/03/03/09/46/travel-3195287_1280.jpg",
                "https://cdn.pixabay.com/photo/2019/10/01/20/31/nice-4519328_1280.jpg",
                "https://cdn.pixabay.com/photo/2016/11/04/10/23/nice-1797345_1280.jpg"
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: niceImages.count)
            return niceImages[index]
            
        case .lyon:
            let lyonImages = [
                "https://cdn.pixabay.com/photo/2018/08/11/12/57/lyon-3598618_1280.jpg",
                "https://cdn.pixabay.com/photo/2015/10/25/15/26/lyon-1005953_1280.jpg",
                "https://cdn.pixabay.com/photo/2015/09/16/14/46/lyon-942770_1280.jpg",
                "https://cdn.pixabay.com/photo/2020/02/27/08/05/city-4883769_1280.jpg"
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: lyonImages.count)
            return lyonImages[index]
            
        case .bordeaux:
            let bordeauxImages = [
                "https://cdn.pixabay.com/photo/2022/05/04/09/13/bordeaux-7173548_1280.jpg",
                "https://cdn.pixabay.com/photo/2023/10/03/09/59/bridge-8291058_1280.jpg",
                "https://cdn.pixabay.com/photo/2018/12/15/14/43/bordeaux-3876988_1280.jpg",
                "https://cdn.pixabay.com/photo/2017/03/17/10/42/grand-2151219_1280.jpg"
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: bordeauxImages.count)
            return bordeauxImages[index]
            
        case .berlin:
            let berlinImages = [
                "https://cdn.pixabay.com/photo/2018/12/01/00/10/blue-hour-3848856_1280.jpg",
                "https://cdn.pixabay.com/photo/2019/09/11/11/39/city-4468570_1280.jpg",
                "https://cdn.pixabay.com/photo/2022/01/28/20/38/road-6975808_1280.jpg"
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: berlinImages.count)
            return berlinImages[index]
            
        case .brussels:
            let brusselsImages = [
                "https://cdn.pixabay.com/photo/2016/07/27/20/58/brussels-1546290_1280.jpg",
                "https://cdn.pixabay.com/photo/2016/01/13/17/02/belgium-1138448_1280.jpg",
                "https://cdn.pixabay.com/photo/2014/11/06/21/13/brussels-519965_1280.jpg",
                "https://cdn.pixabay.com/photo/2018/08/10/19/10/royal-palace-of-brussels-3597435_1280.jpg"
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: brusselsImages.count)
            return brusselsImages[index]
            
        case .bruges:
            let brugesImages = [
                "https://cdn.pixabay.com/photo/2020/03/25/09/30/belgium-4966646_1280.jpg",
                "https://cdn.pixabay.com/photo/2017/03/04/10/12/belgian-2115765_1280.jpg",
                "https://cdn.pixabay.com/photo/2018/08/19/12/20/brugge-3616516_1280.jpg"
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: brugesImages.count)
            return brugesImages[index]
            
        case .barcelona:
            let barcelonaImages = [
                "https://cdn.pixabay.com/photo/2020/05/18/22/17/travel-5188598_1280.jpg",
                "https://cdn.pixabay.com/photo/2021/06/28/13/00/buildings-6371608_1280.jpg",
                "https://cdn.pixabay.com/photo/2013/09/18/16/52/barcelona-183504_1280.jpg",
                "https://cdn.pixabay.com/photo/2020/03/14/09/31/barcelona-4930104_1280.jpg"
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: barcelonaImages.count)
            return barcelonaImages[index]
            
        case .madrid:
            let madridImages = [
                "https://cdn.pixabay.com/photo/2019/01/24/09/38/madrid-3952068_1280.jpg",
                "https://cdn.pixabay.com/photo/2017/10/19/13/52/park-2867683_1280.jpg",
                "https://cdn.pixabay.com/photo/2014/04/19/12/40/madrid-327979_1280.jpg",
                "https://cdn.pixabay.com/photo/2017/06/08/16/43/madrid-2384099_1280.jpg"
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: madridImages.count)
            return madridImages[index]
            
        case .newYork:
            let newYorkImages = [
                "https://cdn.pixabay.com/photo/2015/03/11/12/31/buildings-668616_1280.jpg",
                "https://cdn.pixabay.com/photo/2016/08/13/03/01/new-york-1590176_1280.jpg"
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: newYorkImages.count)
            return newYorkImages[index]
            
        case .rome:
            let romeImages = [
                "https://cdn.pixabay.com/photo/2020/05/17/12/56/rome-5181486_1280.jpg",
                "https://cdn.pixabay.com/photo/2017/05/30/18/06/rome-2357704_1280.jpg",
                "https://cdn.pixabay.com/photo/2015/09/01/16/27/rome-917190_1280.jpg",
                "https://cdn.pixabay.com/photo/2014/10/11/15/29/ancient-rome-484705_1280.jpg"
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: romeImages.count)
            return romeImages[index]
            
        case .milan:
            let milanImages = [
                "https://cdn.pixabay.com/photo/2017/06/24/00/54/milan-cathedral-2436458_1280.jpg",
                "https://cdn.pixabay.com/photo/2021/07/25/09/47/italy-6491421_1280.jpg",
                "https://cdn.pixabay.com/photo/2019/08/31/18/36/tram-4443797_1280.jpg"
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: milanImages.count)
            return milanImages[index]
            
        case .luxembourg:
            let luxembourgImages = [
                "https://cdn.pixabay.com/photo/2016/01/27/15/29/luxembourg-1164656_1280.jpg",
                "https://cdn.pixabay.com/photo/2016/01/27/15/29/luxembourg-1164664_1280.jpg",
                "https://cdn.pixabay.com/photo/2017/08/18/18/57/luxembourg-2656040_1280.jpg",
                "https://cdn.pixabay.com/photo/2022/03/01/13/41/travel-7041341_1280.jpg"
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: luxembourgImages.count)
            return luxembourgImages[index]
            
        case .casablanca:
            let casablancaImages = [
                "https://cdn.pixabay.com/photo/2019/04/17/14/54/mosque-4134459_1280.jpg",
                "https://cdn.pixabay.com/photo/2017/06/13/20/16/casablanca-2399980_1280.jpg",
                "https://media.gettyimages.com/id/84288050/fr/photo/place-mohammed-v-and-city-skyline-dusk.jpg?s=612x612&w=0&k=20&c=iLyuxkuakGgTnzJpUZBudlPIQTvpIi9fSjrhJ63QGV4="
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: casablancaImages.count)
            return casablancaImages[index]
            
        case .tangier:
            let tangierImages = [
                "https://media.gettyimages.com/id/1979490792/fr/photo/view-of-tanger-city-beach-morocco.jpg?s=612x612&w=0&k=20&c=Sw3F_J3oLpgRkfmH7k55xJMa89vle6BTljTylJ4d2Mc=",
                "https://media.gettyimages.com/id/986935356/fr/photo/north-africa-maghreb-morocco-tangier-old-medina-and-famous-continental-hotel.jpg?s=612x612&w=0&k=20&c=C7RP5QEcYz6cvnpDM404su8p5uvofIAp8QZNhkLWCtY=",
                "https://media.gettyimages.com/id/979518900/fr/photo/tangier-harbour.jpg?s=612x612&w=0&k=20&c=6A_g9UmhyB4z7CmEiVDQ1qJXWjNwXqJYpn-hrl0g5qg="
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: tangierImages.count)
            return tangierImages[index]
            
        case .marrakech:
            let marrakechImages = [
                "https://media.gettyimages.com/id/475057992/fr/photo/soir%C3%A9e-djemaa-el-fna-la-mosqu%C3%A9e-de-la-koutoubia-marrakech-maroc.jpg?s=612x612&w=0&k=20&c=kR27kcBe8Hf0uIutFHF5mRv4op4CxfuBhIJHpUKKYHM=",
                "https://media.gettyimages.com/id/577088095/fr/photo/menara-pavilion-and-gardens-marrakesh.jpg?s=612x612&w=0&k=20&c=wzGIbUyCABIOMpBDsYtHPXFUh5TI3YPvHdW8MNFn8I0=",
                "https://media.gettyimages.com/id/1452433155/fr/photo/touriste-chinoise-dorigine-asiatique-curieuse-regardant-des-fleurs-s%C3%A9ch%C3%A9es-color%C3%A9es-sur-un.jpg?s=612x612&w=0&k=20&c=xo-uPjXZ3vGscxDfbEz0Sro80ZbGpzJGcQKE1C1nQ9E="
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: marrakechImages.count)
            return marrakechImages[index]
            
        case .amsterdam:
            let amsterdamImages = [
                "https://media.gettyimages.com/id/1495422795/fr/photo/old-historic-dutch-houses-reflecting-in-the-canal-on-a-sunny-day-amsterdam-netherlands.jpg?s=612x612&w=0&k=20&c=zAq5X3vqwA2s4Xyo7h_l1qv0w8ThQmEzYN-IiCHe3k4=",
                "https://media.gettyimages.com/photo/tulipes-et-moulins-%C3%A0-vent.jpg?s=612x612&w=0&k=20&c=fSir4_pq-wAbwXNoZJV9lL2TrYo2iWj52jG7mgukq2I=",
                "https://media.gettyimages.com/id/1407111882/fr/photo/traditional-dutch-houses-reflecting-in-the-canal-in-jordaan-neighbourhood-amsterdam.jpg?s=612x612&w=0&k=20&c=5aIciikZM5u8AEvBCeGjgTzXFNUkI00CjYv-7tb6OdU="
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: amsterdamImages.count)
            return amsterdamImages[index]
            
        case .london:
            let londonImages = [
                "https://media.gettyimages.com/id/174726708/photo/london-big-ben-and-traffic-on-westminster-bridge.jpg?s=612x612&w=0&k=20&c=K0EcQ1Eq_F22vek8L9CVRCww12g6V3LPdWGboF0NMWo=",
                "https://media.gettyimages.com/id/2158963864/photo/aerial-view-of-finance-district-in-london.jpg?s=612x612&w=0&k=20&c=rci0quMZuxaVrS9qp0DZ3w2AtxPC2TCdqWjAocdjYW0=",
                "https://media.gettyimages.com/id/1464758942/photo/regent-street-and-red-double-decker-bus-london-uk.jpg?s=612x612&w=0&k=20&c=iSP9GbAmCdSkphuXz4ct9xC7a5RFlBGByMhSovD24IU=",
                "https://media.gettyimages.com/id/1974859701/photo/pink-magnolia-blossoms-adorn-londons-streets-in-spring.jpg?s=612x612&w=0&k=20&c=ydu8pGx2QY3_Qzl_SH5bfvJxek_PYSvIO6LHjC2dyXA="
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: londonImages.count)
            return londonImages[index]
            
        case .istanbul:
            let istanbulImages = [
                "https://media.gettyimages.com/id/1942782951/photo/istanbul-cityscape-with-bosphorus-and-galata-tower-on-a-sunny-summer-day-turkey.jpg?s=612x612&w=0&k=20&c=xeHgGnCDWUU0NO6RExp69cz8y9PFoDTg9zsAtbJvlv8=",
                "https://media.gettyimages.com/id/160193420/photo/blue-mosque-in-istanbul.jpg?s=612x612&w=0&k=20&c=GABmGJwvlo-ejMwPZKCU4YCUyiVxXNHc5dDneL7o0Mg=",
                "https://media.gettyimages.com/id/1576877722/photo/narrow-street-with-galata-tower-and-historic-building-in-beyoglu-district-istanbul-turkey.jpg?s=612x612&w=0&k=20&c=kwQZjR-BkXbY_2KJ0DB0amw4kXZF5WJf_OwmuHg4Mog=",
                "https://media.gettyimages.com/id/522616554/photo/grand-bazaar-in-istanbul.jpg?s=612x612&w=0&k=20&c=mDUbw5CoBqK_zqkNfsxk2P9KPC2szX07Df7CWorOnUA="
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: istanbulImages.count)
            return istanbulImages[index]
            
        case .prague:
            let pragueImages = [
                "https://media.gettyimages.com/id/1488321283/photo/old-town-square.jpg?s=612x612&w=0&k=20&c=9HoiJWkQ-qNpP03owQ1798NBAwzXpREIHVHp2Q1bRyY=",
                "https://media.gettyimages.com/id/142761840/photo/view-from-letna-to-prague-city.jpg?s=612x612&w=0&k=20&c=ShQufC49I7l1QE-c0_ZRUZayVVi2_znSkgXG_sUD8VU=",
                "https://media.gettyimages.com/id/1733473763/photo/view-of-prague-old-town-at-winter-over-vltava-river.jpg?s=612x612&w=0&k=20&c=Y-ms3x4vUxsjRrIU4YyWEbi6LgPX7PpKZf6QRdUPrAQ="
            ]
            let index = getUniqueImageIndex(for: tour, totalImages: pragueImages.count)
            return pragueImages[index]
            
        default:
            // Pour les autres villes, utiliser les images de Paris par défaut
            let parisImages = [
                "https://cdn.pixabay.com/photo/2022/09/02/13/45/paris-7427636_1280.jpg",
                "https://cdn.pixabay.com/photo/2021/11/17/15/07/paris-6803796_1280.jpg",
                "https://cdn.pixabay.com/photo/2024/09/22/09/39/pantheon-paris-9065570_1280.jpg",
                "https://cdn.pixabay.com/photo/2021/08/14/01/58/museum-6544420_1280.jpg"
            ]
            let tourIndex = getTourIndex(for: tour)
            let index = tourIndex % parisImages.count
            return parisImages[index]
        }
    }
    
    // Fonction pour obtenir l'index du tour dans la liste des tours de sa ville
    // Dictionnaire pour suivre les images utilisées par ville
    @State private var usedImagesByCity: [City: Set<Int>] = [:]
    
    private func getTourIndex(for tour: GuidedTour) -> Int {
        // Utiliser une combinaison de plusieurs propriétés pour créer un index unique
        let combinedString = tour.title + tour.id + String(tour.stops.count) + tour.difficulty.rawValue
        let combinedHash = abs(combinedString.hashValue)
        return combinedHash % 100 // Limiter à 100 pour éviter les nombres trop grands
    }
    
    private func getUniqueImageIndex(for tour: GuidedTour, totalImages: Int) -> Int {
        let city = tour.city
        
        // Utiliser une approche déterministe basée sur l'ID du tour pour éviter les conflits
        // sans modifier l'état pendant le rendu
        let tourId = tour.id
        let cityHash = city.rawValue.hashValue
        
        // Éviter le débordement arithmétique en utilisant une approche plus sûre
        let tourHash = tourId.hashValue
        let combinedHash = abs(tourHash ^ cityHash) // Utiliser XOR au lieu de l'addition
        
        // Calculer un index unique basé sur le hash combiné
        var imageIndex = combinedHash % totalImages
        
        // Si l'index est 0, utiliser une variation basée sur d'autres propriétés
        if imageIndex == 0 {
            let titleHash = tour.title.hashValue
            let difficultyHash = tour.difficulty.rawValue.hashValue
            imageIndex = abs(titleHash ^ difficultyHash) % totalImages
        }
        
        return imageIndex
    }
    
    var body: some View {
        Button(action: onDetailsTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Tour Image (phase-based pour gérer succès/erreur proprement)
                AsyncImage(url: URL(string: getPreferredImageURL(for: tour))) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [ItinerarlyTheme.ModeColors.guidedTours.opacity(0.3), ItinerarlyTheme.ModeColors.guidedTours.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .aspectRatio(16.0/9.0, contentMode: .fill)
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                            )
                    case .success(let image):
                    image
                        .resizable()
                            .scaledToFill()
                            .aspectRatio(16.0/9.0, contentMode: .fill)
                            .transition(.opacity)
                    case .failure:
                        // Tentative de chargement d'une image de secours
                        AsyncImage(url: URL(string: getFallbackImageURL(for: tour))) { secondaryPhase in
                            switch secondaryPhase {
                            case .empty:
                                Rectangle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [ItinerarlyTheme.ModeColors.guidedTours.opacity(0.3), ItinerarlyTheme.ModeColors.guidedTours.opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .aspectRatio(16.0/9.0, contentMode: .fill)
                                    .overlay(ProgressView().tint(.white))
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .aspectRatio(16.0/9.0, contentMode: .fill)
                            case .failure:
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [ItinerarlyTheme.ModeColors.guidedTours.opacity(0.3), ItinerarlyTheme.ModeColors.guidedTours.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .aspectRatio(16.0/9.0, contentMode: .fill)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        )
                            @unknown default:
                                Color.gray.opacity(0.2)
                            }
                        }
                    @unknown default:
                        Color.gray.opacity(0.2)
                    }
                }
                // Hauteur fixe et recadrage pour éviter les images trop hautes
                .frame(height: ItinerarlyTheme.Sizes.tourCardImageHeight)
                .cornerRadius(12)
                .clipped()
                
                // Tour Info
                VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.sm) {
                    HStack {
                        Text(tour.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if let rating = tour.rating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                Text(String(format: "%.1f", rating))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                
                    Text(tour.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    // Informations d'itinéraire optimisé
                    HStack(spacing: 16) {
                        // Distance totale (utiliser les valeurs optimisées si disponibles)
                        HStack(spacing: 4) {
                            Image(systemName: "figure.walk")
                                .foregroundColor(.green)
                            Text(TourOptimizer.formatDistance(tour.totalDistance ?? calculateTotalDistance()))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        // Temps de marche (utiliser les valeurs optimisées si disponibles)
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .foregroundColor(.orange)
                            Text(TourOptimizer.formatDuration(tour.estimatedTravelTime ?? calculateTravelTime()))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    // Indicateur de point de départ personnalisé
                    if tour.startAddress != nil || tour.startLocation != nil {
                        HStack {
                            Image(systemName: "flag.filled")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Départ depuis votre adresse")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    HStack {
                        // Duration totale
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                            Text(TourOptimizer.formatDuration(tour.duration))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        // Difficulty
                        HStack(spacing: 4) {
                            Image(systemName: tour.difficulty.icon)
                                .foregroundColor(.orange)
                            Text(tour.difficulty.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        // Stops count
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.green)
                            Text("\(tour.stops.count) arrêts")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    .foregroundColor(.secondary)
                    
                    // Boutons d'action
                    HStack(spacing: ItinerarlyTheme.Spacing.sm) {
                        // Voir détails
                        Button(action: onDetailsTap) {
                            HStack {
                                Image(systemName: "info.circle")
                                Text("Détails")
                                    .fontWeight(.medium)
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .allowsHitTesting(true)
                        
                        // Parcours parfait
                        Button(action: onRouteTap) {
                            HStack {
                                Image(systemName: "map")
                                Text("Parcours")
                                    .fontWeight(.medium)
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .allowsHitTesting(true)
                        
                        Spacer()
                        
                        // Price (if available)
                        if let price = tour.price, price > 0 {
                            Text(String(format: "%.2f €", price))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        } else {
                            Text("Gratuit")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func calculateTotalDistance() -> Double {
        // Calculer la distance totale entre tous les arrêts
        let stops = tour.optimizedStops ?? tour.stops
        guard stops.count > 1 else { return 0 }
        
        var totalDistance: Double = 0
        
        // Calculer les distances entre les arrêts
        for i in 0..<stops.count - 1 {
            let from = stops[i]
            let to = stops[i + 1]
            
            let distance = CLLocation(latitude: from.location.latitude, longitude: from.location.longitude)
                .distance(from: to.location.clLocation)
            totalDistance += distance
        }
        
        return totalDistance
    }
    
    private func calculateTravelTime() -> TimeInterval {
        let totalDistance = calculateTotalDistance()
        // Estimation : 5 km/h pour la marche
        return totalDistance / (5000 / 3600) // 5000 mètres par heure
    }
}

#Preview {
    GuidedToursView()
        .environmentObject(AudioService())
}

// MARK: - Helper Functions
extension GuidedToursView {
    private func getUniqueCountries() -> [String] {
        // Pays autorisés pour les tours guidés curés
        return [
            "Allemagne",
            "Belgique",
            "Espagne",
            "États-Unis",
            "France",
            "Italie",
            "Luxembourg",
            "Maroc",
            "Pays-Bas",
            "Royaume-Uni",
            "Turquie",
            "Tchéquie"
        ]
    }
    
    private func getCitiesForCountry(_ country: String) -> [City] {
        switch country {
        case "France":
            return [.paris, .marseille, .lyon, .nice, .bordeaux]
        case "Belgique":
            return [.brussels, .bruges]
        case "Luxembourg":
            return [.luxembourg]
        case "Allemagne":
            return [.berlin]
        case "Espagne":
            return [.barcelona, .madrid]
        case "Italie":
            return [.rome, .milan]
        case "Maroc":
            return [.casablanca, .tangier, .marrakech]
        case "Royaume-Uni":
            return [.london]
        case "Turquie":
            return [.istanbul]
        case "États-Unis":
            return [.newYork]
        case "Pays-Bas":
            return [.amsterdam]
        case "Tchéquie":
            return [.prague]
        default:
            return []
        }
    }
}

// MARK: - Country Filter Button
struct CountryFilterButton: View {
    let country: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(country)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? 
                    Color.purple :
                    Color(.systemGray6)
                )
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 

// MARK: - Transport button harmonisé (taille compacte)
struct GTTransportModeButton: View {
    let mode: TransportMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.system(size: 14, weight: .medium))
                Text(mode.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 70, height: 48)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 