import XCTest
@testable import TranslatorBar

final class HotkeyManagerTests: XCTestCase {

    // MARK: - Accessibility 权限

    func test_checkAccessibility_returnsBool() {
        let result = HotkeyManager.checkAccessibilityPermission()
        // 只验证不崩溃，返回 true 或 false 均可
        XCTAssertNotNil(result)
    }

    // MARK: - 剪贴板

    func test_readClipboard_afterWrite_returnsText() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("test text", forType: .string)
        let result = HotkeyManager.readClipboard()
        XCTAssertEqual(result, "test text")
    }

    func test_readClipboard_empty_returnsNil() {
        NSPasteboard.general.clearContents()
        let result = HotkeyManager.readClipboard()
        XCTAssertNil(result)
    }

    // MARK: - 悬浮窗定位

    func test_floatingWindowPosition_belowCursor_withinScreen() {
        let mousePos = CGPoint(x: 500, y: 500)
        let windowSize = CGSize(width: 320, height: 160)
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let pos = FloatingWindowController.calculatePosition(
            mousePos: mousePos, windowSize: windowSize, screenFrame: screenFrame
        )
        XCTAssertGreaterThanOrEqual(pos.x, screenFrame.minX)
        XCTAssertLessThanOrEqual(pos.x + windowSize.width, screenFrame.maxX)
        XCTAssertGreaterThanOrEqual(pos.y, screenFrame.minY)
    }

    func test_floatingWindowPosition_nearBottomEdge_flipsAbove() {
        let mousePos = CGPoint(x: 500, y: 20) // 接近底部（macOS y 从下往上）
        let windowSize = CGSize(width: 320, height: 160)
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let pos = FloatingWindowController.calculatePosition(
            mousePos: mousePos, windowSize: windowSize, screenFrame: screenFrame
        )
        // 翻转后窗口应在鼠标上方
        XCTAssertGreaterThan(pos.y, mousePos.y)
    }

    func test_floatingWindowPosition_nearRightEdge_clamped() {
        let mousePos = CGPoint(x: 1430, y: 500)
        let windowSize = CGSize(width: 320, height: 160)
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let pos = FloatingWindowController.calculatePosition(
            mousePos: mousePos, windowSize: windowSize, screenFrame: screenFrame
        )
        XCTAssertLessThanOrEqual(pos.x + windowSize.width, screenFrame.maxX)
    }
}
