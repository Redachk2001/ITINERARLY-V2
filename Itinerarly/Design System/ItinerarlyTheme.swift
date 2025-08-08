import SwiftUI

// MARK: - Itinerarly Design System
// Version 1.0 - Exclusive Design Identity

struct ItinerarlyTheme {
    
    // MARK: - Brand Colors (Core Identity)
    static let oceanBlue = Color(red: 0.2, green: 0.4, blue: 0.8)        // #3366CC - Primary Brand
    static let turquoise = Color(red: 0.1, green: 0.6, blue: 0.7)        // #1A99B3 - Adventure Spirit
    static let coral = Color(red: 1.0, green: 0.4, blue: 0.3)            // #FF664D - Energy & Discovery
    static let deepViolet = Color(red: 0.3, green: 0.2, blue: 0.6)       // #4D3399 - Premium Experience
    
    // MARK: - Extended Palette
    static let lightBlue = Color(red: 0.15, green: 0.5, blue: 0.75)      // #2680BF - Secondary Blue
    static let darkCoral = Color(red: 0.8, green: 0.3, blue: 0.2)        // #CC4D33 - Deep Coral
    static let mintGreen = Color(red: 0.2, green: 0.7, blue: 0.6)        // #33B399 - Fresh & Natural
    static let warmGray = Color(red: 0.4, green: 0.4, blue: 0.4)         // #666666 - Neutral
    
    // MARK: - Semantic Colors
    static let primary = oceanBlue
    static let secondary = turquoise
    static let accent = coral
    static let success = mintGreen
    static let warning = Color(red: 1.0, green: 0.6, blue: 0.2)          // #FF9933
    static let danger = Color(red: 0.9, green: 0.2, blue: 0.2)           // #E63333
    
    // MARK: - Mode-Specific Colors
    enum ModeColors {
        static let planner = oceanBlue
        static let guidedTours = turquoise
        static let suggestions = coral
        static let adventure = deepViolet
        static let profile = warmGray
    }
    
    // MARK: - Background Colors
    enum Backgrounds {
        static let primary = Color(.systemBackground)
        static let secondary = Color(.secondarySystemBackground)
        static let tertiary = Color(.tertiarySystemBackground)
        // Use secondarySystemBackground so cards are clearly darker in Dark Mode
        static let card = Color(.secondarySystemBackground)
        
