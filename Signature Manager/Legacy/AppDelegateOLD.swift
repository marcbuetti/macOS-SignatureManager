/*import Cocoa
 import Sparkle
 import LocalAuthentication
 
 
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    
    var statusItem: NSStatusItem!
    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var signaturesStatusMenuItem: NSMenuItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UserDefaults.standard.set(false, forKey: "isRemoteUpdate")
        
        let graphService = GraphService()
        graphService.checkConnection(printout: true)
        graphService.reigsterRemoteDevice()
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            //button.image = NSImage(systemSymbolName: "exclamationmark.icloud.fill", accessibilityDescription: "Signatur Verwaltung: Fehler")
            button.image = NSImage(systemSymbolName: "signature", accessibilityDescription: "Signatur Verwaltung: Aktuell.")
            button.toolTip = "Signatur Verwaltung 2: Aktuell."
        }
        statusItem.menu = menu
        
        graphService.updateRemoteStatus(status: "idle", requestor: "local")
        
        if UserDefaults.standard.bool(forKey: "updateSignaturesWithStart") {
            //SMX.updateSignatures()
        }
        
        
        do { try Logger.shared.rotateLogFileIfNeeded()
        } catch {
            print ("CRITICAL: Could not rotate log file: \(error)")
        }
    }
    
    

    @IBAction func checkForUpdates(_ sender: Any) {
        let mainStoryboard = NSStoryboard(name: "Main", bundle: nil)
        if let settingsWindowController = mainStoryboard.instantiateController(withIdentifier: "UpdateX2WindowController") as? NSWindowController {
            settingsWindowController.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            print("UpdateWindowController konnte nicht gefunden werden.")
        }
        let graphService = GraphService()
        graphService.updateRemoteStatus(status: "updating", requestor: "local")
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath.icloud.fill", accessibilityDescription: "Signatur Verwaltung: Aktualisieren...")
            button.toolTip = "Signatur Verwaltung: Aktualisieren..."
        }
    }
}
*/
