import SwiftUI

@main
struct LingoApp: App {
    @StateObject private var viewModel = TranslationViewModel(
        translationService: TranslationServiceFactory.make()
    )
    @ObservedObject private var hotkeyManager = HotkeyManager.shared
    @State private var showAccessibilityAlert = false
    private let floatingController = FloatingWindowController()
    private let selectionController = SelectionButtonController.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanelView()
                .environmentObject(viewModel)
                .onAppear {
                    setupHotkey()
                    setupSelectionButton()
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
                    Text("Lingo 需要辅助功能权限才能使用 \(hotkeyManager.config.displayString) 快捷键翻译选中文字。")
                }
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    @ViewBuilder
    private var menuBarLabel: some View {
        if viewModel.isTranslating {
            if #available(macOS 15.0, *) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .symbolEffect(.rotate)
            } else {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
        } else if let preview = viewModel.menuBarPreview, !preview.isEmpty {
            HStack(spacing: 4) {
                Image(systemName: "character.bubble")
                    .font(.system(size: 12))
                Text(preview)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.2), value: preview)
        } else {
            Image(systemName: "character.bubble")
        }
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
                // 隐藏划词按钮（如果正在显示）
                selectionController.hideButton()
                vm.translate(text: text)
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    self.floatingController.show(viewModel: vm)
                }
            }
        }
        HotkeyManager.shared.start()
    }

    private func setupSelectionButton() {
        selectionController.onTranslateRequest = { [weak viewModel] text in
            DispatchQueue.main.async {
                guard let vm = viewModel else { return }
                vm.translate(text: text)
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    self.floatingController.show(viewModel: vm)
                }
            }
        }
        selectionController.start()
    }
}
