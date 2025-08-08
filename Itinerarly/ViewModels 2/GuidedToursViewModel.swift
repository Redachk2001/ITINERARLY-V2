import Foundation
import Combine
import CoreLocation

class GuidedToursViewModel: ObservableObject {
    @Published var tours: [GuidedTour] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentCity: City = .paris
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var isLocationOptimized = false
    @Published var isRandomMode = false
    @Published var startAddress: String?
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadTours(for city: City) {
        // Permettre le rechargement si on change de ville, si tours est vide, ou si on sort du mode aléatoire
        guard currentCity != city || tours.isEmpty || isRandomMode else { return }
        
        currentCity = city
        isLoading = true
        errorMessage = nil
        isRandomMode = false
        
        // Pour la démo, utiliser directement les données mock
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loadMockTours(for: city)
            self.optimizeToursForUserLocation()
            self.isLoading = false
        }
    }
    

    
    // MARK: - Optimisation des tours pour la position utilisateur
    func optimizeToursForUserLocation() {
        guard let userLocation = userLocation else {
            print("❌ Pas de position utilisateur disponible")
            return
        }
        
        print("🗺️ Optimisation des tours pour la position: \(userLocation.latitude), \(userLocation.longitude)")
        
        // Sauvegarder l'ordre original des tours
        let originalTours = tours
        
        // Optimiser chaque tour en commençant par le point de départ de l'utilisateur
        tours = originalTours.map { tour in
            let optimizedTour = tour
            
            // Créer un arrêt de départ avec la position de l'utilisateur
            let startLocation = Location(
                id: "user_start_location",
                name: startAddress ?? "Votre point de départ",
                address: startAddress ?? "Votre position actuelle",
                latitude: userLocation.latitude,
                longitude: userLocation.longitude,
                category: .historical,
                description: "Point de départ de votre tour guidé",
                imageURL: nil,
                rating: 0.0,
                openingHours: "24h/24",
                recommendedDuration: TimeInterval(300), // 5 minutes
                visitTips: ["Point de départ de votre tour"]
            )
            
            // Optimiser l'ordre des arrêts en utilisant l'algorithme du plus proche voisin
            // Le point de départ sera ajouté automatiquement par l'algorithme
            let optimizedStops = optimizeStopsOrder(tour.stops, startFromUserLocation: true, userStartLocation: startLocation)
            
            // Créer un nouveau tour avec les arrêts optimisés
            let totalDuration = optimizedStops.reduce(0) { $0 + $1.visitDuration }
            
            return GuidedTour(
                id: optimizedTour.id,
                title: optimizedTour.title,
                city: optimizedTour.city,
                description: optimizedTour.description,
                duration: totalDuration,
                difficulty: optimizedTour.difficulty,
                stops: optimizedStops,
                imageURL: optimizedTour.imageURL,
                rating: optimizedTour.rating,
                price: optimizedTour.price,
                optimizedStops: optimizedStops
            )
        }
        
        print("✅ Tours optimisés: \(tours.count) tours")
        for (index, tour) in tours.enumerated() {
            print("   Tour \(index + 1): \(tour.title)")
            print("     Arrêts optimisés: \(tour.stops.map { $0.location.name })")
        }
        
        isLocationOptimized = true
    }
    
    // MARK: - Algorithme d'optimisation des arrêts
    private func optimizeStopsOrder(_ stops: [TourStop], startFromUserLocation: Bool, userStartLocation: Location? = nil) -> [TourStop] {
        guard stops.count > 0 else { return stops }
        
        var optimizedStops: [TourStop] = []
        var remainingStops = stops
        
        // Ajouter le point de départ de l'utilisateur au début si fourni
        if startFromUserLocation, let _ = userLocation, let startLocation = userStartLocation {
            let startStop = TourStop(
                id: "user_start_stop",
                location: startLocation,
                order: 0,
                audioGuideText: "Bienvenue ! Votre tour guidé commence ici, depuis votre point de départ.",
                audioGuideURL: nil,
                visitDuration: TimeInterval(300),
                tips: "Préparez-vous pour une belle découverte !"
            )
            optimizedStops.append(startStop)
        }
        
        var currentLocation = CLLocation(latitude: userLocation?.latitude ?? 0, longitude: userLocation?.longitude ?? 0)
        
        // Algorithme du plus proche voisin
        while !remainingStops.isEmpty {
            var nearestStop: TourStop?
            var shortestDistance = Double.infinity
            var nearestIndex = 0
            
            for (index, stop) in remainingStops.enumerated() {
                let stopLocation = CLLocation(latitude: stop.location.latitude, longitude: stop.location.longitude)
                let distance = currentLocation.distance(from: stopLocation)
                
                if distance < shortestDistance {
                    shortestDistance = distance
                    nearestStop = stop
                    nearestIndex = index
                }
            }
            
            if let nearest = nearestStop {
                optimizedStops.append(nearest)
                remainingStops.remove(at: nearestIndex)
                currentLocation = CLLocation(latitude: nearest.location.latitude, longitude: nearest.location.longitude)
            }
        }
        
        // Mettre à jour l'ordre des arrêts
        for (index, stop) in optimizedStops.enumerated() {
            var updatedStop = stop
            updatedStop.order = index
            optimizedStops[index] = updatedStop
        }
        
        return optimizedStops
    }
    
    // MARK: - Mise à jour de la localisation utilisateur
    func updateUserLocation(_ location: CLLocationCoordinate2D) {
        userLocation = location
        optimizeToursForUserLocation()
    }
    
    // MARK: - Mode aléatoire
    func loadRandomTour(for city: City) {
        currentCity = city
        isLoading = true
        errorMessage = nil
        isRandomMode = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loadMockTours(for: city)
            let randomTour = self.tours.randomElement()
            if let tour = randomTour {
                self.tours = [tour]
            }
            self.optimizeToursForUserLocation()
            self.isLoading = false
        }
    }
    
    // MARK: - Chargement avec position de départ
    func loadToursWithLocation(for city: City, startLocation: CLLocation?, startAddress: String? = nil) {
        currentCity = city
        isLoading = true
        errorMessage = nil
        isRandomMode = false
        
        // Mettre à jour la position utilisateur si fournie
        if let location = startLocation {
            userLocation = location.coordinate
            print("📍 Position utilisateur mise à jour: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            isLocationOptimized = true
        } else {
            print("⚠️ Aucune position utilisateur fournie")
            isLocationOptimized = false
        }
        
        // Mettre à jour l'adresse du point de départ
        self.startAddress = startAddress
        if let address = startAddress {
            print("📍 Adresse de départ: \(address)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.loadMockTours(for: city)
            self.optimizeToursForUserLocation()
            self.isLoading = false
        }
    }
    
    func loadRandomTourWithLocation(for city: City, startLocation: CLLocation?, startAddress: String? = nil) {
        currentCity = city
        isLoading = true
        errorMessage = nil
        isRandomMode = true
        
        // Mettre à jour la position utilisateur si fournie
        if let location = startLocation {
            userLocation = location.coordinate
            print("📍 Position utilisateur (mode aléatoire): \(location.coordinate.latitude), \(location.coordinate.longitude)")
            isLocationOptimized = true
        } else {
            print("⚠️ Aucune position utilisateur fournie (mode aléatoire)")
            isLocationOptimized = false
        }
        
        // Mettre à jour l'adresse du point de départ
        self.startAddress = startAddress
        if let address = startAddress {
            print("📍 Adresse de départ (mode aléatoire): \(address)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.loadMockTours(for: city)
            let randomTour = self.tours.randomElement()
            if let tour = randomTour {
                self.tours = [tour]
            }
            self.optimizeToursForUserLocation()
            self.isLoading = false
        }
    }
    
    // MARK: - Obtenir tous les tours pour une ville
    private func getAllToursForCity(_ city: City) -> [GuidedTour] {
        // Générer des tours pour toutes les villes
        return createMockToursForCity(city)
    }
    
    private func loadMockTours(for city: City) {
        // Générer des tours pour toutes les villes
        tours = createMockToursForCity(city)
        errorMessage = nil
    }
    
    // MARK: - Créer des tours génériques pour une ville
    private func createMockToursForCity(_ city: City) -> [GuidedTour] {
        let tourTitles = getTourTitles(for: city)
        
        return (0..<3).map { tourIndex in
            let stopCount = Int.random(in: 4...8)
            let mockStops = (1...stopCount).map { index in
                let location = createGenericLocation(for: city, index: index)
                let audioGuide = getAudioGuideText(for: location.name, in: city, index: index)
                return TourStop(
                    id: "\(city.rawValue)_tour_\(tourIndex + 1)_stop_\(index)",
                    location: location,
                    order: index,
                    audioGuideText: audioGuide,
                    audioGuideURL: nil,
                    visitDuration: TimeInterval(600 + Int.random(in: 0...600)), // 10-20 minutes
                    tips: "Conseil : Prenez le temps d'admirer les détails architecturaux."
                )
            }
            
            let tourTitle = tourIndex < tourTitles.count ? tourTitles[tourIndex] : "Découverte de \(city.displayName)"
            
            return GuidedTour(
                id: "\(city.rawValue)_tour_\(tourIndex + 1)",
                title: tourTitle,
                city: city,
                description: "Découvrez les merveilles de \(city.displayName) avec ce tour guidé immersif.",
                duration: TimeInterval(stopCount * 900), // 15 min par arrêt
                difficulty: TourDifficulty.allCases.randomElement() ?? .easy,
                stops: mockStops,
                imageURL: nil,
                rating: Double.random(in: 4.0...5.0),
                price: Bool.random() ? Double.random(in: 0...25) : nil
            )
        }
    }
    
    // MARK: - Fonctions utilitaires pour adresses réelles
    private func getRealAddress(for city: City, index: Int) -> String {
        switch city {
        // FRANCE
        case .paris:
            let addresses = [
                "Champ de Mars, 5 Avenue Anatole France, 75007 Paris, France", // Tour Eiffel - Monument emblématique
                "Musée du Louvre, Rue de Rivoli, 75001 Paris, France", // Musée du Louvre - Musée d'art
                "Arc de Triomphe, Place Charles de Gaulle, 75008 Paris, France", // Arc de Triomphe - Monument historique
                "Cathédrale Notre-Dame, 6 Parvis Notre-Dame - Pl. Jean-Paul II, 75004 Paris, France", // Cathédrale Notre-Dame - Cathédrale gothique
                "Basilique du Sacré-Cœur, 35 Rue du Chevalier de la Barre, 75018 Paris, France", // Basilique du Sacré-Cœur - Basilique
                "Place du Tertre, 75018 Paris, France", // Place du Tertre - Place des artistes
                "Moulin Rouge, 82 Boulevard de Clichy, 75018 Paris, France", // Moulin Rouge - Cabaret célèbre
                "Champs-Élysées, 1 Avenue des Champs-Élysées, 75008 Paris, France", // Champs-Élysées - Avenue prestigieuse
                "Place de la Concorde, 75001 Paris, France", // Place de la Concorde - Place monumentale
                "Place Vendôme, 75001 Paris, France" // Place Vendôme - Place de luxe
            ]
            return addresses[index % addresses.count]
        case .lyon:
            let addresses = [
                "Place Bellecour, 69002 Lyon, France", // Place Bellecour - Place centrale
                "Basilique Notre-Dame de Fourvière, 8 Place de Fourvière, 69005 Lyon, France", // Basilique Notre-Dame de Fourvière - Basilique
                "Vieux Lyon, 69005 Lyon, France", // Vieux Lyon - Quartier historique
                "Place des Terreaux, 69001 Lyon, France", // Place des Terreaux - Place historique
                "Parc de la Tête d'Or, 69006 Lyon, France", // Parc de la Tête d'Or - Parc urbain
                "Place Saint-Jean, 69005 Lyon, France", // Cathédrale Saint-Jean - Cathédrale
                "Musée des Confluences, 86 Quai Perrache, 69002 Lyon, France", // Musée des Confluences - Musée des sciences
                "Théâtre des Célestins, 4 Rue Charles Dullin, 69002 Lyon, France", // Théâtre des Célestins - Théâtre
                "Place des Jacobins, 69002 Lyon, France", // Place des Jacobins - Place publique
                "Rue de la République, 69002 Lyon, France" // Rue de la République - Rue commerçante
            ]
            return addresses[index % addresses.count]
        case .marseille:
            let addresses = [
                "Rue Fort du Sanctuaire, 13006 Marseille, France", // Basilique Notre-Dame de la Garde - Basilique
                "Vieux-Port, 13001 Marseille, France", // Vieux-Port - Port historique
                "MuCEM, 1 Esplanade du J4, 13002 Marseille, France", // MuCEM - Musée des civilisations
                "Palais Longchamp, Boulevard du Jardin Zoologique, 13004 Marseille, France", // Palais Longchamp - Palais et musée
                "Île d'If, 13007 Marseille, France", // Château d'If - Forteresse historique
                "Cours Julien, 13006 Marseille, France", // Cours Julien - Quartier branché
                "Parc Borély, Avenue du Prado, 13008 Marseille, France", // Parc Borély - Parc public
                "Cathédrale de la Major, Place de la Major, 13002 Marseille, France", // Cathédrale de la Major - Cathédrale
                "Fort Saint-Jean, Esplanade de la Tourette, 13002 Marseille, France", // Fort Saint-Jean - Fort historique
                "Place Castellane, 13006 Marseille, France" // Place Castellane - Place centrale
            ]
            return addresses[index % addresses.count]
        case .toulouse:
            let addresses = [
                "Place du Capitole, 31000 Toulouse, France", // Place du Capitole - Place centrale
                "Basilique Saint-Sernin, Place Saint-Sernin, 31000 Toulouse, France", // Basilique Saint-Sernin - Basilique romane
                "Cathédrale Saint-Étienne, Place Saint-Étienne, 31000 Toulouse, France", // Cathédrale Saint-Étienne - Cathédrale
                "Canal du Midi, 31000 Toulouse, France", // Canal du Midi - Canal historique
                "Place Wilson, 31000 Toulouse, France", // Place Wilson - Place publique
                "Musée des Augustins, 21 Rue de Metz, 31000 Toulouse, France", // Musée des Augustins - Musée d'art
                "Jardin des Plantes, Allée Frédéric Mistral, 31000 Toulouse, France", // Jardin des Plantes - Jardin botanique
                "Place Saint-Pierre, 31000 Toulouse, France", // Place Saint-Pierre - Place historique
                "Place d'Assézat, 31000 Toulouse, France", // Hôtel d'Assézat - Hôtel particulier
                "Cité de l'Espace, Avenue Jean Gonord, 31500 Toulouse, France" // Cité de l'Espace - Parc d'attractions spatial
            ]
            return addresses[index % addresses.count]
        case .nice:
            let addresses = [
                "Promenade des Anglais, 06000 Nice, France", // Promenade des Anglais - Promenade maritime
                "Vieille Ville, 06300 Nice, France", // Vieille Ville - Quartier historique
                "Colline du Château, 06300 Nice, France", // Colline du Château - Parc et vue
                "Place Masséna, 06000 Nice, France", // Place Masséna - Place centrale
                "Cours Saleya, 06300 Nice, France", // Cours Saleya - Marché aux fleurs
                "Musée Matisse, 164 Avenue des Arènes de Cimiez, 06000 Nice, France", // Musée Matisse - Musée d'art
                "Cathédrale Sainte-Réparate, Place Rossetti, 06300 Nice, France", // Cathédrale Sainte-Réparate - Cathédrale
                "Parc Phoenix, 405 Promenade des Anglais, 06200 Nice, France", // Parc Phoenix - Parc zoologique
                "Monastère de Cimiez, Place du Monastère, 06000 Nice, France", // Monastère de Cimiez - Monastère
                "Port de Nice, 06300 Nice, France" // Port de Nice - Port de plaisance
            ]
            return addresses[index % addresses.count]
        case .nantes:
            let addresses = [
                "4 Place Marc Elder, 44000 Nantes, France", // Château des Ducs de Bretagne - Château historique
                "Place Saint-Pierre, 44000 Nantes, France", // Cathédrale Saint-Pierre-et-Saint-Paul - Cathédrale
                "Île de Nantes, 44000 Nantes, France", // Île de Nantes - Quartier moderne
                "Place Graslin, 44000 Nantes, France", // Place Graslin - Place historique
                "Rue de la Fosse, 44000 Nantes, France", // Passage Pommeraye - Passage couvert
                "Rue Stanislas Baudry, 44000 Nantes, France", // Jardin des Plantes - Jardin botanique
                "10 Rue Georges Clemenceau, 44000 Nantes, France", // Musée d'Arts de Nantes - Musée d'art
                "Quartier Bouffay, 44000 Nantes, France", // Quartier Bouffay - Quartier médiéval
                "Place Royale, 44000 Nantes, France", // Place Royale - Place monumentale
                "Parc des Chantiers, 44200 Nantes, France" // Les Machines de l'Île - Parc d'attractions
            ]
            return addresses[index % addresses.count]
        case .strasbourg:
            let addresses = [
                "Place de la Cathédrale, 67000 Strasbourg, France", // Cathédrale Notre-Dame - Cathédrale gothique
                "Petite France, 67000 Strasbourg, France", // Petite France - Quartier pittoresque
                "Place Kléber, 67000 Strasbourg, France", // Place Kléber - Place centrale
                "2 Place du Château, 67000 Strasbourg, France", // Palais Rohan - Palais épiscopal
                "Place Gutenberg, 67000 Strasbourg, France", // Place Gutenberg - Place historique
                "Avenue de l'Orangerie, 67000 Strasbourg, France", // Parc de l'Orangerie - Parc public
                "Quartier européen, 67000 Strasbourg, France", // Quartier européen - Institutions européennes
                "Place Broglie, 67000 Strasbourg, France", // Place Broglie - Place historique
                "23-25 Quai Saint-Nicolas, 67000 Strasbourg, France", // Musée Alsacien - Musée ethnographique
                "Ponts Couverts, 67000 Strasbourg, France" // Ponts Couverts - Ponts médiévaux
            ]
            return addresses[index % addresses.count]
        case .montpellier:
            let addresses = [
                "Place de la Comédie, 34000 Montpellier, France", // Place de la Comédie - Place centrale
                "Place Saint-Pierre, 34000 Montpellier, France", // Cathédrale Saint-Pierre - Cathédrale
                "Place du Peyrou, 34000 Montpellier, France", // Arc de Triomphe - Monument historique
                "Place du Peyrou, 34000 Montpellier, France", // Place du Peyrou - Place monumentale
                "Boulevard Henri IV, 34000 Montpellier, France", // Jardin des Plantes - Jardin botanique
                "Quartier Antigone, 34000 Montpellier, France", // Quartier Antigone - Quartier moderne
                "39 Boulevard Bonne Nouvelle, 34000 Montpellier, France", // Musée Fabre - Musée d'art
                "Place Jean-Jaurès, 34000 Montpellier, France", // Place Jean-Jaurès - Place publique
                "Port Marianne, 34000 Montpellier, France", // Port Marianne - Port de plaisance
                "1744 Avenue Albert Einstein, 34000 Montpellier, France" // Château de Flaugergues - Château
            ]
            return addresses[index % addresses.count]
        case .bordeaux:
            let addresses = [
                "Place de la Bourse, 33000 Bordeaux, France", // Place de la Bourse - Place monumentale
                "Place Pey-Berland, 33000 Bordeaux, France", // Cathédrale Saint-André - Cathédrale
                "Place des Quinconces, 33000 Bordeaux, France", // Place des Quinconces - Place publique
                "Rue Sainte-Catherine, 33000 Bordeaux, France", // Rue Sainte-Catherine - Rue commerçante
                "Port de la Lune, 33000 Bordeaux, France", // Port de la Lune - Port historique
                "Place du Parlement, 33000 Bordeaux, France", // Place du Parlement - Place historique
                "20 Cours Pasteur, 33000 Bordeaux, France", // Musée d'Aquitaine - Musée d'histoire
                "Cours de Verdun, 33000 Bordeaux, France", // Jardin Public - Parc public
                "Place Canteloup, 33000 Bordeaux, France", // Basilique Saint-Michel - Basilique
                "134 Quai de Bacalan, 33300 Bordeaux, France" // Cité du Vin - Musée du vin
            ]
            return addresses[index % addresses.count]

        case .reims:
            let addresses = [
                "Place du Cardinal Luçon, 51100 Reims, France", // Cathédrale Notre-Dame - Cathédrale gothique
                "2 Place du Cardinal Luçon, 51100 Reims, France", // Palais du Tau - Palais épiscopal
                "Place Saint-Remi, 51100 Reims, France", // Basilique Saint-Remi - Basilique
                "Place Drouet d'Erlon, 51100 Reims, France", // Place Drouet d'Erlon - Place centrale
                "Porte de Mars, 51100 Reims, France", // Porte de Mars - Porte romaine
                "8 Rue Chanzy, 51100 Reims, France", // Musée des Beaux-Arts - Musée d'art
                "Place Royale, 51100 Reims, France", // Place Royale - Place historique
                "Cryptoportique, 51100 Reims, France", // Cryptoportique - Vestige romain
                "Hôtel de Ville, 51100 Reims, France", // Hôtel de Ville - Mairie
                "Parc de Champagne, 51100 Reims, France" // Parc de Champagne - Parc public
            ]
            return addresses[index % addresses.count]
        case .saintEtienne:
            let addresses = [
                "Place du Peuple, 42000 Saint-Étienne, France", // Place du Peuple - Place centrale
                "Place Saint-Charles, 42000 Saint-Étienne, France", // Cathédrale Saint-Charles - Cathédrale
                "Rue Fernand Léger, 42000 Saint-Étienne, France", // Musée d'Art Moderne - Musée d'art
                "Place Jean-Jaurès, 42000 Saint-Étienne, France", // Place Jean-Jaurès - Place publique
                "Rue de la République, 42000 Saint-Étienne, France", // Rue de la République - Rue commerçante
                "Parc de l'Europe, 42000 Saint-Étienne, France", // Parc de l'Europe - Parc public
                "Hôtel de Ville, 42000 Saint-Étienne, France", // Hôtel de Ville - Mairie
                "Place Dorian, 42000 Saint-Étienne, France", // Place Dorian - Place historique
                "3 Boulevard Maréchal Franchet d'Esperey, 42000 Saint-Étienne, France", // Musée de la Mine - Musée
                "3 Rue Javelin Pagnon, 42000 Saint-Étienne, France" // Cité du Design - Musée du design
            ]
            return addresses[index % addresses.count]
        case .toulon:
            let addresses = [
                "Port de Toulon, 83000 Toulon, France", // Port de Toulon - Port militaire
                "Place de la Liberté, 83000 Toulon, France", // Place de la Liberté - Place centrale
                "Place de la Cathédrale, 83000 Toulon, France", // Cathédrale Sainte-Marie-Majeure - Cathédrale
                "Place Monsenergue, 83000 Toulon, France", // Musée de la Marine - Musée maritime
                "Place Puget, 83000 Toulon, France", // Place Puget - Place historique
                "Mont Faron, 83000 Toulon, France", // Mont Faron - Montagne et téléphérique
                "Place d'Armes, 83000 Toulon, France", // Place d'Armes - Place publique
                "Rue d'Alger, 83000 Toulon, France", // Rue d'Alger - Rue commerçante
                "Jardin Alexandre Ier, 83000 Toulon, France", // Jardin Alexandre Ier - Jardin public
                "Place Victor Hugo, 83000 Toulon, France" // Opéra de Toulon - Opéra
            ]
            return addresses[index % addresses.count]
        case .leHavre:
            let addresses = [
                "Port du Havre, 76600 Le Havre, France", // Port du Havre - Port maritime
                "Place de l'Hôtel de Ville, 76600 Le Havre, France", // Place de l'Hôtel de Ville - Place centrale
                "Boulevard François Ier, 76600 Le Havre, France", // Église Saint-Joseph - Église moderne
                "2 Boulevard Clemenceau, 76600 Le Havre, France", // Musée d'Art Moderne André Malraux - Musée d'art
                "Place du Volcan, 76600 Le Havre, France", // Volcan - Centre culturel
                "Cathédrale Notre-Dame, 76600 Le Havre, France", // Cathédrale Notre-Dame - Cathédrale
                "Quartier Saint-François, 76600 Le Havre, France", // Quartier Saint-François - Quartier historique
                "Rue du Commandant Roque, 76600 Le Havre, France", // Jardin Suspendu - Jardin public
                "Plage du Havre, 76600 Le Havre, France", // Plage du Havre - Plage
                "Rue de Paris, 76600 Le Havre, France" // Rue de Paris - Rue commerçante
            ]
            return addresses[index % addresses.count]
        case .grenoble:
            let addresses = [
                "Place Grenette, 38000 Grenoble, France", // Place Grenette - Place centrale
                "Bastille, 38000 Grenoble, France", // Bastille - Fort et téléphérique
                "Place Notre-Dame, 38000 Grenoble, France", // Cathédrale Notre-Dame - Cathédrale
                "5 Place de Lavalette, 38000 Grenoble, France", // Musée de Grenoble - Musée d'art
                "Place Saint-André, 38000 Grenoble, France", // Place Saint-André - Place historique
                "Jardin de Ville, 38000 Grenoble, France", // Jardin de Ville - Jardin public
                "2 Rue Très Cloîtres, 38000 Grenoble, France", // Musée de l'Ancien Évêché - Musée
                "Place Victor Hugo, 38000 Grenoble, France", // Place Victor Hugo - Place publique
                "Téléphérique de la Bastille, 38000 Grenoble, France", // Téléphérique de la Bastille - Transport
                "Parc Paul Mistral, 38000 Grenoble, France" // Parc Paul Mistral - Parc public
            ]
            return addresses[index % addresses.count]
        case .dijon:
            let addresses = [
                "Place de la Libération, 21000 Dijon, France", // Place de la Libération - Place centrale
                "Place de la Sainte-Chapelle, 21000 Dijon, France", // Palais des Ducs - Palais ducal
                "Place Saint-Bénigne, 21000 Dijon, France", // Cathédrale Saint-Bénigne - Cathédrale
                "Place Notre-Dame, 21000 Dijon, France", // Église Notre-Dame - Église gothique
                "Palais des Ducs, 21000 Dijon, France", // Musée des Beaux-Arts - Musée d'art
                "Place Darcy, 21000 Dijon, France", // Place Darcy - Place publique
                "Rue de la Liberté, 21000 Dijon, France", // Rue de la Liberté - Rue commerçante
                "Jardin Darcy, 21000 Dijon, France", // Jardin Darcy - Jardin public
                "17 Rue Sainte-Anne, 21000 Dijon, France", // Musée de la Vie Bourguignonne - Musée ethnographique
                "Place François Rude, 21000 Dijon, France" // Place François Rude - Place historique
            ]
            return addresses[index % addresses.count]
        case .angers:
            let addresses = [
                "2 Promenade du Bout du Monde, 49000 Angers, France", // Château d'Angers - Château historique
                "Place Saint-Maurice, 49000 Angers, France", // Cathédrale Saint-Maurice - Cathédrale
                "Place du Ralliement, 49000 Angers, France", // Place du Ralliement - Place centrale
                "14 Rue du Musée, 49000 Angers, France", // Musée des Beaux-Arts - Musée d'art
                "Place de la République, 49000 Angers, France", // Place de la République - Place publique
                "Jardin des Plantes, 49000 Angers, France", // Jardin des Plantes - Jardin botanique
                "Hôtel de Ville, 49000 Angers, France", // Hôtel de Ville - Mairie
                "Place du Pilori, 49000 Angers, France", // Place du Pilori - Place historique
                "4 Boulevard Arago, 49000 Angers, France", // Musée Jean-Lurçat - Musée d'art moderne
                "Quartier de la Doutre, 49000 Angers, France" // Quartier de la Doutre - Quartier médiéval
            ]
            return addresses[index % addresses.count]
        case .saintDenis:
            let addresses = [
                "1 Rue de la Légion d'Honneur, 93200 Saint-Denis, France", // Basilique Saint-Denis - Basilique royale
                "Place de la République, 93200 Saint-Denis, France", // Place de la République - Place centrale
                "Stade de France, 93200 Saint-Denis, France", // Stade de France - Stade national
                "Canal Saint-Denis, 93200 Saint-Denis, France", // Canal Saint-Denis - Canal
                "Place de la Légion d'Honneur, 93200 Saint-Denis, France", // Place de la Légion d'Honneur - Place
                "Marché de Saint-Denis, 93200 Saint-Denis, France", // Marché de Saint-Denis - Marché
                "Parc de la Légion d'Honneur, 93200 Saint-Denis, France", // Parc de la Légion d'Honneur - Parc
                "Hôtel de Ville, 93200 Saint-Denis, France", // Hôtel de Ville - Mairie
                "Église Saint-Denis de l'Estrée, 93200 Saint-Denis, France", // Église Saint-Denis de l'Estrée - Église
                "Quartier de la Plaine, 93200 Saint-Denis, France" // Quartier de la Plaine - Quartier
            ]
            return addresses[index % addresses.count]
        case .nimes:
            let addresses = [
                "Boulevard des Arènes, 30000 Nîmes, France", // Arenas de Nîmes - Amphithéâtre romain
                "Place de la Maison Carrée, 30000 Nîmes, France", // Maison Carrée - Temple romain
                "Tour Magne, 30000 Nîmes, France", // Tour Magne - Tour romaine
                "Place d'Assas, 30000 Nîmes, France", // Place d'Assas - Place publique
                "Place aux Herbes, 30000 Nîmes, France", // Cathédrale Notre-Dame-et-Saint-Castor - Cathédrale
                "Quai de la Fontaine, 30000 Nîmes, France", // Jardin de la Fontaine - Jardin public
                "16 Boulevard des Arènes, 30000 Nîmes, France", // Musée de la Romanité - Musée archéologique
                "Place du Marché, 30000 Nîmes, France", // Place du Marché - Place historique
                "Jardin de la Fontaine, 30000 Nîmes, France", // Temple de Diane - Temple romain
                "Porte Auguste, 30000 Nîmes, France" // Porte Auguste - Porte romaine
            ]
            return addresses[index % addresses.count]
        case .saintDenisReunion:
            let addresses = [
                "Place de la République, 97400 Saint-Denis, Réunion", // Place de la République - Place centrale
                "Cathédrale Saint-Denis, 97400 Saint-Denis, Réunion", // Cathédrale Saint-Denis - Cathédrale
                "Barachois, 97400 Saint-Denis, Réunion", // Barachois - Quartier historique
                "Jardin de l'État, 97400 Saint-Denis, Réunion", // Jardin de l'État - Jardin botanique
                "28 Rue de Paris, 97400 Saint-Denis, Réunion", // Musée Léon Dierx - Musée d'art
                "Place Sarda Garriga, 97400 Saint-Denis, Réunion", // Place Sarda Garriga - Place historique
                "Hôtel de Ville, 97400 Saint-Denis, Réunion", // Hôtel de Ville - Mairie
                "Quartier du Chaudron, 97400 Saint-Denis, Réunion", // Quartier du Chaudron - Quartier
                "Cimetière de l'Est, 97400 Saint-Denis, Réunion", // Cimetière de l'Est - Cimetière
                "Plage de la Grande Chaloupe, 97400 Saint-Denis, Réunion" // Plage de la Grande Chaloupe - Plage
            ]
            return addresses[index % addresses.count]
            
        // LUXEMBOURG
        case .luxembourg:
            let addresses = [
                "10 Montée de Clausen, 1343 Luxembourg", // Casemates du Bock
                "17 Rue du Marché-aux-Herbes, 1728 Luxembourg", // Palais Grand-Ducal
                "Place Guillaume II, 1136 Luxembourg", // Place Guillaume II
                "Rue Notre Dame, 2240 Luxembourg", // Cathédrale Notre-Dame
                "Parc Municipal, 2230 Luxembourg", // Parc Municipal
                "3 Park Dräi Eechelen, 1499 Luxembourg", // Musée d'Art Moderne Grand-Duc Jean
                "Pont Adolphe, 1116 Luxembourg", // Pont Adolphe
                "Place de la Gare, 1616 Luxembourg", // Gare de Luxembourg
                "Place d'Armes, 1136 Luxembourg", // Place d'Armes
                "14 Rue du Saint-Esprit, 1475 Luxembourg" // Musée d'Histoire de la Ville
            ]
            return addresses[index % addresses.count]

            
        // SUISSE
        case .zurich:
            let addresses = [
                "Bahnhofstrasse, 8001 Zürich, Switzerland", // Bahnhofstrasse
                "Grossmünsterplatz, 8001 Zürich, Switzerland", // Grossmünster
                "Fraumünster, 8001 Zürich, Switzerland", // Fraumünster
                "Lindenhof, 8001 Zürich, Switzerland", // Lindenhof
                "Münsterhof, 8001 Zürich, Switzerland", // Place du Marché
                "Museumstrasse 2, 8002 Zürich, Switzerland", // Musée national suisse
                "Heimplatz 1, 8001 Zürich, Switzerland", // Kunsthaus Zürich
                "Paradeplatz, 8001 Zürich, Switzerland", // Place Parade
                "Zollikerstrasse 107, 8008 Zürich, Switzerland", // Jardin botanique
                "Uetliberg, 8143 Zürich, Switzerland" // Uetliberg
            ]
            return addresses[index % addresses.count]
        case .geneva:
            let addresses = [
                "Place du Molard, 1204 Genève, Switzerland", // Place du Molard
                "Place du Bourg-de-Four, 1204 Genève, Switzerland", // Cathédrale Saint-Pierre
                "Jet d'eau, 1201 Genève, Switzerland", // Jet d'eau
                "Place du Bourg-de-Four, 1204 Genève, Switzerland", // Place du Bourg-de-Four
                "Rue Charles-Galland 2, 1206 Genève, Switzerland", // Musée d'art et d'histoire
                "Place de la Fusterie, 1204 Genève, Switzerland", // Place de la Fusterie
                "Jardin anglais, 1204 Genève, Switzerland", // Jardin anglais
                "Place Neuve, 1204 Genève, Switzerland", // Place Neuve
                "Parc des Bastions, 1204 Genève, Switzerland", // Parc des Bastions
                "Place du Rhône, 1204 Genève, Switzerland" // Place du Rhône
            ]
            return addresses[index % addresses.count]

        case .bern:
            let addresses = [
                "Bundesplatz, 3011 Bern, Switzerland", // Bundesplatz
                "Bim Zytglogge, 3011 Bern, Switzerland", // Zytglogge
                "Münsterplatz, 3011 Bern, Switzerland", // Münster
                "Marktgasse, 3011 Bern, Switzerland", // Place du Marché
                "Rathausplatz, 3011 Bern, Switzerland", // Hôtel de Ville
                "Helvetiaplatz 5, 3005 Bern, Switzerland", // Musée d'histoire
                "Aargauerstalden 31, 3006 Bern, Switzerland", // Jardin des roses
                "Grosser Muristalden, 3005 Bern, Switzerland", // Parc de l'ours
                "Kramgasse, 3011 Bern, Switzerland", // Kramgasse
                "Gerechtigkeitsgasse, 3011 Bern, Switzerland" // Gerechtigkeitsgasse
            ]
            return addresses[index % addresses.count]
        case .lausanne:
            let addresses = [
                "Place de la Palud, 1003 Lausanne, Switzerland", // Place de la Palud
                "Place de la Cathédrale, 1005 Lausanne, Switzerland", // Cathédrale
                "Place Saint-François, 1003 Lausanne, Switzerland", // Place Saint-François
                "Place de la Riponne, 1004 Lausanne, Switzerland", // Place de la Riponne
                "Quai d'Ouchy 1, 1006 Lausanne, Switzerland", // Musée olympique
                "Place du Marché, 1003 Lausanne, Switzerland", // Place du Marché
                "Place de la Gare, 1003 Lausanne, Switzerland", // Place de la Gare
                "Avenue du Tribunal-Fédéral 2, 1006 Lausanne, Switzerland", // Parc de Mon-Repos
                "Place de la Tour, 1003 Lausanne, Switzerland", // Place de la Tour
                "Rue de Bourg, 1003 Lausanne, Switzerland" // Rue de Bourg
            ]
            return addresses[index % addresses.count]
        case .winterthur:
            let addresses = [
                "Marktgasse, 8400 Winterthur, Switzerland", // Marktgasse
                "Stadtkirche, 8400 Winterthur, Switzerland", // Stadtkirche
                "Rathaus, 8400 Winterthur, Switzerland", // Hôtel de Ville
                "Kunstmuseum, 8400 Winterthur, Switzerland", // Musée des Beaux-Arts
                "Bahnhofplatz, 8400 Winterthur, Switzerland", // Place de la Gare
                "Kirchgasse, 8400 Winterthur, Switzerland", // Kirchgasse
                "Steinberggasse, 8400 Winterthur, Switzerland", // Steinberggasse
                "Obere Kirchgasse, 8400 Winterthur, Switzerland", // Obere Kirchgasse
                "Stadtgarten, 8400 Winterthur, Switzerland", // Parc municipal
                "Schlossgasse, 8400 Winterthur, Switzerland" // Schlossgasse
            ]
            return addresses[index % addresses.count]
        case .stGallen:
            let addresses = [
                "Marktplatz, 9000 St. Gallen, Switzerland", // Marktplatz
                "Stiftskirche, 9000 St. Gallen, Switzerland", // Stiftskirche
                "Rathaus, 9000 St. Gallen, Switzerland", // Hôtel de Ville
                "Stiftsbibliothek, 9000 St. Gallen, Switzerland", // Bibliothèque abbatiale
                "Bahnhofplatz, 9000 St. Gallen, Switzerland", // Place de la Gare
                "Gallusplatz, 9000 St. Gallen, Switzerland", // Gallusplatz
                "Neugasse, 9000 St. Gallen, Switzerland", // Neugasse
                "Spisergasse, 9000 St. Gallen, Switzerland", // Spisergasse
                "Stadtpark, 9000 St. Gallen, Switzerland", // Parc municipal
                "Metzgergasse, 9000 St. Gallen, Switzerland" // Metzgergasse
            ]
            return addresses[index % addresses.count]
        case .lucerne:
            let addresses = [
                "Kapellbrücke, 6004 Luzern, Switzerland", // Kapellbrücke
                "Kapellplatz, 6004 Luzern, Switzerland", // Place de la Chapelle
                "Musegg, 6004 Luzern, Switzerland", // Musegg
                "Rathaus, 6004 Luzern, Switzerland", // Hôtel de Ville
                "Hofkirche, 6004 Luzern, Switzerland", // Cathédrale
                "Bahnhofplatz, 6004 Luzern, Switzerland", // Place de la Gare
                "Weggisgasse, 6004 Luzern, Switzerland", // Weggisgasse
                "Hertensteinstrasse, 6004 Luzern, Switzerland", // Hertensteinstrasse
                "Stadtgarten, 6004 Luzern, Switzerland", // Parc municipal
                "Schwanenplatz, 6004 Luzern, Switzerland" // Schwanenplatz
            ]
            return addresses[index % addresses.count]
            
        // ALLEMAGNE
        case .berlin:
            let addresses = [
                "Pariser Platz, 10117 Berlin, Germany", // Brandenburger Tor
                "Platz der Republik 1, 11011 Berlin, Germany", // Reichstag
                "Alexanderplatz, 10178 Berlin, Germany", // Alexanderplatz
                "Friedrichstraße 43-45, 10117 Berlin, Germany", // Checkpoint Charlie
                "Museumsinsel, 10117 Berlin, Germany", // Museumsinsel
                "Potsdamer Platz, 10117 Berlin, Germany", // Potsdamer Platz
                "Kurfürstendamm, 10719 Berlin, Germany", // Kurfürstendamm
                "Gendarmenmarkt, 10117 Berlin, Germany", // Gendarmenmarkt
                "Tiergarten, 10785 Berlin, Germany", // Tiergarten
                "Mühlenstraße, 10243 Berlin, Germany" // East Side Gallery
            ]
            return addresses[index % addresses.count]
        case .hamburg:
            let addresses = [
                "Rathausmarkt, 20095 Hamburg, Germany", // Rathaus
                "Speicherstadt, 20457 Hamburg, Germany", // Speicherstadt
                "Platz der Deutschen Einheit, 20457 Hamburg, Germany", // Elbphilharmonie
                "Jungfernstieg, 20354 Hamburg, Germany", // Jungfernstieg
                "Reeperbahn, 20359 Hamburg, Germany", // Reeperbahn
                "Planten un Blomen, 20355 Hamburg, Germany", // Planten un Blomen
                "Englische Planke, 20459 Hamburg, Germany", // St. Michaelis Kirche
                "HafenCity, 20457 Hamburg, Germany", // HafenCity
                "Alster, 20099 Hamburg, Germany", // Alster
                "Kehrwieder 2, 20457 Hamburg, Germany" // Miniatur Wunderland
            ]
            return addresses[index % addresses.count]
        case .munich:
            let addresses = [
                "Marienplatz, 80331 München, Germany", // Marienplatz
                "Frauenplatz, 80331 München, Germany", // Frauenkirche
                "Residenzstraße, 80333 München, Germany", // Residenz
                "Englischer Garten, 80538 München, Germany", // Englischer Garten
                "Schloß Nymphenburg, 80638 München, Germany", // Nymphenburg
                "Viktualienmarkt, 80331 München, Germany", // Viktualienmarkt
                "Platzl 9, 80331 München, Germany", // Hofbräuhaus
                "Olympiapark, 80809 München, Germany", // Olympiapark
                "Museumsinsel 1, 80538 München, Germany", // Deutsches Museum
                "Odeonsplatz, 80539 München, Germany" // Odeonsplatz
            ]
            return addresses[index % addresses.count]
        case .cologne:
            let addresses = [
                "Domkloster 4, 50667 Köln, Germany", // Kölner Dom
                "Alter Markt, 50667 Köln, Germany", // Alter Markt
                "Heumarkt, 50667 Köln, Germany", // Heumarkt
                "Rheinpromenade, 50667 Köln, Germany", // Rheinpromenade
                "Heinrich-Böll-Platz, 50667 Köln, Germany", // Museum Ludwig
                "Hohenzollernbrücke, 50667 Köln, Germany", // Hohenzollernbrücke
                "Schildergasse, 50667 Köln, Germany", // Schildergasse
                "Neumarkt, 50667 Köln, Germany", // Neumarkt
                "Roncalliplatz 4, 50667 Köln, Germany", // Römisch-Germanisches Museum
                "Rheinpark, 50679 Köln, Germany" // Rheinpark
            ]
            return addresses[index % addresses.count]
        case .frankfurt:
            let addresses = [
                "Römerberg, 60311 Frankfurt, Germany", // Römer
                "Domplatz, 60311 Frankfurt, Germany", // Dom
                "Zeil, 60313 Frankfurt, Germany", // Zeil
                "Schaumainkai, 60596 Frankfurt, Germany", // Museumsufer
                "Opernplatz, 60313 Frankfurt, Germany", // Alte Oper
                "Siesmayerstraße 61, 60323 Frankfurt, Germany", // Palmengarten
                "Eschenheimer Turm, 60318 Frankfurt, Germany", // Eschenheimer Turm
                "Hauptwache, 60313 Frankfurt, Germany", // Hauptwache
                "Großer Hirschgraben 23-25, 60311 Frankfurt, Germany", // Goethe-Haus
                "Neue Mainzer Straße 52-58, 60311 Frankfurt, Germany" // Main Tower
            ]
            return addresses[index % addresses.count]
        case .stuttgart:
            let addresses = [
                "Schlossplatz, 70173 Stuttgart, Germany", // Schlossplatz
                "Konrad-Adenauer-Straße 30-32, 70173 Stuttgart, Germany", // Neue Staatsgalerie
                "Marktplatz, 70173 Stuttgart, Germany", // Marktplatz
                "Schlossgarten, 70173 Stuttgart, Germany", // Schlossgarten
                "Neckartalstraße, 70376 Stuttgart, Germany", // Wilhelma
                "Stiftskirche, 70173 Stuttgart, Germany", // Stiftskirche
                "Königsstraße, 70173 Stuttgart, Germany", // Königsstraße
                "Rosensteinpark, 70191 Stuttgart, Germany", // Rosensteinpark
                "Mercedesstraße 100, 70372 Stuttgart, Germany", // Mercedes-Benz Museum
                "Porscheplatz 1, 70435 Stuttgart, Germany" // Porsche Museum
            ]
            return addresses[index % addresses.count]

        case .leipzig:
            let addresses = [
                "Markt, 04109 Leipzig, Germany", // Markt
                "Thomaskirche, 04109 Leipzig, Germany", // Thomaskirche
                "Nikolaikirche, 04109 Leipzig, Germany", // Nikolaikirche
                "Gewandhaus, 04109 Leipzig, Germany", // Gewandhaus
                "Völkerschlachtdenkmal, 04299 Leipzig, Germany", // Völkerschlachtdenkmal
                "Augustusplatz, 04109 Leipzig, Germany", // Augustusplatz
                "Altes Rathaus, 04109 Leipzig, Germany", // Altes Rathaus
                "Neues Rathaus, 04109 Leipzig, Germany", // Neues Rathaus
                "Zoo Leipzig, 04105 Leipzig, Germany", // Zoo Leipzig
                "Grassi Museum, 04109 Leipzig, Germany" // Grassi Museum
            ]
            return addresses[index % addresses.count]
        case .dortmund:
            let addresses = [
                "Alter Markt, 44137 Dortmund, Germany", // Alter Markt
                "Reinoldikirche, 44137 Dortmund, Germany", // Reinoldikirche
                "Petrikirche, 44137 Dortmund, Germany", // Petrikirche
                "Marienkirche, 44137 Dortmund, Germany", // Marienkirche
                "Westfalenpark, 44139 Dortmund, Germany", // Westfalenpark
                "Dortmunder U, 44137 Dortmund, Germany", // Dortmunder U
                "Hauptbahnhof, 44137 Dortmund, Germany", // Hauptbahnhof
                "Signal Iduna Park, 44139 Dortmund, Germany", // Signal Iduna Park
                "Museum für Kunst und Kulturgeschichte, 44137 Dortmund, Germany", // Museum für Kunst und Kulturgeschichte
                "Phoenix-See, 44263 Dortmund, Germany" // Phoenix-See
            ]
            return addresses[index % addresses.count]
        case .essen:
            let addresses = [
                "Marktkirche, 45127 Essen, Germany", // Marktkirche
                "Dom, 45127 Essen, Germany", // Dom
                "Villa Hügel, 45133 Essen, Germany", // Villa Hügel
                "Zeche Zollverein, 45309 Essen, Germany", // Zeche Zollverein
                "Grugapark, 45131 Essen, Germany", // Grugapark
                "Alte Synagoge, 45127 Essen, Germany", // Alte Synagoge
                "Museum Folkwang, 45128 Essen, Germany", // Museum Folkwang
                "Kettwiger Straße, 45127 Essen, Germany", // Kettwiger Straße
                "Limbecker Platz, 45127 Essen, Germany", // Limbecker Platz
                "Baldeneysee, 45134 Essen, Germany" // Baldeneysee
            ]
            return addresses[index % addresses.count]
        case .brussels:
            let addresses = [
                "Grand-Place, 1000 Bruxelles, Belgium", // Grand-Place - Place principale
                "Rue de l'Étuve 31, 1000 Bruxelles, Belgium", // Manneken Pis - Statue célèbre
                "Galerie du Roi 5, 1000 Bruxelles, Belgium", // Galeries Royales Saint-Hubert
                "25 Rue Américaine, 1060 Saint-Gilles, Belgium", // Musée Horta - Art nouveau
                "Place du Grand Sablon, 1000 Bruxelles, Belgium", // Place du Grand Sablon
                "Rue au Beurre 31, 1000 Bruxelles, Belgium", // Musée du Cacao et du Chocolat
                "Rue des Bouchers 18, 1000 Bruxelles, Belgium", // Rue des Bouchers - Rue gastronomique
                "Square de l'Atomium, 1020 Bruxelles, Belgium", // Atomium - Monument moderne
                "Avenue du Parc Royal, 1020 Bruxelles, Belgium", // Parc Royal - Parc public
                "Rue Wiertz 60, 1047 Bruxelles, Belgium" // Parc du Cinquantenaire - Parc et musées
            ]
            return addresses[index % addresses.count]
        case .antwerp:
            let addresses = [
                "Grote Markt, 2000 Antwerpen, Belgium", // Grote Markt - Place principale
                "Groenplaats 21, 2000 Antwerpen, Belgium", // Cathédrale Notre-Dame - Cathédrale gothique
                "Steenplein, 2000 Antwerpen, Belgium", // Place Steen - Place historique
                "Vrijdagmarkt 22-23, 2000 Antwerpen, Belgium", // Musée Plantin-Moretus - Musée de l'imprimerie
                "Meir 1, 2000 Antwerpen, Belgium", // Place Meir - Rue commerçante
                "Leopold de Waelplaats 1-2, 2000 Antwerpen, Belgium", // Musée Royal des Beaux-Arts - Musée d'art
                "Wapper 9-11, 2000 Antwerpen, Belgium", // Maison de Rubens - Musée de l'artiste
                "Groenplaats, 2000 Antwerpen, Belgium", // Place du Marché aux Herbes - Place centrale
                "Koningin Astridplein 20-26, 2018 Antwerpen, Belgium", // Zoo d'Anvers - Parc zoologique
                "Port d'Anvers, 2000 Antwerpen, Belgium" // Port d'Anvers - Port maritime
            ]
            return addresses[index % addresses.count]
        case .ghent:
            let addresses = [
                "Korenmarkt, 9000 Gent, Belgium", // Place du Marché aux Grains - Place centrale
                "Sint-Baafsplein, 9000 Gent, Belgium", // Cathédrale Saint-Bavon - Cathédrale gothique
                "Botermarkt, 9000 Gent, Belgium", // Beffroi de Gand - Tour médiévale
                "Sint-Veerleplein, 9000 Gent, Belgium", // Château des Comtes - Forteresse médiévale
                "Sint-Niklaaskerk, 9000 Gent, Belgium", // Église Saint-Nicolas - Église gothique
                "Fernand Scribedreef 1, 9000 Gent, Belgium", // Musée des Beaux-Arts - Musée d'art
                "Graslei, 9000 Gent, Belgium", // Quai aux Herbes - Quai historique
                "Vrijdagmarkt, 9000 Gent, Belgium", // Place du Vendredi - Place médiévale
                "Jardin botanique, 9000 Gent, Belgium", // Jardin botanique - Parc botanique
                "Korenlei, 9000 Gent, Belgium" // Quai aux Grains - Quai historique
            ]
            return addresses[index % addresses.count]
        case .charleroi:
            let addresses = [
                "Place Charles II, 6000 Charleroi, Belgium", // Place Charles II - Place centrale
                "Place de l'Hôtel de Ville, 6000 Charleroi, Belgium", // Hôtel de Ville - Mairie
                "Place de la Digue, 6000 Charleroi, Belgium", // Basilique Saint-Christophe - Basilique
                "Place du Manège, 6000 Charleroi, Belgium", // Musée des Beaux-Arts - Musée d'art
                "Place Albert Ier, 6000 Charleroi, Belgium", // Église Saint-Antoine - Église
                "Parc Reine Astrid, 6000 Charleroi, Belgium", // Parc Reine Astrid - Parc public
                "Gare de Charleroi-Sud, 6000 Charleroi, Belgium", // Gare de Charleroi-Sud - Gare principale
                "Rue de la Montagne, 6000 Charleroi, Belgium", // Rue de la Montagne
                "Rue de Dampremy, 6000 Charleroi, Belgium", // Rue de Dampremy
                "Rue de Marcinelle, 6000 Charleroi, Belgium" // Rue de Marcinelle
            ]
            return addresses[index % addresses.count]
        case .liege:
            let addresses = [
                "Place Saint-Lambert, 4000 Liège, Belgium", // Place Saint-Lambert - Place centrale
                "Place de la Cathédrale, 4000 Liège, Belgium", // Cathédrale Saint-Paul - Cathédrale
                "Place du Marché, 4000 Liège, Belgium", // Place du Marché - Place historique
                "Place Saint-Lambert, 4000 Liège, Belgium", // Palais des Princes-Évêques - Palais historique
                "Montagne de Bueren, 4000 Liège, Belgium", // Montagne de Bueren - Escalier historique
                "Place de la République française, 4000 Liège, Belgium", // Place de la République française - Place publique
                "Place Saint-Jacques, 4000 Liège, Belgium", // Église Saint-Jacques - Église gothique
                "Féronstrée 136, 4000 Liège, Belgium", // Musée Curtius - Musée archéologique
                "Place Cockerill, 4000 Liège, Belgium", // Place Cockerill - Place industrielle
                "Parc de la Boverie, 4000 Liège, Belgium" // Parc de la Boverie - Parc et musée
            ]
            return addresses[index % addresses.count]
        case .bruges:
            let addresses = [
                "Markt, 8000 Brugge, Belgium", // Grand Place - Place principale
                "Markt, 8000 Brugge, Belgium", // Beffroi de Bruges - Tour médiévale
                "Burg, 8000 Brugge, Belgium", // Basilique du Saint-Sang - Basilique
                "Sint-Salvatorskathedraal, 8000 Brugge, Belgium", // Cathédrale Saint-Sauveur - Cathédrale
                "Burg, 8000 Brugge, Belgium", // Place du Bourg - Place historique
                "Mariastraat, 8000 Brugge, Belgium", // Église Notre-Dame - Église gothique
                "Rozenhoedkaai, 8000 Brugge, Belgium", // Quai du Rosaire - Quai pittoresque
                "Jan van Eyckplein, 8000 Brugge, Belgium", // Place Jan van Eyck - Place médiévale
                "Dijver 12, 8000 Brugge, Belgium", // Musée Groeninge - Musée d'art
                "Simon Stevinplein, 8000 Brugge, Belgium" // Place Simon Stevin - Place publique
            ]
            return addresses[index % addresses.count]
        case .namur:
            let addresses = [
                "Route Merveilleuse, 5000 Namur, Belgium", // Citadelle de Namur - Forteresse historique
                "Place d'Armes, 5000 Namur, Belgium", // Place d'Armes - Place centrale
                "Place Saint-Aubain, 5000 Namur, Belgium", // Cathédrale Saint-Aubain - Cathédrale
                "Place du Marché aux Légumes, 5000 Namur, Belgium", // Place du Marché aux Légumes - Marché
                "Place de l'Hôtel de Ville, 5000 Namur, Belgium", // Hôtel de Ville - Mairie
                "Place Saint-Loup, 5000 Namur, Belgium", // Église Saint-Loup - Église baroque
                "Place de l'Ange, 5000 Namur, Belgium", // Place de l'Ange - Place historique
                "Rue du Pont 21, 5000 Namur, Belgium", // Musée des Arts décoratifs - Musée
                "Place du Vieux Marché, 5000 Namur, Belgium", // Place du Vieux Marché - Place médiévale
                "Parc Louise-Marie, 5000 Namur, Belgium" // Parc Louise-Marie - Parc public
            ]
            return addresses[index % addresses.count]
        case .mons:
            let addresses = [
                "Grand Place, 7000 Mons, Belgium", // Grand Place - Place centrale
                "Beffroi de Mons, 7000 Mons, Belgium", // Beffroi de Mons - Tour médiévale
                "Collégiale Sainte-Waudru, 7000 Mons, Belgium", // Collégiale Sainte-Waudru - Église gothique
                "Place du Parc, 7000 Mons, Belgium", // Place du Parc - Place publique
                "Hôtel de Ville, 7000 Mons, Belgium", // Hôtel de Ville - Mairie
                "Église Saint-Nicolas, 7000 Mons, Belgium", // Église Saint-Nicolas - Église
                "Place de Flandre, 7000 Mons, Belgium", // Place de Flandre - Place historique
                "Musée du Doudou, 7000 Mons, Belgium", // Musée du Doudou - Musée
                "Place de la Grand'Rue, 7000 Mons, Belgium", // Place de la Grand'Rue - Place médiévale
                "Parc du Waux-Hall, 7000 Mons, Belgium" // Parc du Waux-Hall - Parc public
            ]
            return addresses[index % addresses.count]

        case .aalst:
            let addresses = [
                "Grote Markt, 9300 Aalst, Belgium", // Grand Place - Place centrale
                "Stadhuis, 9300 Aalst, Belgium", // Hôtel de Ville - Mairie
                "Sint-Martinuskerk, 9300 Aalst, Belgium", // Église Saint-Martin - Église gothique
                "Beffroi van Aalst, 9300 Aalst, Belgium", // Beffroi d'Alost - Tour médiévale
                "Stationstraat, 9300 Aalst, Belgium", // Place de la Gare - Gare
                "Sint-Jozefkerk, 9300 Aalst, Belgium", // Église Saint-Joseph - Église
                "Denderstraat, 9300 Aalst, Belgium", // Parc de la Dender - Parc le long de la Dender
                "Korte Zoutstraat, 9300 Aalst, Belgium", // Korte Zoutstraat
                "Lange Zoutstraat, 9300 Aalst, Belgium", // Lange Zoutstraat
                "Oude Graanmarkt, 9300 Aalst, Belgium" // Oude Graanmarkt
            ]
            return addresses[index % addresses.count]
        
        // MAROC
        case .tangier:
            let addresses = [
                "Place du 9 Avril 1947, Tanger 90000, Morocco", // Place du 9 Avril 1947
                "Kasbah, Tanger 90000, Morocco", // Kasbah de Tanger
                "Place de France, Tanger 90000, Morocco", // Place de France
                "Grand Socco, Tanger 90000, Morocco", // Grand Socco
                "Petit Socco, Tanger 90000, Morocco", // Petit Socco
                "Cap Spartel, Tanger 90000, Morocco", // Cap Spartel
                "Grottes d'Hercule, Tanger 90060, Morocco", // Grotte d'Hercule
                "Plage de Malabata, Tanger 90000, Morocco", // Plage de Malabata
                "Musée de la Kasbah, Tanger 90000, Morocco", // Musée de la Kasbah
                "Cimetière américain, Tanger 90000, Morocco" // Cimetière américain
            ]
            return addresses[index % addresses.count]
        case .casablanca:
            let addresses = [
                "Mosquée Hassan II, Boulevard Sidi Mohammed Ben Abdallah, Casablanca 20000, Morocco", // Mosquée Hassan II
                "Place Mohammed V, Casablanca 20000, Morocco", // Place Mohammed V
                "Rue Tahar Sebti, Ancienne Médina, Casablanca 20250, Morocco", // Médina de Casablanca
                "Rue d'Alger, Casablanca 20250, Morocco", // Cathédrale du Sacré-Cœur
                "Place des Nations Unies, Casablanca 20250, Morocco", // Place des Nations Unies
                "Ain Diab, Casablanca 20000, Morocco", // Ain Diab
                "81 Rue Chasseur Jules Gros, Casablanca 20250, Morocco", // Musée du Judaïsme Marocain
                "Boulevard Moulay Youssef, Casablanca 20250, Morocco", // Parc de la Ligue Arabe
                "Rue Chaouia, Casablanca 20250, Morocco", // Marché Central
                "Boulevard Al Massira Al Khadra, Casablanca 20250, Morocco" // Twin Center
            ]
            return addresses[index % addresses.count]
        case .marrakech:
            let addresses = [
                "Place Jemaa el-Fna, Marrakech 40000, Morocco", // Place Jemaa el-Fna
                "Rue Mouassine, Médina, Marrakech 40000, Morocco", // Médina de Marrakech
                "Mosquée Koutoubia, Avenue Mohammed V, Marrakech 40000, Morocco", // Koutoubia
                "Rue Riad Zitoun el Jdid, Marrakech 40000, Morocco", // Palais Bahia
                "Jardin Majorelle, Rue Yves Saint Laurent, Marrakech 40090, Morocco", // Jardin Majorelle
                "Ksibat Nhass, Marrakech 40000, Morocco", // Palais El Badi
                "Tombeaux Saadiens, Rue de la Kasbah, Marrakech 40000, Morocco", // Tombeaux Saadiens
                "Médersa Ben Youssef, Rue Assouel, Marrakech 40000, Morocco", // Médersa Ben Youssef
                "Souk Semmarine, Médina, Marrakech 40000, Morocco", // Souk de Marrakech
                "Jardin de la Ménara, Marrakech 40000, Morocco" // Jardin de la Ménara
            ]
            return addresses[index % addresses.count]
        case .fez:
            let addresses = [
                "Médina de Fès el-Bali, Rue Talaa Kebira, Fès 30000, Morocco", // Médina de Fès el-Bali
                "Médersa Bou Inania, Rue Talaa Sghira, Fès 30000, Morocco", // Médersa Bou Inania
                "Mosquée Karaouiyine, Place Seffarine, Fès 30000, Morocco", // Mosquée Karaouiyine
                "Place Nejjarine, Fès 30000, Morocco", // Place Nejjarine
                "Tanneries Chouara, Quartier Chouara, Fès 30000, Morocco", // Tanneries Chouara
                "Palais Royal, Fès 30000, Morocco", // Palais Royal
                "Place Bab Boujloud, Fès 30000, Morocco", // Bab Boujloud
                "Musée Dar Batha, Place Batha, Fès 30000, Morocco", // Musée Dar Batha
                "Jardin Jnan Sbil, Fès 30000, Morocco", // Jardin Jnan Sbil
                "Tombeaux des Mérinides, Borj Nord, Fès 30000, Morocco" // Tombeaux des Mérinides
            ]
            return addresses[index % addresses.count]
        case .rabat:
            let addresses = [
                "Rue Bazzo, Kasbah des Oudayas, Rabat 10030, Morocco", // Kasbah des Oudayas
                "Tour Hassan, Boulevard Mohamed Lyazidi, Rabat 10030, Morocco", // Tour Hassan
                "Mausolée Mohammed V, Rabat 10030, Morocco", // Mausolée Mohammed V
                "Rue Souika, Médina, Rabat 10000, Morocco", // Médina de Rabat
                "Chellah Archaeological Site, Rabat 10000, Morocco", // Chellah
                "Musée Mohammed VI, Rabat 10000, Morocco", // Musée Mohammed VI
                "Plage de Rabat, Rabat 10000, Morocco", // Plage de Rabat
                "Jardin d'Essais, Rabat 10000, Morocco", // Jardin d'Essais
                "Cathédrale Saint-Pierre, Place du Golan, Rabat 10000, Morocco", // Cathédrale Saint-Pierre
                "Musée de l'Histoire et des Civilisations, Rabat 10000, Morocco" // Musée de l'Histoire et des Civilisations
            ]
            return addresses[index % addresses.count]
        case .agadir:
            let addresses = [
                "Plage d'Agadir, Agadir 80000, Morocco", // Plage d'Agadir
                "Kasbah d'Agadir Oufella, Agadir 80000, Morocco", // Kasbah d'Agadir Oufella
                "Souk El Had, Agadir 80000, Morocco", // Souk El Had
                "Musée du Patrimoine Amazigh, Agadir 80000, Morocco", // Musée du Patrimoine Amazigh
                "Marina d'Agadir, Agadir 80000, Morocco", // Marina d'Agadir
                "Place Al Amal, Agadir 80000, Morocco", // Place Al Amal
                "Jardin Olhão, Agadir 80000, Morocco", // Jardin Olhão
                "Mosquée Mohammed V, Agadir 80000, Morocco", // Mosquée Mohammed V
                "Crocoparc, Agadir 80000, Morocco", // Crocoparc
                "Vallée des Oiseaux, Agadir 80000, Morocco" // Vallée des Oiseaux
            ]
            return addresses[index % addresses.count]

        case .oujda:
            let addresses = [
                "Place du 16 Août, Oujda 60000, Morocco", // Place du 16 Août
                "Médina d'Oujda, Oujda 60000, Morocco", // Médina d'Oujda
                "Mosquée Sidi Yahya, Oujda 60000, Morocco", // Mosquée Sidi Yahya
                "Musée de la Résistance, Oujda 60000, Morocco", // Musée de la Résistance
                "Parc Lalla Aïcha, Oujda 60000, Morocco", // Parc Lalla Aïcha
                "Bab Sidi Abdelouahab, Oujda 60000, Morocco", // Bab Sidi Abdelouahab
                "Place du 3 Mars, Oujda 60000, Morocco", // Place du 3 Mars
                "Jardin Municipal, Oujda 60000, Morocco", // Jardin Municipal
                "Stade d'Honneur, Oujda 60000, Morocco", // Stade d'Honneur
                "Gare d'Oujda, Oujda 60000, Morocco" // Gare d'Oujda
            ]
            return addresses[index % addresses.count]
        case .tetouan:
            let addresses = [
                "Médina de Tétouan, Tétouan 93000, Morocco", // Médina de Tétouan
                "Place Hassan II, Tétouan 93000, Morocco", // Place Hassan II
                "Musée Ethnographique, Tétouan 93000, Morocco", // Musée Ethnographique
                "Mosquée Sidi Saïd, Tétouan 93000, Morocco", // Mosquée Sidi Saïd
                "Plage de Martil, Martil 93150, Morocco", // Plage de Martil
                "Musée Archéologique, Tétouan 93000, Morocco", // Musée Archéologique
                "Jardin Feddan, Tétouan 93000, Morocco", // Jardin Feddan
                "Bab Okla, Tétouan 93000, Morocco", // Bab Okla
                "Place Moulay el Mehdi, Tétouan 93000, Morocco", // Place Moulay el Mehdi
                "Cimetière espagnol, Tétouan 93000, Morocco" // Cimetière espagnol
            ]
            return addresses[index % addresses.count]
        case .meknes:
            let addresses = [
                "Place el-Hedim, Meknès 50000, Morocco", // Place el-Hedim - Place centrale
                "Bab Mansour, Meknès 50000, Morocco", // Bab Mansour - Porte monumentale
                "Médina de Meknès, Meknès 50000, Morocco", // Médina de Meknès - Quartier historique
                "Mausolée Moulay Ismail, Meknès 50000, Morocco", // Mausolée Moulay Ismail - Mausolée royal
                "Heri es-Souani, Meknès 50000, Morocco", // Heri es-Souani - Greniers royaux
                "Musée Dar Jamaï, Place el-Hedim, Meknès 50000, Morocco", // Musée Dar Jamaï - Musée d'art
                "Mosquée Lalla Aouda, Meknès 50000, Morocco", // Mosquée Lalla Aouda - Mosquée
                "Place Lalla Aouda, Meknès 50000, Morocco", // Place Lalla Aouda - Place publique
                "Jardin Lahboul, Meknès 50000, Morocco", // Jardin Lahboul - Jardin public
                "Bab el-Khemis, Meknès 50000, Morocco" // Bab el-Khemis - Porte historique
            ]
            return addresses[index % addresses.count]
        
        // TURQUIE
        case .istanbul:
            let addresses = [
                "Sultanahmet Meydanı, Fatih, Istanbul, Turkey", // Sultanahmet Meydanı
                "Ayasofya, Sultanahmet, Fatih, Istanbul, Turkey", // Ayasofya
                "Topkapı Sarayı, Sultanahmet, Fatih, Istanbul, Turkey", // Topkapı Sarayı
                "Sultanahmet Camii, Sultanahmet, Fatih, Istanbul, Turkey", // Sultanahmet Camii
                "Kapalı Çarşı, Beyazıt, Fatih, Istanbul, Turkey", // Kapalı Çarşı
                "Galata Kulesi, Galata, Beyoğlu, Istanbul, Turkey", // Galata Kulesi
                "Dolmabahçe Sarayı, Beşiktaş, Istanbul, Turkey", // Dolmabahçe Sarayı
                "Boğaziçi Bridge, Istanbul, Turkey", // Boğaziçi Köprüsü
                "Taksim Meydanı, Beyoğlu, Istanbul, Turkey", // Taksim Meydanı
                "Ortaköy Camii, Ortaköy, Beşiktaş, Istanbul, Turkey" // Ortaköy Camii
            ]
            return addresses[index % addresses.count]
        case .ankara:
            let addresses = [
                "Anıtkabir, Anıt Caddesi, Tandoğan, Ankara, Turkey", // Anıtkabir
                "Kızılay Meydanı, Çankaya, Ankara, Turkey", // Kızılay Meydanı
                "Ulus Meydanı, Altındağ, Ankara, Turkey", // Ulus Meydanı
                "Ankara Kalesi, Altındağ, Ankara, Turkey", // Ankara Kalesi
                "Atakule, Çankaya, Ankara, Turkey", // Atakule
                "Museum of Anatolian Civilizations, Altındağ, Ankara, Turkey", // Museum of Anatolian Civilizations
                "Kurtuluş Savaşı Müzesi, Ulus, Ankara, Turkey", // Kurtuluş Savaşı Müzesi
                "Gençlik Parkı, Altındağ, Ankara, Turkey", // Gençlik Parkı
                "Hacı Bayram-ı Veli Camii, Altındağ, Ankara, Turkey", // Hacı Bayram-ı Veli Camii
                "Çankaya Köşkü, Çankaya, Ankara, Turkey" // Çankaya Köşkü
            ]
            return addresses[index % addresses.count]
        case .izmir:
            let addresses = [
                "Konak Meydanı, Konak, İzmir, Turkey", // Konak Meydanı
                "Kemeraltı Çarşısı, Konak, İzmir, Turkey", // Kemeraltı Çarşısı
                "Saat Kulesi, Konak, İzmir, Turkey", // Saat Kulesi
                "Alsancak Mahallesi, Konak, İzmir, Turkey", // Alsancak Mahallesi
                "Kültürpark, Konak, İzmir, Turkey", // Kültürpark
                "Kadifekale, Konak, İzmir, Turkey", // Kadifekale
                "Asansör, Konak, İzmir, Turkey", // Asansör
                "Agora, Konak, İzmir, Turkey", // Agora
                "Kızlarağası Hanı, Konak, İzmir, Turkey", // Kızlarağası Hanı
                "Basmane Garı, Konak, İzmir, Turkey" // Basmane Garı
            ]
            return addresses[index % addresses.count]
        case .antalya:
            let addresses = [
                "Kaleiçi, Muratpaşa, Antalya, Turkey", // Kaleiçi
                "Yivli Minare, Muratpaşa, Antalya, Turkey", // Yivli Minare
                "Hadrian Kapısı, Muratpaşa, Antalya, Turkey", // Hadrian Kapısı
                "Konyaaltı Plajı, Muratpaşa, Antalya, Turkey", // Konyaaltı Plajı
                "Lara Plajı, Muratpaşa, Antalya, Turkey", // Lara Plajı
                "Düden Şelalesi, Muratpaşa, Antalya, Turkey", // Düden Şelalesi
                "Kurşunlu Şelalesi, Aksu, Antalya, Turkey", // Kurşunlu Şelalesi
                "Perge Antik Kenti, Aksu, Antalya, Turkey", // Perge Antik Kenti
                "Aspendos Antik Tiyatrosu, Serik, Antalya, Turkey", // Aspendos Antik Tiyatrosu
                "Side Antik Kenti, Manavgat, Antalya, Turkey" // Side Antik Kenti
            ]
            return addresses[index % addresses.count]
        case .bursa:
            let addresses = [
                "Uludağ, Nilüfer, Bursa, Turkey", // Uludağ
                "Yeşil Camii, Yeşil, Bursa, Turkey", // Yeşil Camii
                "Yeşil Türbe, Yeşil, Bursa, Turkey", // Yeşil Türbe
                "Ulu Camii, Osmangazi, Bursa, Turkey", // Ulu Camii
                "Koza Han, Osmangazi, Bursa, Turkey", // Koza Han
                "Cumalıkızık Köyü, Yıldırım, Bursa, Turkey", // Cumalıkızık Köyü
                "Tophane Saat Kulesi, Osmangazi, Bursa, Turkey", // Tophane Saat Kulesi
                "Muradiye Külliyesi, Osmangazi, Bursa, Turkey", // Muradiye Külliyesi
                "Oylat Kaplıcaları, İnegöl, Bursa, Turkey", // Oylat Kaplıcaları
                "İznik Gölü, İznik, Bursa, Turkey" // İznik Gölü
            ]
            return addresses[index % addresses.count]
        case .adana:
            let addresses = [
                "Seyhan Barajı, Seyhan, Adana, Turkey", // Seyhan Barajı
                "Taşköprü, Seyhan, Adana, Turkey", // Taşköprü
                "Büyük Saat Kulesi, Seyhan, Adana, Turkey", // Büyük Saat Kulesi
                "Ulu Camii, Seyhan, Adana, Turkey", // Ulu Camii
                "Yılankale, Ceyhan, Adana, Turkey", // Yılankale
                "Kapıkaya Kanyonu, Aladağ, Adana, Turkey", // Kapıkaya Kanyonu
                "Varda Köprüsü, Hacıkırı, Karaisalı, Adana, Turkey", // Varda Köprüsü
                "Anavarza Antik Kenti, Kozan, Adana, Turkey", // Anavarza Antik Kenti
                "Yumurtalık Plajı, Yumurtalık, Adana, Turkey", // Yumurtalık Plajı
                "Seyhan Dam Lake, Seyhan, Adana, Turkey" // Seyhan Dam Lake
            ]
            return addresses[index % addresses.count]
        case .gaziantep:
            let addresses = [
                "Gaziantep Kalesi, Şahinbey, Gaziantep, Turkey", // Gaziantep Kalesi
                "Zeugma Mozaik Müzesi, Şahinbey, Gaziantep, Turkey", // Zeugma Mozaik Müzesi
                "Bakırcılar Çarşısı, Şahinbey, Gaziantep, Turkey", // Bakırcılar Çarşısı
                "Kurtuluş Cami, Şahinbey, Gaziantep, Turkey", // Kurtuluş Cami
                "Emine Göğüş Mutfak Müzesi, Şahinbey, Gaziantep, Turkey", // Emine Göğüş Mutfak Müzesi
                "Gaziantep Hayvanat Bahçesi, Şahinbey, Gaziantep, Turkey", // Gaziantep Hayvanat Bahçesi
                "Dülük Antik Kenti, Şehitkamil, Gaziantep, Turkey", // Dülük Antik Kenti
                "Yesemek Açık Hava Müzesi, İslahiye, Gaziantep, Turkey", // Yesemek Açık Hava Müzesi
                "Rumkale, Nizip, Gaziantep, Turkey", // Rumkale
                "Gaziantep Botanik Bahçesi, Şahinbey, Gaziantep, Turkey" // Gaziantep Botanik Bahçesi
            ]
            return addresses[index % addresses.count]
        case .konya:
            let addresses = [
                "Mevlana Müzesi, Karatay, Konya, Turkey", // Mevlana Müzesi
                "Alaeddin Camii, Karatay, Konya, Turkey", // Alaeddin Camii
                "Alaeddin Tepesi, Karatay, Konya, Turkey", // Alaeddin Tepesi
                "İnce Minare Medresesi, Karatay, Konya, Turkey", // İnce Minare Medresesi
                "Sırçalı Medrese, Karatay, Konya, Turkey", // Sırçalı Medrese
                "Karatay Medresesi, Karatay, Konya, Turkey", // Karatay Medresesi
                "Şems Camii, Karatay, Konya, Turkey", // Şems Camii
                "Sille Köyü, Selçuklu, Konya, Turkey", // Sille Köyü
                "Çatalhöyük, Çumra, Konya, Turkey", // Çatalhöyük
                "Tuz Gölü, Cihanbeyli, Konya, Turkey" // Tuz Gölü
            ]
            return addresses[index % addresses.count]
        case .mersin:
            let addresses = [
                "Mersin Marina, Yenişehir, Mersin",
                "Mersin Kalesi, Yenişehir, Mersin",
                "Atatürk Parkı, Yenişehir, Mersin",
                "Mersin Müzesi, Yenişehir, Mersin",
                "Tarsus Şelalesi, Tarsus, Mersin",
                "St. Paul Kuyusu, Tarsus, Mersin",
                "Kleopatra Kapısı, Tarsus, Mersin",
                "Uzuncaburç Antik Kenti, Silifke, Mersin",
                "Cennet ve Cehennem Obrukları, Silifke, Mersin",
                "Kızkalesi, Erdemli, Mersin"
            ]
            return addresses[index % addresses.count]


        
        // JAPON
        case .tokyo:
            let addresses = [
                "2-3-1 Asakusa, Taito City, Tokyo, Japan", // Senso-ji Temple
                "1-1-2 Oshiage, Sumida City, Tokyo, Japan", // Tokyo Skytree
                "Shibuya Crossing, 2-1 Dogenzaka, Shibuya City, Tokyo, Japan", // Shibuya Crossing
                "4-2-8 Shibakoen, Minato City, Tokyo, Japan", // Tokyo Tower
                "1-1 Yoyogi Kamizonocho, Shibuya City, Tokyo, Japan", // Meiji Shrine
                "4-16-2 Tsukiji, Chuo City, Tokyo, Japan", // Tsukiji Outer Market
                "Akihabara Electric Town, 1-1 Sotokanda, Chiyoda City, Tokyo, Japan", // Akihabara
                "Ueno Park, 5-20 Uenokoen, Taito City, Tokyo, Japan", // Ueno Park
                "Tokyo Imperial Palace, 1-1 Chiyoda, Chiyoda City, Tokyo, Japan", // Tokyo Imperial Palace
                "Harajuku Takeshita Street, 1-17-7 Jingumae, Shibuya City, Tokyo, Japan" // Harajuku
            ]
            return addresses[index % addresses.count]
        case .osaka:
            let addresses = [
                "1-1 Osakajo, Chuo Ward, Osaka, Japan", // Osaka Castle
                "Dotonbori District, 1-6 Dotonbori, Chuo Ward, Osaka, Japan", // Dotonbori
                "2-1-33 Sakurajima, Konohana Ward, Osaka, Japan", // Universal Studios Japan
                "1-11-18 Shitennoji, Tennoji Ward, Osaka, Japan", // Shitennoji Temple
                "1-1-10 Kaigandori, Minato Ward, Osaka, Japan", // Osaka Aquarium Kaiyukan
                "1-1-88 Oyodonaka, Kita Ward, Osaka, Japan", // Umeda Sky Building
                "1-108 Chausuyama, Tennoji Ward, Osaka, Japan", // Tennoji Zoo
                "2-9-89 Sumiyoshi, Sumiyoshi Ward, Osaka, Japan", // Sumiyoshi Taisha
                "4-1-32 Otemae, Chuo Ward, Osaka, Japan", // Osaka Museum of History
                "2-4-21 Namba, Chuo Ward, Osaka, Japan" // Namba Grand Kagetsu
            ]
            return addresses[index % addresses.count]
        case .kyoto:
            let addresses = [
                "1 Kinkakuji-cho, Kita Ward, Kyoto, Japan", // Kinkaku-ji (Golden Pavilion)
                "68 Fukakusa Yabunouchicho, Fushimi Ward, Kyoto, Japan", // Fushimi Inari Taisha
                "1-294 Kiyomizu, Higashiyama Ward, Kyoto, Japan", // Kiyomizu-dera
                "Arashiyama Bamboo Grove, Saga-Tenryuji, Ukyo Ward, Kyoto, Japan", // Arashiyama Bamboo Grove
                "2 Ginkakuji-cho, Sakyo Ward, Kyoto, Japan", // Ginkaku-ji (Silver Pavilion)
                "541 Nijojo-cho, Nakagyo Ward, Kyoto, Japan", // Nijo Castle
                "13 Ryoanji Goryonoshitacho, Ukyo Ward, Kyoto, Japan", // Ryoan-ji
                "Sagano Romantic Train, Saga-Tenryuji, Ukyo Ward, Kyoto, Japan", // Sagano Romantic Train
                "Philosopher's Path, Ginkakuji-cho, Sakyo Ward, Kyoto, Japan", // Philosopher's Path
                "Gion District, 1-1 Gionmachi Minamigawa, Higashiyama Ward, Kyoto, Japan" // Gion District
            ]
            return addresses[index % addresses.count]
        case .yokohama:
            let addresses = [
                "Yokohama Landmark Tower, 2-2-1 Minatomirai, Nishi Ward, Yokohama, Japan",
                "Yokohama Chinatown, 1-1 Yamashita-cho, Naka Ward, Yokohama, Japan",
                "Yokohama Cosmo World, 2-8-1 Shinko, Naka Ward, Yokohama, Japan",
                "Sankeien Garden, 58-1 Honmokusannotani, Naka Ward, Yokohama, Japan",
                "Yokohama Red Brick Warehouse, 1-1 Shinko, Naka Ward, Yokohama, Japan",
                "Yokohama Marine Tower, 15 Yamashita-cho, Naka Ward, Yokohama, Japan",
                "Yokohama Hakkeijima Sea Paradise, 1-1 Hakkeijima, Kanazawa Ward, Yokohama, Japan",
                "Yokohama Museum of Art, 3-4-1 Minatomirai, Nishi Ward, Yokohama, Japan",
                "Yokohama Stadium, 2975-2 Takashima, Nishi Ward, Yokohama, Japan",
                "Yokohama Ramen Museum, 2-14-21 Shinko, Naka Ward, Yokohama, Japan"
            ]
            return addresses[index % addresses.count]
        case .nagoya:
            let addresses = [
                "Nagoya Castle, 1-1 Honmaru, Naka Ward, Nagoya, Japan",
                "Atsuta Shrine, 1-1-1 Jingu, Atsuta Ward, Nagoya, Japan",
                "Osu Kannon Temple, 2-21-47 Osu, Naka Ward, Nagoya, Japan",
                "Nagoya TV Tower, 3-6-15 Nishiki, Naka Ward, Nagoya, Japan",
                "Nagoya Port Aquarium, 1-3 Minatomachi, Minato Ward, Nagoya, Japan",
                "Tokugawa Art Museum, 1017 Tokugawa-cho, Higashi Ward, Nagoya, Japan",
                "Shirotori Garden, 3-5 Atsuta Nishimachi, Atsuta Ward, Nagoya, Japan",
                "Nagoya City Science Museum, 2-17-1 Sakae, Naka Ward, Nagoya, Japan",
                "Oasis 21, 1-11-1 Higashisakura, Higashi Ward, Nagoya, Japan",
                "Nagoya Station, 1-1-4 Meieki, Nakamura Ward, Nagoya, Japan"
            ]
            return addresses[index % addresses.count]
        case .sapporo:
            let addresses = [
                "Sapporo Clock Tower, 2-chome Kita 1-jo Nishi, Chuo Ward, Sapporo, Japan",
                "Odori Park, Odori, Chuo Ward, Sapporo, Japan",
                "Sapporo TV Tower, 1-chome Odori Nishi, Chuo Ward, Sapporo, Japan",
                "Sapporo Beer Museum, 9-1-1 Kita 7-jo Higashi, Higashi Ward, Sapporo, Japan",
                "Mount Moiwa, Moiwa, Minami Ward, Sapporo, Japan",
                "Sapporo Dome, 1 Hitsujigaoka, Toyohira Ward, Sapporo, Japan",
                "Hokkaido University, 5-chome Kita 8-jo Nishi, Kita Ward, Sapporo, Japan",
                "Sapporo Art Park, Geijutsu-no-mori, Minami Ward, Sapporo, Japan",
                "Maruyama Park, Miyanomori, Chuo Ward, Sapporo, Japan",
                "Sapporo Station, 6-chome Kita 5-jo Nishi, Kita Ward, Sapporo, Japan"
            ]
            return addresses[index % addresses.count]
        case .kobe:
            let addresses = [
                "Kobe Port Tower, 5-5 Hatoba-cho, Chuo Ward, Kobe, Japan",
                "Meriken Park, 2-2 Hatoba-cho, Chuo Ward, Kobe, Japan",
                "Kobe Harborland, 1-3 Higashikawasaki-cho, Chuo Ward, Kobe, Japan",
                "Mount Rokko, Rokko, Nada Ward, Kobe, Japan",
                "Kobe Nunobiki Herb Gardens, 1-4-3 Kitano-cho, Chuo Ward, Kobe, Japan",
                "Kobe City Museum, 24 Kyomachi, Chuo Ward, Kobe, Japan",
                "Kobe Animal Kingdom, 3-1 Rokkodai-cho, Nada Ward, Kobe, Japan",
                "Kobe Maritime Museum, 2-2 Hatoba-cho, Chuo Ward, Kobe, Japan",
                "Kobe Chinatown (Nankinmachi), 1-3-18 Sakaemachi-dori, Chuo Ward, Kobe, Japan",
                "Kobe Oji Zoo, 3-1 Oji-cho, Nada Ward, Kobe, Japan"
            ]
            return addresses[index % addresses.count]
        case .fukuoka:
            let addresses = [
                "Fukuoka Tower, 2-3-26 Momochihama, Sawara Ward, Fukuoka, Japan",
                "Ohori Park, 1-2 Ohori Koen, Chuo Ward, Fukuoka, Japan",
                "Fukuoka Castle Ruins, 1-4 Jonai, Chuo Ward, Fukuoka, Japan",
                "Canal City Hakata, 1-2 Sumiyoshi, Hakata Ward, Fukuoka, Japan",
                "Dazaifu Tenmangu, 4-7-1 Saifu, Dazaifu, Fukuoka, Japan",
                "Fukuoka Yafuoku! Dome, 2-2-2 Jigyohama, Chuo Ward, Fukuoka, Japan",
                "Uminonakamichi Seaside Park, 18-25 Saitozaki, Higashi Ward, Fukuoka, Japan",
                "Fukuoka Art Museum, 1-6 Ohori Koen, Chuo Ward, Fukuoka, Japan",
                "Kushida Shrine, 1-41 Kamikawabatamachi, Hakata Ward, Fukuoka, Japan",
                "Tenjin Underground City, Tenjin, Chuo Ward, Fukuoka, Japan"
            ]
            return addresses[index % addresses.count]


        
        // CHINE
        case .beijing:
            let addresses = [
                "Tiantan Donglu, Dongcheng District, Beijing, China", // Temple of Heaven
                "4 Jingshan Qianjie, Dongcheng District, Beijing, China", // Forbidden City
                "Great Wall at Mutianyu, Huairou District, Beijing, China", // Great Wall at Mutianyu
                "19 Xinjian Gongmen Road, Haidian District, Beijing, China", // Summer Palace
                "Tiananmen Square, Dongcheng District, Beijing, China", // Tiananmen Square
                "13 Guozijian Street, Dongcheng District, Beijing, China", // Temple of Confucius
                "12 Yonghegong Street, Dongcheng District, Beijing, China", // Lama Temple
                "1 Wenjin Street, Xicheng District, Beijing, China", // Beihai Park
                "44 Jingshan West Street, Xicheng District, Beijing, China", // Jingshan Park
                "Hutong Tour, Nanluoguxiang, Dongcheng District, Beijing, China" // Hutong Tour
            ]
            return addresses[index % addresses.count]
        case .shanghai:
            let addresses = [
                "Zhongshan East 1st Road, Huangpu District, Shanghai, China", // The Bund
                "218 Anren Street, Huangpu District, Shanghai, China", // Yu Garden
                "501 Yincheng Middle Road, Lujiazui, Pudong, Shanghai, China", // Shanghai Tower
                "Nanjing Road Pedestrian Street, Huangpu District, Shanghai, China", // Nanjing Road
                "201 Renmin Avenue, Huangpu District, Shanghai, China", // Shanghai Museum
                "210 Taikang Road, Huangpu District, Shanghai, China", // Tianzifang
                "310 Huangzhao Road, Pudong, Shanghai, China", // Shanghai Disneyland
                "100 Century Avenue, Pudong, Shanghai, China", // Shanghai World Financial Center
                "123 Xingye Road, Huangpu District, Shanghai, China", // Xintiandi
                "1388 Lujiazui Ring Road, Pudong, Shanghai, China" // Shanghai Ocean Aquarium
            ]
            return addresses[index % addresses.count]
        case .guangzhou:
            let addresses = [
                "Canton Tower, 222 Yuejiang West Road, Haizhu District, Guangzhou, China",
                "Chen Clan Ancestral Hall, 34 Enlong Li, Zhongshan 7th Road, Liwan District, Guangzhou, China",
                "Baiyun Mountain Scenic Area, Baiyun District, Guangzhou, China",
                "Guangzhou Opera House, 1 Zhujiang West Road, Zhujiang New Town, Tianhe District, Guangzhou, China",
                "Sacred Heart Cathedral, 56 Yide Road, Yuexiu District, Guangzhou, China",
                "Guangzhou Museum, 2 Yuexiu South Road, Yuexiu District, Guangzhou, China",
                "Sun Yat-sen Memorial Hall, 259 Dongfeng Middle Road, Yuexiu District, Guangzhou, China",
                "Guangzhou Zoo, 120 Xianlie Middle Road, Yuexiu District, Guangzhou, China",
                "Shamian Island, Liwan District, Guangzhou, China",
                "Guangzhou Library, 39 Zhujiang East Road, Tianhe District, Guangzhou, China"
            ]
            return addresses[index % addresses.count]
        case .shenzhen:
            let addresses = [
                "Window of the World, 9037 Shennan Boulevard, Nanshan District, Shenzhen, China",
                "OCT Loft, 8 North Zhongshan Road, Nanshan District, Shenzhen, China",
                "Shenzhen Museum, 6 Tonggu Road, Futian District, Shenzhen, China",
                "Dameisha Beach, Yantian District, Shenzhen, China",
                "Shenzhen Bay Park, Nanshan District, Shenzhen, China",
                "Splendid China Folk Culture Village, 9003 Shennan Boulevard, Nanshan District, Shenzhen, China",
                "Shenzhen Library, 2002 Fuzhong 1st Road, Futian District, Shenzhen, China",
                "Lianhuashan Park, Futian District, Shenzhen, China",
                "Shenzhen Art Museum, 6 Tonggu Road, Futian District, Shenzhen, China",
                "Shenzhen Civic Center, 2002 Fuzhong 1st Road, Futian District, Shenzhen, China"
            ]
            return addresses[index % addresses.count]
        case .chengdu:
            let addresses = [
                "Giant Panda Breeding Research Base, 1375 Panda Road, Chenghua District, Chengdu, China",
                "Leshan Giant Buddha, Leshan, Sichuan, China",
                "Mount Emei, Emeishan, Sichuan, China",
                "Wuhou Temple, 231 Wuhouci Street, Wuhou District, Chengdu, China",
                "Du Fu Thatched Cottage, 37 Qinghua Road, Qingyang District, Chengdu, China",
                "Chengdu Research Base of Giant Panda Breeding, 1375 Panda Road, Chenghua District, Chengdu, China",
                "Kuanzhai Alley, Qingyang District, Chengdu, China",
                "Chengdu Museum, 1 Tianfu Square, Qingyang District, Chengdu, China",
                "Jinsha Site Museum, 227 Jinsha Site Road, Qingyang District, Chengdu, China",
                "Chengdu Zoo, 234 Zoo Road, Chenghua District, Chengdu, China"
            ]
            return addresses[index % addresses.count]
        case .xian:
            let addresses = [
                "Terracotta Warriors Museum, Lintong District, Xi'an, China",
                "Ancient City Wall, Xi'an, China",
                "Muslim Quarter, Xi'an, China",
                "Great Mosque, 30 Huajue Lane, Xi'an, China",
                "Bell Tower, 2 Beiyuanmen, Xi'an, China",
                "Drum Tower, 2 Beiyuanmen, Xi'an, China",
                "Wild Goose Pagoda, 2 Yanta South Road, Xi'an, China",
                "Shaanxi History Museum, 91 Xiaozhai East Road, Xi'an, China",
                "Huaqing Palace, Lintong District, Xi'an, China",
                "Banpo Museum, Banpo Village, Xi'an, China"
            ]
            return addresses[index % addresses.count]

        case .nanjing:
            let addresses = [
                "Sun Yat-sen Mausoleum, 7 Linggu Road, Nanjing, China",
                "Confucius Temple, 1 Pingjiangfu Road, Nanjing, China",
                "Nanjing Museum, 321 Zhongshan East Road, Nanjing, China",
                "Ming Xiaoling Mausoleum, Nanjing, China",
                "Nanjing City Wall, Nanjing, China",
                "Xuanwu Lake, Nanjing, China",
                "Nanjing Massacre Memorial Hall, 418 Shuiximen Street, Nanjing, China",
                "Nanjing Presidential Palace, 292 Changjiang Road, Nanjing, China",
                "Nanjing Zoo, 60 Hanzhong Road, Nanjing, China",
                "Nanjing Library, 189 Zhongshan East Road, Nanjing, China"
            ]
            return addresses[index % addresses.count]

        // ITALIE
        case .rome:
            let addresses = [
                "Piazza del Colosseo, 1, 00184 Roma RM, Italy", // Colisée
                "Via della Salara Vecchia, 5/6, 00186 Roma RM, Italy", // Forum Romain
                "Viale Vaticano, 00165 Roma RM, Italy", // Vatican
                "Piazza di Trevi, 00187 Roma RM, Italy", // Fontaine de Trevi
                "Piazza della Rotonda, 00186 Roma RM, Italy", // Panthéon
                "Piazza di Spagna, 00187 Roma RM, Italy", // Place d'Espagne
                "Lungotevere Castello, 50, 00193 Roma RM, Italy", // Château Saint-Ange
                "Piazza Navona, 00186 Roma RM, Italy", // Place Navone
                "Via del Corso, 00186 Roma RM, Italy", // Via del Corso
                "Piazza Venezia, 00186 Roma RM, Italy" // Monument à Victor-Emmanuel II
            ]
            return addresses[index % addresses.count]

        case .milan:
            let addresses = [
                "Piazza del Duomo, 20122 Milano MI, Italy", // Cathédrale de Milan
                "Via Santa Maria delle Grazie, 2, 20123 Milano MI, Italy", // Santa Maria delle Grazie
                "Via Filodrammatici, 2, 20121 Milano MI, Italy", // Teatro alla Scala
                "Piazza della Scala, 20121 Milano MI, Italy", // Place de la Scala
                "Via Monte Napoleone, 20121 Milano MI, Italy", // Via Monte Napoleone
                "Piazza Gae Aulenti, 20124 Milano MI, Italy", // Piazza Gae Aulenti
                "Via Torino, 20123 Milano MI, Italy", // Galleria Vittorio Emanuele II
                "Piazza Castello, 20121 Milano MI, Italy", // Château des Sforza
                "Via Brera, 28, 20121 Milano MI, Italy", // Pinacothèque de Brera
                "Parco Sempione, 20154 Milano MI, Italy" // Parc Sempione
            ]
            return addresses[index % addresses.count]

        case .naples:
            let addresses = [
                "Piazza del Plebiscito, 80132 Napoli NA, Italy", // Place du Plébiscite
                "Via Toledo, 80134 Napoli NA, Italy", // Via Toledo
                "Piazza San Domenico Maggiore, 80134 Napoli NA, Italy", // Piazza San Domenico
                "Via San Gregorio Armeno, 80138 Napoli NA, Italy", // Via San Gregorio Armeno
                "Piazza del Gesù Nuovo, 80134 Napoli NA, Italy", // Église du Gesù Nuovo
                "Via Duomo, 80138 Napoli NA, Italy", // Cathédrale de Naples
                "Castel dell'Ovo, 80132 Napoli NA, Italy", // Château de l'Œuf
                "Via Posillipo, 80123 Napoli NA, Italy", // Via Posillipo
                "Piazza Bellini, 80138 Napoli NA, Italy", // Piazza Bellini
                "Via Chiaia, 80121 Napoli NA, Italy" // Via Chiaia
            ]
            return addresses[index % addresses.count]

        case .turin:
            let addresses = [
                "Piazza Castello, 10122 Torino TO, Italy", // Place du Château
                "Via Roma, 10123 Torino TO, Italy", // Via Roma
                "Piazza San Carlo, 10123 Torino TO, Italy", // Place Saint-Charles
                "Via Po, 10124 Torino TO, Italy", // Via Po
                "Piazza Vittorio Veneto, 10124 Torino TO, Italy", // Place Victor-Emmanuel
                "Via Garibaldi, 10122 Torino TO, Italy", // Via Garibaldi
                "Piazza Carignano, 10123 Torino TO, Italy", // Place Carignano
                "Via Lagrange, 10123 Torino TO, Italy", // Via Lagrange
                "Piazza Statuto, 10122 Torino TO, Italy", // Place Statuto
                "Via Pietro Micca, 10122 Torino TO, Italy" // Via Pietro Micca
            ]
            return addresses[index % addresses.count]

        case .palermo:
            let addresses = [
                "Piazza Pretoria, 90133 Palermo PA, Italy", // Place Pretoria
                "Via Maqueda, 90133 Palermo PA, Italy", // Via Maqueda
                "Piazza Bellini, 90133 Palermo PA, Italy", // Place Bellini
                "Via Vittorio Emanuele, 90133 Palermo PA, Italy", // Via Vittorio Emanuele
                "Piazza Marina, 90133 Palermo PA, Italy", // Place Marina
                "Via Alloro, 90133 Palermo PA, Italy", // Via Alloro
                "Piazza San Domenico, 90133 Palermo PA, Italy", // Place San Domenico
                "Via Roma, 90133 Palermo PA, Italy", // Via Roma
                "Piazza Bologni, 90133 Palermo PA, Italy", // Place Bologni
                "Via Cavour, 90133 Palermo PA, Italy" // Via Cavour
            ]
            return addresses[index % addresses.count]

        case .genoa:
            let addresses = [
                "Via Garibaldi, 16124 Genova GE, Italy", // Via Garibaldi
                "Piazza De Ferrari, 16121 Genova GE, Italy", // Place De Ferrari
                "Via San Lorenzo, 16123 Genova GE, Italy", // Cathédrale San Lorenzo
                "Via Balbi, 16126 Genova GE, Italy", // Via Balbi
                "Piazza San Matteo, 16123 Genova GE, Italy", // Place San Matteo
                "Via del Campo, 16123 Genova GE, Italy", // Via del Campo
                "Piazza Banchi, 16123 Genova GE, Italy", // Place Banchi
                "Via San Bernardo, 16123 Genova GE, Italy", // Via San Bernardo
                "Piazza delle Vigne, 16123 Genova GE, Italy", // Place delle Vigne
                "Via di Prè, 16126 Genova GE, Italy" // Via di Prè
            ]
            return addresses[index % addresses.count]

        case .bologna:
            let addresses = [
                "Piazza Maggiore, 40124 Bologna BO, Italy", // Place Maggiore
                "Via Rizzoli, 40125 Bologna BO, Italy", // Via Rizzoli
                "Piazza Santo Stefano, 40125 Bologna BO, Italy", // Place Santo Stefano
                "Via dell'Indipendenza, 40121 Bologna BO, Italy", // Via dell'Indipendenza
                "Piazza San Domenico, 40124 Bologna BO, Italy", // Place San Domenico
                "Via Zamboni, 40126 Bologna BO, Italy", // Via Zamboni
                "Piazza Galvani, 40124 Bologna BO, Italy", // Place Galvani
                "Via San Vitale, 40125 Bologna BO, Italy", // Via San Vitale
                "Piazza della Mercanzia, 40125 Bologna BO, Italy", // Place della Mercanzia
                "Via Ugo Bassi, 40123 Bologna BO, Italy" // Via Ugo Bassi
            ]
            return addresses[index % addresses.count]

        case .florence:
            let addresses = [
                "Piazza del Duomo, 50122 Firenze FI, Italy", // Cathédrale Santa Maria del Fiore
                "Piazza della Signoria, 50122 Firenze FI, Italy", // Place de la Seigneurie
                "Ponte Vecchio, 50125 Firenze FI, Italy", // Ponte Vecchio
                "Piazzale degli Uffizi, 6, 50122 Firenze FI, Italy", // Galerie des Offices
                "Piazza Santa Croce, 50122 Firenze FI, Italy", // Place Santa Croce
                "Via de' Tornabuoni, 50123 Firenze FI, Italy", // Via de' Tornabuoni
                "Piazza della Repubblica, 50123 Firenze FI, Italy", // Place de la République
                "Piazza San Lorenzo, 50123 Firenze FI, Italy", // Place San Lorenzo
                "Piazza Pitti, 50125 Firenze FI, Italy", // Place Pitti
                "Piazza Santo Spirito, 50125 Firenze FI, Italy" // Place Santo Spirito
            ]
            return addresses[index % addresses.count]

        case .bari:
            let addresses = [
                "Piazza del Ferrarese, 70122 Bari BA, Italy", // Place del Ferrarese
                "Via Sparano da Bari, 70122 Bari BA, Italy", // Via Sparano
                "Piazza Mercantile, 70122 Bari BA, Italy", // Place Mercantile
                "Via Arco Basso, 70122 Bari BA, Italy", // Via Arco Basso
                "Piazza San Nicola, 70122 Bari BA, Italy", // Place San Nicola
                "Via Venezia, 70122 Bari BA, Italy", // Via Venezia
                "Piazza Massari, 70122 Bari BA, Italy", // Place Massari
                "Via Carmine, 70122 Bari BA, Italy", // Via Carmine
                "Piazza del Sud, 70122 Bari BA, Italy", // Place del Sud
                "Via Napoli, 70122 Bari BA, Italy" // Via Napoli
            ]
            return addresses[index % addresses.count]

        case .catania:
            let addresses = [
                "Piazza del Duomo, 95124 Catania CT, Italy", // Place du Duomo
                "Via Etnea, 95124 Catania CT, Italy", // Via Etnea
                "Piazza Università, 95124 Catania CT, Italy", // Place de l'Université
                "Via dei Crociferi, 95124 Catania CT, Italy", // Via dei Crociferi
                "Piazza Stesicoro, 95124 Catania CT, Italy", // Place Stesicoro
                "Via San Giuliano, 95124 Catania CT, Italy", // Via San Giuliano
                "Piazza San Francesco, 95124 Catania CT, Italy", // Place San Francesco
                "Via Garibaldi, 95124 Catania CT, Italy", // Via Garibaldi
                "Piazza Carlo Alberto, 95124 Catania CT, Italy", // Place Carlo Alberto
                "Via Vittorio Emanuele II, 95124 Catania CT, Italy" // Via Vittorio Emanuele II
            ]
            return addresses[index % addresses.count]

        // ESPAGNE
        case .madrid:
            let addresses = [
                "Plaza Mayor, 28012 Madrid, Spain", // Plaza Mayor
                "Puerta del Sol, 28013 Madrid, Spain", // Puerta del Sol
                "Paseo del Prado, 28014 Madrid, Spain", // Musée du Prado
                "Plaza de Cibeles, 28014 Madrid, Spain", // Place de Cibeles
                "Gran Vía, 28013 Madrid, Spain", // Gran Vía
                "Plaza de España, 28008 Madrid, Spain", // Place d'Espagne
                "Calle de Alcalá, 28014 Madrid, Spain", // Calle de Alcalá
                "Plaza de Oriente, 28013 Madrid, Spain", // Place d'Orient
                "Calle de la Princesa, 28008 Madrid, Spain", // Calle de la Princesa
                "Paseo de la Castellana, 28046 Madrid, Spain" // Paseo de la Castellana
            ]
            return addresses[index % addresses.count]

        case .barcelona:
            let addresses = [
                "Plaça de Catalunya, 08002 Barcelona, Spain", // Place de Catalogne
                "La Rambla, 08002 Barcelona, Spain", // La Rambla
                "Passeig de Gràcia, 08008 Barcelona, Spain", // Passeig de Gràcia
                "Plaça Reial, 08002 Barcelona, Spain", // Place Royale
                "Carrer de Montcada, 08003 Barcelona, Spain", // Carrer de Montcada
                "Plaça del Pi, 08002 Barcelona, Spain", // Place du Pin
                "Carrer de la Boqueria, 08002 Barcelona, Spain", // Carrer de la Boqueria
                "Plaça de Sant Jaume, 08002 Barcelona, Spain", // Place Sant Jaume
                "Carrer de Ferran, 08002 Barcelona, Spain", // Carrer de Ferran
                "Plaça de Sant Felip Neri, 08002 Barcelona, Spain" // Place Sant Felip Neri
            ]
            return addresses[index % addresses.count]

        case .valencia:
            let addresses = [
                "Plaza de la Virgen, 46001 Valencia, Spain", // Place de la Vierge
                "Plaza de la Reina, 46001 Valencia, Spain", // Place de la Reine
                "Calle de la Paz, 46003 Valencia, Spain", // Calle de la Paz
                "Plaza del Ayuntamiento, 46002 Valencia, Spain", // Place de l'Hôtel de Ville
                "Calle de Colón, 46004 Valencia, Spain", // Calle de Colón
                "Plaza de Toros, 46010 Valencia, Spain", // Plaza de Toros
                "Calle de la Lonja, 46001 Valencia, Spain", // Calle de la Lonja
                "Plaza de San Vicente Ferrer, 46001 Valencia, Spain", // Place San Vicente Ferrer
                "Calle de Serranos, 46003 Valencia, Spain", // Calle de Serranos
                "Plaza de la Almoina, 46001 Valencia, Spain" // Place de l'Almoina
            ]
            return addresses[index % addresses.count]

        case .seville:
            let addresses = [
                "Plaza de España, 41013 Sevilla, Spain", // Place d'Espagne
                "Calle Sierpes, 41004 Sevilla, Spain", // Calle Sierpes
                "Plaza de San Francisco, 41004 Sevilla, Spain", // Place San Francisco
                "Calle Tetuán, 41001 Sevilla, Spain", // Calle Tetuán
                "Plaza del Triunfo, 41004 Sevilla, Spain", // Place du Triomphe
                "Calle de la Feria, 41003 Sevilla, Spain", // Calle de la Feria
                "Plaza de la Alfalfa, 41004 Sevilla, Spain", // Place de l'Alfalfa
                "Calle de la Cuna, 41004 Sevilla, Spain", // Calle de la Cuna
                "Plaza de San Lorenzo, 41003 Sevilla, Spain", // Place San Lorenzo
                "Calle de la Feria, 41003 Sevilla, Spain" // Calle de la Feria
            ]
            return addresses[index % addresses.count]

        case .zaragoza:
            let addresses = [
                "Plaza del Pilar, 50003 Zaragoza, Spain", // Place du Pilar
                "Calle Alfonso I, 50003 Zaragoza, Spain", // Calle Alfonso I
                "Plaza de San Felipe, 50003 Zaragoza, Spain", // Place San Felipe
                "Calle de Don Jaime I, 50001 Zaragoza, Spain", // Calle de Don Jaime I
                "Plaza de la Seo, 50001 Zaragoza, Spain", // Place de la Seo
                "Calle de San Jorge, 50001 Zaragoza, Spain", // Calle de San Jorge
                "Plaza de San Miguel, 50001 Zaragoza, Spain", // Place San Miguel
                "Calle de la Verónica, 50001 Zaragoza, Spain", // Calle de la Verónica
                "Plaza de San Nicolás, 50001 Zaragoza, Spain", // Place San Nicolás
                "Calle de San Pablo, 50003 Zaragoza, Spain" // Calle de San Pablo
            ]
            return addresses[index % addresses.count]

        case .malaga:
            let addresses = [
                "Plaza de la Constitución, 29005 Málaga, Spain", // Place de la Constitution
                "Calle Larios, 29005 Málaga, Spain", // Calle Larios
                "Plaza de la Merced, 29012 Málaga, Spain", // Place de la Merced
                "Calle Granada, 29015 Málaga, Spain", // Calle Granada
                "Plaza de Uncibay, 29008 Málaga, Spain", // Place Uncibay
                "Calle San Agustín, 29015 Málaga, Spain", // Calle San Agustín
                "Plaza de la Marina, 29001 Málaga, Spain", // Place de la Marina
                "Calle de la Victoria, 29012 Málaga, Spain", // Calle de la Victoria
                "Plaza de San Pedro de Alcántara, 29008 Málaga, Spain", // Place San Pedro
                "Calle de la Trinidad, 29005 Málaga, Spain" // Calle de la Trinidad
            ]
            return addresses[index % addresses.count]

        case .murcia:
            let addresses = [
                "Plaza de Cardenal Belluga, 30001 Murcia, Spain", // Place du Cardinal Belluga
                "Calle Trapería, 30001 Murcia, Spain", // Calle Trapería
                "Plaza de San Bartolomé, 30001 Murcia, Spain", // Place San Bartolomé
                "Calle de la Merced, 30001 Murcia, Spain", // Calle de la Merced
                "Plaza de las Flores, 30001 Murcia, Spain", // Place des Fleurs
                "Calle de la Platería, 30001 Murcia, Spain", // Calle de la Platería
                "Plaza de Santo Domingo, 30001 Murcia, Spain", // Place Santo Domingo
                "Calle de la Aurora, 30001 Murcia, Spain", // Calle de la Aurora
                "Plaza de San Nicolás, 30001 Murcia, Spain", // Place San Nicolás
                "Calle de la Gloria, 30001 Murcia, Spain" // Calle de la Gloria
            ]
            return addresses[index % addresses.count]

        case .palma:
            let addresses = [
                "Plaça de Cort, 07001 Palma, Illes Balears, Spain", // Place de Cort
                "Carrer de la Portella, 07001 Palma, Illes Balears, Spain", // Carrer de la Portella
                "Plaça Major, 07001 Palma, Illes Balears, Spain", // Place Major
                "Carrer de Sant Miquel, 07002 Palma, Illes Balears, Spain", // Carrer de Sant Miquel
                "Plaça de Santa Eulàlia, 07001 Palma, Illes Balears, Spain", // Place Santa Eulàlia
                "Carrer de la Llotja, 07001 Palma, Illes Balears, Spain", // Carrer de la Llotja
                "Plaça de la Reina, 07001 Palma, Illes Balears, Spain", // Place de la Reine
                "Carrer de la Concepció, 07001 Palma, Illes Balears, Spain", // Carrer de la Concepció
                "Plaça de Sant Francesc, 07001 Palma, Illes Balears, Spain", // Place Sant Francesc
                "Carrer de la Porta de l'Almudaina, 07001 Palma, Illes Balears, Spain" // Carrer de la Porta
            ]
            return addresses[index % addresses.count]

        case .lasPalmas:
            let addresses = [
                "Plaza de Santa Ana, 35001 Las Palmas de Gran Canaria, Spain", // Place Santa Ana
                "Calle Mayor de Triana, 35001 Las Palmas de Gran Canaria, Spain", // Calle Mayor de Triana
                "Plaza de San Telmo, 35001 Las Palmas de Gran Canaria, Spain", // Place San Telmo
                "Calle de Pérez Galdós, 35001 Las Palmas de Gran Canaria, Spain", // Calle de Pérez Galdós
                "Plaza de San Francisco, 35001 Las Palmas de Gran Canaria, Spain", // Place San Francisco
                "Calle de Vegueta, 35001 Las Palmas de Gran Canaria, Spain", // Calle de Vegueta
                "Plaza de Santo Domingo, 35001 Las Palmas de Gran Canaria, Spain", // Place Santo Domingo
                "Calle de la Catedral, 35001 Las Palmas de Gran Canaria, Spain", // Calle de la Catedral
                "Plaza de San Agustín, 35001 Las Palmas de Gran Canaria, Spain", // Place San Agustín
                "Calle de la Audiencia, 35001 Las Palmas de Gran Canaria, Spain" // Calle de la Audiencia
            ]
            return addresses[index % addresses.count]

        case .bilbao:
            let addresses = [
                "Plaza Nueva, 48005 Bilbao, Spain", // Place Neuve
                "Calle de la Ribera, 48005 Bilbao, Spain", // Calle de la Ribera
                "Plaza de Unamuno, 48006 Bilbao, Spain", // Place Unamuno
                "Calle de la Cruz, 48005 Bilbao, Spain", // Calle de la Cruz
                "Plaza de San Nicolás, 48005 Bilbao, Spain", // Place San Nicolás
                "Calle de la Pelota, 48005 Bilbao, Spain", // Calle de la Pelota
                "Plaza de la Encarnación, 48006 Bilbao, Spain", // Place de l'Incarnation
                "Calle de la Tendería, 48005 Bilbao, Spain", // Calle de la Tendería
                "Plaza de Santiago, 48005 Bilbao, Spain", // Place Santiago
                "Calle de la Sendeja, 48005 Bilbao, Spain" // Calle de la Sendeja
            ]
            return addresses[index % addresses.count]

        // PAYS-BAS
        case .amsterdam:
            let addresses = [
                "Dam, 1012 Amsterdam, Netherlands", // Place du Dam
                "Prinsengracht, 1015 Amsterdam, Netherlands", // Prinsengracht
                "Herengracht, 1017 Amsterdam, Netherlands", // Herengracht
                "Keizersgracht, 1015 Amsterdam, Netherlands", // Keizersgracht
                "Leidseplein, 1017 Amsterdam, Netherlands", // Leidseplein
                "Museumplein, 1071 Amsterdam, Netherlands", // Museumplein
                "Rembrandtplein, 1017 Amsterdam, Netherlands", // Rembrandtplein
                "Waterlooplein, 1011 Amsterdam, Netherlands", // Waterlooplein
                "Nieuwmarkt, 1011 Amsterdam, Netherlands", // Nieuwmarkt
                "Spui, 1012 Amsterdam, Netherlands" // Spui
            ]
            return addresses[index % addresses.count]

        case .rotterdam:
            let addresses = [
                "Coolsingel, 3011 Rotterdam, Netherlands", // Coolsingel
                "Blaak, 3011 Rotterdam, Netherlands", // Blaak
                "Hoogstraat, 3011 Rotterdam, Netherlands", // Hoogstraat
                "Lijnbaan, 3012 Rotterdam, Netherlands", // Lijnbaan
                "Coolsingel, 3011 Rotterdam, Netherlands", // Coolsingel
                "Blaak, 3011 Rotterdam, Netherlands", // Blaak
                "Hoogstraat, 3011 Rotterdam, Netherlands", // Hoogstraat
                "Lijnbaan, 3012 Rotterdam, Netherlands", // Lijnbaan
                "Coolsingel, 3011 Rotterdam, Netherlands", // Coolsingel
                "Blaak, 3011 Rotterdam, Netherlands" // Blaak
            ]
            return addresses[index % addresses.count]

        case .theHague:
            let addresses = [
                "Binnenhof, 2513 The Hague, Netherlands", // Binnenhof
                "Noordeinde, 2514 The Hague, Netherlands", // Noordeinde
                "Grote Marktstraat, 2511 The Hague, Netherlands", // Grote Marktstraat
                "Lange Voorhout, 2514 The Hague, Netherlands", // Lange Voorhout
                "Plein, 2511 The Hague, Netherlands", // Plein
                "Grote Markt, 2511 The Hague, Netherlands", // Grote Markt
                "Noordeinde, 2514 The Hague, Netherlands", // Noordeinde
                "Lange Voorhout, 2514 The Hague, Netherlands", // Lange Voorhout
                "Plein, 2511 The Hague, Netherlands", // Plein
                "Grote Markt, 2511 The Hague, Netherlands" // Grote Markt
            ]
            return addresses[index % addresses.count]

        case .utrecht:
            let addresses = [
                "Domplein, 3512 Utrecht, Netherlands", // Domplein
                "Oudegracht, 3511 Utrecht, Netherlands", // Oudegracht
                "Neude, 3512 Utrecht, Netherlands", // Neude
                "Stadhuisbrug, 3511 Utrecht, Netherlands", // Stadhuisbrug
                "Domplein, 3512 Utrecht, Netherlands", // Domplein
                "Oudegracht, 3511 Utrecht, Netherlands", // Oudegracht
                "Neude, 3512 Utrecht, Netherlands", // Neude
                "Stadhuisbrug, 3511 Utrecht, Netherlands", // Stadhuisbrug
                "Domplein, 3512 Utrecht, Netherlands", // Domplein
                "Oudegracht, 3511 Utrecht, Netherlands" // Oudegracht
            ]
            return addresses[index % addresses.count]

        case .eindhoven:
            let addresses = [
                "Markt, 5611 Eindhoven, Netherlands", // Place du Marché
                "Stratumseind, 5611 Eindhoven, Netherlands", // Stratumseind
                "Dommelstraat, 5611 Eindhoven, Netherlands", // Dommelstraat
                "Rechtestraat, 5611 Eindhoven, Netherlands", // Rechtestraat
                "Kleine Berg, 5611 Eindhoven, Netherlands", // Kleine Berg
                "Bergstraat, 5611 Eindhoven, Netherlands", // Bergstraat
                "Vrijstraat, 5611 Eindhoven, Netherlands", // Vrijstraat
                "Hoogstraat, 5611 Eindhoven, Netherlands", // Hoogstraat
                "Kerkstraat, 5611 Eindhoven, Netherlands", // Kerkstraat
                "Wal, 5611 Eindhoven, Netherlands" // Wal
            ]
            return addresses[index % addresses.count]

        case .tilburg:
            let addresses = [
                "Heuvel, 5038 Tilburg, Netherlands", // Place Heuvel
                "Korvelseweg, 5038 Tilburg, Netherlands", // Korvelseweg
                "Noordstraat, 5038 Tilburg, Netherlands", // Noordstraat
                "Oude Markt, 5038 Tilburg, Netherlands", // Oude Markt
                "Stationsstraat, 5038 Tilburg, Netherlands", // Stationsstraat
                "Korte Schijfstraat, 5038 Tilburg, Netherlands", // Korte Schijfstraat
                "Lange Schijfstraat, 5038 Tilburg, Netherlands", // Lange Schijfstraat
                "Kerkstraat, 5038 Tilburg, Netherlands", // Kerkstraat
                "Gasthuisstraat, 5038 Tilburg, Netherlands", // Gasthuisstraat
                "Willem II Straat, 5038 Tilburg, Netherlands" // Willem II Straat
            ]
            return addresses[index % addresses.count]

        case .groningen:
            let addresses = [
                "Grote Markt, 9711 Groningen, Netherlands", // Grote Markt
                "Vismarkt, 9711 Groningen, Netherlands", // Vismarkt
                "Oude Kijk in 't Jatstraat, 9712 Groningen, Netherlands", // Oude Kijk in 't Jatstraat
                "Herestraat, 9711 Groningen, Netherlands", // Herestraat
                "Grote Kromme Elleboog, 9711 Groningen, Netherlands", // Grote Kromme Elleboog
                "Kleine Kromme Elleboog, 9711 Groningen, Netherlands", // Kleine Kromme Elleboog
                "Poelestraat, 9711 Groningen, Netherlands", // Poelestraat
                "Oosterstraat, 9711 Groningen, Netherlands", // Oosterstraat
                "Folkingestraat, 9711 Groningen, Netherlands", // Folkingestraat
                "Gelkingestraat, 9711 Groningen, Netherlands" // Gelkingestraat
            ]
            return addresses[index % addresses.count]

        case .breda:
            let addresses = [
                "Grote Markt, 4811 Breda, Netherlands", // Grote Markt
                "Haagdijk, 4811 Breda, Netherlands", // Haagdijk
                "Veemarktstraat, 4811 Breda, Netherlands", // Veemarktstraat
                "Ginnekensstraat, 4811 Breda, Netherlands", // Ginnekensstraat
                "Torenstraat, 4811 Breda, Netherlands", // Torenstraat
                "Halstraat, 4811 Breda, Netherlands", // Halstraat
                "Catharinastraat, 4811 Breda, Netherlands", // Catharinastraat
                "Boschstraat, 4811 Breda, Netherlands", // Boschstraat
                "Veerstraat, 4811 Breda, Netherlands", // Veerstraat
                "Kerkstraat, 4811 Breda, Netherlands" // Kerkstraat
            ]
            return addresses[index % addresses.count]

        case .nijmegen:
            let addresses = [
                "Grote Markt, 6511 Nijmegen, Netherlands", // Grote Markt
                "Burchtstraat, 6511 Nijmegen, Netherlands", // Burchtstraat
                "Lange Hezelstraat, 6511 Nijmegen, Netherlands", // Lange Hezelstraat
                "Korte Burchtstraat, 6511 Nijmegen, Netherlands", // Korte Burchtstraat
                "Marikenstraat, 6511 Nijmegen, Netherlands", // Marikenstraat
                "Broerstraat, 6511 Nijmegen, Netherlands", // Broerstraat
                "Houtstraat, 6511 Nijmegen, Netherlands", // Houtstraat
                "Sint Stevenskerkhof, 6511 Nijmegen, Netherlands", // Sint Stevenskerkhof
                "Kelfkensbos, 6511 Nijmegen, Netherlands", // Kelfkensbos
                "Mariënburg, 6511 Nijmegen, Netherlands" // Mariënburg
            ]
            return addresses[index % addresses.count]

        case .enschede:
            let addresses = [
                "Grote Markt, 7511 Enschede, Netherlands", // Grote Markt
                "Oude Markt, 7511 Enschede, Netherlands", // Oude Markt
                "Langestraat, 7511 Enschede, Netherlands", // Langestraat
                "Korte Hengelosestraat, 7511 Enschede, Netherlands", // Korte Hengelosestraat
                "Lange Hengelosestraat, 7511 Enschede, Netherlands", // Lange Hengelosestraat
                "Kerkstraat, 7511 Enschede, Netherlands", // Kerkstraat
                "Walstraat, 7511 Enschede, Netherlands", // Walstraat
                "Haaksbergerstraat, 7511 Enschede, Netherlands", // Haaksbergerstraat
                "Van Heekstraat, 7511 Enschede, Netherlands", // Van Heekstraat
                "Boddenstraat, 7511 Enschede, Netherlands" // Boddenstraat
            ]
            return addresses[index % addresses.count]

        // ROYAUME-UNI
        case .london:
            let addresses = [
                "Trafalgar Square, London WC2N 5DN, UK", // Trafalgar Square
                "Buckingham Palace, London SW1A 1AA, UK", // Buckingham Palace
                "Big Ben, London SW1A 0AA, UK", // Big Ben
                "Tower Bridge, London SE1 2UP, UK", // Tower Bridge
                "Piccadilly Circus, London W1D 7DH, UK", // Piccadilly Circus
                "Covent Garden, London WC2E 8RF, UK", // Covent Garden
                "Leicester Square, London WC2H 7NA, UK", // Leicester Square
                "Oxford Street, London W1C 1AP, UK", // Oxford Street
                "Regent Street, London W1B 4HA, UK", // Regent Street
                "Carnaby Street, London W1F 9PB, UK" // Carnaby Street
            ]
            return addresses[index % addresses.count]

        case .birmingham:
            let addresses = [
                "Victoria Square, Birmingham B1 1BD, UK", // Victoria Square
                "Bullring, Birmingham B5 4BU, UK", // Bullring
                "New Street, Birmingham B2 4PA, UK", // New Street
                "High Street, Birmingham B4 7SL, UK", // High Street
                "Corporation Street, Birmingham B2 4LP, UK", // Corporation Street
                "Colmore Row, Birmingham B3 2QB, UK", // Colmore Row
                "Church Street, Birmingham B3 2NP, UK", // Church Street
                "Carrs Lane, Birmingham B4 7SX, UK", // Carrs Lane
                "Digbeth, Birmingham B5 6DR, UK", // Digbeth
                "Jewellery Quarter, Birmingham B18 6HA, UK" // Jewellery Quarter
            ]
            return addresses[index % addresses.count]

        case .leeds:
            let addresses = [
                "City Square, Leeds LS1 2ES, UK", // City Square
                "Briggate, Leeds LS1 6HD, UK", // Briggate
                "Headrow, Leeds LS1 6PU, UK", // Headrow
                "Kirkgate, Leeds LS1 6TS, UK", // Kirkgate
                "Call Lane, Leeds LS1 7BT, UK", // Call Lane
                "Merrion Street, Leeds LS2 8LY, UK", // Merrion Street
                "Albion Street, Leeds LS1 5ER, UK", // Albion Street
                "Park Row, Leeds LS1 5JF, UK", // Park Row
                "Boar Lane, Leeds LS1 6HW, UK", // Boar Lane
                "Commercial Street, Leeds LS1 6ER, UK" // Commercial Street
            ]
            return addresses[index % addresses.count]

        case .glasgow:
            let addresses = [
                "George Square, Glasgow G2 1DU, UK", // George Square
                "Buchanan Street, Glasgow G1 2FF, UK", // Buchanan Street
                "Sauchiehall Street, Glasgow G2 3EW, UK", // Sauchiehall Street
                "Argyle Street, Glasgow G2 8AG, UK", // Argyle Street
                "Royal Exchange Square, Glasgow G1 3AH, UK", // Royal Exchange Square
                "St Vincent Street, Glasgow G2 5TF, UK", // St Vincent Street
                "Ingram Street, Glasgow G1 1XS, UK", // Ingram Street
                "Trongate, Glasgow G1 5HD, UK", // Trongate
                "Candleriggs, Glasgow G1 1NP, UK", // Candleriggs
                "Saltmarket, Glasgow G1 5LF, UK" // Saltmarket
            ]
            return addresses[index % addresses.count]

        case .sheffield:
            let addresses = [
                "Fargate, Sheffield S1 2HE, UK", // Fargate
                "The Moor, Sheffield S1 4PF, UK", // The Moor
                "High Street, Sheffield S1 2GA, UK", // High Street
                "Division Street, Sheffield S1 4GF, UK", // Division Street
                "West Street, Sheffield S1 4EW, UK", // West Street
                "Ecclesall Road, Sheffield S11 8HW, UK", // Ecclesall Road
                "London Road, Sheffield S2 4LA, UK", // London Road
                "Abbeydale Road, Sheffield S7 1FS, UK", // Abbeydale Road
                "Chesterfield Road, Sheffield S8 0RL, UK", // Chesterfield Road
                "Glossop Road, Sheffield S10 2GW, UK" // Glossop Road
            ]
            return addresses[index % addresses.count]

        case .bradford:
            let addresses = [
                "Centenary Square, Bradford BD1 1HY, UK", // Centenary Square
                "Broadway, Bradford BD1 1JR, UK", // Broadway
                "Kirkgate, Bradford BD1 1QR, UK", // Kirkgate
                "Market Street, Bradford BD1 1LH, UK", // Market Street
                "Sunbridge Road, Bradford BD1 2AP, UK", // Sunbridge Road
                "Ivegate, Bradford BD1 1UZ, UK", // Ivegate
                "Chapel Street, Bradford BD1 5DX, UK", // Chapel Street
                "North Parade, Bradford BD1 3JL, UK", // North Parade
                "Manningham Lane, Bradford BD8 7HY, UK", // Manningham Lane
                "Great Horton Road, Bradford BD7 1AY, UK" // Great Horton Road
            ]
            return addresses[index % addresses.count]

        case .edinburgh:
            let addresses = [
                "Princes Street, Edinburgh EH2 2ER, UK", // Princes Street
                "Royal Mile, Edinburgh EH1 1SG, UK", // Royal Mile
                "Grassmarket, Edinburgh EH1 2HS, UK", // Grassmarket
                "George Street, Edinburgh EH2 2PF, UK", // George Street
                "Rose Street, Edinburgh EH2 2LL, UK", // Rose Street
                "Cockburn Street, Edinburgh EH1 1BS, UK", // Cockburn Street
                "Victoria Street, Edinburgh EH1 2JL, UK", // Victoria Street
                "Thistle Street, Edinburgh EH2 1DG, UK", // Thistle Street
                "Dundas Street, Edinburgh EH3 6SD, UK", // Dundas Street
                "Stockbridge, Edinburgh EH3 6TQ, UK" // Stockbridge
            ]
            return addresses[index % addresses.count]

        case .liverpool:
            let addresses = [
                "Pier Head, Liverpool L3 1BY, UK", // Pier Head
                "Albert Dock, Liverpool L3 4AA, UK", // Albert Dock
                "Bold Street, Liverpool L1 4EU, UK", // Bold Street
                "Church Street, Liverpool L1 1AY, UK", // Church Street
                "Lord Street, Liverpool L2 1TS, UK", // Lord Street
                "Ranelagh Street, Liverpool L1 1JQ, UK", // Ranelagh Street
                "Whitechapel, Liverpool L1 6DA, UK", // Whitechapel
                "Parker Street, Liverpool L1 1JQ, UK", // Parker Street
                "School Lane, Liverpool L1 3BT, UK", // School Lane
                "Mathew Street, Liverpool L2 6RE, UK" // Mathew Street
            ]
            return addresses[index % addresses.count]

        case .manchester:
            let addresses = [
                "Piccadilly Gardens, Manchester M1 1RG, UK", // Piccadilly Gardens
                "Market Street, Manchester M1 1PW, UK", // Market Street
                "Deansgate, Manchester M3 2GQ, UK", // Deansgate
                "King Street, Manchester M2 4PD, UK", // King Street
                "St Ann's Square, Manchester M2 7DH, UK", // St Ann's Square
                "Cross Street, Manchester M2 7JE, UK", // Cross Street
                "Tib Street, Manchester M4 1SH, UK", // Tib Street
                "Oldham Street, Manchester M1 1JN, UK", // Oldham Street
                "High Street, Manchester M4 1SH, UK", // High Street
                "Shudehill, Manchester M4 2AF, UK" // Shudehill
            ]
            return addresses[index % addresses.count]

        case .bristol:
            let addresses = [
                "Broadmead, Bristol BS1 3HA, UK", // Broadmead
                "Cabot Circus, Bristol BS1 3BQ, UK", // Cabot Circus
                "Corn Street, Bristol BS1 1JQ, UK", // Corn Street
                "Park Street, Bristol BS1 5DR, UK", // Park Street
                "Queen Square, Bristol BS1 4LH, UK", // Queen Square
                "College Green, Bristol BS1 5TR, UK", // College Green
                "St Nicholas Street, Bristol BS1 1UE, UK", // St Nicholas Street
                "Wine Street, Bristol BS1 1BD, UK", // Wine Street
                "High Street, Bristol BS1 2AW, UK", // High Street
                "Baldwin Street, Bristol BS1 1PN, UK" // Baldwin Street
            ]
            return addresses[index % addresses.count]

        default:
            return "Adresse touristique, \(city.displayName)"
        }
    }
    
    // MARK: - Tours détaillés pour Paris
        private func createParisTours() -> [GuidedTour] {
            return [
                // Tour 1: Monuments emblématiques de Paris
                GuidedTour(
                    id: "paris_emblematic",
                    title: "🏛️ Monuments emblématiques de Paris",
                    city: .paris,
                    description: "Découvrez les monuments les plus célèbres de Paris avec des guides audio immersifs. De la Tour Eiffel au Louvre, plongez dans l'histoire de la Ville Lumière.",
                    duration: 8400, // 2h20
                    difficulty: .easy,
                    stops: [
                        TourStop(
                            id: "paris_eiffel",
                            location: Location(
                                id: "eiffel_tower",
                                name: "Tour Eiffel",
                                address: "Champ de Mars, 5 Avenue Anatole France, 75007 Paris",
                                latitude: 48.8584, longitude: 2.2945,
                                category: .culture,
                                description: "La Dame de Fer, symbole de Paris depuis 1889",
                                imageURL: "https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?w=400",
                                rating: 4.9,
                                openingHours: "9h30 - 23h45",
                                recommendedDuration: 3600,
                                visitTips: ["Meilleur point de vue : Trocadéro", "Évitez les files : réservez en ligne", "Illuminations toutes les heures après le coucher du soleil"]
                            ),
                            order: 1,
                            audioGuideText: """
                            Bienvenue devant la Tour Eiffel, l'emblème incontesté de Paris ! 
                            
                            Construite par Gustave Eiffel pour l'Exposition universelle de 1889, cette tour de fer de 330 mètres était initialement critiquée par les Parisiens. Aujourd'hui, elle accueille plus de 7 millions de visiteurs par an.
                            
                            Saviez-vous que la Tour Eiffel grandit de 15 centimètres en été à cause de la dilatation du métal ? Et qu'elle pèse 10 100 tonnes ? 
                            
                            Regardez vers le sommet : vous apercevez l'appartement secret de Gustave Eiffel au 3ème étage, où il recevait ses invités prestigieux comme Thomas Edison.
                            
                            La tour scintille toutes les heures après le coucher du soleil grâce à 20 000 ampoules dorées installées en 2000 pour le passage au nouveau millénaire.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1542125387-c71274d94f0a?w=400",
                            visitDuration: TimeInterval(900), // 15 min
                            tips: "💡 Meilleur point de vue : Trocadéro • Évitez les files : réservez en ligne"
                        ),
                        TourStop(
                            id: "paris_louvre",
                            location: Location(
                                id: "louvre_museum",
                                name: "Musée du Louvre",
                                address: "Rue de Rivoli, 75001 Paris",
                                latitude: 48.8606, longitude: 2.3376,
                                category: .museum,
                                description: "Plus grand musée du monde et ancien palais royal",
                                imageURL: "https://images.unsplash.com/photo-1566139447026-9c1d83b64f3e?w=400",
                                rating: 4.7,
                                openingHours: "9h00 - 18h00",
                                recommendedDuration: 7200,
                                visitTips: ["Réservation obligatoire", "Entrée gratuite 1er dimanche du mois (hiver)", "Commencez par la Joconde tôt le matin"]
                            ),
                            order: 2,
                            audioGuideText: """
                            Voici le Louvre, plus grand musée du monde avec ses 35 000 œuvres exposées !
                            
                            Ancien palais royal construit en 1190, transformé en musée en 1793 pendant la Révolution française. Ses 8 départements abritent des trésors de l'humanité : Mona Lisa, Vénus de Milo, Victoire de Samothrace.
                            
                            La pyramide de verre, inaugurée en 1989 par l'architecte Ieoh Ming Pei, fut d'abord controversée. Aujourd'hui, elle illumine le hall Napoléon et est devenue emblématique du musée moderne.
                            
                            10 millions de visiteurs par an viennent admirer 9 000 ans d'art et de civilisations. Pour voir toutes les œuvres 30 secondes chacune, il faudrait... 100 jours non-stop !
                            
                            La Joconde mesure seulement 77 cm sur 53 cm. Son sourire énigmatique fascine depuis 5 siècles. Léonard de Vinci l'a peinte entre 1503 et 1506, mais ne s'en est jamais séparé.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1508706019430-1c4e86b5c80a?w=400",
                            visitDuration: TimeInterval(1800), // 30 min
                            tips: "🎫 Réservation obligatoire • Entrée gratuite 1er dimanche du mois (hiver)"
                        ),
                        TourStop(
                            id: "paris_arc_triomphe",
                            location: Location(
                                id: "arc_triomphe",
                                name: "Arc de Triomphe",
                                address: "Place Charles de Gaulle, 75008 Paris",
                                latitude: 48.8738, longitude: 2.2950,
                                category: .historical,
                                description: "Monument aux victoires de Napoléon",
                                imageURL: "https://images.unsplash.com/photo-1549144511-f099e773c147?w=400",
                                rating: 4.6,
                                openingHours: "10h00 - 23h00",
                                recommendedDuration: 1800,
                                visitTips: ["Montez au sommet pour une vue panoramique", "Accès par le passage souterrain", "Relève de la flamme à 18h30"]
                            ),
                            order: 3,
                            audioGuideText: """
                            L'Arc de Triomphe domine majestueusement les Champs-Élysées depuis 1836 !
                            
                            Commandé par Napoléon en 1806 pour célébrer ses victoires militaires, cet arc mesure 50 mètres de haut et 45 mètres de large. Il est inspiré de l'arc antique de Titus à Rome.
                            
                            Sous l'Arc repose le Soldat Inconnu depuis 1921, dont la flamme est ravivée chaque soir à 18h30. Cette tradition honore tous les soldats morts pour la France.
                            
                            Les sculptures sont remarquables : 'La Marseillaise' de François Rude côté Champs-Élysées, 'Le Triomphe de 1810' de Cortot côté Wagram. Les piliers portent les noms de 128 batailles et 558 généraux.
                            
                            De sa terrasse, la vue sur les 12 avenues qui rayonnent depuis la place de l'Étoile est saisissante : on comprend pourquoi Haussmann a conçu Paris comme une étoile !
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1502602898536-47ad22581b52?w=400",
                            visitDuration: TimeInterval(800), // 13 min
                            tips: "🌟 Montez au sommet pour une vue panoramique • Accès par le passage souterrain"
                        ),
                        TourStop(
                            id: "paris_notre_dame",
                            location: Location(
                                id: "notre_dame",
                                name: "Cathédrale Notre-Dame",
                                address: "6 Parvis Notre-Dame, 75004 Paris",
                                latitude: 48.8530, longitude: 2.3499,
                                category: .religious,
                                description: "Chef-d'œuvre de l'art gothique français",
                                imageURL: "https://images.unsplash.com/photo-1539650116574-75c0c6d4d6b4?w=400",
                                rating: 4.5,
                                openingHours: "8h00 - 18h45",
                                recommendedDuration: 2400,
                                visitTips: ["Restauration jusqu'en 2024", "Admirez l'extérieur depuis le square Jean XXIII", "Visitez la crypte archéologique"]
                            ),
                            order: 4,
                            audioGuideText: """
                            Notre-Dame de Paris, 850 ans d'histoire et de foi !
                            
                            Commencée en 1163 sous l'évêque Maurice de Sully, achevée vers 1345. Cette cathédrale gothique révolutionne l'architecture : voûtes sur croisées d'ogives, arcs-boutants, rosaces géantes.
                            
                            Victor Hugo la sauve de la démolition en 1831 avec son roman 'Notre-Dame de Paris'. Napoléon s'y fait couronner empereur en 1804. De Gaulle y célèbre la Libération en 1944.
                            
                            L'incendie d'avril 2019 émeut le monde entier. La flèche s'effondre, la charpente 'forêt' du 13ème siècle brûle, mais les tours et les trésors sont sauvés par les pompiers de Paris.
                            
                            Reconstruction en cours : les artisans redonnent vie aux techniques médiévales. Charpentiers, tailleurs de pierre, maîtres verriers reconstruisent à l'identique cette merveille gothique.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1502602898536-47ad22581b52?w=400",
                            visitDuration: TimeInterval(1000), // 16 min
                            tips: "🔨 Restauration jusqu'en 2024 • Admirez l'extérieur depuis le square Jean XXIII"
                        )
                    ],
                    imageURL: "https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?w=800&h=600&fit=crop",
                    rating: 4.8,
                    price: nil
                ),
                
                // Tour 2: Montmartre artistique
                GuidedTour(
                    id: "paris_montmartre",
                    title: "🎨 Montmartre artistique",
                    city: .paris,
                    description: "Montez vers Montmartre, village d'artistes mythique. Du Sacré-Cœur aux cabarets de Pigalle, découvrez l'âme bohème de Paris.",
                    duration: 7200, // 2h
                    difficulty: .moderate,
                    stops: [
                        TourStop(
                            id: "paris_sacre_coeur",
                            location: Location(
                                id: "sacre_coeur",
                                name: "Basilique du Sacré-Cœur",
                                address: "35 Rue du Chevalier de la Barre, 75018 Paris",
                                latitude: 48.8867, longitude: 2.3431,
                                category: .religious,
                                description: "Basilique romano-byzantine dominant Paris",
                                imageURL: nil,
                                rating: 4.6,
                                openingHours: "6h00 - 22h30",
                                recommendedDuration: 3600,
                                visitTips: ["Funiculaire pour éviter les escaliers", "Vue magnifique au coucher du soleil", "Visitez la crypte"]
                            ),
                            order: 1,
                            audioGuideText: """
                            Le Sacré-Cœur, sentinelle blanche veillant sur Paris depuis 1914 !
                            
                            Cette basilique romano-byzantine fut érigée après la défaite de 1870 comme 'vœu national' de pénitence. Sa pierre de travertin blanchit avec le temps et la pluie.
                            
                            Du parvis, Paris s'étend à vos pieds ! 237 mètres d'altitude offrent une vue à 50 kilomètres par temps clair. Montmartre était jadis une commune indépendante, rattachée à Paris en 1860.
                            
                            La crypte abrite l'une des plus grosses cloches de France : la Savoyarde pèse 18 tonnes ! Le campanile culmine à 83 mètres, visible de tout Paris.
                            
                            Devant vous s'étend Montmartre, village dans la ville. Ses ruelles pavées, ses vignes (dernière vigne de Paris !), ses cabarets ont inspiré Renoir, Picasso, Toulouse-Lautrec...
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=400",
                            visitDuration: TimeInterval(1200), // 20 min
                            tips: "🚠 Funiculaire pour éviter les escaliers • Vue magnifique au coucher du soleil"
                        ),
                        TourStop(
                            id: "paris_place_du_tertre",
                            location: Location(
                                id: "place_du_tertre",
                                name: "Place du Tertre",
                                address: "Place du Tertre, 75018 Paris",
                                latitude: 48.8865, longitude: 2.3407,
                                category: .culture,
                                description: "Place des artistes peintres de Montmartre",
                                imageURL: nil,
                                rating: 4.3,
                                openingHours: "Toute la journée",
                                recommendedDuration: 1800,
                                visitTips: ["Portraits à partir de 20€", "Ambiance authentique tôt le matin", "Évitez les restaurants touristiques"]
                            ),
                            order: 2,
                            audioGuideText: """
                            Place du Tertre, cœur battant de Montmartre et temple de l'art parisien !
                            
                            Cette petite place de village (126 mètres sur 108) concentre l'esprit bohème de Montmartre. Ici peignaient Picasso, Van Dongen, Dufy au début du 20ème siècle.
                            
                            Les portraitistes perpétuent la tradition : en 10 minutes, votre portrait au crayon ou pastel ! Ces artistes sont sélectionnés par la mairie et font partie du charme authentique du lieu.
                            
                            Le Consulat, La Mère Catherine, Le Clairon de Chasseur : ces restaurants centenaires ont nourri les artistes fauchés. Renoir y peint 'Le Moulin de la Galette' en 1876.
                            
                            Montmartre résiste : malgré les touristes, l'âme rebelle demeure. Ateliers d'artistes, vignes sauvages, jardins secrets perpétuent l'esprit libertaire de la Butte.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1471623643738-61fa74830e33?w=400",
                            visitDuration: TimeInterval(900), // 15 min
                            tips: "🎨 Portraits à partir de 20€ • Ambiance authentique tôt le matin"
                        ),
                        TourStop(
                            id: "paris_moulin_rouge",
                            location: Location(
                                id: "moulin_rouge",
                                name: "Moulin Rouge",
                                address: "82 Boulevard de Clichy, 75018 Paris",
                                latitude: 48.8841, longitude: 2.3322,
                                category: .entertainment,
                                description: "Cabaret mythique et berceau du French Cancan",
                                imageURL: nil,
                                rating: 4.4,
                                openingHours: "Spectacles 19h et 21h",
                                recommendedDuration: 7200,
                                visitTips: ["Réservation obligatoire pour les spectacles", "Dîner-spectacle disponible", "Dress code exigé"]
                            ),
                            order: 3,
                            audioGuideText: """
                            Le Moulin Rouge, temple du French Cancan depuis 1889 !
                            
                            Ce cabaret mythique ouvre ses portes le 6 octobre 1889, même année que la Tour Eiffel. Son moulin rouge de 27 mètres attire immédiatement le Tout-Paris de la Belle Époque.
                            
                            C'est ici qu'est né le French Cancan, danse scandaleuse pour l'époque où les danseuses levaient haut la jambe ! La Goulue et Valentin le Désossé en furent les stars. Toulouse-Lautrec immortalisa leurs spectacles dans ses célèbres affiches.
                            
                            De Joséphine Baker à Mistinguett, de Édith Piaf à Yves Montand, tous les grands noms se sont produits ici. Frank Sinatra, Liza Minnelli, Elton John ont chanté sur cette scène légendaire.
                            
                            Aujourd'hui, le Moulin Rouge perpétue la tradition : plumes, strass, champagne et French Cancan continuent d'éblouir 600 000 spectateurs par an venus du monde entier.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=400",
                            visitDuration: TimeInterval(700), // 12 min
                            tips: "🎭 Réservation obligatoire pour les spectacles • Dîner-spectacle disponible"
                        )
                    ],
                    imageURL: "https://images.unsplash.com/photo-1503917988258-f87a78e3c995?w=800&h=600&fit=crop",
                    rating: 4.6,
                    price: nil
                ),
                
                // Tour 3: Seine et jardins secrets
                GuidedTour(
                    id: "paris_seine_gardens",
                    title: "🌊 Seine et jardins secrets",
                    city: .paris,
                    description: "Découvrez Paris au fil de l'eau : quais de Seine, Île Saint-Louis, jardins cachés et places secrètes de la capitale.",
                    duration: 6900, // 1h55
                    difficulty: .easy,
                    stops: [
                        TourStop(
                            id: "paris_ile_saint_louis",
                            location: Location(
                                id: "ile_saint_louis",
                                name: "Île Saint-Louis",
                                address: "Île Saint-Louis, 75004 Paris",
                                latitude: 48.8518, longitude: 2.3563,
                                category: .historical,
                                description: "Île parisienne préservée du 17ème siècle",
                                imageURL: "https://images.unsplash.com/photo-1522093007474-d86e9bf7ba6f?w=400",
                                rating: 4.5,
                                openingHours: "24h/24",
                                recommendedDuration: nil,
                                visitTips: nil
                            ),
                            order: 1,
                            audioGuideText: """
                            L'Île Saint-Louis, bijou architectural préservé depuis le 17ème siècle !
                            
                            Cette île artificielle fut créée en 1627 par l'union de deux îlots. L'architecte Louis Le Vau y dessine un plan géométrique parfait : rues droites, hôtels particuliers uniformes.
                            
                            Ici, le temps s'est arrêté ! Pas de métro, pas de grandes enseignes, juste des hôtels particuliers où vécurent Voltaire, Mme de Pompadour, Baudelaire. Marie Curie y finit ses jours.
                            
                            Berthillon, glacier mythique depuis 1954, propose les meilleures glaces de Paris. Leurs parfums changent selon les saisons : violette au printemps, châtaigne en automne...
                            
                            Promenez-vous quai de Bourbon : la vue sur Notre-Dame est saisissante. Ces quais romantiques inspirèrent les Impressionnistes et continuent de charmer les amoureux du monde entier.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1502602898536-47ad22581b52?w=400",
                            visitDuration: TimeInterval(1000), // 16 min,
                            tips: "🍦 Glaces Berthillon fermées le lundi et mardi • Promenade magique en soirée"
                        ),
                        TourStop(
                            id: "paris_pont_neuf",
                            location: Location(
                                id: "pont_neuf",
                                name: "Pont Neuf",
                                address: "Pont Neuf, 75001 Paris",
                                latitude: 48.8566, longitude: 2.3421,
                                category: .historical,
                                description: "Plus ancien pont de Paris encore debout",
                                imageURL: "https://images.unsplash.com/photo-1564861715733-f0d63e1d19b6?w=400",
                                rating: 4.4,
                                openingHours: "24h/24",
                                recommendedDuration: nil,
                                visitTips: nil
                            ),
                            order: 2,
                            audioGuideText: """
                            Le Pont Neuf, paradoxalement le plus ancien pont de Paris encore debout !
                            
                            Construit entre 1578 et 1607 sous Henri III puis Henri IV, c'est le premier pont parisien sans maisons ! Révolution urbaine : on peut enfin voir la Seine en traversant.
                            
                            Sa statue équestre d'Henri IV fut la première statue royale installée sur un pont. Fondue à la Révolution, elle est remoulée en 1818 avec le bronze des statues de Napoléon déboulonnées !
                            
                            Le square du Vert-Galant, pointe de l'île de la Cité, porte le surnom d'Henri IV. C'est l'un des lieux les plus romantiques de Paris : vue sur les deux rives, saules pleureurs, amoureux...
                            
                            Christo et Jeanne-Claude l'emballent en 1985 : 40 000 m² de toile dorée transforment le pont en œuvre d'art éphémère. 3 millions de visiteurs viennent admirer cette métamorphose !
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1519677100203-a0e668c92439?w=400",
                            visitDuration: TimeInterval(800), // 13 min,
                            tips: "📸 Meilleure photo depuis le square du Vert-Galant • Croisières au départ du pont"
                        ),
                        TourStop(
                            id: "paris_place_des_vosges",
                            location: Location(
                                id: "place_des_vosges",
                                name: "Place des Vosges",
                                address: "Place des Vosges, 75004 Paris",
                                latitude: 48.8555, longitude: 2.3661,
                                category: .historical,
                                description: "Plus ancienne place royale de Paris",
                                imageURL: "https://images.unsplash.com/photo-1542125387-c71274d94f0a?w=400",
                                rating: 4.8,
                                openingHours: "Toute la journée",
                                recommendedDuration: nil,
                                visitTips: nil
                            ),
                            order: 3,
                            audioGuideText: """
                            La Place des Vosges, plus ancienne place royale de Paris et l'une des plus belles au monde !
                            
                            Inaugurée en 1612 par Louis XIII pour célébrer les fiançailles de Louis XIV et Anne d'Autriche, elle s'appelait alors Place Royale. Rebaptisée Place des Vosges en 1800 pour honorer le premier département à payer ses impôts !
                            
                            Son architecture est parfaitement symétrique : 36 pavillons de brique rouge et pierre de taille, arcades au rez-de-chaussée, combles d'ardoise. Le pavillon du Roi (côté sud) fait face au pavillon de la Reine (côté nord).
                            
                            Victor Hugo vécut au numéro 6 de 1832 à 1848. C'est là qu'il écrit une partie des 'Misérables'. Sa maison est aujourd'hui un musée gratuit retraçant sa vie et son œuvre.
                            
                            Cette harmonie architecturale a inspiré de nombreuses places royales en France et en Europe. C'est un modèle d'urbanisme français exporté dans le monde entier.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1471623643738-61fa74830e33?w=400",
                            visitDuration: TimeInterval(800), // 13 min,
                            tips: "🏠 Visitez la maison de Victor Hugo • Déjeuner sous les arcades"
                        )
                    ],
                    imageURL: "https://images.unsplash.com/photo-1471623643738-61fa74830e33?w=400",
                    rating: 4.7,
                    price: nil
                ),
                
                // Tour 4: Paris underground et mystérieux
                GuidedTour(
                    id: "paris_mysterious",
                    title: "🕳️ Paris souterrain",
                    city: .paris,
                    description: "Explorez le Paris mystérieux : catacombes, passages couverts et légendes urbaines de la capitale.",
                    duration: 7200, // 2h
                    difficulty: .challenging,
                    stops: [
                        TourStop(
                            id: "paris_catacombs",
                            location: Location(
                                id: "catacombs_paris",
                                name: "Catacombes de Paris",
                                address: "1 Avenue du Colonel Henri Rol-Tanguy, 75014 Paris",
                                latitude: 48.8338, longitude: 2.3324,
                                category: .culture,
                                description: "L'empire de la mort sous Paris",
                                imageURL: nil,
                                rating: 4.3,
                                openingHours: "10h00 - 20h30",
                                recommendedDuration: nil,
                                visitTips: nil
                            ),
                            order: 1,
                            audioGuideText: """
                            Descendez dans l'empire de la mort... Bienvenue aux Catacombes de Paris !
                            
                            Ces anciennes carrières de calcaire, exploitées depuis l'époque romaine, abritent les ossements de plus de 6 millions de Parisiens. Au XVIIIe siècle, les cimetières parisiens débordaient et posaient des problèmes sanitaires.
                            
                            En 1786, on décida de transférer tous ces restes dans les carrières abandonnées. Les os ont été artistiquement arrangés, créant des motifs macabres mais fascinants.
                            
                            Vous marchez sur 1,7 kilomètre de galeries ouvertes au public, mais le réseau souterrain s'étend sur plus de 300 kilomètres sous Paris !
                            
                            Frisson garanti : la température reste constante à 14°C toute l'année.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1520637836862-4d197d17c36a?w=400",
                            visitDuration: TimeInterval(2700), // 45 min,
                            tips: "🧥 Prenez une veste ! • 👟 Chaussures fermées obligatoires"
                        ),
                        TourStop(
                            id: "paris_galerie_vivienne",
                            location: Location(
                                id: "galerie_vivienne",
                                name: "Galerie Vivienne",
                                address: "4 Rue des Petits Champs, 75002 Paris",
                                latitude: 48.8656, longitude: 2.3387,
                                category: .culture,
                                description: "Passage couvert du XIXe siècle",
                                imageURL: "https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=400",
                                rating: 4.6,
                                openingHours: "7h00 - 20h30",
                                recommendedDuration: nil,
                                visitTips: nil
                            ),
                            order: 2,
                            audioGuideText: """
                            Entrez dans l'un des plus beaux passages couverts de Paris ! La Galerie Vivienne, construite en 1823, est un joyau du Paris haussmannien.
                            
                            Admirez sa verrière, ses mosaïques au sol et ses décorations néo-classiques. Ce passage était l'ancêtre de nos centres commerciaux modernes !
                            
                            Ici, vous trouvez la librairie Jousseaume, la plus ancienne librairie de passages parisiens, et la célèbre cave Legrand Filles et Fils.
                            
                            Les passages couverts étaient des lieux de sociabilité bourgeoise au XIXe siècle. On y venait autant pour faire ses achats que pour voir et être vu !
                            
                            Jean-Paul Gaultier y a ouvert sa première boutique en 1986.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=400",
                            visitDuration: TimeInterval(900), // 15 min,
                            tips: "📚 Parfait pour chiner des livres rares • ☕ Café historique A Priori Thé"
                        ),
                        TourStop(
                            id: "paris_pere_lachaise",
                            location: Location(
                                id: "pere_lachaise",
                                name: "Cimetière du Père-Lachaise",
                                address: "16 Rue du Repos, 75020 Paris",
                                latitude: 48.8619, longitude: 2.3939,
                                category: .historical,
                                description: "Le plus célèbre cimetière de Paris",
                                imageURL: nil,
                                rating: 4.5,
                                openingHours: "8h00 - 18h00",
                                recommendedDuration: nil,
                                visitTips: nil
                            ),
                            order: 3,
                            audioGuideText: """
                            Bienvenue dans la nécropole la plus visitée au monde ! Le Père-Lachaise, ouvert en 1804, abrite les tombes de personnalités légendaires.
                            
                            Vous marchez sur les traces de Jim Morrison des Doors, d'Édith Piaf, de Molière, de Chopin, d'Oscar Wilde et de tant d'autres génies.
                            
                            Ce cimetière révolutionna l'art funéraire avec ses monuments sculptés et ses mausolées grandioses. C'est un véritable musée à ciel ouvert !
                            
                            La tombe de Jim Morrison est devenue un lieu de pèlerinage pour les fans du monde entier. Celle d'Édith Piaf reste simple, à son image.
                            
                            Avec ses 44 hectares et ses 70 000 tombes, c'est aussi un havre de paix verdoyant au cœur de Paris.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1539650116574-75c0c6d4d6b4?w=400",
                            visitDuration: TimeInterval(1800), // 30 min,
                            tips: "🗺️ Prenez un plan à l'entrée • 🌸 Magnifique au printemps"
                        )
                    ],
                    imageURL: "https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?w=800&h=600&fit=crop",
                    rating: 4.4,
                    price: 8.0
                ),
                
                // Tour 5: Quartiers branchés et tendance
                GuidedTour(
                    id: "paris_trendy",
                    title: "✨ Paris branché",
                    city: .paris,
                    description: "Découvrez le Paris moderne et tendance : Marais, Belleville, street art et nouvelles adresses créatives.",
                    duration: 9600, // 2h40
                    difficulty: .moderate,
                    stops: [
                        TourStop(
                            id: "paris_marais",
                            location: Location(
                                id: "marais_district",
                                name: "Le Marais - Place des Vosges",
                                address: "Place des Vosges, 75004 Paris",
                                latitude: 48.8554, longitude: 2.3650,
                                category: .culture,
                                description: "La plus ancienne place planifiée de Paris",
                                imageURL: "https://images.unsplash.com/photo-1542125387-c71274d94f0a?w=400",
                                rating: 4.7,
                                openingHours: "24h/24",
                                recommendedDuration: nil,
                                visitTips: nil
                            ),
                            order: 1,
                            audioGuideText: """
                            Voici la Place des Vosges, joyau du Marais et plus ancienne place planifiée de Paris !
                            
                            Inaugurée en 1612 sous Henri IV, elle était alors appelée Place Royale. Ses façades uniformes en brique rouge et pierre blanche créent une harmonie parfaite.
                            
                            Victor Hugo a vécu au numéro 6, aujourd'hui transformé en musée. Richelieu habitait au numéro 21. Cette place était le rendez-vous de l'aristocratie française.
                            
                            Le Marais d'aujourd'hui mélange histoire millénaire et modernité branchée. Synagogues côtoient boutiques de créateurs, falafel du quartier juif et galeries d'art contemporain.
                            
                            C'est aussi le cœur du Paris LGBT+ avec ses bars, restaurants et une communauté dynamique.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1569949381669-ecf31ae8e613?w=400",
                            visitDuration: TimeInterval(1200), // 20 min,
                            tips: " Essayez le falafel de L'As du Fallafel • ��️ Boutiques vintage rue de Rosiers"
                        ),
                        TourStop(
                            id: "paris_belleville",
                            location: Location(
                                id: "belleville_street_art",
                                name: "Belleville - Street Art",
                                address: "Rue Dénoyez, 75020 Paris",
                                latitude: 48.8725, longitude: 2.3825,
                                category: .culture,
                                description: "Quartier multiculturel et street art",
                                imageURL: "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400",
                                rating: 4.2,
                                openingHours: "24h/24",
                                recommendedDuration: nil,
                                visitTips: nil
                            ),
                            order: 2,
                            audioGuideText: """
                            Bienvenue à Belleville, le Paris multiculturel et créatif ! Ce quartier populaire est devenu l'épicentre du street art parisien.
                            
                            La rue Dénoyez est une galerie à ciel ouvert où les murs changent constamment. Chaque semaine apporte de nouvelles œuvres d'artistes du monde entier.
                            
                            Belleville, c'est aussi le quartier de naissance d'Édith Piaf ! Ici se mélangent communautés chinoise, africaine, maghrébine dans une ambiance cosmopolite unique.
                            
                            Les ateliers d'artistes occupent d'anciennes fabriques. Le parc de Belleville offre l'une des plus belles vues sur Paris, souvent méconnue des touristes.
                            
                            Ce quartier résiste à la gentrification et garde son âme populaire. Bars alternatifs, restaurants du monde entier et prix encore abordables !
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=400",
                            visitDuration: TimeInterval(1500), // 25 min,
                            tips: "📸 Photos autorisées du street art • 🌅 Coucher de soleil au parc de Belleville"
                        ),
                        TourStop(
                            id: "paris_canal_saint_martin",
                            location: Location(
                                id: "canal_saint_martin",
                                name: "Canal Saint-Martin",
                                address: "Quai de Jemmapes, 75010 Paris",
                                latitude: 48.8719, longitude: 2.3658,
                                category: .nature,
                                description: "Canal romantique et quartier bobo",
                                imageURL: "https://images.unsplash.com/photo-1569949381669-ecf31ae8e613?w=400",
                                rating: 4.6,
                                openingHours: "24h/24",
                                recommendedDuration: nil,
                                visitTips: nil
                            ),
                            order: 3,
                            audioGuideText: """
                            Le Canal Saint-Martin, star d'Instagram et refuge des Parisiens branchés !
                            
                            Creusé sous Napoléon entre 1805 et 1825, ce canal de 4,5 kilomètres relie le bassin de la Villette à la Seine. Ses 9 écluses et ses passerelles métalliques créent un décor romantique unique.
                            
                            C'est ici qu'Amélie Poulain faisait des ricochets ! Le film a propulsé ce quartier sur la scène internationale.
                            
                            Aujourd'hui, les quais vibrent d'une énergie créative : concept stores, cafés de spécialité, galeries émergentes. Les dimanches, les Parisiens pique-niquent au bord de l'eau.
                            
                            L'hôtel du Nord, rendu célèbre par Marcel Carné, reste un symbole du Paris populaire et cinéphile.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1587222086022-c4067dab9bd6?w=400",
                            visitDuration: TimeInterval(1080), // 18 min,
                            tips: "🥐 Café Ten Belles pour le meilleur café • �� Croisière en péniche possible"
                        )
                    ],
                    imageURL: "https://images.unsplash.com/photo-1569949381669-ecf31ae8e613?w=400",
                    rating: 4.5,
                    price: 6.0
                )
            ]
        }
        
        // MARK: - Tours détaillés pour Bruxelles
        private func createBrusselsTours() -> [GuidedTour] {
            return [
                // Tour 1: Centre historique de Bruxelles
                GuidedTour(
                    id: "brussels_historic",
                    title: "🏰 Centre historique de Bruxelles",
                    city: .brussels,
                    description: "Découvrez la Grand-Place, joyau de l'architecture gothique et baroque. Manneken Pis, galeries royales et chocolateries historiques vous attendent.",
                    duration: 5400, // 1h30
                    difficulty: .easy,
                    stops: [
                        TourStop(
                            id: "brussels_grand_place",
                            location: Location(
                                id: "grand_place_brussels",
                                name: "Grand-Place de Bruxelles",
                                address: "Grand-Place, 1000 Bruxelles",
                                latitude: 50.8467, longitude: 4.3525,
                                category: .historical,
                                description: "Une des plus belles places du monde selon Victor Hugo",
                                imageURL: nil,
                                rating: 4.9,
                                openingHours: "24h/24",
                                recommendedDuration: 3600,
                                visitTips: ["Tapis de fleurs en août (années paires)", "Illuminations magiques la nuit", "Visitez les guildes"]
                            ),
                            order: 1,
                            audioGuideText: """
                            Bienvenue sur la Grand-Place, 'plus beau théâtre du monde' selon Jean Cocteau !
                            
                            Cette place gothique du XVe siècle fut entièrement détruite par l'armée française en 1695, puis reconstruite en 4 ans dans un élan collectif exceptionnel. L'Hôtel de Ville gothique (1402) trône avec sa flèche de 96 mètres.
                            
                            Chaque maison des corporations porte un nom : l'Étoile, le Cygne, l'Arbre d'Or (brasseurs), la Louve (archers). Leurs façades dorées brillent au soleil, créant un kaléidoscope architectural unique.
                            
                            Tous les deux ans en août, un tapis de fleurs de 1800 m² recouvre entièrement la place. 500 000 bégonias composent des motifs éphémères admirés par le monde entier.
                            
                            Victor Hugo, exilé ici, la décrivit comme 'admirable' dans ses lettres. Cette harmonie baroque-gothique inspire artistes et poètes depuis 3 siècles.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1553975213-4c35f5a2a1e6?w=400",
                            visitDuration: TimeInterval(1200), // 20 min
                            tips: "🌸 Tapis de fleurs en août (années paires) • Illuminations magiques la nuit"
                        ),
                        TourStop(
                            id: "brussels_manneken_pis",
                            location: Location(
                                id: "manneken_pis",
                                name: "Manneken Pis",
                                address: "Rue de l'Étuve, 1000 Bruxelles",
                                latitude: 50.8450, longitude: 4.3500,
                                category: .culture,
                                description: "Célèbre statue symbole de l'esprit bruxellois",
                                imageURL: nil,
                                rating: 4.2,
                                openingHours: "24h/24",
                                recommendedDuration: 900,
                                visitTips: ["Consultez le calendrier des costumes", "Photo de groupe incontournable", "Visitez le musée des costumes"]
                            ),
                            order: 2,
                            audioGuideText: """
                            Voici Manneken Pis, petit bonhomme de 61 centimètres qui fait la fierté de Bruxelles !
                            
                            Cette fontaine de bronze (1619) de Jérôme Duquesnoy symbolise l'esprit irrévérencieux bruxellois. Selon la légende, un petit garçon sauva la ville en éteignant une bombe d'un jet d'urine !
                            
                            Sa garde-robe compte plus de 1000 costumes offerts par le monde entier : Elvis, samouraï, cosmonaute, footballeur... Il change de tenue 130 fois par an selon un calendrier officiel.
                            
                            Louis XV lui offrit un habit brodé d'or en 1747. Les costumes sont conservés au Musée de la Ville. Chaque don de costume s'accompagne d'une cérémonie et d'une dégustation de bière !
                            
                            Ne manquez pas ses 'sœurs' : Jeanneke Pis (fillette) dans l'impasse de la Fidélité, et Zinneke Pis (chien) rue des Chartreux. Trilogie espiègle de l'humour belge !
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1571847140471-1d7766e825ea?w=400",
                            visitDuration: TimeInterval(600), // 10 min
                            tips: "📅 Consultez le calendrier des costumes • 📸 Photo de groupe incontournable"
                        ),
                        TourStop(
                            id: "brussels_galeries_royales",
                            location: Location(
                                id: "galeries_royales",
                                name: "Galeries Royales Saint-Hubert",
                                address: "Galerie du Roi, 1000 Bruxelles",
                                latitude: 50.8472, longitude: 4.3565,
                                category: .culture,
                                description: "Première galerie commerciale couverte d'Europe",
                                imageURL: nil,
                                rating: 4.6,
                                openingHours: "7h00 - 20h00",
                                recommendedDuration: 1800,
                                visitTips: ["Dégustez du chocolat Neuhaus", "Café au Mokafe historique", "Visitez la librairie Jousseaume"]
                            ),
                            order: 3,
                            audioGuideText: """
                            Entrez dans les Galeries Royales Saint-Hubert, première galerie commerciale couverte d'Europe !
                            
                            Inaugurées en 1847, elles révolutionnent le commerce européen. Leur verrière de fer et verre, longue de 213 mètres, protège chalands et marchands des intempéries. Architecture novatrice inspirée des passages parisiens !
                            
                            Trois galeries : du Roi, de la Reine, des Princes. Le style néo-classique italien crée une atmosphère raffinée. Mosaïques au sol, dorures aux plafonds, élégance bourgeoise du XIXe siècle.
                            
                            Ici naquit la BD belge ! En 1929, Hergé publie les premières aventures de Tintin dans 'Le Petit Vingtième', journal édité galerie de la Reine. La tradition se perpétue avec de nombreuses librairies BD.
                            
                            Chocolatiers, dentellières, libraires perpétuent l'artisanat belge. Café A la Mort Subite sert ses lambics depuis 1928. Théâtre des Galeries programme auteurs contemporains.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1568515387631-8b650bbcdb90?w=400",
                            visitDuration: TimeInterval(800), // 13 min
                            tips: "🍫 Dégustez du chocolat Neuhaus • Café au Mokafe historique"
                        )
                    ],
                    imageURL: "https://images.unsplash.com/photo-1553975213-4c35f5a2a1e6?w=400",
                    rating: 4.7,
                    price: nil
                ),
                
                // Tour 2: Art nouveau et chocolat
                GuidedTour(
                    id: "brussels_art_nouveau",
                    title: "🎭 Art nouveau et chocolat",
                    city: .brussels,
                    description: "Découvrez l'Art nouveau bruxellois avec Victor Horta et les maisons de maître. Terminez par une dégustation chocolat dans les meilleures chocolateries.",
                    duration: 6300, // 1h45
                    difficulty: .moderate,
                    stops: [
                        TourStop(
                            id: "brussels_horta_museum",
                            location: Location(
                                id: "horta_museum",
                                name: "Musée Horta",
                                address: "25 Rue Américaine, 1060 Saint-Gilles",
                                latitude: 50.8275, longitude: 4.3475,
                                category: .museum,
                                description: "Ancienne maison-atelier du maître de l'Art nouveau",
                                imageURL: "https://images.unsplash.com/photo-1568515387631-8b650bbcdb90?w=400",
                                rating: 4.5,
                                openingHours: "14h00 - 17h30",
                                recommendedDuration: 5400,
                                visitTips: ["Réservation conseillée", "Autres maisons Horta : Tassel, Solvay, Van Eetvelde", "Visitez le quartier Art nouveau"]
                            ),
                            order: 1,
                            audioGuideText: """
                            Découvrez la maison-atelier de Victor Horta, père de l'Art nouveau européen !
                            
                            Cette maison (1898-1901) révolutionne l'architecture : plan ouvert, puits de lumière, escalier-sculpture en fer forgé. Horta invente un nouveau style où la nature inspire chaque détail : motifs floraux, courbes organiques.
                            
                            L'Art nouveau naît en réaction contre l'industrialisation. Horta veut réconcilier art et technique, beauté et fonction. Ses innovations : structure métallique apparente, grandes verrières, chauffage central intégré.
                            
                            Admirez la rampe d'escalier : cette spirale de fer et laiton évoque une liane grimpante. Les vitraux diffusent une lumière dorée. Chaque poignée de porte, chaque luminaire est dessiné par l'architecte.
                            
                            Bruxelles compte 80 bâtiments Art nouveau ! Horta, Van de Velde, Hankar créent un mouvement artistique total : architecture, mobilier, arts décoratifs. Influence mondiale de l'École de Bruxelles.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=400",
                            visitDuration: TimeInterval(1800), // 30 min
                            tips: "🏛️ Réservation conseillée • Autres maisons Horta : Tassel, Solvay, Van Eetvelde"
                        ),
                        TourStop(
                            id: "brussels_sablon",
                            location: Location(
                                id: "place_du_sablon",
                                name: "Place du Grand Sablon",
                                address: "Place du Grand Sablon, 1000 Bruxelles",
                                latitude: 50.8420, longitude: 4.3580,
                                category: .culture,
                                description: "Quartier des antiquaires et chocolatiers",
                                imageURL: "https://images.unsplash.com/photo-1571847140471-1d7766e825ea?w=400",
                                rating: 4.4,
                                openingHours: "24h/24",
                                recommendedDuration: 3600,
                                visitTips: ["Dégustation gratuite dans la plupart des boutiques", "Marché antiquités samedi", "Visitez l'église Notre-Dame du Sablon"]
                            ),
                            order: 2,
                            audioGuideText: """
                            Bienvenue au Sablon, quartier élégant des antiquaires et chocolatiers de renom !
                            
                            Cette place gothique tire son nom du sable extrait ici au Moyen Âge. L'église Notre-Dame du Sablon (XVe siècle) est un joyau de gothique flamboyant, illuminée magnifiquement la nuit.
                            
                            Depuis 1751, Pierre Marcolini perpétue l'art chocolatier. Ses ganaches aux épices révolutionnent la chocolaterie mondiale. Wittamer, chocolatier de la Cour depuis 1910, crée ses pralines dans les règles ancestrales.
                            
                            Le marché d'antiquités (week-end) transforme la place en musée à ciel ouvert : horlogerie, mobilier, livres rares, argenterie. Chineurs du monde entier y dénichent des trésors.
                            
                            Astuce de dégustation : laissez fondre le chocolat sur la langue pour libérer tous les arômes. Un bon chocolat belge révèle ses notes : cacaoté, fruité, épicé... Chaque maison a sa signature gustative !
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1587222086022-c4067dab9bd6?w=400",
                            visitDuration: TimeInterval(1200), // 20 min
                            tips: "🍫 Dégustation gratuite dans la plupart des boutiques • Marché antiquités samedi"
                        )
                    ],
                    imageURL: "https://images.unsplash.com/photo-1568515387631-8b650bbcdb90?w=400",
                    rating: 4.8,
                    price: 15.0
                )
            ]
        }
        
        // MARK: - Tours détaillés pour Luxembourg
        private func createLuxembourgTours() -> [GuidedTour] {
            return [
                // Tour 1: Casemates et vieille ville
                GuidedTour(
                    id: "luxembourg_casemates",
                    title: "🏰 Casemates et vieille ville de Luxembourg",
                    city: .luxembourg,
                    description: "Explorez les casemates du Bock, forteresse souterraine classée UNESCO. Découvrez la vieille ville médiévale et ses remparts impressionnants.",
                    duration: 7200, // 2h
                    difficulty: .moderate,
                    stops: [
                        TourStop(
                            id: "luxembourg_bock_casemates",
                            location: Location(
                                id: "bock_casemates",
                                name: "Casemates du Bock",
                                address: "10 Montée de Clausen, 1343 Luxembourg",
                                latitude: 49.6116, longitude: 6.1342,
                                category: .historical,
                                description: "Forteresse souterraine du XVIIIe siècle",
                                imageURL: nil,
                                rating: 4.8,
                                openingHours: "10h00 - 17h30",
                                recommendedDuration: 5400,
                                visitTips: ["Visite guidée recommandée", "Escaliers raides, prévoir chaussures confortables", "Vue panoramique depuis le promontoire"]
                            ),
                            order: 1,
                            audioGuideText: """
                            Bienvenue aux Casemates du Bock, forteresse souterraine unique au monde !
                            
                            Ces galeries militaires de 17 kilomètres creusées dans le rocher du Bock (963) forment un labyrinthe défensif exceptionnel. Classées UNESCO en 1994, elles témoignent de l'ingéniosité militaire européenne.
                            
                            Le rocher du Bock, éperon rocheux de 40 mètres, domine les vallées de l'Alzette et de la Pétrusse. Position stratégique convoitée par les grandes puissances : Espagne, France, Autriche, Prusse se succèdent.
                            
                            Les casemates abritaient 50 canons, 1200 soldats, écuries, boulangeries, ateliers. 40 000 m³ de roche extraits à la main ! Système de ventilation, puits d'eau, chambres de tir... Prouesse d'ingénierie militaire.
                            
                            Vauban, architecte militaire de Louis XIV, renforce la forteresse en 1684. Triple enceinte, bastions, demi-lunes... Luxembourg devient 'Gibraltar du Nord', imprenable jusqu'en 1867.
                            
                            Le traité de Londres (1867) impose le démantèlement. 90% des fortifications sont détruites, mais les casemates subsistent. Aujourd'hui, elles offrent un voyage unique dans l'histoire militaire européenne.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=400",
                            visitDuration: TimeInterval(1800), // 30 min
                            tips: "🏰 Visite guidée recommandée • 👟 Escaliers raides, prévoir chaussures confortables"
                        ),
                        TourStop(
                            id: "luxembourg_palace_grand_ducal",
                            location: Location(
                                id: "palace_grand_ducal",
                                name: "Palais Grand-Ducal",
                                address: "17 Rue du Marché-aux-Herbes, 1728 Luxembourg",
                                latitude: 49.6113, longitude: 6.1299,
                                category: .historical,
                                description: "Résidence officielle du Grand-Duc Henri",
                                imageURL: nil,
                                rating: 4.6,
                                openingHours: "Visites guidées juillet-août",
                                recommendedDuration: 1800,
                                visitTips: ["Réservation obligatoire", "Relève de la garde à 16h", "Photographie interdite"]
                            ),
                            order: 2,
                            audioGuideText: """
                            Le Palais Grand-Ducal, résidence officielle de la famille régnante depuis 1890 !
                            
                            Ancien hôtel de ville (1572), transformé en palais par Guillaume IV en 1890. Architecture Renaissance flamande : façade de grès rouge, tourelles, oriels. Intérieur somptueux : salons d'apparat, salle du trône, chapelle privée.
                            
                            La famille de Nassau règne depuis 1890. Henri, Grand-Duc depuis 2000, et Maria Teresa, Grande-Duchesse, perpétuent la tradition monarchique constitutionnelle. Luxembourg : seule monarchie du Benelux !
                            
                            La relève de la garde (16h) attire les touristes : gardes en uniforme traditionnel, cérémonie protocolaire. La garde assure la protection du palais et de la famille grand-ducale.
                            
                            Visites guidées en été uniquement : salons historiques, salle des banquets, escalier d'honneur. Mobilier d'époque, tapisseries, œuvres d'art... Plongée dans l'intimité monarchique luxembourgeoise.
                            
                            Le Grand-Duc Henri, chef d'État, nomme le Premier ministre, promulgue les lois, représente le Luxembourg à l'étranger. Monarchie parlementaire moderne dans un État prospère de 600 000 habitants.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1568651332539-d6f89b7baca5?w=400",
                            visitDuration: TimeInterval(900), // 15 min
                            tips: "👑 Réservation obligatoire • 🎖️ Relève de la garde à 16h"
                        ),
                        TourStop(
                            id: "luxembourg_place_darmes",
                            location: Location(
                                id: "place_darmes",
                                name: "Place d'Armes",
                                address: "Place d'Armes, 1136 Luxembourg",
                                latitude: 49.6119, longitude: 6.1304,
                                category: .culture,
                                description: "Place centrale de la vieille ville",
                                imageURL: nil,
                                rating: 4.4,
                                openingHours: "24h/24",
                                recommendedDuration: 1800,
                                visitTips: ["Concerts en plein air l'été", "Marché aux fleurs le mercredi", "Cafés et restaurants typiques"]
                            ),
                            order: 3,
                            audioGuideText: """
                            Place d'Armes, cœur battant de la vieille ville depuis le XVIIe siècle !
                            
                            Cette place rectangulaire, ancien terrain de parade militaire, est devenue le centre social de Luxembourg. Pavés historiques, kiosque à musique (1906), platanes centenaires créent une atmosphère méditerranéenne.
                            
                            Le kiosque à musique, de style Art nouveau, accueille concerts et événements culturels. Orchestres militaires, jazz, folklore... La musique résonne sous les platanes centenaires.
                            
                            Cafés historiques : Café de Paris (1930), Brasserie Guillaume (1900)... Ces établissements centenaires perpétuent l'art de vivre luxembourgeois : bières locales, vins mosellans, cuisine traditionnelle.
                            
                            Le marché aux fleurs du mercredi anime la place depuis 1920. Horticulteurs locaux, fleurs de saison, plantes d'intérieur... Tradition horticole luxembourgeoise dans un cadre historique.
                            
                            Vue imprenable sur les remparts et la vallée de l'Alzette. Cette place résume l'identité luxembourgeoise : tradition militaire, culture européenne, art de vivre raffiné.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1571847140471-1d7766e825ea?w=400",
                            visitDuration: TimeInterval(600), // 10 min
                            tips: "🎵 Concerts en plein air l'été • 🌸 Marché aux fleurs le mercredi"
                        )
                    ],
                    imageURL: "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=400",
                    rating: 4.7,
                    price: 12.0
                ),
                
                // Tour 2: Kirchberg et institutions européennes
                GuidedTour(
                    id: "luxembourg_kirchberg",
                    title: "🏛️ Kirchberg et institutions européennes",
                    city: .luxembourg,
                    description: "Découvrez le quartier européen de Kirchberg avec la Cour de Justice européenne, la Banque européenne d'investissement et l'architecture moderne.",
                    duration: 5400, // 1h30
                    difficulty: .easy,
                    stops: [
                        TourStop(
                            id: "luxembourg_court_justice",
                            location: Location(
                                id: "court_justice_eu",
                                name: "Cour de Justice de l'Union européenne",
                                address: "Boulevard Konrad Adenauer, 2925 Luxembourg",
                                latitude: 49.6208, longitude: 6.1364,
                                category: .culture,
                                description: "Plus haute juridiction de l'Union européenne",
                                imageURL: nil,
                                rating: 4.5,
                                openingHours: "Visites guidées sur réservation",
                                recommendedDuration: 3600,
                                visitTips: ["Réservation obligatoire", "Visite de la Grande Salle d'Audience", "Exposition permanente sur l'histoire de l'UE"]
                            ),
                            order: 1,
                            audioGuideText: """
                            La Cour de Justice de l'Union européenne, gardienne du droit européen depuis 1952 !
                            
                            Cette institution suprême, installée à Luxembourg depuis 1952, interprète le droit européen et assure son application uniforme dans les 27 États membres. 27 juges, un par pays, nommés pour 6 ans.
                            
                            Architecture moderne (2008) : façade de verre et acier, salle d'audience circulaire, bibliothèque de 400 000 volumes. Symbole de transparence et d'ouverture démocratique européenne.
                            
                            La Grande Salle d'Audience accueille les audiences publiques. Plafond en bois précieux, acoustique parfaite, traduction simultanée en 24 langues. Chaque citoyen européen peut s'exprimer dans sa langue !
                            
                            Rôle crucial : la Cour a rendu 15 000 arrêts depuis 1952. Affaires célèbres : arrêt Van Gend en Loos (1963) établit l'effet direct du droit européen, arrêt Cassis de Dijon (1979) fonde le marché unique.
                            
                            Luxembourg, capitale judiciaire de l'Europe : Cour de Justice, Tribunal de première instance, Tribunal de la fonction publique. Trois juridictions européennes dans une ville de 100 000 habitants !
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400",
                            visitDuration: TimeInterval(1200), // 20 min
                            tips: "⚖️ Réservation obligatoire • 🏛️ Visite de la Grande Salle d'Audience"
                        ),
                        TourStop(
                            id: "luxembourg_bei",
                            location: Location(
                                id: "bei_luxembourg",
                                name: "Banque européenne d'investissement",
                                address: "98-100 Boulevard Konrad Adenauer, 2950 Luxembourg",
                                latitude: 49.6215, longitude: 6.1375,
                                category: .culture,
                                description: "Institution financière de l'Union européenne",
                                imageURL: nil,
                                rating: 4.3,
                                openingHours: "Visites limitées",
                                recommendedDuration: 1800,
                                visitTips: ["Visites très limitées", "Exposition sur les projets financés", "Architecture moderne remarquable"]
                            ),
                            order: 2,
                            audioGuideText: """
                            La Banque européenne d'investissement, bras financier de l'Union européenne !
                            
                            Créée en 1958, la BEI finance les projets d'intérêt européen : infrastructures, environnement, innovation, PME. 500 milliards d'euros prêtés depuis sa création, 1er prêteur multilatéral au monde.
                            
                            Architecture futuriste (2008) : tours jumelles de 185 mètres, façade en verre intelligent, atrium de 8 étages. Symbole de la puissance financière européenne et de l'innovation technologique.
                            
                            La BEI finance 400 projets par an : autoroutes, TGV, énergies renouvelables, recherche médicale... Impact concret sur la vie quotidienne des Européens. 90% des prêts dans l'UE, 10% dans le monde.
                            
                            Triple A : notation financière maximale, la BEI emprunte sur les marchés aux meilleures conditions et prête aux États membres. Modèle unique de banque publique européenne.
                            
                            Luxembourg, place financière européenne : BEI, Fonds européen d'investissement, Eurostat... Concentration d'institutions européennes unique au monde dans une ville de taille moyenne.
                            """,
                            audioGuideURL: "https://images.unsplash.com/photo-1568651332539-d6f89b7baca5?w=400",
                            visitDuration: TimeInterval(800), // 13 min
                            tips: "🏦 Visites très limitées • 📊 Exposition sur les projets financés"
                        )
                    ],
                    imageURL: "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400",
                    rating: 4.6,
                    price: nil
                )
            ]
        }
        
        // MARK: - Fonction générique pour toutes les villes
        private func createGenericTours(for city: City) -> [GuidedTour] {
            // Générer des tours pour toutes les villes
            let tourTitles = [
                "🏛️ Découverte historique de \(city.displayName)",
                "🎨 \(city.displayName) et ses secrets",
                "✨ Le \(city.displayName) des lumières",
                "🍷 \(city.displayName) gourmand",
                "🏰 \(city.displayName) médiévale",
                "🌳 \(city.displayName) nature",
                "🎪 \(city.displayName) culturelle",
                "📸 \(city.displayName) en photos"
            ]
            
            let tourDescriptions = [
                "Explorez les monuments emblématiques de \(city.displayName) avec des guides audio immersifs. Découvrez l'histoire fascinante de cette ville.",
                "Découvrez les charmes cachés de \(city.displayName) et son histoire artistique. Explorez l'âme de cette ville unique.",
                "Une promenade pour découvrir \(city.displayName) sous un nouveau jour. Ponts, monuments et rues magiques.",
                "Dégustez les meilleures spécialités de \(city.displayName). Visitez les lieux historiques et les marchés traditionnels.",
                "Plongez dans l'histoire médiévale de \(city.displayName) avec ses légendes et son architecture ancienne.",
                "Explorez les parcs et espaces verts de \(city.displayName). Promenades bucoliques au cœur de la ville.",
                "Découvrez la richesse culturelle de \(city.displayName). Musées, théâtres et lieux d'art.",
                "Capturez les plus beaux moments de \(city.displayName). Points de vue exceptionnels et panoramas."
            ]
            
            return (1...3).map { index in
                let title = tourTitles[index - 1]
                let description = tourDescriptions[index - 1]
                
                return createGenericTour(
                    id: "\(city.rawValue)_\(index)",
                    title: title,
                    city: city,
                    description: description,
                    duration: TimeInterval.random(in: 3600...7200), // 1-2 heures
                    difficulty: [.easy, .moderate, .challenging].randomElement() ?? .easy,
                    stopCount: Int.random(in: 3...6)
                )
            }
        }
        
        private func createGenericTour(
            id: String,
            title: String,
            city: City,
            description: String,
            duration: TimeInterval,
            difficulty: TourDifficulty,
            stopCount: Int
        ) -> GuidedTour {
            let mockStops = (1...stopCount).map { index in
                TourStop(
                    id: "\(id)_stop_\(index)",
                    location: createGenericLocation(for: city, index: index),
                    order: index,
                    audioGuideText: "Voici un guide audio immersif pour le lieu \(index). Découvrez l'histoire fascinante de ce lieu emblématique avec des anecdotes captivantes et des détails historiques précis.",
                    audioGuideURL: nil,
                    visitDuration: TimeInterval(600), // 10 minutes
                    tips: "Conseil : Prenez le temps d'admirer les détails architecturaux."
                )
            }
            
            return GuidedTour(
                id: id,
                title: title,
                city: city,
                description: description,
                duration: duration,
                difficulty: difficulty,
                stops: mockStops,
                imageURL: getCityImageURL(for: city),
                rating: Double.random(in: 4.0...5.0),
                price: Bool.random() ? Double.random(in: 0...15) : nil
            )
        }
        
        private func createGenericLocation(for city: City, index: Int) -> Location {
            let locationNames = getLocationNames(for: city)
            let name = index <= locationNames.count ? locationNames[index - 1] : "Lieu \(index)"
            let address = getRealAddress(for: city, index: index)
            
            // Obtenir les vraies coordonnées pour cette adresse spécifique
            let coordinates = getRealCoordinates(for: city, index: index)
            
            return Location(
                id: "\(city.rawValue)_location_\(index)",
                name: name,
                address: address,
                latitude: coordinates.lat,
                longitude: coordinates.lng,
                category: .historical,
                description: "Description du lieu \(name)",
                imageURL: nil,
                rating: Double.random(in: 4.0...5.0),
                openingHours: "9h00 - 18h00",
                recommendedDuration: nil,
                visitTips: nil
            )
        }
        
        private func getRealCoordinates(for city: City, index: Int) -> (lat: Double, lng: Double) {
            switch city {
            case .tangier:
                let coordinates = [
                    (35.7806, -5.8136), // Place du 9 Avril 1947 - Place principale de Tanger (coordonnées exactes)
                    (35.7891, -5.8086), // Kasbah de Tanger - Forteresse historique
                    (35.7765, -5.8082), // Place de France - Place centrale
                    (35.7802, -5.8131), // Grand Socco - Place animée
                    (35.7809, -5.8097), // Petit Socco - Place traditionnelle
                    (35.7761, -5.9396), // Cap Spartel - Point le plus au nord-ouest de l'Afrique
                    (35.7678, -5.9391), // Grotte d'Hercule - Grotte naturelle
                    (35.7897, -5.7636), // Plage de Malabata - Plage populaire
                    (35.7892, -5.8082), // Musée de la Kasbah - Musée dans la forteresse
                    (35.7792, -5.8192)  // Cimetière américain - Cimetière historique
                ]
                return coordinates[index % coordinates.count]
            case .casablanca:
                // Utiliser les vraies coordonnées GPS depuis Apple Maps
                let coordinates = [
                    (33.6085, -7.6327),   // Mosquée Hassan II – Boulevard Sidi Mohammed Ben Abdallah
                    (33.5936, -7.6021),   // Place Mohammed V – Place Mohammed V
                    (33.5920, -7.6148),   // Médina de Casablanca – Rue Tahar Sebti, Ancienne Médina
                    (33.58799, -7.62133), // Cathédrale du Sacré-Cœur – Rue d'Alger
                    (33.5949, -7.6188),   // Place des Nations Unies
                    (33.5882, -7.6651),   // Aïn Diab / Boulevard de la Corniche
                    (33.5523, -7.6394),   // Musée du Judaïsme Marocain – 81 Rue Chasseur Jules Gros
                    (33.5881, -7.6221),   // Parc de la Ligue Arabe – Boulevard Moulay Youssef
                    (33.5930, -7.6180),   // Marché Central – Rue Chaouia
                    (33.533333, -7.583333) // Twin Center – Boulevard Al Massira Al Khadra
                ]
                return coordinates[index % coordinates.count]
            case .marrakech:
                let coordinates = [
                    (31.6258, -7.9891),   // Place Jemaa el-Fna - Place principale
                    (31.6245, -7.9868),   // Médina de Marrakech - Vieille ville
                    (31.6245, -7.9936),   // Koutoubia - Mosquée historique
                    (31.6245, -7.9868),   // Palais Bahia - Palais royal
                    (31.6412, -7.9928),   // Jardin Majorelle - Jardin botanique
                    (31.6245, -7.9868),   // Palais El Badi - Ruines du palais
                    (31.6245, -7.9868),   // Tombeaux Saadiens - Mausolée
                    (31.6245, -7.9868),   // Médersa Ben Youssef - École coranique
                    (31.6245, -7.9868),   // Souk de Marrakech - Marché traditionnel
                    (31.6144, -7.9877)    // Jardin de la Ménara - Jardin historique
                ]
                return coordinates[index % coordinates.count]
            case .marseille:
                let coordinates = [
                    (43.2841, 5.3698),   // Basilique Notre-Dame de la Garde
                    (43.2965, 5.3698),   // Vieux-Port
                    (43.2955, 5.3620),   // MuCEM
                    (43.3050, 5.3950),   // Palais Longchamp
                    (43.2797, 5.3250),   // Château d'If
                    (43.2965, 5.3698),   // Cours Julien
                    (43.2567, 5.3950),   // Parc Borély
                    (43.2965, 5.3698),   // Cathédrale de la Major
                    (43.2965, 5.3698),   // Fort Saint-Jean
                    (43.2965, 5.3698)    // Plage des Catalans
                ]
                return coordinates[index % coordinates.count]
            case .paris:
                let coordinates = [
                    (48.8584, 2.2945),   // Tour Eiffel
                    (48.8738, 2.2950),   // Arc de Triomphe
                    (48.8529, 2.3500),   // Notre-Dame
                    (48.8606, 2.3376),   // Louvre
                    (48.8867, 2.3431),   // Sacré-Cœur
                    (48.8698, 2.3077),   // Champs-Élysées
                    (48.8656, 2.3211),   // Place de la Concorde
                    (48.8719, 2.3317),   // Palais Garnier
                    (48.8462, 2.3371),   // Parc du Luxembourg
                    (48.8600, 2.3266)    // Musée d'Orsay
                ]
                return coordinates[index % coordinates.count]
            case .toulouse:
                let coordinates = [
                    (43.6047, 1.4442),   // Place du Capitole
                    (43.6097, 1.4426),   // Basilique Saint-Sernin
                    (43.6014, 1.4476),   // Cathédrale Saint-Étienne
                    (43.5939, 1.4522),   // Canal du Midi
                    (43.6015, 1.4461),   // Musée des Augustins
                    (43.6046, 1.4549),   // Jardin des Plantes
                    (43.6083, 1.4475),   // Place Wilson
                    (43.6006, 1.4452),   // Hôtel d'Assézat
                    (43.5878, 1.4789),   // Cité de l'Espace
                    (43.6008, 1.4395)    // Pont Neuf
                ]
                return coordinates[index % coordinates.count]
            case .nice:
                let coordinates = [
                    (43.6944, 7.2577),   // Promenade des Anglais
                    (43.6970, 7.2761),   // Vieille Ville
                    (43.6980, 7.2798),   // Colline du Château
                    (43.7001, 7.2681),   // Place Masséna
                    (43.6961, 7.2755),   // Cours Saleya
                    (43.7171, 7.2731),   // Musée Matisse
                    (43.6969, 7.2778),   // Cathédrale Sainte-Réparate
                    (43.6749, 7.2141),   // Parc Phoenix
                    (43.7196, 7.2742),   // Monastère de Cimiez
                    (43.6953, 7.2831)    // Port Lympia (Port de Nice)
                ]
                return coordinates[index % coordinates.count]
            case .nantes:
                let coordinates = [
                    (47.2155, -1.5499),   // Château des Ducs de Bretagne
                    (47.2184, -1.5516),   // Cathédrale Saint-Pierre-et-Saint-Paul
                    (47.2064, -1.5510),   // Les Machines de l'île (sur l'Île de Nantes)
                    (47.2136, -1.5606),   // Place Graslin
                    (47.2144, -1.5583),   // Passage Pommeraye
                    (47.2201, -1.5422),   // Jardin des Plantes
                    (47.2173, -1.5501),   // Musée d'Arts de Nantes
                    (47.2148, -1.5521),   // Quartier Bouffay
                    (47.2131, -1.5458),   // Le Lieu Unique (Tour LU)
                    (47.2084, -1.5602)    // Mémorial de l'Abolition de l'Esclavage
                ]
                return coordinates[index % coordinates.count]
            case .fez:
                let coordinates = [
                    (34.0631, -5.0086),   // Médina de Fès el-Bali
                    (34.0645, -4.9818),   // Médersa Bou Inania
                    (34.0649, -4.9739),   // Mosquée et Université Karaouiyine
                    (34.0632, -4.9748),   // Place Nejjarine et Musée
                    (34.0658, -4.9731),   // Tanneries Chouara
                    (34.0583, -4.9897),   // Palais Royal de Fès (Dar el-Makhzen)
                    (34.0619, -4.9944),   // Bab Boujloud (La Porte Bleue)
                    (34.0592, -4.9822),   // Musée Dar Batha
                    (34.0551, -4.9926),   // Jardin Jnan Sbil
                    (34.0734, -4.9984)    // Tombeaux des Mérinides
                ]
                return coordinates[index % coordinates.count]
            case .rabat:
                let coordinates = [
                    (34.0290, -6.8373),   // Kasbah des Oudayas
                    (34.0241, -6.8229),   // Tour Hassan
                    (34.0232, -6.8225),   // Mausolée Mohammed V
                    (34.0253, -6.8329),   // Médina de Rabat
                    (34.0151, -6.8225),   // Chellah
                    (34.0195, -6.8327),   // Musée Mohammed VI d'Art Moderne et Contemporain
                    (34.0416, -6.7953),   // Plage de Salé
                    (34.0177, -6.8407),   // Jardin d'Essais Botaniques
                    (34.0207, -6.8339),   // Cathédrale Saint-Pierre
                    (34.0210, -6.8361)    // Musée de l'Histoire et des Civilisations
                ]
                return coordinates[index % coordinates.count]
            case .agadir:
                let coordinates = [
                    (30.4181, -9.6028),   // Plage d'Agadir
                    (30.4300, -9.6269),   // Kasbah d'Agadir Oufella
                    (30.4078, -9.5781),   // Souk El Had
                    (30.4192, -9.5977),   // Musée du Patrimoine Amazigh
                    (30.4116, -9.6083),   // Marina d'Agadir
                    (30.4168, -9.5991),   // Place Al Amal (La Roue d'Agadir)
                    (30.4206, -9.5947),   // Jardin d'Olhão (Jardin de Portugal)
                    (30.4191, -9.5961),   // Mosquée Mohammed V
                    (30.4578, -9.5025),   // Crocoparc
                    (30.4173, -9.5971)    // La Vallée des Oiseaux
                ]
                return coordinates[index % coordinates.count]
            case .brussels:
                let coordinates = [
                    (50.8467, 4.3525),   // Grand-Place
                    (50.8450, 4.3499),   // Manneken Pis
                    (50.8485, 4.3537),   // Galeries Royales Saint-Hubert
                    (50.8950, 4.3418),   // Atomium
                    (50.8419, 4.3839),   // Parc du Cinquantenaire
                    (50.8482, 4.3570),   // Cathédrale Saints-Michel-et-Gudule
                    (50.8415, 4.3621),   // Palais Royal de Bruxelles
                    (50.8369, 4.3601),   // Musée Magritte
                    (50.8384, 4.3533),   // Place du Grand Sablon
                    (50.8455, 4.3662)    // Parc de Bruxelles
                ]
                return coordinates[index % coordinates.count]
            case .istanbul:
                let coordinates = [
                    (41.0055, 28.9769),   // Place Sultanahmet (Sultanahmet Meydanı)
                    (41.0086, 28.9800),   // Sainte-Sophie (Ayasofya)
                    (41.0115, 28.9833),   // Palais de Topkapi (Topkapı Sarayı)
                    (41.0053, 28.9767),   // Mosquée Bleue (Sultanahmet Camii)
                    (41.0104, 28.9681),   // Grand Bazar (Kapalıçarşı)
                    (41.0256, 28.9745),   // Tour de Galata (Galata Kulesi)
                    (41.0396, 28.9986),   // Palais de Dolmabahçe (Dolmabahçe Sarayı)
                    (41.0450, 29.0350),   // Pont du Bosphore (Boğaziçi Köprüsü)
                    (41.0370, 28.9763),   // Place Taksim (Taksim Meydanı)
                    (41.0461, 29.0239)    // Mosquée d'Ortaköy (Ortaköy Camii)
                ]
                return coordinates[index % coordinates.count]
            case .ankara:
                let coordinates = [
                    (39.9255, 32.8369),   // Anıtkabir
                    (39.9208, 32.8541),   // Place Kızılay
                    (39.9430, 32.8647),   // Place Ulus
                    (39.9416, 32.8631),   // Château d'Ankara
                    (39.8913, 32.8596),   // Atakule
                    (39.9397, 32.8617),   // Musée des civilisations anatoliennes
                    (39.9429, 32.8604),   // Musée de la Guerre d'Indépendance
                    (39.9317, 32.8569),   // Parc Gençlik
                    (39.9458, 32.8622),   // Mosquée Hacı Bayram Veli
                    (39.8973, 32.8627)    // Palais de Çankaya (Çankaya Köşkü)
                ]
                return coordinates[index % coordinates.count]
            case .tokyo:
                let coordinates = [
                    (35.7148, 139.7967),  // Temple Senso-ji
                    (35.7101, 139.8107),  // Tokyo Skytree
                    (35.6591, 139.7006),  // Traversée de Shibuya
                    (35.6586, 139.7454),  // Tour de Tokyo
                    (35.6764, 139.6993),  // Sanctuaire Meiji
                    (35.6653, 139.7710),  // Marché extérieur de Tsukiji
                    (35.6984, 139.7731),  // Akihabara
                    (35.7150, 139.7714),  // Parc d'Ueno
                    (35.6852, 139.7528),  // Palais Impérial de Tokyo
                    (35.6701, 139.7027)   // Harajuku
                ]
                return coordinates[index % coordinates.count]
            case .luxembourg:
                let coordinates = [
                    (49.6117, 6.1360),   // Casemates du Bock
                    (49.6106, 6.1319),   // Palais Grand-Ducal
                    (49.6100, 6.1314),   // Cathédrale Notre-Dame de Luxembourg
                    (49.6122, 6.1325),   // Chemin de la Corniche
                    (49.6094, 6.1317),   // Place d'Armes
                    (49.6111, 6.1322),   // Place Guillaume II
                    (49.6052, 6.1292),   // Pont Adolphe
                    (49.6133, 6.1345),   // Musée National d'Histoire et d'Art
                    (49.6025, 6.1394),   // Philharmonie Luxembourg
                    (49.6099, 6.1268)    // Ascenseur panoramique du Pfaffenthal
                ]
                return coordinates[index % coordinates.count]
            case .osaka:
                let coordinates = [
                    (34.6873, 135.5262),  // Château d'Osaka
                    (34.6687, 135.5013),  // Dotonbori
                    (34.6654, 135.4323),  // Universal Studios Japan
                    (34.6601, 135.5136),  // Temple Shitennoji
                    (34.6543, 135.4513),  // Aquarium Kaiyukan d'Osaka
                    (34.7055, 135.4900),  // Umeda Sky Building
                    (34.6599, 135.5097),  // Zoo de Tennoji
                    (34.6120, 135.5065),  // Sanctuaire Sumiyoshi Taisha
                    (34.6853, 135.5259),  // Musée d'histoire d'Osaka
                    (34.6658, 135.5042)   // Théâtre Namba Grand Kagetsu
                ]
                return coordinates[index % coordinates.count]
            case .kyoto:
                let coordinates = [
                    (35.0394, 135.7292),  // Kinkaku-ji (Pavillon d'Or)
                    (34.9671, 135.7727),  // Fushimi Inari-taisha
                    (34.9949, 135.7851),  // Kiyomizu-dera
                    (35.0176, 135.6764),  // Forêt de Bambous d'Arashiyama
                    (35.0270, 135.7948),  // Ginkaku-ji (Pavillon d'Argent)
                    (35.0142, 135.7482),  // Château de Nijo
                    (35.0337, 135.7188),  // Ryōan-ji
                    (35.0125, 135.6883),  // Train panoramique de Sagano
                    (35.0191, 135.7869),  // Chemin du Philosophe
                    (35.0037, 135.7783)   // Quartier de Gion
                ]
                return coordinates[index % coordinates.count]
            case .beijing:
                let coordinates = [
                    (39.8810, 116.4066),  // Temple du Ciel
                    (39.9163, 116.3972),  // Cité Interdite
                    (40.3625, 116.0594),  // Grande Muraille à Mutianyu
                    (39.9990, 116.2755),  // Palais d'Été
                    (39.9075, 116.3972),  // Place Tian'anmen
                    (39.9329, 116.4027),  // Temple de Confucius
                    (39.9419, 116.4061),  // Temple des Lamas (Yonghe)
                    (39.9250, 116.3861),  // Parc Beihai
                    (39.9247, 116.3953),  // Colline de Charbon (Jingshan Park)
                    (39.9351, 116.4255)   // Tournée des Hutongs
                ]
                return coordinates[index % coordinates.count]
            default:
                // Pour les autres villes, utiliser les coordonnées de base
                let baseCoordinates = getBaseCoordinates(for: city)
                let latOffset = Double(index) * 0.002
                let lngOffset = Double(index) * 0.003
                return (
                    lat: baseCoordinates.lat + latOffset + Double.random(in: -0.001...0.001),
                    lng: baseCoordinates.lng + lngOffset + Double.random(in: -0.001...0.001)
                )
            }
        }
        
        private func getLocationNames(for city: City) -> [String] {
            switch city {
            case .paris:
                return ["Tour Eiffel", "Arc de Triomphe", "Notre-Dame", "Louvre", "Sacré-Cœur", "Champs-Élysées", "Place de la Concorde", "Palais Garnier", "Parc du Luxembourg", "Musée d'Orsay"]
            case .lyon:
                return ["Basilique Notre-Dame de Fourvière", "Vieux Lyon", "Place Bellecour", "Cathédrale Saint-Jean", "Parc de la Tête d'Or", "Musée des Confluences", "Théâtre des Célestins", "Place des Terreaux", "Jardin des Chartreux", "Amphithéâtre des Trois Gaules"]
            case .marseille:
                return ["Basilique Notre-Dame de la Garde", "Vieux-Port", "MuCEM", "Palais Longchamp", "Château d'If", "Cours Julien", "Parc Borély", "Cathédrale de la Major", "Fort Saint-Jean", "Plage des Catalans"]
            case .toulouse:
                return ["Place du Capitole", "Basilique Saint-Sernin", "Cathédrale Saint-Étienne", "Canal du Midi", "Musée des Augustins", "Jardin des Plantes", "Place Wilson", "Hôtel d'Assézat", "Cité de l'Espace", "Pont Neuf"]
            case .nice:
                return ["Promenade des Anglais", "Vieille Ville", "Colline du Château", "Place Masséna", "Cours Saleya", "Musée Matisse", "Cathédrale Sainte-Réparate", "Parc Phoenix", "Monastère de Cimiez", "Port de Nice"]
            case .nantes:
                return ["Château des Ducs de Bretagne", "Cathédrale Saint-Pierre-et-Saint-Paul", "Île de Nantes", "Place Graslin", "Passage Pommeraye", "Jardin des Plantes", "Musée d'Arts de Nantes", "Quartier Bouffay", "Tour LU", "Mémorial de l'Abolition de l'Esclavage"]
            case .tangier:
                return ["Place du 9 Avril 1947", "Kasbah de Tanger", "Place de France", "Grand Socco", "Petit Socco", "Cap Spartel", "Grotte d'Hercule", "Plage de Malabata", "Musée de la Kasbah", "Cimetière américain"]
            case .casablanca:
                return ["Mosquée Hassan II", "Place Mohammed V", "Médina de Casablanca", "Cathédrale du Sacré-Cœur", "Place des Nations Unies", "Ain Diab", "Musée du Judaïsme Marocain", "Parc de la Ligue Arabe", "Marché Central", "Twin Center"]
            case .marrakech:
                return ["Place Jemaa el-Fna", "Médina de Marrakech", "Koutoubia", "Palais Bahia", "Jardin Majorelle", "Palais El Badi", "Tombeaux Saadiens", "Médersa Ben Youssef", "Souk de Marrakech", "Jardin de la Ménara"]
            case .fez:
                return ["Médina de Fès el-Bali", "Médersa Bou Inania", "Mosquée Karaouiyine", "Place Nejjarine", "Tanneries Chouara", "Palais Royal", "Bab Boujloud", "Musée Dar Batha", "Jardin Jnan Sbil", "Tombeaux des Mérinides"]
            case .rabat:
                return ["Kasbah des Oudayas", "Tour Hassan", "Mausolée Mohammed V", "Médina de Rabat", "Chellah", "Musée Mohammed VI", "Plage de Salé", "Jardin d'Essais", "Cathédrale Saint-Pierre", "Musée de l'Histoire et des Civilisations"]
            case .agadir:
                return ["Plage d'Agadir", "Kasbah d'Agadir Oufella", "Souk El Had", "Musée du Patrimoine Amazigh", "Marina d'Agadir", "Place Al Amal", "Jardin Olhão", "Mosquée Mohammed V", "Croc Parc", "Vallee des Oiseaux"]
            case .oujda:
                return ["Place du 16 Août", "Médina d'Oujda", "Mosquée Sidi Yahya", "Musée de la Résistance", "Parc Lalla Aïcha", "Bab Sidi Abdelouahab", "Place du 3 Mars", "Jardin Municipal", "Stade d'Honneur", "Gare d'Oujda"]
            case .tetouan:
                return ["Médina de Tétouan", "Place Hassan II", "Musée Ethnographique", "Mosquée Sidi Saïd", "Plage de Martil", "Musée Archéologique", "Jardin Feddan", "Bab Okla", "Place Moulay el Mehdi", "Cimetière espagnol"]
            case .meknes:
                return ["Place el-Hedim", "Bab Mansour", "Médina de Meknès", "Mausolée Moulay Ismail", "Heri es-Souani", "Musée Dar Jamaï", "Mosquée Lalla Aouda", "Place Lalla Aouda", "Jardin Lahboul", "Bab el-Khemis"]
            case .istanbul:
                return ["Sultanahmet Meydanı", "Ayasofya", "Topkapı Sarayı", "Sultanahmet Camii", "Kapalı Çarşı", "Galata Kulesi", "Dolmabahçe Sarayı", "Boğaziçi Köprüsü", "Taksim Meydanı", "Ortaköy Camii"]
            case .ankara:
                return ["Anıtkabir", "Kızılay Meydanı", "Ulus Meydanı", "Ankara Kalesi", "Atakule", "Museum of Anatolian Civilizations", "Kurtuluş Savaşı Müzesi", "Gençlik Parkı", "Hacı Bayram-ı Veli Camii", "Çankaya Köşkü"]
            case .izmir:
                return ["Konak Meydanı", "Kemeraltı Çarşısı", "Saat Kulesi", "Alsancak Mahallesi", "Kültürpark", "Kadifekale", "Asansör", "Agora", "Kızlarağası Hanı", "Basmane Garı"]
            case .antalya:
                return ["Kaleiçi", "Yivli Minare", "Hadrian Kapısı", "Konyaaltı Plajı", "Lara Plajı", "Düden Şelalesi", "Kurşunlu Şelalesi", "Perge Antik Kenti", "Aspendos Antik Tiyatrosu", "Side Antik Kenti"]
            case .bursa:
                return ["Uludağ", "Yeşil Camii", "Yeşil Türbe", "Ulu Camii", "Koza Han", "Cumalıkızık Köyü", "Tophane Saat Kulesi", "Muradiye Külliyesi", "Oylat Kaplıcaları", "İznik Gölü"]
            case .adana:
                return ["Seyhan Barajı", "Taşköprü", "Büyük Saat Kulesi", "Ulu Camii", "Yılankale", "Kapıkaya Kanyonu", "Varda Köprüsü", "Anavarza Antik Kenti", "Yumurtalık Plajı", "Seyhan Dam Lake"]
            case .gaziantep:
                return ["Gaziantep Kalesi", "Zeugma Mozaik Müzesi", "Bakırcılar Çarşısı", "Kurtuluş Cami", "Emine Göğüş Mutfak Müzesi", "Gaziantep Hayvanat Bahçesi", "Dülük Antik Kenti", "Yesemek Açık Hava Müzesi", "Rumkale", "Gaziantep Botanik Bahçesi"]
            case .konya:
                return ["Mevlana Müzesi", "Alaeddin Camii", "Alaeddin Tepesi", "İnce Minare Medresesi", "Sırçalı Medrese", "Karatay Medresesi", "Şems Camii", "Sille Köyü", "Çatalhöyük", "Tuz Gölü"]
            case .mersin:
                return ["Mersin Marina", "Mersin Kalesi", "Atatürk Parkı", "Mersin Müzesi", "Tarsus Şelalesi", "St. Paul Kuyusu", "Kleopatra Kapısı", "Uzuncaburç Antik Kenti", "Cennet ve Cehennem Obrukları", "Kızkalesi"]
            case .tokyo:
                return ["Senso-ji Temple", "Tokyo Skytree", "Shibuya Crossing", "Tokyo Tower", "Meiji Shrine", "Tsukiji Outer Market", "Akihabara", "Ueno Park", "Tokyo Imperial Palace", "Harajuku"]
            case .osaka:
                return ["Osaka Castle", "Dotonbori", "Universal Studios Japan", "Shitennoji Temple", "Osaka Aquarium Kaiyukan", "Umeda Sky Building", "Tennoji Zoo", "Sumiyoshi Taisha", "Osaka Museum of History", "Namba Grand Kagetsu"]
            case .kyoto:
                return ["Kinkaku-ji (Golden Pavilion)", "Fushimi Inari Taisha", "Kiyomizu-dera", "Arashiyama Bamboo Grove", "Ginkaku-ji (Silver Pavilion)", "Nijo Castle", "Ryoan-ji", "Sagano Romantic Train", "Philosopher's Path", "Gion District"]
            case .yokohama:
                return ["Yokohama Landmark Tower", "Yokohama Chinatown", "Yokohama Cosmo World", "Sankeien Garden", "Yokohama Red Brick Warehouse", "Yokohama Marine Tower", "Yokohama Hakkeijima Sea Paradise", "Yokohama Museum of Art", "Yokohama Stadium", "Yokohama Ramen Museum"]
            case .nagoya:
                return ["Nagoya Castle", "Atsuta Shrine", "Osu Kannon Temple", "Nagoya TV Tower", "Nagoya Port Aquarium", "Tokugawa Art Museum", "Shirotori Garden", "Nagoya City Science Museum", "Oasis 21", "Nagoya Station"]
            case .sapporo:
                return ["Sapporo Clock Tower", "Odori Park", "Sapporo TV Tower", "Sapporo Beer Museum", "Mount Moiwa", "Sapporo Dome", "Hokkaido University", "Sapporo Art Park", "Maruyama Park", "Sapporo Station"]
            case .kobe:
                return ["Kobe Port Tower", "Meriken Park", "Kobe Harborland", "Mount Rokko", "Kobe Nunobiki Herb Gardens", "Kobe City Museum", "Kobe Animal Kingdom", "Kobe Maritime Museum", "Kobe Chinatown (Nankinmachi)", "Kobe Oji Zoo"]
            case .fukuoka:
                return ["Fukuoka Tower", "Ohori Park", "Fukuoka Castle Ruins", "Canal City Hakata", "Dazaifu Tenmangu", "Fukuoka Yafuoku! Dome", "Uminonakamichi Seaside Park", "Fukuoka Art Museum", "Kushida Shrine", "Tenjin Underground City"]
            case .beijing:
                return ["Temple of Heaven", "Forbidden City", "Great Wall at Mutianyu", "Summer Palace", "Tiananmen Square", "Temple of Confucius", "Lama Temple", "Beihai Park", "Jingshan Park", "Hutong Tour"]
            case .shanghai:
                return ["The Bund", "Yu Garden", "Shanghai Tower", "Nanjing Road", "Shanghai Museum", "Tianzifang", "Shanghai Disneyland", "Shanghai World Financial Center", "Xintiandi", "Shanghai Ocean Aquarium"]
            case .guangzhou:
                return ["Canton Tower", "Chen Clan Ancestral Hall", "Baiyun Mountain", "Guangzhou Opera House", "Sacred Heart Cathedral", "Guangzhou Museum", "Sun Yat-sen Memorial Hall", "Guangzhou Zoo", "Shamian Island", "Guangzhou Library"]
            case .shenzhen:
                return ["Window of the World", "OCT Loft", "Shenzhen Museum", "Dameisha Beach", "Shenzhen Bay Park", "Splendid China Folk Culture Village", "Shenzhen Library", "Lianhuashan Park", "Shenzhen Art Museum", "Shenzhen Civic Center"]
            case .chengdu:
                return ["Giant Panda Breeding Research Base", "Leshan Giant Buddha", "Mount Emei", "Wuhou Temple", "Du Fu Thatched Cottage", "Chengdu Research Base of Giant Panda Breeding", "Kuanzhai Alley", "Chengdu Museum", "Jinsha Site Museum", "Chengdu Zoo"]
            case .xian:
                return ["Terracotta Warriors", "Ancient City Wall", "Muslim Quarter", "Great Mosque", "Bell Tower", "Drum Tower", "Wild Goose Pagoda", "Shaanxi History Museum", "Huaqing Palace", "Banpo Museum"]
            case .nanjing:
                return ["Sun Yat-sen Mausoleum", "Confucius Temple", "Nanjing Museum", "Ming Xiaoling Mausoleum", "Nanjing City Wall", "Xuanwu Lake", "Nanjing Massacre Memorial Hall", "Nanjing Presidential Palace", "Nanjing Zoo", "Nanjing Library"]
            default:
                let genericNames = [
                    "Monument principal", "Place centrale", "Cathédrale", "Musée", "Parc", "Théâtre",
                    "Palais", "Tour", "Pont", "Place du marché", "Jardin public", "Bibliothèque"
                ]
                return Array(genericNames.prefix(6))
            }
        }
        
        private func getTourTitles(for city: City) -> [String] {
            switch city {
            case .paris:
                return [
                    "🏛️ Monuments emblématiques de Paris",
                    "🎨 Art et culture parisienne",
                    "🌆 Paris historique et romantique"
                ]
            case .lyon:
                return [
                    "🏰 Lyon historique et gastronomique",
                    "⛪ Lyon religieux et culturel",
                    "🌿 Lyon nature et détente"
                ]
            case .marseille:
                return [
                    "🌊 Marseille maritime et portuaire",
                    "🏛️ Marseille historique et culturel",
                    "🌅 Marseille authentique et populaire"
                ]
            case .toulouse:
                return [
                    "🔴 Toulouse la rose historique",
                    "🚀 Toulouse spatiale et moderne",
                    "🌿 Toulouse nature et canal"
                ]
            case .nice:
                return [
                    "🌊 Nice la baie des anges",
                    "🏛️ Nice historique et culturel",
                    "🌅 Nice authentique et méditerranéenne"
                ]
            case .nantes:
                return [
                    "🏰 Nantes historique et ducale",
                    "🌿 Nantes verte et créative",
                    "⚓ Nantes maritime et industrielle"
                ]
            case .tangier:
                return [
                    "🌊 Tanger, porte de l'Afrique",
                    "🏛️ Tanger historique et culturel",
                    "🌅 Tanger authentique et méditerranéenne"
                ]
            case .casablanca:
                return [
                    "🕌 Casablanca moderne et religieuse",
                    "🌊 Casablanca maritime et économique",
                    "🏛️ Casablanca historique et culturel"
                ]
            case .marrakech:
                return [
                    "🔴 Marrakech la rouge",
                    "🏛️ Marrakech historique et impériale",
                    "🌿 Marrakech nature et palmeraie"
                ]
            case .fez:
                return [
                    "🏛️ Fès, capitale spirituelle",
                    "🎨 Fès artisanale et culturelle",
                    "🌿 Fès nature et médina"
                ]
            case .rabat:
                return [
                    "🏛️ Rabat, capitale moderne",
                    "🌊 Rabat maritime et historique",
                    "🏰 Rabat royale et administrative"
                ]
            case .agadir:
                return [
                    "🌊 Agadir, station balnéaire",
                    "🏛️ Agadir moderne et culturel",
                    "🌿 Agadir nature et détente"
                ]
            case .oujda:
                return [
                    "🏛️ Oujda historique et culturel",
                    "🌿 Oujda nature et détente",
                    "🏰 Oujda traditionnelle et moderne"
                ]
            case .tetouan:
                return [
                    "🏛️ Tétouan, ville blanche",
                    "🌊 Tétouan maritime et culturel",
                    "🏰 Tétouan historique et traditionnelle"
                ]
            case .meknes:
                return [
                    "🏛️ Meknès, ville impériale",
                    "🏰 Meknès historique et royale",
                    "🌿 Meknès nature et culturel"
                ]
            case .istanbul:
                return [
                    "🕌 Istanbul, entre deux continents",
                    "🏛️ Istanbul historique et byzantine",
                    "🌊 Istanbul maritime et ottomane"
                ]
            case .ankara:
                return [
                    "🏛️ Ankara, capitale moderne",
                    "🏰 Ankara historique et républicaine",
                    "🌿 Ankara nature et culturel"
                ]
            case .izmir:
                return [
                    "🌊 Izmir, perle de l'Égée",
                    "🏛️ Izmir historique et culturel",
                    "🌿 Izmir nature et détente"
                ]
            case .antalya:
                return [
                    "🌊 Antalya, riviera turque",
                    "🏛️ Antalya historique et antique",
                    "🌿 Antalya nature et montagne"
                ]
            case .bursa:
                return [
                    "🏛️ Bursa, première capitale ottomane",
                    "🌿 Bursa nature et thermal",
                    "🏰 Bursa historique et culturel"
                ]
            case .adana:
                return [
                    "🏛️ Adana historique et culturel",
                    "🌿 Adana nature et montagne",
                    "🌊 Adana moderne et économique"
                ]
            case .gaziantep:
                return [
                    "🏛️ Gaziantep, ville de la gastronomie",
                    "🎨 Gaziantep artisanale et culturel",
                    "🏰 Gaziantep historique et traditionnelle"
                ]
            case .konya:
                return [
                    "🕌 Konya, ville de Mevlana",
                    "🏛️ Konya historique et spirituelle",
                    "🌿 Konya nature et culturel"
                ]
            case .mersin:
                return [
                    "🌊 Mersin, port méditerranéen",
                    "🏛️ Mersin historique et antique",
                    "🌿 Mersin nature et montagne"
                ]
            case .tokyo:
                return [
                    "🗼 Tokyo, ville du futur",
                    "🏛️ Tokyo historique et traditionnel",
                    "🎨 Tokyo culturel et moderne"
                ]
            case .osaka:
                return [
                    "🏯 Osaka, ville du commerce",
                    "🎢 Osaka divertissement et culture",
                    "🌊 Osaka maritime et moderne"
                ]
            case .kyoto:
                return [
                    "⛩️ Kyoto, ancienne capitale impériale",
                    "🏛️ Kyoto temples et jardins",
                    "🎭 Kyoto traditionnel et culturel"
                ]
            case .yokohama:
                return [
                    "🌊 Yokohama, port international",
                    "🏛️ Yokohama historique et culturel",
                    "🌿 Yokohama nature et détente"
                ]
            case .nagoya:
                return [
                    "🏯 Nagoya, château et industrie",
                    "🏛️ Nagoya historique et culturel",
                    "🌿 Nagoya nature et moderne"
                ]
            case .sapporo:
                return [
                    "❄️ Sapporo, ville du nord",
                    "🍺 Sapporo bière et culture",
                    "🌿 Sapporo nature et montagne"
                ]
            case .kobe:
                return [
                    "🌊 Kobe, port et montagne",
                    "🏛️ Kobe historique et culturel",
                    "🌿 Kobe nature et détente"
                ]
            case .fukuoka:
                return [
                    "🌊 Fukuoka, porte de Kyushu",
                    "🏛️ Fukuoka historique et culturel",
                    "🌿 Fukuoka nature et moderne"
                ]
            case .beijing:
                return [
                    "🏛️ Beijing, capitale impériale",
                    "🏰 Beijing historique et culturel",
                    "🌿 Beijing nature et moderne"
                ]
            case .shanghai:
                return [
                    "🌆 Shanghai, ville du futur",
                    "🏛️ Shanghai historique et culturel",
                    "🌊 Shanghai maritime et moderne"
                ]
            case .guangzhou:
                return [
                    "🏛️ Guangzhou, ville du commerce",
                    "🌿 Guangzhou nature et culturel",
                    "🌊 Guangzhou maritime et moderne"
                ]
            case .shenzhen:
                return [
                    "🏗️ Shenzhen, ville nouvelle",
                    "🎢 Shenzhen divertissement et culture",
                    "🌿 Shenzhen nature et moderne"
                ]
            case .chengdu:
                return [
                    "🐼 Chengdu, ville des pandas",
                    "🏛️ Chengdu historique et culturel",
                    "🌿 Chengdu nature et détente"
                ]
            case .xian:
                return [
                    "🏛️ Xi'an, ancienne capitale",
                    "🏰 Xi'an historique et impériale",
                    "🌿 Xi'an nature et culturel"
                ]
            case .nanjing:
                return [
                    "🏛️ Nanjing, capitale historique",
                    "🏰 Nanjing historique et culturel",
                    "🌿 Nanjing nature et moderne"
                ]
            default:
                return [
                    "Découverte de \(city.displayName)",
                    "Tour culturel de \(city.displayName)",
                    "Exploration de \(city.displayName)"
                ]
            }
        }
        
        private func getAudioGuideText(for locationName: String, in city: City, index: Int) -> String {
            switch city {
            case .paris:
                switch locationName {
                case "Tour Eiffel":
                    return """
                    Bienvenue devant la Tour Eiffel, la Dame de Fer, symbole incontesté de Paris et de la France !
                    
                    Inaugurée en 1889 pour l'Exposition Universelle, elle fut la plus haute structure du monde pendant 41 ans. Gustave Eiffel, son ingénieur, a relevé le défi de construire une tour de 324 mètres en fer puddlé, un matériau révolutionnaire pour l'époque.
                    
                    Anecdote : La Tour Eiffel peut varier de 15 cm en hauteur en fonction de la température ! Le fer se dilate sous la chaleur et se contracte par temps froid.
                    
                    Saviez-vous que Gustave Eiffel avait un appartement secret au sommet ? Il y recevait des invités de marque comme Thomas Edison. Imaginez la vue imprenable depuis ce perchoir privé !
                    
                    Chaque soir, la Tour s'illumine et scintille pendant 5 minutes toutes les heures, un spectacle magique à ne pas manquer. C'est un moment féerique qui attire des millions de visiteurs chaque année.
                    """
                case "Arc de Triomphe":
                    return """
                    L'Arc de Triomphe domine majestueusement les Champs-Élysées depuis 1836 !
                    
                    Commandé par Napoléon en 1806 pour célébrer ses victoires militaires, cet arc mesure 50 mètres de haut et 45 mètres de large. Il est inspiré de l'arc antique de Titus à Rome.
                    
                    Sous l'Arc repose le Soldat Inconnu depuis 1921, dont la flamme est ravivée chaque soir à 18h30. Cette tradition honore tous les soldats morts pour la France.
                    
                    Les sculptures sont remarquables : 'La Marseillaise' de François Rude côté Champs-Élysées, 'Le Triomphe de 1810' de Cortot côté Wagram. Les piliers portent les noms de 128 batailles et 558 généraux.
                    
                    De sa terrasse, la vue sur les 12 avenues qui rayonnent depuis la place de l'Étoile est saisissante : on comprend pourquoi Haussmann a conçu Paris comme une étoile !
                    """
                case "Notre-Dame":
                    return """
                    Notre-Dame de Paris, 850 ans d'histoire et de foi !
                    
                    Commencée en 1163 sous l'évêque Maurice de Sully, achevée vers 1345. Cette cathédrale gothique révolutionne l'architecture : voûtes sur croisées d'ogives, arcs-boutants, rosaces géantes.
                    
                    Victor Hugo la sauve de la démolition en 1831 avec son roman 'Notre-Dame de Paris'. Napoléon s'y fait couronner empereur en 1804. De Gaulle y célèbre la Libération en 1944.
                    
                    L'incendie d'avril 2019 émeut le monde entier. La flèche s'effondre, la charpente 'forêt' du 13ème siècle brûle, mais les tours et les trésors sont sauvés par les pompiers de Paris.
                    
                    Reconstruction en cours : les artisans redonnent vie aux techniques médiévales. Charpentiers, tailleurs de pierre, maîtres verriers reconstruisent à l'identique cette merveille gothique.
                    """
                case "Louvre":
                    return """
                    Voici le Louvre, plus grand musée du monde avec ses 35 000 œuvres exposées !
                    
                    Ancien palais royal construit en 1190, transformé en musée en 1793 pendant la Révolution française. Ses 8 départements abritent des trésors de l'humanité : Mona Lisa, Vénus de Milo, Victoire de Samothrace.
                    
                    La pyramide de verre, inaugurée en 1989 par l'architecte Ieoh Ming Pei, fut d'abord controversée. Aujourd'hui, elle illumine le hall Napoléon et est devenue emblématique du musée moderne.
                    
                    10 millions de visiteurs par an viennent admirer 9 000 ans d'art et de civilisations. Pour voir toutes les œuvres 30 secondes chacune, il faudrait... 100 jours non-stop !
                    
                    La Joconde mesure seulement 77 cm sur 53 cm. Son sourire énigmatique fascine depuis 5 siècles. Léonard de Vinci l'a peinte entre 1503 et 1506, mais ne s'en est jamais séparé.
                    """
                case "Sacré-Cœur":
                    return """
                    Le Sacré-Cœur, joyau blanc dominant Paris depuis la butte Montmartre !
                    
                    Construit entre 1875 et 1914, ce monument expiatoire répond aux malheurs de la France : défaite de 1870, Commune de Paris. L'architecte Paul Abadie s'inspire de Saint-Marc de Venise et du Panthéon de Rome.
                    
                    La basilique est construite en pierre de Château-Landon, qui blanchit avec l'âge et la pluie. C'est pourquoi elle reste toujours immaculée !
                    
                    L'intérieur abrite la plus grande mosaïque de France : 475 mètres carrés représentant le Christ en gloire. Les vitraux, détruits en 1944, ont été refaits après-guerre.
                    
                    Depuis le parvis, la vue sur Paris est spectaculaire. On dit que par temps clair, on peut voir jusqu'à 50 kilomètres à la ronde !
                    """
                case "Champs-Élysées":
                    return """
                    Les Champs-Élysées, la plus belle avenue du monde !
                    
                    Longue de 1,9 kilomètres, elle relie la place de la Concorde à l'Arc de Triomphe. Créée au 17ème siècle, elle était alors un simple chemin bordé de champs et de marais.
                    
                    Haussmann la transforme au 19ème siècle en avenue prestigieuse. Les marronniers, plantés en 1834, donnent son caractère unique à cette artère majestueuse.
                    
                    Anecdote : chaque année, le 14 juillet, le défilé militaire descend les Champs-Élysées. Et le dernier dimanche d'août, le Tour de France s'y termine en apothéose !
                    
                    Les Champs-Élysées accueillent les plus grandes marques du luxe mondial. C'est aussi le lieu de célébration des victoires sportives françaises, comme en 1998 pour la Coupe du monde de football.
                    """
                case "Place de la Concorde":
                    return """
                    La place de la Concorde, la plus grande place de Paris !
                    
                    Créée entre 1755 et 1775, elle s'appelait d'abord place Louis XV. Pendant la Révolution, elle devient place de la Révolution et voit l'exécution de Louis XVI et Marie-Antoinette.
                    
                    L'obélisque de Louxor, offert par l'Égypte en 1836, trône au centre. Haute de 23 mètres, elle date du règne de Ramsès II, il y a 3300 ans. Les hiéroglyphes racontent ses exploits militaires.
                    
                    Les 8 statues représentent les principales villes de France : Lyon, Marseille, Bordeaux, Nantes, Rouen, Brest, Strasbourg et Lille. Chaque ville est représentée par une femme assise.
                    
                    Anecdote : l'obélisque a failli tomber lors de son transport depuis l'Égypte ! Le navire qui le transportait a failli couler dans la Méditerranée.
                    """
                case "Palais Garnier":
                    return """
                    Le Palais Garnier, temple de l'art lyrique et de l'architecture du 19ème siècle !
                    
                    Construit entre 1861 et 1875 par Charles Garnier, il est inauguré en 1875. L'empereur Napoléon III le commande après un attentat contre lui à l'ancien opéra de la rue Le Peletier.
                    
                    Le grand escalier de marbre est un chef-d'œuvre : 30 mètres de haut, éclairé par un lustre monumental. Le plafond de la salle, peint par Chagall en 1964, représente les plus grandes œuvres lyriques.
                    
                    Le fantôme de l'Opéra, créé par Gaston Leroux en 1910, a rendu ce lieu légendaire. La loge n°5, réservée au fantôme, existe réellement !
                    
                    L'Opéra abrite la plus grande scène d'Europe : 60 mètres de large, 27 mètres de profondeur. Le plafond de la salle pèse 8 tonnes et peut être soulevé pour changer les décors.
                    """
                case "Parc du Luxembourg":
                    return """
                    Le jardin du Luxembourg, poumon vert du Quartier Latin !
                    
                    Créé en 1612 par Marie de Médicis, il s'inspire des jardins de Boboli à Florence. Le palais du Luxembourg, aujourd'hui siège du Sénat, était sa résidence parisienne.
                    
                    Le parc abrite 106 statues, dont la célèbre Statue de la Liberté de Bartholdi, réplique de celle de New York. La fontaine Médicis, construite en 1630, est un chef-d'œuvre de l'art baroque.
                    
                    Anecdote : le parc compte 20 000 arbres, dont des marronniers centenaires. Les enfants peuvent y faire naviguer des voiliers miniatures sur le grand bassin octogonal.
                    
                    Le jardin est divisé en plusieurs parties : le jardin à la française, le jardin anglais, l'orangerie. Il accueille aussi des ruches et un rucher-école depuis 1856 !
                    """
                case "Musée d'Orsay":
                    return """
                    Le musée d'Orsay, temple de l'art du 19ème siècle !
                    
                    Installé dans l'ancienne gare d'Orsay, construite pour l'Exposition universelle de 1900, le musée ouvre ses portes en 1986. L'architecte Gae Aulenti a transformé cette gare en écrin pour les arts.
                    
                    Le musée abrite la plus grande collection d'œuvres impressionnistes au monde : Monet, Renoir, Degas, Van Gogh, Cézanne. La salle des fêtes de l'hôtel, reconstituée, témoigne du luxe de l'époque.
                    
                    L'horloge monumentale, vestige de la gare, offre une vue imprenable sur Paris. Elle rappelle que ce lieu était autrefois le terminus de la ligne Paris-Orléans.
                    
                    Anecdote : la gare était si moderne pour l'époque qu'elle avait l'électricité et des ascenseurs ! Elle a servi de décor au film 'Le Procès' d'Orson Welles en 1962.
                    """
                default:
                    return "Bienvenue à \(locationName) ! Découvrez l'histoire fascinante de ce lieu emblématique de Paris avec des anecdotes captivantes et des détails historiques précis."
                }
            case .tangier:
                switch locationName {
                case "Place du 9 Avril 1947":
                    return """
                    Bienvenue sur la Place du 9 Avril 1947, cœur historique de Tanger !
                    
                    Cette place commémore le discours du sultan Mohammed V, prononcé le 9 avril 1947, qui marqua le début de la lutte pour l'indépendance du Maroc. Le sultan y déclara son attachement à l'unité nationale et à la souveraineté marocaine.
                    
                    La place est entourée de bâtiments coloniaux et de cafés historiques. C'est ici que se réunissaient les intellectuels et les nationalistes marocains pendant la période du protectorat.
                    
                    Anecdote : la place était autrefois le point de départ des caravanes vers l'Afrique subsaharienne. Les marchands y négociaient leurs marchandises avant de partir vers le sud.
                    
                    Aujourd'hui, c'est un lieu de rencontre animé où les Tangérois se retrouvent pour discuter, boire un thé à la menthe ou simplement observer la vie qui passe.
                    """
                case "Kasbah de Tanger":
                    return """
                    La Kasbah de Tanger, forteresse historique dominant la médina !
                    
                    Construite au 17ème siècle par les sultans alaouites, cette citadelle protégeait la ville des attaques maritimes. Ses murs épais et ses tours de guet témoignent de son rôle défensif stratégique.
                    
                    La Kasbah abrite le palais du sultan, transformé en musée. Les jardins andalous, avec leurs fontaines et leurs orangers, offrent une oasis de verdure au cœur de la ville.
                    
                    Anecdote : la Kasbah a servi de décor à de nombreux films, notamment 'Casablanca' en 1942. Humphrey Bogart y a tourné plusieurs scènes mémorables.
                    
                    Depuis les remparts, la vue sur le détroit de Gibraltar est spectaculaire. Par temps clair, on peut voir les côtes espagnoles et même l'Afrique du Nord au-delà du détroit.
                    """
                case "Place de France":
                    return """
                    La Place de France, témoin de l'histoire cosmopolite de Tanger !
                    
                    Cette place élégante, construite pendant la période internationale de Tanger (1923-1956), reflète l'influence française dans la ville. Elle était le centre de la zone française du protectorat.
                    
                    Les bâtiments qui l'entourent mélangent architecture française et éléments mauresques. Les arcades abritent des cafés historiques où se réunissaient les écrivains et artistes de l'époque.
                    
                    Anecdote : la place était le point de rencontre des espions internationaux pendant la Seconde Guerre mondiale. Tanger, ville neutre, attirait les agents de toutes les puissances.
                    
                    Aujourd'hui, la place conserve son charme d'antan avec ses terrasses de cafés et ses palmiers. C'est un lieu prisé pour prendre un verre en fin d'après-midi.
                    """
                case "Grand Socco":
                    return """
                    Le Grand Socco, place centrale et animée de Tanger !
                    
                    'Socco' signifie 'marché' en arabe. Cette place était autrefois le cœur commercial de la ville, où se tenaient les marchés traditionnels. Les caravanes y déchargeaient leurs marchandises.
                    
                    La place est dominée par l'église espagnole, construite en 1925, qui témoigne de l'influence espagnole à Tanger. Son architecture néo-mudéjar est unique dans la ville.
                    
                    Anecdote : le Grand Socco était le point de départ des bus vers l'Espagne. Les Tangérois partaient d'ici pour traverser le détroit vers Algeciras ou Tarifa.
                    
                    Aujourd'hui, c'est un carrefour animé où se croisent piétons, voitures et bus. Les cafés autour de la place sont des lieux de rencontre traditionnels.
                    """
                case "Petit Socco":
                    return """
                    Le Petit Socco, cœur historique de la médina de Tanger !
                    
                    Cette petite place, plus intime que le Grand Socco, était le centre de la vie sociale traditionnelle. Les cafés qui l'entourent sont historiques et ont accueilli de nombreux écrivains.
                    
                    Le Petit Socco était le lieu de rencontre des intellectuels et des artistes pendant la période internationale. William Burroughs, Paul Bowles et d'autres écrivains y ont séjourné.
                    
                    Anecdote : le café Central, sur la place, était le rendez-vous des espions et des journalistes pendant la guerre froide. Les conversations politiques y étaient animées.
                    
                    Aujourd'hui, la place conserve son atmosphère authentique. Les cafés traditionnels servent encore le thé à la menthe et les pâtisseries marocaines.
                    """
                case "Cap Spartel":
                    return """
                    Le Cap Spartel, point de rencontre entre l'Atlantique et la Méditerranée !
                    
                    Ce cap majestueux marque l'extrémité nord-ouest de l'Afrique. C'est ici que se rencontrent l'océan Atlantique et la mer Méditerranée, créant des courants marins spectaculaires.
                    
                    Le phare du Cap Spartel, construit en 1864 par le sultan Mohammed IV, guide les navires depuis plus de 150 ans. Il mesure 24 mètres de haut et sa portée atteint 30 kilomètres.
                    
                    Anecdote : le phare a été construit avec des pierres importées d'Angleterre. Son architecture unique mélange styles européen et mauresque.
                    
                    Depuis le cap, la vue sur le détroit de Gibraltar est époustouflante. Par temps clair, on peut voir les côtes espagnoles et même les montagnes du Rif au sud.
                    """
                case "Grotte d'Hercule":
                    return """
                    La Grotte d'Hercule, légende et géologie réunies !
                    
                    Cette grotte naturelle, creusée par l'érosion marine, s'ouvre sur l'Atlantique. Selon la légende, Hercule s'y serait reposé après avoir séparé l'Europe de l'Afrique en créant le détroit de Gibraltar.
                    
                    La grotte présente une ouverture en forme de carte de l'Afrique, créée naturellement par l'érosion. Les stalactites et stalagmites témoignent de millions d'années d'histoire géologique.
                    
                    Anecdote : la grotte a servi de refuge aux contrebandiers et aux pêcheurs pendant des siècles. Elle abrite aussi des peintures rupestres datant de la préhistoire.
                    
                    L'ambiance mystérieuse de la grotte, avec le bruit des vagues et les jeux de lumière, en fait un lieu magique et contemplatif.
                    """
                case "Plage de Malabata":
                    return """
                    La Plage de Malabata, perle de l'Atlantique tangérois !
                    
                    Cette plage de sable fin s'étend sur plusieurs kilomètres le long de la côte atlantique. Son nom 'Malabata' signifie 'la bien-aimée' en arabe dialectal.
                    
                    La plage est bordée de falaises calcaires qui offrent des vues spectaculaires sur l'océan. Les couchers de soleil y sont particulièrement magnifiques.
                    
                    Anecdote : la plage était autrefois le lieu de prédilection des artistes et écrivains de la Beat Generation. Paul Bowles y passait de longues heures à contempler l'horizon.
                    
                    Aujourd'hui, c'est un lieu de détente prisé des Tangérois et des touristes. Les restaurants de poisson frais bordent la plage.
                    """
                case "Musée de la Kasbah":
                    return """
                    Le Musée de la Kasbah, trésor culturel de Tanger !
                    
                    Installé dans l'ancien palais du sultan, ce musée abrite une collection exceptionnelle d'objets d'art et d'artisanat marocain. L'architecture du palais est un chef-d'œuvre de l'art islamique.
                    
                    Les jardins andalous du musée, avec leurs fontaines et leurs orangers, offrent une oasis de verdure. Ils témoignent de l'influence arabo-andalouse dans la région.
                    
                    Anecdote : le palais a accueilli de nombreux dignitaires étrangers, dont Winston Churchill qui y a séjourné pendant la Seconde Guerre mondiale.
                    
                    Les collections comprennent des céramiques, des tapis, des armes et des bijoux traditionnels. Chaque pièce raconte une partie de l'histoire de Tanger.
                    """
                case "Cimetière américain":
                    return """
                    Le Cimetière américain, mémoire de l'histoire militaire !
                    
                    Ce cimetière militaire américain honore les soldats américains morts pendant la Seconde Guerre mondiale en Afrique du Nord. Il est situé sur une colline offrant une vue panoramique sur Tanger.
                    
                    Les tombes blanches, parfaitement alignées, témoignent du sacrifice de ces hommes. Le cimetière est entretenu par l'American Battle Monuments Commission.
                    
                    Anecdote : le cimetière abrite aussi les tombes de quelques civils américains qui vivaient à Tanger pendant la guerre. C'est un lieu de recueillement et de mémoire.
                    
                    L'architecture du cimetière, avec ses colonnes et ses jardins, reflète le style néoclassique américain. C'est un lieu de paix et de contemplation.
                    """
                default:
                    return "Bienvenue à \(locationName) ! Découvrez l'histoire fascinante de ce lieu emblématique de Tanger avec des anecdotes captivantes et des détails historiques précis."
                }
            case .casablanca:
                switch locationName {
                case "Mosquée Hassan II":
                    return """
                    La Mosquée Hassan II, chef-d'œuvre architectural de Casablanca !
                    
                    Construite entre 1986 et 1993, cette mosquée est la plus grande du Maroc et l'une des plus grandes au monde. Elle peut accueillir 25 000 fidèles à l'intérieur et 80 000 sur l'esplanade.
                    
                    Le minaret, haut de 210 mètres, est le plus haut du monde. Il est surmonté d'un laser qui pointe vers La Mecque. L'architecture mélange styles traditionnel marocain et moderne.
                    
                    Anecdote : la mosquée est construite partiellement sur la mer. Le sol en verre permet de voir l'océan Atlantique sous les pieds des fidèles pendant la prière.
                    
                    Les matériaux utilisés viennent de tout le Maroc : marbre d'Agadir, bois de cèdre de l'Atlas, zelliges de Fès. C'est un véritable musée de l'artisanat marocain.
                    """
                case "Place Mohammed V":
                    return """
                    La Place Mohammed V, cœur administratif de Casablanca !
                    
                    Cette place majestueuse, construite pendant le protectorat français, est le centre névralgique de la ville. Elle abrite les principaux bâtiments administratifs et la préfecture.
                    
                    L'architecture de la place mélange styles art déco et mauresque. Les bâtiments qui l'entourent témoignent de l'influence française dans la ville moderne.
                    
                    Anecdote : la place était le lieu de rassemblement des manifestations pour l'indépendance du Maroc. C'est ici que le sultan Mohammed V prononça son discours historique en 1955.
                    
                    Aujourd'hui, la place est un carrefour animé où se croisent piétons, voitures et tramways. Les palmiers et les fontaines lui donnent un aspect méditerranéen.
                    """
                case "Médina de Casablanca":
                    return """
                    La Médina de Casablanca, cœur historique de la ville !
                    
                    Bien que plus récente que les médinas de Fès ou Marrakech, celle de Casablanca a son charme unique. Elle fut construite au 18ème siècle par le sultan Sidi Mohammed Ben Abdallah.
                    
                    Les ruelles étroites et sinueuses abritent des souks traditionnels, des mosquées historiques et des maisons traditionnelles. L'ambiance y est plus authentique que dans la ville moderne.
                    
                    Anecdote : la médina a été partiellement détruite pendant les bombardements de la Seconde Guerre mondiale. Sa reconstruction a préservé son caractère traditionnel.
                    
                    Les souks de la médina proposent épices, textiles, bijoux et artisanat local. C'est un lieu idéal pour découvrir l'artisanat marocain authentique.
                    """
                case "Cathédrale du Sacré-Cœur":
                    return """
                    La Cathédrale du Sacré-Cœur, témoin de l'histoire coloniale !
                    
                    Construite entre 1930 et 1953, cette cathédrale de style art déco est un exemple unique d'architecture religieuse moderne au Maroc. Elle fut désaffectée après l'indépendance.
                    
                    L'architecture de la cathédrale mélange styles gothique, art déco et éléments mauresques. Les vitraux et les sculptures témoignent du talent des artisans de l'époque.
                    
                    Anecdote : la cathédrale a servi de décor au film 'Casablanca' en 1942. Bien que le film ait été tourné en studio, l'architecture de la ville a inspiré les décors.
                    
                    Aujourd'hui, la cathédrale est fermée au culte mais reste un monument architectural remarquable. Son état de conservation témoigne de la qualité de sa construction.
                    """
                case "Place des Nations Unies":
                    return """
                    La Place des Nations Unies, centre moderne de Casablanca !
                    
                    Cette place moderne, construite après l'indépendance, symbolise le Maroc contemporain. Elle abrite des bâtiments administratifs et commerciaux de style moderne.
                    
                    La place est un carrefour important de la ville, où se croisent plusieurs axes majeurs. L'architecture des bâtiments reflète l'influence internationale de Casablanca.
                    
                    Anecdote : la place a été le lieu de nombreuses manifestations politiques et culturelles. Elle symbolise l'ouverture du Maroc vers le monde.
                    
                    Les cafés et restaurants autour de la place en font un lieu de rencontre animé. C'est un bon point de départ pour explorer la ville moderne.
                    """
                case "Ain Diab":
                    return """
                    Ain Diab, quartier balnéaire de Casablanca !
                    
                    Ce quartier résidentiel et balnéaire s'étend le long de la corniche atlantique. Il est connu pour ses plages, ses restaurants de poisson et son ambiance décontractée.
                    
                    La corniche d'Ain Diab, longue de plusieurs kilomètres, est un lieu de promenade prisé des Casablancais. Les couchers de soleil y sont spectaculaires.
                    
                    Anecdote : Ain Diab était autrefois un village de pêcheurs. Le développement du quartier a commencé pendant le protectorat français.
                    
                    Les restaurants de poisson frais bordent la corniche. C'est le lieu idéal pour déguster les spécialités maritimes de Casablanca.
                    """
                case "Musée du Judaïsme Marocain":
                    return """
                    Le Musée du Judaïsme Marocain, témoin de la diversité culturelle !
                    
                    Ce musée unique au monde raconte l'histoire de la communauté juive marocaine, présente depuis plus de 2000 ans. Il abrite des objets religieux, des costumes et des documents historiques.
                    
                    L'histoire des juifs marocains est riche et complexe. Ils ont contribué à la culture, à l'économie et aux arts du Maroc pendant des siècles.
                    
                    Anecdote : le Maroc a été un refuge pour les juifs expulsés d'Espagne en 1492. La communauté juive marocaine était l'une des plus importantes du monde arabe.
                    
                    Le musée témoigne de la tolérance religieuse qui a longtemps caractérisé le Maroc. C'est un lieu de mémoire et de dialogue interculturel.
                    """
                case "Parc de la Ligue Arabe":
                    return """
                    Le Parc de la Ligue Arabe, poumon vert de Casablanca !
                    
                    Ce grand parc public, créé pendant le protectorat français, offre une oasis de verdure au cœur de la ville moderne. Il abrite de nombreuses espèces d'arbres et de plantes.
                    
                    Le parc est un lieu de détente prisé des Casablancais. Les allées ombragées, les fontaines et les espaces de jeux en font un endroit familial.
                    
                    Anecdote : le parc abrite des arbres centenaires plantés pendant la période coloniale. Certains spécimens sont uniques au Maroc.
                    
                    Les week-ends, le parc s'anime avec des familles, des promeneurs et des musiciens. C'est un lieu de rencontre et de convivialité.
                    """
                case "Marché Central":
                    return """
                    Le Marché Central, temple de la gastronomie casablancaise !
                    
                    Ce marché couvert, construit dans les années 1920, est le cœur gastronomique de Casablanca. Il abrite des étals de poisson frais, de viande, de fruits et légumes.
                    
                    L'architecture du marché, avec ses arcades et ses coupoles, est un exemple d'architecture coloniale bien préservée. L'ambiance y est authentique et animée.
                    
                    Anecdote : le marché est réputé pour la qualité de ses produits frais. Les pêcheurs y débarquent leur pêche du matin directement sur les étals.
                    
                    Les restaurants du marché proposent les meilleures spécialités maritimes de Casablanca. C'est le lieu idéal pour découvrir la cuisine locale authentique.
                    """
                case "Twin Center":
                    return """
                    Le Twin Center, symbole de Casablanca moderne !
                    
                    Ces deux tours jumelles, construites en 1999, sont devenues le symbole de la Casablanca moderne et internationale. Elles abritent des bureaux, des hôtels et des centres commerciaux.
                    
                    Haute de 115 mètres, chaque tour a une forme unique inspirée de l'architecture islamique traditionnelle. L'architecture mélange modernité et références culturelles.
                    
                    Anecdote : les tours ont été conçues par l'architecte Ricardo Bofill. Leur forme évoque les minarets traditionnels marocains.
                    
                    Le centre commercial au pied des tours propose des boutiques internationales et des restaurants. C'est un lieu de shopping moderne et animé.
                    """
                default:
                    return "Bienvenue à \(locationName) ! Découvrez l'histoire fascinante de ce lieu emblématique de Casablanca avec des anecdotes captivantes et des détails historiques précis."
                }
            case .marrakech:
                switch locationName {
                case "Place Jemaa el-Fna":
                    return """
                    La Place Jemaa el-Fna, cœur battant de Marrakech !
                    
                    Cette place mythique, classée au patrimoine mondial de l'UNESCO, est le centre névralgique de la ville depuis le 11ème siècle. Son nom signifie 'Place des Trépassés' en arabe, car elle servait autrefois d'exécutions publiques.
                    
                    La place s'anime dès le matin avec les vendeurs de jus d'orange, les charmeurs de serpents, les acrobates et les conteurs. Le soir, elle se transforme en immense restaurant à ciel ouvert avec des dizaines de stands de cuisine traditionnelle.
                    
                    Anecdote : la place change complètement d'atmosphère entre le jour et la nuit. Le jour, c'est un lieu de spectacle et de commerce. La nuit, c'est un immense restaurant populaire où les Marrakchis se retrouvent.
                    
                    Les minarets de la Koutoubia dominent la place et servent de repère aux visiteurs. La vue depuis les terrasses des cafés sur la place est spectaculaire, surtout au coucher du soleil.
                    """
                case "Médina de Marrakech":
                    return """
                    La Médina de Marrakech, labyrinthe de ruelles et de souks !
                    
                    Fondée au 11ème siècle par les Almoravides, la médina de Marrakech est l'une des plus grandes et des plus anciennes du Maroc. Ses murailles roses, construites en pisé, s'étendent sur 19 kilomètres.
                    
                    Les souks de la médina sont organisés par corporation : souk des épices, souk des tapis, souk des bijoux, souk des babouches. Chaque souk a sa spécialité et ses artisans traditionnels.
                    
                    Anecdote : la médina abrite plus de 100 000 habitants et 40 000 artisans. C'est une ville dans la ville, avec ses propres règles et traditions.
                    
                    Les riads, maisons traditionnelles avec jardin intérieur, sont les joyaux cachés de la médina. Beaucoup ont été transformés en hôtels de charme.
                    """
                case "Koutoubia":
                    return """
                    La Koutoubia, joyau de l'architecture almohade !
                    
                    Construite au 12ème siècle par les Almoravides, cette mosquée est la plus grande de Marrakech. Son minaret de 77 mètres de haut est le modèle de tous les minarets marocains, notamment la Giralda de Séville.
                    
                    Le nom 'Koutoubia' vient de 'koutoub', les livres, car il y avait autrefois un marché de livres à proximité. La mosquée est un chef-d'œuvre de l'architecture islamique avec ses proportions parfaites.
                    
                    Anecdote : le minaret a servi de modèle pour la construction de la Giralda de Séville. Les architectes espagnols s'en sont inspirés lors de la construction de la cathédrale de Séville.
                    
                    La mosquée est entourée de jardins magnifiques, les jardins de la Koutoubia, qui offrent une vue imprenable sur le minaret. C'est un lieu de promenade prisé des Marrakchis.
                    """
                case "Palais Bahia":
                    return """
                    Le Palais Bahia, chef-d'œuvre de l'architecture marocaine !
                    
                    Construit à la fin du 19ème siècle par le grand vizir Si Moussa, ce palais était destiné à sa favorite, Bahia. L'architecture mélange styles arabo-andalou et marocain traditionnel.
                    
                    Le palais compte 160 pièces réparties autour de plusieurs cours et jardins. Les décors en stuc, les plafonds en cèdre sculpté et les zelliges témoignent du raffinement de l'artisanat marocain.
                    
                    Anecdote : le palais a été pillé après la mort de Si Moussa. Les meubles et objets précieux ont été dispersés, mais l'architecture et les décors sont restés intacts.
                    
                    Les jardins du palais, avec leurs orangers et leurs fontaines, offrent une oasis de fraîcheur au cœur de la médina. C'est un lieu de promenade paisible et contemplatif.
                    """
                case "Jardin Majorelle":
                    return """
                    Le Jardin Majorelle, oasis de verdure et d'art !
                    
                    Créé par le peintre français Jacques Majorelle dans les années 1920, ce jardin botanique est un chef-d'œuvre d'art et de nature. Le bleu Majorelle, couleur emblématique du jardin, a été créé spécialement pour ce lieu.
                    
                    Le jardin abrite plus de 300 espèces de plantes du monde entier, notamment des cactus, des bambous et des palmiers. L'architecture du jardin mélange styles art déco et oriental.
                    
                    Anecdote : le jardin a été sauvé de la destruction par Yves Saint Laurent et Pierre Bergé en 1980. Ils l'ont restauré et ouvert au public. Yves Saint Laurent y a même fait construire sa villa.
                    
                    Le musée berbère, installé dans l'ancien atelier de Majorelle, présente une collection exceptionnelle d'objets d'art berbère. C'est un lieu de découverte de la culture amazighe.
                    """
                case "Palais El Badi":
                    return """
                    Le Palais El Badi, ruines majestueuses d'un palais légendaire !
                    
                    Construit au 16ème siècle par le sultan Ahmed al-Mansour, ce palais était considéré comme l'un des plus beaux du monde. Son nom 'El Badi' signifie 'l'Incomparable' en arabe.
                    
                    Le palais comptait 360 pièces décorées d'or, d'onyx et de marbre. Il abritait des jardins immenses avec des bassins, des fontaines et des orangers. Aujourd'hui, seules les ruines témoignent de sa splendeur passée.
                    
                    Anecdote : le palais a été pillé par le sultan Moulay Ismail au 17ème siècle. Il a emporté tous les matériaux précieux pour construire sa capitale, Meknès.
                    
                    Les ruines du palais, avec leurs murs en pisé et leurs cours immenses, offrent une vue imprenable sur la médina. C'est un lieu de promenade romantique et contemplatif.
                    """
                case "Tombeaux Saadiens":
                    return """
                    Les Tombeaux Saadiens, chef-d'œuvre de l'art funéraire marocain !
                    
                    Ces mausolées, construits au 16ème siècle par les sultans saadiens, abritent les tombes de la dynastie saadienne. L'architecture et les décors témoignent du raffinement de l'art marocain de l'époque.
                    
                    Les tombeaux sont divisés en plusieurs salles : la salle des douze colonnes, la salle des trois niches, la salle de prière. Chaque salle est décorée de stucs, de zelliges et de bois sculpté.
                    
                    Anecdote : les tombeaux ont été murés pendant des siècles pour éviter le pillage. Ils n'ont été redécouverts qu'en 1917 par les autorités françaises.
                    
                    Le jardin des tombeaux, avec ses cyprès et ses orangers, offre une atmosphère paisible et recueillie. C'est un lieu de mémoire et de contemplation.
                    """
                case "Médersa Ben Youssef":
                    return """
                    La Médersa Ben Youssef, joyau de l'architecture islamique !
                    
                    Construite au 14ème siècle, cette école coranique est l'une des plus grandes et des plus belles du Maroc. Elle pouvait accueillir jusqu'à 900 étudiants qui logeaient dans 130 cellules.
                    
                    L'architecture de la médersa est un chef-d'œuvre de l'art islamique : cour centrale avec bassin, salle de prière avec mihrab, cellules des étudiants. Les décors en stuc, bois sculpté et zelliges sont d'une finesse exceptionnelle.
                    
                    Anecdote : la médersa a été restaurée dans les années 1950 par les autorités françaises. Elle est aujourd'hui un musée ouvert au public.
                    
                    La cour centrale de la médersa, avec son bassin et ses arcades sculptées, est un lieu de contemplation et de méditation. L'ambiance y est paisible et spirituelle.
                    """
                case "Souk de Marrakech":
                    return """
                    Le Souk de Marrakech, labyrinthe de commerce et d'artisanat !
                    
                    Les souks de Marrakech s'étendent sur plusieurs kilomètres dans la médina. Ils sont organisés par corporation : souk des épices, souk des tapis, souk des bijoux, souk des babouches, souk des métaux.
                    
                    Chaque souk a sa spécialité et ses artisans traditionnels. Les techniques de fabrication n'ont pas changé depuis des siècles : tapis tissés à la main, bijoux forgés, cuir tanné.
                    
                    Anecdote : les souks sont organisés en corporations depuis le Moyen Âge. Chaque corporation a ses règles, ses traditions et ses secrets de fabrication.
                    
                    L'art du marchandage est de rigueur dans les souks. C'est une tradition ancestrale qui fait partie de la culture marocaine. Les prix ne sont jamais fixes !
                    """
                case "Jardin de la Ménara":
                    return """
                    Le Jardin de la Ménara, oasis de verdure aux portes de Marrakech !
                    
                    Créé au 12ème siècle par les Almohades, ce jardin est un chef-d'œuvre d'ingénierie hydraulique. Le grand bassin central, alimenté par un système de canaux souterrains, irrigue tout le jardin.
                    
                    Le pavillon central, construit au 19ème siècle, offre une vue imprenable sur le bassin et les oliveraies. C'est un lieu de promenade prisé des Marrakchis, surtout au coucher du soleil.
                    
                    Anecdote : le bassin de la Ménara a une profondeur de 2 mètres et peut contenir 30 000 mètres cubes d'eau. Il sert de réservoir pour irriguer les oliveraies environnantes.
                    
                    Les oliveraies du jardin, avec leurs arbres centenaires, offrent une promenade paisible et ombragée. C'est un lieu de détente et de contemplation.
                    """
                default:
                    return "Bienvenue à \(locationName) ! Découvrez l'histoire fascinante de ce lieu emblématique de Marrakech avec des anecdotes captivantes et des détails historiques précis."
                }

            default:
                return "Bienvenue à \(locationName) ! Découvrez l'histoire fascinante de ce lieu emblématique de \(city.displayName) avec des anecdotes captivantes et des détails historiques précis."
            }
        }
        
        private func getCityImageURL(for city: City) -> String {
            let cityImages = [
                "paris": "https://images.unsplash.com/photo-1502602898536-47ad22581b52?w=800&h=600&fit=crop",
                "lyon": "https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800&h=600&fit=crop",
                "marseille": "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop",
                "barcelona": "https://images.unsplash.com/photo-1551218808-94e220e084d2?w=800&h=600&fit=crop",
                "rome": "https://images.unsplash.com/photo-1553975213-4c35f5a2a1e6?w=800&h=600&fit=crop",
                "london": "https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800&h=600&fit=crop",
                "amsterdam": "https://images.unsplash.com/photo-1608270586420-2c4ffd2304c9?w=800&h=600&fit=crop",
                "berlin": "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&h=600&fit=crop"
            ]
            
            return cityImages[city.rawValue] ?? "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&h=600&fit=crop"
        }
        
        private func getBaseCoordinates(for city: City) -> (lat: Double, lng: Double) {
            // Coordonnées de base pour les villes non listées dans getRealCoordinates
            switch city {
            case .marseille:
                return (43.2965, 5.3698) // Marseille
            case .toulouse:
                return (43.6047, 1.4442) // Toulouse
            case .nice:
                return (43.7102, 7.2620) // Nice
            case .nantes:
                return (47.2184, -1.5536) // Nantes
            case .fez:
                return (34.0181, -5.0078) // Fès
            case .rabat:
                return (34.0209, -6.8416) // Rabat
            case .agadir:
                return (30.4278, -9.5981) // Agadir
            case .oujda:
                return (34.6814, -1.9086) // Oujda
            case .tetouan:
                return (35.5711, -5.3724) // Tétouan
            case .meknes:
                return (33.8935, -5.5473) // Meknès
            case .istanbul:
                return (41.0082, 28.9784) // Istanbul
            case .ankara:
                return (39.9334, 32.8597) // Ankara
            case .izmir:
                return (38.4192, 27.1287) // Izmir
            case .antalya:
                return (36.8969, 30.7133) // Antalya
            case .bursa:
                return (40.1885, 29.0610) // Bursa
            case .adana:
                return (37.0000, 35.3213) // Adana
            case .gaziantep:
                return (37.0662, 37.3833) // Gaziantep
            case .konya:
                return (37.8716, 32.4846) // Konya
            case .mersin:
                return (36.8121, 34.6415) // Mersin
            case .tokyo:
                return (35.6762, 139.6503) // Tokyo
            case .osaka:
                return (34.6937, 135.5023) // Osaka
            case .kyoto:
                return (35.0116, 135.7681) // Kyoto
            case .yokohama:
                return (35.4437, 139.6380) // Yokohama
            case .nagoya:
                return (35.1815, 136.9066) // Nagoya
            case .sapporo:
                return (43.0618, 141.3545) // Sapporo
            case .kobe:
                return (34.6901, 135.1955) // Kobe
            case .fukuoka:
                return (33.5902, 130.4017) // Fukuoka
            case .beijing:
                return (39.9042, 116.4074) // Beijing
            case .shanghai:
                return (31.2304, 121.4737) // Shanghai
            case .guangzhou:
                return (23.1291, 113.2644) // Guangzhou
            case .shenzhen:
                return (22.3193, 114.1694) // Shenzhen
            case .chengdu:
                return (30.5728, 104.0668) // Chengdu
            case .xian:
                return (34.3416, 108.9398) // Xi'an
            case .nanjing:
                return (32.0603, 118.7969) // Nanjing
            case .antwerp:
                return (51.2194, 4.4025) // Anvers
            case .ghent:
                return (51.0500, 3.7303) // Gand
            case .charleroi:
                return (50.4108, 4.4446) // Charleroi
            case .liege:
                return (50.8503, 5.6889) // Liège
            case .bruges:
                return (51.2093, 3.2247) // Bruges
            case .namur:
                return (50.4669, 4.8675) // Namur

            case .mons:
                return (50.4542, 3.9561) // Mons
            case .zurich:
                return (47.3769, 8.5417) // Zurich
            case .geneva:
                return (46.2044, 6.1432) // Genève

            case .bern:
                return (46.9479, 7.4474) // Berne
            case .lausanne:
                return (46.5197, 6.6323) // Lausanne
            case .winterthur:
                return (47.4979, 8.7286) // Winterthour
            case .stGallen:
                return (47.4245, 9.3767) // Saint-Gall
            case .lucerne:
                return (47.0502, 8.3093) // Lucerne
            case .berlin:
                return (52.5200, 13.4050) // Berlin
            case .hamburg:
                return (53.5511, 9.9937) // Hambourg
            case .munich:
                return (48.1351, 11.5820) // Munich
            case .cologne:
                return (50.9375, 6.9603) // Cologne
            case .frankfurt:
                return (50.1109, 8.6821) // Francfort
            case .stuttgart:
                return (48.7758, 9.1829) // Stuttgart

            case .dortmund:
                return (51.5136, 7.4653) // Dortmund
            case .essen:
                return (51.4556, 7.0116) // Essen
            case .rome:
                return (41.9028, 12.4964) // Rome
            case .milan:
                return (45.4642, 9.1900) // Milan
            case .naples:
                return (40.8518, 14.2681) // Naples
            case .turin:
                return (45.0703, 7.6869) // Turin
            case .palermo:
                return (38.1157, 13.3615) // Palerme
            case .genoa:
                return (44.4056, 8.9463) // Gênes
            case .bologna:
                return (44.4949, 11.3426) // Bologne
            case .florence:
                return (43.7696, 11.2558) // Florence
            case .bari:
                return (41.1171, 16.8719) // Bari
            case .catania:
                return (37.5079, 15.0830) // Catane
            case .madrid:
                return (40.4168, -3.7038) // Madrid
            case .barcelona:
                return (41.3851, 2.1734) // Barcelone
            case .valencia:
                return (39.4699, -0.3763) // Valence
            case .seville:
                return (37.3891, -5.9845) // Séville
            case .zaragoza:
                return (41.6488, -0.8891) // Saragosse
            case .malaga:
                return (36.7213, -4.4217) // Malaga
            case .murcia:
                return (37.9922, -1.1307) // Murcie
            case .palma:
                return (39.5696, 2.6502) // Palma
            case .lasPalmas:
                return (28.1235, -15.4366) // Las Palmas
            case .bilbao:
                return (43.2627, -2.9253) // Bilbao
            case .amsterdam:
                return (52.3676, 4.9041) // Amsterdam
            case .rotterdam:
                return (51.9225, 4.4792) // Rotterdam
            case .theHague:
                return (52.0705, 4.3007) // La Haye
            case .utrecht:
                return (52.0907, 5.1214) // Utrecht
            case .eindhoven:
                return (51.4416, 5.4697) // Eindhoven
            case .tilburg:
                return (51.5719, 5.0672) // Tilbourg
            case .groningen:
                return (53.2194, 6.5665) // Groningue
            case .breda:
                return (51.5719, 4.7683) // Breda
            case .nijmegen:
                return (51.8425, 5.8533) // Nimègue
            case .enschede:
                return (52.2215, 6.8937) // Enschede
            case .london:
                return (51.5074, -0.1278) // Londres
            case .birmingham:
                return (52.4862, -1.8904) // Birmingham
            case .leeds:
                return (53.8008, -1.5491) // Leeds
            case .glasgow:
                return (55.8642, -4.2518) // Glasgow
            case .sheffield:
                return (53.3811, -1.4701) // Sheffield
            case .bradford:
                return (53.8008, -1.5491) // Bradford
            case .edinburgh:
                return (55.9533, -3.1883) // Édimbourg
            case .liverpool:
                return (53.4084, -2.9916) // Liverpool
            case .manchester:
                return (53.4808, -2.2426) // Manchester
            case .bristol:
                return (51.4545, -2.5879) // Bristol
            default:
                return (48.8566, 2.3522) // Paris par défaut
            }
        }
    } 