import SwiftUI
import Combine

enum TranslationState {
    case idle
    case loading
    case success(String)
    case error(String)
}

@MainActor
final class TranslationViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var translationState: TranslationState = .idle
    @Published var langPair: String = "auto" // "auto" | "zh|en" | "en|zh"
    @Published var isTranslating: Bool = false

    private let translationService: TranslationServiceProtocol
    let speechService: SpeechService
    private var translateTask: Task<Void, Never>?

    init(
        translationService: TranslationServiceProtocol = TranslationService.shared,
        speechService: SpeechService = SpeechService.shared
    ) {
        self.translationService = translationService
        self.speechService = speechService
    }

    var effectiveLangPair: String {
        langPair == "auto" ? TranslationService.detectLangPair(inputText) : langPair
    }

    var translatedText: String? {
        if case .success(let text) = translationState { return text }
        return nil
    }

    var errorMessage: String? {
        if case .error(let msg) = translationState { return msg }
        return nil
    }

    func translate(text: String? = nil) {
        let query = text ?? inputText
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if let text { inputText = text }

        translateTask?.cancel()
        translateTask = Task {
            isTranslating = true
            translationState = .loading
            do {
                let result = try await translationService.translate(text: query, langPair: effectiveLangPair)
                guard !Task.isCancelled else { return }
                translationState = .success(result)
            } catch TranslationError.rateLimited {
                translationState = .error("今日翻译次数已用完")
            } catch TranslationError.emptyResult {
                translationState = .error("未找到翻译结果")
            } catch {
                translationState = .error("网络不可用，请检查连接")
            }
            isTranslating = false
        }
    }

    func speakSource() {
        guard !inputText.isEmpty else { return }
        speechService.speak(text: inputText, langPair: effectiveLangPair, speakSource: true)
    }

    func speakResult() {
        guard let text = translatedText else { return }
        speechService.speak(text: text, langPair: effectiveLangPair, speakSource: false)
    }

    func toggleLangPair() {
        switch langPair {
        case "zh|en": langPair = "en|zh"
        case "en|zh": langPair = "zh|en"
        default:
            let detected = TranslationService.detectLangPair(inputText)
            langPair = detected == "zh|en" ? "en|zh" : "zh|en"
        }
        if !inputText.isEmpty { translate() }
    }

    func clear() {
        translateTask?.cancel()
        inputText = ""
        translationState = .idle
        speechService.stop()
    }
}
