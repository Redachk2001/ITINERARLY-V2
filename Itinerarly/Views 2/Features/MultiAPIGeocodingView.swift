import SwiftUI
import CoreLocation

struct MultiAPIGeocodingView: View {
    @StateObject private var viewModel = EnhancedGeocodingViewModel()
    @State private var addressInput = ""
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "location.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Géocodage Multi-APIs")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Test du système de fallback automatique")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Champ de saisie
                VStack(alignment: .leading, spacing: 8) {
                    Text("Adresse à localiser")
                        .font(.headline)
                    
                    TextField("Ex: Tour Eiffel, Paris", text: $addressInput)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    // Suggestions d'adresses de test
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(testAddresses, id: \.self) { testAddress in
                                Button(action: {
                                    addressInput = testAddress
                                }) {
                                    Text(testAddress)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                
                // Bouton de géocodage
                Button(action: {
                    geocodeAddress()
                }) {
                    HStack {
                        if viewModel.isGeocoding {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "location.fill")
                        }
                        
                        Text(viewModel.isGeocoding ? "Recherche..." : "Localiser l'adresse")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isGeocoding ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(viewModel.isGeocoding || addressInput.isEmpty)
                .padding(.horizontal)
                
                // Progression
                if !viewModel.geocodingProgress.isEmpty {
                    VStack(spacing: 4) {
                        Text(viewModel.geocodingProgress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    .padding()
                }
                
                // Message d'erreur
                if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Résultat
                if let location = viewModel.geocodedLocation {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.green)
                        
                        Text("Adresse localisée !")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Coordonnées GPS:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Latitude: \(location.coordinate.latitude, specifier: "%.6f")")
                                .font(.caption)
                                .font(.system(.caption, design: .monospaced))
                            
                            Text("Longitude: \(location.coordinate.longitude, specifier: "%.6f")")
                                .font(.caption)
                                .font(.system(.caption, design: .monospaced))
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Bouton de test
                Button(action: {
                    testAllAPIs()
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Tester toutes les APIs")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.bottom)
            }
            .navigationTitle("Géocodage Multi-APIs")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Actions
    private func geocodeAddress() {
        guard !addressInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        viewModel.geocodeAddress(addressInput.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    private func testAllAPIs() {
        viewModel.testAllAPIs(with: "Tour Eiffel, Paris")
    }
    
    // MARK: - Données de test
    private let testAddresses = [
        "Tour Eiffel, Paris",
        "Times Square, New York",
        "Sagrada Familia, Barcelona",
        "Mosquée Hassan II, Casablanca",
        "123 Main Street, London",
        "Champs-Élysées, Paris",
        "Central Park, New York",
        "Place Jemaa el-Fna, Marrakech"
    ]
}

// MARK: - Preview
struct MultiAPIGeocodingView_Previews: PreviewProvider {
    static var previews: some View {
        MultiAPIGeocodingView()
    }
} 