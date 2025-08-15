// Sources/ScreenshotKit/Extensions/CGRect+Extensions.swift

import Foundation

extension CGRect {
    
    /// 是否为空矩形
    var isRectEmpty: Bool {
        return width <= 0 || height <= 0
    }
    
    /// 中心点
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
    
    /// 转换为NSRect
    var nsRect: NSRect {
        return NSRect(x: origin.x, y: origin.y, width: size.width, height: size.height)
    }
}