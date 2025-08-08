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
    @State private var filteredCities: [City] = City.allCases.filter { $0.country == "France" }
    
    // Location Selection
    @State private var useCurrentLocation = false
    @State private var startAddress = ""
    @State private var isGettingAddress = false
    @State private var geocodedLocation: CLLocation?
    @State private var confirmedAddress = ""
    @State private var isAddressConfirmed = false
    @State private var addressTimer: Timer?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header - Design épuré
                    VStack(spacing: ItinerarlyTheme.Spacing.md) {
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
                        Text("Découvrez 80+ villes européennes avec des tours guidés générés par IA")
                            .font(ItinerarlyTheme.Typography.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, ItinerarlyTheme.Spacing.sm)
                        
                        // Indicateurs d'optimisation et mode aléatoire
                        VStack(spacing: ItinerarlyTheme.Spacing.xs) {
                            if viewModel.isLocationOptimized {
                                HStack {
                                    Image(systemName: "location.circle.fill")
                                        .foregroundColor(ItinerarlyTheme.success)
                                    Text("Itinéraire optimisé depuis votre position")
                                        .font(ItinerarlyTheme.Typography.caption1)
                                        .foregroundColor(ItinerarlyTheme.success)
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
                    
                    // Info sur les nouvelles fonctionnalités
                    VStack(spacing: ItinerarlyTheme.Spacing.md) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(ItinerarlyTheme.ModeColors.guidedTours)
                            Text("Nouveau : Tours guidés générés par IA")
                                .font(ItinerarlyTheme.Typography.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(ItinerarlyTheme.ModeColors.guidedTours)
                        }
                        
                        Text("L'IA crée des itinéraires optimisés avec guides audio détaillés en français pour chaque ville")
                            .font(ItinerarlyTheme.Typography.caption1)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(ItinerarlyTheme.Spacing.lg)
                    .background(ItinerarlyTheme.ModeColors.guidedTours.opacity(0.1))
                    .cornerRadius(ItinerarlyTheme.CornerRadius.md)
                    
                    // Location Selection Card
                    VStack(alignment: .leading, spacing: 16) {
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
                                        
                                        // Ne pas confirmer automatiquement, attendre la validation manuelle
                                    }
                                )
                                
                                // Bouton de validation de l'adresse
                                if !startAddress.isEmpty && !isAddressConfirmed {
                                    Button(action: {
                                        // Confirmer l'adresse manuellement
                                        confirmedAddress = startAddress
                                                isAddressConfirmed = true
                                        geocodeAddress(startAddress)
                                    }) {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("Valider cette adresse")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .onChange(of: startAddress) { oldValue, newValue in
                                // Ne pas confirmer automatiquement l'adresse
                                if newValue.isEmpty {
                                        isAddressConfirmed = false
                                        confirmedAddress = ""
                                        // Recharger sans adresse
                                        loadToursWithLocation(for: selectedCity)
                                    }
                                }
                                
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
                                    .foregroundColor(isGettingAddress ? .gray : .orange)
                                }
                                .disabled(isGettingAddress)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    

                    
                    // City Selector
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ou choisissez votre destination")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // Sélecteur de pays
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: ItinerarlyTheme.Spacing.sm) {
                                ForEach(getUniqueCountries(), id: \.self) { country in
                                    CountryFilterButton(
                                        country: country,
                                        isSelected: selectedCountry == country
                                    ) {
                                        selectedCountry = country
                                        filteredCities = getCitiesForCountry(country)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Sélecteur de villes
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 16) {
                                ForEach(filteredCities, id: \.self) { city in
                                    CitySelectionCard(
                                        city: city,
                                        isSelected: selectedCity == city
                                    ) {
                                        selectedCity = city
                                        loadToursWithLocation(for: city)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Mode de transport
                    VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
                        TranslatedText("Mode de transport")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: ItinerarlyTheme.Spacing.sm) {
                                ForEach(TransportMode.allCases, id: \.self) { mode in
                                    TransportModeButton(
                                        mode: mode,
                                        isSelected: transportMode == mode
                                    ) {
                                        transportMode = mode
                                        // Recharger les tours avec le nouveau mode de transport
                                        if !viewModel.tours.isEmpty {
                                            loadToursWithLocation(for: selectedCity)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Mode aléatoire pour la ville sélectionnée
                    VStack(spacing: 16) {
                        Button(action: {
                            loadRandomTourWithLocation(for: selectedCity)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("🎲")
                                            .font(.title2)
                                        
                                        Text("Mode Surprise - \(selectedCity.displayName)")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.title3)
                                    }
                                    .foregroundColor(.white)
                                    
                                    Text("Laissez-nous choisir un tour aléatoire pour vous dans cette ville !")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.orange.opacity(0.8),
                                        Color.red.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
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
        .onAppear {
            if viewModel.tours.isEmpty {
                loadToursWithLocation(for: selectedCity)
            }
        }
    }
    
    // MARK: - Location Methods
    
    private func getAddressFromCurrentLocation() {
        isGettingAddress = true
        
        guard let location = locationManager.location else {
            isGettingAddress = false
            return
        }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isGettingAddress = false
                
                if let error = error {
                    print("Erreur de géocodage: \(error.localizedDescription)")
                    return
                }
                
                if let placemark = placemarks?.first {
                    let address = [
                        placemark.thoroughfare,
                        placemark.subThoroughfare,
                        placemark.locality,
                        placemark.postalCode,
                        placemark.country
                    ].compactMap { $0 }.joined(separator: ", ")
                    
                    startAddress = address
                    confirmedAddress = address
                    isAddressConfirmed = true
                    geocodedLocation = location
                    useCurrentLocation = true
                    
                    // Recharger les tours avec la nouvelle position et l'adresse géocodée
                    loadToursWithLocation(for: selectedCity)
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
    
    // Fonction pour obtenir l'image représentative selon le titre du tour
    private func getRepresentativeImage(for tour: GuidedTour) -> String {
        let title = tour.title.lowercased()
        
        // Images spécifiques pour Paris
        if tour.city == .paris {
            if title.contains("historique") || title.contains("romantique") {
                return "https://images.unsplash.com/photo-1502602898536-47ad22581b52?w=400&h=300&fit=crop"
            } else if title.contains("art") || title.contains("culture") {
                return "https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=400&h=300&fit=crop"
            } else if title.contains("gastronomie") || title.contains("cuisine") {
                return "https://images.unsplash.com/photo-1559339352-11d035aa65de?w=400&h=300&fit=crop"
            } else if title.contains("mode") || title.contains("shopping") {
                return "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=300&fit=crop"
            } else if title.contains("secrets") || title.contains("caché") {
                return "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop"
            } else if title.contains("littéraire") || title.contains("écrivain") {
                return "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400&h=300&fit=crop"
            } else if title.contains("impressionniste") || title.contains("monet") {
                return "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=300&fit=crop"
            } else if title.contains("révolution") || title.contains("historique") {
                return "https://images.unsplash.com/photo-1502602898536-47ad22581b52?w=400&h=300&fit=crop"
            } else if title.contains("champs") || title.contains("elysées") {
                return "https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=400&h=300&fit=crop"
            } else if title.contains("marais") || title.contains("médiéval") {
                return "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop"
            } else if title.contains("montmartre") || title.contains("artiste") {
                return "https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?w=400&h=300&fit=crop"
            } else if title.contains("latin") || title.contains("université") {
                return "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400&h=300&fit=crop"
            } else if title.contains("seine") || title.contains("fluvial") {
                return "https://images.unsplash.com/photo-1502602898536-47ad22581b52?w=400&h=300&fit=crop"
            } else if title.contains("architecture") || title.contains("haussman") {
                return "https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=400&h=300&fit=crop"
            } else if title.contains("jardin") || title.contains("nature") {
                return "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=300&fit=crop"
            } else if title.contains("nuit") || title.contains("illuminé") {
                return "https://images.unsplash.com/photo-1502602898536-47ad22581b52?w=400&h=300&fit=crop"
            } else {
                // Image par défaut pour Paris
                return "https://images.unsplash.com/photo-1502602898536-47ad22581b52?w=400&h=300&fit=crop"
            }
        }
        
        // Images pour d'autres villes
        switch tour.city {
        case .lyon:
            return "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=300&fit=crop"
        case .marseille:
            return "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop"
        case .nice:
            return "https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=400&h=300&fit=crop"
        case .bordeaux:
            return "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400&h=300&fit=crop"
        case .strasbourg:
            return "https://images.unsplash.com/photo-1502602898536-47ad22581b52?w=400&h=300&fit=crop"
        case .brussels:
            return "https://images.unsplash.com/photo-1559339352-11d035aa65de?w=400&h=300&fit=crop"
        case .luxembourg:
            return "https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=400&h=300&fit=crop"
        default:
            return "https://images.unsplash.com/photo-1502602898536-47ad22581b52?w=400&h=300&fit=crop"
        }
    }
    
    var body: some View {
        Button(action: onDetailsTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Tour Image avec image représentative
                AsyncImage(url: URL(string: getRepresentativeImage(for: tour))) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [ItinerarlyTheme.ModeColors.guidedTours.opacity(0.3), ItinerarlyTheme.ModeColors.guidedTours.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        )
                }
                .frame(height: 150)
                .cornerRadius(12)
                
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
        let countries = Set(City.allCases.map { $0.country })
        return Array(countries).sorted()
    }
    
    private func getCitiesForCountry(_ country: String) -> [City] {
        return City.allCases.filter { $0.country == country }.sorted { $0.displayName < $1.displayName }
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