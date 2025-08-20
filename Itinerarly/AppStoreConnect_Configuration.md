# Configuration App Store Connect - Itinerarly

## 📱 Configuration des Produits d'Abonnement

### 1. Identifiants de Produits à Configurer

Dans App Store Connect, créez les produits suivants :

#### Abonnements Premium
- **ID Produit**: `com.itinerarly.premium.monthly`
- **Type**: Abonnement Auto-Renouvelable
- **Prix**: 9,99 €
- **Période**: 1 mois

- **ID Produit**: `com.itinerarly.premium.yearly`
- **Type**: Abonnement Auto-Renouvelable
- **Prix**: 59,99 €
- **Période**: 1 an

#### Achat Unique
- **ID Produit**: `com.itinerarly.premium.lifetime`
- **Type**: Achat Non-Consommable
- **Prix**: 199,99 €

### 2. Groupe d'Abonnement

Créez un groupe d'abonnement nommé "Premium" et ajoutez-y :
- `com.itinerarly.premium.monthly`
- `com.itinerarly.premium.yearly`

### 3. Configuration des Prix

#### France (EUR)
- Mensuel: 9,99 €
- Annuel: 59,99 €
- Lifetime: 199,99 €

#### États-Unis (USD)
- Mensuel: $9.99
- Annuel: $59.99
- Lifetime: $199.99

### 4. Métadonnées Requises

#### Description des Produits
**Premium Mensuel:**
- Recherche illimitée de lieux
- Itinéraires personnalisés
- Sauvegarde des favoris
- Support prioritaire
- Pas de publicités
- Export d'itinéraires
- Tous les types d'activités (bowling, piscine, etc.)

**Premium Annuel:**
- Tout du plan mensuel
- Économies de 40%
- Accès anticipé aux nouvelles fonctionnalités
- Contenu exclusif
- Itinéraires premium
- Statistiques détaillées
- Réservations intégrées

**Premium à Vie:**
- Tout des autres plans
- Accès permanent
- Mises à jour gratuites à vie
- Support VIP
- Fonctionnalités exclusives
- Pas de renouvellement
- Accès prioritaire aux nouvelles fonctionnalités

### 5. Configuration StoreKit

#### Test en Développement
1. Dans Xcode, allez dans "Product" > "Scheme" > "Edit Scheme"
2. Sélectionnez "Run" > "Options"
3. Dans "StoreKit Configuration", sélectionnez "Create StoreKit Configuration File"
4. Ajoutez les produits avec les IDs exacts

#### Fichier StoreKit Configuration
```json
{
  "identifier": "Itinerarly_Configuration",
  "nonRenewingSubscriptions": [
    {
      "displayPrice": "199.99",
      "familyShareable": false,
      "identifier": "com.itinerarly.premium.lifetime",
      "localizations": [
        {
          "description": "Accès permanent à toutes les fonctionnalités",
          "displayName": "Premium à Vie",
          "locale": "fr_FR"
        }
      ],
      "type": "NonRenewingSubscription"
    }
  ],
  "products": [],
  "settings": {
    "_applicationInternalID": "1234567890",
    "_developerTeamID": "VOTRE_TEAM_ID",
    "_failTransactionsEnabled": false,
    "_lastSynchronizedDate": 1234567890,
    "_locale": "fr_FR",
    "_storefront": "FRA",
    "_storeKitErrors": [
      {
        "current": null,
        "enabled": false,
        "name": "Load Products"
      }
    ]
  },
  "subscriptionGroups": [
    {
      "id": "premium_group",
      "localizations": [
        {
          "description": "Abonnements Premium Itinerarly",
          "displayName": "Premium",
          "locale": "fr_FR"
        }
      ],
      "name": "Premium",
      "subscriptions": [
        {
          "adHocOffers": [],
          "codeOffers": [],
          "displayPrice": "9.99",
          "familyShareable": false,
          "groupNumber": 1,
          "identifier": "com.itinerarly.premium.monthly",
          "introductoryOffer": null,
          "localizations": [
            {
              "description": "Accès complet à toutes les fonctionnalités",
              "displayName": "Premium Mensuel",
              "locale": "fr_FR"
            }
          ],
          "productID": "com.itinerarly.premium.monthly",
          "recurringSubscriptionPeriod": "P1M",
          "referenceName": "Premium Mensuel",
          "subscriptionGroupID": "premium_group",
          "type": "RecurringSubscription"
        },
        {
          "adHocOffers": [],
          "codeOffers": [],
          "displayPrice": "59.99",
          "familyShareable": false,
          "groupNumber": 2,
          "identifier": "com.itinerarly.premium.yearly",
          "introductoryOffer": null,
          "localizations": [
            {
              "description": "Économisez 40% avec l'abonnement annuel",
              "displayName": "Premium Annuel",
              "locale": "fr_FR"
            }
          ],
          "productID": "com.itinerarly.premium.yearly",
          "recurringSubscriptionPeriod": "P1Y",
          "referenceName": "Premium Annuel",
          "subscriptionGroupID": "premium_group",
          "type": "RecurringSubscription"
        }
      ]
    }
  ],
  "version": {
    "major": 3,
    "minor": 0
  }
}
```

### 6. Test des Achats

#### En Mode Développement
1. Utilisez le StoreKit Testing Framework
2. Créez des comptes de test dans App Store Connect
3. Testez les achats avec ces comptes

#### En Mode Production
1. Soumettez l'app pour review
2. Apple testera les achats
3. Une fois approuvé, les achats fonctionneront en production

### 7. Gestion des Abonnements

#### Vérification du Statut
- Utilisez `StoreKitService.shared.subscriptionStatus`
- Vérifiez `isSubscribed` pour l'accès premium

#### Restauration des Achats
- Implémenté dans `StoreKitService.restorePurchases()`
- Permet aux utilisateurs de restaurer leurs achats

### 8. Support Client

#### Gestion des Remboursements
- Les utilisateurs peuvent demander un remboursement via App Store
- Apple gère automatiquement les remboursements

#### Annulation d'Abonnement
- Les utilisateurs peuvent annuler via Réglages > App Store
- L'abonnement reste actif jusqu'à la fin de la période

### 9. Analytics et Rapports

#### Métriques à Surveiller
- Taux de conversion
- Churn rate
- Revenus par utilisateur
- Popularité des plans

#### Rapports App Store Connect
- Ventes et tendances
- Abonnements
- Utilisation de l'app

---

**Note**: Remplacez `VOTRE_TEAM_ID` par votre véritable Team ID Apple Developer.
