import SwiftUI

// MARK: - Tab

enum PanelTab: String, CaseIterable {
    case translate = "translate"
    case history   = "history"
    case settings  = "settings"

    var icon: String {
        switch self {
        case .translate: return "character.bubble"
        case .history:   return "clock"
        case .settings:  return "gearshape"
        }
    }

    var label: String {
        switch self {
        case .translate: return "翻译"
        case .history:   return "历史"
        case .settings:  return "设置"
        }
    }
}

// MARK: - MenuBarPanelView

struct MenuBarPanelView: View {
    @EnvironmentObject var viewModel: TranslationViewModel
    @State private var activeTab: PanelTab = .translate

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────────────────
            HStack(spacing: 0) {
                ForEach(PanelTab.allCases, id: \.self) { tab in
                    Button(action: { activeTab = tab }) {
                        VStack(spacing: 3) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13))
                            Text(tab.label)
                                .font(.system(size: 10))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(activeTab == tab ? Color.accentColor : Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(.windowBackgroundColor).opacity(0.6))

            Divider()

            // ── Content ──────────────────────────────────────────────────────
            Group {
                switch activeTab {
                case .translate:
                    TranslateTabView()
                        .environmentObject(viewModel)
                case .history:
                    HistoryTabView()
                        .environmentObject(viewModel)
                        .onTapGesture { } // 防止点击穿透
                case .settings:
                    SettingsTabView()
                        .environmentObject(viewModel)
                }
            }
        }
        .frame(width: 380)
    }
}

// MARK: - TranslateTabView

struct TranslateTabView: View {
    @EnvironmentObject var viewModel: TranslationViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 语言选择器
            HStack {
                LanguageSelectorView()
                    .environmentObject(viewModel)
                Spacer()
                HotkeyBadgeView()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // 输入区
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topLeading) {
                    if viewModel.inputText.isEmpty {
                        Text("输入要翻译的文字…")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $viewModel.inputText)
                        .font(.system(size: 14))
                        .frame(minHeight: 72, maxHeight: 120)
                        .scrollContentBackground(.hidden)
                        .focused($isInputFocused)
                        .onChange(of: viewModel.inputText) { _, newValue in
                            if newValue.count >= 2 {
                                viewModel.translateDebounced()
                            } else if newValue.isEmpty {
                                viewModel.clear()
                            }
                        }
                }
                .padding(8)
                .background(Color(.textBackgroundColor).opacity(0.6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(isInputFocused ? 0.5 : 0.2), lineWidth: 1)
                )

