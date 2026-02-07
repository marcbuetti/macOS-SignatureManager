//
//  AppManager.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 08.09.25.
//

import SwiftUI
import UserNotifications
import LocalAuthentication


class AppManager {
    
    static func quit() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: String(localized: "QUIT_BY_USER")) { success, authenticationError in
                
                if success == false {
                    if let authenticationError = authenticationError {
                        Logger.shared.log(position: "AppManager.quit", type: "CRITICAL", content: "evaluatePolicy error: \(authenticationError.localizedDescription)")
                    } else {
                        Logger.shared.log(position: "AppManager.quit", type: "WARNING", content: "Authentication failed without error")
                    }
                }
                
                DispatchQueue.main.async {
                    if success {
                        let graphService = GraphService()
                        let semaphore = DispatchSemaphore(value: 0)
                        graphService.updateRemoteStatus(status: "offline", remote: false) {
                            semaphore.signal()
                        }
                        semaphore.wait()
                        NSApplication.shared.terminate(self)
                    } else {
                        let alert = NSAlert()
                        alert.messageText = String(localized: "AUTHENTICATION_FAILED")
                        alert.informativeText = String(localized: "AUTHENTICATION_FAILED_RETRY")
                        alert.alertStyle = .critical
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
            }
        } else {
            if let error = error {
                Logger.shared.log(position: "AppManager.quit", type: "CRITICAL", content: "canEvaluatePolicy failed: \(error.localizedDescription)")
            } else {
                Logger.shared.log(position: "AppManager.quit", type: "WARNING", content: "canEvaluatePolicy not available without error")
            }
            let alert = NSAlert()
            alert.messageText = String(localized: "TOUCH_ID_OR_PASSWORD_REQUIRED")
            alert.informativeText = String(localized: "AUTHENTICATION_REQUIRED_TO_QUIT")
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
            
        }
    }
    
    
    private static func notificationAuthorize(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Logger.shared.log(position: "AppManager.notificationAuthorize", type: "CRITICAL", content: "Notification authorization error: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(granted)
        }
    }
    
    static func notification(title: String, body: String) {
        notificationAuthorize { granted in
            guard granted else {
                Logger.shared.log(position: "AppManager.notification", type: "WARNING", content: "Notification permission not granted; skipping notification")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    Logger.shared.log(position: "AppManager.notification", type: "CRITICAL", content: "Failed to schedule notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    static func hasFullDiskAccess() -> Bool {
        let fileManager = FileManager.default
        let userDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        let testPath = "\(userDirectory)/Library/Mail/V10/MailData/Signatures"
        let readable = fileManager.isReadableFile(atPath: testPath)
        if !readable {
            Logger.shared.log(position: "AppManager.hasFullDiskAccess", type: "WARNING", content: "No read access to: \(testPath)")
        }
        return readable
    }
    
    public static func localize(key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
}

