import Foundation
import AVFoundation

final class SpeechService: NSObject {
    static let shared = SpeechService()
    private var audioPlayer: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()

    /// 语言代码映射：zh → zh-CN，其他保持原样
    static func ttsLangCode(langPair: String, speakSource: Bool) -> String {
        let parts = langPair.split(separator: "|").map(String.init)
        let lang = speakSource ? (parts.first ?? "en") : (parts.last ?? "zh")
        return lang == "zh" ? "zh-CN" : lang
    }

    /// 构建 Google TTS URL
    static func buildGoogleTTSURL(text: String, lang: String) -> URL? {
        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return nil }
        return URL(string: "https://translate.googleapis.com/translate_tts?ie=UTF-8&q=\(encoded)&tl=\(lang)&client=gtx")
    }

    /// 发音：优先 Google TTS，失败降级系统 TTS
    func speak(text: String, langPair: String, speakSource: Bool) {
        let lang = Self.ttsLangCode(langPair: langPair, speakSource: speakSource)
        guard let url = Self.buildGoogleTTSURL(text: text, lang: lang) else {
            fallbackSpeak(text: text, lang: lang)
            return
        }
        Task {
            do {
                var request = URLRequest(url: url, timeoutInterval: 5)
                request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
                let (data, _) = try await URLSession.shared.data(for: request)
                await MainActor.run {
                    self.audioPlayer = try? AVAudioPlayer(data: data)
                    self.audioPlayer?.play()
                }
            } catch {
                await MainActor.run { self.fallbackSpeak(text: text, lang: lang) }
            }
        }
    }

    private func fallbackSpeak(text: String, lang: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: lang)
        synthesizer.speak(utterance)
    }

    func stop() {
        audioPlayer?.stop()
        synthesizer.stopSpeaking(at: .immediate)
    }
}
