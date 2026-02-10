//
//  AboutSettingsViewController.swift
//  Signature Manager
//
//  Created by Marc Büttner on 08.09.24.
//

/*import Cocoa
import Sparkle

class AboutSettingsViewController: NSViewController {
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var licensedForNameLabel: NSTextField!
    
    let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let _ = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            versionLabel.stringValue = "Version: \(version)"
            licensedForNameLabel.stringValue = "Lizensiert für " + SMX.getAppStringVar(key: "licensedForName")
        }
    }
    
    @IBAction func checkForUpdates(_ sender: Any) {
        let canCheckForUpdates = true
        if canCheckForUpdates {
            updaterController.checkForUpdates(sender)
        }
    }
}
*/
