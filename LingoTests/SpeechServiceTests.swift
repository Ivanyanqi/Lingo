import XCTest
@testable import Lingo

final class SpeechServiceTests: XCTestCase {

    // MARK: - 语言代码映射

    func test_langCode_zhEn_sourceIsZhCN() {
        XCTAssertEqual(SpeechService.ttsLangCode(langPair: "zh|en", speakSource: true), "zh-CN")
    }

    func test_langCode_zhEn_targetIsEn() {
        XCTAssertEqual(SpeechService.ttsLangCode(langPair: "zh|en", speakSource: false), "en-US")
    }

    func test_langCode_enZh_sourceIsEn() {
        XCTAssertEqual(SpeechService.ttsLangCode(langPair: "en|zh", speakSource: true), "en-US")
    }

    func test_langCode_enZh_targetIsZhCN() {
        XCTAssertEqual(SpeechService.ttsLangCode(langPair: "en|zh", speakSource: false), "zh-CN")
    }

    // MARK: - Voice matching

    func test_bestVoice_unknownLanguage_returnsNil() {
        XCTAssertNil(SpeechService.bestVoice(for: "zz-ZZ"))
    }

    func test_langCode_unknownLanguage_returnsRawCode() {
        XCTAssertEqual(SpeechService.ttsLangCode(langPair: "it|pl", speakSource: true), "it")
    }
}
