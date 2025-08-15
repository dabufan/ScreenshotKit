// Tests/ScreenshotKitTests/ScreenshotKitTests.swift

import XCTest
import ScreenshotKit
@testable import ScreenshotKit

@MainActor
final class ScreenshotKitTests: XCTestCase {
    
    var screenshotKit: ScreenshotKit!
    
    override func setUpWithError() throws {
        screenshotKit = ScreenshotKit.shared
    }
    
    override func tearDownWithError() throws {
        // 清理资源
    }
    
    func testScreenshotKitSingleton() throws {
        // 测试单例模式
        let instance1 = ScreenshotKit.shared
        let instance2 = ScreenshotKit.shared
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testDefaultConfig() throws {
        // 测试默认配置
        let config = ScreenshotConfig()
        
        XCTAssertEqual(config.overlayColor, NSColor.black.withAlphaComponent(0.3))
        XCTAssertEqual(config.selectionBorderColor, .systemBlue)
        XCTAssertEqual(config.selectionBorderWidth, 2.0)
        XCTAssertTrue(config.showCrosshairCursor)
        XCTAssertTrue(config.showDimensions)
        XCTAssertTrue(config.autoCopyToClipboard)
        XCTAssertFalse(config.autoSaveToFile)
        XCTAssertEqual(config.imageFormat, .png)
        XCTAssertEqual(config.imageQuality, 1.0)
    }
    
    func testImageFormatExtensions() throws {
        // 测试图片格式扩展
        XCTAssertEqual(ImageFormat.png.fileExtension, "png")
        XCTAssertEqual(ImageFormat.jpeg.fileExtension, "jpg")
        XCTAssertEqual(ImageFormat.tiff.fileExtension, "tiff")
    }
    
    func testKeyCodeValues() throws {
        // 测试按键代码值
        XCTAssertEqual(KeyCode.escape.rawValue, 53)
        XCTAssertEqual(KeyCode.`return`.rawValue, 36)
        XCTAssertEqual(KeyCode.space.rawValue, 49)
        XCTAssertEqual(KeyCode.four.rawValue, 21)
    }
    
    func testKeyboardShortcut() throws {
        // 测试快捷键结构体
        let shortcut = KeyboardShortcut(key: .four, modifiers: [.command, .shift])
        XCTAssertEqual(shortcut.key, .four)
        XCTAssertEqual(shortcut.modifiers, [.command, .shift])
    }
    
    func testScreenshotResultSuccess() throws {
        // 测试成功结果
        let image = NSImage(size: NSSize(width: 100, height: 100))
        let area = CGRect(x: 0, y: 0, width: 100, height: 100)
        let result = ScreenshotResult.success(image: image, area: area)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.image, image)
        XCTAssertEqual(result.area, area)
        XCTAssertNil(result.error)
        XCTAssertNil(result.filePath)
    }
    
    func testScreenshotResultFailure() throws {
        // 测试失败结果
        let error = ScreenshotError.permissionDenied
        let result = ScreenshotResult.failure(error)
        
        XCTAssertFalse(result.success)
        XCTAssertNil(result.image)
        XCTAssertEqual(result.area, .zero)
        XCTAssertNotNil(result.error)
        XCTAssertNil(result.filePath)
    }
    
    func testScreenshotErrorDescriptions() throws {
        // 测试错误描述
        XCTAssertNotNil(ScreenshotError.permissionDenied.errorDescription)
        XCTAssertNotNil(ScreenshotError.cancelled.errorDescription)
        XCTAssertNotNil(ScreenshotError.alreadyInProgress.errorDescription)
    }
    
    func testCGRectExtensions() throws {
        // 测试CGRect扩展
        let rect = CGRect(x: 10, y: 20, width: 100, height: 200)
        
        XCTAssertFalse(rect.isRectEmpty)
        XCTAssertEqual(rect.center, CGPoint(x: 60, y: 120))
        XCTAssertEqual(rect.nsRect, NSRect(x: 10, y: 20, width: 100, height: 200))
    }
    
    func testEmptyRect() throws {
        // 测试空矩形
        let emptyRect = CGRect.zero
        XCTAssertTrue(emptyRect.isRectEmpty)
    }
    
    func testPerformanceExample() throws {
        // 性能测试示例
        measure {
            // 这里可以添加性能测试代码
            let config = ScreenshotConfig()
            _ = config.overlayColor
        }
    }
}