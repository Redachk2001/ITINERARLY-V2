import Foundation
import AVFoundation
import Combine

// MARK: - Voice Models
struct AudioVoice: Identifiable, Codable {
    let id: String
    let name: String
    let language: String
    let voiceIdentifier: String
    let description: String
    let isPremium: Bool
    
    static let availableVoices: [AudioVoice] = [
        // Voix françaises
        AudioVoice(id: "fr-female-1", name: "Marie", language: "fr-FR", voiceIdentifier: "com.apple.ttsbundle.Marie-compact", description: "Voix féminine française claire et professionnelle", isPremium: false),
        AudioVoice(id: "fr-female-2", name: "Sophie", language: "fr-FR", voiceIdentifier: "com.apple.ttsbundle.Sophie-compact", description: "Voix féminine française chaleureuse", isPremium: false),
        AudioVoice(id: "fr-male-1", name: "Thomas", language: "fr-FR", voiceIdentifier: "com.apple.ttsbundle.Thomas-compact", description: "Voix masculine française posée", isPremium: false),
        AudioVoice(id: "fr-male-2", name: "Pierre", language: "fr-FR", voiceIdentifier: "com.apple.ttsbundle.Pierre-compact", description: "Voix masculine française dynamique", isPremium: false),
        
        // Voix anglaises
        AudioVoice(id: "en-female-1", name: "Emma", language: "en-US", voiceIdentifier: "com.apple.ttsbundle.Samantha-compact", description: "Voix féminine anglaise claire", isPremium: false),
        AudioVoice(id: "en-male-1", name: "James", language: "en-US", voiceIdentifier: "com.apple.ttsbundle.Alex-compact", description: "Voix masculine anglaise professionnelle", isPremium: false),
        
        // Voix allemandes
        AudioVoice(id: "de-female-1", name: "Anna", language: "de-DE", voiceIdentifier: "com.apple.ttsbundle.Anna-compact", description: "Voix féminine allemande", isPremium: true),
        AudioVoice(id: "de-male-1", name: "Hans", language: "de-DE", voiceIdentifier: "com.apple.ttsbundle.Hans-compact", description: "Voix masculine allemande", isPremium: true),
        
        // Voix espagnoles
        AudioVoice(id: "es-female-1", name: "Carmen", language: "es-ES", voiceIdentifier: "com.apple.ttsbundle.Carmen-compact", description: "Voix féminine espagnole", isPremium: true),
        AudioVoice(id: "es-male-1", name: "Carlos", language: "es-ES", voiceIdentifier: "com.apple.ttsbundle.Carlos-compact", description: "Voix masculine espagnole", isPremium: true),
        
        // Voix italiennes
        AudioVoice(id: "it-female-1", name: "Giulia", language: "it-IT", voiceIdentifier: "com.apple.ttsbundle.Giulia-compact", description: "Voix féminine italienne", isPremium: true),
        AudioVoice(id: "it-male-1", name: "Marco", language: "it-IT", voiceIdentifier: "com.apple.ttsbundle.Marco-compact", description: "Voix masculine italienne", isPremium: true)
    ]
    
    static let defaultVoice = availableVoices.first!
    
    // Fonction pour obtenir les vraies voix système
    static func getSystemVoices() -> [AudioVoice] {
        let systemVoices = AVSpeechSynthesisVoice.speechVoices()
        var customVoices: [AudioVoice] = []
        
        // Récupérer toutes les voix françaises disponibles
        let frenchVoices = systemVoices.filter { $0.language.hasPrefix("fr") }
        
        if let frVoice = frenchVoices.first {
            // Voix française standard
            customVoices.append(AudioVoice(
                id: "fr-standard",
                name: "Marie",
                language: "fr-FR",
                voiceIdentifier: frVoice.identifier,
                description: "Voix française claire et professionnelle",
                isPremium: false
            ))
            
            // Voix française plus lente
            customVoices.append(AudioVoice(
                id: "fr-slow",
                name: "Sophie",
                language: "fr-FR",
                voiceIdentifier: frVoice.identifier,
                description: "Voix française posée et détaillée",
                isPremium: false
            ))
            
            // Voix française plus rapide
            customVoices.append(AudioVoice(
                id: "fr-fast",
                name: "Claire",
                language: "fr-FR",
                voiceIdentifier: frVoice.identifier,
                description: "Voix française dynamique et énergique",
                isPremium: false
            ))
            
            // Voix française grave
            customVoices.append(AudioVoice(
                id: "fr-deep",
                name: "Thomas",
                language: "fr-FR",
                voiceIdentifier: frVoice.identifier,
                description: "Voix française masculine et posée",
                isPremium: false
            ))
            
            // Voix française aiguë
            customVoices.append(AudioVoice(
                id: "fr-high",
                name: "Emma",
                language: "fr-FR",
                voiceIdentifier: frVoice.identifier,
                description: "Voix française jeune et enthousiaste",
                isPremium: false
            ))
        }
        
        // Ajouter quelques voix anglaises si disponibles
        if let enVoice = systemVoices.first(where: { $0.language.hasPrefix("en-US") }) {
            customVoices.append(AudioVoice(
                id: "en-system",
                name: "English Voice",
                language: "en-US",
                voiceIdentifier: enVoice.identifier,
                description: "English system voice",
                isPremium: false
            ))
        }
        
        return customVoices.isEmpty ? availableVoices : customVoices
    }
}

