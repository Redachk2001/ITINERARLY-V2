import Foundation
import CoreLocation
import MapKit

class ComprehensivePlaceSearchService: ObservableObject {
    
    // Base de données locale des lieux connus
    private let localPlacesDatabase: [LocalPlace] = [
        // PISCINES DE BRUXELLES
        LocalPlace(
            name: "Piscine de Molenbeek",
            address: "Boulevard Mettewie 17, 1080 Molenbeek-Saint-Jean",
            latitude: 50.8547,
            longitude: 4.3247,
            category: .swimmingPool,
            description: "Piscine municipale de Molenbeek-Saint-Jean"
        ),
        LocalPlace(
            name: "Piscine de Schaerbeek",
            address: "Rue Royale Sainte-Marie 22, 1030 Schaerbeek",
            latitude: 50.8674,
            longitude: 4.3774,
            category: .swimmingPool,
            description: "Piscine municipale de Schaerbeek"
        ),
        LocalPlace(
            name: "Piscine de Saint-Gilles",
            address: "Rue de la Victoire 26, 1060 Saint-Gilles",
            latitude: 50.8274,
            longitude: 4.3456,
            category: .swimmingPool,
            description: "Piscine municipale de Saint-Gilles"
        ),
        LocalPlace(
            name: "Piscine de Woluwe-Saint-Pierre",
            address: "Avenue de Tervueren 205, 1150 Woluwe-Saint-Pierre",
            latitude: 50.8347,
            longitude: 4.4567,
            category: .swimmingPool,
            description: "Piscine municipale de Woluwe-Saint-Pierre"
        ),
        LocalPlace(
            name: "Piscine de Forest",
            address: "Avenue du Mont Kemmel 2, 1190 Forest",
            latitude: 50.8123,
            longitude: 4.3234,
            category: .swimmingPool,
            description: "Piscine municipale de Forest"
        ),
        LocalPlace(
            name: "Piscine de Jette",
            address: "Rue de la Reine 1, 1090 Jette",
            latitude: 50.8765,
            longitude: 4.3234,
            category: .swimmingPool,
            description: "Piscine municipale de Jette"
        ),
        LocalPlace(
            name: "Piscine de Koekelberg",
            address: "Place de la Reine 1, 1081 Koekelberg",
            latitude: 50.8634,
            longitude: 4.3234,
            category: .swimmingPool,
            description: "Piscine municipale de Koekelberg"
        ),
        LocalPlace(
            name: "Piscine de Berchem-Sainte-Agathe",
            address: "Rue des Trois Tilleuls 1, 1082 Berchem-Sainte-Agathe",
            latitude: 50.8634,
            longitude: 4.2934,
            category: .swimmingPool,
            description: "Piscine municipale de Berchem-Sainte-Agathe"
        ),
        LocalPlace(
            name: "Piscine de Ganshoren",
            address: "Place de la Reine 1, 1083 Ganshoren",
            latitude: 50.8734,
            longitude: 4.3034,
            category: .swimmingPool,
            description: "Piscine municipale de Ganshoren"
        ),
        LocalPlace(
            name: "Piscine de Laeken",
            address: "Rue des Palais 1, 1020 Laeken",
            latitude: 50.8834,
            longitude: 4.3534,
            category: .swimmingPool,
            description: "Piscine municipale de Laeken"
        ),
        LocalPlace(
            name: "Piscine de Neder-Over-Heembeek",
            address: "Rue de la Reine 1, 1120 Neder-Over-Heembeek",
            latitude: 50.8934,
            longitude: 4.3834,
            category: .swimmingPool,
            description: "Piscine municipale de Neder-Over-Heembeek"
        ),
        LocalPlace(
            name: "Piscine de Haren",
            address: "Rue de la Reine 1, 1130 Haren",
            latitude: 50.8934,
            longitude: 4.4134,
            category: .swimmingPool,
            description: "Piscine municipale de Haren"
        ),
        LocalPlace(
            name: "Piscine de Woluwe-Saint-Lambert",
            address: "Avenue de Tervueren 205, 1200 Woluwe-Saint-Lambert",
            latitude: 50.8447,
            longitude: 4.4567,
            category: .swimmingPool,
            description: "Piscine municipale de Woluwe-Saint-Lambert"
        ),
        LocalPlace(
            name: "Piscine d'Etterbeek",
            address: "Rue de la Reine 1, 1040 Etterbeek",
            latitude: 50.8334,
            longitude: 4.3834,
            category: .swimmingPool,
            description: "Piscine municipale d'Etterbeek"
        ),
        LocalPlace(
            name: "Piscine d'Ixelles",
            address: "Rue de la Reine 1, 1050 Ixelles",
            latitude: 50.8234,
            longitude: 4.3734,
            category: .swimmingPool,
            description: "Piscine municipale d'Ixelles"
        ),
        LocalPlace(
            name: "Piscine d'Uccle",
            address: "Rue de la Reine 1, 1180 Uccle",
            latitude: 50.8134,
            longitude: 4.3334,
            category: .swimmingPool,
            description: "Piscine municipale d'Uccle"
        ),
        LocalPlace(
            name: "Piscine de Watermael-Boitsfort",
            address: "Rue de la Reine 1, 1170 Watermael-Boitsfort",
            latitude: 50.8034,
            longitude: 4.4134,
            category: .swimmingPool,
            description: "Piscine municipale de Watermael-Boitsfort"
        ),
        LocalPlace(
            name: "Piscine d'Auderghem",
            address: "Rue de la Reine 1, 1160 Auderghem",
            latitude: 50.8134,
            longitude: 4.4334,
            category: .swimmingPool,
            description: "Piscine municipale d'Auderghem"
        ),
        LocalPlace(
            name: "Piscine d'Evere",
            address: "Rue de la Reine 1, 1140 Evere",
            latitude: 50.8734,
            longitude: 4.4034,
            category: .swimmingPool,
            description: "Piscine municipale d'Evere"
        ),
        LocalPlace(
            name: "Piscine de Saint-Josse-ten-Noode",
            address: "Rue de la Reine 1, 1210 Saint-Josse-ten-Noode",
            latitude: 50.8534,
            longitude: 4.3734,
            category: .swimmingPool,
            description: "Piscine municipale de Saint-Josse-ten-Noode"
        ),
        
        // SALLES D'ESCALADE DE BRUXELLES
        LocalPlace(
            name: "Climbing Center Brussels",
            address: "Rue de la Poudrière 7, 1000 Bruxelles",
            latitude: 50.8503,
            longitude: 4.3517,
            category: .climbingGym,
            description: "Salle d'escalade en centre-ville"
        ),
        LocalPlace(
            name: "Mur d'Escalade de Forest",
            address: "Avenue du Mont Kemmel 2, 1190 Forest",
            latitude: 50.8123,
            longitude: 4.3234,
            category: .climbingGym,
            description: "Mur d'escalade de Forest"
        ),
        LocalPlace(
            name: "Bloc Shop Brussels",
            address: "Rue de la Poudrière 7, 1000 Bruxelles",
            latitude: 50.8503,
            longitude: 4.3517,
            category: .climbingGym,
            description: "Salle de bloc et escalade"
        ),
        LocalPlace(
            name: "Climbing Center Ixelles",
            address: "Rue de la Reine 1, 1050 Ixelles",
            latitude: 50.8234,
            longitude: 4.3734,
            category: .climbingGym,
            description: "Salle d'escalade d'Ixelles"
        ),
        LocalPlace(
            name: "Mur d'Escalade de Schaerbeek",
            address: "Rue Royale Sainte-Marie 22, 1030 Schaerbeek",
            latitude: 50.8674,
            longitude: 4.3774,
            category: .climbingGym,
            description: "Mur d'escalade de Schaerbeek"
        ),
        LocalPlace(
            name: "Climbing Center Woluwe",
            address: "Avenue de Tervueren 205, 1150 Woluwe-Saint-Pierre",
            latitude: 50.8347,
            longitude: 4.4567,
            category: .climbingGym,
            description: "Salle d'escalade de Woluwe"
        ),
        LocalPlace(
            name: "Mur d'Escalade de Molenbeek",
            address: "Boulevard Mettewie 17, 1080 Molenbeek-Saint-Jean",
            latitude: 50.8547,
            longitude: 4.3247,
            category: .climbingGym,
            description: "Mur d'escalade de Molenbeek"
        ),
        LocalPlace(
            name: "Climbing Center Uccle",
            address: "Rue de la Reine 1, 1180 Uccle",
            latitude: 50.8134,
            longitude: 4.3334,
            category: .climbingGym,
            description: "Salle d'escalade d'Uccle"
        ),
        LocalPlace(
            name: "Mur d'Escalade d'Etterbeek",
            address: "Rue de la Reine 1, 1040 Etterbeek",
            latitude: 50.8334,
            longitude: 4.3834,
            category: .climbingGym,
            description: "Mur d'escalade d'Etterbeek"
        ),
        LocalPlace(
            name: "Climbing Center Saint-Gilles",
            address: "Rue de la Victoire 26, 1060 Saint-Gilles",
            latitude: 50.8274,
            longitude: 4.3456,
            category: .climbingGym,
            description: "Salle d'escalade de Saint-Gilles"
        ),
        
        // BOWLING DE BRUXELLES
        LocalPlace(
            name: "Bowling de Woluwe",
            address: "Avenue de Tervueren 205, 1150 Woluwe-Saint-Pierre",
            latitude: 50.8347,
            longitude: 4.4567,
            category: .bowling,
            description: "Bowling de Woluwe-Saint-Pierre"
        ),
        LocalPlace(
            name: "Bowling de Schaerbeek",
            address: "Rue Royale Sainte-Marie 22, 1030 Schaerbeek",
            latitude: 50.8674,
            longitude: 4.3774,
            category: .bowling,
            description: "Bowling de Schaerbeek"
        ),
        LocalPlace(
            name: "Bowling de Forest",
            address: "Avenue du Mont Kemmel 2, 1190 Forest",
            latitude: 50.8123,
            longitude: 4.3234,
            category: .bowling,
            description: "Bowling de Forest"
        ),
        LocalPlace(
            name: "Bowling de Molenbeek",
            address: "Boulevard Mettewie 17, 1080 Molenbeek-Saint-Jean",
            latitude: 50.8547,
            longitude: 4.3247,
            category: .bowling,
            description: "Bowling de Molenbeek"
        ),
        LocalPlace(
            name: "Bowling d'Ixelles",
            address: "Rue de la Reine 1, 1050 Ixelles",
            latitude: 50.8234,
            longitude: 4.3734,
            category: .bowling,
            description: "Bowling d'Ixelles"
        ),
        LocalPlace(
            name: "Bowling d'Uccle",
            address: "Rue de la Reine 1, 1180 Uccle",
            latitude: 50.8134,
            longitude: 4.3334,
            category: .bowling,
            description: "Bowling d'Uccle"
        ),
        LocalPlace(
            name: "Bowling d'Etterbeek",
            address: "Rue de la Reine 1, 1040 Etterbeek",
            latitude: 50.8334,
            longitude: 4.3834,
            category: .bowling,
            description: "Bowling d'Etterbeek"
        ),
        LocalPlace(
            name: "Bowling de Saint-Gilles",
            address: "Rue de la Victoire 26, 1060 Saint-Gilles",
            latitude: 50.8274,
            longitude: 4.3456,
            category: .bowling,
            description: "Bowling de Saint-Gilles"
        ),
        
        // RESTAURANTS POPULAIRES DE BRUXELLES
        LocalPlace(
            name: "Restaurant Le Gourmet",
            address: "Rue de la Loi 123, 1000 Bruxelles",
            latitude: 50.8503,
            longitude: 4.3517,
            category: .restaurant,
            description: "Restaurant gastronomique"
        ),
        LocalPlace(
            name: "Bistrot du Coin",
            address: "Rue des Bouchers 45, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .restaurant,
            description: "Bistrot traditionnel"
        ),
        LocalPlace(
            name: "Chez Léon",
            address: "Rue des Bouchers 18, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .restaurant,
            description: "Restaurant de moules célèbre"
        ),
        LocalPlace(
            name: "La Roue d'Or",
            address: "Rue des Chapeliers 26, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .restaurant,
            description: "Restaurant traditionnel bruxellois"
        ),
        LocalPlace(
            name: "Aux Armes de Bruxelles",
            address: "Rue des Bouchers 13, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .restaurant,
            description: "Restaurant historique"
        ),
        LocalPlace(
            name: "Le Pré Salé",
            address: "Rue de Flandre 20, 1000 Bruxelles",
            latitude: 50.8576,
            longitude: 4.3523,
            category: .restaurant,
            description: "Restaurant de fruits de mer"
        ),
        LocalPlace(
            name: "La Quincaillerie",
            address: "Rue du Page 45, 1050 Ixelles",
            latitude: 50.8234,
            longitude: 4.3734,
            category: .restaurant,
            description: "Restaurant branché d'Ixelles"
        ),
        LocalPlace(
            name: "Le Pain Quotidien",
            address: "Rue Antoine Dansaert 16, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .restaurant,
            description: "Restaurant bio et artisanal"
        ),
        LocalPlace(
            name: "Le Cercle des Voyageurs",
            address: "Rue des Grands Carmes 18, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .restaurant,
            description: "Restaurant international"
        ),
        LocalPlace(
            name: "La Bécasse",
            address: "Rue de Tabora 11, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .restaurant,
            description: "Restaurant traditionnel"
        ),
        LocalPlace(
            name: "Le Zinneke",
            address: "Place de la Bourse 1, 1000 Bruxelles",
            latitude: 50.8484,
            longitude: 4.3497,
            category: .restaurant,
            description: "Restaurant belge moderne"
        ),
        LocalPlace(
            name: "La Maison du Cygne",
            address: "Grand Place 9, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .restaurant,
            description: "Restaurant gastronomique"
        ),
        LocalPlace(
            name: "Le Marmiton",
            address: "Rue des Bouchers 43, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .restaurant,
            description: "Restaurant français"
        ),
        LocalPlace(
            name: "L'Écailler du Palais Royal",
            address: "Rue Bodenbroek 18, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .restaurant,
            description: "Restaurant de fruits de mer"
        ),
        LocalPlace(
            name: "Le Petit Château",
            address: "Rue du Château 5, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .restaurant,
            description: "Restaurant traditionnel"
        ),
        LocalPlace(
            name: "La Villa Lorraine",
            address: "Avenue du Vivier d'Oie 75, 1170 Watermael-Boitsfort",
            latitude: 50.8034,
            longitude: 4.4134,
            category: .restaurant,
            description: "Restaurant gastronomique"
        ),
        LocalPlace(
            name: "Le Chalet Robinson",
            address: "Avenue de la Foresterie 1, 1050 Ixelles",
            latitude: 50.8234,
            longitude: 4.3734,
            category: .restaurant,
            description: "Restaurant au bord du lac"
        ),
        LocalPlace(
            name: "Le Comptoir des Galeries",
            address: "Galerie du Roi 9, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .restaurant,
            description: "Restaurant dans les galeries"
        ),
        LocalPlace(
            name: "La Belle Maraîchère",
            address: "Rue des Foulons 47, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .restaurant,
            description: "Restaurant de poissons"
        ),
        LocalPlace(
            name: "Le Steakhouse",
            address: "Rue des Bouchers 25, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .restaurant,
            description: "Restaurant de viandes"
        ),
        LocalPlace(
            name: "L'Atelier de la Main d'Or",
            address: "Rue des Chartreux 66, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .restaurant,
            description: "Restaurant gastronomique"
        ),
        
        // CAFÉS DE BRUXELLES
        LocalPlace(
            name: "Café Central",
            address: "Place de la Bourse 18, 1000 Bruxelles",
            latitude: 50.8484,
            longitude: 4.3497,
            category: .cafe,
            description: "Café historique"
        ),
        LocalPlace(
            name: "Le Cirio",
            address: "Rue de la Bourse 18, 1000 Bruxelles",
            latitude: 50.8484,
            longitude: 4.3497,
            category: .cafe,
            description: "Café historique depuis 1886"
        ),
        LocalPlace(
            name: "Le Falstaff",
            address: "Rue Henri Maus 17, 1000 Bruxelles",
            latitude: 50.8484,
            longitude: 4.3497,
            category: .cafe,
            description: "Café Art Nouveau"
        ),
        LocalPlace(
            name: "Le Greenwich",
            address: "Rue des Chartreux 7, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .cafe,
            description: "Café traditionnel bruxellois"
        ),
        LocalPlace(
            name: "Le Poechenellekelder",
            address: "Rue du Chêne 5, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .cafe,
            description: "Café près du Manneken Pis"
        ),
        LocalPlace(
            name: "Le Délirium Café",
            address: "Impasse de la Fidélité 4, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .cafe,
            description: "Café avec grande sélection de bières"
        ),
        LocalPlace(
            name: "Le Monk",
            address: "Rue Sainte-Catherine 42, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .cafe,
            description: "Café branché"
        ),
        LocalPlace(
            name: "Le Café Belga",
            address: "Place Eugène Flagey 18, 1050 Ixelles",
            latitude: 50.8234,
            longitude: 4.3734,
            category: .cafe,
            description: "Café populaire d'Ixelles"
        ),
        LocalPlace(
            name: "Le Café de la Presse",
            address: "Rue de la Presse 1, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .cafe,
            description: "Café des journalistes"
        ),
        LocalPlace(
            name: "Le Café Métropole",
            address: "Place de Brouckère 31, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .cafe,
            description: "Café historique"
        ),
        LocalPlace(
            name: "Le Café de la Gare",
            address: "Place de la Gare Centrale 1, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .cafe,
            description: "Café de la gare centrale"
        ),
        LocalPlace(
            name: "Le Café du Sablon",
            address: "Place du Grand Sablon 1, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .cafe,
            description: "Café du Sablon"
        ),
        LocalPlace(
            name: "Le Café de la Place",
            address: "Place de la Bourse 1, 1000 Bruxelles",
            latitude: 50.8484,
            longitude: 4.3497,
            category: .cafe,
            description: "Café de la place de la Bourse"
        ),
        LocalPlace(
            name: "Le Café des Étoiles",
            address: "Rue du Marché aux Herbes 7, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .cafe,
            description: "Café avec terrasse"
        ),
        LocalPlace(
            name: "Le Café de la Monnaie",
            address: "Place de la Monnaie 1, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .cafe,
            description: "Café près de l'opéra"
        ),
        LocalPlace(
            name: "Le Café de la Rue",
            address: "Rue des Bouchers 25, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .cafe,
            description: "Café de la rue des Bouchers"
        ),
        
        // MUSÉES DE BRUXELLES
        LocalPlace(
            name: "Musées Royaux des Beaux-Arts",
            address: "Rue de la Régence 3, 1000 Bruxelles",
            latitude: 50.8411,
            longitude: 4.3606,
            category: .museum,
            description: "Musée d'art classique et moderne"
        ),
        LocalPlace(
            name: "Musée Magritte",
            address: "Place Royale 1, 1000 Bruxelles",
            latitude: 50.8411,
            longitude: 4.3606,
            category: .museum,
            description: "Musée dédié à René Magritte"
        ),
        LocalPlace(
            name: "Musée des Instruments de Musique",
            address: "Rue Montagne de la Cour 2, 1000 Bruxelles",
            latitude: 50.8411,
            longitude: 4.3606,
            category: .museum,
            description: "MIM - Musée des instruments de musique"
        ),
        LocalPlace(
            name: "Musée Horta",
            address: "Rue Américaine 25, 1060 Saint-Gilles",
            latitude: 50.8274,
            longitude: 4.3456,
            category: .museum,
            description: "Maison-musée de Victor Horta"
        ),
        LocalPlace(
            name: "Musée du Cinquantenaire",
            address: "Parc du Cinquantenaire 10, 1000 Bruxelles",
            latitude: 50.8411,
            longitude: 4.3606,
            category: .museum,
            description: "Musée d'art et d'histoire"
        ),
        LocalPlace(
            name: "Musée des Sciences Naturelles",
            address: "Rue Vautier 29, 1000 Bruxelles",
            latitude: 50.8411,
            longitude: 4.3606,
            category: .museum,
            description: "Musée des sciences naturelles"
        ),
        LocalPlace(
            name: "Musée de la Ville de Bruxelles",
            address: "Grand Place 1, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .museum,
            description: "Musée de l'histoire de Bruxelles"
        ),
        LocalPlace(
            name: "Musée du Costume et de la Dentelle",
            address: "Rue de la Violette 12, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .museum,
            description: "Musée du costume et de la dentelle"
        ),
        LocalPlace(
            name: "Musée Charlier",
            address: "Avenue des Arts 16, 1210 Saint-Josse-ten-Noode",
            latitude: 50.8534,
            longitude: 4.3734,
            category: .museum,
            description: "Musée d'art décoratif"
        ),
        LocalPlace(
            name: "Musée Wiertz",
            address: "Rue Vautier 62, 1050 Ixelles",
            latitude: 50.8234,
            longitude: 4.3734,
            category: .museum,
            description: "Musée Antoine Wiertz"
        ),
        LocalPlace(
            name: "Musée Constantin Meunier",
            address: "Rue de l'Abbaye 59, 1050 Ixelles",
            latitude: 50.8234,
            longitude: 4.3734,
            category: .museum,
            description: "Musée Constantin Meunier"
        ),
        LocalPlace(
            name: "Musée David et Alice van Buuren",
            address: "Avenue Léo Errera 41, 1180 Uccle",
            latitude: 50.8134,
            longitude: 4.3334,
            category: .museum,
            description: "Maison-musée Art Déco"
        ),
        LocalPlace(
            name: "Musée de la Bande Dessinée",
            address: "Rue des Sables 20, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .museum,
            description: "Centre belge de la bande dessinée"
        ),
        LocalPlace(
            name: "Musée du Cacao et du Chocolat",
            address: "Rue de la Tête d'Or 9, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .museum,
            description: "Musée du chocolat belge"
        ),
        LocalPlace(
            name: "Musée de la Bière",
            address: "Grand Place 10, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .museum,
            description: "Musée de la bière belge"
        ),
        LocalPlace(
            name: "Musée du Jouet",
            address: "Rue de l'Association 24, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .museum,
            description: "Musée du jouet"
        ),
        
        // PARCS ET ESPACES VERTS DE BRUXELLES
        LocalPlace(
            name: "Parc de Bruxelles",
            address: "Place des Palais, 1000 Bruxelles",
            latitude: 50.8421,
            longitude: 4.3634,
            category: .nature,
            description: "Parc royal de Bruxelles"
        ),
        LocalPlace(
            name: "Parc du Cinquantenaire",
            address: "Parc du Cinquantenaire, 1000 Bruxelles",
            latitude: 50.8411,
            longitude: 4.3606,
            category: .nature,
            description: "Parc avec arc de triomphe"
        ),
        LocalPlace(
            name: "Parc de Laeken",
            address: "Avenue du Parc Royal, 1020 Laeken",
            latitude: 50.8834,
            longitude: 4.3534,
            category: .nature,
            description: "Parc royal de Laeken"
        ),
        LocalPlace(
            name: "Parc de Forest",
            address: "Avenue du Mont Kemmel, 1190 Forest",
            latitude: 50.8123,
            longitude: 4.3234,
            category: .nature,
            description: "Parc de Forest"
        ),
        LocalPlace(
            name: "Parc de Woluwe",
            address: "Avenue de Tervueren, 1150 Woluwe-Saint-Pierre",
            latitude: 50.8347,
            longitude: 4.4567,
            category: .nature,
            description: "Parc de Woluwe"
        ),
        LocalPlace(
            name: "Parc Josaphat",
            address: "Avenue Louis Bertrand, 1030 Schaerbeek",
            latitude: 50.8674,
            longitude: 4.3774,
            category: .nature,
            description: "Parc Josaphat à Schaerbeek"
        ),
        LocalPlace(
            name: "Parc de Wolvendael",
            address: "Avenue Wolvendael, 1180 Uccle",
            latitude: 50.8134,
            longitude: 4.3334,
            category: .nature,
            description: "Parc de Wolvendael à Uccle"
        ),
        LocalPlace(
            name: "Parc Tenbosch",
            address: "Rue Tenbosch, 1050 Ixelles",
            latitude: 50.8234,
            longitude: 4.3734,
            category: .nature,
            description: "Parc Tenbosch à Ixelles"
        ),
        LocalPlace(
            name: "Parc de la Cambre",
            address: "Avenue de la Cambre, 1050 Ixelles",
            latitude: 50.8234,
            longitude: 4.3734,
            category: .nature,
            description: "Parc de la Cambre"
        ),
        LocalPlace(
            name: "Parc Duden",
            address: "Avenue Duden, 1180 Uccle",
            latitude: 50.8134,
            longitude: 4.3334,
            category: .nature,
            description: "Parc Duden à Uccle"
        ),
        LocalPlace(
            name: "Parc de la Sauvagère",
            address: "Avenue de la Sauvagère, 1180 Uccle",
            latitude: 50.8134,
            longitude: 4.3334,
            category: .nature,
            description: "Parc de la Sauvagère"
        ),
        LocalPlace(
            name: "Parc de la Woluwe",
            address: "Avenue de la Woluwe, 1200 Woluwe-Saint-Lambert",
            latitude: 50.8447,
            longitude: 4.4567,
            category: .nature,
            description: "Parc de la Woluwe"
        ),
        LocalPlace(
            name: "Parc Malou",
            address: "Avenue de la Chasse, 1200 Woluwe-Saint-Lambert",
            latitude: 50.8447,
            longitude: 4.4567,
            category: .nature,
            description: "Parc Malou"
        ),
        LocalPlace(
            name: "Parc de la Jeunesse",
            address: "Avenue de la Jeunesse, 1080 Molenbeek-Saint-Jean",
            latitude: 50.8547,
            longitude: 4.3247,
            category: .nature,
            description: "Parc de la Jeunesse à Molenbeek"
        ),
        LocalPlace(
            name: "Parc de la Rosée",
            address: "Avenue de la Rosée, 1080 Molenbeek-Saint-Jean",
            latitude: 50.8547,
            longitude: 4.3247,
            category: .nature,
            description: "Parc de la Rosée"
        ),
        LocalPlace(
            name: "Parc de la Cité Modèle",
            address: "Avenue de la Cité Modèle, 1080 Molenbeek-Saint-Jean",
            latitude: 50.8547,
            longitude: 4.3247,
            category: .nature,
            description: "Parc de la Cité Modèle"
        ),
        LocalPlace(
            name: "Parc de la Senne",
            address: "Quai de la Senne, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .nature,
            description: "Parc le long de la Senne"
        ),
        LocalPlace(
            name: "Parc du Maelbeek",
            address: "Avenue du Maelbeek, 1040 Etterbeek",
            latitude: 50.8334,
            longitude: 4.3834,
            category: .nature,
            description: "Parc du Maelbeek"
        ),
        LocalPlace(
            name: "Parc de la Petite Suisse",
            address: "Avenue de la Petite Suisse, 1050 Ixelles",
            latitude: 50.8234,
            longitude: 4.3734,
            category: .nature,
            description: "Parc de la Petite Suisse"
        ),
        
        // BARS DE BRUXELLES
        LocalPlace(
            name: "Bar du Quartier",
            address: "Rue des Bouchers 67, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .bar,
            description: "Bar traditionnel bruxellois"
        ),
        LocalPlace(
            name: "Le Délirium Café",
            address: "Impasse de la Fidélité 4, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .bar,
            description: "Bar avec grande sélection de bières"
        ),
        LocalPlace(
            name: "Le Monk",
            address: "Rue Sainte-Catherine 42, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .bar,
            description: "Bar branché"
        ),
        LocalPlace(
            name: "Le Poechenellekelder",
            address: "Rue du Chêne 5, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .bar,
            description: "Bar près du Manneken Pis"
        ),
        LocalPlace(
            name: "Le Greenwich",
            address: "Rue des Chartreux 7, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .bar,
            description: "Bar traditionnel bruxellois"
        ),
        LocalPlace(
            name: "Le Falstaff",
            address: "Rue Henri Maus 17, 1000 Bruxelles",
            latitude: 50.8484,
            longitude: 4.3497,
            category: .bar,
            description: "Bar Art Nouveau"
        ),
        LocalPlace(
            name: "Le Cirio",
            address: "Rue de la Bourse 18, 1000 Bruxelles",
            latitude: 50.8484,
            longitude: 4.3497,
            category: .bar,
            description: "Bar historique depuis 1886"
        ),
        LocalPlace(
            name: "Le Café Belga",
            address: "Place Eugène Flagey 18, 1050 Ixelles",
            latitude: 50.8234,
            longitude: 4.3734,
            category: .bar,
            description: "Bar populaire d'Ixelles"
        ),
        LocalPlace(
            name: "Le Bar du Sablon",
            address: "Place du Grand Sablon 1, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .bar,
            description: "Bar du Sablon"
        ),
        LocalPlace(
            name: "Le Bar de la Place",
            address: "Place de la Bourse 1, 1000 Bruxelles",
            latitude: 50.8484,
            longitude: 4.3497,
            category: .bar,
            description: "Bar de la place de la Bourse"
        ),
        LocalPlace(
            name: "Le Bar des Étoiles",
            address: "Rue du Marché aux Herbes 7, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .bar,
            description: "Bar avec terrasse"
        ),
        LocalPlace(
            name: "Le Bar de la Monnaie",
            address: "Place de la Monnaie 1, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .bar,
            description: "Bar près de l'opéra"
        ),
        LocalPlace(
            name: "Le Bar de la Rue",
            address: "Rue des Bouchers 25, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .bar,
            description: "Bar de la rue des Bouchers"
        ),
        
        // AUTRES ACTIVITÉS DE BRUXELLES
        LocalPlace(
            name: "Cinéma UGC de Brouckère",
            address: "Place de Brouckère 38, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .entertainment,
            description: "Cinéma multiplex"
        ),
        LocalPlace(
            name: "Cinéma Aventure",
            address: "Galerie du Centre 57, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .entertainment,
            description: "Cinéma art et essai"
        ),
        LocalPlace(
            name: "Cinéma Nova",
            address: "Rue d'Arenberg 3, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .entertainment,
            description: "Cinéma indépendant"
        ),
        LocalPlace(
            name: "Théâtre Royal de la Monnaie",
            address: "Place de la Monnaie 1, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .entertainment,
            description: "Opéra de Bruxelles"
        ),
        LocalPlace(
            name: "Théâtre National",
            address: "Boulevard Émile Jacqmain 111, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .entertainment,
            description: "Théâtre national"
        ),
        LocalPlace(
            name: "Palais des Beaux-Arts",
            address: "Rue Ravenstein 23, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .entertainment,
            description: "Centre culturel"
        ),
        LocalPlace(
            name: "Bozar",
            address: "Rue Ravenstein 23, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .entertainment,
            description: "Palais des Beaux-Arts"
        ),
        LocalPlace(
            name: "Cirque Royal",
            address: "Rue de l'Enseignement 81, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .entertainment,
            description: "Salle de spectacle"
        ),
        LocalPlace(
            name: "Ancienne Belgique",
            address: "Boulevard Anspach 110, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .entertainment,
            description: "Salle de concert"
        ),
        LocalPlace(
            name: "Forest National",
            address: "Avenue du Globe 36, 1190 Forest",
            latitude: 50.8123,
            longitude: 4.3234,
            category: .entertainment,
            description: "Salle de concert"
        ),
        LocalPlace(
            name: "Botanique",
            address: "Rue Royale 236, 1210 Saint-Josse-ten-Noode",
            latitude: 50.8534,
            longitude: 4.3734,
            category: .entertainment,
            description: "Centre culturel"
        ),
        LocalPlace(
            name: "VK",
            address: "Boulevard de l'Empereur 4, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .entertainment,
            description: "Salle de concert"
        ),
        LocalPlace(
            name: "Fuse",
            address: "Rue Blaes 208, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .entertainment,
            description: "Club de musique électronique"
        ),
        LocalPlace(
            name: "Mirano",
            address: "Chaussée de Louvain 38, 1210 Saint-Josse-ten-Noode",
            latitude: 50.8534,
            longitude: 4.3734,
            category: .entertainment,
            description: "Club de musique"
        ),
        LocalPlace(
            name: "C12",
            address: "Rue du Marché aux Herbes 116, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .entertainment,
            description: "Club underground"
        ),
        LocalPlace(
            name: "Jeux d'Évasion Bruxelles",
            address: "Rue de la Loi 123, 1000 Bruxelles",
            latitude: 50.8503,
            longitude: 4.3517,
            category: .escapeRoom,
            description: "Salle d'escape game"
        ),
        LocalPlace(
            name: "Escape Room Brussels",
            address: "Rue des Bouchers 45, 1000 Bruxelles",
            latitude: 50.8476,
            longitude: 4.3523,
            category: .escapeRoom,
            description: "Salle d'escape game"
        ),
        LocalPlace(
            name: "Laser Game Brussels",
            address: "Rue de la Poudrière 7, 1000 Bruxelles",
            latitude: 50.8503,
            longitude: 4.3517,
            category: .laserTag,
            description: "Salle de laser game"
        ),
        LocalPlace(
            name: "Laser Tag Forest",
            address: "Avenue du Mont Kemmel 2, 1190 Forest",
            latitude: 50.8123,
            longitude: 4.3234,
            category: .laserTag,
            description: "Salle de laser tag"
        ),
        LocalPlace(
            name: "Paintball Brussels",
            address: "Rue de la Loi 123, 1000 Bruxelles",
            latitude: 50.8503,
            longitude: 4.3517,
            category: .paintball,
            description: "Terrain de paintball"
        ),
        LocalPlace(
            name: "Karting Brussels",
            address: "Avenue de Tervueren 205, 1150 Woluwe-Saint-Pierre",
            latitude: 50.8347,
            longitude: 4.4567,
            category: .karting,
            description: "Piste de karting"
        ),
        LocalPlace(
            name: "Mini Golf Woluwe",
            address: "Avenue de Tervueren 205, 1150 Woluwe-Saint-Pierre",
            latitude: 50.8347,
            longitude: 4.4567,
            category: .miniGolf,
            description: "Mini golf de Woluwe"
        ),
        LocalPlace(
            name: "Trampoline Park Brussels",
            address: "Rue de la Loi 123, 1000 Bruxelles",
            latitude: 50.8503,
            longitude: 4.3517,
            category: .trampolinePark,
            description: "Parc de trampolines"
        ),
        LocalPlace(
            name: "Parc d'Aventures Forest",
            address: "Avenue du Mont Kemmel 2, 1190 Forest",
            latitude: 50.8123,
            longitude: 4.3234,
            category: .adventurePark,
            description: "Parc d'aventures"
        ),
        LocalPlace(
            name: "Zoo d'Anvers",
            address: "Koningin Astridplein 20, 2018 Anvers",
            latitude: 51.2167,
            longitude: 4.4167,
            category: .zoo,
            description: "Zoo d'Anvers"
        ),
        LocalPlace(
            name: "Aquarium de Bruxelles",
            address: "Rue de la Loi 123, 1000 Bruxelles",
            latitude: 50.8503,
            longitude: 4.3517,
            category: .aquarium,
            description: "Aquarium de Bruxelles"
        ),
        LocalPlace(
            name: "Parc Aquatique Bruxelles",
            address: "Avenue de Tervueren 205, 1150 Woluwe-Saint-Pierre",
            latitude: 50.8347,
            longitude: 4.4567,
            category: .waterPark,
            description: "Parc aquatique"
        ),
        LocalPlace(
            name: "Patinoire de Forest",
            address: "Avenue du Mont Kemmel 2, 1190 Forest",
            latitude: 50.8123,
            longitude: 4.3234,
            category: .iceRink,
            description: "Patinoire de Forest"
        ),
        LocalPlace(
            name: "Patinoire de Woluwe",
            address: "Avenue de Tervueren 205, 1150 Woluwe-Saint-Pierre",
            latitude: 50.8347,
            longitude: 4.4567,
            category: .iceRink,
            description: "Patinoire de Woluwe"
        )
    ]
    
