import SwiftUI

struct SignupView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var acceptedTerms = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Name Field
            VStack(alignment: .leading, spacing: 8) {
                Label("Nom complet", systemImage: "person")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Votre nom", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
            }
            
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
                        .stroke(passwordValidationColor, lineWidth: 1)
                )
                
                // Password validation
                if !password.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        PasswordValidationRow(
                            text: "Au moins 8 caractères",
                            isValid: password.count >= 8
                        )
                        PasswordValidationRow(
                            text: "Au moins une majuscule",
                            isValid: password.range(of: "[A-Z]", options: .regularExpression) != nil
                        )
                        PasswordValidationRow(
                            text: "Au moins un chiffre",
                            isValid: password.range(of: "[0-9]", options: .regularExpression) != nil
                        )
                    }
                    .font(.caption)
                    .padding(.top, 4)
                }
            }
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: 8) {
                Label("Confirmer le mot de passe", systemImage: "lock.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack {
                    Group {
                        if showConfirmPassword {
                            TextField("Confirmer", text: $confirmPassword)
                        } else {
                            SecureField("Confirmer", text: $confirmPassword)
                        }
                    }
                    .textFieldStyle(PlainTextFieldStyle())
                    
                    Button(action: { showConfirmPassword.toggle() }) {
                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(confirmPasswordValidationColor, lineWidth: 1)
                )
                
                if !confirmPassword.isEmpty && password != confirmPassword {
                    Text("Les mots de passe ne correspondent pas")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
            }
            
            // Terms and Conditions
            HStack(alignment: .top, spacing: 12) {
                Button(action: { acceptedTerms.toggle() }) {
                    Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                        .foregroundColor(acceptedTerms ? .blue : .secondary)
                        .font(.system(size: 18))
                }
                
                Text("J'accepte les **conditions d'utilisation** et la **politique de confidentialité**")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            // Error Message
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            
            // Signup Button
            Button(action: handleSignup) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "person.badge.plus")
                        Text("Créer mon compte")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
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
        }
        .onAppear {
            authManager.clearError()
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        isPasswordValid &&
        password == confirmPassword &&
        acceptedTerms
    }
    
    private var isPasswordValid: Bool {
        password.count >= 8 &&
        password.range(of: "[A-Z]", options: .regularExpression) != nil &&
        password.range(of: "[0-9]", options: .regularExpression) != nil
    }
    
    private var passwordValidationColor: Color {
        if password.isEmpty {
            return Color(.systemGray4)
        }
        return isPasswordValid ? .green : .red
    }
    
    private var confirmPasswordValidationColor: Color {
        if confirmPassword.isEmpty {
            return Color(.systemGray4)
        }
        return password == confirmPassword ? .green : .red
    }
    
    private func handleSignup() {
        authManager.signup(name: name, email: email, password: password)
    }
}

struct PasswordValidationRow: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isValid ? .green : .red)
                .font(.system(size: 12))
            
            Text(text)
                .foregroundColor(isValid ? .green : .red)
            
            Spacer()
        }
    }
}

#Preview {
    SignupView()
        .environmentObject(AuthManager())
        .padding()
} 