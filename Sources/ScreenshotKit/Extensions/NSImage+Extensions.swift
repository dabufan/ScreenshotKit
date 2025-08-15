// Sources/ScreenshotKit/Extensions/NSImage+Extensions.swift

import AppKit

extension NSImage {
    
    /// 获取CGImage
    var cgImage: CGImage? {
        return self.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
    
    /// 调整图片大小
    /// - Parameter newSize: 新尺寸
    /// - Returns: 调整后的图片
    func resized(to newSize: NSSize) -> NSImage {
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: newSize))
        resizedImage.unlockFocus()
        return resizedImage
    }
    
    /// 裁剪图片
    /// - Parameter rect: 裁剪区域
    /// - Returns: 裁剪后的图片
    func cropped(to rect: CGRect) -> NSImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        guard let croppedCGImage = cgImage.cropping(to: rect) else { return nil }
        
        let size = NSSize(width: croppedCGImage.width, height: croppedCGImage.height)
        return NSImage(cgImage: croppedCGImage, size: size)
    }
    
    /// 转换为PNG数据
    /// - Returns: PNG格式的图片数据
    func pngData() -> Data? {
        guard let cgImage = self.cgImage else { return nil }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .png, properties: [:])
    }
    
    /// 转换为JPEG数据
    /// - Parameter quality: 质量 (0.0-1.0)
    /// - Returns: JPEG格式的图片数据
    func jpegData(quality: Float = 0.8) -> Data? {
        guard let cgImage = self.cgImage else { return nil }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        let properties = [NSBitmapImageRep.PropertyKey.compressionFactor: quality]
        return bitmapRep.representation(using: .jpeg, properties: properties)
    }
    
    /// 转换为TIFF数据
    /// - Parameter quality: 质量 (0.0-1.0)
    /// - Returns: TIFF格式的图片数据
    func tiffData(quality: Float = 1.0) -> Data? {
        guard let cgImage = self.cgImage else { return nil }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        let properties = [NSBitmapImageRep.PropertyKey.compressionFactor: quality]
        return bitmapRep.representation(using: .tiff, properties: properties)
    }
    
    /// 保存图片到文件
    /// - Parameters:
    ///   - url: 保存路径
    ///   - format: 图片格式
    ///   - quality: 质量
    /// - Throws: 保存失败时抛出错误
    func save(to url: URL, format: ImageFormat, quality: Float = 1.0) throws {
        let data: Data
        
        switch format {
        case .png:
            guard let pngData = self.pngData() else {
                throw ScreenshotError.saveFailure(NSError(domain: "NSImage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PNG data"]))
            }
            data = pngData
            
        case .jpeg:
            guard let jpegData = self.jpegData(quality: quality) else {
                throw ScreenshotError.saveFailure(NSError(domain: "NSImage", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create JPEG data"]))
            }
            data = jpegData
            
        case .tiff:
            guard let tiffData = self.tiffData(quality: quality) else {
                throw ScreenshotError.saveFailure(NSError(domain: "NSImage", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create TIFF data"]))
            }
            data = tiffData
        }
        
        try data.write(to: url)
    }
}
