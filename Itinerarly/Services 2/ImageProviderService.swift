import Foundation

// MARK: - Image Provider using Pixabay API (CC0-like Pixabay License)
final class ImageProviderService {
    static let shared = ImageProviderService()
    private init() {}

    private let session = URLSession(configuration: .default)
    private var inMemoryCache: [String: String] = [:]

    private var apiKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "PIXABAY_API_KEY") as? String
    }

    func fetchImageURL(for query: String, completion: @escaping (String?) -> Void) {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if let cached = inMemoryCache[normalized] {
            completion(cached)
            return
        }

        guard let apiKey = apiKey, apiKey.isEmpty == false else {
            completion(nil)
            return
        }

        var components = URLComponents(string: "https://pixabay.com/api/")!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "q", value: normalized),
            URLQueryItem(name: "image_type", value: "photo"),
            URLQueryItem(name: "orientation", value: "horizontal"),
            URLQueryItem(name: "category", value: "places"),
            URLQueryItem(name: "safesearch", value: "true"),
            URLQueryItem(name: "per_page", value: "3"),
            URLQueryItem(name: "order", value: "popular")
        ]

        guard let url = components.url else {
            completion(nil)
            return
        }

        session.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, error == nil, let data = data else {
                completion(nil)
                return
            }
            do {
                let result = try JSONDecoder().decode(PixabayResponse.self, from: data)
                // Prefer largeImageURL, fallback to webformatURL
                let imageURL = result.hits.first?.largeImageURL ?? result.hits.first?.webformatURL
                if let imageURL = imageURL {
                    self.inMemoryCache[normalized] = imageURL
                }
                completion(imageURL)
            } catch {
                completion(nil)
            }
        }.resume()
    }
}

// MARK: - Models
private struct PixabayResponse: Decodable {
    let total: Int
    let totalHits: Int
    let hits: [PixabayHit]
}

private struct PixabayHit: Decodable {
    let webformatURL: String?
    let largeImageURL: String?
}

