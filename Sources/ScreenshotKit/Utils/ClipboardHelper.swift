// Sources/ScreenshotKit/Utils/ClipboardHelper.swift

import Foundation
import AppKit

/// 剪贴板辅助工具
public struct ClipboardHelper {
    
    /// 将图片复制到剪贴板
    /// - Parameter image: 要复制的图片
    public static func copyImage(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
    
    /// 将文本复制到剪贴板
    /// - Parameter text: 要复制的文本
    public static func copyText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    /// 从剪贴板获取图片
    /// - Returns: 剪贴板中的图片，如果没有则返回 nil
    public static func getImage() -> NSImage? {
        let pasteboard = NSPasteboard.general
        return NSImage(pasteboard: pasteboard)
    }
    
    /// 从剪贴板获取文本
    /// - Returns: 剪贴板中的文本，如果没有则返回 nil
    public static func getText() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }
}