                HStack {
                    Text("\(viewModel.inputText.count) / 500")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    if !viewModel.inputText.isEmpty {
                        Button(action: { viewModel.speakSource() }) {
                            Image(systemName: "speaker.wave.2")
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("朗读原文")

                        Button(action: { viewModel.clear() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("清空")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // 结果区
            ResultAreaView()
                .environmentObject(viewModel)
        }
        .onAppear { isInputFocused = true }
    }
}

// MARK: - LanguageSelectorView

struct LanguageSelectorView: View {
    @EnvironmentObject var viewModel: TranslationViewModel
    @State private var showPicker = false

    var displayText: String {
        if viewModel.targetLang == .chineseEnglish {
            let pair = viewModel.forcedLangPair ?? TranslationService.detectLangPair(viewModel.inputText)
            return pair == "zh|en" ? "中文 → EN" : "EN → 中文"
        }
        return "\(viewModel.targetLang.flag) \(viewModel.targetLang.displayName)"
    }

    var body: some View {
        Button(action: { showPicker.toggle() }) {
            HStack(spacing: 4) {
                Text(displayText)
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPicker, arrowEdge: .bottom) {
            LanguagePickerView(showPicker: $showPicker)
                .environmentObject(viewModel)
        }
    }
}

struct LanguagePickerView: View {
    @EnvironmentObject var viewModel: TranslationViewModel
    @Binding var showPicker: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("目标语言")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 10)

            ForEach(TargetLanguage.allCases, id: \.self) { lang in
                Button(action: {
                    viewModel.setTargetLanguage(lang)
                    showPicker = false
                }) {
                    HStack {
                        Text(lang.flag)
                        Text(lang.displayName)
                            .font(.system(size: 13))
                        Spacer()
                        if viewModel.targetLang == lang {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(viewModel.targetLang == lang ? Color.accentColor.opacity(0.08) : Color.clear)
            }
            .padding(.bottom, 6)
        }
        .frame(width: 200)
    }
}

// MARK: - HotkeyBadgeView

struct HotkeyBadgeView: View {
    @ObservedObject private var hotkeyManager = HotkeyManager.shared

    var body: some View {
        if hotkeyManager.config.isEnabled {
            Text(hotkeyManager.config.displayString)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.quaternary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(4)
        }
    }
}

// MARK: - ResultAreaView

struct ResultAreaView: View {
    @EnvironmentObject var viewModel: TranslationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("翻译结果")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .tracking(1)

            Group {
                switch viewModel.translationState {
                case .idle:
                    Text("输入文字开始翻译…")
                        .font(.system(size: 14))
                        .foregroundStyle(.quaternary)

                case .loading:
                    LoadingDotsView()

                case .success(let text):
                    VStack(alignment: .leading, spacing: 10) {
                        Text(text)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity.animation(.easeIn(duration: 0.2)))

                        HStack {
                            // 收藏按钮
                            if let latest = HistoryStore.shared.entries.first {
                                Button(action: { HistoryStore.shared.toggleFavorite(id: latest.id) }) {
                                    Image(systemName: latest.isFavorite ? "star.fill" : "star")
                                        .font(.system(size: 13))
                                        .foregroundStyle(latest.isFavorite ? .yellow : .secondary)
                                }
                                .buttonStyle(.plain)
                                .help(latest.isFavorite ? "取消收藏" : "收藏")
                            }
                            Spacer()
                            Button(action: { viewModel.speakResult() }) {
                                Label("朗读", systemImage: "speaker.wave.2")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(.blue)

                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(text, forType: .string)
                            }) {
                                Label("复制", systemImage: "doc.on.doc")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(.purple)
                        }
                    }

                case .error(let msg):
                    Text(msg)
                        .font(.system(size: 13))
                        .foregroundStyle(.red.opacity(0.8))
                }
            }
            .frame(minHeight: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - HistoryTabView

struct HistoryTabView: View {
    @EnvironmentObject var viewModel: TranslationViewModel
    @ObservedObject private var historyStore = HistoryStore.shared
    @State private var showFavoritesOnly = false
    @State private var showExportAlert = false
    @State private var exportURL: URL? = nil

    var displayedEntries: [HistoryEntry] {
        showFavoritesOnly ? historyStore.favorites : historyStore.entries
    }

    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack {
                Toggle(isOn: $showFavoritesOnly) {
                    Label("仅收藏", systemImage: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(showFavoritesOnly ? .yellow : .secondary)
                }
                .toggleStyle(.button)
                .controlSize(.small)

                Spacer()

                Button(action: exportCSV) {
                    Label("导出", systemImage: "square.and.arrow.up")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("导出为 CSV")

                Button(action: { historyStore.clearAll() }) {
                    Label("清空", systemImage: "trash")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("清空历史")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            Divider()

            if displayedEntries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: showFavoritesOnly ? "star.slash" : "clock.badge.xmark")
                        .font(.system(size: 28))
                        .foregroundStyle(.quaternary)
                    Text(showFavoritesOnly ? "暂无收藏" : "暂无翻译历史")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(displayedEntries) { entry in
                            HistoryRowView(entry: entry)
                                .environmentObject(viewModel)
                            Divider().padding(.leading, 14)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }

    private func exportCSV() {
        let csv = historyStore.exportCSV()
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("lingo_history.csv")
        try? csv.write(to: tmpURL, atomically: true, encoding: .utf8)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "lingo_history.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        if panel.runModal() == .OK, let dest = panel.url {
            try? FileManager.default.copyItem(at: tmpURL, to: dest)
        }
    }
}

struct HistoryRowView: View {
    @EnvironmentObject var viewModel: TranslationViewModel
    let entry: HistoryEntry
    @ObservedObject private var historyStore = HistoryStore.shared

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.langBadge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(3)
                    Text(entry.date, style: .relative)
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                }
                Text(entry.sourceText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(entry.translatedText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            Spacer()
            VStack(spacing: 8) {
                Button(action: { historyStore.toggleFavorite(id: entry.id) }) {
                    Image(systemName: entry.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundColor(entry.isFavorite ? .yellow : Color(.quaternaryLabelColor))
                }
                .buttonStyle(.plain)

                Button(action: {
                    viewModel.inputText = entry.sourceText
                    viewModel.translate(text: entry.sourceText)
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11))
                        .foregroundColor(Color(.quaternaryLabelColor))
                }
                .buttonStyle(.plain)
                .help("重新翻译")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - SettingsTabView

struct SettingsTabView: View {
    @EnvironmentObject var viewModel: TranslationViewModel
    @ObservedObject private var hotkeyManager = HotkeyManager.shared
    @ObservedObject private var launchManager = LaunchAtLoginManager.shared
    @State private var showHotkeySettings = false
    @State private var selectedEngine = TranslationEngine.load()
    @State private var deepLKey = TranslationEngine.deepLAPIKey
    @State private var openAIKey = TranslationEngine.openAIAPIKey

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                // ── 翻译引擎 ────────────────────────────────────────────────
                SettingsSectionHeader(title: "翻译引擎")

                VStack(spacing: 0) {
                    ForEach(TranslationEngine.allCases, id: \.self) { engine in
                        Button(action: {
                            selectedEngine = engine
                            TranslationEngine.save(engine)
                        }) {
                            HStack {
                                Image(systemName: selectedEngine == engine ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedEngine == engine ? .accentColor : .secondary)
                                Text(engine.displayName)
                                    .font(.system(size: 13))
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if engine != TranslationEngine.allCases.last {
                            Divider().padding(.leading, 36)
                        }
                    }
                }
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)

                // API Key 输入
                if selectedEngine == .deepL {
                    APIKeyField(label: "DeepL API Key", placeholder: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx:fx",
                                value: $deepLKey) {
                        TranslationEngine.deepLAPIKey = deepLKey
                    }
                } else if selectedEngine == .openAI {
                    APIKeyField(label: "OpenAI API Key", placeholder: "sk-...",
                                value: $openAIKey) {
                        TranslationEngine.openAIAPIKey = openAIKey
                    }
                }

                // ── 快捷键 ──────────────────────────────────────────────────
                SettingsSectionHeader(title: "快捷键")

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("全局翻译快捷键")
                            .font(.system(size: 13))
                        Text("选中文字后按下快捷键自动翻译")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { hotkeyManager.config.isEnabled },
                        set: { val in
                            var c = hotkeyManager.config; c.isEnabled = val
                            hotkeyManager.config = c
                        }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }
                .padding(12)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)

                Button(action: { showHotkeySettings = true }) {
                    HStack {
                        Text("当前快捷键")
                            .font(.system(size: 13))
                        Spacer()
                        Text(hotkeyManager.config.displayString)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.accentColor)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showHotkeySettings, arrowEdge: .trailing) {
                    HotkeySettingsView()
                }

                // ── 通用 ────────────────────────────────────────────────────
                SettingsSectionHeader(title: "通用")

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("登录时自动启动")
                            .font(.system(size: 13))
                        Text("开机后自动在菜单栏运行 Lingo")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { launchManager.isEnabled },
                        set: { _ in launchManager.toggle() }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }
                .padding(12)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)

                // 权限提示
                if !HotkeyManager.checkAccessibilityPermission() {
                    AccessibilityWarningView()
                }

                // ── 退出 ────────────────────────────────────────────────────
                Divider()
                    .padding(.top, 4)

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    HStack {
                        Image(systemName: "power")
                            .font(.system(size: 13))
                        Text("退出 Lingo")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(.red.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.06))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(14)
        }
        .frame(maxHeight: 400)
    }
}

struct SettingsSectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.top, 4)
    }
}

struct APIKeyField: View {
    let label: String
    let placeholder: String
    @Binding var value: String
    var onCommit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            SecureField(placeholder, text: $value, onCommit: onCommit)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, design: .monospaced))
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct AccessibilityWarningView: View {
    var body: some View {
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
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - LoadingDotsView

struct LoadingDotsView: View {
    @State private var phase = 0
    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 7, height: 7)
                    .opacity(phase == i ? 1.0 : 0.25)
                    .scaleEffect(phase == i ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 0.3), value: phase)
            }
        }
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}
