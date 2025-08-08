import Foundation
import Combine

class APIService {
    static let shared = APIService()
    
    private let baseURL = "" // DEMO MODE - PAS D'APPELS RÉSEAU
    private var authToken: String?
    private let session = URLSession.shared
    private let decoder: JSONDecoder
    
    private init() {
        decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        decoder.dateDecodingStrategy = .formatted(formatter)
    }
    
    func setAuthToken(_ token: String) {
        authToken = token
    }
    
    func clearAuthToken() {
        authToken = nil
    }
    
    // MARK: - Authentication
    func login(request: LoginRequest) -> AnyPublisher<AuthResponse, Error> {
        // MOCK DATA pour la démo - PAS D'APPEL RÉSEAU
        let mockUser = User(
            id: "demo_user_123",
            email: request.email,
            name: "Utilisateur Demo",
            createdAt: Date()
        )
        
        let mockResponse = AuthResponse(
            user: mockUser,
            token: "demo_token_12345",
            expiresAt: Date().addingTimeInterval(3600)
        )
        
        // Simule un délai réseau
        return Just(mockResponse)
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func signup(request: SignupRequest) -> AnyPublisher<AuthResponse, Error> {
        // MOCK DATA pour la démo - PAS D'APPEL RÉSEAU
        let mockUser = User(
            id: "demo_user_\(UUID().uuidString.prefix(8))",
            email: request.email,
            name: request.name,
            createdAt: Date()
        )
        
        let mockResponse = AuthResponse(
            user: mockUser,
            token: "demo_token_\(UUID().uuidString.prefix(8))",
            expiresAt: Date().addingTimeInterval(3600)
        )
        
        // Simule un délai réseau
        return Just(mockResponse)
            .delay(for: .seconds(1.5), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Day Trip Planning
    func planTrip(request: TripPlanRequest) -> AnyPublisher<DayTrip, Error> {
        return makeRequest(
            endpoint: "/trips/plan",
            method: "POST",
            body: request
        )
    }
    
    func getUserTrips() -> AnyPublisher<[DayTrip], Error> {
        return makeRequest(
            endpoint: "/trips/user",
            method: "GET"
        )
    }
    
    // MARK: - Guided Tours
    func getToursForCity(_ city: City) -> AnyPublisher<[GuidedTour], Error> {
        return makeRequest(
            endpoint: "/tours/city/\(city.rawValue)",
            method: "GET"
        )
    }
    
    func getTourDetails(tourId: String) -> AnyPublisher<GuidedTour, Error> {
        return makeRequest(
            endpoint: "/tours/\(tourId)",
            method: "GET"
        )
    }
    
    func generateAudioGuide(text: String) -> AnyPublisher<Data, Error> {
        return makeRequest(
            endpoint: "/audio/generate",
            method: "POST",
            body: ["text": text],
            responseType: Data.self
        )
    }
    
    // MARK: - Beat Boredom
    func getActivitySuggestions(filter: ActivityFilter, userLocation: CLLocation) -> AnyPublisher<[ActivitySuggestion], Error> {
        let requestBody: [String: Any] = [
            "category": filter.category?.rawValue ?? "",
            "max_distance": filter.maxDistance,
            "transport_mode": filter.transportMode.rawValue,
            "available_time": filter.availableTime,
            "user_latitude": userLocation.coordinate.latitude,
            "user_longitude": userLocation.coordinate.longitude,
            "time_slot": filter.timeSlot != nil ? [
                "start_time": filter.timeSlot!.startTime.timeIntervalSince1970,
                "end_time": filter.timeSlot!.endTime.timeIntervalSince1970
            ] : nil
        ]
        
        return makeRequest(
            endpoint: "/activities/suggestions",
            method: "POST",
            body: requestBody
        )
    }
    
    // MARK: - Adventurer Mode
    func generateAdventure(request: AdventureRequest) -> AnyPublisher<Adventure, Error> {
        return makeRequest(
            endpoint: "/adventures/generate",
            method: "POST",
            body: request
        )
    }
    
    func getUserAdventures() -> AnyPublisher<[Adventure], Error> {
        return makeRequest(
            endpoint: "/adventures/user",
            method: "GET"
        )
    }
    
    // MARK: - Locations
    func searchLocations(query: String, near: CLLocation?) -> AnyPublisher<[Location], Error> {
        var params: [String: String] = ["q": query]
        if let location = near {
            params["lat"] = "\(location.coordinate.latitude)"
            params["lng"] = "\(location.coordinate.longitude)"
        }
        
        return makeRequest(
            endpoint: "/locations/search",
            method: "GET",
            queryParams: params
        )
    }
    
    // MARK: - Private Helpers
    private func makeRequest<T: Codable, R: Codable>(
        endpoint: String,
        method: String,
        body: T? = nil,
        queryParams: [String: String]? = nil,
        requiresAuth: Bool = true,
        responseType: R.Type = R.self
    ) -> AnyPublisher<R, Error> {
        
        guard let url = buildURL(endpoint: endpoint, queryParams: queryParams) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: R.self, decoder: decoder)
            .mapError { error in
                if error is DecodingError {
                    return APIError.decodingError
                }
                return error
            }
            .eraseToAnyPublisher()
    }
    
    private func makeRequest<R: Codable>(
        endpoint: String,
        method: String,
        body: [String: Any]? = nil,
        queryParams: [String: String]? = nil,
        requiresAuth: Bool = true,
        responseType: R.Type = R.self
    ) -> AnyPublisher<R, Error> {
        
        // MODE DÉMO - Simulation de réponses selon l'endpoint
        return createMockResponse(for: endpoint, responseType: responseType)
            .delay(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func createMockResponse<R: Codable>(for endpoint: String, responseType: R.Type) -> AnyPublisher<R, Error> {
        // Simule des réponses vides ou par défaut selon le type
        if R.self == [DayTrip].self {
            return Just([] as! R).setFailureType(to: Error.self).eraseToAnyPublisher()
        } else if R.self == [GuidedTour].self {
            return Just([] as! R).setFailureType(to: Error.self).eraseToAnyPublisher()
        } else if R.self == [ActivitySuggestion].self {
            return Just([] as! R).setFailureType(to: Error.self).eraseToAnyPublisher()
        } else if R.self == [Adventure].self {
            return Just([] as! R).setFailureType(to: Error.self).eraseToAnyPublisher()
        } else {
            // Pour les autres types, retourne une erreur douce
            return Fail(error: APIError.networkError)
                .eraseToAnyPublisher()
        }
    }
    
    private func buildURL(endpoint: String, queryParams: [String: String]? = nil) -> URL? {
        guard var components = URLComponents(string: baseURL + endpoint) else {
            return nil
        }
        
        if let queryParams = queryParams {
            components.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        return components.url
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case decodingError
    case networkError
    case unauthorized
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network error"
        case .unauthorized:
            return "Unauthorized"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

import CoreLocation 