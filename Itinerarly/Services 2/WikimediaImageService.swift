import Foundation

// MARK: - Wikimedia Commons Image Provider
final class WikimediaImageService {
    static let shared = WikimediaImageService()
    private init() {}

    private let session = URLSession(configuration: .default)
    private var cache: [String: String] = [:]

    // Requête Wikimedia Commons pour obtenir une miniature de 800px
    // Docs: https://www.mediawiki.org/wiki/API:Search
    func fetchImageURL(for placeQuery: String, completion: @escaping (String?) -> Void) {
        let normalized = placeQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if let cached = cache[normalized] {
            completion(cached)
            return
        }

        var components = URLComponents(string: "https://commons.wikimedia.org/w/api.php")!
        components.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "prop", value: "pageimages"),
            URLQueryItem(name: "piprop", value: "thumbnail"),
            // Demander une miniature plus large pour garder un bon rendu en 16:9
            URLQueryItem(name: "pithumbsize", value: "1280"),
            URLQueryItem(name: "generator", value: "search"),
            URLQueryItem(name: "gsrsearch", value: normalized),
            URLQueryItem(name: "gsrlimit", value: "8"),
            URLQueryItem(name: "gsrnamespace", value: "6|0") // fichiers et pages
        ]

        guard let url = components.url else { completion(nil); return }

        session.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, error == nil, let data = data else {
                completion(nil)
                return
            }
            do {
                let decoded = try JSONDecoder().decode(WikimediaQueryResponse.self, from: data)
                guard let pages = decoded.query?.pages?.values, pages.isEmpty == false else {
                    completion(nil)
                    return
                }
                // Choisir la meilleure miniature selon des heuristiques (paysage, extérieur, panorama...)
                let best = pages.max(by: { [weak self] lhs, rhs in
                    guard let self = self else { return false }
                    return self.score(page: lhs) < self.score(page: rhs)
                })
                if let src = best?.thumbnail?.source {
                    self.cache[normalized] = src
                    completion(src)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }.resume()
    }

    private func score(page: WikimediaPage) -> Int {
        let title = (page.title ?? "").lowercased()
        let width = page.thumbnail?.width ?? 0
        let height = page.thumbnail?.height ?? 0
        var s = 0
        // Orientation paysage privilégiée
        if width >= height { s += 3 }
        // Mots-clés positifs
        let positives = [
            "façade","facade","exterior","extérieur","vue","panorama","place","square","pont","bridge",
            "harbor","port","basilique","basilica","cathédrale","cathedral","église","church","mosquée","mosque",
            "tour","tower","gate","porte","plaza","skyline","quai","quay","rive","promenade"
        ]
        for k in positives where title.contains(k) { s += 2 }
        // Mots-clés négatifs (éviter intérieurs et gros plans)
        let negatives = [
            "intérieur","interior","inside","detail","détail","close-up","statue","sculpture","plafond",
            "ceiling","vitrail","stained glass","crypt","chapel","choir"
        ]
        for k in negatives where title.contains(k) { s -= 3 }
        return s
    }
}

// MARK: - Models
private struct WikimediaQueryResponse: Decodable {
    let batchcomplete: String?
    let query: WikimediaQuery?
}

private struct WikimediaQuery: Decodable {
    let pages: [String: WikimediaPage]? // keys are pageid strings
}

private struct WikimediaPage: Decodable {
    let pageid: Int?
    let title: String?
    let thumbnail: WikimediaThumbnail?
}

private struct WikimediaThumbnail: Decodable {
    let source: String?
    let width: Int?
    let height: Int?
}

