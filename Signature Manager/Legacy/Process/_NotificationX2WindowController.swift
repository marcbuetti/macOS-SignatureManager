//
//  NotificationW.swift
//  Signature Manager
//
//  Created by Marc Büttner on 17.09.24.
//

/*import Cocoa

class NotificationX2WindowController: NSWindowController {
    
    var pubWindowHeight = 60
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let window = window else { return }
        window.alphaValue = 0.0
        
        // Check for SafeAreaInsets (MacBooks with Notch)
        if let screen = NSScreen.main {
            let safeAreaInsets = screen.safeAreaInsets

            if safeAreaInsets.top > 0 {
                pubWindowHeight = 60
            } else {
                pubWindowHeight = 40
            }
        }
        
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let windowWidth = window.frame.width
        let windowHeight = window.frame.height
        let offScreenPosition = NSRect(x: screenFrame.width, y: screenFrame.height - windowHeight - CGFloat(pubWindowHeight), width: windowWidth, height: windowHeight)
        
        window.setFrame(offScreenPosition, display: false)
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.level = .mainMenu + 1
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.isMovable = false
        window.isMovableByWindowBackground = false
        
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        slideInFromRight()
    }
    
    
    private func slideInFromRight() {
        guard let window = window else { return }
        
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let windowWidth = window.frame.width
        let windowHeight = window.frame.height
        let targetPosition = NSRect(x: screenFrame.width - windowWidth - 16, y: screenFrame.height - windowHeight - CGFloat(pubWindowHeight), width: windowWidth, height: windowHeight)
        
        window.alphaValue = 1.0
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)
            window.animator().setFrame(targetPosition, display: true)
        }, completionHandler: {
        })
    }
    
    func slideOutToRight() {
        guard let window = window else { return }
        
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let windowWidth = window.frame.width
        let windowHeight = window.frame.height
        let offScreenPosition = NSRect(x: screenFrame.width, y: screenFrame.height - windowHeight - CGFloat(pubWindowHeight), width: windowWidth, height: windowHeight) // Positioniert es wieder außerhalb
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().setFrame(offScreenPosition, display: true)
        }, completionHandler: {
            window.alphaValue = 0.0
            window.close()
        })
    }
}
*/
