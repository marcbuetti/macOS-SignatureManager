//
//  GeneralSettingsViewController.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 10.09.24.
//

/*import Cocoa

class GeneralSettingsViewController: NSViewController {
    
    @IBOutlet weak var startAppWithSystemSwitch: NSSwitch!
    @IBOutlet weak var startAppWithSystemSpinner: NSProgressIndicator!
    @IBOutlet weak var updateSignaturesWithStartSwitch: NSSwitch!
    @IBOutlet weak var showProcessByUpdatingSignaturesSwitch: NSSwitch!
    @IBOutlet weak var autoSearchForSoftwareupdatesSwitch: NSSwitch!
    @IBOutlet weak var autoInstallSoftwareupdatesSwitch: NSSwitch!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let startupState = StartupControlHelper.getAppStartupState() {
            if startupState == "true" {
                startAppWithSystemSwitch.state = NSControl.StateValue.on
            } else {
                startAppWithSystemSwitch.state = NSControl.StateValue.off
            }
        } else {
            SMX.exception(location: "Settings-GetStartupState", title: "Error by loading Startobjects state", body: "")
        }
                    
        updateSignaturesWithStartSwitch.state = UserDefaults.standard.bool(forKey: "updateSignaturesWithStart") ? .on : .off
        //showProcessByUpdatingSignaturesSwitch.state = UserDefaults.standard.bool(forKey: "showProcessByUpdatingSignatures") ? .on : .off
        autoSearchForSoftwareupdatesSwitch.state = UserDefaults.standard.bool(forKey: "SUEnableAutomaticChecks") ? .on : .off
        autoInstallSoftwareupdatesSwitch.state = UserDefaults.standard.bool(forKey: "SUAutomaticallyUpdate") ? .on : .off
    }
    
    @objc func handleConnectSheetDismissed() {
        self.startAppWithSystemSwitch.isEnabled = true
        self.startAppWithSystemSpinner.stopAnimation(self)
        self.startAppWithSystemSpinner.isHidden = true
    }
        
    @IBAction func toggelStartAppWithSystem(_ sender: Any) {
        if (startAppWithSystemSwitch.state == NSControl.StateValue.on) {
            startAppWithSystemSwitch.isEnabled = false
            startAppWithSystemSpinner.isHidden = false
            startAppWithSystemSpinner.startAnimation(self)
            StartupControlHelper.addAppToStartup()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.startAppWithSystemSwitch.isEnabled = true
                self.startAppWithSystemSpinner.stopAnimation(self)
                self.startAppWithSystemSpinner.isHidden = true
            }
        } else {
            startAppWithSystemSwitch.isEnabled = false
            startAppWithSystemSpinner.isHidden = false
            startAppWithSystemSpinner.startAnimation(self)
            StartupControlHelper.removeAppFromStartup()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.startAppWithSystemSwitch.isEnabled = true
                self.startAppWithSystemSpinner.stopAnimation(self)
                self.startAppWithSystemSpinner.isHidden = true
            }
        }
    }
    
    @IBAction func toggleUpdateSignaturesWithStart(_ sender: Any) {
        if (updateSignaturesWithStartSwitch.state == NSControl.StateValue.on) {
            UserDefaults.standard.set(true, forKey: "updateSignaturesWithStart")
        } else {
            UserDefaults.standard.set(false, forKey: "updateSignaturesWithStart")
        }
    }
    
    @IBAction func toogleShowProcessByUpdatingSignatures(_ sender: Any) {
        if (showProcessByUpdatingSignaturesSwitch.state == NSControl.StateValue.on) {
            UserDefaults.standard.set(true, forKey: "showProcessByUpdatingSignatures")
        } else {
            UserDefaults.standard.set(false, forKey: "showProcessByUpdatingSignatures")
        }
    }
    
    @IBAction func toggleAutoSearchForSoftwareupdates(_ sender: Any) {
        if (autoSearchForSoftwareupdatesSwitch.state == NSControl.StateValue.on) {
            UserDefaults.standard.set(true, forKey: "SUEnableAutomaticChecks")
        } else {
            UserDefaults.standard.set(false, forKey: "SUEnableAutomaticChecks")
        }
    }
    
    @IBAction func toggleAutoInstallSoftwareupdates(_ sender: Any) {
        if (autoInstallSoftwareupdatesSwitch.state == NSControl.StateValue.on) {
            UserDefaults.standard.set(true, forKey: "SUAutomaticallyUpdate")
        } else {
            UserDefaults.standard.set(false, forKey: "SUAutomaticallyUpdate")
        }
    }
    
}
*/
