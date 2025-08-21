# 🛒 Configuration App Store Connect pour les Achats Intégrés

## 📋 Étapes à suivre dans App Store Connect

### **1. Créer les Produits d'Achat Intégré**

1. **Connectez-vous à App Store Connect** : https://appstoreconnect.apple.com
2. **Sélectionnez votre app** Itinerarly
3. **Allez dans "Fonctionnalités" > "Achats intégrés"**
4. **Cliquez sur "+" pour créer un nouvel achat intégré**

### **2. Configuration des 3 Produits Premium**

#### **Produit 1 : Premium Mensuel**
- **Référence** : `com.itinerarly.premium.monthly`
- **Type** : Abonnement automatique renouvelable
- **Nom d'affichage** : "Premium Mensuel"
- **Description** : "Accès complet à toutes les fonctionnalités premium"
- **Prix** : 9,99 € (ou prix local équivalent)
- **Durée** : 1 mois

#### **Produit 2 : Premium Annuel**
- **Référence** : `com.itinerarly.premium.yearly`
- **Type** : Abonnement automatique renouvelable
- **Nom d'affichage** : "Premium Annuel"
- **Description** : "Économisez 40% avec l'abonnement annuel"
- **Prix** : 59,99 € (ou prix local équivalent)
- **Durée** : 1 an

#### **Produit 3 : Premium à Vie**
- **Référence** : `com.itinerarly.premium.lifetime`
- **Type** : Achat non consommable
- **Nom d'affichage** : "Premium à Vie"
- **Description** : "Accès permanent à toutes les fonctionnalités"
- **Prix** : 199,99 € (ou prix local équivalent)

### **3. Configuration du Groupe d'Abonnement**

1. **Créez un groupe d'abonnement** : "Premium"
2. **Ajoutez les abonnements mensuel et annuel** au groupe
3. **Configurez les niveaux d'abonnement** :
   - Niveau 1 : Premium (mensuel et annuel)
   - Niveau 2 : Premium à Vie (non consommable)

### **4. Configuration des Métadonnées**

#### **Pour chaque produit :**
- **Nom localisé** (français) : "Premium [Période]"
- **Description localisée** : Description détaillée des fonctionnalités
- **Image de produit** : 1024x1024px (optionnel)

### **5. Configuration des Prix**

1. **Sélectionnez les territoires** où l'app sera disponible
2. **Définissez les prix** pour chaque territoire
3. **Activez la disponibilité** pour chaque produit

### **6. Soumission pour Révision**

1. **Vérifiez que tous les produits sont configurés**
2. **Soumettez pour révision** (peut prendre 24-48h)
3. **Attendez l'approbation** d'Apple

## 🔧 Configuration Technique

### **Fichier de Configuration StoreKit (pour les tests)**

Créez un fichier `Configuration.storekit` dans votre projet Xcode :

```json
{
  "identifier" : "Configuration",
  "nonRenewingSubscriptions" : [

  ],
  "products" : [
    {
      "displayPrice" : "199.99",
      "familyShareable" : false,
      "internalID" : "lifetime_premium",
      "localizations" : [
        {
          "description" : "Accès permanent à toutes les fonctionnalités premium",
          "displayName" : "Premium à Vie",
          "locale" : "fr_FR"
        }
      ],
      "productID" : "com.itinerarly.premium.lifetime",
      "referenceName" : "Premium Lifetime",
      "type" : "NonConsumable"
    }
  ],
  "settings" : {
    "_applicationInternalID" : "lifetime_premium",
    "_developerTeamID" : "VOTRE_TEAM_ID",
    "_failTransactionsEnabled" : false,
    "_lastSynchronizedDate" : 1234567890,
    "_locale" : "fr_FR",
    "_storefront" : "FRA",
    "_storeKitErrors" : [
      {
        "current" : null,
        "enabled" : false,
        "name" : "Load Products"
      }
    ]
  },
  "subscriptionGroups" : [
    {
      "id" : "premium_group",
      "localizations" : [
        {
          "description" : "Abonnements premium Itinerarly",
          "displayName" : "Premium",
          "locale" : "fr_FR"
        }
      ],
      "name" : "Premium",
      "subscriptions" : [
        {
          "adHocOffers" : [

          ],
          "codeOffers" : [

          ],
          "displayPrice" : "9.99",
          "familyShareable" : false,
          "groupNumber" : 1,
          "internalID" : "monthly_premium",
          "introductoryOffer" : null,
          "localizations" : [
            {
              "description" : "Accès complet à toutes les fonctionnalités premium",
              "displayName" : "Premium Mensuel",
              "locale" : "fr_FR"
            }
          ],
          "productID" : "com.itinerarly.premium.monthly",
          "recurringSubscriptionPeriod" : "P1M",
          "referenceName" : "Premium Monthly",
          "subscriptionGroupID" : "premium_group",
          "type" : "RecurringSubscription"
        },
        {
          "adHocOffers" : [

          ],
          "codeOffers" : [

          ],
          "displayPrice" : "59.99",
          "familyShareable" : false,
          "groupNumber" : 1,
          "internalID" : "yearly_premium",
          "introductoryOffer" : null,
          "localizations" : [
            {
              "description" : "Économisez 40% avec l'abonnement annuel",
              "displayName" : "Premium Annuel",
              "locale" : "fr_FR"
            }
          ],
          "productID" : "com.itinerarly.premium.yearly",
          "recurringSubscriptionPeriod" : "P1Y",
          "referenceName" : "Premium Yearly",
          "subscriptionGroupID" : "premium_group",
          "type" : "RecurringSubscription"
        }
      ]
    }
  ],
  "version" : {
    "major" : 3,
    "minor" : 0
  }
}
```

## 🧪 Test des Achats

### **En Mode Développement :**
1. **Utilisez des comptes de test** Sandbox
2. **Testez avec le fichier Configuration.storekit**
3. **Vérifiez les transactions** dans App Store Connect

### **En Mode Production :**
1. **Soumettez l'app** avec les achats intégrés
2. **Attendez l'approbation** d'Apple
3. **Testez avec de vrais comptes** (après approbation)

## 📱 Intégration dans l'App

L'app est déjà configurée avec :
- ✅ `StoreKitService` pour gérer les achats
- ✅ `SubscriptionView` pour l'interface utilisateur
- ✅ Gestion des abonnements et restaurations
- ✅ Vérification du statut premium

## 🎯 Prochaines Étapes

1. **Configurez App Store Connect** selon ce guide
2. **Testez en mode développement**
3. **Soumettez pour révision**
4. **Activez en production**

---
*Dernière mise à jour : $(date)*
