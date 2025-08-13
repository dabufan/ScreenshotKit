// Sources/ScreenshotKit/ScreenshotKit.swift

import Foundation
import AppKit
import Combine
import CoreGraphics

/// The main API class for ScreenshotKit.
@MainActor
public class ScreenshotKit: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = ScreenshotKit()
    
    // MARK: - Configuration
    @Published public var config = ScreenshotConfig()
    
    // MARK: - State
    @Published public private(set) var isScreenshotInProgress = false
    
    // MARK: - Private Properties
    private var overlayWindow: ScreenshotOverlayWindow?
    private var keyboardMonitor: KeyboardMonitor?
    private var globalShortcutMonitor: GlobalShortcutMonitor?
    private var completionHandler: ((ScreenshotResult) -> Void)?
    
    private init() {
        setupKeyboardMonitor()
    }
    
    // MARK: - Public Methods
    
    /// Starts a screenshot session.
    /// - Parameter completion: The callback with the screenshot result.
    public func startScreenshot(completion: @escaping (ScreenshotResult) -> Void) {
        guard !isScreenshotInProgress else {
            completion(ScreenshotResult.failure(.alreadyInProgress))
            return
        }
        
        Task {
            let hasPermission = await requestPermission()
            guard hasPermission else {
                completion(ScreenshotResult.failure(.permissionDenied))
                return
            }

            isScreenshotInProgress = true
            completionHandler = completion

            // Create the overlay window.
            createOverlayWindow()

            // Start monitoring keyboard events.
            keyboardMonitor?.startMonitoring()
        }
    }
    
    /// Cancels the current screenshot session.
    public func cancelScreenshot() {
        guard isScreenshotInProgress else { return }
        
        cleanup()
        completionHandler?(ScreenshotResult.failure(.cancelled))
    }
    
    /// Completes the screenshot.
    /// - Parameter area: The selected area to capture.
    internal func completeScreenshot(area: CGRect) {
        guard isScreenshotInProgress else { return }
        
        // Hide the overlay window.
        overlayWindow?.orderOut(nil)
        
        // Add a short delay to ensure the window is fully hidden before capturing.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.performScreenshot(area: area)
        }
    }
    
    /// Registers a global shortcut to trigger screenshots.
    /// - Parameter shortcut: The keyboard shortcut to register.
    public func registerGlobalShortcut(_ shortcut: KeyboardShortcut) {
        globalShortcutMonitor?.registerShortcut(shortcut) { [weak self] in
            self?.startScreenshot { result in
                // Default handling. This can be extended via a delegate pattern.
                print("Screenshot result: \(result)")
            }
        }
    }
    
    /// Unregisters the global shortcut.
    public func unregisterGlobalShortcut() {
        globalShortcutMonitor?.unregisterShortcut()
    }
    
    // MARK: - Private Methods
    
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
        // Get the union of all screen frames.
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
            
            // Automatically copy the image to the clipboard.
            if config.autoCopyToClipboard {
                ClipboardHelper.copyImage(image)
            }
            
            // Automatically save the image to a file.
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
    
    /// Requests screen recording permission.
    /// - Returns: A boolean indicating whether the permission is granted.
    public func requestPermission() async -> Bool {
        if hasScreenRecordingPermission() {
            return true
        }

        return CGRequestScreenCaptureAccess()
    }

    /// Checks if the user has granted screen recording permission.
    /// - Returns: A boolean indicating whether the permission is granted.
    public func hasScreenRecordingPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }
}

// MARK: - Configuration Struct
public struct ScreenshotConfig {
    // UI Configuration
    public var overlayColor: NSColor = NSColor.black.withAlphaComponent(0.3)
    public var selectionBorderColor: NSColor = .systemBlue
    public var selectionBorderWidth: CGFloat = 2.0
    public var showCrosshairCursor: Bool = true
    public var showDimensions: Bool = true
    
    // Behavior Configuration
    public var autoCopyToClipboard: Bool = true
    public var autoSaveToFile: Bool = false
    public var saveDirectory: URL?
    public var imageFormat: ImageFormat = .png
    public var imageQuality: Float = 1.0
    
    // Shortcut Configuration
    public var cancelKey: KeyCode = .escape
    public var confirmKey: KeyCode = .returnKey
    
    public init() {}
}

// MARK: - Result Type
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

// MARK: - Error Type
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

// MARK: - Supporting Types
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