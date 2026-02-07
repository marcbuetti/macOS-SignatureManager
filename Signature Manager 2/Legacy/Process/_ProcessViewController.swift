//
//  ViewController.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 08.09.24.
//

/*import Cocoa
import AppKit
import Foundation
import UserNotifications
import SystemConfiguration

class ProcessViewController: NSViewController {

    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var processLabel: NSTextField!
    var mailWasRunning = false
    var errorCode = ""
    
    // Liste der Signaturen und zugehörigen Dateipfade
    var signaturesToUpdate: [(String, String, String)] = []
    var currentIndex = 0
    
    override func viewDidAppear() {
        super.viewDidAppear()
        loadSignatures()
        progress.isIndeterminate = true
        progress.startAnimation(self)
        
        // Direkt fortfahren mit Mail-Check und Signatur-Update
        checkMailAndProceed()
    }
    
    func checkIfHtmlFileExists(forSignatureId signatureId: String) -> Bool {
        let fileManager = FileManager.default
        // Pfad zur HTML-Datei basierend auf der Signatur-ID
        let signatureHtmlPath = "~/Library/Mail/V10/MailData/Signatures/\(signatureId).mailsignature"
        // Pfad mit Home-Verzeichnis auflösen
        let expandedPath = NSString(string: signatureHtmlPath).expandingTildeInPath
        
        // Überprüfen, ob die Datei im Dateisystem existiert
        if fileManager.fileExists(atPath: expandedPath) {
            print("HTML-Datei für Signatur-ID \(signatureId) gefunden: \(expandedPath)")
            return true
        } else {
            print("HTML-Datei für Signatur-ID \(signatureId) nicht gefunden.")
            return false
        }
    }
    
    func checkIfSignatureFileExists(forSignatureId signatureId: String) -> Bool {
        let fileManager = FileManager.default
        let signatureFilePath = "~/Library/Mail/V10/MailData/Signatures/\(signatureId).mailsignature"
        let expandedPath = NSString(string: signatureFilePath).expandingTildeInPath
        
        if fileManager.fileExists(atPath: expandedPath) {
            print("Signatur-Datei für Signatur-ID \(signatureId) gefunden: \(expandedPath)")
            return true
        } else {
            print("Signatur-Datei für Signatur-ID \(signatureId) nicht gefunden.")
            return false
        }
    }
    
    private func loadSignatures() {
        signaturesToUpdate.removeAll()
        let signatureCount = UserDefaults.standard.integer(forKey: "app.signatures.count")
        var failedSignaturesHtml: [String] = [] // Liste für fehlende HTML-Dateien
        var failedSignaturesFiles: [String] = [] // Liste für fehlende Signatur-Dateien

        if signatureCount > 0 {
            for index in 1...signatureCount {
                let idKey = "signature\(index)ID"
                let nameKey = "signature\(index)Name"
                let htmlKey = "signature\(index)HTML"
                
                if let id = UserDefaults.standard.string(forKey: idKey),
                   let name = UserDefaults.standard.string(forKey: nameKey),
                   let html = UserDefaults.standard.string(forKey: htmlKey),
                   !id.isEmpty, !name.isEmpty, !html.isEmpty {
                    // Füge die Signatur der Liste hinzu
                    signaturesToUpdate.append((id, html, name))
                    
                    // Überprüfe, ob die HTML-Datei existiert
                    let htmlExists = checkIfHtmlFileExists(forSignatureId: id)
                    if !htmlExists {
                        failedSignaturesHtml.append(name) // Füge den Namen der fehlenden HTML-Datei zur Liste hinzu
                    }
                    
                    // Überprüfe, ob die Signatur-Datei existiert
                    let signatureExists = checkIfSignatureFileExists(forSignatureId: id)
                    if !signatureExists {
                        failedSignaturesFiles.append(name) // Füge den Namen der fehlenden Signatur-Datei zur Liste hinzu
                    }
                }
            }
            
            // Zeige Warnung für fehlende HTML-Dateien
            if !failedSignaturesHtml.isEmpty {
                let failedHtmlSignaturesString = failedSignaturesHtml.joined(separator: ", ") // Namen mit Komma trennen
                showAlert(title: "HTML-Dateien fehlen", message: "Die folgenden Signaturen haben keine zugehörige HTML-Datei: \(failedHtmlSignaturesString)")
            }
            
            // Zeige Warnung für fehlende Signatur-Dateien
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
            print("Vorgang durch Benutzer gestoppt.")
            DispatchQueue.main.async {
                self.progress.stopAnimation(self)
                self.progress.isIndeterminate = false
                self.progress.doubleValue = 0
            }
        }
    }
    
    func updateNextSignature() {
        while currentIndex < signaturesToUpdate.count {
            let (signatureId, htmlContent, name) = signaturesToUpdate[currentIndex]
            
            // Überspringe leere oder ungültige Signaturen
            if signatureId.isEmpty || htmlContent.isEmpty || name.isEmpty {
                currentIndex += 1
                continue
            }
            
            print("Aktualisiere Signatur-ID: \(signatureId) mit HTML-Inhalt.")
            self.processLabel.isHidden = false
            self.processLabel.stringValue = "(\(name))"
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
        
        // Wenn keine weiteren Signaturen zu aktualisieren sind oder alle übersprungen wurden
        finishUpdate(success: true)
    }
    
    func updateMailSignature(signatureId: String, htmlContent: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            
            let signaturePath = NSString(string: "~/Library/Mail/V10/MailData/Signatures/\(signatureId).mailsignature").expandingTildeInPath
            let tempPath = "/tmp/\(signatureId).mailsignature"
            
            // Überprüfe, ob die Signaturdatei existiert
            guard fileManager.fileExists(atPath: signaturePath) else {
                print("Signatur-Datei für Signatur-ID \(signatureId) nicht gefunden.")
                completion(false)
                return
            }
            
            // Pfad zur HTML-Datei
            let htmlFilePath = NSString(string: htmlContent).expandingTildeInPath
            
            // Lese den Inhalt der HTML-Datei
            guard let htmlContentString = try? String(contentsOfFile: htmlFilePath, encoding: .utf8) else {
                print("Fehler beim Lesen der HTML-Datei \(htmlFilePath).")
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
                print("Fehler beim Aktualisieren der Signatur: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    func finishUpdate(success: Bool) {
        DispatchQueue.main.async {
            if success {
                self.processLabel.isHidden = true
                self.progress.stopAnimation(self)
                self.progress.isIndeterminate = false
                self.progress.doubleValue = 100
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.view.window?.close()
                }
            } else {
                self.progress.stopAnimation(self)
                self.progress.isIndeterminate = false
                self.progress.doubleValue = 0
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

        print("Befehl: \(command)")
        print("Ausgabe: \(output)")
        if !errorOutput.isEmpty {
            DispatchQueue.main.async {
                self.showAlert(title: "Fehler aufgetreten", message: errorOutput)
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
}

*/
