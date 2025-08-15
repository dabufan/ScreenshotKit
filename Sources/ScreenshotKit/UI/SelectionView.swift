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
    
    // 性能优化：缓存绘制对象
    private var cachedAttributedString: NSAttributedString?
    private var cachedTextSize: CGSize = .zero
    private var lastSelectionRect: CGRect = .zero
    
    // UI改进：动画支持
    private var animationLayer: CALayer?
    private var isAnimating: Bool = false
    
    init(frame: NSRect, config: ScreenshotConfig, completion: @escaping (CGRect) -> Void) {
        self.config = config
        self.completionHandler = completion
        super.init(frame: frame)
        
        setupButtons()
        setupAnimationLayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButtons() {
        // 确认按钮 - 改进样式
        confirmButton = NSButton(frame: NSRect(x: 0, y: 0, width: 70, height: 28))
        confirmButton?.title = "确定"
        confirmButton?.bezelStyle = .rounded
        confirmButton?.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        confirmButton?.contentTintColor = .white
        confirmButton?.target = self
        confirmButton?.action = #selector(confirmSelection)
        confirmButton?.isHidden = true
        
        // 设置按钮背景色
        if let button = confirmButton {
            button.wantsLayer = true
            button.layer?.backgroundColor = NSColor.systemGreen.cgColor
            button.layer?.cornerRadius = 6
            button.layer?.masksToBounds = true
        }
        
        addSubview(confirmButton!)
        
        // 取消按钮 - 改进样式
        cancelButton = NSButton(frame: NSRect(x: 0, y: 0, width: 70, height: 28))
        cancelButton?.title = "取消"
        cancelButton?.bezelStyle = .rounded
        cancelButton?.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        cancelButton?.contentTintColor = .white
        cancelButton?.target = self
        cancelButton?.action = #selector(cancelSelection)
        cancelButton?.isHidden = true
        
        // 设置按钮背景色
        if let button = cancelButton {
            button.wantsLayer = true
            button.layer?.backgroundColor = NSColor.systemRed.cgColor
            button.layer?.cornerRadius = 6
            button.layer?.masksToBounds = true
        }
        
        addSubview(cancelButton!)
    }
    
    private func setupAnimationLayer() {
        wantsLayer = true
        animationLayer = CALayer()
        animationLayer?.frame = bounds
        layer?.addSublayer(animationLayer!)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // 性能优化：只在需要时重绘
        if !dirtyRect.intersects(bounds) {
            return
        }
        
        // 绘制遮罩
        config.overlayColor.setFill()
        bounds.fill()
        
        // 如果正在选择，绘制选择区域
        if isSelecting && !selectionRect.isRectEmpty {
            drawSelection()
        } else if !selectionRect.isRectEmpty {
            drawSelection()
            
            // 性能优化：只在选区改变时更新手柄和按钮
            if selectionRect != lastSelectionRect {
                updateResizeHandles()
                updateButtonPositions()
                lastSelectionRect = selectionRect
            }
        }
    }
    
    private func drawSelection() {
        // 清除选择区域的遮罩
        NSColor.clear.setFill()
        selectionRect.fill(using: .copy)
        
        // 绘制选择框边框 - 改进视觉效果
        let borderPath = NSBezierPath(rect: selectionRect)
        borderPath.lineWidth = config.selectionBorderWidth
        
        // 添加阴影效果
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        shadow.shadowBlurRadius = 2
        shadow.set()
        
        config.selectionBorderColor.setStroke()
        borderPath.stroke()
        
        // 重置阴影
        NSShadow().set()
        
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
        
        // 性能优化：缓存attributedString
        if cachedAttributedString == nil || cachedTextSize == .zero {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: NSColor.white,
                .backgroundColor: NSColor.black.withAlphaComponent(0.8)
            ]
            
            cachedAttributedString = NSAttributedString(string: text, attributes: attributes)
            cachedTextSize = cachedAttributedString!.size()
        }
        
        guard let attributedString = cachedAttributedString else { return }
        
        let textRect = CGRect(
            x: selectionRect.maxX - cachedTextSize.width - 8,
            y: selectionRect.minY - cachedTextSize.height - 8,
            width: cachedTextSize.width + 16,
            height: cachedTextSize.height + 8
        )
        
        // 改进背景样式
        let backgroundPath = NSBezierPath(roundedRect: textRect, xRadius: 4, yRadius: 4)
        NSColor.black.withAlphaComponent(0.8).setFill()
        backgroundPath.fill()
        
        // 添加边框
        NSColor.white.withAlphaComponent(0.3).setStroke()
        backgroundPath.lineWidth = 0.5
        backgroundPath.stroke()
        
        attributedString.draw(at: CGPoint(x: textRect.minX + 8, y: textRect.minY + 4))
    }
    
    private func drawResizeHandles() {
        let handleColor = NSColor.white
        let handleBorderColor = config.selectionBorderColor
        
        for (_, handle) in resizeHandles.enumerated() {
            // 绘制手柄背景 - 改进样式
            let handlePath = NSBezierPath(ovalIn: handle)
            
            // 添加渐变效果
            let gradient = NSGradient(colors: [handleColor, handleColor.withAlphaComponent(0.9)])
            gradient?.draw(in: handlePath, angle: 45)
            
            // 绘制手柄边框
            handleBorderColor.setStroke()
            handlePath.lineWidth = 1.5
            handlePath.stroke()
            
            // 添加中心点
            let centerPoint = CGPoint(x: handle.midX, y: handle.midY)
            let centerPath = NSBezierPath(ovalIn: CGRect(x: centerPoint.x - 1, y: centerPoint.y - 1, width: 2, height: 2))
            NSColor.black.withAlphaComponent(0.6).setFill()
            centerPath.fill()
        }
    }
    
    private func updateResizeHandles() {
        let handleSize: CGFloat = 10
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
        
        let buttonWidth: CGFloat = 70
        let buttonHeight: CGFloat = 28
        let buttonSpacing: CGFloat = 12
        let totalWidth = buttonWidth * 2 + buttonSpacing
        
        let buttonY = selectionRect.minY - buttonHeight - 15
        
        // 添加动画效果
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            confirmButton.animator().frame = NSRect(
                x: selectionRect.midX - totalWidth / 2,
                y: buttonY,
                width: buttonWidth,
                height: buttonHeight
            )
            
            cancelButton.animator().frame = NSRect(
                x: selectionRect.midX + totalWidth / 2 - buttonWidth,
                y: buttonY,
                width: buttonWidth,
                height: buttonHeight
            )
        }) {
            // 动画完成后显示按钮
            confirmButton.isHidden = false
            cancelButton.isHidden = false
        }
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
                
                // 添加视觉反馈
                NSCursor.crosshair.set()
                return
            }
            
            // 检查是否点击了选区内部（拖拽移动）
            if selectionRect.contains(location) {
                isDragging = true
                dragStartPoint = location
                originalSelectionRect = selectionRect
                
                // 添加视觉反馈
                NSCursor.openHand.set()
                return
            }
            
            // 开始新的选择
            startPoint = location
            currentPoint = location
            isSelecting = true
            selectionRect = .zero
            confirmButton?.isHidden = true
            cancelButton?.isHidden = true
            
            // 清除缓存
            cachedAttributedString = nil
            cachedTextSize = .zero
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
                
                // 添加选区确认动画
                animateSelectionConfirmation()
            }
        } else if isResizing {
            isResizing = false
            activeHandle = -1
            NSCursor.crosshair.set()
        } else if isDragging {
            isDragging = false
            NSCursor.crosshair.set()
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
        if newRect.width >= 20 && newRect.height >= 20 {
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
    
    private func animateSelectionConfirmation() {
        guard !isAnimating else { return }
        isAnimating = true
        
        // 创建确认动画
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1.0
        animation.toValue = 1.05
        animation.duration = 0.15
        animation.autoreverses = true
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        animationLayer?.add(animation, forKey: "selectionConfirmation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isAnimating = false
        }
    }
    
    // MARK: - 公共方法
    
    @objc func confirmSelection() {
        if !selectionRect.isRectEmpty {
            // 添加确认动画
            animateConfirmation()
            
            // 延迟执行回调，让动画完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.completionHandler(self?.selectionRect ?? .zero)
            }
        }
    }
    
    @objc func cancelSelection() {
        ScreenshotKit.shared.cancelScreenshot()
    }
    
    private func animateConfirmation() {
        // 创建确认动画
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        layer?.add(animation, forKey: "fadeOut")
    }
}