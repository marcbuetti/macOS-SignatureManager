//
//  ThankYouViewController.swift
//  DevTools 2
//
//  Created by Marc Büttner on 29.02.24.
//

/*import Cocoa

class ThankYouViewController: NSViewController {
    
    @IBOutlet weak var progressBar: NSProgressIndicator!
    var progressTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeProgressBar()
        startCountdown()
    }
    
    func initializeProgressBar() {
        progressBar.maxValue = 100
        progressBar.doubleValue = 100
    }
    
    func startCountdown() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.10, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            if self.progressBar.doubleValue > 0 {
                self.progressBar.doubleValue -= 1
            } else {
                timer.invalidate()
                self.view.window?.close()
            }
        }
    }
    
    @IBAction func openIssueOnWeb(_ sender: Any) {
        if let issueUrl = UserDefaults.standard.string(forKey: "issueUrl") {
            guard let url = URL(string: "\(issueUrl)") else {
                print("Ungültige URL")
                return
            }
            
            NSWorkspace.shared.open(url)
        }
    }
}*/
