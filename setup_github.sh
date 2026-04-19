#!/bin/bash

echo "=========================================="
echo "  TranslatePopup - GitHub 设置向导"
echo "=========================================="
echo ""
echo "此脚本将帮你："
echo "1. 配置 Git 用户信息"
echo "2. 登录 GitHub"
echo "3. 创建仓库并推送代码"
echo ""

# 检查 git 配置
if [ -z "$(git config --global user.name)" ]; then
    echo "请输入你的 GitHub 用户名："
    read -r github_username
    git config --global user.name "$github_username"
    echo "✅ 用户名已设置: $github_username"
else
    github_username=$(git config --global user.name)
    echo "✅ Git 用户名已配置: $github_username"
fi

if [ -z "$(git config --global user.email)" ]; then
    echo "请输入你的 GitHub 邮箱："
    read -r github_email
    git config --global user.email "$github_email"
    echo "✅ 邮箱已设置: $github_email"
else
    github_email=$(git config --global user.email)
    echo "✅ Git 邮箱已配置: $github_email"
fi

echo ""
echo "=========================================="
echo "  开始 GitHub 登录..."
echo "=========================================="
echo ""

# 检查是否已登录
if gh auth status >/dev/null 2>&1; then
    echo "✅ 已经登录 GitHub"
else
    echo "将打开浏览器进行 GitHub 登录..."
    echo "请按照浏览器中的提示完成授权。"
    echo ""
    gh auth login --web -p https
fi

echo ""
echo "=========================================="
echo "  创建 GitHub 仓库..."
echo "=========================================="
echo ""

# 进入项目目录
cd ~/projects/TranslatePopup

# 检查是否已经是 git 仓库
if [ ! -d ".git" ]; then
    echo "初始化 Git 仓库..."
    git init
    echo "✅ Git 仓库已初始化"
fi

# 创建 README.md
cat > README.md << 'README'
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
README

echo "✅ README.md 已创建"

# 添加所有文件到 git
git add -A

# 提交
git commit -m "初始提交：TranslatePopup macOS 沉浸式翻译工具

功能：
- 选中英文文字自动翻译
- 菜单栏应用，支持开机自启
- 中文界面，浮动翻译窗口
- 支持拖动和关闭"

echo ""
echo "=========================================="
echo "  推送到 GitHub..."
echo "=========================================="
echo ""

# 创建 GitHub 仓库
echo "正在创建 GitHub 仓库..."
gh repo create TranslatePopup --public --source=. --remote=origin --push

echo ""
echo "=========================================="
echo "  ✅ 完成！"
echo "=========================================="
echo ""
echo "你的项目已成功推送到 GitHub！"
echo ""
echo "仓库地址："
gh repo view --web
echo ""
echo "管理命令："
echo "  查看仓库: gh repo view --web"
echo "  同步更新: git add -A && git commit -m '更新' && git push"
