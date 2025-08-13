// Sources/ScreenshotKit/UI/SelectionView.swift

import AppKit

/// 选择区域视图
class SelectionView: NSView {
    
    private let config: ScreenshotConfig
    private let completionHandler: (CGRect) -> Void
    
    private var startPoint: CGPoint = .zero
    private var currentPoint: CGPoint = .zero
    private var isSelecting: Bool = false
    private var selectionRect: CGRect = .zero
    
    init(frame: NSRect, config: ScreenshotConfig, completion: @escaping (CGRect) -> Void) {
        self.config = config
        self.completionHandler = completion
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // 绘制遮罩
        config.overlayColor.setFill()
        bounds.fill()
        
        // 如果正在选择，绘制选择区域
        if isSelecting && !selectionRect.isEmpty {
            drawSelection()
        }
    }
    
    private func drawSelection() {
        // 清除选择区域的遮罩
        NSColor.clear.setFill()
        selectionRect.fill(using: .copy)
        
        // 绘制选择框边框
        config.selectionBorderColor.setStroke()
        let path = NSBezierPath(rect: selectionRect)
        path.lineWidth = config.selectionBorderWidth
        path.stroke()
        
        // 显示尺寸信息
        if config.showDimensions {
            drawDimensions()
        }
    }
    
    private func drawDimensions() {
        let width = Int(selectionRect.width)
        let height = Int(selectionRect.height)
        let text = "\(width) × \(height)"
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.7)
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        let textRect = CGRect(
            x: selectionRect.maxX - textSize.width - 5,
            y: selectionRect.minY - textSize.height - 5,
            width: textSize.width + 10,
            height: textSize.height + 4
        )
        
        NSColor.black.withAlphaComponent(0.7).setFill()
        textRect.fill()
        
        attributedString.draw(at: CGPoint(x: textRect.minX + 5, y: textRect.minY + 2))
    }
    
    // MARK: - 鼠标事件
    
    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        isSelecting = true
        updateSelectionRect()
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isSelecting else { return }
        
        currentPoint = convert(event.locationInWindow, from: nil)
        updateSelectionRect()
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        guard isSelecting else { return }
        
        isSelecting = false
        
        if !selectionRect.isEmpty {
            completionHandler(selectionRect)
        }
    }
    
    private func updateSelectionRect() {
        selectionRect = CGRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )
    }
    
    func confirmSelection() {
        if !selectionRect.isEmpty {
            completionHandler(selectionRect)
        }
    }
}