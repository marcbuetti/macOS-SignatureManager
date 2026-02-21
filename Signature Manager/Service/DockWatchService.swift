//
//  DockWatcher.swift
//  Signature Manager
//
//  Created by Marc Büttner on 05.09.25.
//

import SwiftUI


struct DockWatcher: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            if let window = v.window {
                context.coordinator.startObserving(window)
            } else {
                LogManager.shared.log(.critical, "NSView has no window yet; cannot start observing")
            }
        }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    class Coordinator: NSObject, NSWindowDelegate {
        weak var window: NSWindow?
        func startObserving(_ window: NSWindow) {
            if let existing = self.window, existing === window {
                // Already observing this window; no log to avoid noise
                return
            } else if self.window != nil {
                LogManager.shared.log(.warning, "startObserving called while another window is already observed; replacing reference")
            }
            
            self.window = window
            window.delegate = self
            // If the window is already visible, ensure the Dock icon is shown
            if window.isVisible {
                NotificationCenter.default.post(name: .ShowAppInDock, object: nil)
            }
            // Observe when the window becomes key or main to show the Dock icon
            NotificationCenter.default.addObserver(self, selector: #selector(windowDidBecomeKeyNotification(_:)), name: NSWindow.didBecomeKeyNotification, object: window)
            NotificationCenter.default.addObserver(self, selector: #selector(windowDidBecomeMainNotification(_:)), name: NSWindow.didBecomeMainNotification, object: window)
        }
        
        @objc private func windowDidBecomeKeyNotification(_ notification: Notification) {
            NotificationCenter.default.post(name: .ShowAppInDock, object: nil)
        }

        @objc private func windowDidBecomeMainNotification(_ notification: Notification) {
            NotificationCenter.default.post(name: .ShowAppInDock, object: nil)
        }
        
        func windowDidBecomeKey(_ notification: Notification) {
            NotificationCenter.default.post(name: .ShowAppInDock, object: nil)
        }

        func windowDidBecomeMain(_ notification: Notification) {
            NotificationCenter.default.post(name: .ShowAppInDock, object: nil)
        }
        
        func windowWillClose(_ notification: Notification) {
            NotificationCenter.default.post(name: .HideAppFromDock, object: nil)
        }
    }
}

