import Foundation
import StoreKit
import Combine

// MARK: - Modèles d'abonnement
struct SubscriptionPlan: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let price: String
    let period: String
    let features: [String]
    let productId: String
    let isPopular: Bool
    
    var displayPrice: String {
        return price
    }
}

struct SubscriptionStatus {
    let isSubscribed: Bool
    let currentPlan: String?
    let expirationDate: Date?
    let autoRenewStatus: Bool
}

// MARK: - Service StoreKit
@MainActor
class StoreKitService: ObservableObject {
    static let shared = StoreKitService()
    
    // MARK: - Propriétés
    @Published var products: [Product] = []
    @Published var purchasedProducts: Set<String> = []
    @Published var subscriptionStatus: SubscriptionStatus?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var updateListenerTask: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Product IDs
    private let productIds = [
        "com.itinerarly.premium.monthly",
        "com.itinerarly.premium.yearly",
        "com.itinerarly.premium.lifetime"
    ]
    
    // MARK: - Plans d'abonnement
    let subscriptionPlans: [SubscriptionPlan] = [
        SubscriptionPlan(
            id: "monthly",
            title: "Premium Mensuel",
            description: "Accès complet à toutes les fonctionnalités",
            price: "9,99 €",
            period: "par mois",
            features: [
                "Recherche illimitée de lieux",
                "Itinéraires personnalisés",
                "Sauvegarde des favoris",
                "Support prioritaire",
                "Pas de publicités",
                "Export d'itinéraires",
                "Tous les types d'activités (bowling, piscine, etc.)"
            ],
            productId: "com.itinerarly.premium.monthly",
            isPopular: false
        ),
        SubscriptionPlan(
            id: "yearly",
            title: "Premium Annuel",
            description: "Économisez 40% avec l'abonnement annuel",
            price: "59,99 €",
            period: "par an",
            features: [
                "Tout du plan mensuel",
                "Économies de 40%",
                "Accès anticipé aux nouvelles fonctionnalités",
                "Contenu exclusif",
                "Itinéraires premium",
                "Statistiques détaillées",
                "Réservations intégrées"
            ],
            productId: "com.itinerarly.premium.yearly",
            isPopular: true
        ),
        SubscriptionPlan(
            id: "lifetime",
            title: "Premium à Vie",
            description: "Accès permanent à toutes les fonctionnalités",
            price: "199,99 €",
            period: "à vie",
            features: [
                "Tout des autres plans",
                "Accès permanent",
                "Mises à jour gratuites à vie",
                "Support VIP",
                "Fonctionnalités exclusives",
                "Pas de renouvellement",
                "Accès prioritaire aux nouvelles fonctionnalités"
            ],
            productId: "com.itinerarly.premium.lifetime",
            isPopular: false
        )
    ]
    
    // MARK: - Initialisation
    init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Chargement des produits
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            products = try await Product.products(for: productIds)
            print("✅ Produits chargés: \(products.count)")
        } catch {
            errorMessage = "Erreur lors du chargement des produits: \(error.localizedDescription)"
            print("❌ Erreur chargement produits: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Achat d'abonnement
    func purchase(_ product: Product) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Vérifier la transaction
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updateSubscriptionStatus()
                    print("✅ Achat réussi: \(transaction.productID)")
                case .unverified(_, let error):
                    throw error
                }
            case .userCancelled:
                print("❌ Achat annulé par l'utilisateur")
            case .pending:
                print("⏳ Achat en attente")
            @unknown default:
                print("❓ Statut d'achat inconnu")
            }
        } catch {
            errorMessage = "Erreur lors de l'achat: \(error.localizedDescription)"
            print("❌ Erreur achat: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Restauration des achats
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            print("✅ Achats restaurés")
        } catch {
            errorMessage = "Erreur lors de la restauration: \(error.localizedDescription)"
            print("❌ Erreur restauration: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Gestion des abonnements
    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                purchasedProducts.insert(transaction.productID)
                
                // Déterminer le statut d'abonnement
                let isSubscribed = !purchasedProducts.isEmpty
                let currentPlan = getCurrentPlan(from: transaction.productID)
                let expirationDate = transaction.expirationDate
                let autoRenewStatus = transaction.isUpgraded
                
                subscriptionStatus = SubscriptionStatus(
                    isSubscribed: isSubscribed,
                    currentPlan: currentPlan,
                    expirationDate: expirationDate,
                    autoRenewStatus: autoRenewStatus
                )
                
                print("✅ Statut abonnement mis à jour: \(currentPlan ?? "Aucun")")
                
            case .unverified(_, let error):
                print("❌ Transaction non vérifiée: \(error)")
            }
        }
    }
    
    // MARK: - Gestion des transactions
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                await self.handleTransactionResult(result)
            }
        }
    }
    
    private func handleTransactionResult(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            await transaction.finish()
            await self.updateSubscriptionStatus()
        case .unverified(_, let error):
            print("❌ Transaction non vérifiée: \(error)")
        }
    }
    
    // MARK: - Utilitaires
    private func getCurrentPlan(from productId: String) -> String? {
        switch productId {
        case "com.itinerarly.premium.monthly":
            return "Premium Mensuel"
        case "com.itinerarly.premium.yearly":
            return "Premium Annuel"
        case "com.itinerarly.premium.lifetime":
            return "Premium à Vie"
        default:
            return nil
        }
    }
    
    // MARK: - Vérification du statut Premium
    func isPremiumUser() -> Bool {
        return hasActiveSubscription()
    }
    
    func getCurrentSubscriptionPlan() -> String? {
        return subscriptionStatus?.currentPlan
    }
    
    func getSubscriptionExpirationDate() -> Date? {
        return subscriptionStatus?.expirationDate
    }
    
    func getProduct(for plan: SubscriptionPlan) -> Product? {
        return products.first { $0.id == plan.productId }
    }
    
    func isSubscribed(to productId: String) -> Bool {
        return purchasedProducts.contains(productId)
    }
    
    func hasActiveSubscription() -> Bool {
        return subscriptionStatus?.isSubscribed == true
    }
}

// MARK: - Extensions utiles
extension Product {
    var displayPrice: String {
        return self.price.description
    }
    
    var isSubscription: Bool {
        return type == .autoRenewable || type == .nonRenewable
    }
}
