# Lingo

一款轻量的 macOS 菜单栏翻译工具。选中文字，按下快捷键，即刻获得翻译结果——支持 MyMemory、DeepL 和 OpenAI 三种引擎，不用时完全不打扰你。

[English](README.md) · [版本迭代记录](CHANGELOG_CN.md)

---

## 功能特性

- **原生菜单栏** — 安静地住在菜单栏里，不占 Dock 空间
- **全局快捷键** — 在任意应用中选中文字，按 `⌥⌘J` 立即翻译
- **划词悬浮按钮** — 选中文字后光标旁出现「译」按钮，无需键盘即可触发翻译
- **自动语言检测** — 自动识别中英文方向，无需手动切换
- **多语言支持** — 支持翻译到中文、英文、日语、韩语、法语、西班牙语、德语、葡萄牙语、俄语
- **多翻译引擎** — 可在设置中切换 MyMemory（免费）、DeepL、OpenAI 三种引擎
- **翻译历史记录** — 本地保存最近 50 条翻译，落盘加密，支持收藏和 CSV 导出
- **LRU 缓存** — 相同文本直接从缓存返回，无需重复请求 API
- **悬浮结果窗口** — 翻译结果浮现在光标附近，3 秒后自动淡出
- **文字转语音** — 支持朗读原文和译文（系统 TTS，离线可用）
- **开机自启动** — 可选，基于 `SMAppService` 登录时自动启动
- **网络状态感知** — 断网时立即提示，已缓存的翻译仍可正常使用
- **自定义快捷键** — 可将快捷键改为任意你喜欢的组合
- **隐私加固** — API Key 存入 Keychain、剪贴板回退后自动恢复、应用启用沙盒隔离

## 系统要求

- macOS 14（Sonoma）或更高版本
- 辅助功能权限（全局快捷键和划词按钮所必需）

## 安装

1. 从 [Releases](https://github.com/Ivanyanqi/Lingo/releases) 页面下载最新版本
2. 解压后将 `Lingo.app` 移动到 `/Applications` 文件夹
3. 启动 Lingo，菜单栏会出现一个气泡图标
4. 按提示在「系统设置 → 隐私与安全性 → 辅助功能」中授予权限

## 使用方法

**快捷键翻译**

1. 在任意应用中选中文字
2. 按下 `⌥⌘J`（Option + Command + J）
3. 翻译结果以悬浮窗形式出现在光标附近

**划词悬浮按钮**

1. 在任意应用中选中文字
2. 光标旁出现「译」小按钮
3. 点击按钮，翻译结果立即弹出

**菜单栏面板**

点击菜单栏图标打开面板，包含三个 Tab：

- **翻译** — 输入或粘贴文字，实时查看翻译结果
- **历史** — 浏览、收藏、重新翻译历史记录，支持导出 CSV
- **设置** — 选择翻译引擎、管理 API Key、配置快捷键、开关开机自启和划词按钮

**切换目标语言**

点击翻译 Tab 左上角的语言标签（如 `中文 → EN`）打开语言选择器。

**切换翻译引擎**

进入设置 → 翻译引擎，选择 MyMemory（无需 Key）、DeepL 或 OpenAI，按需填写 API Key。

## 项目结构

```
Lingo/
├── Lingo/
│   ├── Core/
│   │   ├── HotkeyManager.swift              # 基于 CGEvent tap 的全局快捷键
│   │   ├── TranslationService.swift         # MyMemory / DeepL / OpenAI 客户端
│   │   ├── TranslationViewModel.swift       # 响应式状态、防抖、缓存
│   │   ├── TranslationCache.swift           # 线程安全 LRU 缓存
│   │   ├── HistoryStore.swift               # 本地历史持久化
│   │   ├── TargetLanguage.swift             # 支持语言枚举
│   │   ├── SelectionButtonController.swift  # 划词悬浮翻译按钮
│   │   ├── LaunchAtLoginManager.swift       # SMAppService 封装
│   │   ├── NetworkMonitor.swift             # NWPathMonitor 封装
│   │   └── SpeechService.swift              # 系统 TTS（AVSpeechSynthesizer）
│   └── Views/
│       ├── MenuBarPanelView.swift           # 三 Tab 菜单栏面板
│       ├── FloatingResultView.swift         # 悬浮翻译窗口
│       ├── FloatingWindowController.swift   # NSPanel 控制器
│       └── HotkeySettingsView.swift         # 快捷键录制界面
└── LingoTests/                              # 单元测试
```

## 从源码构建

```bash
git clone https://github.com/Ivanyanqi/Lingo.git
cd Lingo
open Lingo.xcodeproj
```

选择 **Lingo** Scheme，按 `⌘R` 构建并运行。

## 版本迭代记录

完整的版本历史请查看 [CHANGELOG_CN.md](CHANGELOG_CN.md)，英文版请查看 [CHANGELOG.md](CHANGELOG.md)。

| 版本 | 主要内容 |
|------|---------|
| [v0.4.0](CHANGELOG_CN.md#v040--安全与隐私加固) | App Sandbox、Keychain API Key、历史加密、仅系统 TTS、更安全的剪贴板与 CSV 导出 |
| [v0.3.0](CHANGELOG_CN.md#v030--bug-修复与体验打磨) | 引擎切换立即生效、收藏按钮精确匹配、500 字符上限、划词按钮开关、网络感知、系统 TTS 优先 |
| [v0.2.0](CHANGELOG_CN.md#v020--全面功能迭代) | 翻译历史、多语言、DeepL/OpenAI 引擎、LRU 缓存、防抖、开机自启、划词按钮、退出按钮 |
| [v0.1.0](CHANGELOG_CN.md#v010--mvp-最小可用版本) | 菜单栏应用、全局快捷键、MyMemory 翻译、悬浮窗、TTS、自定义快捷键 |

## 隐私说明

Lingo 不收集任何个人数据。你翻译的文字会通过 HTTPS 发送至你所选择的翻译 API（MyMemory、DeepL 或 OpenAI）。API Key 仅保存在本机 macOS Keychain 中；翻译历史仅保存在本地应用数据目录，并以加密形式落盘；文字朗读只使用系统 TTS，不再把文本发送到第三方语音服务；若需要使用剪贴板回退方案，Lingo 会在读取后恢复原有剪贴板内容。

## 开源协议

MIT
