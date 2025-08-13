# ScreenshotKit

一个现代化的macOS截图框架，提供微信风格的截图体验。

## ✨ 特性

- 🎯 **微信风格界面**: 半透明遮罩 + 清晰选择区域
- ⌨️ **快捷键支持**: 可自定义的全局快捷键
- 📋 **自动复制**: 截图完成后自动复制到剪贴板
- 🖥️ **多显示器支持**: 完美支持多屏幕环境
- 🎨 **高度可定制**: 丰富的配置选项
- 🚀 **高性能**: 优化的屏幕捕获算法

## 🚀 快速开始

### 基本使用

```swift
import ScreenshotKit

// 开始截图
ScreenshotKit.shared.startScreenshot { result in
    switch result.success {
    case true:
        print("截图成功！")
        if let image = result.image {
            // 处理截图
        }
    case false:
        print("截图失败: \(result.error?.localizedDescription ?? "未知错误")")
    }
}
```

### 配置截图参数

```swift
// 自定义配置
ScreenshotKit.shared.config.autoCopyToClipboard = true
ScreenshotKit.shared.config.showDimensions = true
ScreenshotKit.shared.config.selectionBorderColor = .systemBlue
ScreenshotKit.shared.config.imageFormat = .png
```

### 注册全局快捷键

```swift
// 注册 Cmd+Shift+4 快捷键
let shortcut = KeyboardShortcut(key: .four, modifiers: [.command, .shift])
ScreenshotKit.shared.registerGlobalShortcut(shortcut)
```

## 📋 系统要求

- macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## 🔐 权限要求

ScreenshotKit需要屏幕录制权限才能正常工作。

### Info.plist配置

在你的应用的 `Info.plist` 中添加权限说明：

```xml
<key>NSScreenCaptureDescription</key>
<string>此应用需要屏幕录制权限来提供截图功能</string>
```

## 📄 许可证

本项目采用 MIT 许可证。