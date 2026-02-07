//
//  RightsViewController.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 15.09.24.
//

/*import Cocoa
import LocalAuthentication
import UserNotifications

class SetupWizardViewController: NSViewController {
    
    @IBOutlet weak var image: NSImageView!
    
    @IBOutlet weak var userDirectoryLabel: NSTextField!
    @IBOutlet weak var userDirectoryLoader: NSProgressIndicator!
    @IBOutlet weak var userDirectoryImage: NSImageView!
    @IBOutlet weak var userDirectoryImageOK: NSImageView!
    @IBOutlet weak var userDirectoryImageERROR: NSImageView!
    
    @IBOutlet weak var executingLocalCommandsLabel: NSTextField!
    @IBOutlet weak var executingLocalCommandsLoader: NSProgressIndicator!
    @IBOutlet weak var executingLocalCommandsImage: NSImageView!
    @IBOutlet weak var executingLocalCommandsImageOK: NSImageView!
    @IBOutlet weak var executingLocalCommandsImageERROR: NSImageView!
    
    @IBOutlet weak var showNotificationsLabel: NSTextField!
    @IBOutlet weak var showNotificationsLoader: NSProgressIndicator!
    @IBOutlet weak var showNotificationsImage: NSImageView!
    @IBOutlet weak var showNotificationsImageOK: NSImageView!
    @IBOutlet weak var showNotificationsImageERROR: NSImageView!
    
    @IBOutlet weak var requestButton: NSButton!
    @IBOutlet weak var finishButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userDirectoryImageOK.isHidden = true
        userDirectoryImageERROR.isHidden = true
        executingLocalCommandsImageOK.isHidden = true
        executingLocalCommandsImageERROR.isHidden = true
        showNotificationsImageOK.isHidden = true
        showNotificationsImageERROR.isHidden = true
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) &&
                event.modifierFlags.contains(.control) &&
                event.charactersIgnoringModifiers == "s" {
                let context = LAContext()
                context.localizedFallbackTitle = "Passwort verwenden"
                var error: NSError?
                
                if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                    let reason = "dev.force.diskAccesss ausführen"
                    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                        DispatchQueue.main.async {
                            if success {
                                UserDefaults.standard.set(true, forKey: "rightsFullDiskAccess")
                                self.userDirectoryImage.isHidden = true
                                self.userDirectoryImageOK.isHidden = false
                                self.userDirectoryLoader.stopAnimation(self)
                                self.userDirectoryLoader.isHidden = true
                                
                                self.executingLocalCommandsImage.isHidden = true
                                self.executingLocalCommandsLoader.startAnimation(self)
                                self.executingLocalCommandsLoader.isHidden = false
                                NSApp.activate(ignoringOtherApps: true)
                                self.askAccessMailApp()
                            } else {
                                self.showNoAuthMethodAlert()
                            }
                        }
                    }
                } else {
                    self.showNoAuthMethodAlert()
                }
                return nil
            }
            return event
        }
    }
    
    @IBAction func start(_ sender: Any) {
        UserDefaults.standard.set(false, forKey: "swpSettingsGranted")
        
        userDirectoryImageOK.isHidden = true
        userDirectoryImageERROR.isHidden = true
        executingLocalCommandsImageOK.isHidden = true
        executingLocalCommandsImageERROR.isHidden = true
        showNotificationsImageOK.isHidden = true
        showNotificationsImageERROR.isHidden = true
        
        requestButton.isEnabled = false
        userDirectoryImage.isHidden = true
        userDirectoryImageOK.isHidden = true
        userDirectoryLoader.startAnimation(self)
        userDirectoryLoader.isHidden = false
        
        askFullDiskAccess()
    }
    
    public func hasFullDiskAccess() -> Bool {
        let fileManager = FileManager.default
        let userDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        let testPath = "\(userDirectory)/Library/Mail/V10"
        do {
            let _ = try fileManager.contentsOfDirectory(atPath: testPath)
            return true
        } catch {
            print("FDA check failed: \(error.localizedDescription)")
            return false
        }
    }
    
    private func askFullDiskAccess() {
        _ = LAContext()
        var _: NSError?
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if (SMX.hasFullDiskAccess()) {
                UserDefaults.standard.set(true, forKey: "rightsFullDiskAccess")
                self.userDirectoryImage.isHidden = true
                self.userDirectoryImageOK.isHidden = false
                self.userDirectoryLoader.stopAnimation(self)
                self.userDirectoryLoader.isHidden = true
                
                self.executingLocalCommandsImage.isHidden = true
                self.executingLocalCommandsLoader.startAnimation(self)
                self.executingLocalCommandsLoader.isHidden = false
                NSApp.activate(ignoringOtherApps: true)
                self.askAccessMailApp()
            } else {
                self.openFullDiskAccessSettingsAndWait()
            }
        }
    }
    
    private func openFullDiskAccessSettingsAndWait() {
        let fullDiskAccessSettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(fullDiskAccessSettingsURL)
        let timeout: TimeInterval = 120
        let startTime = Date()
        
        self.userDirectoryLoader.startAnimation(self)
        
        DispatchQueue.global(qos: .background).async {
            while !self.hasFullDiskAccess() {
                if Date().timeIntervalSince(startTime) > timeout {
                    DispatchQueue.main.async {
                        self.handleTimeout()
                    }
                    return
                }
                sleep(1)
            }
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: "rightsFullDiskAccess")
                self.userDirectoryImage.isHidden = true
                self.userDirectoryImageOK.isHidden = false
                self.userDirectoryLoader.stopAnimation(self)
                self.userDirectoryLoader.isHidden = true
                
                self.executingLocalCommandsImage.isHidden = true
                self.executingLocalCommandsLoader.startAnimation(self)
                self.executingLocalCommandsLoader.isHidden = false
                NSApp.activate(ignoringOtherApps: true)
                self.askAccessMailApp()
            }
        }
    }
    
    private func handleTimeout() {
        self.userDirectoryLoader.stopAnimation(self)
        self.userDirectoryLoader.isHidden = true
        self.userDirectoryImage.isHidden = true
        self.userDirectoryImageERROR.isHidden = false
        
        UserDefaults.standard.set(false, forKey: "rightsFullDiskAccess")
    }
    
    private func handleAuthError(error: Error?) {
        UserDefaults.standard.set(false, forKey: "rightsFullDiskAccess")
        self.userDirectoryImage.isHidden = true
        self.userDirectoryImageERROR.isHidden = false
        self.userDirectoryLoader.stopAnimation(self)
        self.userDirectoryLoader.isHidden = true
    }
    
    private func askAccessMailApp() {
        let context = LAContext()
        context.localizedFallbackTitle = "Passwort verwenden"
        var error: NSError?
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NSApp.activate(ignoringOtherApps: true)
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                let reason = "auf Mail zugreifen"
                
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                    DispatchQueue.main.async {
                        if success {
                            UserDefaults.standard.set(true, forKey: "rightsAccessMailApp")
                            self.executingLocalCommandsImage.isHidden = true
                            self.executingLocalCommandsImageOK.isHidden = false
                            self.executingLocalCommandsLoader.stopAnimation(self)
                            self.executingLocalCommandsLoader.isHidden = true
                            
                            self.showNotificationsImage.isHidden = true
                            self.showNotificationsLoader.startAnimation(self)
                            self.showNotificationsLoader.isHidden = false
                            NSApp.activate(ignoringOtherApps: true)
                            self.askShowNotifications()
                        } else {
                            print("Auth error: \(authenticationError?.localizedDescription ?? "Unbekannt")")
                            self.handleAuthError(error: authenticationError)
                        }
                    }
                }
            } else {
                self.showNoAuthMethodAlert()
            }
        }
    }
    
    private func askShowNotifications() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    self.showNotificationsImage.isHidden = true
                    self.showNotificationsImageERROR.isHidden = false
                    self.showNotificationsLoader.stopAnimation(self)
                    self.showNotificationsLoader.isHidden = true
                    NSApp.activate(ignoringOtherApps: true)
                    print("Fehler beim Anfordern der Benachrichtigungsrechte: \(error.localizedDescription)")
                    UserDefaults.standard.set(false, forKey: "rightsShowNotifications")
                }
                DispatchQueue.main.async {
                    self.showNotificationsImage.isHidden = true
                    self.showNotificationsImageOK.isHidden = false
                    self.showNotificationsLoader.stopAnimation(self)
                    self.showNotificationsLoader.isHidden = true
                    NSApp.activate(ignoringOtherApps: true)
                }
                print("Benachrichtigungsrechte gewährt: \(granted)")
                UserDefaults.standard.set(true, forKey: "rightsShowNotifications")
                //self.completeCheckout()
                self.connectToServer()
            }
        }
    }
    
    
    private func connectToServer() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        DispatchQueue.main.async {
            guard let connectToServerViewController = storyboard.instantiateController(withIdentifier: "ConnectToServerViewController") as? AutodiscoverViewController else {
                print("ViewController konnte nicht gefunden werden.")
                return
            }
            connectToServerViewController.onComplete = {
                self.completeCheckout()
            }
            self.presentAsSheet(connectToServerViewController)
        }
    }
    
    
    private func completeCheckout() {
        let rightsUserDirectory = UserDefaults.standard.bool(forKey: "rightsFullDiskAccess")
        let rightsExecutingLocalCommands = UserDefaults.standard.bool(forKey: "rightsAccessMailApp")
        let rightsShowNotifications = UserDefaults.standard.bool(forKey: "rightsShowNotifications")
        
        let clientId = UserDefaults.standard.string(forKey: "clientId")
        let tenantId = UserDefaults.standard.string(forKey: "tenantId")
        let clientSecret = UserDefaults.standard.string(forKey: "clientSecret")
        let licensedForName = UserDefaults.standard.string(forKey: "licensedForName")
        
        if rightsUserDirectory && rightsExecutingLocalCommands && rightsShowNotifications
            && !(clientId?.isEmpty ?? true)
            && !(tenantId?.isEmpty ?? true)
            && !(clientSecret?.isEmpty ?? true)
            && !(licensedForName?.isEmpty ?? true) {
            DispatchQueue.main.async {
                self.finishButton.isHidden = false
                self.requestButton.isHidden = true
            }
        } else {
            DispatchQueue.main.async {
                self.requestButton.isEnabled = true
            }
        }
    }
    
    @IBAction func finish(_ sender: Any) {
        self.view.window?.close()
        showUpdateAlert()
    }
    
    private func showAuthFailedAlert() {
        let alert = NSAlert()
        alert.messageText = "Authentifizierung fehlgeschlagen"
        alert.informativeText = "Sie konnten sich nicht authentifizieren. Bitte versuchen Sie es erneut."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showNoAuthMethodAlert() {
        let alert = NSAlert()
        alert.messageText = "Touch ID oder Passwort erforderlich"
        alert.informativeText = "Sie müssen sich authentifizieren, um Signatur Verwaltung zu beenden."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func showUpdateAlert() {
        let alert = NSAlert()
        alert.messageText = "Einrichtung abgeschlossen."
        alert.informativeText = "Möchten Sie mit der Aktualisierung der Signaturen fortfahren?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Ja")
        alert.addButton(withTitle: "Nein")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            SMX.updateSignatures()
        }
    }
}

extension Notification.Name {
    static let didDismissConnectSheet = Notification.Name("didDismissConnectSheet")
}
*/
