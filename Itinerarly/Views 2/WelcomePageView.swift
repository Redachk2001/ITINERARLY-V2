import SwiftUI

struct WelcomePageView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var animationOffset: CGFloat = 100
    @State private var animationOpacity: Double = 0
    @State private var bubbleScale: CGFloat = 0.1
    @State private var selectedMode: AppMode?
    @State private var bubblesInitialAnimation = false
    @State private var showSparkles = false
    @State private var isTransitioning = false
    @State private var transitionProgress: Double = 0
    @State private var showLoadingElements = false
    @State private var showMainApp = false
    @State private var showProfile = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Soft beige animated background (cohérent avec le thème Itinerarly)
                SoftBeigeBackground()
                    .ignoresSafeArea()
                
                // Floating background bubbles
                FloatingBubblesBackground()
                    .opacity(animationOpacity * 0.2)

                // Monuments flottants (léger parallax)
                FloatingLandmarksView()
                    .opacity(0.18)
                
                // Sparkles effect
                if showSparkles {
                    SparklesView()
                        .opacity(animationOpacity)
                }
                
                VStack(spacing: 40) {
                    // Espace supérieur réservé (la bulle profil est en overlay topTrailing)
                    Spacer().frame(height: 10)

                    // Header avec animation
                    VStack(spacing: 16) {
                        // Wave animation emoji
                        Text("👋")
                            .font(.system(size: 60))
                            .offset(y: animationOffset)
                            .opacity(animationOpacity)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animationOffset)
                            .rotationEffect(.degrees(animationOpacity == 1 ? 0 : -20))
                            .animation(.spring(response: 1.0, dampingFraction: 0.5).delay(0.8), value: animationOpacity)
                        
                        VStack(spacing: 8) {
                            Text("Salut !")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .offset(y: animationOffset)
                                .opacity(animationOpacity)
                                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3), value: animationOffset)
                            
                            Text("Tu veux faire quoi aujourd'hui ?")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                                .offset(y: animationOffset)
                                .opacity(animationOpacity)
                                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4), value: animationOffset)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    
                    // Bulles des modes avec animation d'entrée spectaculaire
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 24),
                        GridItem(.flexible(), spacing: 24)
                    ], spacing: 24) {
                        ForEach(AppMode.allCases, id: \.self) { mode in
                            AnimatedModeButton(
                                mode: mode,
                                scale: bubbleScale,
                                opacity: animationOpacity,
                                delay: Double(mode.rawValue) * 0.15 + 0.8,
                                initialAnimation: bubblesInitialAnimation
                            ) {
                                startTransition(for: mode)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(isTransitioning ? 0.3 : 1.0)
                .blur(radius: isTransitioning ? 5 : 0)
                .overlay(alignment: .topTrailing) {
                    ProfileBubbleButton(action: { showProfile = true })
                        .padding(.trailing, 16)
                        .padding(.top, 26)
                }
                
                // Transition dynamique overlay
                if isTransitioning, let mode = selectedMode {
                    TransitionLoadingView(
                        mode: mode,
                        progress: transitionProgress,
                        showElements: showLoadingElements
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.5).combined(with: .opacity),
                        removal: .scale(scale: 1.2).combined(with: .opacity)
                    ))
                }
            }
        }
        .onAppear {
            startAnimations()
        }
        .fullScreenCover(isPresented: $showMainApp) {
            if let mode = selectedMode {
                MainTabView(initialTab: mode.rawValue)
            } else {
                MainTabView()
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }
    
    private func startAnimations() {
        // Démarrer les animations d'entrée
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            animationOffset = 0
            animationOpacity = 1.0
        }
        
        // Animation des bulles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                bubbleScale = 1.0
                bubblesInitialAnimation = true
            }
        }
        
        // Sparkles effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showSparkles = true
            }
        }
    }
    
    private func startTransition(for mode: AppMode) {
        selectedMode = mode
        
        // Feedback haptique
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // 1. Démarrer la transition
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            isTransitioning = true
            bubbleScale = 0.8
            animationOpacity = 0.3
        }
        
        // 2. Afficher les éléments de chargement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.showLoadingElements = true
            }
        }
        
        // 3. Animer la progression
        animateProgress()
        
        // 4. Navigation vers l'app principale après la transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                self.showMainApp = true
            }
        }
    }
    
    private func animateProgress() {
        withAnimation(.linear(duration: 1.5)) {
            transitionProgress = 1.0
        }
    }
}

