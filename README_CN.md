# Lingo

一款轻量的 macOS 菜单栏翻译工具。选中文字，按下快捷键，即刻获得翻译结果，不用时完全不打扰你。

[English](README.md)

---

## 功能特性

- **原生菜单栏** — 安静地住在菜单栏里，不占 Dock 空间
- **全局快捷键** — 在任意应用中选中文字，按 `⌥⌘J` 立即翻译
- **自动语言检测** — 自动识别中英文方向，无需手动切换
- **悬浮结果窗口** — 翻译结果浮现在光标附近，无需切换上下文
- **文字转语音** — 支持朗读原文和译文
- **自定义快捷键** — 可将快捷键改为任意你喜欢的组合
- **基于 MyMemory** — 免费翻译 API，无需注册账号或填写 API Key

## 系统要求

- macOS 14（Sonoma）或更高版本
- 辅助功能权限（全局快捷键所必需）

## 安装

1. 从 [Releases](https://github.com/Ivanyanqi/Lingo/releases) 页面下载最新版本
2. 解压后将 `Lingo.app` 移动到 `/Applications` 文件夹
3. 启动 Lingo，菜单栏会出现一个气泡图标
4. 按提示在「系统设置 → 隐私与安全性 → 辅助功能」中授予权限

## 使用方法

**快捷键翻译**

1. 在任意应用中选中文字
2. 按下 `⌥⌘J`（Option + Command + J）
3. 翻译结果以悬浮窗形式出现

**菜单栏面板**

点击菜单栏图标打开面板，直接输入或粘贴文字，实时查看翻译结果。

**切换翻译方向**

点击面板右上角的语言标签（如 `中文 ⇄ English`）可切换翻译方向。

**自定义快捷键**

点击面板底部的齿轮图标 `⚙` 打开快捷键设置。

## 项目结构

```
Lingo/
├── Lingo/
│   ├── Core/
│   │   ├── HotkeyManager.swift        # 基于 CGEvent tap 的全局快捷键
│   │   ├── TranslationService.swift   # MyMemory API 客户端
│   │   ├── TranslationViewModel.swift # 状态管理
│   │   └── SpeechService.swift        # 文字转语音
│   └── Views/
│       ├── MenuBarPanelView.swift      # 菜单栏主面板
│       ├── FloatingResultView.swift    # 悬浮翻译窗口
│       ├── FloatingWindowController.swift
│       └── HotkeySettingsView.swift
└── LingoTests/                        # 单元测试
```

## 从源码构建

```bash
git clone https://github.com/Ivanyanqi/Lingo.git
cd Lingo
open Lingo.xcodeproj
```

选择 **Lingo** Scheme，按 `⌘R` 构建并运行。

## 隐私说明

Lingo 不收集任何个人数据。你翻译的文字会通过 HTTPS 发送至 [MyMemory](https://mymemory.translated.net) 公共 API，无需账号，无需 API Key。

## 开源协议

MIT
