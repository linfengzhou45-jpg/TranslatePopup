import Cocoa

/// Menu-bar app delegate that manages the status item, monitor lifecycle,
/// and accessibility permission flow.
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    private var statusItem: NSStatusItem!
    private let monitor = SelectionMonitor()
    private var isEnabled = true

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        // No Dock icon.
        NSApp.setActivationPolicy(.accessory)

        setupMenuBar()
        checkAccessibilityAndStart()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    // MARK: - Menu bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "🌐"
            button.toolTip = "沉浸式翻译 — 选中文字即可翻译"
        }
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: isEnabled ? "暂停翻译" : "开启翻译",
            action: #selector(toggleMonitoring),
            keyEquivalent: "t"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let permItem = NSMenuItem(
            title: "检查辅助功能权限…",
            action: #selector(checkPermissions),
            keyEquivalent: ""
        )
        permItem.target = self
        menu.addItem(permItem)

        menu.addItem(.separator())

        menu.addItem(
            withTitle: "退出",
            action: #selector(quit),
            keyEquivalent: "q"
        )

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func toggleMonitoring() {
        isEnabled.toggle()
        if isEnabled {
            checkAccessibilityAndStart()
        } else {
            monitor.stop()
        }
        rebuildMenu()
    }

    @objc    private func checkPermissions() {
        if AccessibilityHelper.isTrusted {
            showPermissionAlert(
                title: "辅助功能权限",
                message: "沉浸式翻译已获得辅助功能权限。"
            )
        } else {
            AccessibilityHelper.requestTrust()
            // Re-check after a short delay to give the user time to approve.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                if AccessibilityHelper.isTrusted {
                    self?.startMonitorIfNeeded()
                    self?.showPermissionAlert(
                        title: "辅助功能权限",
                        message: "权限已授予！沉浸式翻译已启动。"
                    )
                }
            }
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Helpers

    private func checkAccessibilityAndStart() {
        if AccessibilityHelper.isTrusted {
            startMonitorIfNeeded()
        } else {
            AccessibilityHelper.requestTrust()
            // Poll until the user grants access.
            pollForAccessibility()
        }
    }

    private func pollForAccessibility() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self, self.isEnabled else { return }
            if AccessibilityHelper.isTrusted {
                self.startMonitorIfNeeded()
            } else {
                self.pollForAccessibility()
            }
        }
    }

    private func startMonitorIfNeeded() {
        guard isEnabled, !monitor.isRunning else { return }
        let ok = monitor.start()
        if !ok {
            showPermissionAlert(
                title: "事件监听失败",
                message: "无法创建全局事件监听。请确保已在系统设置 → 隐私与安全性 → 辅助功能中授予权限。"
            )
        }
    }

    private func showPermissionAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好的")
        // Activate the app so the alert is visible even in accessory mode.
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
