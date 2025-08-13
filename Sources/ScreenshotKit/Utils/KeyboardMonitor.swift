// Sources/ScreenshotKit/Utils/KeyboardMonitor.swift

import AppKit

/// 键盘监听器
class KeyboardMonitor {
    
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    private let keyHandler: (KeyCode) -> Void
    
    init(keyHandler: @escaping (KeyCode) -> Void) {
        self.keyHandler = keyHandler
    }
    
    func startMonitoring() {
        // 本地事件监听
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
        
        // 全局事件监听
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
    }
    
    func stopMonitoring() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        if let keyCode = KeyCode(rawValue: event.keyCode) {
            keyHandler(keyCode)
        }
    }
    
    deinit {
        stopMonitoring()
    }
}