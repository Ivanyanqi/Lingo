import XCTest
@testable import Lingo

final class TranslationServiceTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = UUID().uuidString
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
        TranslationEngine.userDefaults = userDefaults
        TranslationEngine.secureStore = MemorySecureStore()
    }

    override func tearDown() {
        TranslationEngine.userDefaults = .standard
        TranslationEngine.secureStore = KeychainStore()
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - 语言检测

    func test_detectLanguage_chinese_returnsZhEn() {
        let result = TranslationService.detectLangPair("你好世界")
        XCTAssertEqual(result, "zh|en")
    }

    func test_detectLanguage_english_returnsEnZh() {
        let result = TranslationService.detectLangPair("Hello world")
        XCTAssertEqual(result, "en|zh")
    }

    func test_detectLanguage_mixed_returnsZhEn() {
        let result = TranslationService.detectLangPair("Hello 你好")
        XCTAssertEqual(result, "zh|en")
    }

    func test_detectLanguage_empty_returnsEnZh() {
        let result = TranslationService.detectLangPair("")
        XCTAssertEqual(result, "en|zh")
    }

    // MARK: - API 响应解析

    func test_parseResponse_validJSON_returnsTranslatedText() throws {
        let json = """
        {"responseData":{"translatedText":"Hello"},"responseStatus":200}
        """.data(using: .utf8)!
        let result = try TranslationService.parseResponse(json)
        XCTAssertEqual(result, "Hello")
    }

    func test_parseResponse_emptyText_throwsError() {
        let json = """
        {"responseData":{"translatedText":""},"responseStatus":200}
        """.data(using: .utf8)!
        XCTAssertThrowsError(try TranslationService.parseResponse(json)) { error in
            XCTAssertTrue(error is TranslationError)
        }
    }

    func test_parseResponse_invalidJSON_throwsError() {
        let json = "not json".data(using: .utf8)!
        XCTAssertThrowsError(try TranslationService.parseResponse(json))
    }

    // MARK: - Secure key storage

    func test_openAIKey_migratesLegacyUserDefaultsValueIntoSecureStore() {
        userDefaults.set("legacy-key", forKey: "openAIAPIKey")

        let result = TranslationEngine.openAIAPIKey

        XCTAssertEqual(result, "legacy-key")
        XCTAssertNil(userDefaults.string(forKey: "openAIAPIKey"))
        XCTAssertEqual(TranslationEngine.secureStore.string(forKey: "openAIAPIKey"), "legacy-key")
    }

    func test_deepLKey_emptyStringRemovesStoredSecret() {
        TranslationEngine.deepLAPIKey = "abc"
        TranslationEngine.deepLAPIKey = ""

        XCTAssertEqual(TranslationEngine.deepLAPIKey, "")
        XCTAssertNil(TranslationEngine.secureStore.string(forKey: "deepLAPIKey"))
    }

    @MainActor
    func test_translate_clearCancelsInFlightRequestWithoutShowingNetworkError() async throws {
        let defaultsSuite = UUID().uuidString
        guard let defaults = UserDefaults(suiteName: defaultsSuite) else {
            XCTFail("Expected isolated defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: defaultsSuite)

        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            defaults.removePersistentDomain(forName: defaultsSuite)
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let viewModel = TranslationViewModel(
            translationService: SlowTranslationService(),
            historyStore: HistoryStore(
                storageURL: tempDirectory.appendingPathComponent("history.json"),
                userDefaults: defaults
            ),
            cache: TranslationCache(maxSize: 5)
        )

        XCTAssertTrue(viewModel.networkMonitor.isConnected, "Cancellation path assumes network is reachable")

        viewModel.translate(text: "hello")
        viewModel.clear()
        try? await Task.sleep(nanoseconds: 80_000_000)

        XCTAssertFalse(viewModel.isTranslating)
        if case .idle = viewModel.translationState {
            return
        }
        XCTFail("Expected idle state after cancellation, got \(viewModel.translationState)")
    }

    @MainActor
    func test_translate_passedLongText_usesTrimmedInputForRequestAndHistory() async throws {
        let defaultsSuite = UUID().uuidString
        guard let defaults = UserDefaults(suiteName: defaultsSuite) else {
            XCTFail("Expected isolated defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: defaultsSuite)

        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            defaults.removePersistentDomain(forName: defaultsSuite)
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let service = RecordingTranslationService()
        let historyStore = HistoryStore(
            storageURL: tempDirectory.appendingPathComponent("history.json"),
            userDefaults: defaults
        )
        let viewModel = TranslationViewModel(
            translationService: service,
            historyStore: historyStore,
            cache: TranslationCache(maxSize: 5)
        )
        let longText = String(repeating: "a", count: 700)

        XCTAssertTrue(viewModel.networkMonitor.isConnected, "Request path assumes network is reachable")

        viewModel.translate(text: longText)
        try? await Task.sleep(nanoseconds: 80_000_000)

        XCTAssertEqual(viewModel.inputText.count, 500)
        XCTAssertEqual(service.recordedText, String(repeating: "a", count: 500))
        XCTAssertEqual(historyStore.entries.first?.sourceText.count, 500)
    }

    @MainActor
    func test_translate_cacheHit_setsCurrentEntryAndHistoryWithoutCallingService() throws {
        let defaultsSuite = UUID().uuidString
        guard let defaults = UserDefaults(suiteName: defaultsSuite) else {
            XCTFail("Expected isolated defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: defaultsSuite)

        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            defaults.removePersistentDomain(forName: defaultsSuite)
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let cache = TranslationCache(maxSize: 5)
        cache.set(text: "hello", langPair: "en|zh", result: "你好")

        let service = RecordingTranslationService()
        let historyStore = HistoryStore(
            storageURL: tempDirectory.appendingPathComponent("history.json"),
            userDefaults: defaults
        )
        let viewModel = TranslationViewModel(
            translationService: service,
            historyStore: historyStore,
            cache: cache
        )

        viewModel.translate(text: "hello")

        XCTAssertEqual(service.callCount, 0)
        XCTAssertEqual(historyStore.entries.first?.translatedText, "你好")
        XCTAssertEqual(historyStore.entries.first?.sourceText, "hello")
        XCTAssertEqual(viewModel.currentEntryID, historyStore.entries.first?.id)
    }
}

private final class MemorySecureStore: SecureStore {
    private var storage: [String: String] = [:]

    func string(forKey key: String) -> String? {
        storage[key]
    }

    @discardableResult
    func setString(_ value: String, forKey key: String) -> Bool {
        storage[key] = value
        return true
    }

    @discardableResult
    func removeValue(forKey key: String) -> Bool {
        storage.removeValue(forKey: key)
        return true
    }
}

private struct SlowTranslationService: TranslationServiceProtocol {
    func translate(text: String, langPair: String?) async throws -> String {
        try await Task.sleep(nanoseconds: 5_000_000_000)
        return "translated"
    }
}

@MainActor
private final class RecordingTranslationService: TranslationServiceProtocol {
    private(set) var recordedText: String?
    private(set) var callCount = 0

    func translate(text: String, langPair: String?) async throws -> String {
        callCount += 1
        recordedText = text
        return "translated"
    }
}
