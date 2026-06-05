import SwiftUI
import Carbon

// MARK: - HotkeySettingsView

struct HotkeySettingsView: View {
    @ObservedObject var hotkeyManager = HotkeyManager.shared
    @State private var isRecording = false
    @State private var recordedConfig: HotkeyConfig? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("快捷键设置")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                // 启用/禁用开关
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("启用全局快捷键")
                            .font(.system(size: 13, weight: .medium))
                        Text("按下快捷键自动翻译选中文字")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { hotkeyManager.config.isEnabled },
                        set: { newVal in
                            var c = hotkeyManager.config
                            c.isEnabled = newVal
                            hotkeyManager.config = c
                        }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }
                .padding(12)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)

                // 快捷键录制区
                VStack(alignment: .leading, spacing: 8) {
                    Text("当前快捷键")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    HStack(spacing: 10) {
                        // 快捷键显示/录制框
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isRecording
                                      ? Color.accentColor.opacity(0.12)
                                      : Color(.controlBackgroundColor))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isRecording
                                                ? Color.accentColor
                                                : Color.secondary.opacity(0.2),
                                                lineWidth: isRecording ? 1.5 : 1)
                                )

                            if isRecording {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 7, height: 7)
                                        .opacity(0.9)
                                    Text("请按下新快捷键…")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Text(hotkeyManager.config.displayString)
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .foregroundStyle(hotkeyManager.config.isEnabled ? .primary : .secondary)
                            }
                        }
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if hotkeyManager.config.isEnabled {
                                isRecording.toggle()
                            }
                        }
                        // 键盘事件捕获
                        .background(
                            KeyRecorderView(isRecording: $isRecording) { newConfig in
                                hotkeyManager.config = newConfig
                                isRecording = false
                            }
                        )

                        // 重置按钮
                        Button(action: {
                            isRecording = false
                            hotkeyManager.config = .default
                        }) {
                            Text("重置")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .help("重置为默认快捷键 ⌥⌘J")
                    }

                    if !hotkeyManager.config.isEnabled {
                        Text("快捷键已禁用，请先开启上方开关")
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                    } else if isRecording {
                        Text("支持 ⌃⌥⇧⌘ 组合键，按 Esc 取消录制")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("点击上方方框开始录制新快捷键")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)

                // 权限提示
                if !HotkeyManager.checkAccessibilityPermission() {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 13))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("需要辅助功能权限")
                                .font(.system(size: 12, weight: .medium))
                            Text("快捷键功能需要此权限才能正常工作")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("去授权") {
                            HotkeyManager.requestAccessibilityPermission()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.orange)
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(16)
        }
        .frame(width: 340)
        .onDisappear { isRecording = false }
    }
}

// MARK: - KeyRecorderView（NSViewRepresentable 捕获键盘事件）

struct KeyRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onRecord: (HotkeyConfig) -> Void

    func makeNSView(context: Context) -> KeyCaptureNSView {
        let view = KeyCaptureNSView()
        view.onKeyDown = { keyCode, flags in
            // Esc 取消录制
            if keyCode == 53 {
                DispatchQueue.main.async { self.isRecording = false }
                return
            }
            // 必须包含至少一个修饰键
            let relevantMask: CGEventFlags = [.maskAlternate, .maskCommand, .maskControl, .maskShift]
            let mods = flags.intersection(relevantMask)
            guard !mods.isEmpty else { return }

            let newConfig = HotkeyConfig(
                keyCode: keyCode,
                modifiers: mods.rawValue,
                isEnabled: HotkeyManager.shared.config.isEnabled
            )
            DispatchQueue.main.async { self.onRecord(newConfig) }
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureNSView, context: Context) {
        nsView.isActive = isRecording
    }
}

final class KeyCaptureNSView: NSView {
    var onKeyDown: ((Int, CGEventFlags) -> Void)?
    var isActive = false

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard isActive else { super.keyDown(with: event); return }
        let keyCode = Int(event.keyCode)
        let flags = CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))
        onKeyDown?(keyCode, flags)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
}
