import SwiftUI
import MapKit
import CoreLocation

struct LocationSearchField: View {
    @Binding var text: String
    let placeholder: String
    let userLocation: CLLocation?
    let onSuggestionSelected: ((MKMapItem) -> Void)?
    
    @StateObject private var searchService = PlaceSearchService()
    @State private var showingSuggestions = false
    @State private var suggestions: [MKMapItem] = []
    @State private var searchTimer: Timer?
    @State private var isSelectingSuggestion = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Champ de texte principal
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .onChange(of: text) { newValue in
                    handleTextChange(newValue)
                }
                .onTapGesture {
                    if !text.isEmpty {
                        showingSuggestions = true
                    }
                }
            
            // Liste des suggestions avec animation
            if showingSuggestions && !suggestions.isEmpty && !isSelectingSuggestion {
                VStack(spacing: 0) {
                    ForEach(suggestions.prefix(8), id: \.self) { mapItem in
                        LocationSuggestionRow(
                            mapItem: mapItem,
                            userLocation: userLocation
                        ) {
                            selectSuggestion(mapItem)
                        }
                        
                        // Séparateur sauf pour le dernier élément
                        if mapItem != suggestions.prefix(8).last {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                .zIndex(1)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onReceive(searchService.$searchResults) { results in
            // Ne pas mettre à jour les suggestions si on est en train de sélectionner
            guard !isSelectingSuggestion else { return }
            
            self.suggestions = results
            self.showingSuggestions = !results.isEmpty && !text.isEmpty
        }
    }
    
    private func handleTextChange(_ newValue: String) {
        // Ignorer les changements de texte pendant une sélection
        if isSelectingSuggestion {
            return
        }
        
        // Annuler le timer précédent
        searchTimer?.invalidate()
        
        if newValue.isEmpty {
            withAnimation(.easeOut(duration: 0.2)) {
                showingSuggestions = false
            }
            suggestions = []
            return
        }
        
        if newValue.count >= 2 {
            // Debounce : attendre 0.3 secondes avant de lancer la recherche
            searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                searchNearbyPlaces(query: newValue)
            }
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                showingSuggestions = false
            }
        }
    }
    
    private func searchNearbyPlaces(query: String) {
        // Recherche plus précise avec adresses complètes
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest] // Prioriser les adresses
        
        // Limiter la recherche autour de la position utilisateur
        if let userLocation = userLocation {
            let region = MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: 100000, // 100km de rayon pour plus de résultats
                longitudinalMeters: 100000
            )
            request.region = region
        }
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                // Ne pas traiter les résultats si on est en train de sélectionner
                guard !self.isSelectingSuggestion else { return }
                
                if let error = error {
                    print("❌ Erreur de recherche: \(error.localizedDescription)")
                    return
                }
                
