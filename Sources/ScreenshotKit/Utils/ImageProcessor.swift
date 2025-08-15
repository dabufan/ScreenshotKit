// Sources/ScreenshotKit/Utils/ImageProcessor.swift

import AppKit
import UniformTypeIdentifiers
import ImageIO

/// 图像处理工具
public class ImageProcessor {
    
    // 性能优化：缓存常用格式的转换器
    private static var formatConverters: [ImageFormat: ImageConverter] = [:]
    private static let converterQueue = DispatchQueue(label: "com.screenshotkit.imageprocessor", qos: .userInitiated)
    
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
    
    /// 异步保存图片到文件（性能优化）
    /// - Parameters:
    ///   - image: 要保存的图片
    ///   - directory: 保存目录
    ///   - format: 图片格式
    ///   - quality: 图片质量
    ///   - completion: 完成回调
    public static func saveImageAsync(
        _ image: NSImage,
        to directory: URL,
        format: ImageFormat = .png,
        quality: Float = 1.0,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        converterQueue.async {
            do {
                let fileURL = try saveImage(image, to: directory, format: format, quality: quality)
                DispatchQueue.main.async {
                    completion(.success(fileURL))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
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
        
        // 性能优化：使用缓存的转换器
        let converter = getOrCreateConverter(for: format)
        return try converter.convert(cgImage: cgImage, quality: quality)
    }
    
    /// 异步转换图片为数据（性能优化）
    /// - Parameters:
    ///   - image: 原始图片
    ///   - format: 目标格式
    ///   - quality: 质量
    ///   - completion: 完成回调
    public static func convertImageToDataAsync(
        _ image: NSImage,
        format: ImageFormat,
        quality: Float,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        converterQueue.async {
            do {
                let data = try convertImageToData(image, format: format, quality: quality)
                DispatchQueue.main.async {
                    completion(.success(data))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
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
        
        // 性能优化：使用高质量插值
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: size))
        
        resizedImage.unlockFocus()
        return resizedImage
    }
    
    /// 异步调整图片大小（性能优化）
    /// - Parameters:
    ///   - image: 原始图片
    ///   - size: 目标大小
    ///   - completion: 完成回调
    public static func resizeImageAsync(
        _ image: NSImage,
        to size: NSSize,
        completion: @escaping (NSImage) -> Void
    ) {
        converterQueue.async {
            let resizedImage = resizeImage(image, to: size)
            DispatchQueue.main.async {
                completion(resizedImage)
            }
        }
    }
    
    /// 压缩图片（性能优化）
    /// - Parameters:
    ///   - image: 原始图片
    ///   - maxSize: 最大尺寸
    ///   - quality: 压缩质量
    /// - Returns: 压缩后的图片
    public static func compressImage(
        _ image: NSImage,
        maxSize: NSSize,
        quality: Float = 0.8
    ) -> NSImage {
        let originalSize = image.size
        
        // 如果图片已经小于最大尺寸，直接返回
        if originalSize.width <= maxSize.width && originalSize.height <= maxSize.height {
            return image
        }
        
        // 计算缩放比例
        let scaleX = maxSize.width / originalSize.width
        let scaleY = maxSize.height / originalSize.height
        let scale = min(scaleX, scaleY)
        
        let newSize = NSSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
        
        return resizeImage(image, to: newSize)
    }
    
    /// 获取或创建格式转换器
    private static func getOrCreateConverter(for format: ImageFormat) -> ImageConverter {
        if let converter = formatConverters[format] {
            return converter
        }
        
        let converter: ImageConverter
        switch format {
        case .png:
            converter = PNGConverter()
        case .jpeg:
            converter = JPEGConverter()
        case .tiff:
            converter = TIFFConverter()
        }
        
        formatConverters[format] = converter
        return converter
    }
    
    /// 清理缓存
    public static func clearCache() {
        formatConverters.removeAll()
    }
}

// MARK: - 图片转换器协议

private protocol ImageConverter {
    func convert(cgImage: CGImage, quality: Float) throws -> Data
}

// MARK: - PNG转换器

private class PNGConverter: ImageConverter {
    func convert(cgImage: CGImage, quality: Float) throws -> Data {
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        
        guard let data = bitmapRep.representation(using: .png, properties: [:]) else {
            throw ScreenshotError.saveFailure(NSError(domain: "ImageProcessor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create PNG data"]))
        }
        
        return data
    }
}

// MARK: - JPEG转换器

private class JPEGConverter: ImageConverter {
    func convert(cgImage: CGImage, quality: Float) throws -> Data {
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        
        let properties = [NSBitmapImageRep.PropertyKey.compressionFactor: quality]
        guard let data = bitmapRep.representation(using: .jpeg, properties: properties) else {
            throw ScreenshotError.saveFailure(NSError(domain: "ImageProcessor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create JPEG data"]))
        }
        
        return data
    }
}

// MARK: - TIFF转换器

private class TIFFConverter: ImageConverter {
    func convert(cgImage: CGImage, quality: Float) throws -> Data {
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        
        let properties = [NSBitmapImageRep.PropertyKey.compressionFactor: quality]
        guard let data = bitmapRep.representation(using: .tiff, properties: properties) else {
            throw ScreenshotError.saveFailure(NSError(domain: "ImageProcessor", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create TIFF data"]))
        }
        
        return data
    }
}

extension DateFormatter {
    static let screenshotFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}