    func searchPlaces(
        for categories: [LocationCategory],
        near userLocation: CLLocation,
        maxDistance: Double,
        completion: @escaping ([Location]) -> Void
    ) {
        print("🔍 ComprehensivePlaceSearchService - Recherche pour \(categories.count) catégories")
        
        var allPlaces: [Location] = []
        let group = DispatchGroup()
        
        // 1. Recherche dans la base de données locale
        group.enter()
        searchLocalDatabase(for: categories, near: userLocation, maxDistance: maxDistance) { localPlaces in
            allPlaces.append(contentsOf: localPlaces)
            print("📚 Base locale: \(localPlaces.count) lieux trouvés")
            group.leave()
        }
        
        // 2. Recherche avec Apple Maps (améliorée)
        group.enter()
        searchWithAppleMaps(for: categories, near: userLocation, maxDistance: maxDistance) { applePlaces in
            allPlaces.append(contentsOf: applePlaces)
            print("🍎 Apple Maps: \(applePlaces.count) lieux trouvés")
            group.leave()
        }
        
        // 3. Recherche avec OpenStreetMap (gratuit et complet)
        group.enter()
        searchWithOpenStreetMap(for: categories, near: userLocation, maxDistance: maxDistance) { osmPlaces in
            allPlaces.append(contentsOf: osmPlaces)
            print("🗺️ OpenStreetMap: \(osmPlaces.count) lieux trouvés")
            group.leave()
        }
        
        group.notify(queue: .main) {
            // Dédupliquer et filtrer par distance
            let uniquePlaces = self.deduplicatePlaces(allPlaces)
            let nearbyPlaces = self.filterByDistance(places: uniquePlaces, userLocation: userLocation, maxDistance: maxDistance)
            
            print("✅ Total final: \(nearbyPlaces.count) lieux uniques")
            completion(nearbyPlaces)
        }
    }
    
