import AppKit
import SwiftUI

final class FloatingWindowController {
    private var panel: NSPanel?
    private var globalMonitor: Any?

    func show(viewModel: TranslationViewModel) {
        let mousePos = NSEvent.mouseLocation
        let screenFrame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let windowSize = CGSize(width: 320, height: 180)
        let origin = Self.calculatePosition(mousePos: mousePos, windowSize: windowSize, screenFrame: screenFrame)

        if panel == nil {
            let p = NSPanel(
                contentRect: CGRect(origin: origin, size: windowSize),
                styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
                backing: .buffered,
                defer: false
            )
            p.isFloatingPanel = true
            p.level = .floating
            p.backgroundColor = .clear
            p.isOpaque = false
            p.hasShadow = true
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            p.isMovableByWindowBackground = true

            let hosting = NSHostingView(rootView: FloatingResultView(viewModel: viewModel) {
                self.hide()
            })
            hosting.frame = CGRect(origin: .zero, size: windowSize)
            p.contentView = hosting
            self.panel = p
        } else {
            panel?.setFrameOrigin(origin)
        }

        panel?.orderFrontRegardless()

        // 点击其他地方自动关闭
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hide()
        }
    }

    func hide() {
        panel?.orderOut(nil)
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }

    /// 计算悬浮窗位置：鼠标下方 12pt，超出屏幕则翻转到上方
    static func calculatePosition(mousePos: CGPoint, windowSize: CGSize, screenFrame: CGRect) -> CGPoint {
        let offset: CGFloat = 12
        var x = mousePos.x - windowSize.width / 2
        var y = mousePos.y - windowSize.height - offset

        // 水平边界
        x = max(screenFrame.minX + 8, min(x, screenFrame.maxX - windowSize.width - 8))
        // 垂直边界：下方空间不足则翻转到上方
        if y < screenFrame.minY + 8 {
            y = mousePos.y + offset
        }
        return CGPoint(x: x, y: y)
    }
}
