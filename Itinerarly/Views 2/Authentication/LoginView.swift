import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Label("Email", systemImage: "envelope")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("votre@email.com", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Label("Mot de passe", systemImage: "lock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack {
                    Group {
                        if showPassword {
                            TextField("Mot de passe", text: $password)
                        } else {
                            SecureField("Mot de passe", text: $password)
                        }
                    }
                    .textFieldStyle(PlainTextFieldStyle())
                    
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
            
            // Error Message
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            
            // Login Button
            Button(action: handleLogin) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Se connecter")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(authManager.isLoading || !isFormValid)
                .opacity((authManager.isLoading || !isFormValid) ? 0.6 : 1.0)
            }
            .padding(.top, 8)
            
            // Forgot Password
            Button("Mot de passe oublié ?") {
                // TODO: Implement forgot password
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.blue)
        }
        .onAppear {
            authManager.clearError()
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func handleLogin() {
        authManager.login(email: email, password: password)
    }
}

// CustomTextFieldStyle déplacé dans SharedStyles.swift

#Preview {
    LoginView()
        .environmentObject(AuthManager())
        .padding()
} 