# ScreenshotKit

一个功能强大的macOS截图工具包，支持选区调整、拖拽移动、自动保存和剪贴板复制等功能。

## 功能特性

- 🖱️ **智能选区**：支持鼠标拖拽选择截图区域
- 🔧 **选区调整**：8个调整手柄，可精确调整选区大小和位置
- 📱 **选区移动**：支持拖拽移动整个选区
- 📋 **自动复制**：截图完成后自动复制到剪贴板
- 💾 **自动保存**：支持PNG、JPEG、TIFF格式，可配置保存路径
- ⌨️ **快捷键支持**：支持全局快捷键触发截图
- 🖥️ **多屏幕支持**：完美支持多显示器环境
- 🎨 **可定制UI**：支持自定义颜色、边框宽度等

## 系统要求

- macOS 12.0 或更高版本
- Xcode 14.0 或更高版本
- Swift 5.9 或更高版本

## 安装

### Swift Package Manager

在Xcode项目中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/ScreenshotKit.git", from: "1.0.0")
]
```

或者直接克隆到本地：

```bash
git clone https://github.com/yourusername/ScreenshotKit.git
cd ScreenshotKit
swift build
```

## 使用方法

### 基本用法

```swift
import ScreenshotKit

// 获取单例实例
let screenshotKit = ScreenshotKit.shared

// 配置截图设置
screenshotKit.config.autoCopyToClipboard = true
screenshotKit.config.autoSaveToFile = true
screenshotKit.config.saveDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")

// 开始截图
screenshotKit.startScreenshot { result in
    switch result.success {
    case true:
        if let image = result.image {
            print("截图成功！尺寸: \(image.size)")
        }
    case false:
        if let error = result.error {
            print("截图失败: \(error.localizedDescription)")
        }
    }
}
```

### 配置选项

```swift
// UI配置
screenshotKit.config.overlayColor = NSColor.black.withAlphaComponent(0.3)
screenshotKit.config.selectionBorderColor = .systemBlue
screenshotKit.config.selectionBorderWidth = 2.0
screenshotKit.config.showCrosshairCursor = true
screenshotKit.config.showDimensions = true

// 行为配置
screenshotKit.config.autoCopyToClipboard = true
screenshotKit.config.autoSaveToFile = true
screenshotKit.config.saveDirectory = URL(fileURLWithPath: "/path/to/save")
screenshotKit.config.imageFormat = .png
screenshotKit.config.imageQuality = 1.0
```

### 全局快捷键

```swift
// 注册快捷键 (Cmd+Shift+4)
let shortcut = KeyboardShortcut(
    key: .four,
    modifiers: [.command, .shift]
)
screenshotKit.registerGlobalShortcut(shortcut)

// 注销快捷键
screenshotKit.unregisterGlobalShortcut()
```

### 手动触发

```swift
// 手动开始截图
screenshotKit.startScreenshot { result in
    // 处理结果
}

// 取消截图
screenshotKit.cancelScreenshot()
```

## 截图流程

1. **启动截图**：调用 `startScreenshot()` 或使用快捷键
2. **选择区域**：鼠标拖拽选择截图区域
3. **调整选区**：使用8个调整手柄调整大小，拖拽移动位置
4. **确认截图**：点击"确定"按钮或按回车键确认
5. **自动处理**：截图自动复制到剪贴板，可选择保存到文件

## 操作说明

### 选区操作
- **选择区域**：鼠标拖拽选择
- **调整大小**：拖拽8个调整手柄
- **移动位置**：拖拽选区内部
- **重新选择**：在空白区域点击开始新选择

### 键盘快捷键
- **Esc**：取消截图
- **Enter/Space**：确认截图
- **Cmd+Shift+4**：全局快捷键（可配置）

## 示例应用

项目包含一个完整的示例应用，展示如何使用ScreenshotKit：

```bash
# 构建示例应用
swift build -c release --product ScreenshotExample

# 运行示例应用
.build/release/ScreenshotExample
```

示例应用提供：
- 菜单栏图标
- 快捷键支持
- 自动保存功能
- 系统通知

## 权限要求

ScreenshotKit需要以下系统权限：

1. **屏幕录制权限**：用于捕获屏幕内容
2. **辅助功能权限**：用于全局快捷键监听

首次运行时会自动请求权限，或在系统偏好设置中手动授权。

## 架构设计

```
ScreenshotKit/
├── Core/                 # 核心功能
│   └── ScreenCapture    # 屏幕捕获
├── UI/                  # 用户界面
│   ├── ScreenshotOverlayWindow  # 遮罩窗口
│   └── SelectionView    # 选区视图
├── Utils/               # 工具类
│   ├── ClipboardHelper  # 剪贴板操作
│   ├── ImageProcessor   # 图片处理
│   ├── GlobalShortcutMonitor  # 全局快捷键
│   └── KeyboardMonitor # 键盘监听
└── Extensions/          # 扩展方法
    ├── NSImage+Extensions
    └── CGRect+Extensions
```

## 错误处理

ScreenshotKit提供详细的错误信息：

```swift
public enum ScreenshotError: Error, LocalizedError {
    case permissionDenied      // 权限被拒绝
    case captureFailure(Error) // 捕获失败
    case saveFailure(Error)    // 保存失败
    case cancelled            // 用户取消
    case alreadyInProgress    // 截图进行中
}
```

## 贡献

欢迎提交Issue和Pull Request！

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 更新日志

详见 [CHANGELOG.md](CHANGELOG.md)