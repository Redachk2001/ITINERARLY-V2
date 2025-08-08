import SwiftUI

// MARK: - Enhanced User-Friendly Slider
struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let trackColor: Color
    let progressColors: [Color]
    let thumbColor: Color
    let unit: String
    let valueFormatter: ((Double) -> String)?
    
    @State private var isDragging = false
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    init(
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        trackColor: Color,
        progressColors: [Color],
        thumbColor: Color,
        unit: String,
        valueFormatter: ((Double) -> String)? = nil
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.trackColor = trackColor
        self.progressColors = progressColors
        self.thumbColor = thumbColor
        self.unit = unit
        self.valueFormatter = valueFormatter
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Slider principal plus grand et plus facile à utiliser
            sliderBody
        }
        .onAppear {
            hapticFeedback.prepare()
        }
    }
    
    private var sliderBody: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width - 32 // Plus de marge pour faciliter l'utilisation
            let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let thumbPosition = normalizedValue * trackWidth + 16 // Ajuster pour la marge
            
            ZStack(alignment: .leading) {
                // Track background plus épais
                RoundedRectangle(cornerRadius: 8)
                    .fill(trackColor)
                    .frame(height: 16)
                
                // Progress bar avec animation
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: progressColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: max(16, thumbPosition), height: 16)
                    .animation(.easeInOut(duration: 0.1), value: value)
                
                // Thumb plus gros et plus visible
                Circle()
                    .fill(thumbColor)
                    .frame(width: isDragging ? 32 : 28, height: isDragging ? 32 : 28)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                    )
                    .offset(x: thumbPosition - 16, y: 0)
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                if !isDragging {
                                    isDragging = true
                                    hapticFeedback.impactOccurred()
                                }
                                
                                let dragPosition = gesture.location.x
                                let clampedPosition = max(16, min(trackWidth + 16, dragPosition))
                                let newNormalizedValue = (clampedPosition - 16) / trackWidth
                                let newValue = range.lowerBound + newNormalizedValue * (range.upperBound - range.lowerBound)
                                
                                // Snap to step
                                let steppedValue = round(newValue / step) * step
                                let clampedValue = max(range.lowerBound, min(range.upperBound, steppedValue))
                                
                                if abs(clampedValue - value) >= step * 0.5 {
                                    value = clampedValue
                                    hapticFeedback.impactOccurred()
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                                hapticFeedback.impactOccurred()
                            }
                    )
                
                // Affichage de la valeur au-dessus du thumb
                if isDragging || valueFormatter != nil {
                    let displayText = valueFormatter?(value) ?? "\(Int(value))\(unit)"
                    
                    Text(displayText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(thumbColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                        .offset(x: thumbPosition - 16, y: -40)
                        .opacity(isDragging ? 1.0 : 0.8)
                        .animation(.easeInOut(duration: 0.2), value: isDragging)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                let tapPosition = max(16, min(trackWidth + 16, location.x))
                let newNormalizedValue = (tapPosition - 16) / trackWidth
                let newValue = range.lowerBound + newNormalizedValue * (range.upperBound - range.lowerBound)
                
                // Snap to step
                let steppedValue = round(newValue / step) * step
                let clampedValue = max(range.lowerBound, min(range.upperBound, steppedValue))
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    value = clampedValue
                }
                hapticFeedback.impactOccurred()
            }
        }
        .frame(height: 60)
    }
    

}