        // Gradient Backgrounds
        static func modeGradient(for mode: AppModeType) -> LinearGradient {
            switch mode {
            case .planner:
                return LinearGradient(
                    colors: [oceanBlue.opacity(0.15), lightBlue.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .guidedTours:
                return LinearGradient(
                    colors: [turquoise.opacity(0.15), mintGreen.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .suggestions:
                return LinearGradient(
                    colors: [coral.opacity(0.15), darkCoral.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .adventure:
                return LinearGradient(
                    colors: [deepViolet.opacity(0.15), oceanBlue.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .profile:
                return LinearGradient(
                    colors: [warmGray.opacity(0.08), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        
        static let appGradient = LinearGradient(
            colors: [
                oceanBlue.opacity(0.12),
                turquoise.opacity(0.08),
                coral.opacity(0.06),
                deepViolet.opacity(0.05),
                oceanBlue.opacity(0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Typography
    enum Typography {
        // Headlines
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        
        // Body
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        
        // Special
        static let buttonText = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let navigationTitle = Font.system(size: 17, weight: .semibold, design: .rounded)
    }
    
    // MARK: - Spacing System
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
        static let circle: CGFloat = 50
    }
    
    // MARK: - Shadows
    enum Shadow {
        static let small = (color: Color.black.opacity(0.1), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        static let medium = (color: Color.black.opacity(0.1), radius: CGFloat(5), x: CGFloat(0), y: CGFloat(2))
        static let large = (color: Color.black.opacity(0.15), radius: CGFloat(10), x: CGFloat(0), y: CGFloat(4))
        static let xl = (color: Color.black.opacity(0.2), radius: CGFloat(15), x: CGFloat(0), y: CGFloat(6))
        
        // Mode-specific shadows
        static func modeShadow(for mode: AppModeType) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            switch mode {
            case .planner:
                return (oceanBlue.opacity(0.3), 8, 0, 4)
            case .guidedTours:
                return (turquoise.opacity(0.3), 8, 0, 4)
            case .suggestions:
                return (coral.opacity(0.3), 8, 0, 4)
            case .adventure:
                return (deepViolet.opacity(0.3), 8, 0, 4)
            case .profile:
                return (warmGray.opacity(0.3), 8, 0, 4)
            }
        }
    }
    
    // MARK: - Button Styles
    enum ButtonStyle {
        case primary(AppModeType)
        case secondary(AppModeType)
        case tertiary(AppModeType)
        case destructive
        case ghost(AppModeType)
        
        var backgroundColor: Color {
            switch self {
            case .primary(let mode):
                return mode.primaryColor
            case .secondary(let mode):
                return mode.primaryColor.opacity(0.1)
            case .tertiary(_):
                return Color(.secondarySystemBackground)
            case .destructive:
                return ItinerarlyTheme.danger
            case .ghost(_):
                return Color.clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary(_):
                return .white
            case .secondary(let mode), .ghost(let mode):
                return mode.primaryColor
            case .tertiary(_):
                return .primary
            case .destructive:
                return .white
            }
        }
    }
}

// MARK: - App Mode Type Enum
enum AppModeType: CaseIterable {
    case planner, guidedTours, suggestions, adventure, profile
    
    var primaryColor: Color {
        switch self {
        case .planner: return ItinerarlyTheme.ModeColors.planner
        case .guidedTours: return ItinerarlyTheme.ModeColors.guidedTours
        case .suggestions: return ItinerarlyTheme.ModeColors.suggestions
        case .adventure: return ItinerarlyTheme.ModeColors.adventure
        case .profile: return ItinerarlyTheme.ModeColors.profile
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .planner:
            return [ItinerarlyTheme.oceanBlue, ItinerarlyTheme.lightBlue]
        case .guidedTours:
            return [ItinerarlyTheme.turquoise, ItinerarlyTheme.mintGreen]
        case .suggestions:
            return [ItinerarlyTheme.coral, ItinerarlyTheme.darkCoral]
        case .adventure:
            return [ItinerarlyTheme.deepViolet, ItinerarlyTheme.oceanBlue]
        case .profile:
            return [ItinerarlyTheme.warmGray, ItinerarlyTheme.warmGray.opacity(0.7)]
        }
    }
    
    var icon: String {
        switch self {
        case .planner: return "map"
        case .guidedTours: return "headphones"
        case .suggestions: return "lightbulb"
        case .adventure: return "dice"
        case .profile: return "person.circle"
        }
    }
    
    var title: String {
        switch self {
        case .planner: return "Planifier"
        case .guidedTours: return "Tours guidés"
        case .suggestions: return "Suggestions"
        case .adventure: return "Aventure"
        case .profile: return "Profil"
        }
    }
}

// MARK: - View Extensions for Easy Access
extension View {
    func itinerarlyButtonStyle(_ style: ItinerarlyTheme.ButtonStyle) -> some View {
        self
            .font(ItinerarlyTheme.Typography.buttonText)
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, ItinerarlyTheme.Spacing.lg)
            .padding(.vertical, ItinerarlyTheme.Spacing.md)
            .background(style.backgroundColor)
            .cornerRadius(ItinerarlyTheme.CornerRadius.md)
    }
    
    func itinerarlyCard(mode: AppModeType? = nil) -> some View {
        let shadow = mode != nil ? ItinerarlyTheme.Shadow.modeShadow(for: mode!) : ItinerarlyTheme.Shadow.medium
        
        return self
            .background(ItinerarlyTheme.Backgrounds.card)
            .cornerRadius(ItinerarlyTheme.CornerRadius.md)
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    func itinerarlyBackground(mode: AppModeType? = nil) -> some View {
        self.modifier(ThemedBackgroundModifier(mode: mode))
    }
}

// MARK: - Dark-mode aware background
private struct ThemedBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let mode: AppModeType?

    func body(content: Content) -> some View {
        ZStack {
            backgroundView
                .ignoresSafeArea()
            content
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        if colorScheme == .dark {
            // True dark backgrounds with a subtle mode tint
            let baseDark = LinearGradient(
                colors: [Color.black, Color(red: 0.06, green: 0.06, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let mode = mode {
                ZStack {
                    baseDark
                    LinearGradient(
                        colors: [mode.primaryColor.opacity(0.12), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            } else {
                baseDark
            }
        } else {
            // Light mode keeps the soft branded gradients
            if let mode = mode {
                ItinerarlyTheme.Backgrounds.modeGradient(for: mode)
            } else {
                ItinerarlyTheme.Backgrounds.appGradient
            }
        }
    }
}