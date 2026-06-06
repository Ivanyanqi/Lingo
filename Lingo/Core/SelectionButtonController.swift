import AppKit
import SwiftUI

/// 划词悬浮翻译按钮控制器
/// 监听全局鼠标松开事件 → 检测选中文字 → 在选区旁显示小按钮 → 点击触发翻译
final class SelectionButtonController: ObservableObject {

    static let shared = SelectionButtonController()

    var onTranslateRequest: ((String) -> Void)?

    private static let enabledKey = "selectionButtonEnabled"

    /// 是否启用划词悬浮按钮（持久化）
    @Published var isEnabled: Bool = UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            if isEnabled {
                startMonitor()
            } else {
                stopMonitor()
            }
        }
    }

    private var buttonPanel: NSPanel?
    private var mouseUpMonitor: Any?
    private var dismissMonitor: Any?
    private var dismissTask: DispatchWorkItem?

    // MARK: - Lifecycle

    func start() {
        guard isEnabled else { return }
        startMonitor()
    }

    func stop() {
        stopMonitor()
    }

    private func startMonitor() {
        guard mouseUpMonitor == nil else { return }
        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            self?.handleMouseUp(event: event)
        }
    }

    private func stopMonitor() {
        if let m = mouseUpMonitor { NSEvent.removeMonitor(m); mouseUpMonitor = nil }
        hideButton()
    }

    // MARK: - Mouse Up Handler

    private func handleMouseUp(event: NSEvent) {
        // 延迟一点点，等系统完成选区更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.checkSelectionAndShow(mousePos: NSEvent.mouseLocation)
        }
    }

    private func checkSelectionAndShow(mousePos: CGPoint) {
        // 优先用 Accessibility API 读取选中文字
        if let text = SelectedTextReader.accessibilitySelectedText() {
            showButton(near: mousePos, text: text)
            return
        }
        // 降级：读剪贴板（某些 app 选中后会自动写入剪贴板）
        // 这里不做降级，避免误触发
    }

    // MARK: - Show / Hide Button

    private func showButton(near mousePos: CGPoint, text: String) {
        hideButton()

        let buttonSize = CGSize(width: 36, height: 28)
        let screenFrame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)

        // 按钮出现在鼠标右上方
        var origin = CGPoint(
            x: mousePos.x + 8,
            y: mousePos.y + 4
        )
        // 边界保护
        origin.x = min(origin.x, screenFrame.maxX - buttonSize.width - 4)
        origin.y = min(origin.y, screenFrame.maxY - buttonSize.height - 4)

        let panel = NSPanel(
            contentRect: CGRect(origin: origin, size: buttonSize),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating + 1
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let button = SelectionTranslateButton {  [weak self] in
            self?.hideButton()
            self?.onTranslateRequest?(text)
        }
        let hosting = NSHostingView(rootView: button)
        hosting.frame = CGRect(origin: .zero, size: buttonSize)
        panel.contentView = hosting

        self.buttonPanel = panel
        panel.orderFrontRegardless()

        // 监听点击其他地方 → 消失
        dismissMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .leftMouseDragged]) { [weak self] _ in
            self?.hideButton()
        }

        // 4 秒后自动消失
        let task = DispatchWorkItem { [weak self] in self?.hideButton() }
        dismissTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: task)
    }

    func hideButton() {
        dismissTask?.cancel()
        dismissTask = nil
        buttonPanel?.orderOut(nil)
        buttonPanel = nil
        if let m = dismissMonitor { NSEvent.removeMonitor(m); dismissMonitor = nil }
    }
}

// MARK: - SelectionTranslateButton View

struct SelectionTranslateButton: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: "character.bubble.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("译")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isHovered
                          ? Color(red: 0.25, green: 0.45, blue: 1.0)
                          : Color(red: 0.35, green: 0.55, blue: 1.0))
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isHovered)
    }
}
