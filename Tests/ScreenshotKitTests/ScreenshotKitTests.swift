// Tests/ScreenshotKitTests/ScreenshotKitTests.swift

import XCTest
@testable import ScreenshotKit

final class ScreenshotKitTests: XCTestCase {
    
    var screenshotKit: ScreenshotKit!
    
    override func setUpWithError() throws {
        screenshotKit = ScreenshotKit.shared
    }
    
    override func tearDownWithError() throws {
        screenshotKit = nil
    }
    
    // MARK: - 配置测试
    
    func testDefaultConfiguration() throws {
        let config = ScreenshotConfig()
        
        XCTAssertTrue(config.autoCopyToClipboard)
        XCTAssertFalse(config.autoSaveToFile)
        XCTAssertEqual(config.imageFormat, .png)
        XCTAssertEqual(config.imageQuality, 1.0)
        XCTAssertEqual(config.selectionBorderWidth, 2.0)
    }
    
    func testConfigurationCustomization() throws {
        var config = ScreenshotConfig()
        config.autoCopyToClipboard = false
        config.autoSaveToFile = true
        config.imageFormat = .jpeg
        config.imageQuality = 0.8
        
        XCTAssertFalse(config.autoCopyToClipboard)
        XCTAssertTrue(config.autoSaveToFile)
        XCTAssertEqual(config.imageFormat, .jpeg)
        XCTAssertEqual(config.imageQuality, 0.8)
    }
    
    // MARK: - 图像格式测试
    
    func testImageFormatExtensions() throws {
        XCTAssertEqual(ImageFormat.png.fileExtension, "png")
        XCTAssertEqual(ImageFormat.jpeg.fileExtension, "jpg")
        XCTAssertEqual(ImageFormat.tiff.fileExtension, "tiff")
    }
    
    // MARK: - 剪贴板测试
    
    func testClipboardOperations() throws {
        let testText = "Test clipboard content"
        
        // 测试文本复制
        ClipboardHelper.copyText(testText)
        let retrievedText = ClipboardHelper.getText()
        XCTAssertEqual(retrievedText, testText)
    }
    
    // MARK: - 错误处理测试
    
    func testScreenshotErrorDescriptions() throws {
        let permissionError = ScreenshotError.permissionDenied
        XCTAssertNotNil(permissionError.errorDescription)
        
        let cancelledError = ScreenshotError.cancelled
        XCTAssertNotNil(cancelledError.errorDescription)
        
        let inProgressError = ScreenshotError.alreadyInProgress
        XCTAssertNotNil(inProgressError.errorDescription)
    }
    
    // MARK: - 结果测试
    
    func testScreenshotResultSuccess() throws {
        let testImage = NSImage(size: NSSize(width: 100, height: 100))
        let testRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        let result = ScreenshotResult.success(image: testImage, area: testRect)
        
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.image)
        XCTAssertEqual(result.area, testRect)
        XCTAssertNil(result.error)
    }
    
    func testScreenshotResultFailure() throws {
        let result = ScreenshotResult.failure(.cancelled)
        
        XCTAssertFalse(result.success)
        XCTAssertNil(result.image)
        XCTAssertEqual(result.area, .zero)
        XCTAssertNotNil(result.error)
    }
    
    // MARK: - 快捷键测试
    
    func testKeyboardShortcut() throws {
        let shortcut = KeyboardShortcut(key: .escape, modifiers: [.command, .shift])
        
        XCTAssertEqual(shortcut.key, .escape)
        XCTAssertTrue(shortcut.modifiers.contains(.command))
        XCTAssertTrue(shortcut.modifiers.contains(.shift))
    }
    
    // MARK: - 扩展测试
    
    func testCGRectExtensions() throws {
        let emptyRect = CGRect.zero
        XCTAssertTrue(emptyRect.isEmpty)
        
        let nonEmptyRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        XCTAssertFalse(nonEmptyRect.isEmpty)
        
        let center = nonEmptyRect.center
        XCTAssertEqual(center.x, 50)
        XCTAssertEqual(center.y, 50)
    }
    
    func testNSImageExtensions() throws {
        let testImage = NSImage(size: NSSize(width: 100, height: 100))
        
        // 测试PNG表示
        let pngData = testImage.pngRepresentation
        XCTAssertNotNil(pngData)
        
        // 测试JPEG表示
        let jpegData = testImage.jpegRepresentation(quality: 0.8)
        XCTAssertNotNil(jpegData)
    }
}