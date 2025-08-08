import SwiftUI

struct AudioSettingsView: View {
    @EnvironmentObject var audioService: AudioService
    @Environment(\.dismiss) private var dismiss
    @State private var showingPremiumAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Voix d'audio guide")) {
                    ForEach(audioService.availableVoices) { voice in
                        VoiceSelectionRow(
                            voice: voice,
                            isSelected: audioService.selectedVoice.id == voice.id,
                            onSelect: {
                                if voice.isPremium {
                                    showingPremiumAlert = true
                                } else {
                                    audioService.changeVoice(to: voice)
                                }
                            }
                        )
                    }
                }
                
                Section(header: Text("Informations"), footer: Text("Les voix premium nécessitent un abonnement pour être utilisées.")) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Voix actuelle")
                        Spacer()
                        Text(audioService.selectedVoice.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(.green)
                        Text("Test de voix")
                        Spacer()
                        Button("Écouter") {
                            audioService.speakText("Bonjour, je suis votre guide audio. Comment puis-je vous aider ?")
                        }
                        .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.orange)
                        Text("Recharger les voix")
                        Spacer()
                        Button("Actualiser") {
                            audioService.reloadSystemVoices()
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Paramètres Audio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Terminé") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Voix Premium", isPresented: $showingPremiumAlert) {
            Button("OK") { }
        } message: {
            Text("Cette voix est disponible en version premium. Améliorez votre expérience avec des voix de qualité supérieure !")
        }
        .onAppear {
            audioService.loadSavedVoice()
            audioService.reloadSystemVoices()
        }
    }
}

struct VoiceSelectionRow: View {
    let voice: AudioVoice
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(voice.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if voice.isPremium {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(voice.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Text(voice.language)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                        
                        if voice.isPremium {
                            Text("Premium")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AudioSettingsView()
        .environmentObject(AudioService())
} 