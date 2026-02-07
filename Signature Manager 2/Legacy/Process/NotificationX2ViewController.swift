//
//  NotificationX2ViewController.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 17.09.24.
//

/*import Cocoa
import AppKit
import Foundation
import UserNotifications
import SystemConfiguration

class NotificationX2ViewController: NSViewController {
    
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var processLabel: NSTextField!
    var mailWasRunning = false
    var errorCode = ""
    var signaturesToUpdate: [(String, String, String)] = []
    var currentIndex = 0
    
    let graphService = GraphService()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let visualEffectView = NSVisualEffectView(frame: view.bounds)
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.material = .hudWindow
        
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 15
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.layer?.borderColor = NSColor(calibratedWhite: 0.3, alpha: 0.8).cgColor
        visualEffectView.layer?.borderWidth = 0.5
        
        view.addSubview(visualEffectView, positioned: .below, relativeTo: nil)
        view.wantsLayer = true
        view.layer?.cornerRadius = 15
        view.layer?.masksToBounds = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        
        let remote = UserDefaults.standard.bool(forKey: "isRemoteUpdate")
        if remote {
            self.processLabel.stringValue = "Vorbereiten... - Von Ihrer Organisation angefordert"
        } else {
            self.processLabel.stringValue = "Vorbereiten..."
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        let remote = UserDefaults.standard.bool(forKey: "isRemoteUpdate")
        if remote {
            self.processLabel.stringValue = "Vorbereiten... - Von Ihrer Organisation angefordert"
        } else {
            self.processLabel.stringValue = "Vorbereiten..."
        }
        
        loadSignatures()
        progress.isIndeterminate = true
        progress.startAnimation(self)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkMailAndProceed()
        }
    }
    
    func checkIfHtmlFileExists(forSignatureId signatureId: String) -> Bool {
        let fileManager = FileManager.default
        let signatureHtmlPath = "~/Library/Mail/V10/MailData/Signatures/\(signatureId).mailsignature"
        let expandedPath = NSString(string: signatureHtmlPath).expandingTildeInPath
        
        if fileManager.fileExists(atPath: expandedPath) {
            return true
        } else {
            print("HTML-Datei für Signatur-ID \(signatureId) nicht gefunden.")
            Logger.shared.log(position: "PROCESS", type:"WARNING", content: "HTML-File for Signature-ID \(signatureId) not found at \(expandedPath)!")
            return false
        }
    }
    
    func checkIfSignatureFileExists(forSignatureId signatureId: String) -> Bool {
        let fileManager = FileManager.default
        let signatureFilePath = "~/Library/Mail/V10/MailData/Signatures/\(signatureId).mailsignature"
        let expandedPath = NSString(string: signatureFilePath).expandingTildeInPath
        
        if fileManager.fileExists(atPath: expandedPath) {
            return true
        } else {
            print("Signatur-Datei für Signatur-ID \(signatureId) nicht gefunden.")
            Logger.shared.log(position: "PROCESS", type:"WARNING", content: "Signature-File for Signature-ID \(signatureId) not found!")
            return false
        }
    }
    
    private func loadSignatures() {
        signaturesToUpdate.removeAll()
        let signatureCount = UserDefaults.standard.integer(forKey: "app.signatures.count")
        var failedSignaturesHtml: [String] = []
        var failedSignaturesFiles: [String] = []
        
        if signatureCount > 0 {
            for index in 1...signatureCount {
                let idKey = "signature\(index)ID"
                let nameKey = "signature\(index)Name"
                let htmlKey = "signature\(index)HTML"
                
                if let id = UserDefaults.standard.string(forKey: idKey),
                   let name = UserDefaults.standard.string(forKey: nameKey),
                   let html = UserDefaults.standard.string(forKey: htmlKey),
                   !id.isEmpty, !name.isEmpty, !html.isEmpty {
                    signaturesToUpdate.append((id, html, name))
                    
                    let htmlExists = checkIfHtmlFileExists(forSignatureId: id)
                    if !htmlExists {
                        failedSignaturesHtml.append(name)
                    }
                    
                    let signatureExists = checkIfSignatureFileExists(forSignatureId: id)
                    if !signatureExists {
                        failedSignaturesFiles.append(name)
                    }
                }
            }
            
            if !failedSignaturesHtml.isEmpty {
                let failedHtmlSignaturesString = failedSignaturesHtml.joined(separator: ", ") // Namen mit Komma trennen
                showAlert(title: "HTML-Dateien fehlen", message: "Die folgenden Signaturen haben keine zugehörige HTML-Datei: \(failedHtmlSignaturesString)")
            }
            
            if !failedSignaturesFiles.isEmpty {
                let failedSignatureFilesString = failedSignaturesFiles.joined(separator: ", ") // Namen mit Komma trennen
                showAlert(title: "Signatur-Dateien fehlen", message: "Die folgenden Signaturen haben keine zugehörige Signatur-Datei: \(failedSignatureFilesString)")
            }
        }
    }
    
    func checkMailAndProceed() {
        mailWasRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.apple.mail"
        }
        
        if mailWasRunning {
            let remote = UserDefaults.standard.bool(forKey: "isRemoteUpdate")
            let graphService = GraphService()
            if remote {
                graphService.stopRemoteUpdateChecker()
            }
            showUpdateAlert()
        } else {
            updateNextSignature()
        }
    }
    
    func showUpdateAlert() {
        let alert = NSAlert()
        alert.messageText = "Aktualisierung der Signaturen"
        alert.informativeText = "Signature Manager möchte Mail schließen, um Signaturen zu aktualisieren. Möchten Sie fortfahren?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Ja")
        alert.addButton(withTitle: "Nein")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            updateNextSignature()
        } else {
            Logger.shared.log(position: "PROCESS", type:"INFO", content: "Process was stopped by user action.")
            self.finishUpdate(success: false)
        }
    }
    
    func updateNextSignature() {
        while currentIndex < signaturesToUpdate.count {
            let (signatureId, htmlContent, name) = signaturesToUpdate[currentIndex]
            
            if signatureId.isEmpty || htmlContent.isEmpty || name.isEmpty {
                currentIndex += 1
                continue
            }
            
            Logger.shared.log(position: "PROCESS", type:"INFO", content: "Updating Signature-ID \(signatureId) with HTML-Content \(htmlContent).")
            graphService.updateRemoteStatus(status: "updating", requestor: "local")
            let remote = UserDefaults.standard.bool(forKey: "isRemoteUpdate")
            if remote {
                self.processLabel.stringValue = "Aktualisieren: \(name) - Von Ihrer Organisation angefordert"
            } else {
                self.processLabel.stringValue = "Aktualisieren: \(name)"
            }
            updateMailSignature(signatureId: signatureId, htmlContent: htmlContent) { success in
                DispatchQueue.main.async {
                    if success {
                        self.currentIndex += 1
                        if self.currentIndex < self.signaturesToUpdate.count {
                            self.updateNextSignature()
                        } else {
                            self.finishUpdate(success: true)
                        }
                    } else {
                        self.finishUpdate(success: false)
                    }
                }
            }
            return
        }
        finishUpdate(success: true)
    }
    
    func updateMailSignature(signatureId: String, htmlContent: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            
            let signaturePath = NSString(string: "~/Library/Mail/V10/MailData/Signatures/\(signatureId).mailsignature").expandingTildeInPath
            let tempPath = "/tmp/\(signatureId).mailsignature"
            
            guard fileManager.fileExists(atPath: signaturePath) else {
                completion(false)
                return
            }
            
            let htmlFilePath = NSString(string: htmlContent).expandingTildeInPath
            guard let htmlContentString = try? String(contentsOfFile: htmlFilePath, encoding: .utf8) else {
                Logger.shared.log(position: "PROCESS", type:"CRITICAL", content: "Error by reading HTML file \(htmlFilePath).")
                completion(false)
                return
            }
            
            do {
                self.runShellCommand("pkill Mail")
                self.runShellCommand("chflags nouchg \(signaturePath)")
                
                
                if fileManager.fileExists(atPath: tempPath) {
                    try fileManager.removeItem(atPath: tempPath)
                }
                
                try fileManager.copyItem(atPath: signaturePath, toPath: tempPath)
                
                let signatureContent = try String(contentsOfFile: tempPath, encoding: .utf8)
                let signatureHeaderLines = signatureContent.components(separatedBy: "\n").prefix(6).joined(separator: "\n")
                let finalSignatureContent = "\(signatureHeaderLines)\n\n\(htmlContentString)"
                try finalSignatureContent.write(toFile: tempPath, atomically: true, encoding: .utf8)
                
                self.runShellCommand("chflags nouchg \(tempPath)")
                try fileManager.removeItem(atPath: signaturePath)
                try fileManager.copyItem(atPath: tempPath, toPath: signaturePath)
                self.runShellCommand("chflags uchg \(signaturePath)")
                
                completion(true)
            } catch {
                Logger.shared.log(position: "PROCESS", type:"CRITICAL", content: "Error by updating mail signature: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    func finishUpdate(success: Bool) {
        DispatchQueue.main.async {
            if success {
                self.progress.stopAnimation(self)
                self.progress.isIndeterminate = false
                self.progress.doubleValue = 100
                let remote = UserDefaults.standard.bool(forKey: "isRemoteUpdate")
                if remote {
                    self.processLabel.stringValue = "Abgeschlossen. - Von Ihrer Organisation angefordert"
                } else {
                    self.processLabel.stringValue = "Abgeschlossen."
                }
                self.graphService.updateRemoteStatus(status: "idle", requestor: "local")
                
                if self.mailWasRunning {
                    let script = """
                        tell application "Mail"
                            activate
                        end tell
                        """
                    let appleScript = NSAppleScript(source: script)
                    var error: NSDictionary?
                    appleScript?.executeAndReturnError(&error)
                    if let error = error {
                        print("Error reopening Mail: \(error)")
                    }
                }
                
                let appDelegate = NSApplication.shared.delegate as? AppDelegate
                let button = appDelegate?.statusItem.button
                let signaturesStatusMenuItem = appDelegate?.signaturesStatusMenuItem
                DispatchQueue.main.async {
                    button?.image = NSImage(systemSymbolName: "signature", accessibilityDescription: "Signatur Verwaltung: Aktuell")
                    button?.toolTip = "Signatur Verwaltung: Aktuell"
                    signaturesStatusMenuItem?.title = "Signaturen: Aktuell"
                    signaturesStatusMenuItem?.image = NSImage(named: NSImage.statusAvailableName)
                }
                
                UserDefaults.standard.set(false, forKey: "isRemoteUpdate")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.slideOutProcess()
                }
            
                self.graphService.startRemoteUpdateChecker()
            } else {
                let appDelegate = NSApplication.shared.delegate as? AppDelegate
                let button = appDelegate?.statusItem.button
                let signaturesStatusMenuItem = appDelegate?.signaturesStatusMenuItem
                DispatchQueue.main.async {
                    button?.image = NSImage(systemSymbolName: "signature", accessibilityDescription: "Signatur Verwaltung: Aktualisierung abgebrochen.")
                    button?.toolTip = "Signatur Verwaltung: Aktualisierung abgebrochen."
                    signaturesStatusMenuItem?.title = "Signaturen: Aktualisierung abgebrochen."
                    signaturesStatusMenuItem?.image = NSImage(named: NSImage.statusUnavailableName)
                }
                
                self.progress.stopAnimation(self)
                self.progress.isIndeterminate = false
                self.progress.doubleValue = 100
                let remote = UserDefaults.standard.bool(forKey: "isRemoteUpdate")
                if remote {
                    self.processLabel.stringValue = "Abgebrochen. - Von Ihrer Organisation angefordert"
                } else {
                    self.processLabel.stringValue = "Abgebrochen."
                }
                self.graphService.updateRemoteStatus(status: "idle", requestor: "local")
                
                UserDefaults.standard.set(false, forKey: "isRemoteUpdate")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.slideOutProcess()
                }
            }
        }
    }
        
    @discardableResult
    func runShellCommand(_ command: String) -> Bool {
        let process = Process()
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", command]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        process.launch()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? "Keine Ausgabe"
    
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
        
        Logger.shared.log(position: "PROCESS.RUNNER", type:"INFO", content: "Running command \(command) with result \(output).")
        
        if !errorOutput.isEmpty {
            DispatchQueue.main.async {
                self.showAlert(title: "Fehler aufgetreten", message: errorOutput)
                Logger.shared.log(position: "PROCESS.RUNNER", type:"CRITICAL", content: "Error by runnning updating command \(command).")
            }
            return false
        }
        
        return true
    }
    
    func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func slideOutProcess() {
        guard let window = self.view.window else {
            return
        }
        
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let windowWidth = window.frame.width
        let windowHeight = window.frame.height
        let offScreenPosition = NSRect(x: screenFrame.width, y: screenFrame.height - windowHeight - 60, width: windowWidth, height: windowHeight) //
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().setFrame(offScreenPosition, display: true)
        }, completionHandler: {
            window.close()
        })
    }
}
*/
