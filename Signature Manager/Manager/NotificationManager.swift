//
//  NotificationManager.swift
//  Signature Manager
//
//  Created by Marc Büttner on 07.02.26.
//

import UserNotifications

class NotificationManager {
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
}
