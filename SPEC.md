# TranslatePopup - macOS 沉浸式翻译工具

## 核心需求
当用户在任意应用中选中英文文字时，在鼠标指针右上角弹出翻译结果窗口，无需切换应用。

## 技术架构

### 1. 文本选择检测
- 使用 macOS Accessibility API (AXUIElement)
- 监听全局鼠标松开事件 (CGEvent mouseUp)
- 获取当前焦点元素的 selectedText 属性

### 2. 翻译引擎
优先级：
1. Apple Translation Framework (macOS 12+，支持英译中)
2. 备选：调用在线翻译 API

### 3. 弹窗 UI
- 使用 NSPanel（浮动面板）
- 位置：鼠标指针右上方
- 样式：半透明背景，圆角，阴影
- 行为：
  - 鼠标移出区域时自动关闭
  - 点击其他地方自动关闭
  - 支持复制翻译结果

### 4. 应用形态
- Menu Bar App（菜单栏应用）
- 菜单栏图标可切换开关
- 不占用 Dock 位置

## 技术实现要点

### 权限要求
- 辅助功能权限 (Accessibility)：用于读取其他应用的选中文本

### 性能要求
- 翻译响应 < 500ms
- 不影响原应用流畅度
- 低内存占用

### 文件结构
```
TranslatePopup/
├── Sources/
│   ├── main.swift              # 应用入口
│   ├── AppDelegate.swift       # 应用代理
│   ├── SelectionMonitor.swift  # 文本选择监听
│   ├── TranslationService.swift # 翻译服务
│   ├── PopupWindow.swift       # 弹窗 UI
│   └── AccessibilityHelper.swift # 辅助功能工具
├── Package.swift
└── README.md
```

## 编译与运行
```bash
cd ~/projects/TranslatePopup
swift build
# 或直接编译
swiftc -o TranslatePopup Sources/*.swift -framework Cocoa -framework ApplicationServices -framework CoreGraphics
./TranslatePopup
```

## 注意事项
- 首次运行需要用户授权辅助功能权限
- 某些应用（如 Terminal）可能不支持 Accessibility API 获取选中文本
- 翻译服务需要网络连接（除非使用离线方案）