// MARK: - App Mode Enum
enum AppMode: Int, CaseIterable {
    case planner = 0
    case guidedTours = 1
    case suggestions = 2
    case adventure = 3
    
    var title: String {
        switch self {
        case .planner:
            return "Planifier"
        case .guidedTours:
            return "Tours guidés"
        case .suggestions:
            return "Suggestions"
        case .adventure:
            return "Aventure"
        }
    }
    
    var icon: String {
        switch self {
        case .planner:
            return "🗺️"
        case .guidedTours:
            return "🎧"
        case .suggestions:
            return "💡"
        case .adventure:
            return "🎲"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .planner:
            return ItinerarlyTheme.ModeColors.planner
        case .guidedTours:
            return ItinerarlyTheme.ModeColors.guidedTours
        case .suggestions:
            return ItinerarlyTheme.ModeColors.suggestions
        case .adventure:
            return ItinerarlyTheme.ModeColors.adventure
        }
    }
}

// MARK: - Animated Mode Button Component
struct AnimatedModeButton: View {
    let mode: AppMode
    let scale: CGFloat
    let opacity: Double
    let delay: Double
    let initialAnimation: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var showingSparkles = false
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowIntensity: Double = 0.4
    
    var body: some View {
        Button(action: {
            // Haptic feedback plus intense
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                isPressed = true
                showingSparkles = true
                rotationAngle += 360
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                action()
            }
        }) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(mode.primaryColor.opacity(glowIntensity * 0.3))
                    .frame(width: 160, height: 160)
                    .blur(radius: 10)
                    .scaleEffect(pulseScale)
                
                // Background bubble avec effet 3D
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                mode.primaryColor.opacity(0.75),
                                mode.primaryColor.opacity(0.5),
                                mode.primaryColor.opacity(0.85)
                            ],
                            center: .topLeading,
                            startRadius: 10,
                            endRadius: 80
                        )
                    )
                    .frame(width: 150, height: 150)
                    .shadow(color: mode.primaryColor.opacity(0.30), radius: isPressed ? 18 : 10, x: 0, y: isPressed ? 12 : 6)
                    .scaleEffect(isPressed ? 1.15 : 1.0)
                    .rotationEffect(.degrees(rotationAngle))
                
                // Inner glow
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 130, height: 130)
                    .opacity(initialAnimation ? 1.0 : 0.0)
                
                // Content avec animation bounce
                VStack(spacing: 12) {
                    Text(mode.icon)
                        .font(.system(size: 45))
                        .scaleEffect(isPressed ? 1.3 : 1.0)
                        .rotationEffect(.degrees(isPressed ? 10 : 0))
                    
                    Text(mode.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.white.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .offset(y: initialAnimation ? 0 : 200)
                .animation(.spring(response: 0.8, dampingFraction: 0.4).delay(delay), value: initialAnimation)
                
                // Sparkles effect amélioré
                if showingSparkles {
                    ForEach(0..<12, id: \.self) { index in
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: CGFloat.random(in: 3...6), height: CGFloat.random(in: 3...6))
                            .offset(
                                x: CGFloat.random(in: -80...80),
                                y: CGFloat.random(in: -80...80)
                            )
                            .opacity(showingSparkles ? 0 : 1)
                            .scaleEffect(showingSparkles ? 2.0 : 0.1)
                            .animation(
                                .easeOut(duration: 1.0).delay(Double(index) * 0.05),
                                value: showingSparkles
                            )
                    }
                }
            }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .animation(.spring(response: 1.0, dampingFraction: 0.3).delay(delay), value: scale)
        .animation(.spring(response: 1.0, dampingFraction: 0.3).delay(delay), value: opacity)
        .onAppear {
            startContinuousAnimations()
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func startContinuousAnimations() {
        // Animation de pulse continue
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
            glowIntensity = 0.8
        }
    }
}

// MARK: - Profile Bubble (même style que les bulles de mode)
struct ProfileBubbleButton: View {
    let action: () -> Void
    @State private var pulse: CGFloat = 1.0
    var body: some View {
        Button(action: action) {
            ZStack {
                // Minimaliste: cercle blanc discret
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 58, height: 58)
                    .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                    .scaleEffect(pulse)
                Circle()
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    .frame(width: 54, height: 54)
                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulse = 1.05
            }
        }
    }
}

