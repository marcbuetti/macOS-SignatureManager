//
//  EditSignatureViewController.swift
//  Signature Manager
//
//  Created by Marc Büttner on 07.04.25.
//

/*import Cocoa

class EditSignatureViewController: NSViewController {
    
    
    @IBOutlet weak var contentScrollView: NSScrollView!
    @IBOutlet weak var boldButton: NSButton!
    @IBOutlet weak var italicButton: NSButton!
    @IBOutlet weak var underlineButton: NSButton!
    @IBOutlet weak var updateLabel: NSTextField!
    @IBOutlet weak var updateProgressbar: NSProgressIndicator!
    @IBOutlet weak var errorCodeLabel: NSTextField!
    
    var isEditing = false
    var existingSignature: (id: String, name: String, html: String)?
    var textView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(containerSize: NSMakeSize(self.contentScrollView.contentSize.width, .greatestFiniteMagnitude))
        layoutManager.addTextContainer(textContainer)
        
        let dynamicTextView = NSTextView(frame: self.contentScrollView.bounds, textContainer: textContainer)
        dynamicTextView.autoresizingMask = [.width]
        dynamicTextView.minSize = NSSize(width: 0, height: self.contentScrollView.contentSize.height)
        dynamicTextView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        dynamicTextView.isVerticallyResizable = true
        dynamicTextView.isHorizontallyResizable = false
        dynamicTextView.textContainerInset = NSSize(width: 5, height: 5)
        
        self.contentScrollView.documentView = dynamicTextView
        self.textView = dynamicTextView
        
        //print(existingSignature);
        
        if let signature = existingSignature {
            let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let onlineSigDir = appSupportDir.appendingPathComponent("Signature Manager/OnlineSignatures", isDirectory: true)
            let fileURL: URL
            if signature.html.hasPrefix("/") {
                fileURL = URL(fileURLWithPath: signature.html)
            } else {
                fileURL = onlineSigDir.appendingPathComponent(signature.html)
            }
            do {
                let htmlContent = try String(contentsOf: fileURL, encoding: .utf8)
                
                print(htmlContent);
                
                if let splitRange = htmlContent.range(of: "<p><br></p><table") {
                    let editableHtml = String(htmlContent[..<splitRange.lowerBound])
                    let plainText = editableHtml
                        .replacingOccurrences(of: "<br>", with: "\n")
                        .replacingOccurrences(of: "&nbsp;", with: " ")
                        .replacingOccurrences(of: "<p style=\"font-size: 13px\">", with: "")
                        .replacingOccurrences(of: "</p>", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    textView.string = plainText
                    
                    let fullRange = NSRange(location: 0, length: textView.string.utf16.count)
                    let mutable = textView.textStorage!
                    
                    // Fett
                    let boldRegex = try! NSRegularExpression(pattern: "<b>(.*?)</b>", options: [])
                    for match in boldRegex.matches(in: mutable.string, options: [], range: fullRange).reversed() {
                        let innerRange = match.range(at: 1)
                        let innerText = (mutable.string as NSString).substring(with: innerRange)
                        mutable.replaceCharacters(in: match.range, with: innerText)
                        let newRange = NSRange(location: match.range.location, length: innerText.utf16.count)
                        if let font = textView.font {
                            let boldFont = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
                            mutable.addAttribute(.font, value: boldFont, range: newRange)
                        }
                    }
                    
                    // Kursiv
                    let italicRegex = try! NSRegularExpression(pattern: "<i>(.*?)</i>", options: [])
                    for match in italicRegex.matches(in: mutable.string, options: [], range: NSRange(location: 0, length: mutable.length)).reversed() {
                        let innerRange = match.range(at: 1)
                        let innerText = (mutable.string as NSString).substring(with: innerRange)
                        mutable.replaceCharacters(in: match.range, with: innerText)
                        let newRange = NSRange(location: match.range.location, length: innerText.utf16.count)
                        if let font = textView.font {
                            let italicFont = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
                            mutable.addAttribute(.font, value: italicFont, range: newRange)
                        }
                    }
                    
                    // Unterstrichen
                    let underlineRegex = try! NSRegularExpression(pattern: "<u>(.*?)</u>", options: [])
                    for match in underlineRegex.matches(in: mutable.string, options: [], range: NSRange(location: 0, length: mutable.length)).reversed() {
                        let innerRange = match.range(at: 1)
                        let innerText = (mutable.string as NSString).substring(with: innerRange)
                        mutable.replaceCharacters(in: match.range, with: innerText)
                        let newRange = NSRange(location: match.range.location, length: innerText.utf16.count)
                        mutable.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: newRange)
                    }
                } else {
                    // Leere Vorlage vorbereiten
                    textView.string = ""
                }
            } catch {
                print("Fehler beim Lesen der Datei: \(error)")
            }
        }
        
        self.textView.delegate = self
    }
    
    @objc func updateToolbarState() {
        let range = textView.selectedRange()
        guard range.length > 0 else {
            boldButton?.state = .off
            italicButton?.state = .off
            underlineButton?.state = .off
            return
        }
        
        if let font = textView.textStorage?.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont {
            let traits = NSFontManager.shared.traits(of: font)
            boldButton?.state = traits.contains(.boldFontMask) ? .on : .off
            italicButton?.state = traits.contains(.italicFontMask) ? .on : .off
        } else {
            boldButton?.state = .off
            italicButton?.state = .off
        }
        
        if let underline = textView.textStorage?.attribute(.underlineStyle, at: range.location, effectiveRange: nil) as? Int {
            underlineButton?.state = underline != 0 ? .on : .off
        } else {
            underlineButton?.state = .off
        }
    }
    
    @IBAction func makeBold(_ sender: Any) {
        wrapSelection(with: .boldFontMask)
    }
    
    @IBAction func makeItalic(_ sender: Any) {
        wrapSelection(with: .italicFontMask)
    }
    
    @IBAction func makeUnderline(_ sender: Any) {
        let selectedRange = textView.selectedRange()
        guard selectedRange.length > 0 else { return }
        
        let existing = textView.textStorage?.attribute(.underlineStyle, at: selectedRange.location, effectiveRange: nil) as? Int ?? 0
        if existing == NSUnderlineStyle.single.rawValue {
            textView.textStorage?.removeAttribute(.underlineStyle, range: selectedRange)
        } else {
            textView.textStorage?.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: selectedRange)
        }
    }
    
    func wrapSelection(with style: NSFontTraitMask) {
        let selectedRange = textView.selectedRange()
        guard selectedRange.length > 0 else { return }
        
        guard let baseFont = textView.font else { return }
        
        let attributedString = textView.attributedSubstring(forProposedRange: selectedRange, actualRange: nil)
        let hasStyle = attributedString?.attribute(.font, at: 0, effectiveRange: nil)
            .flatMap { $0 as? NSFont }
            .map { NSFontManager.shared.traits(of: $0).contains(style) } ?? false
        
        let newFont: NSFont
        if hasStyle {
            newFont = NSFontManager.shared.convert(baseFont, toNotHaveTrait: style)
        } else {
            newFont = NSFontManager.shared.convert(baseFont, toHaveTrait: style)
        }
        
        textView.textStorage?.addAttribute(.font, value: newFont, range: selectedRange)
    }
    
    func getFormattedHTML() -> String {
        guard let textStorage = textView.textStorage else { return "" }
        
        let fullRange = NSRange(location: 0, length: textStorage.length)
        var htmlString = ""
        
        textStorage.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            guard let substring = textStorage.attributedSubstring(from: range).string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
                .removingPercentEncoding?
                .replacingOccurrences(of: "\n", with: "<br>") else { return }
            
            var openingTags = ""
            var closingTags = ""
            
            if let font = attributes[.font] as? NSFont {
                let traits = NSFontManager.shared.traits(of: font)
                if traits.contains(.boldFontMask) {
                    openingTags += "<b>"
                    closingTags = "</b>" + closingTags
                }
                if traits.contains(.italicFontMask) {
                    openingTags += "<i>"
                    closingTags = "</i>" + closingTags
                }
            }
            
            if let underline = attributes[.underlineStyle] as? Int, underline != 0 {
                openingTags += "<u>"
                closingTags = "</u>" + closingTags
            }
            
            htmlString += openingTags + substring + closingTags
        }
        
        let cleaned = htmlString
            .replacingOccurrences(of: "  ", with: "&nbsp; ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return "<p style=\"font-size: 13px\">\(cleaned)</p>"
    }
    
    func updateRemoteSignature() {
        contentScrollView.isHidden = true
        updateLabel.isHidden = false
        updateLabel.stringValue = "Online Signaturen werden aktualisiert..."
        updateProgressbar.isHidden = false
        updateProgressbar.isIndeterminate = true
        updateProgressbar.startAnimation(self)
        
        guard let signature = existingSignature else {
            print("Keine Signatur zum Hochladen vorhanden.")
            return
        }
        
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let onlineSigDir = appSupportDir.appendingPathComponent("Signature Manager/OnlineSignatures", isDirectory: true)
        let fileURL: URL
        if signature.html.hasPrefix("/") {
            fileURL = URL(fileURLWithPath: signature.html)
        } else {
            fileURL = onlineSigDir.appendingPathComponent(signature.html)
        }
        GraphService().fetchRemoteUser { [self] user in
            guard let user = user else {
                DispatchQueue.main.async {
                    self.handleM365DownloadFailed()
                }
                return
            }
            GraphService().uploadContentsToRemote(remoteAppDataUserFolder: user, specificFile: fileURL, success: {
                DispatchQueue.main.async {
                    self.handleM365DownloadComplete()
                }
            }, failure: {
                DispatchQueue.main.async {
                    self.handleM365DownloadFailed()
                }
            })
        }
    }
    
    @objc func handleM365DownloadComplete() {
        self.view.window?.close()
        updateProgressbar.stopAnimation(self)
    }
    
    @objc func handleM365DownloadFailed() {
        updateProgressbar.isIndeterminate = false
        updateProgressbar.stopAnimation(self)
        updateProgressbar.isHidden = true
        updateLabel.stringValue = "Online Signaturen konnten nicht aktualisiert werden.\nBitte veruschen Sie es später erneut."
        errorCodeLabel.stringValue = "Error Code: 0x80070057"
        errorCodeLabel.isHidden = false
    }
    
    @IBAction func saveSignature(_ sender: Any) {
        let newParagraph = getFormattedHTML()
        
        if let signature = existingSignature {
            let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let onlineSigDir = appSupportDir.appendingPathComponent("Signature Manager/OnlineSignatures", isDirectory: true)
            try? FileManager.default.createDirectory(at: onlineSigDir, withIntermediateDirectories: true, attributes: nil)
            let fileURL: URL
            if signature.html.hasPrefix("/") {
                fileURL = URL(fileURLWithPath: signature.html)
            } else {
                fileURL = onlineSigDir.appendingPathComponent(signature.html)
            }
            do {
                let originalHTML = try String(contentsOf: fileURL, encoding: .utf8)
                
                if let splitRange = originalHTML.range(of: "<p><br></p><table") {
                    let newHTML = newParagraph + originalHTML[splitRange.lowerBound...]
                    try newHTML.write(to: fileURL, atomically: true, encoding: .utf8)
                    print("Neue HTML-Signatur:\n\(newHTML)")
                    print("Signatur erfolgreich gespeichert unter: \(fileURL.path)")
                    updateRemoteSignature()
                } else {
                    // Noch keine Struktur → alles neu erzeugen
                    let newHTML = newParagraph + "<p><br></p><table></table>"
                    try newHTML.write(to: fileURL, atomically: true, encoding: .utf8)
                    print("Neue HTML-Signatur (neu erstellt):\n\(newHTML)")
                    print("Signatur erfolgreich gespeichert unter: \(fileURL.path)")
                    updateRemoteSignature()
                }
            } catch {
                print("Fehler beim Speichern der Signatur: \(error)")
            }
        }
    }
    
    @IBAction func cancle(_ sender: Any) {
        self.view.window?.close()
    }
}
    
extension EditSignatureViewController: NSTextViewDelegate {
    func textViewDidChangeSelection(_ notification: Notification) {
        updateToolbarState()
    }
}
*/
