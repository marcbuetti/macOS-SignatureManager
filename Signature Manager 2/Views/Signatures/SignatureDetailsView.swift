//
//  SignatureDetailView.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 17.09.25.
//

import SwiftUI
import UniformTypeIdentifiers


private struct MailSignature: Identifiable {
    let id: String
    let name: String
}


private struct M365File: Identifiable, Hashable {
    let id: String      // absolute path
    let name: String    // filename
    var url: URL { URL(fileURLWithPath: id) }
}


struct SignatureDetailsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // Mail-Signaturen (Plist)
    @State private var plistSignatures: [MailSignature] = []
    @State private var selectedPlistIndex: Int = 0
    @State private var selectedMailSignatureID: String = ""

    // Storage Selector (0 = Local, 1 = Cloud M365)
    @State private var storageSelection: Int = 0

    // Local file
    @State private var selectedHTMLFile: URL? = nil
    @State private var showingFileImporter = false

    // Cloud (M365)
    @State private var m365Files: [M365File] = []
    @State private var selectedM365Index: Int = 0
    @State private var isLoadingM365: Bool = false
    @State private var m365Error: String? = nil

    // Editor (UI)
    @State private var richText: AttributedString = AttributedString("")
    @State private var selectedColor: Color = .primary
    @State private var selectedFontSize: CGFloat = 14

    // Edit-Logik: Rest des HTMLs (ab <p><br></p><table) zwischenspeichern
    @State private var htmlTailAfterEditable: String? = nil
    @State private var currentHTMLLoadToken = UUID()

    @State private var showDeleteConfirmation = false
    
    let signature: Signature

    var body: some View {
        ScrollView {
            Spacer(minLength: 10)
            VStack(alignment: .leading, spacing: 4) {
                Text("LAST_UPDATED: \(formatPretty(signature.lastUpdated))")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 20)

            Spacer(minLength: 10)

            GroupBox {
                VStack {
                    HStack {
                        Text("MAIL_SIGNATURE")
                        Spacer()
                        Picker("", selection: $selectedPlistIndex) {
                            if plistSignatures.isEmpty {
                                Text("NO_SIGNATURES_FOUND").tag(0)
                            } else {
                                ForEach(plistSignatures.indices, id: \.self) { i in
                                    Text(plistSignatures[i].name).tag(i)
                                }
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedPlistIndex) { oldValue, newValue in
                            selectedMailSignatureID = plistSignatures.indices.contains(newValue)
                                ? plistSignatures[newValue].id
                                : ""
                        }
                    }
                    Divider()
                    HStack {
                        Text("SIGNATURE_STORAGE")
                        Spacer()
                        Picker("", selection: $storageSelection) {
                            Text("LOCAL_STORAGE").tag(0)
                            Text("CLOUD_M365").tag(1)
                        }
                        .pickerStyle(.menu)
                        .onChange(of: storageSelection) { oldValue, newValue in
                            if newValue == 1, selectedHTMLFile == nil {
                                loadM365Files()
                            }
                            richText = AttributedString("")
                            htmlTailAfterEditable = nil
                            if let url = selectedHTMLFile { loadEditableFromHTML(at: url) }
                        }
                    }
                }
                .padding(4)
            }
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1))
            .padding(.horizontal)

            Spacer(minLength: 30)

            GroupBox {
                HStack(spacing: 12) {
                    Text("EDIT_SIGNATURE").padding(.leading, 5)
                    Spacer()

                    if storageSelection == 1 {
                        // CLOUD
                        HStack(spacing: 8) {
                            if isLoadingM365 {
                                ProgressView().controlSize(.small)
                                    .padding(.trailing, -10)
                            }
                            Picker("", selection: $selectedM365Index) {
                                if let err = m365Error {
                                    Text("ERROR: \(err)").tag(0)
                                } else if m365Files.isEmpty {
                                    Text(isLoadingM365 ? "LOADING" : "NO_FILES_FOUND").tag(0)
                                } else {
                                    ForEach(m365Files.indices, id: \.self) { i in
                                        Text(m365Files[i].name).tag(i)
                                    }
                                }
                            }
                            .frame(minWidth: 100)
                            .disabled(isLoadingM365 || (!m365Error.isNil && m365Files.isEmpty))
                            .onChange(of: selectedM365Index) { oldValue, newIndex in
                                guard m365Files.indices.contains(newIndex) else { return }
                                let url = m365Files[newIndex].url

                                richText = AttributedString("")
                                htmlTailAfterEditable = nil

                                selectedHTMLFile = url
                                print("[M365] Picker changed -> index: \(newIndex), path: \(m365Files[newIndex].id)")

                                DispatchQueue.main.async {
                                    loadEditableFromHTML(at: url)
                                }
                            }
                        }
                        .padding(.trailing, 5)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    } else {
                        HStack(alignment: .center, spacing: 8) {
                            if let url = selectedHTMLFile {
                                Text(url.path)
                                    .font(.footnote)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: 360, alignment: .trailing)
                                Button("EDIT") { showingFileImporter = true }
                            } else {
                                Button("CHOOSE_HTML_FILE") { showingFileImporter = true }
                            }
                        }
                        .padding(.trailing, 5)
                        .fileImporter(
                            isPresented: $showingFileImporter,
                            allowedContentTypes: [.html],
                            allowsMultipleSelection: false
                        ) { result in
                            switch result {
                            case .success(let urls):
                                if let url = urls.first {
                                    selectedHTMLFile = url
                                    loadEditableFromHTML(at: url)
                                }
                            case .failure:
                                Logger.shared.log(position: "SignatureDetailsView.fileImporter", type: "WARNING", content: "User cancelled or failed selecting HTML file")
                                selectedHTMLFile = nil
                                richText = AttributedString("")
                                htmlTailAfterEditable = nil
                            }
                        }
                    }
                }
                .padding(.vertical, 6)

                Spacer()

                VStack(alignment: .leading) {
                    HStack {
                        Button(action: { toggleBold() }) { Image(systemName: "bold") }
                        Button(action: { toggleItalic() }) { Image(systemName: "italic") }
                        Button(action: { toggleUnderline() }) { Image(systemName: "underline") }
                        ColorPicker("", selection: $selectedColor).labelsHidden()
                        Picker("", selection: $selectedFontSize) {
                            Text("12").tag(CGFloat(12))
                            Text("14").tag(CGFloat(14))
                            Text("18").tag(CGFloat(18))
                            Text("24").tag(CGFloat(24))
                            Text("36").tag(CGFloat(36))
                        }
                        .frame(width: 60)
                        .labelsHidden()
                    }
                    .padding(.bottom, 4)

                    TextEditor(text: Binding(
                        get: { String(richText.characters) },
                        set: { richText = AttributedString($0) }
                    ))
                    .font(.system(size: selectedFontSize))
                    .foregroundColor(selectedColor)
                    .frame(height: 350)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2)))

                    Text("AFTER_SIGNATURE_PLACEHOLDER")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(4)

            }
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1))
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle(signature.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Button(action: saveChanges) {
                        Label("SAVE", systemImage: "checkmark")
                    }
                    .disabled(saveDisabled)

                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        Label("DELETE", systemImage: "trash")
                    }
                }
            }
        }
        .onAppear {
            loadPlistSignatures()

            storageSelection = signature.storageType == .local ? 0 : 1
            selectedMailSignatureID = signature.mailSignatureId
            selectedHTMLFile = signature.htmlPath.isEmpty
                ? nil
                : URL(fileURLWithPath: signature.htmlPath)

            if storageSelection == 1 {
                loadM365Files(prefillPath: signature.htmlPath)
            }

            if let url = selectedHTMLFile {
                loadEditableFromHTML(at: url)
            }
        }
        .confirmationDialog(String(localized: "DELETE_SIGNATURE_CONFIRMATION"), isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("DELETE", role: .destructive) { deleteSignature() }
            Button("CANCEL", role: .cancel) {}
        }
    }

    private var saveDisabled: Bool {
        if storageSelection == 1 {
            return m365Files.isEmpty || selectedHTMLFile == nil || plistSignatures.isEmpty
        } else {
            return plistSignatures.isEmpty || selectedMailSignatureID.isEmpty
        }
    }

    private func saveChanges() {
        guard plistSignatures.indices.contains(selectedPlistIndex) else { return }
        let selectedPlist = plistSignatures[selectedPlistIndex]

        if let fileURL = selectedHTMLFile {
            do {
                let original = (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
                let newParagraph = formattedHTMLFromEditor()
                let merged = buildHTMLWithEditedParagraph(
                    originalHTML: original,
                    editedParagraphHTML: newParagraph
                )
                try merged.write(to: fileURL, atomically: true, encoding: .utf8)

                if storageSelection == 1 {
                    uploadToM365(fileURL: fileURL)
                }
            } catch {
                Logger.shared.log(
                    position: "SignatureDetailsView.saveChanges",
                    type: "CRITICAL",
                    content: "Failed to write HTML: \(error.localizedDescription)"
                )
            }
        }

        // 🔥 SwiftData Update
        signature.mailSignatureId = selectedPlist.id
        signature.name = selectedPlist.name
        signature.htmlPath = selectedHTMLFile?.path ?? ""
        signature.storageType = storageSelection == 0 ? .local : .cloudM365
        signature.m365FileName = storageSelection == 1
            ? selectedHTMLFile?.lastPathComponent
            : nil
        signature.lastUpdated = .now

        dismiss()
    }

    /*private func deleteSignature() {
        guard let idx = signatureIndex else { return }
        let total = signaturesCount
        guard total > 0 else { return }

        if idx < total {
            for i in idx..<total {
                let src = i + 1
                copySignature(from: src, to: i)
            }
        }

        deleteSignatureKeys(at: total)
        signaturesCount = max(0, total - 1)
        reloadFlag = true
        dismiss()
    }

    private func resolveSignatureIndex() {
        let targetName   = signature.name
        let targetStore  = signature.storageLocation
        let targetUpdate = signature.lastUpdate

        for i in 1...signaturesCount {
            let name = UserDefaults.standard.string(forKey: "app.signature\(i)Name") ?? ""
            if name != targetName { continue }
            let stype = UserDefaults.standard.string(forKey: "app.signature\(i)StorageType")
                ?? ((UserDefaults.standard.string(forKey: "app.signature\(i)HTML") ?? "").isEmpty ? "Local Storage" : "Cloud - Microsoft 365")
            if stype != targetStore { continue }

            let whenRaw = UserDefaults.standard.string(forKey: "app.signature\(i)LastUpdated")
            let pretty = formatPretty(parseISO8601(whenRaw)) ?? (whenRaw ?? "—")
            if pretty == targetUpdate {
                signatureIndex = i
                return
            }
        }
        for i in 1...signaturesCount {
            let name = UserDefaults.standard.string(forKey: "app.signature\(i)Name") ?? ""
            if name == targetName { signatureIndex = i; return }
        }
    }

    private func preloadCurrentValues() {
        if let idx = signatureIndex {
            let savedID   = UserDefaults.standard.string(forKey: "app.signature\(idx)ID") ?? ""
            let savedHTML = UserDefaults.standard.string(forKey: "app.signature\(idx)HTML") ?? ""
            let stype     = UserDefaults.standard.string(forKey: "app.signature\(idx)StorageType")
                ?? (savedHTML.isEmpty ? "Local Storage" : "Cloud - Microsoft 365")

            storageSelection = (stype == "Cloud - Microsoft 365") ? 1 : 0
            print("[Preload] idx=\(idx), storage=\(storageSelection == 1 ? "Cloud" : "Local")")

            if let pIndex = plistSignatures.firstIndex(where: { $0.id == savedID }) {
                selectedPlistIndex = pIndex
                selectedMailSignatureID = plistSignatures[pIndex].id
                print("[Preload] Selected plist: id=\(selectedMailSignatureID), name=\(plistSignatures[pIndex].name)")
            } else if !plistSignatures.isEmpty {
                selectedPlistIndex = 0
                selectedMailSignatureID = plistSignatures[0].id
                print("[Preload] Default plist: id=\(selectedMailSignatureID), name=\(plistSignatures[0].name)")
            }

            if storageSelection == 0 {
                if !savedHTML.isEmpty {
                    let url = URL(fileURLWithPath: savedHTML)
                    selectedHTMLFile = url
                    print("[Preload] Local HTML path: \(url.path)")
                }
            } else {
                loadM365Files(prefillPath: savedHTML)
                print("[Preload] Cloud prefill path: \(savedHTML)")
            }
        }
    }*/

    private func loadPlistSignatures() {
        guard let plistURL = findAllSignaturesPlist() else { plistSignatures = []; return }
        do {
            let data = try Data(contentsOf: plistURL)
            if let array = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [[String: Any]] {
                plistSignatures = array.compactMap { dict in
                    guard let name = dict["SignatureName"] as? String,
                          let uid  = dict["SignatureUniqueId"] as? String else { return nil }
                    return MailSignature(id: uid, name: name)
                }
                print("[Plist] Loaded signatures: \(plistSignatures.map{ $0.name }) (")
            }
        } catch {
            plistSignatures = []
            print("[Plist] Failed to load AllSignatures.plist")
        }
    }

    private func loadM365Files(prefillPath: String? = nil) {
        isLoadingM365 = true
        m365Error = nil
        m365Files = []
        selectedHTMLFile = nil
        selectedM365Index = 0
        print("[M365] Start loading files, prefill: \(prefillPath ?? "nil")")

        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let targetDir = appSupport.appendingPathComponent("com.mibuettner.SignatureManager/OnlineSignatures", isDirectory: true)
        try? fm.createDirectory(at: targetDir, withIntermediateDirectories: true)

        FileManagerHelper().deleteAllHTMLFiles()

        let graph = GraphService()
        graph.fetchRemoteUser { user in
            guard let user = user else {
                Logger.shared.log(position: "SignatureDetailsView.loadM365Files", type: "WARNING", content: "Could not resolve user for M365 fetch")
                DispatchQueue.main.async {
                    self.isLoadingM365 = false
                    self.m365Error = "Could not load user"
                }
                return
            }
            graph.fetchSubfolderContentsAndDownload(fromMacOSFolder: user, success: {
                do {
                    let urls = try fm.contentsOfDirectory(at: targetDir, includingPropertiesForKeys: nil)
                    let htmls = urls.filter { ["html", "txt"].contains($0.pathExtension.lowercased()) }
                    let files = htmls.map { M365File(id: $0.path, name: $0.lastPathComponent) }
                        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                    DispatchQueue.main.async {
                        self.m365Files = files
                        print("[M365] Downloaded files: \(files.map{ $0.name })")
                        self.isLoadingM365 = false
                        if let p = prefillPath, let matchIndex = files.firstIndex(where: { $0.id == p }) {
                            self.selectedM365Index = matchIndex
                            self.selectedHTMLFile = files[matchIndex].url
                            print("[M365] Prefilled selection -> index: \(matchIndex), path: \(files[matchIndex].id)")
                            self.loadEditableFromHTML(at: files[matchIndex].url)
                        } else if self.selectedHTMLFile == nil, let first = files.first {
                            self.selectedM365Index = 0
                            self.selectedHTMLFile = first.url
                            print("[M365] Default selection -> index: 0, path: \(first.id)")
                            self.loadEditableFromHTML(at: first.url)
                        } else {
                            // Keep existing selection if any; sync index to current file
                            if let current = self.selectedHTMLFile,
                               let idx = files.firstIndex(where: { $0.url == current }) {
                                self.selectedM365Index = idx
                                print("[M365] Keep existing selection -> index: \(idx), path: \(files[idx].id)")
                            }
                        }
                    }
                } catch {
                    Logger.shared.log(position: "SignatureDetailsView.loadM365Files", type: "CRITICAL", content: "Failed to read downloaded files: \(error.localizedDescription)")
                    print("[M365] Failed to read downloaded files: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isLoadingM365 = false
                        self.m365Error = error.localizedDescription
                    }
                }
            }, failure: {
                Logger.shared.log(position: "SignatureDetailsView.loadM365Files", type: "CRITICAL", content: "Download of M365 files failed")
                print("[M365] Download failed")
                DispatchQueue.main.async {
                    self.isLoadingM365 = false
                    self.m365Error = "Download failed"
                }
            })
        }
    }

    private func loadEditableFromHTML(at url: URL) {
        let token = UUID()
        currentHTMLLoadToken = token

        print("[HTML] Loading: \(url.path)")
        do {
            let html = try String(contentsOf: url, encoding: .utf8)
            if let splitRange = html.range(of: "<p><br></p><table") {
                guard currentHTMLLoadToken == token else {
                    print("[HTML] Ignored outdated load for: \(url.lastPathComponent)")
                    return
                }
                let editableHtml = String(html[..<splitRange.lowerBound])
                let tail = String(html[splitRange.lowerBound...])
                htmlTailAfterEditable = tail
                let inner = stripOuterParagraph(from: editableHtml)
                let plain = inner
                    .replacingOccurrences(of: "<br>", with: "\n")
                    .replacingOccurrences(of: "&nbsp;", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                richText = attributedFromSimpleHTML(plainHTML: plain)
                print("[HTML] Parsed editable part (len=\(editableHtml.count)) and tail (len=\(tail.count))")
            } else {
                guard currentHTMLLoadToken == token else {
                    print("[HTML] Ignored outdated load for: \(url.lastPathComponent)")
                    return
                }
                htmlTailAfterEditable = nil
                richText = AttributedString("")
                print("[HTML] No split marker found; editor cleared")
            }
        } catch {
            guard currentHTMLLoadToken == token else {
                print("[HTML] Ignored outdated load for: \(url.lastPathComponent)")
                return
            }
            Logger.shared.log(position: "SignatureDetailsView.loadEditableFromHTML", type: "CRITICAL", content: "Failed to read HTML: \(error.localizedDescription)")
            print("[HTML] Read failed: \(error.localizedDescription)")
            htmlTailAfterEditable = nil
            richText = AttributedString("")
        }
    }

    private func buildHTMLWithEditedParagraph(originalHTML: String, editedParagraphHTML: String) -> String {
        if let splitRange = originalHTML.range(of: "<p><br></p><table") {
            let tail = String(originalHTML[splitRange.lowerBound...])
            return editedParagraphHTML + tail
        } else {
            return editedParagraphHTML + "<p><br></p><table></table>"
        }
    }

    private func formattedHTMLFromEditor() -> String {
        let full = String(richText.characters)
        let html = full
            .replacingOccurrences(of: "\n", with: "<br>")
            .replacingOccurrences(of: "  ", with: "&nbsp; ")
        return "<p style=\"font-size: 13px\">\(html)</p>"
    }

    private func stripOuterParagraph(from html: String) -> String {
        guard let openP = html.range(of: "<p"),
              let closeAngle = html.range(of: ">", range: openP.upperBound..<html.endIndex),
              let closeP = html.range(of: "</p>", options: .backwards) else {
            return html
        }
        return String(html[closeAngle.upperBound..<closeP.lowerBound])
    }

    private func attributedFromSimpleHTML(plainHTML: String) -> AttributedString {
        let stripped = plainHTML
            .replacingOccurrences(of: "<b>", with: "")
            .replacingOccurrences(of: "</b>", with: "")
            .replacingOccurrences(of: "<i>", with: "")
            .replacingOccurrences(of: "</i>", with: "")
            .replacingOccurrences(of: "<u>", with: "")
            .replacingOccurrences(of: "</u>", with: "")
        return AttributedString(stripped)
    }

    private func uploadToM365(fileURL: URL) {
        let graph = GraphService()
        graph.fetchRemoteUser { user in
            guard let user = user else {
                Logger.shared.log(position: "SignatureDetailsView.uploadToM365", type: "WARNING", content: "M365 upload: could not resolve user")
                return
            }
            GraphService().uploadContentsToRemote(
                remoteAppDataUserFolder: user,
                specificFile: fileURL,
                success: { /* Removed success print/log per instructions */ },
                failure: { 
                    Logger.shared.log(position: "SignatureDetailsView.uploadToM365", type: "CRITICAL", content: "M365 upload failed") 
                }
            )
        }
    }

    /*private func copySignature(from src: Int, to dst: Int) {
        let keys = ["ID","Name","HTML","StorageType","LastUpdated"]
        for k in keys {
            let sv = UserDefaults.standard.object(forKey: "app.signature\(src)\(k)")
            if let v = sv {
                UserDefaults.standard.set(v, forKey: "app.signature\(dst)\(k)")
            } else {
                UserDefaults.standard.removeObject(forKey: "app.signature\(dst)\(k)")
            }
        }
        let mKeySrc = "app.m365Signature\(src)FileName"
        let mKeyDst = "app.m365Signature\(dst)FileName"
        if let mv = UserDefaults.standard.object(forKey: mKeySrc) {
            UserDefaults.standard.set(mv, forKey: mKeyDst)
        } else {
            UserDefaults.standard.removeObject(forKey: mKeyDst)
        }
    }

    private func deleteSignatureKeys(at idx: Int) {
        let keys = ["ID","Name","HTML","StorageType","LastUpdated"]
        for k in keys {
            UserDefaults.standard.removeObject(forKey: "app.signature\(idx)\(k)")
        }
        UserDefaults.standard.removeObject(forKey: "app.m365Signature\(idx)FileName")
    }*/
    
    private func deleteSignature() {
        context.delete(signature)
        dismiss()
    }

   /* private func iso8601Now() -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.string(from: Date())
    }
    private func parseISO8601(_ s: String?) -> Date? {
        guard let s = s else { return nil }
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: s) { return d }
        let f2 = ISO8601DateFormatter()
        return f2.date(from: s)
    }*/
    private func formatPretty(_ d: Date?) -> String? {
        guard let d = d else { return nil }
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: d)
    }
    /*private func debugPrintSignature(_ idx: Int) {
        let id = UserDefaults.standard.string(forKey: "app.signature\(idx)ID")
        let name = UserDefaults.standard.string(forKey: "app.signature\(idx)Name")
        if id == nil || name == nil || id == "" || name == "" {
            Logger.shared.log(position: "SignatureDetailsView.debugPrintSignature", type: "WARNING", content: "Updated signature #\(idx) has missing id or name")
        }
    }*/

    private func findAllSignaturesPlist() -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let mailDir = home.appendingPathComponent("Library/Mail", isDirectory: true)
        guard let contents = try? FileManager.default.contentsOfDirectory(at: mailDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { return nil }
        let vFolders = contents.filter { $0.lastPathComponent.hasPrefix("V") && $0.hasDirectoryPath }
        let sorted = vFolders.sorted { (a, b) -> Bool in
            (Int(a.lastPathComponent.dropFirst()) ?? 0) > (Int(b.lastPathComponent.dropFirst()) ?? 0)
        }
        for v in sorted {
            let plist = v.appendingPathComponent("MailData/Signatures/AllSignatures.plist")
            if FileManager.default.fileExists(atPath: plist.path) {
                print("[Plist] Found AllSignatures.plist at: \(plist.path)")
                return plist
            }
        }
        print("[Plist] No AllSignatures.plist found")
        return nil
    }

    private func toggleBold() {
        let r = richText.startIndex..<richText.endIndex
        richText[r].font = .system(size: selectedFontSize, weight: .bold)
    }
    
    private func toggleItalic() {
        let r = richText.startIndex..<richText.endIndex
        richText[r].font = .system(size: selectedFontSize).italic()
    }
    
    private func toggleUnderline() {
        let r = richText.startIndex..<richText.endIndex
        richText[r].underlineStyle = .single
    }
}


private extension Optional where Wrapped == String {
    var isNil: Bool { self == nil }
}


#Preview {
    SignatureDetailsView(
        signature: Signature(
            mailSignatureId: "preview-id",
            name: "Preview Name",
            htmlPath: "/tmp/preview.html",
            storageType: .local,
            lastUpdated: .now
        )
    )
}