// MARK: - Custom Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Animated Background
struct AnimatedBackground: View {
    @State private var gradientRotation: Double = 0
    
    var body: some View {
        ItinerarlyTheme.Backgrounds.appGradient
        .rotationEffect(.degrees(gradientRotation))
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                gradientRotation = 360
            }
        }
    }
}

// MARK: - Soft Beige Background (theme splash-like)
struct SoftBeigeBackground: View {
    @State private var animate = false
    var body: some View {
        LinearGradient(
            colors: [
                Color(#colorLiteral(red: 0.99, green: 0.97, blue: 0.94, alpha: 1)),
                Color(#colorLiteral(red: 0.98, green: 0.93, blue: 0.88, alpha: 1))
            ],
            startPoint: animate ? .topLeading : .bottomTrailing,
            endPoint: animate ? .bottomTrailing : .topLeading
        )
        .animation(.linear(duration: 18).repeatForever(autoreverses: true), value: animate)
        .onAppear { animate = true }
    }
}

// MARK: - Sparkles View
struct SparklesView: View {
    @State private var sparkleOpacity: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<20, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: CGFloat.random(in: 2...4), height: CGFloat.random(in: 2...4))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .opacity(sparkleOpacity)
                        .animation(
                            .easeInOut(duration: Double.random(in: 1...3))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                            value: sparkleOpacity
                        )
                }
            }
        }
        .onAppear {
            sparkleOpacity = 1.0
        }
    }
}

// MARK: - Floating Bubbles Background
struct FloatingBubblesBackground: View {
    @State private var animatePosition = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<12, id: \.self) { index in
                    FloatingBubble(
                        index: index,
                        geometry: geometry,
                        animatePosition: animatePosition
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animatePosition.toggle()
            }
        }
    }
}

// MARK: - Floating Landmarks Layer
struct FloatingLandmarksView: View {
    @State private var animate = false
    private struct Landmark: Identifiable { let id = UUID(); let emoji: String; let start: CGPoint; let end: CGPoint; let size: CGFloat; let delay: Double }
    private func randomLandmarks(in size: CGSize) -> [Landmark] {
        let emojis = ["🗼", "🗽", "🏛️", "🕌", "⛩️", "🕍", "🗿", "🗿", "🏰", "🗺️"]
        return (0..<8).map { i in
            let start = CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat.random(in: 0...size.height))
            let end = CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat.random(in: 0...size.height))
            return Landmark(emoji: emojis[i % emojis.count], start: start, end: end, size: CGFloat.random(in: 24...36), delay: Double.random(in: 0...2))
        }
    }
    var body: some View {
        GeometryReader { geo in
            let items = randomLandmarks(in: geo.size)
            ZStack {
                ForEach(items) { l in
                    Text(l.emoji)
                        .font(.system(size: l.size))
                        .position(animate ? l.end : l.start)
                        .opacity(0.85)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .animation(
                            .easeInOut(duration: Double.random(in: 10...16))
                                .repeatForever(autoreverses: true)
                                .delay(l.delay),
                            value: animate
                        )
                }
            }
            .onAppear { animate = true }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Individual Floating Bubble
struct FloatingBubble: View {
    let index: Int
    let geometry: GeometryProxy
    let animatePosition: Bool
    
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    private var bubbleColor: Color {
        let colors: [Color] = [
            ItinerarlyTheme.oceanBlue,
            ItinerarlyTheme.turquoise,
            ItinerarlyTheme.coral,
            ItinerarlyTheme.deepViolet,
            ItinerarlyTheme.lightBlue,
            ItinerarlyTheme.darkCoral
        ]
        return colors[index % colors.count]
    }
    
    private var bubbleSize: CGFloat {
        CGFloat.random(in: 20...50)
    }
    
    private var initialPosition: CGPoint {
        CGPoint(
            x: CGFloat.random(in: -50...geometry.size.width + 50),
            y: CGFloat.random(in: -50...geometry.size.height + 50)
        )
    }
    
    private var finalPosition: CGPoint {
        CGPoint(
            x: CGFloat.random(in: -50...geometry.size.width + 50),
            y: CGFloat.random(in: -50...geometry.size.height + 50)
        )
    }
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        bubbleColor.opacity(0.2),
                        bubbleColor.opacity(0.05),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: bubbleSize / 2
                )
            )
            .frame(width: bubbleSize, height: bubbleSize)
            .scaleEffect(pulseScale)
            .rotationEffect(.degrees(rotationAngle))
            .position(animatePosition ? finalPosition : initialPosition)
            .animation(
                .easeInOut(duration: Double.random(in: 6...10))
                .delay(Double(index) * 0.3),
                value: animatePosition
            )
            .onAppear {
                // Rotation continue
                withAnimation(.linear(duration: Double.random(in: 15...25)).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
                
                // Pulse effet
                withAnimation(.easeInOut(duration: Double.random(in: 2...4)).repeatForever(autoreverses: true)) {
                    pulseScale = CGFloat.random(in: 0.8...1.2)
                }
            }
    }
}

