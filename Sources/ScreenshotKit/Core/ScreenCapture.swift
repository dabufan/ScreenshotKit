// Sources/ScreenshotKit/Core/ScreenCapture.swift

import Foundation
import AppKit
import CoreGraphics

/// Core class for screen capture.
public class ScreenCapture {
    
    /// Captures the entire screen.
    /// - Returns: An NSImage of the screen.
    public static func captureScreen() throws -> NSImage {
        let displayID = CGMainDisplayID()
        guard let cgImage = CGDisplayCreateImage(displayID) else {
            throw ScreenshotError.captureFailure(NSError(domain: "ScreenCapture", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to capture screen"]))
        }
        
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }
    
    /// Captures a specific area of the screen.
    /// - Parameter rect: The area to capture.
    /// - Returns: An NSImage of the specified area.
    public static func captureArea(_ rect: CGRect) throws -> NSImage {
        let fullImage = try captureScreen()
        return try cropImage(fullImage, to: rect)
    }
    
    /// Captures a specific screen.
    /// - Parameter screen: The target screen to capture.
    /// - Returns: An NSImage of the screen.
    public static func captureScreen(_ screen: NSScreen) throws -> NSImage {
        let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! CGDirectDisplayID
        guard let cgImage = CGDisplayCreateImage(displayID) else {
            throw ScreenshotError.captureFailure(NSError(domain: "ScreenCapture", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to capture specific screen"]))
        }
        
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }
    
    /// Crops an image to a specified rectangle.
    /// - Parameters:
    ///   - image: The original image.
    ///   - rect: The rectangle to crop to.
    /// - Returns: The cropped image.
    private static func cropImage(_ image: NSImage, to rect: CGRect) throws -> NSImage {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ScreenshotError.captureFailure(NSError(domain: "ScreenCapture", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to get CGImage"]))
        }
        
        // Convert coordinate system (macOS origin is at the bottom-left).
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