    private func searchLocalDatabase(
        for categories: [LocationCategory],
        near userLocation: CLLocation,
        maxDistance: Double,
        completion: @escaping ([Location]) -> Void
    ) {
        let relevantPlaces = localPlacesDatabase.filter { place in
            categories.contains(place.category)
        }
        
        let nearbyPlaces = relevantPlaces.compactMap { localPlace in
            let placeLocation = CLLocation(latitude: localPlace.latitude, longitude: localPlace.longitude)
            let distance = userLocation.distance(from: placeLocation) / 1000.0
            
            if distance <= maxDistance {
                return Location(
                    id: UUID().uuidString,
                    name: localPlace.name,
                    address: localPlace.address,
                    latitude: localPlace.latitude,
                    longitude: localPlace.longitude,
                    category: localPlace.category,
                    description: localPlace.description,
                    imageURL: nil,
                    rating: 4.0,
                    openingHours: "Ouvert",
                    recommendedDuration: nil,
                    visitTips: nil
                )
            }
            return nil
        }
        
        completion(nearbyPlaces)
    }
    
    private func searchWithAppleMaps(
        for categories: [LocationCategory],
        near userLocation: CLLocation,
        maxDistance: Double,
        completion: @escaping ([Location]) -> Void
    ) {
        var allPlaces: [Location] = []
        let group = DispatchGroup()
        
        for category in categories {
            group.enter()
            
            let queries = generateQueriesForCategory(category)
            for query in queries {
                group.enter()
                
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = query
                request.region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    latitudinalMeters: maxDistance * 2000, // Convertir km en mètres
                    longitudinalMeters: maxDistance * 2000
                )
                request.resultTypes = [.pointOfInterest]
                
                let search = MKLocalSearch(request: request)
                search.start { response, error in
                    DispatchQueue.main.async {
                        if let response = response {
                            let places = response.mapItems.map { mapItem in
                                self.convertMapItemToLocation(mapItem, category: category)
                            }
                            allPlaces.append(contentsOf: places)
                        }
                        group.leave()
                    }
                }
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(allPlaces)
        }
    }
    
