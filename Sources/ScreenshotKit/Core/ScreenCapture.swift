// Sources/ScreenshotKit/Core/ScreenCapture.swift

import Foundation
import AppKit
import CoreGraphics

/// 屏幕捕获核心类
public class ScreenCapture {
    
    /// 捕获整个屏幕
    /// - Returns: 屏幕截图
    public static func captureScreen() throws -> NSImage {
        guard let displayID = CGMainDisplayID(),
              let cgImage = CGDisplayCreateImage(displayID) else {
            throw ScreenshotError.captureFailure(NSError(domain: "ScreenCapture", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to capture screen"]))
        }
        
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }
    
    /// 捕获指定区域
    /// - Parameter rect: 捕获区域
    /// - Returns: 区域截图
    public static func captureArea(_ rect: CGRect) throws -> NSImage {
        let fullImage = try captureScreen()
        return try cropImage(fullImage, to: rect)
    }
    
    /// 捕获指定屏幕
    /// - Parameter screen: 目标屏幕
    /// - Returns: 屏幕截图
    public static func captureScreen(_ screen: NSScreen) throws -> NSImage {
        let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! CGDirectDisplayID
        
        guard let cgImage = CGDisplayCreateImage(displayID) else {
            throw ScreenshotError.captureFailure(NSError(domain: "ScreenCapture", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to capture specific screen"]))
        }
        
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }
    
    /// 裁剪图片
    /// - Parameters:
    ///   - image: 原始图片
    ///   - rect: 裁剪区域
    /// - Returns: 裁剪后的图片
    private static func cropImage(_ image: NSImage, to rect: CGRect) throws -> NSImage {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ScreenshotError.captureFailure(NSError(domain: "ScreenCapture", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to get CGImage"]))
        }
        
        // 转换坐标系（macOS坐标系原点在左下角）
        let flippedRect = CGRect(
            x: rect.origin.x,
            y: CGFloat(cgImage.height) - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
        
        guard let croppedCGImage = cgImage.cropping(to: flippedRect) else {
            throw ScreenshotError.captureFailure(NSError(domain: "ScreenCapture", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to crop image"]))
        }
        
        let size = NSSize(width: croppedCGImage.width, height: croppedCGImage.height)
        return NSImage(cgImage: croppedCGImage, size: size)
    }
}