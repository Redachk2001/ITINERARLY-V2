import SwiftUI
import MapKit
import CoreLocation
import UIKit

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Sous‑vue factorisée pour réduire la complexité du corps principal
private struct StartAddressPicker: View {
    @Binding var startAddress: String
    let userLocation: CLLocation?
    @Binding var isGettingAddress: Bool
    let onUseCurrentLocation: () -> Void
    let onPickOnMap: () -> Void
    let onBeginEditing: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            LocationSearchField(
                text: $startAddress,
                placeholder: "Tapez votre adresse de départ...",
                userLocation: userLocation,
                onSuggestionSelected: { mapItem in
                    startAddress = formatAddress(mapItem)
                }
            )
            .overlay(alignment: .trailing) {
                Button(action: onPickOnMap) {
                    Image(systemName: "mappin.and.ellipse")
                        .padding(8)
                }
            }
            .simultaneousGesture(TapGesture().onEnded { onBeginEditing() })

            HStack {
                Button(action: onUseCurrentLocation) {
                    HStack(spacing: 4) {
                        if isGettingAddress {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "location.fill")
                        }
                        Text(isGettingAddress ? "Récupération de l'adresse..." : "Utiliser ma position")
                    }
                    .font(.caption)
                    .foregroundColor(isGettingAddress ? .gray : .blue)
                }
                Spacer(minLength: 12)
                Button(action: onPickOnMap) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                        Text("Choisir sur la carte")
                    }
                    .font(.caption)
                }
            }
        }
    }

    // Formateur d'adresse local (évite la dépendance externe)
    private func formatAddress(_ mapItem: MKMapItem) -> String {
        var components: [String] = []
        if let name = mapItem.name, !name.isEmpty { components.append(name) }
        var addressComponents: [String] = []
        if let number = mapItem.placemark.subThoroughfare { addressComponents.append(number) }
        if let street = mapItem.placemark.thoroughfare { addressComponents.append(street) }
        if let city = mapItem.placemark.locality { addressComponents.append(city) }
        if let postalCode = mapItem.placemark.postalCode { addressComponents.append(postalCode) }
        if !addressComponents.isEmpty { components.append(addressComponents.joined(separator: ", ")) }
        return components.joined(separator: ", ")
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
    @State private var wantsToUseCurrentLocation = false
    @State private var showingMapPicker = false
    @StateObject private var multiGeocoder = MultiAPIGeocodingService()
    
    var body: some View {
        NavigationView {
            ScrollView { content }
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
        }
        .sheet(isPresented: $showingMapPicker) { mapPickerSheet }
        .onReceive(viewModel.$generatedTrip) { trip in
            if trip != nil {
                showingResults = true
            }
        }
        .onReceive(locationManager.$location) { location in
            // Dès qu'on reçoit quelque chose, marquer l'utilisation
            if location != nil { useCurrentLocation = true }
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
                // Remplir immédiatement avec les coordonnées
                let coordString = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
                self.startAddress = coordString

                locationManager.reverseGeocode(location) { result in
                    DispatchQueue.main.async {
                        self.isGettingAddress = false
                        self.locationManager.stopUpdatingLocation()
                        
                        switch result {
                        case .success(let address):
                            self.startAddress = address
                        case .failure(_):
                            break // on garde les coordonnées déjà mises
                        }
                    }
                }
            }
        }
        .onChange(of: useCurrentLocation) { newValue in
            guard FeatureFlags.enableUseCurrentLocation else { return }
            if newValue {
                locationManager.startUpdatingLocation()
            } else {
                locationManager.stopUpdatingLocation()
                startAddress = ""
            }
        }
        .onChange(of: locationManager.authorizationStatus) { newStatus in
            guard FeatureFlags.enableUseCurrentLocation else { return }
            // Si l'utilisateur a cliqué et vient d'autoriser, lancer l'obtention
            if wantsToUseCurrentLocation,
               (newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways) {
                isGettingAddress = true
                locationManager.startUpdatingLocation()
            }
            // Si refusé, lever l'alerte et réactiver le bouton
            if wantsToUseCurrentLocation, (newStatus == .denied || newStatus == .restricted) {
                wantsToUseCurrentLocation = false
                isGettingAddress = false
                // Autorisation refusée - ne rien faire
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
    
    // MARK: - Sous-vues factorisées
    private var content: some View {
        VStack(spacing: 20) {
            headerSection
            configCard
            generateButton
            loadingSection
            geocodingSection
            if let errorMessage = viewModel.errorMessage { errorSection(errorMessage) }
            Spacer(minLength: 20)
        }
        .padding()
    }

    private var headerSection: some View {
        VStack(spacing: ItinerarlyTheme.Spacing.md) {
            HStack {
                TranslatedText("Planifier")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                Spacer()
            }
            Image(systemName: "map.fill")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(ItinerarlyTheme.ModeColors.planner)
                .padding(.top, ItinerarlyTheme.Spacing.sm)
            TranslatedText("Créez un itinéraire optimisé pour votre journée")
                .font(ItinerarlyTheme.Typography.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, ItinerarlyTheme.Spacing.sm)
        }
        .padding(.top)
    }

    private var configCard: some View {
        VStack(spacing: ItinerarlyTheme.Spacing.md) {
            numberOfLocationsSection
            Divider()
            startLocationSection
            Divider()
            destinationsSection
            Divider()
            transportModeSection
        }
        .padding(ItinerarlyTheme.Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(ItinerarlyTheme.CornerRadius.sm)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    private var numberOfLocationsSection: some View {
        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
            Label(languageManager.translate("Nombre de lieux à visiter"), systemImage: "number.circle")
                .font(.headline)
                .foregroundColor(.primary)
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { number in
                    NumberOfLocationsButton(
                        number: number,
                        isSelected: numberOfLocations == number
                    ) {
                        numberOfLocations = number
                        updateDestinations(count: number)
                    }
                }
            }
        }
    }

    private var startLocationSection: some View {
        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
            Label(languageManager.translate("Point de départ"), systemImage: "mappin.and.ellipse")
                .font(.headline)
                .foregroundColor(.primary)
            StartAddressPicker(
                startAddress: $startAddress,
                userLocation: locationManager.location,
                isGettingAddress: $isGettingAddress,
                onUseCurrentLocation: { getAddressFromCurrentLocation() },
                onPickOnMap: { showingMapPicker = true },
                onBeginEditing: { if useCurrentLocation { useCurrentLocation = false } }
            )
        }
    }

    private var destinationsSection: some View {
        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
            Label(languageManager.translate("Lieux à visiter"), systemImage: "number.circle")
                .font(.headline)
                .foregroundColor(.primary)
            ForEach(0..<numberOfLocations, id: \.self) { index in
                HStack(spacing: 8) {
                    Text("\(index + 1)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.blue)
                        .clipShape(Circle())
                    
                    LocationSearchField(
                        text: destinationBinding(for: index),
                        placeholder: "Lieu \(index + 1)",
                        userLocation: locationManager.location,
                        onSuggestionSelected: { mapItem in
                            let formattedAddress = formatAddressFromMapItem(mapItem)
                            destinations[index] = formattedAddress
                        }
                    )
                    .frame(height: 36)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var transportModeSection: some View {
        VStack(alignment: .leading, spacing: ItinerarlyTheme.Spacing.md) {
            Label(languageManager.translate("Mode de transport"), systemImage: "car")
                .font(.headline)
                .foregroundColor(.primary)
            HStack(spacing: 6) {
                ForEach(TransportMode.allCases, id: \.self) { mode in
                    TransportModeButton(
                        mode: mode,
                        isSelected: transportMode == mode
                    ) { transportMode = mode }
                }
            }
        }
    }

    private var generateButton: some View {
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
    }

    private var loadingSection: some View {
        Group {
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
                    
                    if viewModel.totalGeocodingSteps > 0 {
                        ProgressView(value: Double(viewModel.geocodingStep), total: Double(viewModel.totalGeocodingSteps))
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    private var geocodingSection: some View {
        Group {
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
        }
    }

    private func errorSection(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.red)
            .padding(.horizontal)
            .multilineTextAlignment(.center)
    }

    private var mapPickerSheet: some View {
        MapPickerView(
            cityName: mapPickerCityName,
            initialCoordinate: locationManager.location?.coordinate,
            onPicked: { loc, address in
                self.startAddress = address
                self.useCurrentLocation = false
                self.wantsToUseCurrentLocation = false
                // Ouvrir Apple Plans à l’emplacement choisi
                locationManager.openInAppleMaps(coordinate: loc.coordinate, label: address)
            }
        )
    }
    
    // Heuristique simple pour centrer la carte: utiliser la ville déduite de l'adresse de départ ou un fallback
    private var mapPickerCityName: String {
        let lower = startAddress.lowercased()
        // Si l’utilisateur a déjà saisi une adresse avec une ville, réutiliser
        let knownCities = [
            "berlin", "bruxelles", "brussels", "nice", "paris", "marseille", "lyon", "bordeaux", "casablanca", "luxembourg"
        ]
        if let match = knownCities.first(where: { lower.contains($0) }) {
            return match.capitalized
        }
        // Sinon, fallback générique
        return "Paris"
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
        print("🎯 updateDestinations: nouveau count = \(count), destinations = \(destinations)")
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
        guard FeatureFlags.enableUseCurrentLocation else { return }
        wantsToUseCurrentLocation = true
        isGettingAddress = true
        useCurrentLocation = true
        // Pré-remplir immédiatement avec la dernière coord si disponible
        if let last = locationManager.location {
            let coordString = String(format: "%.6f, %.6f", last.coordinate.latitude, last.coordinate.longitude)
            self.startAddress = coordString
            // Ouvrir Apple Plans sur la position actuelle
            locationManager.openAppleMapsAtCurrentLocation()
        } else if startAddress.trimmingCharacters(in: .whitespaces).isEmpty {
            self.startAddress = "Votre position (en cours)"
        }
        
        // Demander/rafraîchir l'autorisation (sans lecture synchrone du statut)
        locationManager.requestWhenInUseAuthorization()
        
        // Lancer immédiatement la récupération de position
        locationManager.startUpdatingLocation()
        locationManager.requestLocation()
        
        // Sécurité: si aucune position n'arrive
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if self.isGettingAddress {
                self.isGettingAddress = false
                self.wantsToUseCurrentLocation = false
                self.locationManager.stopUpdatingLocation()
                // Dernier recours: tenter un géocodage multi-API sur la dernière coord connue
                if let last = self.locationManager.location {
                    self.locationManager.reverseGeocode(last) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let address):
                                self.startAddress = address
                                self.locationManager.openAppleMapsAtCurrentLocation()
                            case .failure(_):
                                let coordString = String(format: "%.6f, %.6f", last.coordinate.latitude, last.coordinate.longitude)
                                self.startAddress = coordString
                                self.locationManager.openAppleMapsAtCurrentLocation()
                            }
                        }
                    }
                } else {
                    // En cas d'échec, utiliser des coordonnées par défaut
                    self.startAddress = "Position par défaut"
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

}

struct TransportModeButton: View {
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
            }
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NumberOfLocationsButton: View {
    let number: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number == 1 ? "1 lieu" : "\(number) lieux")
                .font(.caption2)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(isSelected ? ItinerarlyTheme.ModeColors.planner : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DayTripPlannerView()
        .environmentObject(LocationManager())
} 