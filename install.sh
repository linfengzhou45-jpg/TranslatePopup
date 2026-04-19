#!/bin/bash

APP_NAME="TranslatePopup"
APP_PATH="$HOME/projects/TranslatePopup/TranslatePopup"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$PLIST_DIR/com.user.translatetranslate.plist"

# 创建 LaunchAgents 目录（如果不存在）
mkdir -p "$PLIST_DIR"

# 创建 plist 文件实现开机自启动
cat > "$PLIST_FILE" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.translatetranslate</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_PATH</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
PLIST

echo "✅ LaunchAgent 已创建: $PLIST_FILE"
echo ""
echo "使用方法:"
echo "  启动: launchctl load $PLIST_FILE"
echo "  停止: launchctl unload $PLIST_FILE"
echo "  删除: launchctl unload $PLIST_FILE && rm $PLIST_FILE"
