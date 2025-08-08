import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email, name
        case createdAt = "created_at"
    }
}

struct AuthResponse: Codable {
    let user: User
    let token: String
    let expiresAt: Date
    
    enum CodingKeys: String, CodingKey {
        case user, token
        case expiresAt = "expires_at"
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SignupRequest: Codable {
    let email: String
    let password: String
    let name: String
} 