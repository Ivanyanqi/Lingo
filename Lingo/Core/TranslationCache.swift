import Foundation

/// 简单的 LRU 缓存，线程安全，用于避免相同文本重复请求翻译 API
final class TranslationCache {
    static let shared = TranslationCache()

    private struct CacheKey: Hashable {
        let text: String
        let langPair: String
    }

    private var cache: [CacheKey: String] = [:]
    private var order: [CacheKey] = []   // 最近使用排在末尾
    private let maxSize: Int
    private let lock = NSLock()

    init(maxSize: Int = 100) {
        self.maxSize = maxSize
    }

    func get(text: String, langPair: String) -> String? {
        let key = CacheKey(text: text, langPair: langPair)
        lock.lock()
        defer { lock.unlock() }
        guard let value = cache[key] else { return nil }
        // 移到末尾（最近使用）
        order.removeAll { $0 == key }
        order.append(key)
        return value
    }

    func set(text: String, langPair: String, result: String) {
        let key = CacheKey(text: text, langPair: langPair)
        lock.lock()
        defer { lock.unlock() }
        if cache[key] != nil {
            order.removeAll { $0 == key }
        } else if cache.count >= maxSize, let oldest = order.first {
            cache.removeValue(forKey: oldest)
            order.removeFirst()
        }
        cache[key] = result
        order.append(key)
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
        order.removeAll()
    }
}
