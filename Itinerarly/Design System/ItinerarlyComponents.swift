import SwiftUI

// MARK: - Itinerarly Design Components
// Composants réutilisables avec l'identité Itinerarly

// MARK: - Buttons
struct ItinerarlyButton: View {
    let title: String
    let style: ItinerarlyTheme.ButtonStyle
    let icon: String?
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(_ title: String, style: ItinerarlyTheme.ButtonStyle, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: ItinerarlyTheme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(ItinerarlyTheme.Typography.buttonText)
            }
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, ItinerarlyTheme.Spacing.lg)
            .padding(.vertical, ItinerarlyTheme.Spacing.md)
            .background(style.backgroundColor)
            .cornerRadius(ItinerarlyTheme.CornerRadius.md)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Cards
struct ItinerarlyCard<Content: View>: View {
    let mode: AppModeType?
    let content: Content
    
    init(mode: AppModeType? = nil, @ViewBuilder content: () -> Content) {
        self.mode = mode
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(ItinerarlyTheme.Spacing.lg)
            .itinerarlyCard(mode: mode)
    }
}

// MARK: - Mode Selector
struct ItinerarlyModeSelector: View {
    @Binding var selectedMode: AppModeType
    let modes: [AppModeType]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ItinerarlyTheme.Spacing.md) {
                ForEach(modes, id: \.self) { mode in
                    ModeChip(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedMode = mode
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, ItinerarlyTheme.Spacing.lg)
        }
    }
}

struct ModeChip: View {
    let mode: AppModeType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ItinerarlyTheme.Spacing.sm) {
                Image(systemName: mode.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(mode.title)
                    .font(ItinerarlyTheme.Typography.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : mode.primaryColor)
            .padding(.horizontal, ItinerarlyTheme.Spacing.md)
            .padding(.vertical, ItinerarlyTheme.Spacing.sm)
            .background(isSelected ? mode.primaryColor : mode.primaryColor.opacity(0.1))
            .cornerRadius(ItinerarlyTheme.CornerRadius.xl)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Progress Indicators
struct ItinerarlyProgressBar: View {
    let progress: Double
    let mode: AppModeType
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 8)
                    .cornerRadius(ItinerarlyTheme.CornerRadius.xs)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: mode.gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 8)
                    .cornerRadius(ItinerarlyTheme.CornerRadius.xs)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Custom Slider
struct ItinerarlySlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let mode: AppModeType
    let unit: String
    let valueFormatter: ((Double) -> String)?
    
    @State private var isDragging = false
    
    init(
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 1,
        mode: AppModeType,
        unit: String = "",
        valueFormatter: ((Double) -> String)? = nil
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.mode = mode
        self.unit = unit
        self.valueFormatter = valueFormatter
    }
    
    var body: some View {
        VStack(spacing: ItinerarlyTheme.Spacing.md) {
            // Slider
            GeometryReader { geometry in
                let trackWidth = geometry.size.width - 32
                let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
                let thumbPosition = normalizedValue * trackWidth + 16
                
                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: ItinerarlyTheme.CornerRadius.sm)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: ItinerarlyTheme.CornerRadius.sm)
                        .fill(
                            LinearGradient(
                                colors: mode.gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, thumbPosition), height: 6)
                    
                    // Thumb
                    Circle()
                        .fill(mode.primaryColor)
                        .frame(width: isDragging ? 24 : 20, height: isDragging ? 24 : 20)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .shadow(color: mode.primaryColor.opacity(0.3), radius: isDragging ? 8 : 4)
                        )
                        .offset(x: thumbPosition - 12, y: 0)
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    if !isDragging {
                                        isDragging = true
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                    }
                                    
                                    let dragPosition = gesture.location.x
                                    let clampedPosition = max(16, min(trackWidth + 16, dragPosition))
                                    let newNormalizedValue = (clampedPosition - 16) / trackWidth
                                    let newValue = range.lowerBound + newNormalizedValue * (range.upperBound - range.lowerBound)
                                    
                                    let steppedValue = round(newValue / step) * step
                                    let clampedValue = max(range.lowerBound, min(range.upperBound, steppedValue))
                                    
                                    value = clampedValue
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                        )
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let tapPosition = max(16, min(trackWidth + 16, location.x))
                    let newNormalizedValue = (tapPosition - 16) / trackWidth
                    let newValue = range.lowerBound + newNormalizedValue * (range.upperBound - range.lowerBound)
                    
                    let steppedValue = round(newValue / step) * step
                    let clampedValue = max(range.lowerBound, min(range.upperBound, steppedValue))
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        value = clampedValue
                    }
                }
            }
            .frame(height: 40)
        }
    }
}

// MARK: - Status Badge
struct ItinerarlyStatusBadge: View {
    let text: String
    let status: StatusType
    
    enum StatusType {
        case success, warning, error, info(AppModeType)
        
        var color: Color {
            switch self {
            case .success: return ItinerarlyTheme.success
            case .warning: return ItinerarlyTheme.warning
            case .error: return ItinerarlyTheme.danger
            case .info(let mode): return mode.primaryColor
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(ItinerarlyTheme.Typography.caption1)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, ItinerarlyTheme.Spacing.sm)
            .padding(.vertical, ItinerarlyTheme.Spacing.xs)
            .background(status.color)
            .cornerRadius(ItinerarlyTheme.CornerRadius.xs)
    }
}

// MARK: - Loading States
struct ItinerarlyLoadingView: View {
    let mode: AppModeType
    let message: String
    
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: ItinerarlyTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .stroke(mode.primaryColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(mode.primaryColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(rotation))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: rotation)
            }
            .onAppear {
                rotation = 360
            }
            
            Text(message)
                .font(ItinerarlyTheme.Typography.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(ItinerarlyTheme.Spacing.xl)
    }
}

// MARK: - Section Header
struct ItinerarlySectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let mode: AppModeType?
    
    init(_ title: String, subtitle: String? = nil, icon: String? = nil, mode: AppModeType? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.mode = mode
    }
    
    var body: some View {
        HStack(spacing: ItinerarlyTheme.Spacing.md) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(mode?.primaryColor ?? ItinerarlyTheme.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ItinerarlyTheme.Typography.title3)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(ItinerarlyTheme.Typography.caption1)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, ItinerarlyTheme.Spacing.lg)
        .padding(.vertical, ItinerarlyTheme.Spacing.md)
    }
}