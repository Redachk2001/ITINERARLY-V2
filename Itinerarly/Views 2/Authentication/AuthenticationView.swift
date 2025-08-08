import SwiftUI

struct AuthenticationView: View {
    @State private var isLoginMode = true
    @State private var showingPassword = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(.blue)
                        
                        Text("Itinerarly")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(isLoginMode ? "Bon retour !" : "Créez votre compte")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                    
                    // Authentication Form
                    VStack(spacing: 24) {
                        // Mode Selector
                        Picker("Mode", selection: $isLoginMode) {
                            Text("Connexion").tag(true)
                            Text("Inscription").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        // Form Content
                        if isLoginMode {
                            LoginView()
                        } else {
                            SignupView()
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoginMode)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthManager())
} 