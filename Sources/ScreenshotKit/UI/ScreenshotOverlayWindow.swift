// Sources/ScreenshotKit/UI/ScreenshotOverlayWindow.swift

import AppKit

/// 截图遮罩窗口
class ScreenshotOverlayWindow: NSWindow {
    
    private let config: ScreenshotConfig
    private let completionHandler: (CGRect) -> Void
    private var selectionView: SelectionView?
    
    // UI改进：动画支持
    private var animationLayer: CALayer?
    private var isAnimating: Bool = false
    
    init(contentRect: NSRect, config: ScreenshotConfig, completion: @escaping (CGRect) -> Void) {
        self.config = config
        self.completionHandler = completion
        
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
        setupSelectionView()
        setupAnimationLayer()
    }
    
    private func setupWindow() {
        // 设置窗口层级，确保显示在最前面
        level = .screenSaver + 100
        backgroundColor = config.overlayColor
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        
        // 设置光标
        if config.showCrosshairCursor {
            NSCursor.crosshair.set()
        }
        
        // 设置窗口属性
        isMovable = false
        isReleasedWhenClosed = false
    }
    
    private func setupSelectionView() {
        selectionView = SelectionView(frame: contentView!.bounds, config: config) { [weak self] rect in
            self?.completionHandler(rect)
        }
        
        contentView?.addSubview(selectionView!)
    }
    
    private func setupAnimationLayer() {
        // NSWindow没有直接的layer属性，我们通过contentView来设置
        contentView?.wantsLayer = true
        animationLayer = CALayer()
        animationLayer?.frame = contentView?.bounds ?? .zero
        contentView?.layer?.addSublayer(animationLayer!)
    }
    
    func confirmSelection() {
        selectionView?.confirmSelection()
    }
    
    override func keyDown(with event: NSEvent) {
        // 处理键盘事件
        switch event.keyCode {
        case 53: // Esc
            animateWindowClose {
                ScreenshotKit.shared.cancelScreenshot()
            }
        case 36: // Return
            confirmSelection()
        case 49: // Space
            confirmSelection()
        default:
            super.keyDown(with: event)
        }
    }
    
    override func performClose(_ sender: Any?) {
        animateWindowClose {
            ScreenshotKit.shared.cancelScreenshot()
        }
    }
    
    override func close() {
        super.close()
    }
    
    // MARK: - 动画方法
    
    /// 窗口显示动画
    func animateWindowShow() {
        guard !isAnimating else { return }
        isAnimating = true
        
        // 设置初始状态
        alphaValue = 0.0
        setFrame(NSRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: frame.height), display: false)
        
        // 执行显示动画
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            animator().alphaValue = 1.0
        }) {
            self.isAnimating = false
        }
    }
    
    /// 窗口关闭动画
    func animateWindowClose(completion: @escaping () -> Void) {
        guard !isAnimating else { return }
        isAnimating = true
        
        // 执行关闭动画
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            
            animator().alphaValue = 0.0
        }) {
            self.isAnimating = false
            completion()
        }
    }
    
    /// 添加进入动画
    override func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        animateWindowShow()
    }
    
    /// 添加退出动画
    override func orderOut(_ sender: Any?) {
        animateWindowClose {
            super.orderOut(sender)
        }
    }
}