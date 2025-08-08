# Itinerarly 📱🗺️

Une application iOS moderne pour planifier des itinéraires et découvrir des activités près de chez vous.

## 🚀 Fonctionnalités

### Modes principaux
- **Planifier** : Créer des itinéraires optimisés pour votre journée
- **Tours guidés** : Découvrir des parcours audio guidés
- **Suggestions** : Trouver des activités sympas près de chez vous
- **Aventure** : Découvrir des lieux surprenants

### Fonctionnalités avancées
- 🎧 **Guides audio** : Tours guidés avec anecdotes détaillées
- 🌍 **Multi-langues** : Support pour français, anglais, allemand, espagnol, chinois, arabe
- 🌙 **Mode sombre** : Interface adaptée à vos préférences
- 📍 **Géolocalisation** : Détection automatique de votre position
- 🚌 **Transports** : Intégration des transports en commun
- ⏱️ **Estimation temps** : Durées adaptées aux recommandations

## 🛠️ Technologies

- **SwiftUI** : Interface utilisateur moderne
- **Core Location** : Services de géolocalisation
- **AVFoundation** : Synthèse vocale pour les guides audio
- **URLSession** : API de traduction et services externes
- **UserDefaults** : Persistance des préférences utilisateur

## 📱 Captures d'écran

[Captures à ajouter]

## 🚀 Installation

### Prérequis
- Xcode 15.0+
- iOS 16.0+
- macOS 13.0+

### Étapes d'installation
1. Clonez le repository :
```bash
git clone https://github.com/votre-username/Itinerarly.git
cd Itinerarly
```

2. Ouvrez le projet dans Xcode :
```bash
open Itinerarly.xcodeproj
```

3. Sélectionnez votre équipe de développement dans les paramètres du projet

4. Compilez et lancez l'application sur votre simulateur ou appareil

## 🏗️ Architecture

### Structure du projet
```
Itinerarly/
├── Views 2/                 # Interface utilisateur
│   ├── Components/          # Composants réutilisables
│   ├── Features/           # Vues principales
│   └── SplashView.swift    # Écran de démarrage
├── Services 2/             # Services métier
│   ├── AudioService.swift  # Synthèse vocale
│   ├── LanguageManager.swift # Gestion des langues
│   └── TranslationService.swift # API de traduction
├── Design System/          # Système de design
│   ├── ItinerarlyTheme.swift
│   └── ItinerarlyComponents.swift
└── ContentView.swift       # Point d'entrée
```

### Services principaux
- **AudioService** : Gestion de la synthèse vocale
- **LocationManager** : Services de géolocalisation
- **LanguageManager** : Gestion multi-langues
- **TranslationService** : API de traduction instantanée
- **ThemeManager** : Gestion du mode sombre/clair

## 🎨 Design System

### Couleurs
- **Mode Planifier** : Bleu (#007AFF)
- **Mode Tours guidés** : Orange (#FF9500)
- **Mode Suggestions** : Vert (#34C759)
- **Mode Aventure** : Rouge (#FF3B30)

### Typographie
- **Titres principaux** : 32pt, Bold
- **Sous-titres** : 18pt, Medium
- **Corps de texte** : 16pt, Regular

## 🌍 Internationalisation

L'application supporte 6 langues :
- 🇫🇷 Français (par défaut)
- 🇺🇸 Anglais
- 🇩🇪 Allemand
- 🇪🇸 Espagnol
- 🇨🇳 Chinois
- 🇸🇦 Arabe

### Ajout d'une nouvelle langue
1. Ajoutez la langue dans `AppLanguage` enum
2. Mettez à jour `TranslationService`
3. Testez la traduction dans l'interface

## 🤝 Contribution

### Workflow Git
1. Créez une branche pour votre fonctionnalité :
```bash
git checkout -b feature/nouvelle-fonctionnalite
```

2. Développez et testez votre code

3. Committez vos changements :
```bash
git add .
git commit -m "feat: ajout de la nouvelle fonctionnalité"
```

4. Poussez vers GitHub :
```bash
git push origin feature/nouvelle-fonctionnalite
```

5. Créez une Pull Request sur GitHub

### Conventions de code
- **SwiftUI** : Utilisez les bonnes pratiques SwiftUI
- **Nommage** : Variables et fonctions en camelCase
- **Commentaires** : Code auto-documenté, commentaires pour la logique complexe
- **Tests** : Ajoutez des tests pour les nouvelles fonctionnalités

## 📋 Roadmap

### Version 1.1
- [ ] Amélioration des guides audio
- [ ] Plus de langues supportées
- [ ] Optimisation des performances

### Version 1.2
- [ ] Mode hors-ligne
- [ ] Synchronisation cloud
- [ ] Partage d'itinéraires

### Version 2.0
- [ ] Mode réalité augmentée
- [ ] Intégration IA pour recommandations
- [ ] API publique pour développeurs

## 🐛 Signaler un bug

1. Vérifiez que le bug n'a pas déjà été signalé
2. Créez une issue avec :
   - Description détaillée du problème
   - Étapes pour reproduire
   - Version d'iOS et d'Itinerarly
   - Captures d'écran si applicable

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 👥 Équipe

- **Développeur principal** : [Votre nom]
- **Design** : [Nom du designer]
- **Tests** : [Nom du testeur]

## 📞 Contact

- **Email** : contact@itinerarly.app
- **Site web** : https://itinerarly.app
- **Twitter** : @ItinerarlyApp

---

**Itinerarly** - Découvrez le monde qui vous entoure 🌍✨ 