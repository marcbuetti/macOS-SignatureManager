//
//  AppManager.swift
//  Signature Manager
//
//  Created by Marc Büttner on 08.09.25.
//

import SwiftUI
import AppKit

class AppManager {

    static func quit() {

        SecurityManager.authenticateUser(
            reason: String(localized: "QUIT_BY_USER")
        ) { success in

            guard success else {
                Logger.shared.log(
                    position: "AppManager.quit",
                    type: "WARNING",
                    content: "User authentication failed"
                )

                let alert = NSAlert()
                alert.messageText = String(localized: "AUTHENTICATION_FAILED")
                alert.informativeText = String(localized: "AUTHENTICATION_FAILED_RETRY")
                alert.alertStyle = .critical
                alert.addButton(withTitle: "OK")
                alert.runModal()
                return
            }

            // ✅ Auth ok → sauber abmelden
            let graphService = GraphService()
            let semaphore = DispatchSemaphore(value: 0)

            graphService.updateRemoteStatus(status: "offline", remote: false) {
                semaphore.signal()
            }

            semaphore.wait()
            NSApplication.shared.terminate(self)
        }
    }
}
