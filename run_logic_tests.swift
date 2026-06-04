#!/usr/bin/swift
// 验证核心逻辑（不依赖 AppKit/SwiftUI）

import Foundation
import CoreGraphics

var passed = 0
var failed = 0

func assert_eq<T: Equatable>(_ a: T, _ b: T, _ name: String) {
    if a == b {
        print("  ✅ \(name)")
        passed += 1
    } else {
        print("  ❌ \(name): expected \(b), got \(a)")
        failed += 1
    }
}

func assert_throws(_ name: String, block: () throws -> Void) {
    do {
        try block()
        print("  ❌ \(name): expected throw but didn't")
        failed += 1
    } catch {
        print("  ✅ \(name)")
        passed += 1
    }
}

// ── TranslationService 语言检测 ───────────────────────────────────────────────
print("\n[TranslationService] 语言检测")

func detectLangPair(_ text: String) -> String {
    let hasChinese = text.unicodeScalars.contains { $0.value >= 0x4e00 && $0.value <= 0x9fff }
    return hasChinese ? "zh|en" : "en|zh"
}

assert_eq(detectLangPair("你好世界"), "zh|en", "中文 → zh|en")
assert_eq(detectLangPair("Hello world"), "en|zh", "英文 → en|zh")
assert_eq(detectLangPair("Hello 你好"), "zh|en", "混合含中文 → zh|en")
assert_eq(detectLangPair(""), "en|zh", "空字符串 → en|zh")

// ── TranslationService API 响应解析 ──────────────────────────────────────────
print("\n[TranslationService] API 响应解析")

struct Response: Decodable {
    struct ResponseData: Decodable { let translatedText: String }
    let responseData: ResponseData
}

func parseResponse(_ data: Data) throws -> String {
    let decoded = try JSONDecoder().decode(Response.self, from: data)
    let text = decoded.responseData.translatedText
    guard !text.isEmpty else { throw NSError(domain: "empty", code: 0) }
    return text
}

let validJSON = #"{"responseData":{"translatedText":"Hello"},"responseStatus":200}"#.data(using: .utf8)!
let emptyJSON = #"{"responseData":{"translatedText":""},"responseStatus":200}"#.data(using: .utf8)!
let badJSON = "not json".data(using: .utf8)!

if let result = try? parseResponse(validJSON) {
    assert_eq(result, "Hello", "有效 JSON 解析")
} else {
    print("  ❌ 有效 JSON 解析: 解析失败")
    failed += 1
}
assert_throws("空结果抛出错误") { _ = try parseResponse(emptyJSON) }
assert_throws("无效 JSON 抛出错误") { _ = try parseResponse(badJSON) }

// ── SpeechService 语言代码映射 ────────────────────────────────────────────────
print("\n[SpeechService] 语言代码映射")

func ttsLangCode(langPair: String, speakSource: Bool) -> String {
    let parts = langPair.split(separator: "|").map(String.init)
    let lang = speakSource ? (parts.first ?? "en") : (parts.last ?? "zh")
    return lang == "zh" ? "zh-CN" : lang
}

assert_eq(ttsLangCode(langPair: "zh|en", speakSource: true),  "zh-CN", "zh|en 原文 → zh-CN")
assert_eq(ttsLangCode(langPair: "zh|en", speakSource: false), "en",    "zh|en 译文 → en")
assert_eq(ttsLangCode(langPair: "en|zh", speakSource: true),  "en",    "en|zh 原文 → en")
assert_eq(ttsLangCode(langPair: "en|zh", speakSource: false), "zh-CN", "en|zh 译文 → zh-CN")

// ── SpeechService Google TTS URL ──────────────────────────────────────────────
print("\n[SpeechService] Google TTS URL 构建")

func buildGoogleTTSURL(text: String, lang: String) -> URL? {
    guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
    return URL(string: "https://translate.googleapis.com/translate_tts?ie=UTF-8&q=\(encoded)&tl=\(lang)&client=gtx")
}

let url1 = buildGoogleTTSURL(text: "Hello", lang: "en")
if let u = url1 {
    assert_eq(u.absoluteString.contains("translate.googleapis.com"), true, "URL 包含 googleapis.com")
    assert_eq(u.absoluteString.contains("Hello"), true, "URL 包含文本")
    assert_eq(u.absoluteString.contains("tl=en"), true, "URL 包含语言参数")
    passed += 3
} else {
    print("  ❌ URL 构建失败")
    failed += 1
}

let url2 = buildGoogleTTSURL(text: "你好", lang: "zh-CN")
assert_eq(url2 != nil, true, "中文 URL 构建成功")

// ── FloatingWindowController 定位计算 ────────────────────────────────────────
print("\n[FloatingWindowController] 悬浮窗定位")

func calculatePosition(mousePos: CGPoint, windowSize: CGSize, screenFrame: CGRect) -> CGPoint {
    let offset: CGFloat = 12
    var x = mousePos.x - windowSize.width / 2
    var y = mousePos.y - windowSize.height - offset
    x = max(screenFrame.minX + 8, min(x, screenFrame.maxX - windowSize.width - 8))
    if y < screenFrame.minY + 8 { y = mousePos.y + offset }
    return CGPoint(x: x, y: y)
}

let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
let winSize = CGSize(width: 320, height: 160)

let pos1 = calculatePosition(mousePos: CGPoint(x: 500, y: 500), windowSize: winSize, screenFrame: screen)
assert_eq(pos1.x >= screen.minX, true, "正常位置：x 不超出左边界")
assert_eq(pos1.x + winSize.width <= screen.maxX, true, "正常位置：x 不超出右边界")
assert_eq(pos1.y >= screen.minY, true, "正常位置：y 不超出下边界")

let pos2 = calculatePosition(mousePos: CGPoint(x: 500, y: 20), windowSize: winSize, screenFrame: screen)
assert_eq(pos2.y > 20, true, "底部边缘：翻转到鼠标上方")

let pos3 = calculatePosition(mousePos: CGPoint(x: 1430, y: 500), windowSize: winSize, screenFrame: screen)
assert_eq(pos3.x + winSize.width <= screen.maxX, true, "右边缘：x 被 clamp")

// ── 汇总 ─────────────────────────────────────────────────────────────────────
print("\n────────────────────────────────")
print("✅ 通过: \(passed)  ❌ 失败: \(failed)")
if failed == 0 {
    print("🎉 所有测试通过！")
} else {
    print("⚠️  有 \(failed) 个测试失败")
}
