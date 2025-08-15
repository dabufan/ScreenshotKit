// Sources/ScreenshotKit/Core/ScreenCapture.swift

import Foundation
import AppKit
import CoreGraphics

/// 屏幕捕获核心类
public class ScreenCapture {
    
    /// 捕获整个屏幕
    /// - Returns: 屏幕截图
    public static func captureScreen() throws -> NSImage {
        guard let displayID = CGMainDisplayID() as CGDirectDisplayID?,
              let cgImage = CGDisplayCreateImage(displayID) else {
            throw ScreenshotError.captureFailure(NSError(domain: "ScreenCapture", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to capture screen"]))
        }
        
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }
    
    /// 捕获指定区域
    /// - Parameter rect: 捕获区域（屏幕坐标系）
    /// - Returns: 区域截图
    public static func captureArea(_ rect: CGRect) throws -> NSImage {
        // 获取主屏幕
        guard let mainScreen = NSScreen.main else {
            throw ScreenshotError.captureFailure(NSError(domain: "ScreenCapture", code: 5, userInfo: [NSLocalizedDescriptionKey: "No main screen found"]))
        }
        
        let displayID = mainScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! CGDirectDisplayID
        
        guard let cgImage = CGDisplayCreateImage(displayID) else {
            throw ScreenshotError.captureFailure(NSError(domain: "ScreenCapture", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to capture specific screen"]))
        }
        
        // 转换坐标系（macOS坐标系原点在左下角，CGImage坐标系原点在左上角）
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
    
    /// 捕获多屏幕区域
    /// - Parameter rect: 捕获区域（全局坐标系）
    /// - Returns: 区域截图
    public static func captureMultiScreenArea(_ rect: CGRect) throws -> NSImage {
        // 获取所有屏幕
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            throw ScreenshotError.captureFailure(NSError(domain: "ScreenCapture", code: 6, userInfo: [NSLocalizedDescriptionKey: "No screens found"]))
        }
        
        // 如果只有一个屏幕，使用单屏幕捕获
        if screens.count == 1 {
            return try captureArea(rect)
        }
        
        // 多屏幕情况下的处理
        var capturedImages: [NSImage] = []
        
        for screen in screens {
            let screenFrame = screen.frame
            let intersection = rect.intersection(screenFrame)
            
            if !intersection.isEmpty {
                // 转换到屏幕本地坐标系
                let localRect = CGRect(
                    x: intersection.origin.x - screenFrame.origin.x,
                    y: intersection.origin.y - screenFrame.origin.y,
                    width: intersection.width,
                    height: intersection.height
                )
                
                let screenImage = try captureScreen(screen)
                if let croppedImage = screenImage.cropped(to: localRect) {
                    capturedImages.append(croppedImage)
                }
            }
        }
        
        // 合并多屏幕截图
        return try mergeImages(capturedImages, in: rect)
    }
    
    /// 合并多张图片
    /// - Parameters:
    ///   - images: 图片数组
    ///   - rect: 目标区域
    /// - Returns: 合并后的图片
    private static func mergeImages(_ images: [NSImage], in rect: CGRect) throws -> NSImage {
        let mergedImage = NSImage(size: rect.size)
        
        mergedImage.lockFocus()
        
        for image in images {
            image.draw(in: NSRect(origin: .zero, size: image.size))
        }
        
        mergedImage.unlockFocus()
        
        return mergedImage
    }
}