    private func searchWithOpenStreetMap(
        for categories: [LocationCategory],
        near userLocation: CLLocation,
        maxDistance: Double,
        completion: @escaping ([Location]) -> Void
    ) {
        // Utiliser l'API Overpass (OpenStreetMap) qui est gratuite et complète
        let overpassQueries = generateOverpassQueries(for: categories, userLocation: userLocation, maxDistance: maxDistance)
        
        var allPlaces: [Location] = []
        let group = DispatchGroup()
        
        for query in overpassQueries {
            group.enter()
            
            searchOverpassAPI(query: query) { places in
                allPlaces.append(contentsOf: places)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(allPlaces)
        }
    }
    
    private func generateQueriesForCategory(_ category: LocationCategory) -> [String] {
        switch category {
        case .swimmingPool:
            return ["piscine", "swimming pool", "centre aquatique", "natation", "piscine municipale", "piscine olympique", "piscine couverte"]
        case .climbingGym:
            return ["escalade", "climbing gym", "mur d'escalade", "salle d'escalade", "climbing center", "bloc", "voie escalade", "centre escalade"]
        case .bowling:
            return ["bowling", "bowling alley", "quilles", "jeu de quilles", "bowl", "bowling center"]
        case .restaurant:
            return ["restaurant", "resto", "gastronomie", "cuisine", "table", "manger", "dîner", "déjeuner"]
        case .cafe:
            return ["café", "coffee shop", "salon de thé", "cafétéria", "espresso", "cappuccino"]
        case .museum:
            return ["musée", "museum", "exposition", "galerie", "art", "histoire", "culture"]
        case .nature:
            return ["parc", "jardin", "espace vert", "forêt", "bois", "nature", "verdure"]
        case .bar:
            return ["bar", "pub", "brasserie", "cocktail", "bière", "alcool", "boisson"]
        case .entertainment:
            return ["cinéma", "théâtre", "concert", "spectacle", "divertissement", "loisir", "amusement"]
        case .shopping:
            return ["magasin", "boutique", "centre commercial", "shopping", "achat", "retail", "commerce", "store"]
        case .sport:
            return ["sport", "fitness", "gym", "salle de sport", "entraînement", "exercice", "musculation"]
        case .historical:
            return ["historique", "monument", "patrimoine", "architecture", "ancien", "classique"]
        case .religious:
            return ["église", "cathédrale", "temple", "mosquée", "synagogue", "religieux", "culte"]
        case .iceRink:
            return ["patinoire", "ice rink", "patinage", "glace", "skating"]
        case .miniGolf:
            return ["mini golf", "golf miniature", "putting", "golf mini", "parcours golf"]
        case .escapeRoom:
            return ["escape room", "escape game", "jeu d'évasion", "énigme", "mystère", "escape"]
        case .laserTag:
            return ["laser game", "laser tag", "combat laser", "arène laser", "laser"]
        case .paintball:
            return ["paintball", "airsoft", "combat", "balle", "tir"]
        case .karting:
            return ["karting", "kart", "circuit", "course", "voiture", "racing"]
        case .trampolinePark:
            return ["trampoline", "jump", "rebond", "parc trampoline", "trampoline park"]
        case .waterPark:
            return ["parc aquatique", "water park", "toboggan", "piscine", "aquatique"]
        case .adventurePark:
            return ["parc d'aventure", "aventure", "accrobranche", "tyrolienne", "parcours aventure"]
        case .zoo:
            return ["zoo", "parc animalier", "animaux", "faune", "sauvage"]
        case .aquarium:
            return ["aquarium", "poissons", "marine", "faune marine", "océan"]
        default:
            return [category.displayName.lowercased()]
        }
    }
    
    private func generateOverpassQueries(
        for categories: [LocationCategory],
        userLocation: CLLocation,
        maxDistance: Double
    ) -> [String] {
        var queries: [String] = []
        
        for category in categories {
            let osmTags = getOSMTags(for: category)
            for tag in osmTags {
                let query = """
                [out:json][timeout:25];
                (
                  node["\(tag.key)"="\(tag.value)"](around:\(Int(maxDistance * 1000)),\(userLocation.coordinate.latitude),\(userLocation.coordinate.longitude));
                  way["\(tag.key)"="\(tag.value)"](around:\(Int(maxDistance * 1000)),\(userLocation.coordinate.latitude),\(userLocation.coordinate.longitude));
                  relation["\(tag.key)"="\(tag.value)"](around:\(Int(maxDistance * 1000)),\(userLocation.coordinate.latitude),\(userLocation.coordinate.longitude));
                );
                out body;
                >;
                out skel qt;
                """
                queries.append(query)
            }
        }
        
        return queries
    }
    
    private func getOSMTags(for category: LocationCategory) -> [(key: String, value: String)] {
        switch category {
        case .swimmingPool:
            return [("leisure", "swimming_pool"), ("sport", "swimming")]
        case .climbingGym:
            return [("sport", "climbing"), ("leisure", "sports_centre")]
        case .bowling:
            return [("sport", "bowling"), ("leisure", "bowling_alley")]
        case .restaurant:
            return [("amenity", "restaurant"), ("cuisine", "french")]
        case .cafe:
            return [("amenity", "cafe"), ("cuisine", "coffee_shop")]
        case .museum:
            return [("tourism", "museum"), ("amenity", "museum")]
        case .nature:
            return [("leisure", "park"), ("landuse", "recreation_ground")]
        case .bar:
            return [("amenity", "bar"), ("amenity", "pub")]
        default:
            return []
        }
    }
    
    private func searchOverpassAPI(query: String, completion: @escaping ([Location]) -> Void) {
        guard let url = URL(string: "https://overpass-api.de/api/interpreter") else {
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = query.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("❌ Erreur Overpass API: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                do {
                    let places = try self.parseOverpassResponse(data: data)
                    completion(places)
                } catch {
                    print("❌ Erreur parsing Overpass: \(error)")
                    completion([])
                }
            }
        }.resume()
    }
    
