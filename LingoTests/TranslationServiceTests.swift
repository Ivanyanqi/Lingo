import XCTest
@testable import Lingo

final class TranslationServiceTests: XCTestCase {

    // MARK: - 语言检测

    func test_detectLanguage_chinese_returnsZhEn() {
        let result = TranslationService.detectLangPair("你好世界")
        XCTAssertEqual(result, "zh|en")
    }

    func test_detectLanguage_english_returnsEnZh() {
        let result = TranslationService.detectLangPair("Hello world")
        XCTAssertEqual(result, "en|zh")
    }

    func test_detectLanguage_mixed_returnsZhEn() {
        let result = TranslationService.detectLangPair("Hello 你好")
        XCTAssertEqual(result, "zh|en")
    }

    func test_detectLanguage_empty_returnsEnZh() {
        let result = TranslationService.detectLangPair("")
        XCTAssertEqual(result, "en|zh")
    }

    // MARK: - API 响应解析

    func test_parseResponse_validJSON_returnsTranslatedText() throws {
        let json = """
        {"responseData":{"translatedText":"Hello"},"responseStatus":200}
        """.data(using: .utf8)!
        let result = try TranslationService.parseResponse(json)
        XCTAssertEqual(result, "Hello")
    }

    func test_parseResponse_emptyText_throwsError() {
        let json = """
        {"responseData":{"translatedText":""},"responseStatus":200}
        """.data(using: .utf8)!
        XCTAssertThrowsError(try TranslationService.parseResponse(json)) { error in
            XCTAssertTrue(error is TranslationError)
        }
    }

    func test_parseResponse_invalidJSON_throwsError() {
        let json = "not json".data(using: .utf8)!
        XCTAssertThrowsError(try TranslationService.parseResponse(json))
    }
}
