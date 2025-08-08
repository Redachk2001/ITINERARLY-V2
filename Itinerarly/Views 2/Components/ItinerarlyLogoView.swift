import SwiftUI

struct ItinerarlyLogoView: View {
    let size: CGFloat
    let showText: Bool
    
    init(size: CGFloat = 120, showText: Bool = true) {
        self.size = size
        self.showText = showText
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Logo principal
            ZStack {
                // Cercle de fond avec dégradé
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.31, green: 0.27, blue: 0.90), Color(red: 0.49, green: 0.23, blue: 0.93)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                
                // Boussole centrale
                ZStack {
                    // Cercle blanc de la boussole
                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: size * 0.6, height: size * 0.6)
                    
                    // Bordure de la boussole
                    Circle()
                        .stroke(Color(red: 0.31, green: 0.27, blue: 0.90), lineWidth: 2)
                        .frame(width: size * 0.55, height: size * 0.55)
                    
                    // Aiguille de la boussole
                    ZStack {
                        // Aiguille rouge
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: -size * 0.2))
                            path.addLine(to: CGPoint(x: -size * 0.04, y: 0))
                            path.addLine(to: CGPoint(x: 0, y: size * 0.2))
                            path.addLine(to: CGPoint(x: size * 0.04, y: 0))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.94, green: 0.27, blue: 0.27), Color(red: 0.98, green: 0.45, blue: 0.09)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        // Centre de la boussole
                        Circle()
                            .fill(Color(red: 0.31, green: 0.27, blue: 0.90))
                            .frame(width: size * 0.08, height: size * 0.08)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: size * 0.04, height: size * 0.04)
                    }
                    
                    // Directions de la boussole
                    VStack(spacing: size * 0.5) {
                        Text("N")
                            .font(.system(size: size * 0.06, weight: .bold))
                            .foregroundColor(Color(red: 0.31, green: 0.27, blue: 0.90))
                        
                        Text("S")
                            .font(.system(size: size * 0.06, weight: .bold))
                            .foregroundColor(Color(red: 0.31, green: 0.27, blue: 0.90))
                    }
                    
                    HStack(spacing: size * 0.5) {
                        Text("W")
                            .font(.system(size: size * 0.06, weight: .bold))
                            .foregroundColor(Color(red: 0.31, green: 0.27, blue: 0.90))
                        
                        Text("E")
                            .font(.system(size: size * 0.06, weight: .bold))
                            .foregroundColor(Color(red: 0.31, green: 0.27, blue: 0.90))
                    }
                }
                
                // Éléments de route
                VStack {
                    Spacer()
                    
                    HStack(spacing: size * 0.2) {
                        // Points de route
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(Color(red: 0.94, green: 0.27, blue: 0.27))
                                .frame(width: size * 0.04, height: size * 0.04)
                        }
                    }
                    .offset(y: size * 0.1)
                }
            }
            
            // Texte du logo
            if showText {
                Text("ITINERARLY")
                    .font(.system(size: size * 0.08, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.31, green: 0.27, blue: 0.90))
                    .tracking(1)
            }
        }
    }
}

// MARK: - Variantes du logo
struct ItinerarlyLogoCompactView: View {
    let size: CGFloat
    
    init(size: CGFloat = 60) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Cercle de fond avec dégradé
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.31, green: 0.27, blue: 0.90), Color(red: 0.49, green: 0.23, blue: 0.93)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            // Boussole simplifiée
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: size * 0.7, height: size * 0.7)
                
                // Aiguille simple
                Path { path in
                    path.move(to: CGPoint(x: 0, y: -size * 0.25))
                    path.addLine(to: CGPoint(x: -size * 0.05, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: size * 0.25))
                    path.addLine(to: CGPoint(x: size * 0.05, y: 0))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.94, green: 0.27, blue: 0.27), Color(red: 0.98, green: 0.45, blue: 0.09)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                Circle()
                    .fill(Color(red: 0.31, green: 0.27, blue: 0.90))
                    .frame(width: size * 0.1, height: size * 0.1)
            }
        }
    }
}

// MARK: - Logo pour Splash Screen
struct ItinerarlySplashLogoView: View {
    var body: some View {
        VStack(spacing: 20) {
            ItinerarlyLogoView(size: 120, showText: false)
            
            Text("ITINERARLY")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.31, green: 0.27, blue: 0.90))
                .tracking(2)
            
            Text("Votre compagnon de voyage intelligent")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Preview
struct ItinerarlyLogoView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            ItinerarlyLogoView(size: 120)
            
            HStack(spacing: 20) {
                ItinerarlyLogoCompactView(size: 40)
                ItinerarlyLogoCompactView(size: 60)
                ItinerarlyLogoCompactView(size: 80)
            }
            
            ItinerarlySplashLogoView()
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 