    private func parseOverpassResponse(data: Data) throws -> [Location] {
        // Parser la réponse JSON d'Overpass
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let elements = json?["elements"] as? [[String: Any]] ?? []
        
        var places: [Location] = []
        
        for element in elements {
            if let tags = element["tags"] as? [String: Any],
               let name = tags["name"] as? String,
               let lat = element["lat"] as? Double,
               let lon = element["lon"] as? Double {
                
                let category = determineCategoryFromTags(tags)
                let address = tags["addr:street"] as? String ?? "Adresse non disponible"
                
                let location = Location(
                    id: UUID().uuidString,
                    name: name,
                    address: address,
                    latitude: lat,
                    longitude: lon,
                    category: category,
                    description: "Lieu trouvé via OpenStreetMap",
                    imageURL: nil,
                    rating: 4.0,
                    openingHours: "Ouvert",
                    recommendedDuration: nil,
                    visitTips: nil
                )
                
                places.append(location)
            }
        }
        
        return places
    }
    
    private func determineCategoryFromTags(_ tags: [String: Any]) -> LocationCategory {
        if tags["leisure"] as? String == "swimming_pool" || tags["sport"] as? String == "swimming" {
            return .swimmingPool
        } else if tags["sport"] as? String == "climbing" {
            return .climbingGym
        } else if tags["sport"] as? String == "bowling" || tags["leisure"] as? String == "bowling" {
            return .bowling
        } else if tags["amenity"] as? String == "restaurant" {
            return .restaurant
        } else if tags["amenity"] as? String == "cafe" {
            return .cafe
        } else if tags["tourism"] as? String == "museum" {
            return .museum
        } else if tags["leisure"] as? String == "park" {
            return .nature
        } else if tags["amenity"] as? String == "bar" {
            return .bar
        } else if tags["shop"] != nil {
            return .shopping
        } else if tags["leisure"] as? String == "sports_centre" {
            return .sport
        } else if tags["historic"] != nil {
            return .historical
        } else if tags["amenity"] as? String == "place_of_worship" {
            return .religious
        } else if tags["leisure"] as? String == "ice_rink" {
            return .iceRink
        } else if tags["leisure"] as? String == "miniature_golf" {
            return .miniGolf
        } else if tags["leisure"] as? String == "escape_game" {
            return .escapeRoom
        } else if tags["leisure"] as? String == "laser_tag" {
            return .laserTag
        } else if tags["leisure"] as? String == "paintball" {
            return .paintball
        } else if tags["leisure"] as? String == "go_kart" {
            return .karting
        } else if tags["leisure"] as? String == "trampoline_park" {
            return .trampolinePark
        } else if tags["leisure"] as? String == "water_park" {
            return .waterPark
        } else if tags["leisure"] as? String == "adventure_park" {
            return .adventurePark
        } else if tags["tourism"] as? String == "zoo" {
            return .zoo
        } else if tags["tourism"] as? String == "aquarium" {
            return .aquarium
        } else if tags["amenity"] as? String == "cinema" || tags["amenity"] as? String == "theatre" {
            return .entertainment
        }
        
        return .cafe // fallback
    }
    
