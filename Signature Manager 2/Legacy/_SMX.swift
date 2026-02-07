//
//  SMX.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 10.09.24.
//

/*import Cocoa
import Foundation
import UserNotifications

class SMX {
    
    static func inizializeDTX() {
        notificationAuthorize()
        SMXinfo(message: "DTX Inizialized!")
    }
    
    // MARK: Inizializes
    private static func notificationAuthorize() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                SMXerror(message: "Error by requesting of Notification rights: \(error.localizedDescription)")
            }
            SMXinfo(message: "Notification rights granted: \(granted)")
        }
    }
    
    
    
    //MARK: Functions
    //-------------------------------------------------------------------------------------
    static func notification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    
    static func exception(location: String, title: String, body: String) {
        DispatchQueue.main.async {
            print("\(title): \(body)")
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = body
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Report this error to the developer")
            
            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                UserDefaults.standard.set("\(location)", forKey: "exceptionRaw")
                UserDefaults.standard.set("\(location) |-| \(body)", forKey: "exceptionPoint")
                let mainStoryboard = NSStoryboard(name: "Main", bundle: nil)
                let settingsWindowController = mainStoryboard.instantiateController(withIdentifier: "ReportWindowController") as! NSWindowController
                settingsWindowController.window?.center()
                settingsWindowController.window?.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            SMXException(location: location, message: body)
        }
    }
    //-------------------------------------------------------------------------------------
    
    
    
    // MARK: Helpers
    public static func SMXinfo(message: String) {
        print("SMX INFO: \(message)")
    }
    
    public static func SMXerror(message: String) {
        print("SMX ERROR: \(message)")
    }
    
    public static func SMXException(location: String, message: String) {
        print("SMX EXCEPTION: \(location)|\(message)")
    }
    
    public static func hasFullDiskAccess() -> Bool {
        let fileManager = FileManager.default
        let userDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        let testPath = "\(userDirectory)/Library/Mail/V10/MailData/Signatures"
        return fileManager.isReadableFile(atPath: testPath)
    }
    
    public static func updateSignatures() {
        if (!SMX.hasFullDiskAccess()) {
            let mainStoryboard = NSStoryboard(name: "Main", bundle: nil)
            if let rightsWindowController = mainStoryboard.instantiateController(withIdentifier: "SetupWizardWindowController") as? NSWindowController {
                rightsWindowController.window?.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                print("RightsWindowController konnte nicht gefunden werden.")
            }
        } else {
            
            // UPDATE
            let mainStoryboard = NSStoryboard(name: "Main", bundle: nil)
            if let processWindowController = mainStoryboard.instantiateController(withIdentifier: "UpdateX2WindowController") as? NSWindowController {
                processWindowController.window?.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                print("UpdateWindowController konnte nicht gefunden werden.")
            }
            
            let appDelegate = NSApplication.shared.delegate as? AppDelegate
            let button = appDelegate?.statusItem.button
            let signaturesStatusMenuItem = appDelegate?.signaturesStatusMenuItem
            DispatchQueue.main.async {
                button?.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath.icloud.fill", accessibilityDescription: "Signatur Verwaltung 2: Aktualisieren...")
                button?.toolTip = "Signatur Verwaltung 2: Aktualisieren..."
                signaturesStatusMenuItem?.title = "Signaturen: Aktualisieren..."
                signaturesStatusMenuItem?.image = NSImage(named: NSImage.statusAvailableName)
            }
        }
    }
    
    public static func localize(key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
    public static func getAppStringVar(key: String) -> String {
        return UserDefaults.standard.string(forKey: key) ?? "%appStringVar"
    }
    
    public static func setAppStringVar(key: String, value: String?, forceSync: Bool = false) {
        guard let value = value else { return }
        UserDefaults.standard.set(value, forKey: key)
        if (forceSync == true) {
            UserDefaults.standard.synchronize()
        }
    }
    
    //TODO: getAppVar with Check is user default exists //
    
}
  

*/
