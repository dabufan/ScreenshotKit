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
    private var isDragging: Bool = false
    private var dragStartPoint: CGPoint = .zero
    private var originalSelectionRect: CGRect = .zero
    
    // 选区调整手柄
    private var resizeHandles: [CGRect] = []
    private var activeHandle: Int = -1
    private var isResizing: Bool = false
    
    // 确认和取消按钮
    private var confirmButton: NSButton?
    private var cancelButton: NSButton?
    
    init(frame: NSRect, config: ScreenshotConfig, completion: @escaping (CGRect) -> Void) {
        self.config = config
        self.completionHandler = completion
        super.init(frame: frame)
        
        setupButtons()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButtons() {
        // 确认按钮
        confirmButton = NSButton(frame: NSRect(x: 0, y: 0, width: 60, height: 24))
        confirmButton?.title = "确定"
        confirmButton?.bezelStyle = .rounded
        confirmButton?.target = self
        confirmButton?.action = #selector(confirmSelection)
        confirmButton?.isHidden = true
        addSubview(confirmButton!)
        
        // 取消按钮
        cancelButton = NSButton(frame: NSRect(x: 0, y: 0, width: 60, height: 24))
        cancelButton?.title = "取消"
        cancelButton?.bezelStyle = .rounded
        cancelButton?.target = self
        cancelButton?.action = #selector(cancelSelection)
        cancelButton?.isHidden = true
        addSubview(cancelButton!)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // 绘制遮罩
        config.overlayColor.setFill()
        bounds.fill()
        
        // 如果正在选择，绘制选择区域
        if isSelecting && !selectionRect.isRectEmpty {
            drawSelection()
        } else if !selectionRect.isRectEmpty {
            drawSelection()
            updateResizeHandles()
            updateButtonPositions()
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
        
        // 绘制调整手柄
        if !isSelecting && !selectionRect.isRectEmpty {
            drawResizeHandles()
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
    
    private func drawResizeHandles() {
        let handleColor = NSColor.white
        let handleBorderColor = config.selectionBorderColor
        
        for handle in resizeHandles {
            // 绘制手柄背景
            handleColor.setFill()
            handle.fill()
            
            // 绘制手柄边框
            handleBorderColor.setStroke()
            let path = NSBezierPath(rect: handle)
            path.lineWidth = 1
            path.stroke()
        }
    }
    
    private func updateResizeHandles() {
        let handleSize: CGFloat = 8
        let halfHandle = handleSize / 2
        
        resizeHandles = [
            // 左上角
            CGRect(x: selectionRect.minX - halfHandle, y: selectionRect.maxY - halfHandle, width: handleSize, height: handleSize),
            // 右上角
            CGRect(x: selectionRect.maxX - halfHandle, y: selectionRect.maxY - halfHandle, width: handleSize, height: handleSize),
            // 左下角
            CGRect(x: selectionRect.minX - halfHandle, y: selectionRect.minY - halfHandle, width: handleSize, height: handleSize),
            // 右下角
            CGRect(x: selectionRect.maxX - halfHandle, y: selectionRect.minY - halfHandle, width: handleSize, height: handleSize),
            // 上边中点
            CGRect(x: selectionRect.midX - halfHandle, y: selectionRect.maxY - halfHandle, width: handleSize, height: handleSize),
            // 下边中点
            CGRect(x: selectionRect.midX - halfHandle, y: selectionRect.minY - halfHandle, width: handleSize, height: handleSize),
            // 左边中点
            CGRect(x: selectionRect.minX - halfHandle, y: selectionRect.midY - halfHandle, width: handleSize, height: handleSize),
            // 右边中点
            CGRect(x: selectionRect.maxX - halfHandle, y: selectionRect.midY - halfHandle, width: handleSize, height: handleSize)
        ]
    }
    
    private func updateButtonPositions() {
        guard let confirmButton = confirmButton, let cancelButton = cancelButton else { return }
        
        let buttonWidth: CGFloat = 60
        let buttonHeight: CGFloat = 24
        let buttonSpacing: CGFloat = 10
        let totalWidth = buttonWidth * 2 + buttonSpacing
        
        let buttonY = selectionRect.minY - buttonHeight - 10
        
        confirmButton.frame = NSRect(
            x: selectionRect.midX - totalWidth / 2,
            y: buttonY,
            width: buttonWidth,
            height: buttonHeight
        )
        
        cancelButton.frame = NSRect(
            x: selectionRect.midX + totalWidth / 2 - buttonWidth,
            y: buttonY,
            width: buttonWidth,
            height: buttonHeight
        )
        
        confirmButton.isHidden = false
        cancelButton.isHidden = false
    }
    
    // MARK: - 鼠标事件
    
    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        
        if isSelecting {
            // 正在选择区域
            startPoint = location
            currentPoint = location
            updateSelectionRect()
        } else if !selectionRect.isRectEmpty {
            // 检查是否点击了调整手柄
            if let handleIndex = getHandleIndex(at: location) {
                activeHandle = handleIndex
                isResizing = true
                dragStartPoint = location
                originalSelectionRect = selectionRect
                return
            }
            
            // 检查是否点击了选区内部（拖拽移动）
            if selectionRect.contains(location) {
                isDragging = true
                dragStartPoint = location
                originalSelectionRect = selectionRect
                return
            }
            
            // 开始新的选择
            startPoint = location
            currentPoint = location
            isSelecting = true
            selectionRect = .zero
            confirmButton?.isHidden = true
            cancelButton?.isHidden = true
        } else {
            // 开始选择
            startPoint = location
            currentPoint = location
            isSelecting = true
        }
        
        needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        
        if isSelecting {
            currentPoint = location
            updateSelectionRect()
        } else if isResizing {
            handleResize(at: location)
        } else if isDragging {
            handleDrag(to: location)
        }
        
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        if isSelecting {
            isSelecting = false
            if !selectionRect.isRectEmpty {
                updateResizeHandles()
                updateButtonPositions()
            }
        } else if isResizing {
            isResizing = false
            activeHandle = -1
        } else if isDragging {
            isDragging = false
        }
        
        needsDisplay = true
    }
    
    override func mouseMoved(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        
        if !isSelecting && !selectionRect.isRectEmpty {
            if getHandleIndex(at: location) != nil {
                NSCursor.crosshair.set()
            } else if selectionRect.contains(location) {
                NSCursor.openHand.set()
            } else {
                NSCursor.crosshair.set()
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func updateSelectionRect() {
        selectionRect = CGRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )
    }
    
    private func getHandleIndex(at point: CGPoint) -> Int? {
        for (index, handle) in resizeHandles.enumerated() {
            if handle.contains(point) {
                return index
            }
        }
        return nil
    }
    
    private func handleResize(at point: CGPoint) {
        guard activeHandle >= 0 && activeHandle < resizeHandles.count else { return }
        
        let deltaX = point.x - dragStartPoint.x
        let deltaY = point.y - dragStartPoint.y
        
        var newRect = originalSelectionRect
        
        switch activeHandle {
        case 0: // 左上角
            newRect.origin.x += deltaX
            newRect.origin.y += deltaY
            newRect.size.width -= deltaX
            newRect.size.height -= deltaY
        case 1: // 右上角
            newRect.origin.y += deltaY
            newRect.size.width += deltaX
            newRect.size.height -= deltaY
        case 2: // 左下角
            newRect.origin.x += deltaX
            newRect.size.width -= deltaX
            newRect.size.height += deltaY
        case 3: // 右下角
            newRect.size.width += deltaX
            newRect.size.height += deltaY
        case 4: // 上边中点
            newRect.origin.y += deltaY
            newRect.size.height -= deltaY
        case 5: // 下边中点
            newRect.size.height += deltaY
        case 6: // 左边中点
            newRect.origin.x += deltaX
            newRect.size.width -= deltaX
        case 7: // 右边中点
            newRect.size.width += deltaX
        default:
            break
        }
        
        // 确保选区不会太小
        if newRect.width >= 10 && newRect.height >= 10 {
            selectionRect = newRect
        }
    }
    
    private func handleDrag(to point: CGPoint) {
        let deltaX = point.x - dragStartPoint.x
        let deltaY = point.y - dragStartPoint.y
        
        selectionRect.origin.x = originalSelectionRect.origin.x + deltaX
        selectionRect.origin.y = originalSelectionRect.origin.y + deltaY
        
        // 确保选区不会超出屏幕边界
        let minX = max(0, selectionRect.minX)
        let minY = max(0, selectionRect.minY)
        let maxX = min(bounds.width, selectionRect.maxX)
        let maxY = min(bounds.height, selectionRect.maxY)
        
        selectionRect.origin.x = minX
        selectionRect.origin.y = minY
        selectionRect.size.width = maxX - minX
        selectionRect.size.height = maxY - minY
    }
    
    // MARK: - 公共方法
    
    @objc func confirmSelection() {
        if !selectionRect.isRectEmpty {
            completionHandler(selectionRect)
        }
    }
    
    @objc func cancelSelection() {
        ScreenshotKit.shared.cancelScreenshot()
    }
}