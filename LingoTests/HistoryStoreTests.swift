import XCTest
@testable import Lingo

final class HistoryStoreTests: XCTestCase {
    private var tempDirectory: URL!
    private var defaults: UserDefaults!
    private var defaultsSuiteName: String!
    private var secureStore: MemorySecureStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defaultsSuiteName = UUID().uuidString
        defaults = UserDefaults(suiteName: defaultsSuiteName)
        secureStore = MemorySecureStore()
    }

    override func tearDownWithError() throws {
        if let defaults, let defaultsSuiteName {
            defaults.removePersistentDomain(forName: defaultsSuiteName)
        }
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
        defaults = nil
        defaultsSuiteName = nil
        secureStore = nil
        try super.tearDownWithError()
    }

    func test_add_persistsEncryptedEntriesToFileAndReloads() throws {
        let storageURL = tempDirectory.appendingPathComponent("history.json")
        let store = HistoryStore(storageURL: storageURL, userDefaults: defaults, secureStore: secureStore)

        store.add(source: "hello", translated: "你好", langPair: "en|zh")

        let rawData = try Data(contentsOf: storageURL)
        XCTAssertFalse(String(decoding: rawData, as: UTF8.self).contains("hello"))

        let reloaded = HistoryStore(storageURL: storageURL, userDefaults: defaults, secureStore: secureStore)
        XCTAssertEqual(reloaded.entries.count, 1)
        XCTAssertEqual(reloaded.entries.first?.sourceText, "hello")
        XCTAssertEqual(reloaded.entries.first?.translatedText, "你好")
    }

    func test_load_migratesLegacyUserDefaultsDataToFile() throws {
        let legacyEntry = HistoryEntry(sourceText: "hello", translatedText: "bonjour", langPair: "en|fr")
        let data = try JSONEncoder().encode([legacyEntry])
        defaults.set(data, forKey: "translationHistory")
        let storageURL = tempDirectory.appendingPathComponent("history.json")

        let store = HistoryStore(storageURL: storageURL, userDefaults: defaults, secureStore: secureStore)

        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries.first?.translatedText, "bonjour")
        XCTAssertNil(defaults.data(forKey: "translationHistory"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: storageURL.path))
        XCTAssertFalse(String(decoding: try Data(contentsOf: storageURL), as: UTF8.self).contains("bonjour"))
    }

    func test_load_migratesLegacyPlaintextFileToEncryptedData() throws {
        let legacyEntry = HistoryEntry(sourceText: "plain", translatedText: "cipher", langPair: "en|zh")
        let storageURL = tempDirectory.appendingPathComponent("history.json")
        try JSONEncoder().encode([legacyEntry]).write(to: storageURL, options: .atomic)

        let store = HistoryStore(storageURL: storageURL, userDefaults: defaults, secureStore: secureStore)

        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries.first?.sourceText, "plain")
        XCTAssertFalse(String(decoding: try Data(contentsOf: storageURL), as: UTF8.self).contains("plain"))
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
