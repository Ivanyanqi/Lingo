import Foundation

// MARK: - Error

enum TranslationError: Error, LocalizedError {
    case emptyResult
    case networkError(Error)
    case invalidResponse
    case rateLimited
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .emptyResult:    return "未找到翻译结果"
        case .networkError:   return "网络不可用，请检查连接"
        case .invalidResponse: return "服务器响应异常"
        case .rateLimited:    return "今日翻译次数已用完"
        case .missingAPIKey:  return "请先在设置中填写 API Key"
        }
    }
}

// MARK: - Protocol

protocol TranslationServiceProtocol {
    func translate(text: String, langPair: String?) async throws -> String
}

// MARK: - Engine

enum TranslationEngine: String, CaseIterable, Codable {
    case myMemory = "mymemory"
    case deepL    = "deepl"
    case openAI   = "openai"

    var displayName: String {
        switch self {
        case .myMemory: return "MyMemory（免费）"
        case .deepL:    return "DeepL"
        case .openAI:   return "OpenAI"
        }
    }

    var requiresAPIKey: Bool {
        self != .myMemory
    }

    private static let engineKey = "translationEngine"
    private static let deepLKeyKey = "deepLAPIKey"
    private static let openAIKeyKey = "openAIAPIKey"

    static func load() -> TranslationEngine {
        guard let raw = UserDefaults.standard.string(forKey: engineKey),
              let engine = TranslationEngine(rawValue: raw)
        else { return .myMemory }
        return engine
    }

    static func save(_ engine: TranslationEngine) {
        UserDefaults.standard.set(engine.rawValue, forKey: engineKey)
    }

    static var deepLAPIKey: String {
        get { UserDefaults.standard.string(forKey: deepLKeyKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: deepLKeyKey) }
    }

    static var openAIAPIKey: String {
        get { UserDefaults.standard.string(forKey: openAIKeyKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: openAIKeyKey) }
    }
}

// MARK: - MyMemory

final class TranslationService: TranslationServiceProtocol {
    static let shared = TranslationService()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// 语言检测：含中文字符 → zh|en，否则 → en|zh
    static func detectLangPair(_ text: String) -> String {
        let hasChinese = text.unicodeScalars.contains {
            $0.value >= 0x4e00 && $0.value <= 0x9fff
        }
        return hasChinese ? "zh|en" : "en|zh"
    }

    func translate(text: String, langPair: String? = nil) async throws -> String {
        let pair = langPair ?? Self.detectLangPair(text)
        var components = URLComponents(string: "https://api.mymemory.translated.net/get")!
        components.queryItems = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "langpair", value: pair)
        ]
        guard let url = components.url else { throw TranslationError.invalidResponse }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("Lingo/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw TranslationError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, http.statusCode == 429 {
            throw TranslationError.rateLimited
        }

        return try Self.parseResponse(data)
    }

    static func parseResponse(_ data: Data) throws -> String {
        struct Response: Decodable {
            struct ResponseData: Decodable { let translatedText: String }
            let responseData: ResponseData
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let text = decoded.responseData.translatedText
        guard !text.isEmpty else { throw TranslationError.emptyResult }
        // URL-decode 结果（MyMemory 有时返回 percent-encoded 字符串）
        return text.removingPercentEncoding ?? text
    }
}

// MARK: - DeepL

final class DeepLTranslationService: TranslationServiceProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func translate(text: String, langPair: String?) async throws -> String {
        let apiKey = TranslationEngine.deepLAPIKey
        guard !apiKey.isEmpty else { throw TranslationError.missingAPIKey }

        // DeepL Free API endpoint（付费用 api.deepl.com）
        let baseURL = apiKey.hasSuffix(":fx")
            ? "https://api-free.deepl.com/v2/translate"
            : "https://api.deepl.com/v2/translate"

        guard let url = URL(string: baseURL) else { throw TranslationError.invalidResponse }

        // 目标语言：从 langPair 取后半段，zh → ZH，en → EN
        let targetLang = langPair?.split(separator: "|").last.map(String.init)?.uppercased() ?? "EN"
        let deeplTarget = targetLang == "ZH" ? "ZH-HANS" : targetLang

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["text": [text], "target_lang": deeplTarget]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw TranslationError.networkError(error)
        }

        if let http = response as? HTTPURLResponse {
            if http.statusCode == 429 { throw TranslationError.rateLimited }
            if http.statusCode == 403 { throw TranslationError.missingAPIKey }
        }

        struct DeepLResponse: Decodable {
            struct Translation: Decodable { let text: String }
            let translations: [Translation]
        }
        let decoded = try JSONDecoder().decode(DeepLResponse.self, from: data)
        guard let result = decoded.translations.first?.text, !result.isEmpty else {
            throw TranslationError.emptyResult
        }
        return result
    }
}

// MARK: - OpenAI

final class OpenAITranslationService: TranslationServiceProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func translate(text: String, langPair: String?) async throws -> String {
        let apiKey = TranslationEngine.openAIAPIKey
        guard !apiKey.isEmpty else { throw TranslationError.missingAPIKey }

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw TranslationError.invalidResponse
        }

        let targetLangName: String
        if let pair = langPair {
            let parts = pair.split(separator: "|")
            let tgt = parts.last.map(String.init) ?? "en"
            targetLangName = languageName(for: tgt)
        } else {
            targetLangName = TranslationService.detectLangPair(text) == "zh|en" ? "English" : "Chinese"
        }

        let prompt = "Translate the following text to \(targetLangName). Output only the translation, no explanation:\n\n\(text)"

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": 500,
            "temperature": 0.3
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw TranslationError.networkError(error)
        }

        if let http = response as? HTTPURLResponse {
            if http.statusCode == 429 { throw TranslationError.rateLimited }
            if http.statusCode == 401 { throw TranslationError.missingAPIKey }
        }

        struct OpenAIResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }
        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let result = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines),
              !result.isEmpty else {
            throw TranslationError.emptyResult
        }
        return result
    }

    private func languageName(for code: String) -> String {
        let map = ["zh": "Chinese", "en": "English", "ja": "Japanese",
                   "ko": "Korean", "fr": "French", "es": "Spanish",
                   "de": "German", "pt": "Portuguese", "ru": "Russian"]
        return map[code.lowercased()] ?? code
    }
}

// MARK: - Factory

enum TranslationServiceFactory {
    static func make(engine: TranslationEngine = TranslationEngine.load()) -> TranslationServiceProtocol {
        switch engine {
        case .myMemory: return TranslationService.shared
        case .deepL:    return DeepLTranslationService()
        case .openAI:   return OpenAITranslationService()
        }
    }
}