    private func convertMapItemToLocation(_ mapItem: MKMapItem, category: LocationCategory) -> Location {
        // Vérifier que le lieu correspond vraiment à la catégorie recherchée
        let placeName = mapItem.name?.lowercased() ?? ""
        let categoryKeywords = getCategoryKeywords(for: category)
        
        let matchesCategory = categoryKeywords.contains { keyword in
            placeName.contains(keyword)
        }
        
        // Si ça ne correspond pas, ne pas inclure ce lieu
        guard matchesCategory else {
            return Location(
                id: UUID().uuidString,
                name: mapItem.name ?? "Lieu sans nom",
                address: mapItem.placemark.thoroughfare ?? "Adresse non disponible",
                latitude: mapItem.placemark.coordinate.latitude,
                longitude: mapItem.placemark.coordinate.longitude,
                category: .cafe, // Catégorie par défaut
                description: "Lieu trouvé via Apple Maps",
                imageURL: nil,
                rating: 4.0,
                openingHours: "Ouvert",
                recommendedDuration: nil,
                visitTips: nil
            )
        }
        
        // Construire une adresse complète
        let address = buildCompleteAddress(from: mapItem.placemark)
        
        return Location(
            id: UUID().uuidString,
            name: mapItem.name ?? "Lieu sans nom",
            address: address,
            latitude: mapItem.placemark.coordinate.latitude,
            longitude: mapItem.placemark.coordinate.longitude,
            category: category,
            description: "Lieu trouvé via Apple Maps",
            imageURL: nil,
            rating: 4.0,
            openingHours: "Ouvert",
            recommendedDuration: nil,
            visitTips: nil
        )
    }
    
