import SwiftUI
import MapKit
import CoreLocation
import UIKit

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct DayTripPlannerView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var viewModel = DayTripPlannerViewModel()
    @State private var showingResults = false
    @State private var numberOfLocations = 3
    @State private var startAddress = ""
    @State private var destinations: [String] = []
    @State private var transportMode: TransportMode = .driving
    @State private var useCurrentLocation = false
    @State private var isGettingAddress = false
    @State private var showingLocationAlert = false
    @State private var locationAlertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header - Design épuré
                    VStack(spacing: ItinerarlyTheme.Spacing.md) {
                        // Titre en haut à gauche
                        HStack {
                            TranslatedText("Planifier")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        // Icône centrée
                        Image(systemName: "map.fill")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(ItinerarlyTheme.ModeColors.planner)
                            .padding(.top, ItinerarlyTheme.Spacing.sm)
                        
                        // Description centrée
                        TranslatedText("Créez un itinéraire optimisé pour votre journée")
                            .font(ItinerarlyTheme.Typography.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, ItinerarlyTheme.Spacing.sm)
                    }
                    .padding(.top)
                    
                    // Configuration Card
                    VStack(spacing: ItinerarlyTheme.Spacing.lg) {
                        // Number of locations
                        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
                            Label(languageManager.translate("Nombre de lieux à visiter"), systemImage: "number.circle")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                                                    Picker("Nombre de lieux", selection: $numberOfLocations) {
                            ForEach(1...5, id: \.self) { number in
                                Text("\(number) lieu\(number > 1 ? "x" : "")")
                                    .tag(number)
                            }
                        }
                            .pickerStyle(SegmentedPickerStyle())
                            .accentColor(ItinerarlyTheme.ModeColors.planner)
                            .onChange(of: numberOfLocations) { newValue in
                                updateDestinations(count: newValue)
                            }
                        }
                        
                        Divider()
                        
                        // Start location
                        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
                            Label(languageManager.translate("Point de départ"), systemImage: "mappin.and.ellipse")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if useCurrentLocation {
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.blue)
                                    Text("Position actuelle")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Button("Modifier") {
                                        useCurrentLocation = false
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
                                        }
                                    )
                                    
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
                                        .foregroundColor(isGettingAddress ? .gray : .blue)
                                    }
                                    .disabled(isGettingAddress)
                                    

                                }
                            }
                        }
                        
                        Divider()
                        
                        // Destinations
                        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
                            Label(languageManager.translate("Lieux à visiter"), systemImage: "number.circle")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ForEach(0..<numberOfLocations, id: \.self) { index in
                                HStack {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                    
                                    LocationSearchField(
                                        text: destinationBinding(for: index),
                                        placeholder: "Adresse ou nom du lieu (ex: McDonald's, Carrefour...)",
                                        userLocation: locationManager.location,
                                        onSuggestionSelected: { mapItem in
                                            // Mettre l'adresse formatée dans le champ
                                            let formattedAddress = formatAddressFromMapItem(mapItem)
                                            destinations[index] = formattedAddress
                                        }
                                    )
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Transport mode
                        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
                            Label(languageManager.translate("Mode de transport"), systemImage: "car")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(TransportMode.allCases, id: \.self) { mode in
                                        TransportModeButton(
                                            mode: mode,
                                            isSelected: transportMode == mode
                                        ) {
                                            transportMode = mode
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(ItinerarlyTheme.Spacing.lg)
                    .background(Color(.systemBackground))
                    .cornerRadius(ItinerarlyTheme.CornerRadius.md)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Generate button avec design system
                    Button(action: generateItinerary) {
                        HStack(spacing: ItinerarlyTheme.Spacing.md) {
                            if viewModel.isLoading {
                                ItinerarlyLoadingView(mode: .planner, message: "Génération...")
                                    .scaleEffect(0.6)
                            } else {
                                Image(systemName: "route")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            
                            Text(viewModel.isLoading ? "Génération..." : "Générer l'itinéraire")
                                .font(ItinerarlyTheme.Typography.buttonText)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(ItinerarlyTheme.ModeColors.planner)
                        .foregroundColor(.white)
                        .cornerRadius(ItinerarlyTheme.CornerRadius.md)
                        .disabled(viewModel.isLoading || !isFormValid)
                        .opacity((viewModel.isLoading || !isFormValid) ? 0.6 : 1.0)
                    }
                    
                    // Loading message avec progrès détaillé
                    if viewModel.isLoading {
                        VStack(spacing: 12) {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.geocodingProgress.isEmpty ? "🗺️ Préparation de l'itinéraire..." : viewModel.geocodingProgress)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    if viewModel.totalGeocodingSteps > 0 {
                                        Text("\(viewModel.geocodingStep)/\(viewModel.totalGeocodingSteps) adresses traitées")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            
                            // Barre de progrès
                            if viewModel.totalGeocodingSteps > 0 {
                                ProgressView(value: Double(viewModel.geocodingStep), total: Double(viewModel.totalGeocodingSteps))
                                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Geocoding message
                    if viewModel.isGeocodingLocation {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("📍 Conversion de votre position en adresse...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
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
                .padding()
            }
            .navigationBarHidden(true)
            .itinerarlyBackground(mode: .planner)
            .onTapGesture {
                hideKeyboard()
            }
            .sheet(isPresented: $showingResults) {
                if let trip = viewModel.generatedTrip {
                    TripResultsView(trip: trip)
                }
            }
            .alert("Autorisation de localisation", isPresented: $showingLocationAlert) {
                Button("Annuler") { }
                Button("Ouvrir Réglages") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            } message: {
                Text(locationAlertMessage)
            }
        }
        .onReceive(viewModel.$generatedTrip) { trip in
            if trip != nil {
                showingResults = true
            }
        }
        .onReceive(locationManager.$location) { location in
            // Observer pour useCurrentLocation (mode automatique)
            if let location = location, useCurrentLocation {
                // Convertir la position GPS en adresse pour le mode automatique
                viewModel.getCurrentLocationAddress(from: location) { address in
                    DispatchQueue.main.async {
                        startAddress = address
                    }
                }
            }
            
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
                        case .failure(_):
                            // Utiliser les coordonnées en cas d'échec
                            let coordString = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
                            self.startAddress = coordString
                        }
                    }
                }
            }
        }
        .onChange(of: useCurrentLocation) { newValue in
            if newValue {
                locationManager.startUpdatingLocation()
            } else {
                locationManager.stopUpdatingLocation()
                startAddress = ""
            }
        }
        .onAppear {
            updateDestinations(count: numberOfLocations)
        }
        .onDisappear {
            if useCurrentLocation {
                locationManager.stopUpdatingLocation()
            }
        }
    }
    
    private var isFormValid: Bool {
        // Vérification du point de départ
        let hasStartLocation: Bool
        if useCurrentLocation {
            hasStartLocation = locationManager.location != nil || !startAddress.isEmpty
        } else {
            hasStartLocation = !startAddress.isEmpty
        }
        
        // Vérification des destinations (TOUTES les destinations sélectionnées doivent être remplies)
        let currentDestinations = Array(destinations.prefix(numberOfLocations))
        let nonEmptyDestinations = currentDestinations.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let hasAllDestinations = nonEmptyDestinations.count == numberOfLocations
        
        print("🎯 Debug isFormValid:")
        print("   numberOfLocations: \(numberOfLocations)")
        print("   currentDestinations: \(currentDestinations)")
        print("   nonEmptyDestinations: \(nonEmptyDestinations)")
        print("   hasAllDestinations: \(hasAllDestinations)")
        print("   hasStartLocation: \(hasStartLocation)")
        
        return hasStartLocation && hasAllDestinations
    }
    
    private func updateDestinations(count: Int) {
        // Assurer qu'on a exactement le bon nombre de destinations
        DispatchQueue.main.async {
            // Créer un nouveau tableau avec exactement le bon nombre d'éléments
            var newDestinations: [String] = []
            
            // Garder les valeurs existantes autant que possible
            for i in 0..<count {
                if i < destinations.count {
                    newDestinations.append(destinations[i])
                } else {
                    newDestinations.append("")
                }
            }
            
            destinations = newDestinations
        }
    }
    
    private func destinationBinding(for index: Int) -> Binding<String> {
        return Binding<String>(
            get: {
                guard index < destinations.count else { 
                    return "" 
                }
                return destinations[index]
            },
            set: { newValue in
                // S'assurer que le tableau a la bonne taille
                while destinations.count <= index {
                    destinations.append("")
                }
                destinations[index] = newValue
            }
        )
    }
    
    private func generateItinerary() {
        let finalStartAddress: String
        
        if useCurrentLocation {
            if let location = locationManager.location {
                // Utiliser les coordonnées GPS directement
                finalStartAddress = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
            } else {
                finalStartAddress = startAddress.isEmpty ? "Position actuelle" : startAddress
            }
        } else {
            finalStartAddress = startAddress
        }
        
        // Prendre exactement le nombre de destinations sélectionné
        let validDestinations = destinations.prefix(numberOfLocations)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // Vérifier qu'on a exactement le bon nombre de destinations
        guard validDestinations.count == numberOfLocations else {
            print("❌ Erreur: \(validDestinations.count) destinations trouvées, \(numberOfLocations) attendues")
            return
        }
        
        // Utiliser la nouvelle méthode avec géolocalisation réelle
        viewModel.planTripWithRealLocations(
            startAddress: finalStartAddress,
            destinations: validDestinations,
            transportMode: transportMode,
            numberOfLocations: numberOfLocations
        )
    }
    
    private func getAddressFromCurrentLocation() {
        // Vérifier que les services de localisation sont activés
        guard CLLocationManager.locationServicesEnabled() else {
            showLocationError("Les services de localisation sont désactivés. Veuillez les activer dans Réglages → Confidentialité et sécurité → Service de localisation.")
            return
        }
        
        // Vérifier d'abord l'autorisation
        if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
            showLocationError("Veuillez autoriser l'accès à la localisation dans les Réglages de votre iPhone.")
            return
        }
        
        // Si pas d'autorisation, la demander
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        isGettingAddress = true
        
        // Simple : demander la position directement
        locationManager.requestLocation()
        
        // Timeout de sécurité
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if self.isGettingAddress {
                self.isGettingAddress = false
                self.locationManager.stopUpdatingLocation()
                self.showLocationError("Impossible d'obtenir votre position. Vérifiez que la localisation est activée.")
            }
        }
    }
    

    
    private func showLocationError(_ message: String) {
        locationAlertMessage = message
        showingLocationAlert = true
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

}

struct TransportModeButton: View {
    let mode: TransportMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.system(size: 16, weight: .medium))
                Text(mode.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 80, height: 60)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DayTripPlannerView()
        .environmentObject(LocationManager())
} 