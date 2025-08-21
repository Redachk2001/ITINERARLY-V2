import Foundation
import SwiftUI

// MARK: - Service de gestion Premium
@MainActor
class PremiumService: ObservableObject {
    static let shared = PremiumService()
    
    @Published var isPremium: Bool = false
    @Published var currentPlan: String?
    @Published var expirationDate: Date?
    
    private let storeKitService = StoreKitService.shared
    
    init() {
        updatePremiumStatus()
    }
    
    // MARK: - Mise à jour du statut Premium
    func updatePremiumStatus() {
        isPremium = storeKitService.isPremiumUser()
        currentPlan = storeKitService.getCurrentSubscriptionPlan()
        expirationDate = storeKitService.getSubscriptionExpirationDate()
    }
    
    // MARK: - Vérification des fonctionnalités Premium
    
    /// Vérifie si l'utilisateur peut accéder aux fonctionnalités premium
    func canAccessPremiumFeatures() -> Bool {
        return isPremium
    }
    
    /// Vérifie si l'utilisateur peut créer plus de 3 itinéraires
    func canCreateUnlimitedItineraries() -> Bool {
        return isPremium
    }
    
    /// Vérifie si l'utilisateur peut sauvegarder des favoris illimités
    func canSaveUnlimitedFavorites() -> Bool {
        return isPremium
    }
    
    /// Vérifie si l'utilisateur peut exporter des itinéraires
    func canExportItineraries() -> Bool {
        return isPremium
    }
    
    /// Vérifie si l'utilisateur peut accéder aux statistiques détaillées
    func canAccessDetailedStats() -> Bool {
        return isPremium
    }
    
    /// Vérifie si l'utilisateur peut accéder aux réservations intégrées
    func canAccessIntegratedBookings() -> Bool {
        return isPremium
    }
    
    /// Vérifie si l'utilisateur peut accéder au support prioritaire
    func canAccessPrioritySupport() -> Bool {
        return isPremium
    }
    
    // MARK: - Limites pour les utilisateurs gratuits
    
    /// Nombre maximum d'itinéraires pour les utilisateurs gratuits
    let maxFreeItineraries = 3
    
    /// Nombre maximum de favoris pour les utilisateurs gratuits
    let maxFreeFavorites = 10
    
    /// Nombre maximum de recherches par jour pour les utilisateurs gratuits
    let maxFreeSearchesPerDay = 20
    
    // MARK: - Messages d'information
    
    func getPremiumUpgradeMessage() -> String {
        return "Passez à Premium pour débloquer toutes les fonctionnalités !"
    }
    
    func getFeatureLockedMessage(for feature: String) -> String {
        return "\(feature) est disponible uniquement pour les utilisateurs Premium"
    }
    
    func getLimitReachedMessage(for limit: String) -> String {
        return "Limite atteinte pour les utilisateurs gratuits. Passez à Premium pour plus de \(limit)"
    }
}

// MARK: - Modificateur de vue pour les fonctionnalités Premium
struct PremiumFeatureModifier: ViewModifier {
    let feature: String
    let isPremium: Bool
    let action: () -> Void
    
    func body(content: Content) -> some View {
        if isPremium {
            content
        } else {
            content
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("Premium")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .onTapGesture {
                            action()
                        }
                    }
                    .padding(.bottom, 8)
                    .padding(.trailing, 8),
                    alignment: .bottomTrailing
                )
        }
    }
}

// MARK: - Extension pour faciliter l'utilisation
extension View {
    func premiumFeature(_ feature: String, isPremium: Bool, action: @escaping () -> Void) -> some View {
        self.modifier(PremiumFeatureModifier(feature: feature, isPremium: isPremium, action: action))
    }
    
    func premiumOnly(_ isPremium: Bool, action: @escaping () -> Void) -> some View {
        self.modifier(PremiumFeatureModifier(feature: "", isPremium: isPremium, action: action))
    }
}

// MARK: - Composant d'alerte Premium
struct PremiumAlert: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var premiumService = PremiumService.shared
    
    let title: String
    let message: String
    let feature: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Icône Premium
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            
            // Titre
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Fonctionnalité
            if !feature.isEmpty {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(feature)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(8)
            }
            
            // Boutons
            VStack(spacing: 12) {
                Button("Passer à Premium") {
                    // Ouvrir la vue d'abonnement
                    dismiss()
                    // Ici vous pouvez ajouter la logique pour ouvrir SubscriptionView
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("Plus tard") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding()
    }
}