    private func buildCompleteAddress(from placemark: MKPlacemark) -> String {
        var addressComponents: [String] = []
        
        if let thoroughfare = placemark.thoroughfare {
            addressComponents.append(thoroughfare)
        }
        if let subThoroughfare = placemark.subThoroughfare {
            addressComponents.append(subThoroughfare)
        }
        if let locality = placemark.locality {
            addressComponents.append(locality)
        }
        if let postalCode = placemark.postalCode {
            addressComponents.append(postalCode)
        }
        
        if addressComponents.isEmpty {
            return "Adresse non disponible"
        }
        
        return addressComponents.joined(separator: ", ")
    }
    
    private func getCategoryKeywords(for category: LocationCategory) -> [String] {
        switch category {
        case .swimmingPool:
            return ["piscine", "swimming", "aquatique", "natation"]
        case .climbingGym:
            return ["escalade", "climbing", "mur", "bloc", "voie"]
        case .bowling:
            return ["bowling", "quilles", "bowl"]
        case .restaurant:
            return ["restaurant", "resto", "gastronomie", "cuisine", "table", "manger"]
        case .cafe:
            return ["café", "coffee", "salon", "cafétéria", "espresso"]
        case .museum:
            return ["musée", "museum", "exposition", "galerie", "art"]
        case .nature:
            return ["parc", "jardin", "espace vert", "forêt", "bois", "nature"]
        case .bar:
            return ["bar", "pub", "brasserie", "cocktail", "bière"]
        case .entertainment:
            return ["cinéma", "théâtre", "concert", "spectacle", "divertissement"]
        case .shopping:
            return ["magasin", "boutique", "centre commercial", "shopping", "achat", "retail", "store"]
        case .sport:
            return ["sport", "fitness", "gym", "salle", "entraînement"]
        case .historical:
            return ["historique", "monument", "patrimoine", "architecture"]
        case .religious:
            return ["église", "cathédrale", "temple", "mosquée", "synagogue"]
        case .iceRink:
            return ["patinoire", "ice", "patinage", "glace"]
        case .miniGolf:
            return ["mini golf", "golf miniature", "putting"]
        case .escapeRoom:
            return ["escape", "évasion", "énigme", "mystère"]
        case .laserTag:
            return ["laser", "combat", "arène"]
        case .paintball:
            return ["paintball", "airsoft", "combat", "balle"]
        case .karting:
            return ["karting", "kart", "circuit", "course"]
        case .trampolinePark:
            return ["trampoline", "jump", "rebond"]
        case .waterPark:
            return ["aquatique", "water", "toboggan"]
        case .adventurePark:
            return ["aventure", "accrobranche", "tyrolienne"]
        case .zoo:
            return ["zoo", "animalier", "animaux", "faune"]
        case .aquarium:
            return ["aquarium", "poissons", "marine"]
        default:
            return []
        }
    }
    
    private func deduplicatePlaces(_ places: [Location]) -> [Location] {
        var uniquePlaces: [Location] = []
        var seenCoordinates = Set<String>()
        
        for place in places {
            let latKey = String(format: "%.4f", place.latitude)
            let lngKey = String(format: "%.4f", place.longitude)
            let coordinateKey = "\(latKey),\(lngKey)"
            
            if !seenCoordinates.contains(coordinateKey) {
                seenCoordinates.insert(coordinateKey)
                uniquePlaces.append(place)
            }
        }
        
        return uniquePlaces
    }
    
    private func filterByDistance(places: [Location], userLocation: CLLocation, maxDistance: Double) -> [Location] {
        return places.filter { place in
            let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
            let distance = userLocation.distance(from: placeLocation) / 1000.0
            return distance <= maxDistance
        }
    }
}

// Structure pour la base de données locale
struct LocalPlace {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let category: LocationCategory
    let description: String
} 