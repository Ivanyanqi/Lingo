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
    @Published var targetLang: TargetLanguage = TargetLanguage.load()
    @Published var isTranslating: Bool = false
    @Published var menuBarPreview: String? = nil  // 菜单栏短暂预览文字

    // 固定翻译方向（nil = 自动检测）
    @Published var forcedLangPair: String? = nil

    private let translationService: TranslationServiceProtocol
    let speechService: SpeechService
    private let historyStore: HistoryStore
    private let cache: TranslationCache

    private var translateTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?

    init(
        translationService: TranslationServiceProtocol = TranslationService.shared,
        speechService: SpeechService = SpeechService.shared,
        historyStore: HistoryStore = .shared,
        cache: TranslationCache = .shared
    ) {
        self.translationService = translationService
        self.speechService = speechService
        self.historyStore = historyStore
        self.cache = cache
    }

    // MARK: - Computed

    var effectiveLangPair: String {
        if let forced = forcedLangPair { return forced }
        return targetLang.langPair(for: inputText)
    }

    var translatedText: String? {
        if case .success(let text) = translationState { return text }
        return nil
    }

    var errorMessage: String? {
        if case .error(let msg) = translationState { return msg }
        return nil
    }

    // MARK: - Translation (with debounce + cache)

    /// 带防抖的翻译入口（面板输入时使用）
    func translateDebounced() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000) // 400ms
            guard !Task.isCancelled else { return }
            translate()
        }
    }

    /// 立即翻译（快捷键触发时使用）
    func translate(text: String? = nil) {
        let query = text ?? inputText
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if let text { inputText = text }

        let pair = effectiveLangPair

        // 命中缓存直接返回
        if let cached = cache.get(text: query, langPair: pair) {
            translationState = .success(cached)
            showMenuBarPreview(cached)
            return
        }

        translateTask?.cancel()
        translateTask = Task {
            isTranslating = true
            translationState = .loading
            do {
                let result = try await translationService.translate(text: query, langPair: pair)
                guard !Task.isCancelled else { return }
                translationState = .success(result)
                cache.set(text: query, langPair: pair, result: result)
                historyStore.add(source: query, translated: result, langPair: pair)
                showMenuBarPreview(result)
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

    // MARK: - Language

    func toggleLangPair() {
        let current = effectiveLangPair
        forcedLangPair = current == "zh|en" ? "en|zh" : "zh|en"
        if !inputText.isEmpty { translate() }
    }

    func setTargetLanguage(_ lang: TargetLanguage) {
        targetLang = lang
        forcedLangPair = nil
        TargetLanguage.save(lang)
        if !inputText.isEmpty { translate() }
    }

    // MARK: - Speech

    func speakSource() {
        guard !inputText.isEmpty else { return }
        speechService.speak(text: inputText, langPair: effectiveLangPair, speakSource: true)
    }

    func speakResult() {
        guard let text = translatedText else { return }
        speechService.speak(text: text, langPair: effectiveLangPair, speakSource: false)
    }

    // MARK: - Clear

    func clear() {
        debounceTask?.cancel()
        translateTask?.cancel()
        inputText = ""
        translationState = .idle
        forcedLangPair = nil
        speechService.stop()
    }

    // MARK: - Menu bar preview

    private func showMenuBarPreview(_ text: String) {
        let preview = String(text.prefix(12))
        menuBarPreview = preview
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.menuBarPreview = nil
        }
    }
}
