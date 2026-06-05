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
    @Published var inputText: String = "" {
        didSet {
            // 强制执行 500 字符上限
            if inputText.count > 500 {
                inputText = String(inputText.prefix(500))
            }
        }
    }
    @Published var translationState: TranslationState = .idle
    @Published var targetLang: TargetLanguage = TargetLanguage.load()
    @Published var isTranslating: Bool = false
    @Published var menuBarPreview: String? = nil  // 菜单栏短暂预览文字
    @Published var currentEntryID: UUID? = nil    // 当前翻译对应的历史条目 ID

    // 固定翻译方向（nil = 自动检测）
    @Published var forcedLangPair: String? = nil

    // 当前翻译引擎（响应式，切换后立即生效）
    @Published var currentEngine: TranslationEngine = TranslationEngine.load() {
        didSet {
            guard oldValue != currentEngine else { return }
            TranslationEngine.save(currentEngine)
            // 动态切换 service 实例
            translationService = TranslationServiceFactory.make(engine: currentEngine)
            // 清空缓存，避免旧引擎结果污染新引擎
            cache.clear()
            // 如果当前有输入，用新引擎重新翻译
            if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                translate()
            }
        }
    }

    private var translationService: TranslationServiceProtocol
    let speechService: SpeechService
    private let historyStore: HistoryStore
    private let cache: TranslationCache
    let networkMonitor: NetworkMonitor = .shared

    private var translateTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?

    init(
        translationService: TranslationServiceProtocol? = nil,
        speechService: SpeechService = SpeechService.shared,
        historyStore: HistoryStore = .shared,
        cache: TranslationCache = .shared
    ) {
        let engine = TranslationEngine.load()
        self.translationService = translationService ?? TranslationServiceFactory.make(engine: engine)
        self.currentEngine = engine
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

        // 命中缓存直接返回（无需网络）
        if let cached = cache.get(text: query, langPair: pair) {
            translationState = .success(cached)
            showMenuBarPreview(cached)
            return
        }

        // 无网络时提前报错，避免等待超时
        guard networkMonitor.isConnected else {
            translationState = .error("网络不可用，请检查连接")
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
                let entryID = historyStore.add(source: query, translated: result, langPair: pair)
                currentEntryID = entryID
                showMenuBarPreview(result)
            } catch TranslationError.rateLimited {
                translationState = .error("今日翻译次数已用完")
            } catch TranslationError.emptyResult {
                translationState = .error("未找到翻译结果")
            } catch TranslationError.missingAPIKey {
                translationState = .error("请先在设置中填写 API Key")
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
        currentEntryID = nil
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
