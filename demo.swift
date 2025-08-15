#!/usr/bin/env swift

import Foundation

// 这是一个简单的演示脚本，展示如何使用ScreenshotKit

print("ScreenshotKit 演示")
print("==================")

print("✓ ScreenshotKit 已准备就绪")
print("")
print("主要功能：")
print("- 智能选区：支持鼠标拖拽选择截图区域")
print("- 选区调整：8个调整手柄，可精确调整选区大小和位置")
print("- 选区移动：支持拖拽移动整个选区")
print("- 自动复制：截图完成后自动复制到剪贴板")
print("- 自动保存：支持PNG、JPEG、TIFF格式，可配置保存路径")
print("- 快捷键支持：支持全局快捷键触发截图")
print("- 多屏幕支持：完美支持多显示器环境")
print("")
print("使用方法：")
print("1. 在Xcode项目中添加ScreenshotKit依赖")
print("2. 导入模块：import ScreenshotKit")
print("3. 获取实例：let screenshotKit = ScreenshotKit.shared")
print("4. 开始截图：screenshotKit.startScreenshot { result in ... }")
print("")
print("示例代码：")
print("""
import ScreenshotKit

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
            print("截图成功！尺寸: \\(image.size)")
        }
    case false:
        if let error = result.error {
            print("截图失败: \\(error.localizedDescription)")
        }
    }
}
""")
print("")
print("快捷键：")
print("- Esc：取消截图")
print("- Enter/Space：确认截图")
print("- Cmd+Shift+4：全局快捷键（可配置）")
print("")
print("权限要求：")
print("- 屏幕录制权限：用于捕获屏幕内容")
print("- 辅助功能权限：用于全局快捷键监听")
print("")
print("演示完成！")
