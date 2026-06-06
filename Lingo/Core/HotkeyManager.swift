import Cocoa
import Carbon

// MARK: - HotkeyConfig

struct HotkeyConfig: Codable, Equatable {
    var keyCode: Int        // CGKeyCode
    var modifiers: UInt64   // CGEventFlags rawValue
    var isEnabled: Bool

    /// 默认：⌥⌘J (keyCode=38, option+command)
    static let `default` = HotkeyConfig(
        keyCode: 38,
        modifiers: CGEventFlags.maskAlternate.rawValue | CGEventFlags.maskCommand.rawValue,
        isEnabled: true
    )

    /// 人类可读的快捷键字符串，如 "⌥⌘J"
    var displayString: String {
        var parts = ""
        let flags = CGEventFlags(rawValue: modifiers)
        if flags.contains(.maskControl)   { parts += "⌃" }
        if flags.contains(.maskAlternate) { parts += "⌥" }
        if flags.contains(.maskShift)     { parts += "⇧" }
        if flags.contains(.maskCommand)   { parts += "⌘" }
        parts += keyCodeToChar(keyCode)
        return parts
    }

    private func keyCodeToChar(_ code: Int) -> String {
        // 常用键映射
        let map: [Int: String] = [
            0:"A",1:"S",2:"D",3:"F",4:"H",5:"G",6:"Z",7:"X",8:"C",9:"V",
            11:"B",12:"Q",13:"W",14:"E",15:"R",16:"Y",17:"T",
            31:"O",32:"U",34:"I",35:"P",37:"L",38:"J",40:"K",
            45:"N",46:"M",
            49:"Space",51:"⌫",53:"Esc",
            123:"←",124:"→",125:"↓",126:"↑"
        ]
        return map[code] ?? "(\(code))"
    }
}

// MARK: - HotkeyManager

final class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()

    var onTranslateRequest: ((String) -> Void)?

    @Published var config: HotkeyConfig {
        didSet {
            saveConfig()
            restartIfNeeded()
        }
    }

    private var eventTap: CFMachPort?
    private var eventTapContext: UnsafeMutableRawPointer?
    private let configKey = "hotkeyConfig"

    private init() {
        // 从 UserDefaults 加载，否则用默认值
        if let data = UserDefaults.standard.data(forKey: "hotkeyConfig"),
           let saved = try? JSONDecoder().decode(HotkeyConfig.self, from: data) {
            config = saved
        } else {
            config = .default
        }
    }

    // MARK: - Accessibility

    static func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    static func readClipboard() -> String? {
        return NSPasteboard.general.string(forType: .string)
    }

    // MARK: - Lifecycle

    func start() {
        guard config.isEnabled, Self.checkAccessibilityPermission() else { return }
        stopEventTap()

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let selfPtr = Unmanaged.passRetained(self).toOpaque()
        eventTapContext = selfPtr
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { proxy, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon else { return Unmanaged.passUnretained(event) }
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

    func stop() {
        stopEventTap()
    }

    private func stopEventTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
        if let context = eventTapContext {
            Unmanaged<HotkeyManager>.fromOpaque(context).release()
            eventTapContext = nil
        }
    }

    private func restartIfNeeded() {
        stopEventTap()
        if config.isEnabled {
            start()
        }
    }

    // MARK: - Event Handling

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        // 只保留修饰键部分做比较（忽略 numpad、caps lock 等噪音位）
        let relevantMask: CGEventFlags = [.maskAlternate, .maskCommand, .maskControl, .maskShift]
        let eventModifiers = flags.intersection(relevantMask)
        let targetModifiers = CGEventFlags(rawValue: config.modifiers).intersection(relevantMask)

        if keyCode == config.keyCode && eventModifiers == targetModifiers {
            triggerTranslation()
            return nil // 消费事件
        }
        return Unmanaged.passUnretained(event)
    }

    private func triggerTranslation() {
        if let text = SelectedTextReader.accessibilitySelectedText() {
            onTranslateRequest?(text)
            return
        }

        let pasteboard = NSPasteboard.general
        let snapshot = ClipboardSnapshot.capture(from: pasteboard)
        let originalChangeCount = pasteboard.changeCount
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true) // C
        let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags   = .maskCommand
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            defer {
                if pasteboard.changeCount != originalChangeCount {
                    snapshot.restore(to: pasteboard)
                }
            }
            guard pasteboard.changeCount != originalChangeCount else { return }
            guard let text = Self.readClipboard(),
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return }
            self?.onTranslateRequest?(text)
        }
    }

    // MARK: - Persistence

    private func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: configKey)
        }
    }
}
