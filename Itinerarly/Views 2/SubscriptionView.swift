import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var storeKitService = StoreKitService.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Plans d'abonnement
                    plansSection
                    
                    // Fonctionnalités Premium
                    featuresSection
                    
                    // Boutons d'action
                    actionButtonsSection
                    
                    // Informations légales
                    legalSection
                }
                .padding()
            }
            .background(ItinerarlyTheme.Backgrounds.appGradient)
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Fermer") { dismiss() })
            .onAppear {
                Task {
                    await storeKitService.loadProducts()
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Logo Premium
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [ItinerarlyTheme.coral, ItinerarlyTheme.deepViolet],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Passez à Premium")
                    .font(ItinerarlyTheme.Typography.title1)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Débloquez toutes les fonctionnalités avancées d'Itinerarly")
                    .font(ItinerarlyTheme.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(ItinerarlyTheme.Backgrounds.card)
        .cornerRadius(ItinerarlyTheme.CornerRadius.lg)
    }
    
    // MARK: - Plans Section
    private var plansSection: some View {
        VStack(spacing: 16) {
            ForEach(storeKitService.subscriptionPlans) { plan in
                SubscriptionPlanCard(
                    plan: plan,
                    product: storeKitService.getProduct(for: plan),
                    isSelected: false,
                    onSelect: {
                        Task {
                            if let product = storeKitService.getProduct(for: plan) {
                                try await storeKitService.purchase(product)
                            }
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fonctionnalités Premium")
                .font(ItinerarlyTheme.Typography.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                FeatureCard(
                    icon: "headphones",
                    title: "Tours guidés",
                    description: "Accès illimité à tous nos tours audio"
                )
                
                FeatureCard(
                    icon: "lightbulb",
                    title: "Suggestions IA",
                    description: "Recommandations personnalisées"
                )
                
                FeatureCard(
                    icon: "map",
                    title: "Navigation hors ligne",
                    description: "Téléchargez vos itinéraires"
                )
                
                FeatureCard(
                    icon: "star",
                    title: "Contenu exclusif",
                    description: "Tours et lieux premium"
                )
                
                FeatureCard(
                    icon: "xmark.circle",
                    title: "Sans publicités",
                    description: "Expérience sans interruption"
                )
                
                FeatureCard(
                    icon: "message",
                    title: "Support prioritaire",
                    description: "Aide rapide et personnalisée"
                )
            }
        }
        .padding()
        .background(ItinerarlyTheme.Backgrounds.card)
        .cornerRadius(ItinerarlyTheme.CornerRadius.lg)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if storeKitService.isLoading {
                ProgressView("Chargement...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Button("Restaurer les achats") {
                    Task {
                        await storeKitService.restorePurchases()
                    }
                }
                .font(ItinerarlyTheme.Typography.buttonText)
                .foregroundColor(ItinerarlyTheme.ModeColors.profile)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: ItinerarlyTheme.CornerRadius.md)
                        .stroke(ItinerarlyTheme.ModeColors.profile, lineWidth: 1)
                )
            }
            
            if let errorMessage = storeKitService.errorMessage {
                Text(errorMessage)
                    .font(ItinerarlyTheme.Typography.caption1)
                    .foregroundColor(ItinerarlyTheme.danger)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
    
    // MARK: - Legal Section
    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("L'abonnement se renouvelle automatiquement sauf annulation 24h avant la fin de la période. Annulez à tout moment dans les paramètres de votre compte App Store.")
                .font(ItinerarlyTheme.Typography.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Conditions d'utilisation") {
                    // Ouvrir les conditions
                }
                .font(ItinerarlyTheme.Typography.caption2)
                .foregroundColor(ItinerarlyTheme.ModeColors.profile)
                
                Button("Politique de confidentialité") {
                    // Ouvrir la politique
                }
                .font(ItinerarlyTheme.Typography.caption2)
                .foregroundColor(ItinerarlyTheme.ModeColors.profile)
            }
        }
        .padding()
    }
}

// MARK: - Subscription Plan Card
struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let product: Product?
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(plan.title)
                            .font(ItinerarlyTheme.Typography.headline)
                            .fontWeight(.bold)
                        
                        if plan.isPopular {
                            Text("POPULAIRE")
                                .font(ItinerarlyTheme.Typography.caption1)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(ItinerarlyTheme.coral)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(plan.description)
                        .font(ItinerarlyTheme.Typography.caption1)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(plan.features.prefix(3), id: \.self) { feature in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(ItinerarlyTheme.success)
                                    .font(.caption)
                                Text(feature)
                                    .font(ItinerarlyTheme.Typography.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product?.displayPrice ?? plan.price)
                        .font(ItinerarlyTheme.Typography.title3)
                        .fontWeight(.bold)
                    
                    Text(plan.period)
                        .font(ItinerarlyTheme.Typography.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: ItinerarlyTheme.CornerRadius.md)
                    .fill(isSelected ? ItinerarlyTheme.ModeColors.profile.opacity(0.1) : ItinerarlyTheme.Backgrounds.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: ItinerarlyTheme.CornerRadius.md)
                            .stroke(isSelected ? ItinerarlyTheme.ModeColors.profile : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(ItinerarlyTheme.ModeColors.profile)
            
            Text(title)
                .font(ItinerarlyTheme.Typography.subheadline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(ItinerarlyTheme.Typography.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(ItinerarlyTheme.CornerRadius.md)
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(LanguageManager.shared)
} 