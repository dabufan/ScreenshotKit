// Sources/ScreenshotKit/ScreenshotKit.swift

import Foundation
import AppKit
import Combine

/// ScreenshotKit 主要API类
@MainActor
public class ScreenshotKit: ObservableObject {
    
    // MARK: - 单例
    public static let shared = ScreenshotKit()
    
    // MARK: - 配置
    @Published public var config = ScreenshotConfig()
    
    // MARK: - 状态
    @Published public private(set) var isScreenshotInProgress = false
    
    // MARK: - 私有属性
    private var overlayWindow: ScreenshotOverlayWindow?
    private var keyboardMonitor: KeyboardMonitor?
    private var globalShortcutMonitor: GlobalShortcutMonitor?
    private var completionHandler: ((ScreenshotResult) -> Void)?
    
    private init() {
        setupKeyboardMonitor()
    }
    
    // MARK: - 公共方法
    
    /// 开始截图
    /// - Parameter completion: 截图完成回调
    public func startScreenshot(completion: @escaping (ScreenshotResult) -> Void) {
        guard !isScreenshotInProgress else {
            completion(ScreenshotResult.failure(.alreadyInProgress))
            return
        }
        
        // 检查权限
        guard checkScreenRecordingPermission() else {
            completion(ScreenshotResult.failure(.permissionDenied))
            return
        }
        
        isScreenshotInProgress = true
        completionHandler = completion
        
        // 创建遮罩窗口
        createOverlayWindow()
        
        // 开始键盘监听
        keyboardMonitor?.startMonitoring()
    }
    
    /// 取消截图
    public func cancelScreenshot() {
        guard isScreenshotInProgress else { return }
        
        cleanup()
        completionHandler?(ScreenshotResult.failure(.cancelled))
    }
    
    /// 完成截图
    /// - Parameter area: 截图区域
    internal func completeScreenshot(area: CGRect) {
        guard isScreenshotInProgress else { return }
        
        // 隐藏遮罩窗口
        overlayWindow?.orderOut(nil)
        
        // 延迟一点时间确保窗口完全隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.performScreenshot(area: area)
        }
    }
    
    /// 注册全局快捷键
    /// - Parameter shortcut: 快捷键配置
    public func registerGlobalShortcut(_ shortcut: KeyboardShortcut) {
        globalShortcutMonitor?.registerShortcut(shortcut) { [weak self] in
            self?.startScreenshot { result in
                // 默认处理，可以通过delegate模式扩展
                print("Screenshot result: \(result)")
            }
        }
    }
    
    /// 注销全局快捷键
    public func unregisterGlobalShortcut() {
        globalShortcutMonitor?.unregisterShortcut()
    }
    
    // MARK: - 私有方法
    
    private func setupKeyboardMonitor() {
        keyboardMonitor = KeyboardMonitor { [weak self] keyCode in
            switch keyCode {
            case .escape:
                self?.cancelScreenshot()
            case .returnKey:
                self?.overlayWindow?.confirmSelection()
            default:
                break
            }
        }
        
        globalShortcutMonitor = GlobalShortcutMonitor()
    }
    
    private func createOverlayWindow() {
        // 获取所有屏幕的联合区域
        let combinedFrame = NSScreen.screens.reduce(CGRect.zero) { result, screen in
            return result.union(screen.frame)
        }
        
        overlayWindow = ScreenshotOverlayWindow(
            contentRect: combinedFrame,
            config: config
        ) { [weak self] area in
            self?.completeScreenshot(area: area)
        }
        
        overlayWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func performScreenshot(area: CGRect) {
        let result: ScreenshotResult
        
        do {
            let image = try ScreenCapture.captureArea(area)
            
            // 自动复制到剪贴板
            if config.autoCopyToClipboard {
                ClipboardHelper.copyImage(image)
            }
            
            // 自动保存到文件
            var filePath: URL?
            if config.autoSaveToFile, let saveDirectory = config.saveDirectory {
                filePath = try ImageProcessor.saveImage(
                    image, 
                    to: saveDirectory, 
                    format: config.imageFormat,
                    quality: config.imageQuality
                )
            }
            
            result = ScreenshotResult.success(
                image: image,
                area: area,
                filePath: filePath
            )
            
        } catch {
            result = ScreenshotResult.failure(.captureFailure(error))
        }
        
        cleanup()
        completionHandler?(result)
    }
    
    private func cleanup() {
        isScreenshotInProgress = false
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        keyboardMonitor?.stopMonitoring()
        completionHandler = nil
    }
    
    private func checkScreenRecordingPermission() -> Bool {
        // 检查屏幕录制权限
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options)
    }
}

// MARK: - 配置结构体
public struct ScreenshotConfig {
    // UI配置
    public var overlayColor: NSColor = NSColor.black.withAlphaComponent(0.3)
    public var selectionBorderColor: NSColor = .systemBlue
    public var selectionBorderWidth: CGFloat = 2.0
    public var showCrosshairCursor: Bool = true
    public var showDimensions: Bool = true
    
    // 行为配置
    public var autoCopyToClipboard: Bool = true
    public var autoSaveToFile: Bool = false
    public var saveDirectory: URL?
    public var imageFormat: ImageFormat = .png
    public var imageQuality: Float = 1.0
    
    // 快捷键配置
    public var cancelKey: KeyCode = .escape
    public var confirmKey: KeyCode = .returnKey
    
    public init() {}
}

// MARK: - 结果类型
public struct ScreenshotResult {
    public let image: NSImage?
    public let area: CGRect
    public let timestamp: Date
    public let success: Bool
    public let error: ScreenshotError?
    public let filePath: URL?
    
    public static func success(image: NSImage, area: CGRect, filePath: URL? = nil) -> ScreenshotResult {
        return ScreenshotResult(
            image: image,
            area: area,
            timestamp: Date(),
            success: true,
            error: nil,
            filePath: filePath
        )
    }
    
    public static func failure(_ error: ScreenshotError) -> ScreenshotResult {
        return ScreenshotResult(
            image: nil,
            area: .zero,
            timestamp: Date(),
            success: false,
            error: error,
            filePath: nil
        )
    }
}

// MARK: - 错误类型
public enum ScreenshotError: Error, LocalizedError {
    case permissionDenied
    case captureFailure(Error)
    case saveFailure(Error)
    case cancelled
    case alreadyInProgress
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Screen recording permission denied"
        case .captureFailure(let error):
            return "Screenshot capture failed: \(error.localizedDescription)"
        case .saveFailure(let error):
            return "Failed to save screenshot: \(error.localizedDescription)"
        case .cancelled:
            return "Screenshot cancelled by user"
        case .alreadyInProgress:
            return "Screenshot already in progress"
        }
    }
}

// MARK: - 支持类型
public enum ImageFormat {
    case png
    case jpeg
    case tiff
    
    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        case .tiff: return "tiff"
        }
    }
}

public enum KeyCode: UInt16 {
    case escape = 53
    case returnKey = 36
    case space = 49
    case four = 21
}

public struct KeyboardShortcut {
    public let key: KeyCode
    public let modifiers: NSEvent.ModifierFlags
    
    public init(key: KeyCode, modifiers: NSEvent.ModifierFlags) {
        self.key = key
        self.modifiers = modifiers
    }
}