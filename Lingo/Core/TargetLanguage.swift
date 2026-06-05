import Foundation

/// 支持的目标语言
enum TargetLanguage: String, CaseIterable, Codable {
    case chineseEnglish = "zh_en"   // 中英互译（默认）
    case japanese       = "ja"
    case korean         = "ko"
    case french         = "fr"
    case spanish        = "es"
    case german         = "de"
    case portuguese     = "pt"
    case russian        = "ru"

    var displayName: String {
        switch self {
        case .chineseEnglish: return "中文 ⇄ English"
        case .japanese:       return "日本語"
        case .korean:         return "한국어"
        case .french:         return "Français"
        case .spanish:        return "Español"
        case .german:         return "Deutsch"
        case .portuguese:     return "Português"
        case .russian:        return "Русский"
        }
    }

    var flag: String {
        switch self {
        case .chineseEnglish: return "🌐"
        case .japanese:       return "🇯🇵"
        case .korean:         return "🇰🇷"
        case .french:         return "🇫🇷"
        case .spanish:        return "🇪🇸"
        case .german:         return "🇩🇪"
        case .portuguese:     return "🇧🇷"
        case .russian:        return "🇷🇺"
        }
    }

    /// 根据输入文本自动决定 langPair（source|target）
    func langPair(for text: String) -> String {
        switch self {
        case .chineseEnglish:
            return TranslationService.detectLangPair(text)
        case .japanese:
            return TranslationService.isChineseOrEnglish(text) ? "auto|\(apiCode)" : "\(apiCode)|zh"
        default:
            // 其他语言：中文/英文 → 目标语言
            return "auto|\(apiCode)"
        }
    }

    /// MyMemory API 语言代码
    var apiCode: String {
        switch self {
        case .chineseEnglish: return "en"   // 不直接用，由 langPair 决定
        case .japanese:       return "ja"
        case .korean:         return "ko"
        case .french:         return "fr"
        case .spanish:        return "es"
        case .german:         return "de"
        case .portuguese:     return "pt"
        case .russian:        return "ru"
        }
    }

    // MARK: - Persistence

    private static let storageKey = "targetLanguage"

    static func load() -> TargetLanguage {
        guard let raw = UserDefaults.standard.string(forKey: storageKey),
              let lang = TargetLanguage(rawValue: raw)
        else { return .chineseEnglish }
        return lang
    }

    static func save(_ lang: TargetLanguage) {
        UserDefaults.standard.set(lang.rawValue, forKey: storageKey)
    }
}

extension TranslationService {
    /// 判断文本是否为中文或英文（用于多语言方向判断）
    static func isChineseOrEnglish(_ text: String) -> Bool {
        let hasChinese = text.unicodeScalars.contains {
            $0.value >= 0x4e00 && $0.value <= 0x9fff
        }
        if hasChinese { return true }
        let hasNonLatin = text.unicodeScalars.contains {
            $0.value > 0x024F && !($0.value >= 0x4e00 && $0.value <= 0x9fff)
        }
        return !hasNonLatin
    }
}
