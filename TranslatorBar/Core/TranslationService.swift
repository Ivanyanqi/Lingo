import Foundation

enum TranslationError: Error, LocalizedError {
    case emptyResult
    case networkError(Error)
    case invalidResponse
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .emptyResult: return "未找到翻译结果"
        case .networkError: return "网络不可用，请检查连接"
        case .invalidResponse: return "服务器响应异常"
        case .rateLimited: return "今日翻译次数已用完"
        }
    }
}

protocol TranslationServiceProtocol {
    func translate(text: String, langPair: String?) async throws -> String
}

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
        // 用 URLComponents 构建 URL，避免手动编码导致的双重编码问题
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
        return text
    }
}
