// Sources/ScreenshotKit/Examples/ScreenshotExample.swift

import AppKit
import ScreenshotKit
import UserNotifications

/// ScreenshotKit 使用示例
@MainActor
class ScreenshotExample: NSObject {
    
    private let screenshotKit = ScreenshotKit.shared
    
    override init() {
        super.init()
        setupScreenshotKit()
    }
    
    private func setupScreenshotKit() {
        // 配置截图设置
        screenshotKit.config.autoCopyToClipboard = true
        screenshotKit.config.autoSaveToFile = true
        screenshotKit.config.saveDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        screenshotKit.config.imageFormat = .png
        screenshotKit.config.imageQuality = 1.0
        
        // 注册全局快捷键 (Cmd+Shift+4)
        let shortcut = KeyboardShortcut(
            key: .four,
            modifiers: [.command, .shift]
        )
        screenshotKit.registerGlobalShortcut(shortcut)
    }
    
    /// 开始截图
    func startScreenshot() {
        screenshotKit.startScreenshot { [weak self] result in
            self?.handleScreenshotResult(result)
        }
    }
    
    /// 处理截图结果
    private func handleScreenshotResult(_ result: ScreenshotResult) {
        switch result.success {
        case true:
            if let image = result.image {
                print("截图成功！")
                print("区域: \(result.area)")
                print("尺寸: \(image.size)")
                
                if let filePath = result.filePath {
                    print("已保存到: \(filePath.path)")
                }
                
                // 显示成功通知
                showNotification(title: "截图成功", body: "截图已保存并复制到剪贴板")
            }
            
        case false:
            if let error = result.error {
                print("截图失败: \(error.localizedDescription)")
                
                // 显示错误通知
                showNotification(title: "截图失败", body: error.localizedDescription)
            }
        }
    }
    
    /// 显示系统通知
    private func showNotification(title: String, body: String) {
        let notification = UNMutableNotificationContent()
        notification.title = title
        notification.body = body
        notification.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: notification,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知发送失败: \(error)")
            }
        }
    }
}

// MARK: - 菜单栏应用示例

@MainActor
class ScreenshotMenuBarApp: NSObject {
    
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let screenshotKit = ScreenshotKit.shared
    private let example = ScreenshotExample()
    
    override init() {
        super.init()
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        // 设置状态栏图标
        statusItem.button?.title = "📷"
        statusItem.button?.toolTip = "ScreenshotKit"
        
        // 创建菜单
        let menu = NSMenu()
        
        let screenshotItem = NSMenuItem(
            title: "开始截图",
            action: #selector(startScreenshot),
            keyEquivalent: "4"
        )
        screenshotItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(screenshotItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(
            title: "设置",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        menu.addItem(settingsItem)
        
        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc private func startScreenshot() {
        example.startScreenshot()
    }
    
    @objc private func openSettings() {
        // 这里可以打开设置窗口
        print("打开设置...")
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - 主应用入口

@main
struct ScreenshotApp {
    static func main() {
        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("通知权限请求失败: \(error)")
            }
        }
        
        // 创建应用
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        
        // 创建菜单栏应用
        _ = ScreenshotMenuBarApp()
        
        // 运行应用
        app.run()
    }
}
