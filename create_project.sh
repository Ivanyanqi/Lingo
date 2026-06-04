#!/bin/bash
# 生成 TranslatorBar Xcode 项目结构
set -e

BASE="/Users/yanqi/Documents/onlyspace/TranslatorBar"
APP="$BASE/TranslatorBar"
TESTS="$BASE/TranslatorBarTests"
PROJ="$BASE/TranslatorBar.xcodeproj"

mkdir -p "$APP/Core" "$APP/Views" "$APP/Assets.xcassets/AppIcon.appiconset" "$TESTS" "$PROJ/project.xcworkspace"

# ── Info.plist ──────────────────────────────────────────────────────────────
cat > "$APP/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>TranslatorBar</string>
    <key>CFBundleIdentifier</key>
    <string>ivanqi.TranslatorBar</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAccessibilityUsageDescription</key>
    <string>TranslatorBar 需要辅助功能权限以支持全局快捷键翻译选中文字。</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# ── Entitlements ─────────────────────────────────────────────────────────────
cat > "$APP/TranslatorBar.entitlements" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
EOF

# ── Assets ───────────────────────────────────────────────────────────────────
cat > "$APP/Assets.xcassets/Contents.json" << 'EOF'
{ "info": { "author": "xcode", "version": 1 } }
EOF
cat > "$APP/Assets.xcassets/AppIcon.appiconset/Contents.json" << 'EOF'
{ "images": [], "info": { "author": "xcode", "version": 1 } }
EOF

# ── workspace ────────────────────────────────────────────────────────────────
cat > "$PROJ/project.xcworkspace/contents.xcworkspacedata" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace version = "1.0">
   <FileRef location = "self:">
   </FileRef>
</Workspace>
EOF

echo "✅ 目录结构和配置文件创建完成"
ls -R "$BASE"
