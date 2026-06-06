import CryptoKit
import Foundation

/// 单条翻译历史
struct HistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let sourceText: String
    let translatedText: String
    let langPair: String
    let date: Date
    var isFavorite: Bool

    init(sourceText: String, translatedText: String, langPair: String) {
        self.id = UUID()
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.langPair = langPair
        self.date = Date()
        self.isFavorite = false
    }

    /// 语言方向展示，如 "ZH → EN"
    var langBadge: String {
        let parts = langPair.split(separator: "|")
        let src = parts.first.map(String.init)?.uppercased() ?? "?"
        let tgt = parts.last.map(String.init)?.uppercased() ?? "?"
        return "\(src) → \(tgt)"
    }
}

/// 本地持久化翻译历史，最多保留 50 条
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()
    private static let legacyStorageKey = "translationHistory"
    private static let encryptionKeyKey = "historyEncryptionKey"

    @Published private(set) var entries: [HistoryEntry] = []

    private let maxCount = 50
    private let storageURL: URL
    private let userDefaults: UserDefaults
    private let secureStore: SecureStore

    init(
        storageURL: URL = HistoryStore.defaultStorageURL(),
        userDefaults: UserDefaults = .standard,
        secureStore: SecureStore = KeychainStore(service: "ivanqi.Lingo.history")
    ) {
        self.storageURL = storageURL
        self.userDefaults = userDefaults
        self.secureStore = secureStore
        load()
    }

    // MARK: - Public API

    @discardableResult
    func add(source: String, translated: String, langPair: String) -> UUID {
        // 去重：相同原文+语言对已存在则移到最前
        entries.removeAll { $0.sourceText == source && $0.langPair == langPair }
        let entry = HistoryEntry(sourceText: source, translatedText: translated, langPair: langPair)
        entries.insert(entry, at: 0)
        if entries.count > maxCount {
            entries = Array(entries.prefix(maxCount))
        }
        save()
        return entry.id
    }

    func toggleFavorite(id: UUID) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].isFavorite.toggle()
        save()
    }

    func delete(id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func clearAll() {
        entries.removeAll()
        save()
    }

    var favorites: [HistoryEntry] {
        entries.filter { $0.isFavorite }
    }

    // MARK: - CSV 导出

    func exportCSV() -> String {
        var lines = ["Source,Translation,Language,Date,Favorite"]
        let formatter = ISO8601DateFormatter()
        for e in entries {
            let src = e.sourceText.replacingOccurrences(of: "\"", with: "\"\"")
            let tgt = e.translatedText.replacingOccurrences(of: "\"", with: "\"\"")
            lines.append("\"\(src)\",\"\(tgt)\",\(e.langPair),\(formatter.string(from: e.date)),\(e.isFavorite)")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(entries),
              let encrypted = encrypt(data) else { return }
        let directory = storageURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? encrypted.write(to: storageURL, options: .atomic)
    }

    private func load() {
        if let data = try? Data(contentsOf: storageURL) {
            if let saved = decodeEncryptedEntries(from: data) {
                entries = saved
                return
            }

            if let saved = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
                entries = saved
                save()
                return
            }
        }

        guard let legacyData = userDefaults.data(forKey: Self.legacyStorageKey),
              let saved = try? JSONDecoder().decode([HistoryEntry].self, from: legacyData) else {
            return
        }
        entries = saved
        save()
        userDefaults.removeObject(forKey: Self.legacyStorageKey)
    }

    private func decodeEncryptedEntries(from data: Data) -> [HistoryEntry]? {
        guard let decrypted = decrypt(data),
              let saved = try? JSONDecoder().decode([HistoryEntry].self, from: decrypted) else {
            return nil
        }
        return saved
    }

    private func encrypt(_ data: Data) -> Data? {
        guard let key = historyKey(),
              let sealedBox = try? AES.GCM.seal(data, using: key),
              let combined = sealedBox.combined else {
            return nil
        }
        return combined
    }

    private func decrypt(_ data: Data) -> Data? {
        guard let key = historyKey(),
              let sealedBox = try? AES.GCM.SealedBox(combined: data),
              let decrypted = try? AES.GCM.open(sealedBox, using: key) else {
            return nil
        }
        return decrypted
    }

    private func historyKey() -> SymmetricKey? {
        if let stored = secureStore.string(forKey: Self.encryptionKeyKey),
           let keyData = Data(base64Encoded: stored) {
            return SymmetricKey(data: keyData)
        }

        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        guard secureStore.setString(keyData.base64EncodedString(), forKey: Self.encryptionKeyKey) else {
            return nil
        }
        return key
    }

    static func defaultStorageURL(fileManager: FileManager = .default) -> URL {
        let appSupport = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)
        return appSupport
            .appendingPathComponent("Lingo", isDirectory: true)
            .appendingPathComponent("history.json", isDirectory: false)
    }
}
