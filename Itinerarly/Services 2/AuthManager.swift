import Foundation
import Combine

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private let userDefaultsKey = "user_token"
    private let userKey = "current_user"
    
    init() {
        checkAuthStatus()
    }
    
    private func checkAuthStatus() {
        if let token = UserDefaults.standard.string(forKey: userDefaultsKey),
           let userData = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            
            // Verify token is still valid
            apiService.setAuthToken(token)
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        let request = LoginRequest(email: email, password: password)
        
        apiService.login(request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.handleAuthSuccess(response: response)
                }
            )
            .store(in: &cancellables)
    }
    
    func signup(name: String, email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        let request = SignupRequest(email: email, password: password, name: name)
        
        apiService.signup(request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.handleAuthSuccess(response: response)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleAuthSuccess(response: AuthResponse) {
        // Save token and user data
        UserDefaults.standard.set(response.token, forKey: userDefaultsKey)
        
        if let userData = try? JSONEncoder().encode(response.user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
        
        // Update API service
        apiService.setAuthToken(response.token)
        
        // Update state
        currentUser = response.user
        isAuthenticated = true
        errorMessage = nil
    }
    
    func logout() {
        // Clear stored data
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        
        // Clear API service token
        apiService.clearAuthToken()
        
        // Update state
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
    }
    
    func clearError() {
        errorMessage = nil
    }
} 