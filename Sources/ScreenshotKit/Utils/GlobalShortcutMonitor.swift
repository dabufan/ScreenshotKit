// Sources/ScreenshotKit/Utils/GlobalShortcutMonitor.swift

import AppKit
import Carbon

/// 全局快捷键监听器
class GlobalShortcutMonitor {
    
    private var eventHotKeyRef: EventHotKeyRef?
    private var shortcutHandler: (() -> Void)?
    
    func registerShortcut(_ shortcut: KeyboardShortcut, handler: @escaping () -> Void) {
        unregisterShortcut()
        
        self.shortcutHandler = handler
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(fourCharCodeFrom("SSKT"))
        hotKeyID.id = 1
        
        let modifiers = UInt32(shortcut.modifiers.carbonFlags)
        
        let status = RegisterEventHotKey(
            UInt32(shortcut.key.rawValue),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &eventHotKeyRef
        )
        
        if status != noErr {
            print("Failed to register global shortcut: \(status)")
        }
    }
    
    func unregisterShortcut() {
        if let hotKeyRef = eventHotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            eventHotKeyRef = nil
        }
        shortcutHandler = nil
    }
    
    deinit {
        unregisterShortcut()
    }
}

// MARK: - 扩展

extension NSEvent.ModifierFlags {
    var carbonFlags: Int {
        var flags = 0
        if contains(.command) { flags |= cmdKey }
        if contains(.option) { flags |= optionKey }
        if contains(.control) { flags |= controlKey }
        if contains(.shift) { flags |= shiftKey }
        return flags
    }
}

private func fourCharCodeFrom(_ string: String) -> FourCharCode {
    assert(string.count == 4)
    var result: FourCharCode = 0
    for char in string.utf8 {
        result = (result << 8) + FourCharCode(char)
    }
    return result
}