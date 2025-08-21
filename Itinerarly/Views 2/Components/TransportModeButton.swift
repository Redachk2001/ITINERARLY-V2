import SwiftUI

struct TransportModeButton: View {
    let mode: TransportMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.system(size: 16, weight: .medium))
                Text(mode.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 60)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TransportModeRow: View {
    @Binding var selectedMode: TransportMode
    let modes: [TransportMode]
    let onModeChanged: (TransportMode) -> Void
    
    init(selectedMode: Binding<TransportMode>, modes: [TransportMode] = TransportMode.allCases, onModeChanged: @escaping (TransportMode) -> Void = { _ in }) {
        self._selectedMode = selectedMode
        self.modes = modes
        self.onModeChanged = onModeChanged
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(modes, id: \.self) { mode in
                TransportModeButton(
                    mode: mode,
                    isSelected: selectedMode == mode
                ) {
                    selectedMode = mode
                    onModeChanged(mode)
                }
            }
        }
    }
}
