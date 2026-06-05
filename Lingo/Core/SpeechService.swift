import Foundation
import AVFoundation

/// 语音朗读服务
/// 优先使用系统 AVSpeechSynthesizer（稳定、离线可用），
/// 系统 TTS 不支持该语言时降级到 Google TTS（需联网）。
final class SpeechService: NSObject {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var currentTask: Task<Void, Never>?

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

    /// 朗读文字：优先系统 TTS，不可用时降级 Google TTS
    func speak(text: String, langPair: String, speakSource: Bool) {
        stop()
        let lang = Self.ttsLangCode(langPair: langPair, speakSource: speakSource)

        // 检查系统是否有对应语言的声音
        if let voice = AVSpeechSynthesisVoice(language: lang) {
            systemSpeak(text: text, voice: voice)
        } else {
            // 降级：Google TTS（非官方接口，仅作备用）
            currentTask = Task { [weak self] in
                await self?.googleSpeak(text: text, lang: lang)
            }
        }
    }

    // MARK: - System TTS

    private func systemSpeak(text: String, voice: AVSpeechSynthesisVoice) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    // MARK: - Google TTS (fallback)

    private func googleSpeak(text: String, lang: String) async {
        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://translate.googleapis.com/translate_tts?ie=UTF-8&q=\(encoded)&tl=\(lang)&client=gtx")
        else {
            // 最终降级：用英语系统声音
            await MainActor.run {
                let utterance = AVSpeechUtterance(string: text)
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                self.synthesizer.speak(utterance)
            }
            return
        }

        do {
            var request = URLRequest(url: url, timeoutInterval: 5)
            request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: request)
            await MainActor.run {
                self.audioPlayer = try? AVAudioPlayer(data: data)
                self.audioPlayer?.play()
            }
        } catch {
            // 网络失败：最终降级到系统 TTS（无声音也不崩溃）
            await MainActor.run {
                let utterance = AVSpeechUtterance(string: text)
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                self.synthesizer.speak(utterance)
            }
        }
    }

    // MARK: - Stop

    func stop() {
        currentTask?.cancel()
        currentTask = nil
        audioPlayer?.stop()
        audioPlayer = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
