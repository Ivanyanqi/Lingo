import Cocoa
import Carbon

final class HotkeyManager {
    static let shared = HotkeyManager()
    var onTranslateRequest: ((String) -> Void)?
    private var eventTap: CFMachPort?

    private init() {}

    /// 检测 Accessibility 权限（不弹提示）
    static func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// 请求权限（弹出系统提示）
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// 读取剪贴板文字
    static func readClipboard() -> String? {
        return NSPasteboard.general.string(forType: .string)
    }

    /// 启动全局快捷键监听（⌥Space）
    func start() {
        guard Self.checkAccessibilityPermission() else { return }
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let selfPtr = Unmanaged.passRetained(self).toOpaque()
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { proxy, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: selfPtr
        )
        guard let tap = eventTap else { return }
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // ⌥Space: keyCode 49, flags contains .maskAlternate
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        if keyCode == 49 && flags.contains(.maskAlternate) && !flags.contains(.maskCommand) && !flags.contains(.maskControl) {
            triggerTranslation()
            return nil // 消费事件
        }
        return Unmanaged.passRetained(event)
    }

    private func triggerTranslation() {
        // 模拟 ⌘C 复制选中文字
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true) // C
        let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags   = .maskCommand
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)

        // 等待剪贴板更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            guard let text = Self.readClipboard(),
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return }
            self?.onTranslateRequest?(text)
        }
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
    }
}
