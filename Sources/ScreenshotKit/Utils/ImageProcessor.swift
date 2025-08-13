// Sources/ScreenshotKit/Utils/ImageProcessor.swift

import AppKit
import UniformTypeIdentifiers

/// 图像处理工具
public class ImageProcessor {
    
    /// 保存图片到文件
    /// - Parameters:
    ///   - image: 要保存的图片
    ///   - directory: 保存目录
    ///   - format: 图片格式
    ///   - quality: 图片质量 (0.0-1.0)
    /// - Returns: 保存的文件路径
    public static func saveImage(
        _ image: NSImage,
        to directory: URL,
        format: ImageFormat = .png,
        quality: Float = 1.0
    ) throws -> URL {
        
        // 生成文件名
        let timestamp = DateFormatter.screenshotFormatter.string(from: Date())
        let filename = "Screenshot_\(timestamp).\(format.fileExtension)"
        let fileURL = directory.appendingPathComponent(filename)
        
        // 转换图片数据
        let imageData = try convertImageToData(image, format: format, quality: quality)
        
        // 写入文件
        try imageData.write(to: fileURL)
        
        return fileURL
    }
    
    /// 转换图片为数据
    /// - Parameters:
    ///   - image: 原始图片
    ///   - format: 目标格式
    ///   - quality: 质量
    /// - Returns: 图片数据
    public static func convertImageToData(
        _ image: NSImage,
        format: ImageFormat,
        quality: Float
    ) throws -> Data {
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ScreenshotError.saveFailure(NSError(domain: "ImageProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get CGImage"]))
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        
        switch format {
        case .png:
            guard let data = bitmapRep.representation(using: .png, properties: [:]) else {
                throw ScreenshotError.saveFailure(NSError(domain: "ImageProcessor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create PNG data"]))
            }
            return data
            
        case .jpeg:
            let properties = [NSBitmapImageRep.PropertyKey.compressionFactor: quality]
            guard let data = bitmapRep.representation(using: .jpeg, properties: properties) else {
                throw ScreenshotError.saveFailure(NSError(domain: "ImageProcessor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create JPEG data"]))
            }
            return data
            
        case .tiff:
            let properties = [NSBitmapImageRep.PropertyKey.compressionFactor: quality]
            guard let data = bitmapRep.representation(using: .tiff, properties: properties) else {
                throw ScreenshotError.saveFailure(NSError(domain: "ImageProcessor", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create TIFF data"]))
            }
            return data
        }
    }
    
    /// 调整图片大小
    /// - Parameters:
    ///   - image: 原始图片
    ///   - size: 目标大小
    /// - Returns: 调整后的图片
    public static func resizeImage(_ image: NSImage, to size: NSSize) -> NSImage {
        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size))
        resizedImage.unlockFocus()
        return resizedImage
    }
}

extension DateFormatter {
    static let screenshotFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}