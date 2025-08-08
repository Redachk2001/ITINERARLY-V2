import SwiftUI

struct SplashView: View {
    @State private var scale = 0.7
    @State private var opacity = 0.5
    @State private var bob = false
    @State private var pulse = false
    @State private var spin: Double = 0
    
    var body: some View {
        ZStack {
            // Gradient Background moderne
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.31, green: 0.27, blue: 0.90), // Indigo
                    Color(red: 0.49, green: 0.23, blue: 0.93)  // Violet
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo: globe stylisé avec un I et son point
                GlobeILogoView(size: 170, spin: spin, pulse: pulse, bob: bob)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                // App Name et description
                VStack(spacing: 12) {
                    Text("ITINERARLY")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                        .opacity(opacity)
                    
                    Text("Votre compagnon de voyage intelligent")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(opacity)
                }
                
                // Indicateur de chargement
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                        .opacity(opacity)
                    
                    Text("Chargement...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(opacity)
                }
            }
        }
        .onAppear {
            // Animation d'apparition
            withAnimation(.easeInOut(duration: 1.5)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Animations (bobbing + itinéraire animé)
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                bob = true
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                spin = 360
            }
        }
    }
}

#Preview {
    SplashView()
} 

// MARK: - Route Logo View
private struct GlobeILogoView: View {
    let size: CGFloat
    let spin: Double
    let pulse: Bool
    let bob: Bool

    var body: some View {
        ZStack {
            // Halo
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: size * 0.95, height: size * 0.95)
                .blur(radius: 1)

            // Globe principal
            Circle()
                .stroke(Color.white.opacity(0.35), lineWidth: 2)
                .background(Circle().fill(LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                .frame(width: size * 0.9, height: size * 0.9)
                .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)

            // Méridiens / parallèles
            GlobeGrid()
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                .frame(width: size * 0.86, height: size * 0.86)
                .rotationEffect(.degrees(spin))

            // Monogramme I au centre (pilier)
            RoundedRectangle(cornerRadius: size * 0.1, style: .continuous)
                .fill(Color.white.opacity(0.22))
                .frame(width: size * 0.18, height: size * 0.68)
                .overlay(RoundedRectangle(cornerRadius: size * 0.1, style: .continuous).stroke(Color.white.opacity(0.35), lineWidth: 1))

            // Point du i
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.11, height: size * 0.11)
                .offset(y: -size * 0.44)
                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                .scaleEffect(pulse ? 1.06 : 0.94)
        }
        .offset(y: bob ? -5 : 5)
    }
}

// Méridiens/parallèles stylisés (3 cercles + 2 arcs en rotation)
private struct GlobeGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height)/2
        // Parallèles
        p.addEllipse(in: CGRect(x: center.x-r, y: center.y-r*0.6, width: r*2, height: r*1.2))
        p.addEllipse(in: CGRect(x: center.x-r, y: center.y-r*0.3, width: r*2, height: r*0.6))
        // Méridiens (arcs)
        p.addArc(center: center, radius: r*0.95, startAngle: .degrees(-70), endAngle: .degrees(70), clockwise: false)
        p.addArc(center: center, radius: r*0.95, startAngle: .degrees(110), endAngle: .degrees(250), clockwise: false)
        return p
    }
}

// Grille subtile (4x4)
private struct GridOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cols = 4
        let rows = 4
        let cw = rect.width / CGFloat(cols)
        let rh = rect.height / CGFloat(rows)
        for i in 1..<cols { p.move(to: CGPoint(x: rect.minX + CGFloat(i)*cw, y: rect.minY)); p.addLine(to: CGPoint(x: rect.minX + CGFloat(i)*cw, y: rect.maxY)) }
        for j in 1..<rows { p.move(to: CGPoint(x: rect.minX, y: rect.minY + CGFloat(j)*rh)); p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + CGFloat(j)*rh)) }
        return p
    }
}

// Tracé qui forme implicitement un "I" (départ au point du i)
private struct IRoutePath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let start = CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.02)
        let c1 = CGPoint(x: rect.midX - rect.width * 0.36, y: rect.minY + rect.height * 0.18)
        let c2 = CGPoint(x: rect.midX + rect.width * 0.28, y: rect.minY + rect.height * 0.34)
        let mid = CGPoint(x: rect.midX, y: rect.midY)
        let c3 = CGPoint(x: rect.midX - rect.width * 0.28, y: rect.maxY - rect.height * 0.28)
        let c4 = CGPoint(x: rect.midX + rect.width * 0.34, y: rect.maxY - rect.height * 0.14)
        let end = CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.02)
        p.move(to: start)
        p.addCurve(to: mid, control1: c1, control2: c2)
        p.addCurve(to: end, control1: c3, control2: c4)
        return p
    }
}

// MARK: - Helpers
// Courbe du tracé de l'itinéraire
private struct RoutePath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let start = CGPoint(x: rect.minX + rect.width * 0.08, y: rect.maxY - rect.height * 0.18)
        let end = CGPoint(x: rect.maxX - rect.width * 0.06, y: rect.minY + rect.height * 0.22)
        let c1 = CGPoint(x: rect.minX + rect.width * 0.35, y: rect.minY + rect.height * 0.05)
        let c2 = CGPoint(x: rect.minX + rect.width * 0.55, y: rect.maxY - rect.height * 0.05)
        p.move(to: start)
        p.addCurve(to: end, control1: c1, control2: c2)
        return p
    }
}

// Petit utilitaire pour positionner un contenu à un alignement précis dans un frame
private struct AlignmentReader<Content: View>: View {
    let alignment: Alignment
    let content: () -> Content
    
    init(_ alignment: Alignment, @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.content = content
    }
    
    var body: some View {
        ZStack(alignment: alignment) {
            Color.clear
            content()
        }
    }
}

// Chemin de l'itinéraire partant du point du "i"
private struct MonogramRoutePath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // départ proche du point du i (en haut-centre)
        let start = CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.08)
        let end = CGPoint(x: rect.maxX - rect.width * 0.06, y: rect.maxY - rect.height * 0.12)
        let c1 = CGPoint(x: rect.midX - rect.width * 0.38, y: rect.minY + rect.height * 0.22)
        let c2 = CGPoint(x: rect.midX + rect.width * 0.30, y: rect.maxY - rect.height * 0.18)
        p.move(to: start)
        p.addCurve(to: end, control1: c1, control2: c2)
        return p
    }
}