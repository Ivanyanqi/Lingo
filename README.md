# Lingo

A lightweight macOS menu bar translator. Select any text, press your hotkey, and get instant translations. Stays out of your way until you need it.

[中文文档](README_CN.md)

---

## Features

- **Menu bar native** — lives quietly in your menu bar, zero dock clutter
- **Global hotkey** — select any text anywhere, press `⌥⌘J` to translate instantly
- **Auto language detection** — automatically detects Chinese ↔ English direction
- **Floating result window** — translation pops up near your cursor, no context switching
- **Text-to-speech** — listen to both source and translated text
- **Customizable hotkey** — change the shortcut to any key combination you prefer
- **Powered by MyMemory** — free translation API, no API key required

## Requirements

- macOS 14 (Sonoma) or later
- Accessibility permission (required for global hotkey)

## Installation

1. Download the latest release from the [Releases](https://github.com/Ivanyanqi/Lingo/releases) page
2. Unzip and move `Lingo.app` to your `/Applications` folder
3. Launch Lingo — a bubble icon will appear in your menu bar
4. When prompted, grant **Accessibility** permission in System Settings → Privacy & Security → Accessibility

## Usage

**Hotkey translation**

1. Select any text in any app
2. Press `⌥⌘J` (Option + Command + J)
3. The translation appears in a floating window

**Menu bar panel**

Click the menu bar icon to open the panel, type or paste text directly, and see the translation in real time.

**Switch language direction**

Click the language badge (e.g. `中文 ⇄ English`) in the top-right of the panel to flip the translation direction.

**Customize hotkey**

Click the gear icon `⚙` at the bottom of the panel to open hotkey settings.

## Project Structure

```
Lingo/
├── Lingo/
│   ├── Core/
│   │   ├── HotkeyManager.swift        # Global hotkey via CGEvent tap
│   │   ├── TranslationService.swift   # MyMemory API client
│   │   ├── TranslationViewModel.swift # State management
│   │   └── SpeechService.swift        # Text-to-speech
│   └── Views/
│       ├── MenuBarPanelView.swift      # Main menu bar panel
│       ├── FloatingResultView.swift    # Floating translation window
│       ├── FloatingWindowController.swift
│       └── HotkeySettingsView.swift
└── LingoTests/                        # Unit tests
```

## Building from Source

```bash
git clone https://github.com/Ivanyanqi/Lingo.git
cd Lingo
open Lingo.xcodeproj
```

Select the **Lingo** scheme and press `⌘R` to build and run.

## Privacy

Lingo does not collect any personal data. Text you translate is sent to the [MyMemory](https://mymemory.translated.net) public API over HTTPS. No account or API key is required.

## License

MIT
