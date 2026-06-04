import SwiftUI

struct MenuBarPanelView: View {
    @EnvironmentObject var viewModel: TranslationViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────────────────
            HStack {
                Label("TranslatorBar", systemImage: "character.bubble")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                LangSwitcherView()
                    .environmentObject(viewModel)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // ── Input ────────────────────────────────────────────────────────
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
                                viewModel.translate()
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

            // ── Result ───────────────────────────────────────────────────────
            ResultAreaView()
                .environmentObject(viewModel)

            Divider()

            // ── Footer ───────────────────────────────────────────────────────
            HStack {
                Text("⌥Space 翻译选中文字")
                    .font(.system(size: 11))
                    .foregroundStyle(.quaternary)
                Spacer()
                Text("MyMemory")
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 380)
        .onAppear { isInputFocused = true }
    }
}

// MARK: - LangSwitcherView

struct LangSwitcherView: View {
    @EnvironmentObject var viewModel: TranslationViewModel

    var displayText: String {
        switch viewModel.langPair {
        case "zh|en": return "中文 ⇄ English"
        case "en|zh": return "English ⇄ 中文"
        default:
            let detected = TranslationService.detectLangPair(viewModel.inputText)
            return detected == "zh|en" ? "中文 ⇄ English" : "English ⇄ 中文"
        }
    }

    var body: some View {
        Button(action: { viewModel.toggleLangPair() }) {
            Text(displayText)
                .font(.system(size: 12, weight: .medium))
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
        .help("点击切换翻译方向")
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
