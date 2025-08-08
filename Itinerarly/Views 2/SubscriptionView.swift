import SwiftUI

struct SubscriptionView: View {
    @State private var isPremium = false
    @State private var showingPurchaseSheet = false
    @State private var selectedPlan: SubscriptionPlan = .monthly
    
    enum SubscriptionPlan: String, CaseIterable {
        case monthly = "monthly"
        case yearly = "yearly"
        
        var displayName: String {
            switch self {
            case .monthly: return "Mensuel"
            case .yearly: return "Annuel"
            }
        }
        
        var price: String {
            switch self {
            case .monthly: return "4,99 €"
            case .yearly: return "39,99 €"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "Économisez 33%"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: isPremium ? "crown.fill" : "crown")
                            .font(.system(size: 60))
                            .foregroundColor(isPremium ? .yellow : .gray)
                        
                        Text(isPremium ? "Premium Actif" : "Passez à Premium")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(isPremium ? "Profitez de toutes les fonctionnalités avancées" : "Débloquez tout le potentiel d'Itinerarly")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    if !isPremium {
                        // Plans d'abonnement
                        VStack(spacing: 16) {
                            Text("Choisissez votre plan")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                                PlanCard(
                                    plan: plan,
                                    isSelected: selectedPlan == plan,
                                    action: { selectedPlan = plan }
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Bouton d'achat
                        Button(action: {
                            showingPurchaseSheet = true
                        }) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                Text("S'abonner à Premium")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Comparaison des fonctionnalités
                    FeatureComparisonView(isPremium: isPremium)
                    
                    if isPremium {
                        // Gestion de l'abonnement
                        VStack(spacing: 16) {
                            Text("Gestion de l'abonnement")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 12) {
                                Button(action: {
                                    // Gérer l'abonnement
                                }) {
                                    HStack {
                                        Image(systemName: "gear")
                                        Text("Gérer l'abonnement")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .foregroundColor(.primary)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    // Annuler l'abonnement
                                }) {
                                    HStack {
                                        Image(systemName: "xmark.circle")
                                        Text("Annuler l'abonnement")
                                        Spacer()
                                    }
                                    .foregroundColor(.red)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Abonnement")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPurchaseSheet) {
                PurchaseSheet(plan: selectedPlan)
            }
        }
    }
}

struct PlanCard: View {
    let plan: SubscriptionView.SubscriptionPlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(plan.price)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FeatureComparisonView: View {
    let isPremium: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Comparaison des fonctionnalités")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                FeatureRow(
                    feature: "Mode Aventure",
                    freeValue: "1 catégorie exclue",
                    premiumValue: "Toutes catégories",
                    isPremium: isPremium
                )
                
                FeatureRow(
                    feature: "Tours Guidés",
                    freeValue: "Tours limités",
                    premiumValue: "100% des tours",
                    isPremium: isPremium
                )
                
                FeatureRow(
                    feature: "Mode Suggestions",
                    freeValue: "1 essai/jour",
                    premiumValue: "Illimité",
                    isPremium: isPremium
                )
                
                FeatureRow(
                    feature: "Publicités",
                    freeValue: "Avec publicités",
                    premiumValue: "Sans publicités",
                    isPremium: isPremium
                )
                
                FeatureRow(
                    feature: "Sponsoring Business",
                    freeValue: "Non disponible",
                    premiumValue: "Accès prioritaire",
                    isPremium: isPremium
                )
            }
        }
        .padding(.horizontal)
    }
}

struct FeatureRow: View {
    let feature: String
    let freeValue: String
    let premiumValue: String
    let isPremium: Bool
    
    var body: some View {
        HStack {
            Text(feature)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            Text(freeValue)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .center)
            
            Text(premiumValue)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isPremium ? .blue : .secondary)
                .frame(width: 80, alignment: .center)
        }
        .padding(.vertical, 4)
    }
}

struct PurchaseSheet: View {
    let plan: SubscriptionView.SubscriptionPlan
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Confirmation
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Confirmer l'abonnement")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Plan \(plan.displayName) - \(plan.price)")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                // Détails
                VStack(alignment: .leading, spacing: 12) {
                    Text("Votre abonnement inclut :")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureItem(text: "Mode Aventure illimité")
                        FeatureItem(text: "Tous les tours guidés")
                        FeatureItem(text: "Suggestions illimitées")
                        FeatureItem(text: "Sans publicités")
                        FeatureItem(text: "Support prioritaire")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
                
                // Boutons
                VStack(spacing: 12) {
                    Button(action: {
                        // Procéder à l'achat
                        dismiss()
                    }) {
                        Text("Confirmer l'achat")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Annuler")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .navigationTitle("Achat")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Fermer") { dismiss() })
        }
    }
}

struct FeatureItem: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark")
                .foregroundColor(.green)
                .font(.caption)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    SubscriptionView()
} 