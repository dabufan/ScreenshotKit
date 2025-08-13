// Sources/ScreenshotKit/UI/ScreenshotOverlayWindow.swift

import AppKit

/// 截图遮罩窗口
class ScreenshotOverlayWindow: NSWindow {
    
    private let config: ScreenshotConfig
    private let completionHandler: (CGRect) -> Void
    private var selectionView: SelectionView?
    
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
    }
    
    private func setupWindow() {
        level = .screenSaver + 1
        backgroundColor = config.overlayColor
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        
        // 设置光标
        if config.showCrosshairCursor {
            NSCursor.crosshair.set()
        }
    }
    
    private func setupSelectionView() {
        selectionView = SelectionView(frame: contentView!.bounds, config: config) { [weak self] rect in
            self?.completionHandler(rect)
        }
        
        contentView?.addSubview(selectionView!)
    }
    
    func confirmSelection() {
        selectionView?.confirmSelection()
    }
    
    override func keyDown(with event: NSEvent) {
        // 处理键盘事件
        switch event.keyCode {
        case 53: // Esc
            ScreenshotKit.shared.cancelScreenshot()
        case 36: // Return
            confirmSelection()
        default:
            super.keyDown(with: event)
        }
    }
}