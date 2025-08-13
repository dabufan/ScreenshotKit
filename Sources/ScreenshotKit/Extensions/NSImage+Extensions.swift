// Sources/ScreenshotKit/Extensions/NSImage+Extensions.swift

import AppKit

extension NSImage {
    
    /// 获取图片的 CGImage 表示
    var cgImage: CGImage? {
        return cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
    
    /// 将图片保存为指定格式的数据
    /// - Parameters:
    ///   - format: 图片格式
    ///   - quality: 图片质量 (0.0-1.0)
    /// - Returns: 图片数据
    func data(format: ImageFormat, quality: Float = 1.0) -> Data? {
        guard let cgImage = self.cgImage else { return nil }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        
        switch format {
        case .png:
            return bitmapRep.representation(using: .png, properties: [:])
        case .jpeg:
            return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality])
        case .tiff:
            return bitmapRep.representation(using: .tiff, properties: [:])
        }
    }
}
