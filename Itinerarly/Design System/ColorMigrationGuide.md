# Migration vers Itinerarly Design System

## 🎨 Remplacement des couleurs dans toute l'app

### Ancien → Nouveau

#### Couleurs principales
- `.blue` → `ItinerarlyTheme.oceanBlue` ou `ItinerarlyTheme.ModeColors.planner`
- `.orange` → `ItinerarlyTheme.coral` ou `ItinerarlyTheme.ModeColors.suggestions`
- `.purple` → `ItinerarlyTheme.deepViolet` ou `ItinerarlyTheme.ModeColors.adventure`
- `.green` → `ItinerarlyTheme.turquoise` ou `ItinerarlyTheme.ModeColors.guidedTours`

#### Couleurs sémantiques
- Succès: `ItinerarlyTheme.success`
- Warning: `ItinerarlyTheme.warning`
- Erreur: `ItinerarlyTheme.danger`
- Primaire: `ItinerarlyTheme.primary`

### Fichiers à migrer prioritairement

1. **AuthenticationView.swift** - Utilise `.blue` hardcodé
2. **SplashView.swift** - Utilise des couleurs hardcodées
3. **ProfileView.swift** - Mélange de couleurs
4. **GuidedToursView.swift** - Beaucoup de `.purple`, `.orange`, `.blue`
5. **AdventurerView.swift** - Couleurs `purple` hardcodées
6. **SuggestionResultsView.swift** - Mix de couleurs
7. **Tous les composants** dans Views 2/Components/

### Remplacement par mode

#### Planifier (Bleu océan)
```swift
// Ancien
.foregroundColor(.blue)
.background(Color.blue)

// Nouveau
.foregroundColor(ItinerarlyTheme.ModeColors.planner)
.background(ItinerarlyTheme.ModeColors.planner)
```

#### Tours guidés (Turquoise)
```swift
// Ancien
.foregroundColor(.green)

// Nouveau
.foregroundColor(ItinerarlyTheme.ModeColors.guidedTours)
```

#### Suggestions (Corail)
```swift
// Ancien
.foregroundColor(.orange)

// Nouveau
.foregroundColor(ItinerarlyTheme.ModeColors.suggestions)
```

#### Aventure (Violet profond)
```swift
// Ancien
.foregroundColor(.purple)

// Nouveau
.foregroundColor(ItinerarlyTheme.ModeColors.adventure)
```

### Utilitaires du Design System

#### Styles de boutons
```swift
// Ancien
.background(Color.blue)
.foregroundColor(.white)
.cornerRadius(12)

// Nouveau
.itinerarlyButtonStyle(.primary(.planner))
```

#### Cartes
```swift
// Ancien
.background(Color(.systemBackground))
.cornerRadius(12)
.shadow(...)

// Nouveau
.itinerarlyCard(mode: .planner)
```

#### Backgrounds
```swift
// Ancien
LinearGradient(colors: [.blue, .purple], ...)

// Nouveau
.itinerarlyBackground(mode: .planner)
```

### Progression
- [ ] Design System créé ✅
- [ ] HomeView migré ✅ 
- [ ] MainTabView migré ✅
- [ ] SuggestionView (en cours) 🔄
- [ ] AuthenticationView
- [ ] SplashView  
- [ ] ProfileView
- [ ] GuidedToursView
- [ ] AdventurerView
- [ ] Tous les résultats des vues
- [ ] Composants réutilisables