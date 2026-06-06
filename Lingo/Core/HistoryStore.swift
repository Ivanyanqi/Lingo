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

    @Published private(set) var entries: [HistoryEntry] = []

    private let maxCount = 50
    private let storageURL: URL
    private let userDefaults: UserDefaults

    init(
        storageURL: URL = HistoryStore.defaultStorageURL(),
        userDefaults: UserDefaults = .standard
    ) {
        self.storageURL = storageURL
        self.userDefaults = userDefaults
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
        guard let data = try? JSONEncoder().encode(entries) else { return }
        let directory = storageURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: storageURL, options: .atomic)
    }

    private func load() {
        if let data = try? Data(contentsOf: storageURL),
           let saved = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            entries = saved
            return
        }

        guard let legacyData = userDefaults.data(forKey: Self.legacyStorageKey),
              let saved = try? JSONDecoder().decode([HistoryEntry].self, from: legacyData) else {
            return
        }
        entries = saved
        save()
        userDefaults.removeObject(forKey: Self.legacyStorageKey)
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
