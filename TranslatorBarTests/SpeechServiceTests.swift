import XCTest
@testable import TranslatorBar

final class SpeechServiceTests: XCTestCase {

    // MARK: - 语言代码映射

    func test_langCode_zhEn_sourceIsZhCN() {
        XCTAssertEqual(SpeechService.ttsLangCode(langPair: "zh|en", speakSource: true), "zh-CN")
    }

    func test_langCode_zhEn_targetIsEn() {
        XCTAssertEqual(SpeechService.ttsLangCode(langPair: "zh|en", speakSource: false), "en")
    }

    func test_langCode_enZh_sourceIsEn() {
        XCTAssertEqual(SpeechService.ttsLangCode(langPair: "en|zh", speakSource: true), "en")
    }

    func test_langCode_enZh_targetIsZhCN() {
        XCTAssertEqual(SpeechService.ttsLangCode(langPair: "en|zh", speakSource: false), "zh-CN")
    }

    // MARK: - Google TTS URL 构建

    func test_buildTTSURL_validText_returnsURL() {
        let url = SpeechService.buildGoogleTTSURL(text: "Hello", lang: "en")
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("translate.googleapis.com"))
        XCTAssertTrue(url!.absoluteString.contains("Hello"))
        XCTAssertTrue(url!.absoluteString.contains("tl=en"))
    }

    func test_buildTTSURL_chineseText_encodesCorrectly() {
        let url = SpeechService.buildGoogleTTSURL(text: "你好", lang: "zh-CN")
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("translate.googleapis.com"))
    }
}