class AudioService: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentProgress: Double = 0.0
    @Published var totalDuration: Double = 0.0
    @Published var errorMessage: String?
    @Published var selectedVoice: AudioVoice = AudioVoice.defaultVoice
    @Published var availableVoices: [AudioVoice] = AudioVoice.getSystemVoices()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var currentUtterance: AVSpeechUtterance?
    private var progressTimer: Timer?
    
    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            errorMessage = "Failed to setup audio session: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Text-to-Speech
    func speakText(_ text: String, language: String? = nil) {
        guard !text.isEmpty else { return }
        
        // Stop any current speech
        stopSpeaking()
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Utiliser la voix sélectionnée ou la langue spécifiée
        if let language = language {
            utterance.voice = AVSpeechSynthesisVoice(language: language)
        } else {
            // Essayer d'abord avec l'identifiant exact
            if let voice = AVSpeechSynthesisVoice(identifier: selectedVoice.voiceIdentifier) {
                utterance.voice = voice
            } else {
                // Fallback sur la langue
                utterance.voice = AVSpeechSynthesisVoice(language: selectedVoice.language)
            }
        }
        
        // Appliquer des paramètres différents selon la voix sélectionnée
        switch selectedVoice.id {
        case "fr-standard":
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
            utterance.volume = 1.0
        case "fr-slow":
            utterance.rate = 0.4
            utterance.pitchMultiplier = 0.9
            utterance.volume = 1.0
        case "fr-fast":
            utterance.rate = 0.6
            utterance.pitchMultiplier = 1.1
            utterance.volume = 1.0
        case "fr-deep":
            utterance.rate = 0.45
            utterance.pitchMultiplier = 0.7
            utterance.volume = 1.0
        case "fr-high":
            utterance.rate = 0.55
            utterance.pitchMultiplier = 1.3
            utterance.volume = 1.0
        default:
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
            utterance.volume = 1.0
        }
        
        currentUtterance = utterance
        synthesizer.speak(utterance)
        isPlaying = true
        
        print("🎤 Utilisation de la voix: \(selectedVoice.name) (\(selectedVoice.language)) - Rate: \(utterance.rate), Pitch: \(utterance.pitchMultiplier)")
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isPlaying = false
        currentProgress = 0.0
        currentUtterance = nil
        stopProgressTimer()
    }
    
    func pauseSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
        }
    }
    
    func resumeSpeaking() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }
    
    // MARK: - Audio File Playback
    func playAudioFromURL(_ url: URL) {
        stopSpeaking()
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            totalDuration = audioPlayer?.duration ?? 0.0
            
            if audioPlayer?.play() == true {
                isPlaying = true
                startProgressTimer()
            }
        } catch {
            errorMessage = "Failed to play audio: \(error.localizedDescription)"
        }
    }
    
    func playAudioFromData(_ data: Data) {
        stopSpeaking()
        
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            totalDuration = audioPlayer?.duration ?? 0.0
            
            if audioPlayer?.play() == true {
                isPlaying = true
                startProgressTimer()
            }
        } catch {
            errorMessage = "Failed to play audio: \(error.localizedDescription)"
        }
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
    }
    
    func resumeAudio() {
        if audioPlayer?.play() == true {
            isPlaying = true
            startProgressTimer()
        }
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentProgress = 0.0
        totalDuration = 0.0
        stopProgressTimer()
    }
    
    func seekTo(progress: Double) {
        guard let player = audioPlayer else { return }
        let time = progress * player.duration
        player.currentTime = time
        currentProgress = progress
    }
    
    // MARK: - Progress Tracking
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func updateProgress() {
        if let player = audioPlayer, player.isPlaying {
            currentProgress = player.currentTime / player.duration
        }
    }
    
    // MARK: - Helper Methods
    func clearError() {
        errorMessage = nil
    }
    
    var systemAvailableVoices: [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices()
            .filter { voice in
                voice.language.hasPrefix("fr") || voice.language.hasPrefix("en")
            }
    }
    
    // MARK: - Voice Management
    func changeVoice(to voice: AudioVoice) {
        selectedVoice = voice
        // Sauvegarder la préférence
        UserDefaults.standard.set(voice.id, forKey: "selectedAudioVoice")
    }
    
    func loadSavedVoice() {
        if let savedVoiceId = UserDefaults.standard.string(forKey: "selectedAudioVoice"),
           let savedVoice = availableVoices.first(where: { $0.id == savedVoiceId }) {
            selectedVoice = savedVoice
        }
    }
    
    func reloadSystemVoices() {
        availableVoices = AudioVoice.getSystemVoices()
        // Mettre à jour la voix sélectionnée si elle n'existe plus
        if !availableVoices.contains(where: { $0.id == selectedVoice.id }) {
            selectedVoice = availableVoices.first ?? AudioVoice.defaultVoice
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension AudioService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = true
            self.totalDuration = Double(utterance.speechString.count) * 0.1 // Rough estimation
            self.startProgressTimer()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentProgress = 1.0
            self.stopProgressTimer()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.stopProgressTimer()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = true
            self.startProgressTimer()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            let totalLength = utterance.speechString.count
            let progress = Double(characterRange.location) / Double(totalLength)
            self.currentProgress = progress
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentProgress = 1.0
            self.stopProgressTimer()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.errorMessage = error?.localizedDescription ?? "Audio playback error"
            self.stopProgressTimer()
        }
    }
} 