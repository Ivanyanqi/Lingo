import SwiftUI

@main
struct TranslatorBarApp: App {
    @StateObject private var viewModel = TranslationViewModel()
    @ObservedObject private var hotkeyManager = HotkeyManager.shared
    @State private var showAccessibilityAlert = false
    private let floatingController = FloatingWindowController()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanelView()
                .environmentObject(viewModel)
                .onAppear {
                    setupHotkey()
                    checkAccessibility()
                }
                .alert("需要辅助功能权限", isPresented: $showAccessibilityAlert) {
                    Button("打开系统设置") {
                        NSWorkspace.shared.open(
                            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                        )
                    }
                    Button("稍后再说", role: .cancel) {}
                } message: {
                    Text("TranslatorBar 需要辅助功能权限才能使用 \(hotkeyManager.config.displayString) 快捷键翻译选中文字。")
                }
        } label: {
            if viewModel.isTranslating {
                if #available(macOS 15.0, *) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .symbolEffect(.rotate)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
            } else {
                Image(systemName: "character.bubble")
            }
        }
        .menuBarExtraStyle(.window)
    }

    private func checkAccessibility() {
        if !HotkeyManager.checkAccessibilityPermission() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showAccessibilityAlert = true
            }
        }
    }

    private func setupHotkey() {
        HotkeyManager.shared.onTranslateRequest = { [weak viewModel] text in
            DispatchQueue.main.async {
                guard let vm = viewModel else { return }
                vm.translate(text: text)
                // 等待翻译完成后显示悬浮窗
                Task { @MainActor in
                    // 短暂延迟确保翻译状态已更新为 loading
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    self.floatingController.show(viewModel: vm)
                }
            }
        }
        HotkeyManager.shared.start()
    }
}
