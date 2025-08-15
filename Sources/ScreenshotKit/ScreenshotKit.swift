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
    
    // 性能优化：添加性能监控
    @Published public private(set) var lastScreenshotTime: TimeInterval = 0
    @Published public private(set) var averageScreenshotTime: TimeInterval = 0
    @Published public private(set) var totalScreenshots: Int = 0
    
    // MARK: - 私有属性
    private var overlayWindow: ScreenshotOverlayWindow?
    private var keyboardMonitor: KeyboardMonitor?
    private var globalShortcutMonitor: GlobalShortcutMonitor?
    private var completionHandler: ((ScreenshotResult) -> Void)?
    
    // 性能优化：缓存和队列管理
    private let screenshotQueue = DispatchQueue(label: "com.screenshotkit.processing", qos: .userInitiated)
    private var performanceMetrics: [TimeInterval] = []
    private let maxMetricsCount = 10
    
    private init() {
        setupKeyboardMonitor()
        setupPerformanceMonitoring()
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
        
        // 预加载屏幕信息（性能优化）
        ScreenCapture.preloadScreenInfo()
        
        // 创建遮罩窗口
        createOverlayWindow()
        
        // 开始键盘监听
        keyboardMonitor?.startMonitoring()
    }
    
    /// 异步开始截图（性能优化）
    /// - Parameter completion: 截图完成回调
    public func startScreenshotAsync(completion: @escaping (ScreenshotResult) -> Void) {
        DispatchQueue.main.async {
            self.startScreenshot(completion: completion)
        }
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
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 隐藏遮罩窗口
        overlayWindow?.orderOut(nil)
        
        // 延迟一点时间确保窗口完全隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.performScreenshot(area: area, startTime: startTime)
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
    
    /// 清理缓存（性能优化）
    public func clearCache() {
        ScreenCapture.clearCache()
        ImageProcessor.clearCache()
        performanceMetrics.removeAll()
        averageScreenshotTime = 0
        totalScreenshots = 0
    }
    
    /// 获取性能统计（性能监控）
    public func getPerformanceStats() -> PerformanceStats {
        return PerformanceStats(
            totalScreenshots: totalScreenshots,
            averageTime: averageScreenshotTime,
            lastTime: lastScreenshotTime,
            cacheSize: performanceMetrics.count
        )
    }
    
    // MARK: - 私有方法
    
    private func setupKeyboardMonitor() {
        keyboardMonitor = KeyboardMonitor { [weak self] keyCode in
            switch keyCode {
            case .escape:
                self?.cancelScreenshot()
            case .`return`:
                self?.overlayWindow?.confirmSelection()
            case .space:
                self?.overlayWindow?.confirmSelection()
            default:
                break
            }
        }
        
        globalShortcutMonitor = GlobalShortcutMonitor()
    }
    
    private func setupPerformanceMonitoring() {
        // 定期清理旧指标
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cleanupOldMetrics()
            }
        }
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
    
    private func performScreenshot(area: CGRect, startTime: CFAbsoluteTime) {
        let result: ScreenshotResult
        
        do {
            // 使用多屏幕捕获
            let image = try ScreenCapture.captureMultiScreenArea(area)
            
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
        
        // 更新性能指标
        updatePerformanceMetrics(startTime: startTime)
        
        cleanup()
        completionHandler?(result)
    }
    
    private func updatePerformanceMetrics(startTime: CFAbsoluteTime) {
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        lastScreenshotTime = duration
        totalScreenshots += 1
        
        // 添加到性能指标数组
        performanceMetrics.append(duration)
        
        // 限制指标数量
        if performanceMetrics.count > maxMetricsCount {
            performanceMetrics.removeFirst()
        }
        
        // 计算平均时间
        averageScreenshotTime = performanceMetrics.reduce(0, +) / Double(performanceMetrics.count)
    }
    
    private func cleanupOldMetrics() {
        let cutoffTime = CFAbsoluteTimeGetCurrent() - 300 // 5分钟前的数据
        performanceMetrics = performanceMetrics.filter { $0 > cutoffTime }
        
        // 重新计算平均值
        if !performanceMetrics.isEmpty {
            averageScreenshotTime = performanceMetrics.reduce(0, +) / Double(performanceMetrics.count)
        } else {
            averageScreenshotTime = 0
        }
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
    
    // 性能配置
    public var enableAsyncProcessing: Bool = true
    public var enablePerformanceMonitoring: Bool = true
    public var maxImageSize: NSSize = NSSize(width: 4096, height: 4096)
    
    // 快捷键配置
    public var cancelKey: KeyCode = .escape
    public var confirmKey: KeyCode = .`return`
    
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

// MARK: - 性能统计结构体
public struct PerformanceStats {
    public let totalScreenshots: Int
    public let averageTime: TimeInterval
    public let lastTime: TimeInterval
    public let cacheSize: Int
    
    public var formattedAverageTime: String {
        return String(format: "%.3fs", averageTime)
    }
    
    public var formattedLastTime: String {
        return String(format: "%.3fs", lastTime)
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
    case `return` = 36
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