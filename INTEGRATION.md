# ScreenshotKit 集成指南

## 在ecopy中使用ScreenshotKit

### 1. 添加Package依赖

#### 方法一：使用Xcode
1. 打开ecopy项目
2. File → Add Package Dependencies
3. 输入：`https://github.com/dabufan/ScreenshotKit.git`
4. 选择版本：Up to Next Major Version: 1.0.0
5. 点击Add Package

#### 方法二：使用Package.swift
```swift
dependencies: [
    .package(url: "https://github.com/dabufan/ScreenshotKit.git", from: "1.0.0")
]
```

### 2. 更新ScreenshotManager.swift

```swift
import ScreenshotKit

class ScreenshotManager: ObservableObject {
    // 替换临时实现
    func startScreenshot() {
        ScreenshotKit.shared.startScreenshot { [weak self] result in
            DispatchQueue.main.async {
                if let image = result.image {
                    self?.handleScreenshotResult(image)
                }
            }
        }
    }
    
    private func setupScreenshot() {
        ScreenshotKit.shared.config.autoCopyToClipboard = true
        ScreenshotKit.shared.config.showDimensions = true
        
        let shortcut = KeyboardShortcut(key: .four, modifiers: [.command, .shift])
        ScreenshotKit.shared.registerGlobalShortcut(shortcut)
    }
}
```

### 3. 清理ecopy项目

删除本地ScreenshotKit目录：
```bash
cd ../ecopy
rm -rf ScreenshotKit/
git add .
git commit -m "🔧 Migrate to independent ScreenshotKit package"
```
