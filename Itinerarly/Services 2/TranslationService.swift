import Foundation

enum TranslationError: Error {
    case unsupportedLanguage
    case emptyText
    case network
    case decode
}

final class TranslationService {
    static let shared = TranslationService()
    static let didUpdateNotification = Notification.Name("TranslationService.didUpdate")
    
    struct UpdateInfo {
        let originalText: String
        let translatedText: String
        let targetLanguage: String
        let sourceLanguage: String
    }
    
    // Simple in-memory cache to speed up repeated requests
    private var cache: [String: String] = [:]
    private let diskURL: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("translations-cache.json")
    }()
    private let lock = NSLock()
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 6
        config.timeoutIntervalForResource = 8
        session = URLSession(configuration: config)
        loadCacheFromDisk()
    }
    
    // Map AppLanguage (or raw ISO code) to provider codes
    private func providerCode(for code: String, provider: Provider) -> String? {
        // Normalize incoming codes
        let normalized = code.lowercased()
        switch provider {
        case .myMemory:
            // MyMemory expects two-letter codes (ISO-639-1) mostly
            if normalized.hasPrefix("zh") { return "zh" }
            if normalized.count >= 2 { return String(normalized.prefix(2)) }
            return nil
        case .libreTranslate:
            // LibreTranslate uses zh for Chinese, en, fr, de, es, ar
            if normalized.hasPrefix("zh") { return "zh" }
            if normalized.count >= 2 { return String(normalized.prefix(2)) }
            return nil
        }
    }
    
    enum Provider { case myMemory, libreTranslate }
    
    func translate(text: String, from source: String, to target: String) async throws -> String {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { throw TranslationError.emptyText }
        if source.lowercased().hasPrefix(target.lowercased()) { return text }
        
        let cacheKey = "\(source.lowercased())|\(target.lowercased())|\(text)"
        if let cached = cached(for: cacheKey) { return cached }
        
        // Race both providers, return the first successful
        if let translated = try? await translateRace(text: text, from: source, to: target) {
            store(translated, for: cacheKey)
            return translated
        }
        throw TranslationError.network
    }

    // Instant return: immediate (cached or original) + background fetch to fill cache, then a notification is posted
    func translateInstant(text: String, from source: String, to target: String) -> String {
        print("🔍 TranslationService.translateInstant: '\(text)' from \(source) to \(target)")
        
        let key = "\(source.lowercased())|\(target.lowercased())|\(text)"
        if let cached = cached(for: key) { 
            print("✅ Found in cache: \(cached)")
            return cached 
        }
        
        print("❌ Not in cache, starting background fetch...")
        
        // Kick off background fetch
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            if let translated = try? await self.translate(text: text, from: source, to: target) {
                self.store(translated, for: key)
                self.saveCacheToDisk()
                let info = UpdateInfo(
                    originalText: text,
                    translatedText: translated,
                    targetLanguage: target,
                    sourceLanguage: source
                )
                NotificationCenter.default.post(
                    name: TranslationService.didUpdateNotification,
                    object: info,
                    userInfo: nil
                )
            }
        }
        return text // immediate fallback (instant)
    }

    // Batch warmup to pre-translate common strings
    func warmup(strings: [String], from source: String, to target: String) {
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            for s in strings where !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                _ = self.translateInstant(text: s, from: source, to: target)
            }
        }
    }
    
    private func translateMyMemory(text: String, from source: String, to target: String) async throws -> String {
        guard let src = providerCode(for: source, provider: .myMemory),
              let tgt = providerCode(for: target, provider: .myMemory) else { throw TranslationError.unsupportedLanguage }
        
        var comps = URLComponents(string: "https://api.mymemory.translated.net/get")!
        comps.queryItems = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "langpair", value: "\(src)|\(tgt)")
        ]
        let url = comps.url!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw TranslationError.network }
        
        struct MyMemoryResponse: Decodable { struct DataObj: Decodable { let translatedText: String }
            let responseData: DataObj
        }
        guard let obj = try? JSONDecoder().decode(MyMemoryResponse.self, from: data) else { throw TranslationError.decode }
        return obj.responseData.translatedText
    }
    
    private func translateLibre(text: String, from source: String, to target: String) async throws -> String {
        guard let src = providerCode(for: source, provider: .libreTranslate),
              let tgt = providerCode(for: target, provider: .libreTranslate) else { throw TranslationError.unsupportedLanguage }
        
        // Use a reliable public instance (rate limits may apply). You can self-host LibreTranslate to remove limits.
        let url = URL(string: "https://libretranslate.de/translate")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let body = "q=\(urlEncode(text))&source=\(src)&target=\(tgt)&format=text"
        req.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw TranslationError.network }
        
        struct LibreResp: Decodable { let translatedText: String }
        guard let obj = try? JSONDecoder().decode(LibreResp.self, from: data) else { throw TranslationError.decode }
        return obj.translatedText
    }

    // Race both providers to minimize latency
    private func translateRace(text: String, from source: String, to target: String) async throws -> String {
        try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask { [self] in try await translateMyMemory(text: text, from: source, to: target) }
            group.addTask { [self] in try await translateLibre(text: text, from: source, to: target) }
            defer { group.cancelAll() }
            for try await result in group { return result }
            throw TranslationError.network
        }
    }
    
    private func urlEncode(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
    }
    
    private func cached(for key: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        return cache[key]
    }
    
    private func store(_ value: String, for key: String) {
        lock.lock(); defer { lock.unlock() }
        cache[key] = value
    }

    private func loadCacheFromDisk() {
        guard let data = try? Data(contentsOf: diskURL) else { return }
        if let dict = try? JSONDecoder().decode([String:String].self, from: data) {
            cache = dict
        }
    }
    private func saveCacheToDisk() {
        lock.lock(); let dict = cache; lock.unlock()
        if let data = try? JSONEncoder().encode(dict) {
            try? data.write(to: diskURL, options: .atomic)
        }
    }
}

