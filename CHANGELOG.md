# Changelog

All notable changes to Lingo are documented here, organized by version.

[中文版本记录](CHANGELOG_CN.md)

---

## [v0.3.0] — Bug Fixes & Polish

> Focus: Fix all known issues from v0.2.0 and improve reliability across the board.

### Fixed

- **Engine switching now takes effect immediately** — Previously, switching translation engines in Settings required a restart. The `TranslationViewModel` now holds a reactive `currentEngine` property; changing it instantly swaps the underlying service instance and clears the cache so stale results from the old engine are never shown.
- **Favorite button now targets the correct history entry** — The star button in the result area previously used `entries.first`, which could match the wrong entry if the list was updated concurrently. It now tracks `currentEntryID` (a `UUID` returned by `HistoryStore.add()`) and looks up the exact entry by ID.
- **500-character input limit is now enforced** — The limit was displayed in the UI but never actually enforced. Input is now truncated in `inputText.didSet`. The character counter turns red when you approach 450 characters.

### Added

- **Selection button toggle in Settings** — The floating "Translate" button that appears when you select text can now be turned on or off from Settings → General. The preference is persisted across launches. `SelectionButtonController` is now a singleton.
- **Network status awareness** — A new `NetworkMonitor` (backed by `NWPathMonitor`) detects connectivity in real time. When offline, translation requests fail immediately with a clear error instead of timing out after 10 seconds. A banner appears at the top of the Translate tab when the network is unavailable (cached translations still work).

### Changed

- **System TTS is now the primary speech engine** — `SpeechService` previously called the unofficial Google TTS endpoint first, which could be blocked or rate-limited. It now checks whether `AVSpeechSynthesisVoice` supports the target language and uses the system synthesizer directly. Google TTS is kept as a fallback, with a final fallback to English system voice if the network call fails.

---

## [v0.2.0] — Full Feature Iteration

> Focus: Transform the MVP into a complete daily-use tool with history, multi-engine support, and smarter UX.

### Added

- **Translation history** — Every translation is saved locally (up to 50 entries). The History tab shows source text, translated text, language pair, and relative timestamp. Entries can be favorited (⭐) or deleted individually. The full history can be exported as a CSV file.
- **Multi-language support** — Added 8 target languages beyond Chinese/English: Japanese 🇯🇵, Korean 🇰🇷, French 🇫🇷, Spanish 🇪🇸, German 🇩🇪, Portuguese 🇧🇷, Russian 🇷🇺. Language selection is persisted across launches.
- **DeepL engine** — Integrate DeepL API (Free and Pro tiers). Requires a DeepL API key entered in Settings.
- **OpenAI engine** — Integrate OpenAI `gpt-4o-mini` for context-aware translations. Requires an OpenAI API key.
- **Engine switcher in Settings** — Choose between MyMemory (free, no key), DeepL, and OpenAI. API keys are stored securely in `UserDefaults`.
- **LRU translation cache** — A thread-safe 100-entry LRU cache (`TranslationCache`) avoids redundant API calls for repeated queries.
- **Input debounce** — Typing in the panel triggers translation after a 400 ms pause, reducing unnecessary API calls.
- **Launch at login** — Toggle in Settings → General to start Lingo automatically on login, powered by `SMAppService`.
- **Selection floating button** — After selecting text in any app, a small "译" button appears near the cursor. Clicking it translates the selection and shows the floating result window. Implemented via `NSEvent` global monitor + Accessibility API.
- **Menu bar preview** — After a translation completes, the first 12 characters of the result briefly appear next to the menu bar icon.
- **Quit button** — Added a "Quit Lingo" button in Settings so the app can be fully exited without going to the Dock or Force Quit.
- **Three-tab panel** — The menu bar panel is reorganized into Translate / History / Settings tabs.

### Changed

- Floating result window now auto-dismisses after 3 seconds with a fade-out animation.
- Error messages are more specific: rate limit, missing API key, empty result, and network failure are each reported separately.

---

## [v0.1.0] — MVP

> The first working version. Core translation loop only.

### Added

- **Menu bar app** — Runs as a `MenuBarExtra` with no Dock icon. The menu bar icon shows a speech bubble (`character.bubble`).
- **Global hotkey** (`⌥⌘J`) — Registered via `CGEvent` tap. Reads the selected text from the focused element using the Accessibility API (`AXSelectedText`). Triggers translation immediately.
- **MyMemory translation** — Calls the free `api.mymemory.translated.net` endpoint. No API key required.
- **Auto language detection** — Detects Chinese characters (Unicode range U+4E00–U+9FFF) to decide the translation direction (`zh|en` or `en|zh`).
- **Floating result window** — An `NSPanel` appears near the cursor showing the translated text. Supports text selection and one-click copy.
- **Menu bar panel** — Click the icon to open a panel for manual text input with real-time translation.
- **Text-to-speech** — Speak source or translated text using `AVSpeechSynthesizer`.
- **Customizable hotkey** — A settings popover lets you record a new key combination.
- **Accessibility permission prompt** — On first launch, guides the user to grant the required Accessibility permission.
- **Unit tests** — Basic tests for `TranslationService`, `HotkeyManager`, and `SpeechService`.

---

*For the full commit history, see the [GitHub repository](https://github.com/Ivanyanqi/Lingo).*
