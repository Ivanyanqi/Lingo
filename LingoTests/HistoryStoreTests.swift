import XCTest
@testable import Lingo

final class HistoryStoreTests: XCTestCase {
    private var tempDirectory: URL!
    private var defaults: UserDefaults!
    private var defaultsSuiteName: String!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defaultsSuiteName = UUID().uuidString
        defaults = UserDefaults(suiteName: defaultsSuiteName)
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
        try super.tearDownWithError()
    }

    func test_add_persistsEntriesToFileAndReloads() {
        let storageURL = tempDirectory.appendingPathComponent("history.json")
        let store = HistoryStore(storageURL: storageURL, userDefaults: defaults)

        store.add(source: "hello", translated: "你好", langPair: "en|zh")

        let reloaded = HistoryStore(storageURL: storageURL, userDefaults: defaults)
        XCTAssertEqual(reloaded.entries.count, 1)
        XCTAssertEqual(reloaded.entries.first?.sourceText, "hello")
        XCTAssertEqual(reloaded.entries.first?.translatedText, "你好")
    }

    func test_load_migratesLegacyUserDefaultsDataToFile() throws {
        let legacyEntry = HistoryEntry(sourceText: "hello", translatedText: "bonjour", langPair: "en|fr")
        let data = try JSONEncoder().encode([legacyEntry])
        defaults.set(data, forKey: "translationHistory")
        let storageURL = tempDirectory.appendingPathComponent("history.json")

        let store = HistoryStore(storageURL: storageURL, userDefaults: defaults)

        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries.first?.translatedText, "bonjour")
        XCTAssertNil(defaults.data(forKey: "translationHistory"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: storageURL.path))
    }
}
