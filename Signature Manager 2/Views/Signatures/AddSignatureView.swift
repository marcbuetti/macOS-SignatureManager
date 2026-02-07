//
//  AddSignatureView.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 17.09.25.
//

import SwiftUI


private struct MailSignature: Identifiable {
    let id: String
    let name: String
}


private struct M365File: Identifiable, Hashable {
    let id: String
    let name: String
    var url: URL { URL(fileURLWithPath: id) }
}


struct AddSignatureView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    //@AppStorage("app.swpSignatureListReload") private var swpSignatureListReload: Bool = false

    @State private var signatures: [MailSignature] = []
    @State private var selectedSignatureIndex: Int = 0
    @State private var selectedSignatureID: String = ""

    // Storage selector (0 = Local, 1 = Cloud M365)
    @State private var signatureStorageSelection = 1

    // Local file picker
    @State private var selectedHTMLFile: URL? = nil
    @State private var showingFileImporter = false

    // Cloud (M365) files
    @State private var m365Files: [M365File] = []
    @State private var selectedM365Index: Int = 0
    @State private var isLoadingM365: Bool = false
    @State private var m365Error: String? = nil

    // Editor states (nur UI)
    @State private var richText: AttributedString = ""
    @State private var selectedColor: Color = .primary
    @State private var selectedFontSize: CGFloat = 14

    // Intern: Merker für "Rest" des HTMLs (ab <p><br></p><table)
    @State private var htmlTailAfterEditable: String? = nil
    
    let signature: Signature?

    var body: some View {
        ScrollView {
            Spacer(minLength: 10)

            GroupBox {
                VStack {
                    HStack {
                        Text("MAIL_SIGNATURE")
                        Spacer()
                        Picker("", selection: $selectedSignatureIndex) {
                            if signatures.isEmpty {
                                Text("NO_SIGNATURES_FOUND").tag(0)
                            } else {
                                ForEach(signatures.indices, id: \.self) { i in
                                    Text(signatures[i].name).tag(i)
                                }
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedSignatureIndex) { oldValue, newValue in
                            selectedSignatureID = signatures.indices.contains(newValue) ? signatures[newValue].id : ""
                        }
                    }

                    Divider()

                    HStack {
                        Text("SIGNATURE_STORAGE")
                        Spacer()
                        Picker("", selection: $signatureStorageSelection) {
                            Text("LOCAL_STORAGE").tag(0)
                            Text("CLOUD_M365").tag(1)
                        }
                        .pickerStyle(.menu)
                        .onChange(of: signatureStorageSelection) { oldValue, newValue in
                            if newValue == 1 { loadM365Files() }
                            // Storagewechsel → Editor zurücksetzen (optional)
                            richText = ""
                            htmlTailAfterEditable = nil
                            if let url = selectedHTMLFile {
                                loadEditableFromHTML(at: url)
                            }
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

                    if signatureStorageSelection == 1 {
                        HStack() {
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
                                    let baseFiles = m365Files.enumerated().filter { $0.element.name.lowercased().contains("base") }
                                    let customFiles = m365Files.enumerated().filter { $0.element.name.lowercased().contains("custom") }

                                    if !baseFiles.isEmpty {
                                        Text("— BASE —").tag(-1)
                                        ForEach(baseFiles, id: \.offset) { pair in
                                            Text(pair.element.name).tag(pair.offset)
                                        }
                                    }

                                    if !customFiles.isEmpty {
                                        Text("— CUSTOM —").tag(-2)
                                        ForEach(customFiles, id: \.offset) { pair in
                                            Text(pair.element.name).tag(pair.offset)
                                        }
                                    }
                                }
                            }
                            .frame(minWidth: 100)
                            .disabled(isLoadingM365 || (!m365Error.isNil && m365Files.isEmpty))
                            .onChange(of: selectedM365Index) { oldValue, newValue in
                                guard m365Files.indices.contains(newValue) else { return }
                                selectedHTMLFile = m365Files[newValue].url
                                loadEditableFromHTML(at: m365Files[newValue].url)
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
                                Logger.shared.log(position: "AddSignatureView.fileImporter", type: "WARNING", content: "User cancelled or failed selecting HTML file")
                                selectedHTMLFile = nil
                                richText = ""
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
        .navigationTitle("NEW_SIGNATURE")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: saveSignature) {
                    Label("SAVE", systemImage: "checkmark")
                }
                .disabled(saveDisabled)
            }
        }
        .onAppear {
            //migrateMissingSignatureMetadataIfNeeded()
            loadSignaturesFromPlist()
            if signatureStorageSelection == 1 { loadM365Files() }
            if let url = selectedHTMLFile { loadEditableFromHTML(at: url) }
        }
    }

    private var saveDisabled: Bool {
        if signatureStorageSelection == 1 {
            return m365Files.isEmpty || selectedHTMLFile == nil || signatures.isEmpty
        } else {
            return signatures.isEmpty || selectedSignatureID.isEmpty
        }
    }

    private func saveSignature() {
        guard signatures.indices.contains(selectedSignatureIndex) else { return }
        let selectedMailSig = signatures[selectedSignatureIndex]

        if let fileURL = selectedHTMLFile {
            do {
                let original = (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
                let newParagraph = formattedHTMLFromEditor()
                let merged = buildHTMLWithEditedParagraph(
                    originalHTML: original,
                    editedParagraphHTML: newParagraph
                )
                try merged.write(to: fileURL, atomically: true, encoding: .utf8)

                if signatureStorageSelection == 1 {
                    uploadToM365(fileURL: fileURL)
                }
            } catch {
                Logger.shared.log(
                    position: "AddSignatureView.saveSignature",
                    type: "CRITICAL",
                    content: "Failed to write HTML: \(error.localizedDescription)"
                )
            }
        }

        // 🔥 HIER IST DER WICHTIGE TEIL 🔥
        let newSignature = Signature(
            mailSignatureId: selectedMailSig.id,
            name: selectedMailSig.name,
            htmlPath: selectedHTMLFile?.path ?? "",
            storageType: signatureStorageSelection == 0 ? .local : .cloudM365,
            m365FileName: signatureStorageSelection == 1
                ? selectedHTMLFile?.lastPathComponent
                : nil,
            lastUpdated: .now
        )

        context.insert(newSignature)

        dismiss()
    }

    private func loadEditableFromHTML(at url: URL) {
        do {
            let html = try String(contentsOf: url, encoding: .utf8)

            if let splitRange = html.range(of: "<p><br></p><table") {
                let editableHtml = String(html[..<splitRange.lowerBound])
                let tail = String(html[splitRange.lowerBound...]) // Rest behalten
                htmlTailAfterEditable = tail
                let inner = stripOuterParagraph(from: editableHtml)
                let plain = inner
                    .replacingOccurrences(of: "<br>", with: "\n")
                    .replacingOccurrences(of: "&nbsp;", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let attr = attributedFromSimpleHTML(plainHTML: plain)
                richText = attr
            } else {
                htmlTailAfterEditable = nil
                richText = ""
            }
        } catch {
            Logger.shared.log(position: "AddSignatureView.loadEditableFromHTML", type: "CRITICAL", content: "Failed to read HTML: \(error.localizedDescription)")
            htmlTailAfterEditable = nil
            richText = ""
        }
    }

    private func buildHTMLWithEditedParagraph(originalHTML: String, editedParagraphHTML: String) -> String {
        if let splitRange = originalHTML.range(of: "<p><br></p><table") {
            let tail = String(originalHTML[splitRange.lowerBound...])
            return editedParagraphHTML + tail
        } else {
            // Fallback: Struktur neu erzeugen
            return editedParagraphHTML + "<p><br></p><table></table>"
        }
    }

    private func formattedHTMLFromEditor() -> String {
        let full = String(richText.characters)
        var html = full
            .replacingOccurrences(of: "\n", with: "<br>")
            .replacingOccurrences(of: "  ", with: "&nbsp; ")
        html = "<p style=\"font-size: 13px\">\(html)</p>"
        return html
    }

    private func stripOuterParagraph(from html: String) -> String {
        // grob: finde erstes <p ...> und letztes </p>
        guard let startRange = html.range(of: "<p"),
              let closeStart = html.range(of: ">", range: startRange.upperBound..<html.endIndex),
              let endRange = html.range(of: "</p>", options: .backwards)
        else { return html }
        let innerRange = closeStart.upperBound..<endRange.lowerBound
        return String(html[innerRange])
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
                Logger.shared.log(position: "AddSignatureView.uploadToM365", type: "WARNING", content: "M365 upload: could not resolve user")
                return
            }
            GraphService().uploadContentsToRemote(
                remoteAppDataUserFolder: user,
                specificFile: fileURL,
                success: {
                    // Removed success print log per instructions
                },
                failure: {
                    Logger.shared.log(position: "AddSignatureView.uploadToM365", type: "CRITICAL", content: "M365 upload failed")
                }
            )
        }
    }

    private func iso8601Now() -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.string(from: Date())
    }

    /*private func debugPrintSavedSignature(_ index: Int) {
        let id = UserDefaults.standard.string(forKey: "app.signature\(index)ID")
        let name = UserDefaults.standard.string(forKey: "app.signature\(index)Name")
        if id == nil || name == nil || id == "" || name == "" {
            Logger.shared.log(position: "AddSignatureView.debugPrintSavedSignature", type: "WARNING", content: "Saved signature #\(index) has missing id or name")
        }
    }

    private func migrateMissingSignatureMetadataIfNeeded() {
        let total = signaturesCount
        guard total > 0 else { return }

        for i in 1...total {
            let storageKey = "app.signature\(i)StorageType"
            let updatedKey = "app.signature\(i)LastUpdated"
            var didChange = false

            if UserDefaults.standard.string(forKey: storageKey) == nil {
                let html = UserDefaults.standard.string(forKey: "app.signature\(i)HTML") ?? ""
                let derived = html.isEmpty ? "Local Storage" : "Cloud - Microsoft 365"
                UserDefaults.standard.set(derived, forKey: storageKey)
                didChange = true
            }

            if UserDefaults.standard.string(forKey: updatedKey) == nil {
                UserDefaults.standard.set(iso8601Now(), forKey: updatedKey)
                didChange = true
            }

            if didChange {
                let id     = UserDefaults.standard.string(forKey: "app.signature\(i)ID") ?? "–"
                let name   = UserDefaults.standard.string(forKey: "app.signature\(i)Name") ?? "–"
                let html   = UserDefaults.standard.string(forKey: "app.signature\(i)HTML") ?? "–"
                let file   = UserDefaults.standard.string(forKey: "app.m365Signature\(i)FileName") ?? "–"
                let when   = UserDefaults.standard.string(forKey: updatedKey) ?? "–"
                let stype  = UserDefaults.standard.string(forKey: storageKey) ?? "–"

                print("""
                [Migration] Filled missing fields for signature #\(i):
                - ID: \(id)
                - Name: \(name)
                - HTML/Path: \(html)
                - M365 File: \(file)
                - Storage Type: \(stype)
                - Last Updated: \(when)
                """)
            }
        }
    }*/

    private func loadM365Files() {
        isLoadingM365 = true
        m365Error = nil
        m365Files = []
        selectedHTMLFile = nil
        selectedM365Index = 0
        richText = ""
        htmlTailAfterEditable = nil

        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let targetDir = appSupport.appendingPathComponent("com.mbuettner.SignatureManager/OnlineSignatures", isDirectory: true)
        try? fm.createDirectory(at: targetDir, withIntermediateDirectories: true)

        FileManagerHelper().deleteAllHTMLFiles()

        let graph = GraphService()
        graph.fetchRemoteUser { user in
            guard let user = user else {
                Logger.shared.log(position: "AddSignatureView.loadM365Files", type: "WARNING", content: "Could not resolve user for M365 fetch")
                DispatchQueue.main.async {
                    self.isLoadingM365 = false
                    self.m365Error = "Could not load user"
                }
                return
            }
            graph.fetchSubfolderContentsAndDownload(fromMacOSFolder: user, success: {
                do {
                    let baseDir = targetDir.appendingPathComponent("base", isDirectory: true)
                    let customDir = targetDir.appendingPathComponent("custom", isDirectory: true)

                    var collectedFiles: [M365File] = []

                    if let baseFiles = try? fm.contentsOfDirectory(at: baseDir, includingPropertiesForKeys: nil) {
                        let htmls = baseFiles.filter { ["html", "txt"].contains($0.pathExtension.lowercased()) }
                        collectedFiles.append(contentsOf: htmls.map {
                            M365File(id: $0.path, name: "base / \($0.lastPathComponent)")
                        })
                    }

                    if let customFiles = try? fm.contentsOfDirectory(at: customDir, includingPropertiesForKeys: nil) {
                        let htmls = customFiles.filter { ["html", "txt"].contains($0.pathExtension.lowercased()) }
                        collectedFiles.append(contentsOf: htmls.map {
                            M365File(id: $0.path, name: "custom / \($0.lastPathComponent)")
                        })
                    }

                    let files = collectedFiles.sorted {
                        $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    }

                    DispatchQueue.main.async {
                        self.m365Files = files
                        self.isLoadingM365 = false
                        if let first = files.first {
                            self.selectedM365Index = 0
                            self.selectedHTMLFile = first.url
                            self.loadEditableFromHTML(at: first.url)
                        }
                    }
                } catch {
                    Logger.shared.log(position: "AddSignatureView.loadM365Files", type: "CRITICAL", content: "Failed to read downloaded files: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isLoadingM365 = false
                        self.m365Error = error.localizedDescription
                    }
                }
            }, failure: {
                Logger.shared.log(position: "AddSignatureView.loadM365Files", type: "CRITICAL", content: "Download of M365 files failed")
                DispatchQueue.main.async {
                    self.isLoadingM365 = false
                    self.m365Error = "Download failed"
                }
            })
        }
    }

    private func loadSignaturesFromPlist() {
        guard let plistURL = findAllSignaturesPlist() else {
            signatures = []; selectedSignatureIndex = 0; selectedSignatureID = ""; return
        }
        do {
            let data = try Data(contentsOf: plistURL)
            if let array = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [[String: Any]] {
                signatures = array.compactMap { dict in
                    guard let name = dict["SignatureName"] as? String,
                          let uid  = dict["SignatureUniqueId"] as? String else { return nil }
                    return MailSignature(id: uid, name: name)
                }
                if !signatures.isEmpty {
                    selectedSignatureIndex = 0
                    selectedSignatureID = signatures[0].id
                }
            }
        } catch {
            signatures = []
        }
    }

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
            if FileManager.default.fileExists(atPath: plist.path) { return plist }
        }
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
    let sig = Signature(
        mailSignatureId: "preview",
        name: "Preview",
        htmlPath: "/tmp/test.html",
        storageType: .local
    )
    AddSignatureView(signature: sig)
}

