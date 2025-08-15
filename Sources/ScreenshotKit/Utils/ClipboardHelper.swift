// Sources/ScreenshotKit/Utils/ClipboardHelper.swift

import AppKit

/// 剪贴板操作工具
public class ClipboardHelper {
    
    /// 复制图片到剪贴板
    /// - Parameter image: 要复制的图片
    public static func copyImage(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // 复制图片到剪贴板
        pasteboard.writeObjects([image])
    }
    
    /// 复制图片数据到剪贴板
    /// - Parameter imageData: 图片数据
    /// - Parameter type: 图片类型
    public static func copyImageData(_ imageData: Data, type: NSPasteboard.PasteboardType) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // 复制图片数据到剪贴板
        pasteboard.setData(imageData, forType: type)
    }
    
    /// 从剪贴板获取图片
    /// - Returns: 剪贴板中的图片，如果没有则返回nil
    public static func getImageFromClipboard() -> NSImage? {
        let pasteboard = NSPasteboard.general
        
        // 尝试获取图片对象
        if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
            return image
        }
        
        // 尝试获取图片数据
        if let imageData = pasteboard.data(forType: .png) {
            return NSImage(data: imageData)
        }
        
        return nil
    }
    
    /// 检查剪贴板是否包含图片
    /// - Returns: 是否包含图片
    public static func hasImage() -> Bool {
        let pasteboard = NSPasteboard.general
        return pasteboard.canReadObject(forClasses: [NSImage.self], options: nil)
    }
}
