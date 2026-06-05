import AppKit
import SwiftUI

final class FloatingWindowController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<FloatingResultView>?
    private var globalMonitor: Any?
    private var autoDismissTask: DispatchWorkItem?

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

            let rootView = FloatingResultView(viewModel: viewModel) { [weak self] in
                self?.hide()
            }
            let hosting = NSHostingView(rootView: rootView)
            hosting.frame = CGRect(origin: .zero, size: windowSize)
            p.contentView = hosting
            self.panel = p
            self.hostingView = hosting
        } else {
            // 每次 show 都更新 viewModel 引用，避免显示旧数据
            let rootView = FloatingResultView(viewModel: viewModel) { [weak self] in
                self?.hide()
            }
            hostingView?.rootView = rootView
            panel?.setFrameOrigin(origin)
        }

        panel?.orderFrontRegardless()
        scheduleAutoDismiss()

        // 点击其他地方自动关闭
        if globalMonitor == nil {
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.hide()
            }
        }
    }

    func hide() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
        panel?.orderOut(nil)
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }

    // MARK: - 自动消失（3 秒后淡出）

    private func scheduleAutoDismiss() {
        autoDismissTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self, let panel = self.panel else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.4
                panel.animator().alphaValue = 0
            }, completionHandler: {
                self.hide()
                panel.alphaValue = 1
            })
        }
        autoDismissTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: task)
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