// MARK: - Dynamic Transition Loading View
struct TransitionLoadingView: View {
    let mode: AppMode
    let progress: Double
    let showElements: Bool
    
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var sparkleOpacity: Double = 0
    @State private var messageIndex = 0
    
    private var loadingMessages: [String] {
        switch mode {
        case .planner:
            return [
                "Préparation du planificateur...",
                "Chargement des cartes...",
                "Optimisation des itinéraires...",
                "Prêt à planifier ! 🗺️"
            ]
        case .guidedTours:
            return [
                "Préparation des tours guidés...",
                "Chargement des audioguides...",
                "Synchronisation du contenu...",
                "Découverte en cours ! 🎧"
            ]
        case .suggestions:
            return [
                "Recherche d'activités sympas...",
                "Analyse de vos préférences...",
                "Génération de suggestions...",
                "Inspiration trouvée ! 💡"
            ]
        case .adventure:
            return [
                "Préparation de l'aventure...",
                "Recherche de lieux insolites...",
                "Création de surprises...",
                "Aventure prête ! 🎲"
            ]
        }
    }
    
    var body: some View {
        ZStack {
            // Background dégradé spécifique au mode
            LinearGradient(
                colors: [
                    mode.primaryColor.opacity(0.95),
                    mode.primaryColor.opacity(0.8),
                    mode.primaryColor.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: ItinerarlyTheme.Spacing.xl) {
                
                // Mode Icon with animation
                ZStack {
                    // Pulsing background
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseScale)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
                    
                    // Rotating ring
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 3)
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(rotationAngle))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: rotationAngle)
                    
                    // Mode icon
                    Text(mode.icon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white)
                        .scaleEffect(showElements ? 1.0 : 0.1)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showElements)
                }
                
                if showElements {
                    VStack(spacing: ItinerarlyTheme.Spacing.lg) {
                        
                        // Mode title
                        Text(mode.title)
                            .font(ItinerarlyTheme.Typography.title2)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .opacity(showElements ? 1 : 0)
                            .animation(.easeInOut(duration: 0.8).delay(0.2), value: showElements)
                        
                        // Dynamic progress bar
                        VStack(spacing: ItinerarlyTheme.Spacing.sm) {
                            ProgressView(value: progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: mode.primaryColor))
                                .frame(height: 8)
                                .frame(maxWidth: 200)
                            
                            Text("\(Int(progress * 100))%")
                                .font(ItinerarlyTheme.Typography.caption1)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .opacity(showElements ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8).delay(0.4), value: showElements)
                        
                        // Dynamic loading message
                        Text(loadingMessages[messageIndex])
                            .font(ItinerarlyTheme.Typography.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .opacity(showElements ? 1 : 0)
                            .animation(.easeInOut(duration: 0.8).delay(0.6), value: showElements)
                            .id("message-\(messageIndex)")
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                        // Sparkles effet
                        HStack(spacing: 8) {
                            ForEach(0..<5) { index in
                                Image(systemName: "sparkle")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .opacity(sparkleOpacity)
                                    .animation(
                                        .easeInOut(duration: 0.8)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(index) * 0.2),
                                        value: sparkleOpacity
                                    )
                            }
                        }
                        .opacity(showElements ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8).delay(0.8), value: showElements)
                    }
                }
            }
            .padding(ItinerarlyTheme.Spacing.lg)
        }
        .onAppear {
            startLoadingAnimations()
            startMessageRotation()
        }
    }
    
    private func startLoadingAnimations() {
        rotationAngle = 360
        pulseScale = 1.2
        sparkleOpacity = 1.0
    }
    
    private func startMessageRotation() {
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            DispatchQueue.main.async {
                if self.messageIndex < self.loadingMessages.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.messageIndex += 1
                    }
                } else {
                    timer.invalidate()
                }
            }
        }
    }
} 