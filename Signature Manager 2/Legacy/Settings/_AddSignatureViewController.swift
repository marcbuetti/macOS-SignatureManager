//
//  AddSignatureViewController.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 08.09.24.
//

/*import Cocoa
import Foundation

class AddSignatureViewController: NSViewController, NSComboBoxDelegate, NSComboBoxDataSource, NSTabViewDelegate {
    
    @IBOutlet weak var pageTitle: NSTextField!
    @IBOutlet weak var tabulator: NSTabView!
    @IBOutlet weak var automaticSignatureComboBox: NSComboBox!
    @IBOutlet weak var automaticSignatureName: NSTextField!
    @IBOutlet weak var automaticSignatureHTML: NSTextField!
    
    
    @IBOutlet weak var onlineM365SignatureName: NSTextField!
    @IBOutlet weak var onlineM365SignatureComboBox: NSComboBox!
    @IBOutlet weak var onlineM365SignatureFileComboBox: NSComboBox!
    @IBOutlet weak var onlineM365SignatureLabel: NSTextField!
    @IBOutlet weak var onlineM365SignatureProgressbar: NSProgressIndicator!
    
    @IBOutlet weak var saveButton: NSButton!
    
    var isEditing = false
    var existingSignature: (id: String, name: String, html: String)?
    
    var signatureIsCount: Int = 0
    var plistSignatures: [(name: String, uniqueId: String)] = [] // Plist-Signaturen
    var fileSignatures: [(name: String, uniqueId: String)] = [] // Datei-Signaturen
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.set(false, forKey: "app.swpSignatureListReload")
        loadSignaturesFromPlist()
        
        signatureIsCount = UserDefaults.standard.integer(forKey: "app.signatures.count")
        print("Aktuelle Signaturanzahl: \(signatureIsCount)")
        
        tabulator.delegate = self
        
        if isEditing, let signature = existingSignature {
            pageTitle.stringValue = "Signatur bearbeiten"
            onlineM365SignatureName.stringValue = signature.name
            automaticSignatureHTML.stringValue = signature.html
            
            if let selectedIndex = plistSignatures.firstIndex(where: { $0.uniqueId == signature.id }) {
                onlineM365SignatureComboBox.selectItem(at: selectedIndex)
                automaticSignatureComboBox.selectItem(at: selectedIndex)
                automaticSignatureName.stringValue = plistSignatures[selectedIndex].name
            }
        }
    }
    
    func loadSignaturesFromPlist() {
        let plistPath = NSString(string: "~/Library/Mail/V10/MailData/Signatures/AllSignatures.plist").expandingTildeInPath
        
        do {
            let plistData = try Data(contentsOf: URL(fileURLWithPath: plistPath))
            
            if let plistArray = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [[String: Any]] {
                if plistArray.isEmpty {
                    print("Keine Signaturen in der Plist gefunden.")
                    automaticSignatureComboBox.addItem(withObjectValue: "Keine Signaturen gefunden")
                    onlineM365SignatureComboBox.addItem(withObjectValue: "Keine Signaturen gefunden")
                } else {
                    for signatureDict in plistArray {
                        if let name = signatureDict["SignatureName"] as? String,
                           let uniqueId = signatureDict["SignatureUniqueId"] as? String {
                            plistSignatures.append((name: name, uniqueId: uniqueId))
                            
                            // Nur Plist-Signaturen zu den ComboBoxen hinzufügen
                            automaticSignatureComboBox.addItem(withObjectValue: name)
                            onlineM365SignatureComboBox.addItem(withObjectValue: name)
                        } else {
                            print("Fehler: Ungültige Signaturdaten in der Plist.")
                        }
                    }
                }
            } else {
                print("Fehler beim Parsen der Plist-Daten: Format nicht erkannt.")
            }
        } catch {
            print("Fehler beim Laden der Plist-Daten: \(error.localizedDescription)")
        }
        
        // Debugging: Ausgaben der geladenen Daten
        print("Geladene Plist-Signaturen:")
        plistSignatures.forEach { print("Name: \($0.name), ID: \($0.uniqueId)") }
        
        automaticSignatureComboBox.delegate = self
        automaticSignatureComboBox.dataSource = self
        onlineM365SignatureComboBox.delegate = self
        onlineM365SignatureComboBox.dataSource = self
    }
    
    func loadFilesFromDirectory(success: @escaping () -> Void, failure: @escaping () -> Void) {
        let graphService = GraphService()
        let fileManager = FileManager.default
        let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupportDir.appendingPathComponent("Signature Manager 2/OnlineSignatures", isDirectory: true)
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
        
        onlineM365SignatureProgressbar.isHidden = false
        onlineM365SignatureProgressbar.doubleValue = 0
        onlineM365SignatureProgressbar.isIndeterminate = true
        onlineM365SignatureProgressbar.startAnimation(self)
        onlineM365SignatureLabel.isHidden = false
        onlineM365SignatureLabel.stringValue = "Online Signaturen werden abgerufen..."
        onlineM365SignatureName.isHidden = true
        onlineM365SignatureComboBox.isHidden = true
        onlineM365SignatureFileComboBox.isHidden = true
        saveButton.isEnabled = false
                
        graphService.fetchRemoteUser { user in
            guard let user = user else {
                DispatchQueue.main.async {
                    self.onlineM365SignatureFileComboBox.removeAllItems()
                    self.onlineM365SignatureFileComboBox.addItem(withObjectValue: "Signaturen konnten nicht geladen werden")
                }
                failure()
                return
            }
            
            FileManagerHelper().deleteAllHTMLFiles(at: appDirectory)

            graphService.fetchSubfolderContentsAndDownload(fromMacOSFolder: user, success: {
                // Wenn Dateien erfolgreich heruntergeladen wurden
                do {
                    let fileURLs = try fileManager.contentsOfDirectory(at: appDirectory, includingPropertiesForKeys: nil)

                    let htmlFiles = fileURLs.filter { $0.pathExtension == "html" || $0.pathExtension == "txt" }
                    guard !htmlFiles.isEmpty else {
                        DispatchQueue.main.async {
                            self.onlineM365SignatureFileComboBox.addItem(withObjectValue: "Keine Dateien gefunden")
                            self.onlineM365SignatureFileComboBox.delegate = self
                            self.onlineM365SignatureFileComboBox.dataSource = self
                            failure()
                        }
                        return
                    }

                    DispatchQueue.main.async {
                        self.onlineM365SignatureFileComboBox.removeAllItems()
                        for fileURL in htmlFiles {
                            let fileName = fileURL.lastPathComponent
                            let uniqueId = fileURL.path
                            self.fileSignatures.append((name: fileName, uniqueId: uniqueId))
                            self.onlineM365SignatureFileComboBox.addItem(withObjectValue: fileName)
                        }
                        self.onlineM365SignatureFileComboBox.delegate = self
                        self.onlineM365SignatureFileComboBox.dataSource = self
                        success()
                    }
                } catch {
                    print("Fehler beim Lesen des Verzeichnisses: \(error.localizedDescription)")
                }
            }, failure: {
                // Wenn der Download fehlschlägt
                failure()
            })
        }
    }
        
    func comboBoxSelectionDidChange(_ notification: Notification) {
        guard let comboBox = notification.object as? NSComboBox else { return }

        if comboBox == automaticSignatureComboBox {
            let selectedIndex = automaticSignatureComboBox.indexOfSelectedItem
            if selectedIndex >= 0 && selectedIndex < plistSignatures.count {
                let selectedSignature = plistSignatures[selectedIndex]
                print("Ausgewählte Signatur: \(selectedSignature.name), UniqueId: \(selectedSignature.uniqueId)")
                automaticSignatureName.stringValue = selectedSignature.name
                automaticSignatureHTML.stringValue = "" // Reset HTML content
            }
        } else if comboBox == onlineM365SignatureFileComboBox {
            let selectedIndex = onlineM365SignatureFileComboBox.indexOfSelectedItem
            if selectedIndex >= 0 && selectedIndex < fileSignatures.count {
                let selectedFile = fileSignatures[selectedIndex]
                onlineM365SignatureName.stringValue = selectedFile.name
                print("Ausgewählte Datei: \(selectedFile.name), Pfad: \(selectedFile.uniqueId)")
            }
        }
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        if comboBox == automaticSignatureComboBox {
            return plistSignatures.count
        } else if comboBox == onlineM365SignatureFileComboBox {
            return fileSignatures.count
        }
        return 0
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        if comboBox == automaticSignatureComboBox {
            return plistSignatures[index].name
        } else if comboBox == onlineM365SignatureFileComboBox {
            return fileSignatures[index].name
        }
        return nil
    }
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        if tabViewItem?.identifier as? String == "m365" {
            loadFilesFromDirectory(success: {
                self.onlineM365SignatureProgressbar.isIndeterminate = false
                self.onlineM365SignatureProgressbar.stopAnimation(self)
                self.onlineM365SignatureProgressbar.isHidden = true
                self.onlineM365SignatureLabel.isHidden = true
                self.onlineM365SignatureName.isHidden = false
                self.onlineM365SignatureComboBox.isHidden = false
                self.onlineM365SignatureFileComboBox.isHidden = false
                self.saveButton.isEnabled = true
            }, failure: {
                self.onlineM365SignatureProgressbar.isIndeterminate = false
                self.onlineM365SignatureProgressbar.stopAnimation(self)
                self.onlineM365SignatureProgressbar.doubleValue = 100
                self.onlineM365SignatureProgressbar.isHidden = true
                self.onlineM365SignatureLabel.stringValue = "Online Signaturen konnten nicht abgerufen werden, \n da diese für ihr Konto noch nicht freigeschalten worden sind."
            })
        }
    }
    
    @IBAction func save(_ sender: Any) {
        print("Speichern gestartet...")
        
        if !isEditing {
            signatureIsCount += 1
            print("Neuer Signaturzählerwert: \(signatureIsCount)")
        }
        
        let selectedIndex = automaticSignatureComboBox.indexOfSelectedItem
        let m365SelectedIndex = onlineM365SignatureComboBox.indexOfSelectedItem
        let fileSelectedIndex = onlineM365SignatureFileComboBox.indexOfSelectedItem
        
        if selectedIndex >= 0 && selectedIndex < plistSignatures.count {
            // Plist-Signatur speichern
            let selectedSignature = plistSignatures[selectedIndex]
            UserDefaults.standard.set(selectedSignature.uniqueId, forKey: "signature\(signatureIsCount)ID") // ID aus Plist
            UserDefaults.standard.set(automaticSignatureHTML.stringValue, forKey: "signature\(signatureIsCount)HTML") // Kein HTML
            UserDefaults.standard.set(selectedSignature.name, forKey: "signature\(signatureIsCount)Name") // Name aus Plist
            print("Plist-Signatur gespeichert: \(selectedSignature.name)")
        } else if m365SelectedIndex >= 0 && m365SelectedIndex < plistSignatures.count {
            // M365-Signatur speichern
            let m365SelectedSignature = plistSignatures[m365SelectedIndex]
            UserDefaults.standard.set(m365SelectedSignature.uniqueId, forKey: "signature\(signatureIsCount)ID") // ID aus M365-Plist
            UserDefaults.standard.set("", forKey: "signature\(signatureIsCount)HTML") // Kein HTML
            UserDefaults.standard.set(onlineM365SignatureName.stringValue, forKey: "signature\(signatureIsCount)Name") // Name aus M365-Name-Feld
            
            // Datei-Signatur prüfen und speichern
            if fileSelectedIndex >= 0 && fileSelectedIndex < fileSignatures.count {
                let selectedFile = fileSignatures[fileSelectedIndex]
                UserDefaults.standard.set(selectedFile.uniqueId, forKey: "signature\(signatureIsCount)HTML") // Datei-Pfad
                UserDefaults.standard.set(selectedFile.name, forKey: "m365Signature\(signatureIsCount)FileName") // Datei-Name
            } else {
                print("Fehler: Keine gültige Datei für M365 ausgewählt.")
            }
            print("M365-Signatur gespeichert: \(m365SelectedSignature.name)")
        } else {
            print("Fehler: Keine gültige Signatur ausgewählt.")
            return
        }
        
        // Speichern abschließen
        UserDefaults.standard.set(signatureIsCount, forKey: "app.signatures.count")
        UserDefaults.standard.set(true, forKey: "app.swpSignatureListReload")
        print("Speichern abgeschlossen. Fenster wird geschlossen.")
        
        // Geladene Werte nach dem Speichern ausgeben
        let storedSignatureID = UserDefaults.standard.string(forKey: "signature\(signatureIsCount)ID") ?? "Nicht gespeichert"
        let storedSignatureHTML = UserDefaults.standard.string(forKey: "signature\(signatureIsCount)HTML") ?? "Nicht gespeichert"
        let storedSignatureName = UserDefaults.standard.string(forKey: "signature\(signatureIsCount)Name") ?? "Nicht gespeichert"
        let storedFileName = UserDefaults.standard.string(forKey: "m365Signature\(signatureIsCount)FileName") ?? "Nicht gespeichert"
        
        print("""
        Gespeicherte Werte:
        - Signatur ID: \(storedSignatureID)
        - Signatur HTML: \(storedSignatureHTML)
        - Signatur Name: \(storedSignatureName)
        - Datei-Name: \(storedFileName)
        """)
        
        self.view.window?.close()
    }
    @IBAction func cancle(_ sender: Any) {
        self.view.window?.close()
    }
}

extension FileManagerHelper {
    func deleteAllHTMLFiles(at path: URL) {
        let fileManager = FileManager.default
        let files = try? fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
        files?.forEach { file in
            if file.pathExtension == "html" || file.pathExtension == "txt" {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}
*/
