import SwiftUI

struct FloatingResultView: View {
    @ObservedObject var viewModel: TranslationViewModel
    var onClose: (() -> Void)?

    var langBadge: String {
        let pair = viewModel.effectiveLangPair
        let parts = pair.split(separator: "|")
        let src = parts.first.map(String.init)?.uppercased() ?? "?"
        let tgt = parts.last.map(String.init)?.uppercased() ?? "?"
        return "\(src) → \(tgt)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Header ───────────────────────────────────────────────────────
            HStack(spacing: 8) {
                Text(langBadge)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.12))
                    .cornerRadius(4)

                Text(viewModel.inputText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                Button(action: { onClose?() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .frame(width: 18, height: 18)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(9)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // ── Body ─────────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.inputText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                switch viewModel.translationState {
                case .loading:
                    LoadingDotsView()
                        .frame(minHeight: 28)

                case .success(let text):
                    Text(text)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity.animation(.easeIn(duration: 0.2)))

                    HStack {
                        Spacer()
                        Button(action: { viewModel.speakResult() }) {
                            Label("朗读", systemImage: "speaker.wave.2")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .tint(.blue)

                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(text, forType: .string)
                        }) {
                            Label("复制", systemImage: "doc.on.doc")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .tint(.purple)
                    }

                case .error(let msg):
                    Text(msg)
                        .font(.system(size: 13))
                        .foregroundStyle(.red.opacity(0.8))
                        .frame(minHeight: 28)

                case .idle:
                    EmptyView()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(.regularMaterial)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
    }
}
