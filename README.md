# TranslatePopup - macOS 沉浸式翻译工具

一款简洁高效的 macOS 菜单栏应用，选中英文文字即可立即获得翻译，无需切换应用。

## ✨ 特性

- **即时翻译** - 选中文字后自动弹出翻译结果
- **无干扰体验** - 菜单栏应用，不占用 Dock 位置
- **简洁 UI** - 浮动窗口显示翻译结果，可拖动、可关闭
- **中文界面** - 完全中文化的用户界面
- **免费翻译** - 使用 MyMemory API，无需付费
- **开机自启** - 支持设置开机自动启动

## 🚀 安装

### 方式一：从源码编译

```bash
# 克隆仓库
git clone https://github.com/你的用户名/TranslatePopup.git
cd TranslatePopup

# 编译
swiftc -o TranslatePopup Sources/*.swift -framework Cocoa -framework ApplicationServices -framework CoreGraphics

# 运行
./TranslatePopup
```

### 方式二：设置开机自启动

```bash
# 运行安装脚本
./install.sh

# 或手动加载 LaunchAgent
launchctl load ~/Library/LaunchAgents/com.user.translatetranslate.plist
```

## 📋 系统要求

- macOS 13.0+ (Ventura 或更高版本)
- 需要授予「辅助功能」权限

## 🔧 使用说明

1. 点击菜单栏 🌐 图标
2. 在任意应用中选中英文文字
3. 翻译结果会自动出现在鼠标指针附近
4. 点击其他位置或 ✕ 按钮关闭弹窗
5. 拖动弹窗可移动位置

## 📁 项目结构

```
TranslatePopup/
├── Sources/
│   ├── main.swift              # 应用入口
│   ├── AppDelegate.swift       # 菜单栏应用代理
│   ├── SelectionMonitor.swift  # 鼠标选择监听
│   ├── AccessibilityHelper.swift # 辅助功能工具
│   ├── TranslationService.swift # 翻译服务
│   └── PopupWindow.swift       # 浮动弹窗 UI
├── install.sh                  # 安装脚本
└── README.md
```

## 🛠️ 开发

### 编译

```bash
cd ~/projects/TranslatePopup
swiftc -o TranslatePopup Sources/*.swift -framework Cocoa -framework ApplicationServices -framework CoreGraphics
```

### 停止应用

```bash
# 停止 LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.user.translatetranslate.plist

# 或直接杀死进程
pkill -f TranslatePopup
```

### 删除自启动

```bash
launchctl unload ~/Library/LaunchAgents/com.user.translatetranslate.plist
rm ~/Library/LaunchAgents/com.user.translatetranslate.plist
```

## 📄 许可证

MIT License
