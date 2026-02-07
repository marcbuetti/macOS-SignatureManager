//
//  SignaturesSettingsViewController.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 08.09.24.
//

/*import Cocoa

class SignaturesSettingsViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var tableView: NSTableView!
    
    var data: [(id: String, name: String, html: String)] = []
    var signatureIsCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        loadData()
        let rightClickMenu = NSMenu()
        let editMenuItem = NSMenuItem(title: "Bearbeiten", action: #selector(editItem), keyEquivalent: "")
        rightClickMenu.addItem(editMenuItem)
        
        let deleteMenuItem = NSMenuItem(title: "Löschen", action: #selector(deleteItem), keyEquivalent: "")
        rightClickMenu.addItem(deleteMenuItem)
        
        rightClickMenu.addItem(NSMenuItem.separator())

        let editSignatureMenuItem = NSMenuItem(title: "Signatur bearbeiten", action: #selector(editSignature), keyEquivalent: "")
        rightClickMenu.addItem(editSignatureMenuItem)
        
        tableView.menu = rightClickMenu
        
        print(UserDefaults.standard.string(forKey: "signature1ID") ?? "")
        print(UserDefaults.standard.string(forKey: "signature1HTML") ?? "")
        print(UserDefaults.standard.string(forKey: "signature1Name") ?? "")
    }
    
    // MARK: - Daten laden
    
    func loadData() {
        data.removeAll()
        
        let signatureCount = UserDefaults.standard.integer(forKey: "app.signatures.count")
        
        if signatureCount > 0 {
            for index in 1...signatureCount {
                let idKey = "signature\(index)ID"
                let nameKey = "signature\(index)Name"
                let htmlKey = "signature\(index)HTML"
                
                if let id = UserDefaults.standard.string(forKey: idKey),
                   let name = UserDefaults.standard.string(forKey: nameKey),
                   let html = UserDefaults.standard.string(forKey: htmlKey),
                   !id.isEmpty, !name.isEmpty, !html.isEmpty {
                    data.append((id: id, name: name, html: html))
                }
            }
        }
        
        tableView.reloadData()
    }
    
    // MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn else { return nil }
        
        let item = data[row]
        var text = ""
        
        switch tableColumn.identifier.rawValue {
        case "idColumn":
            text = item.name
        case "nameColumn":
            text = item.name
        case "htmlColumn":
            text = item.html
        default:
            break
        }
        
        if let cell = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        
        return nil
    }
    
    // MARK: - NSTableViewDelegate
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = tableView.selectedRow
        if selectedRow >= 0 {
            print("Selected: \(data[selectedRow])")
        }
    }
    
    // MARK: - Kontextmenü Aktionen
    
    @objc func editItem() {
        let selectedRow = tableView.clickedRow
        if selectedRow >= 0 {
            let selectedSignature = data[selectedRow]
            
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            guard let addSignatureViewController = storyboard.instantiateController(withIdentifier: "AddSignatureViewController") as? AddSignatureViewController else {
                print("ViewController konnte nicht gefunden werden.")
                return
            }
            
            addSignatureViewController.isEditing = true
            addSignatureViewController.existingSignature = selectedSignature
            
            self.presentAsSheet(addSignatureViewController)
        }
    }
    
    @objc func deleteItem() {
        let selectedRow = tableView.clickedRow
        if selectedRow >= 0 {
            let alert = NSAlert()
            alert.messageText = "Bist du sicher, dass du dieses Element löschen möchtest?"
            alert.informativeText = "Dies kann nicht rückgängig gemacht werden."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Löschen")
            alert.addButton(withTitle: "Abbrechen")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let itemToDelete = data[selectedRow]
                
                let signatureCount = UserDefaults.standard.integer(forKey: "app.signatures.count")
                
                if signatureCount > 0 {
                    for index in 1...signatureCount {
                        if UserDefaults.standard.string(forKey: "signature\(index)ID") == itemToDelete.id {
                            UserDefaults.standard.removeObject(forKey: "signature\(index)ID")
                            UserDefaults.standard.removeObject(forKey: "signature\(index)Name")
                            UserDefaults.standard.removeObject(forKey: "signature\(index)HTML")
                            break
                        }
                    }
                }
                data.remove(at: selectedRow)
                tableView.reloadData()
            }
        }
    }
        
    @IBAction func addItemButton(_ sender: Any) {
        UserDefaults.standard.set(data.count, forKey: "app.signatures.count")
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let addSignatureViewController = storyboard.instantiateController(withIdentifier: "AddSignatureViewController") as? NSViewController else {
            print("ViewController konnte nicht gefunden werden.")
            return
        }
        startAjaxSignatureListReload()
        self.presentAsSheet(addSignatureViewController)
    }
    
    func startAjaxSignatureListReload() {
        DispatchQueue.global(qos: .background).async {
            while true {
                sleep(1)
                
                if UserDefaults.standard.bool(forKey: "app.swpSignatureListReload") {
                    DispatchQueue.main.async {
                        self.loadData()
                        print("Liste neu geladen")
                    }
                    break
                }
            }
        }
    }
    
    @objc func editSignature() {
        print("Signatur bearbeiten wurde ausgewählt.")
        let selectedRow = tableView.clickedRow
        if selectedRow >= 0 {
            let selectedSignature = data[selectedRow]
            
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            guard let editSignatureViewController = storyboard.instantiateController(withIdentifier: "EditSignatureViewController") as? EditSignatureViewController else {
                print("ViewController konnte nicht gefunden werden.")
                return
            }
            
            editSignatureViewController.isEditing = true
            editSignatureViewController.existingSignature = selectedSignature
            
            self.presentAsSheet(editSignatureViewController)
        }
    }
    
}
*/
