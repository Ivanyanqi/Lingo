import Foundation
import AVFoundation

/// 语音朗读服务
/// 始终使用系统 AVSpeechSynthesizer，避免将朗读文本发送到第三方服务。
final class SpeechService: NSObject {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()

    // MARK: - Language Code

    /// 将 langPair 转换为 BCP-47 语言代码
    static func ttsLangCode(langPair: String, speakSource: Bool) -> String {
        let parts = langPair.split(separator: "|").map(String.init)
        let lang = speakSource ? (parts.first ?? "en") : (parts.last ?? "zh")
        // 映射到完整 BCP-47 代码，提升系统 TTS 识别率
        let map: [String: String] = [
            "zh": "zh-CN",
            "en": "en-US",
            "ja": "ja-JP",
            "ko": "ko-KR",
            "fr": "fr-FR",
            "es": "es-ES",
            "de": "de-DE",
            "pt": "pt-BR",
            "ru": "ru-RU"
        ]
        return map[lang.lowercased()] ?? lang
    }

    // MARK: - Speak

    /// 朗读文字：优先精确匹配语言声音，找不到时退回同语言前缀或系统默认声音。
    func speak(text: String, langPair: String, speakSource: Bool) {
        stop()
        let lang = Self.ttsLangCode(langPair: langPair, speakSource: speakSource)
        systemSpeak(text: text, voice: Self.bestVoice(for: lang))
    }

    // MARK: - System TTS

    private func systemSpeak(text: String, voice: AVSpeechSynthesisVoice?) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    static func bestVoice(for language: String) -> AVSpeechSynthesisVoice? {
        if let exact = AVSpeechSynthesisVoice(language: language) {
            return exact
        }
        let prefix = language.split(separator: "-").first.map(String.init)?.lowercased() ?? language.lowercased()
        return AVSpeechSynthesisVoice.speechVoices().first {
            $0.language.lowercased() == prefix || $0.language.lowercased().hasPrefix("\(prefix)-")
        }
    }

    // MARK: - Stop

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
