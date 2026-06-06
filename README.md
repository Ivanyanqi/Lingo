# Lingo

A lightweight macOS menu bar translator. Select any text, press your hotkey, and get instant translations — powered by MyMemory, DeepL, or OpenAI. Stays out of your way until you need it.

[中文文档](README_CN.md) · [Changelog](CHANGELOG.md)

---

## Features

- **Menu bar native** — lives quietly in your menu bar, zero dock clutter
- **Global hotkey** — select any text anywhere, press `⌥⌘J` to translate instantly
- **Selection floating button** — a "Translate" button appears near your cursor after selecting text; click to translate without touching the keyboard
- **Auto language detection** — automatically detects Chinese ↔ English direction
- **Multi-language support** — translate to Chinese, English, Japanese, Korean, French, Spanish, German, Portuguese, or Russian
- **Multiple translation engines** — switch between MyMemory (free), DeepL, and OpenAI in Settings
- **Translation history** — last 50 translations saved locally, encrypted at rest, with favorites and CSV export
- **LRU cache** — repeated queries are served instantly from cache, no extra API calls
- **Floating result window** — translation pops up near your cursor, auto-dismisses after 3 seconds
- **Text-to-speech** — listen to both source and translated text (system TTS, works offline)
- **Launch at login** — optional auto-start on login via `SMAppService`
- **Network awareness** — detects offline state immediately; cached translations still work
- **Customizable hotkey** — change the shortcut to any key combination you prefer
- **Privacy hardening** — API keys stored in Keychain, clipboard fallback restores previous clipboard contents, app runs sandboxed

## Requirements

- macOS 14 (Sonoma) or later
- Accessibility permission (required for global hotkey and selection button)

## Installation

1. Download the latest release from the [Releases](https://github.com/Ivanyanqi/Lingo/releases) page
2. Unzip and move `Lingo.app` to your `/Applications` folder
3. Launch Lingo — a bubble icon will appear in your menu bar
4. When prompted, grant **Accessibility** permission in System Settings → Privacy & Security → Accessibility

## Usage

**Hotkey translation**

1. Select any text in any app
2. Press `⌥⌘J` (Option + Command + J)
3. The translation appears in a floating window near your cursor

**Selection floating button**

1. Select any text in any app
2. A small "译" button appears near your cursor
3. Click it — the translation pops up immediately

**Menu bar panel**

Click the menu bar icon to open the panel. Three tabs are available:

- **Translate** — type or paste text and see the translation in real time
- **History** — browse, favorite, and re-run past translations; export to CSV
- **Settings** — choose translation engine, manage API keys, configure hotkey, toggle launch at login and selection button

**Switch language direction**

Click the language badge (e.g. `中文 → EN`) in the top-left of the Translate tab to open the language picker.

**Change translation engine**

Go to Settings → Translation Engine. Select MyMemory (no key needed), DeepL, or OpenAI. Enter your API key when prompted.

## Project Structure

```
Lingo/
├── Lingo/
│   ├── Core/
│   │   ├── HotkeyManager.swift              # Global hotkey via CGEvent tap
│   │   ├── TranslationService.swift         # MyMemory / DeepL / OpenAI clients
│   │   ├── TranslationViewModel.swift       # Reactive state, debounce, cache
│   │   ├── TranslationCache.swift           # Thread-safe LRU cache
│   │   ├── HistoryStore.swift               # Local history persistence
│   │   ├── TargetLanguage.swift             # Supported language enum
│   │   ├── SelectionButtonController.swift  # Floating translate button
│   │   ├── LaunchAtLoginManager.swift       # SMAppService wrapper
│   │   ├── NetworkMonitor.swift             # NWPathMonitor wrapper
│   │   └── SpeechService.swift              # System TTS (AVSpeechSynthesizer)
│   └── Views/
│       ├── MenuBarPanelView.swift           # Three-tab menu bar panel
│       ├── FloatingResultView.swift         # Floating translation window
│       ├── FloatingWindowController.swift   # NSPanel controller
│       └── HotkeySettingsView.swift         # Hotkey recorder
└── LingoTests/                              # Unit tests
```

## Building from Source

```bash
git clone https://github.com/Ivanyanqi/Lingo.git
cd Lingo
open Lingo.xcodeproj
```

Select the **Lingo** scheme and press `⌘R` to build and run.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a full version history, or [CHANGELOG_CN.md](CHANGELOG_CN.md) for the Chinese version.

| Version | Highlights |
|---------|-----------|
| [v0.4.0](CHANGELOG.md#v040--security--privacy-hardening) | App Sandbox, Keychain API keys, encrypted history, local-only TTS, safer clipboard and CSV export |
| [v0.3.0](CHANGELOG.md#v030--bug-fixes--polish) | Engine switching fix, favorite button fix, 500-char limit, selection button toggle, network awareness, system TTS |
| [v0.2.0](CHANGELOG.md#v020--full-feature-iteration) | History, multi-language, DeepL/OpenAI engines, LRU cache, debounce, launch at login, selection button, quit button |
| [v0.1.0](CHANGELOG.md#v010--mvp) | Menu bar app, global hotkey, MyMemory translation, floating window, TTS, customizable hotkey |

## Privacy

Lingo does not collect any personal data. Text you translate is sent to the translation API you choose (MyMemory, DeepL, or OpenAI) over HTTPS. API keys are stored locally in the macOS Keychain. Translation history stays on your Mac in local app storage and is encrypted at rest. Speech playback uses the system TTS engine only, and clipboard fallback restores your previous clipboard contents after capture.

## License

MIT