                if let mapItems = response?.mapItems {
                    print("🔍 Trouvé \(mapItems.count) résultats pour '\(query)'")
                    
                    // Filtrer et améliorer les résultats
                    let filteredItems = mapItems.compactMap { item -> MKMapItem? in
                        let placemark = item.placemark
                        
                        // Vérifier que l'adresse est complète
                        let hasCompleteAddress = placemark.thoroughfare != nil || placemark.name != nil
                        guard hasCompleteAddress else { return nil }
                        
                        return item
                    }
                    
                    // Trier par pertinence et distance
                    if let userLocation = userLocation {
                        let sortedItems = filteredItems.sorted { item1, item2 in
                            let relevance1 = self.calculateSearchRelevance(query: query, mapItem: item1)
                            let relevance2 = self.calculateSearchRelevance(query: query, mapItem: item2)
                            
                            if relevance1 != relevance2 {
                                return relevance1 > relevance2 // Plus pertinence = mieux
                            }
                            
                            // Si même pertinence, trier par distance
                            let distance1 = userLocation.distance(from: CLLocation(latitude: item1.placemark.coordinate.latitude, longitude: item1.placemark.coordinate.longitude))
                            let distance2 = userLocation.distance(from: CLLocation(latitude: item2.placemark.coordinate.latitude, longitude: item2.placemark.coordinate.longitude))
                            return distance1 < distance2
                        }
                        self.suggestions = sortedItems
                    } else {
                        // Sans position, trier seulement par pertinence
                        let sortedItems = filteredItems.sorted { item1, item2 in
                            let relevance1 = self.calculateSearchRelevance(query: query, mapItem: item1)
                            let relevance2 = self.calculateSearchRelevance(query: query, mapItem: item2)
                            return relevance1 > relevance2
                        }
                        self.suggestions = sortedItems
                    }
                    
                    print("🎯 Suggestions filtrées: \(self.suggestions.count)")
                    
                    withAnimation(.easeIn(duration: 0.2)) {
                        self.showingSuggestions = true
                    }
                }
            }
        }
    }
    
    private func calculateSearchRelevance(query: String, mapItem: MKMapItem) -> Double {
        let queryLower = query.lowercased()
        var score: Double = 0.0
        
        // Vérifier le nom (POI)
        if let name = mapItem.name?.lowercased() {
            if name.hasPrefix(queryLower) {
                score += 1.0 // Correspondance parfaite au début
            } else if name.contains(queryLower) {
                score += 0.8 // Contient la requête
            }
        }
        
        // Vérifier l'adresse
        if let thoroughfare = mapItem.placemark.thoroughfare?.lowercased() {
            if thoroughfare.hasPrefix(queryLower) {
                score += 0.9 // Rue commence par la requête
            } else if thoroughfare.contains(queryLower) {
                score += 0.6 // Rue contient la requête
            }
        }
        
        // Vérifier le numéro de rue
        if let subThoroughfare = mapItem.placemark.subThoroughfare {
            if queryLower.hasPrefix(subThoroughfare.lowercased()) {
                score += 0.7 // Numéro correspond
            }
        }
        
        // Bonus pour adresses vs POI selon la requête
        if queryLower.contains(where: { $0.isNumber }) {
            // Si la requête contient un numéro, favoriser les adresses
            if mapItem.placemark.subThoroughfare != nil {
                score += 0.3
            }
        } else {
            // Si pas de numéro, favoriser les POI
            if mapItem.name != nil && mapItem.placemark.thoroughfare == nil {
                score += 0.2
            }
        }
        
        return score
    }
    
    private func selectSuggestion(_ mapItem: MKMapItem) {
        // Marquer qu'on est en train de sélectionner pour éviter les nouvelles recherches
        isSelectingSuggestion = true
        
        // Annuler immédiatement le timer de recherche pour éviter les interférences
        searchTimer?.invalidate()
        
        // Fermer immédiatement les suggestions sans délai
        showingSuggestions = false
        suggestions = []
        
        // Ne pas mettre automatiquement le texte dans le champ
        // Laisser la vue parente décider quoi faire
        
        print("✅ Suggestion sélectionnée: '\(mapItem.name ?? "Aucun")'")
        print("   Nom du POI: \(mapItem.name ?? "Aucun")")
        print("   Adresse complète: \(mapItem.placemark.formattedAddressFromComponents)")
        print("   Coordonnées: \(mapItem.placemark.coordinate.latitude), \(mapItem.placemark.coordinate.longitude)")
        
        // Réactiver les recherches après un court délai
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isSelectingSuggestion = false
        }
        
        // Fermer le clavier
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Appeler le callback si fourni
        onSuggestionSelected?(mapItem)
    }
    
    private func formatSelectedAddress(_ mapItem: MKMapItem) -> String {
        // Toujours construire l'adresse complète pour une meilleure précision
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

struct LocationSuggestionRow: View {
    let mapItem: MKMapItem
    let userLocation: CLLocation?
    let onTap: () -> Void
    
    private var distance: String {
        guard let userLocation = userLocation else { return "" }
        
        let itemLocation = CLLocation(
            latitude: mapItem.placemark.coordinate.latitude,
            longitude: mapItem.placemark.coordinate.longitude
        )
        
        let distanceInMeters = userLocation.distance(from: itemLocation)
        
        if distanceInMeters < 1000 {
            return "\(Int(distanceInMeters))m"
        } else {
            return String(format: "%.1fkm", distanceInMeters / 1000)
        }
    }
    
    private var displayName: String {
        // Priorité : nom du POI > adresse avec numéro > nom générique
        if let name = mapItem.name, !name.isEmpty {
            return name
        } else if let number = mapItem.placemark.subThoroughfare,
                  let street = mapItem.placemark.thoroughfare {
            return "\(number) \(street)"
        } else if let street = mapItem.placemark.thoroughfare {
            return street
        } else {
            return "Adresse"
        }
    }
    
    private var fullAddress: String {
        var components: [String] = []
        
        // Numéro + rue (si pas déjà dans displayName)
        if mapItem.name != nil {
            // Si on a un nom POI, afficher l'adresse complète en dessous
            if let number = mapItem.placemark.subThoroughfare,
               let street = mapItem.placemark.thoroughfare {
                components.append("\(number) \(street)")
            } else if let street = mapItem.placemark.thoroughfare {
                components.append(street)
            }
        }
        
        // Ville
        if let city = mapItem.placemark.locality {
            components.append(city)
        }
        
        // Code postal
        if let postalCode = mapItem.placemark.postalCode {
            components.append(postalCode)
        }
        
        // Pays (si différent)
        if let country = mapItem.placemark.country, country != "France" {
            components.append(country)
        }
        
        let result = components.joined(separator: ", ")
        
        // Si aucune adresse détaillée, au moins afficher quelque chose
        if result.isEmpty {
            if let name = mapItem.name {
                return "Près de \(name)"
            } else {
                return "Coordonnées GPS"
            }
        }
        
        return result
    }
    
    private var categoryIcon: String {
        guard let category = mapItem.pointOfInterestCategory else {
            return "mappin"
        }
        
        switch category {
        case .restaurant, .bakery, .brewery, .cafe, .foodMarket:
            return "fork.knife"
        case .gasStation:
            return "fuelpump"
        case .store, .pharmacy:
            return "bag"
        case .hospital:
            return "cross"
        case .school, .university:
            return "book"
        case .bank, .atm:
            return "banknote"
        case .museum, .library:
            return "building.columns"
        case .park:
            return "leaf"
        case .hotel:
            return "bed.double"
        default:
            return "mappin"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icône de catégorie
                Image(systemName: categoryIcon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    // Nom du lieu ou numéro + rue
                    Text(displayName)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Adresse complète avec ville et code postal
                    Text(fullAddress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Distance
                if !distance.isEmpty {
                    Text(distance)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.clear)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack {
        LocationSearchField(
            text: .constant("McDonald"),
            placeholder: "Rechercher un lieu...",
            userLocation: CLLocation(latitude: 48.8566, longitude: 2.3522),
            onSuggestionSelected: { mapItem in
                print("Suggestion sélectionnée: \(mapItem.name ?? "Aucun")")
            }
        )
        
        Spacer()
    }
    .padding()
} 