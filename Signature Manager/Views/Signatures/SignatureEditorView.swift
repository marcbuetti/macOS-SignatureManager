//
//  AddSignatureView.swift
//  Signature Manager
//
//  Created by Marc Büttner on 17.09.25.
//

import SwiftUI
import SwiftData

struct SignatureEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("graph.clientId") private var clientId: String = ""
    @AppStorage("graph.tenantId") private var tenantId: String = ""
    @AppStorage("graph.clientSecret") private var clientSecret: String = ""
    @AppStorage("graph.sharepointDomain") private var sharepointDomain: String = ""
    @AppStorage("graph.siteId") private var siteId: String = ""
    @AppStorage("graph.standardFolderName") private var standardFolderName: String = ""
    @AppStorage("graph.AppDataFolder") private var AppDataFolder: String = ""

    @State private var signatures: [MailSignature] = []
    @State private var selectedSignatureIndex: Int = 0
    @State private var selectedSignatureID: String = ""
    @State private var selectedStandardIndex: Int = -1
    @State private var signatureStorageSelection = 1
    @State private var selectedHTMLFile: URL? = nil
    @State private var showingFileImporter = false
    @State private var m365Files: [M365File] = []
    @State private var selectedM365Index: Int = 0
    @State private var isLoadingM365: Bool = false
    @State private var m365Error: String? = nil
    @State private var richText: AttributedString = ""
    @State private var selectedColor: Color = .primary
    @State private var selectedFontSize: CGFloat = 13
    @State private var htmlBeforeCustom: String = ""
    @State private var htmlAfterCustom: String = ""
    @State private var draftCustomID: String? = nil
    @State private var isProcessing: Bool = false
    @State private var originalCustomName: String? = nil
    @State private var customSignatureName: String = ""
    
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
                    }

                    Divider()

                    HStack {
                        Text("SIGNATURE_STORAGE")
                        Spacer()
                        Picker("", selection: $signatureStorageSelection) {
                            Text("LOCAL_STORAGE").tag(0)
                            //MARK: FIX LATER - I THINK ITS THE CACHED RENAMING
                            //if (clientId != "" && clientSecret != "" && tenantId != "" && sharepointDomain != "" && siteId != "" && standardFolderName != "" && AppDataFolder != "") {
                                Text("CLOUD_M365").tag(1)
                            //}
                        }
                        .pickerStyle(.menu)
                        .onChange(of: signatureStorageSelection) { oldValue, newValue in
                            if newValue == 1 {
                                // Switching to Cloud: load M365 files and reset editor state
                                loadM365Files()
                                richText = ""
                                htmlAfterCustom = ""
                            } else {
                                // Switching to Local: clear current selection and editor so user must pick a file again
                                selectedHTMLFile = nil
                                selectedM365Index = 0
                                richText = ""
                                htmlAfterCustom = ""
                            }
                        }
                    }
                }
                .padding(4)
            }
            .cardStyle()

            Spacer(minLength: 30)
            
            GroupBox {
                VStack {
                    let isCloud = signatureStorageSelection == 1
                    let hasSelection = m365Files.indices.contains(selectedM365Index) || selectedM365Index == -2
                    let isCustomSelection: Bool = {
                        if selectedM365Index == -2 { return true }
                        guard m365Files.indices.contains(selectedM365Index) else {
                            // no valid selection yet => not custom/new
                            return false
                        }
                        return m365Files[selectedM365Index].name.lowercased().contains("custom")
                    }()
                    if isCloud && hasSelection && isCustomSelection {
                        HStack {
                            Text("NAME")
                            Spacer()
                            TextField("SIGNATURE_NAME_PLACEHOLDER", text: $customSignatureName)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 6)
                                .disabled(selectedM365Index != -2)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("STANDARD_SIGNATURE")
                            Spacer()
                            if isLoadingM365 {
                                ProgressView().controlSize(.small)
                                    .padding(.trailing, -10)
                            }
                            Picker("", selection: $selectedStandardIndex) {
                                
                                if let err = m365Error {
                                    Text("ERROR: \(err)").tag(0)
                                } else if m365Files.isEmpty {
                                    Text(isLoadingM365 ? "LOADING" : "NO_FILES_FOUND").tag(0)
                                } else {
                                    let standardFiles = m365Files.enumerated()
                                        .filter { $0.element.name.lowercased().contains("standard") }
                                    if !standardFiles.isEmpty {
                                        ForEach(standardFiles, id: \.offset) { pair in
                                            let displayNamestandard = pair.element.name.replacingOccurrences(of: "standard / ", with: "")
                                            Text(displayNamestandard.replacingOccurrences(of: ".html", with: "").replacingOccurrences(of: ".txt", with: ""))
                                                .tag(pair.offset)
                                        }
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                            .disabled(isLoadingM365 || (!m365Error.isNil && m365Files.isEmpty))
                            .onChange(of: selectedStandardIndex) { _, newValue in
                                guard m365Files.indices.contains(newValue) else { return }

                                let standardURL = m365Files[newValue].url

                                do {
                                    let standardHTML = try String(contentsOf: standardURL, encoding: .utf8)

                                    let fileName = m365Files[newValue].name
                                        .replacingOccurrences(of: "standard / ", with: "")

                                    let tagName = standardTagName(from: fileName)
                                    
                                    let currentFullHTML = htmlBeforeCustom + formattedHTMLFromEditor() + htmlAfterCustom
                                    if currentFullHTML.contains("<\(tagName)>") && currentFullHTML.contains("</\(tagName)>") {
                                        return
                                    }

                                    let extracted = extractStandardHTML(
                                        from: standardHTML,
                                        tagName: tagName
                                    )

                                    replaceStandardSignature(with: extracted)

                                } catch {
                                    Logger.shared.log(
                                        position: "AddSignatureView.standardPicker",
                                        type: "CRITICAL",
                                        content: error.localizedDescription
                                    )
                                }
                            }
                            .onAppear {
                                guard selectedStandardIndex == -1 else { return }

                                if let firstStandardIndex = m365Files.firstIndex(where: {
                                    $0.name.lowercased().contains("standard")
                                }) {
                                    selectedStandardIndex = firstStandardIndex
                                    // ❗ KEIN htmlAfterCustom setzen
                                }
                            }
                        }
                        
                        Divider()
                        
                    }

                    HStack {
                        Text("SIGNATURE")
                        Spacer()
                        if signatureStorageSelection == 1 {
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
                                    
                                    let standardFiles = m365Files.enumerated()
                                        .filter { $0.element.name.lowercased().contains("standard") }
                                    
                                    let customFiles = m365Files.enumerated()
                                        .filter { $0.element.name.lowercased().contains("custom") }
                                    
                                    if !standardFiles.isEmpty {
                                        Section("STANDARD") {
                                            ForEach(standardFiles, id: \.offset) { pair in
                                                let displayNamestandard = pair.element.name.replacingOccurrences(of: "standard / ", with: "")
                                                Text(displayNamestandard.replacingOccurrences(of: ".html", with: "").replacingOccurrences(of: ".txt", with: ""))
                                                    .tag(pair.offset)
                                            }
                                        }
                                    }
                                    
                                    
                                    if !customFiles.isEmpty {
                                        Section("CUSTOM") {
                                            ForEach(customFiles, id: \.offset) { pair in
                                                let displayNameCustom = pair.element.name.replacingOccurrences(of: "custom / ", with: "")
                                                Text(displayNameCustom.replacingOccurrences(of: ".html", with: "").replacingOccurrences(of: ".txt", with: ""))
                                                    .tag(pair.offset)
                                            }
                                        }
                                    }
                                    
                                    Section() {
                                        Label("NEW_CUSTOM_SIGNATURE", systemImage: "plus").tag(-2)
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                            .disabled(isLoadingM365 || (!m365Error.isNil && m365Files.isEmpty))
                            .onChange(of: selectedM365Index) { _, newValue in
                                
                                // 🆕 NEW_CUSTOM_SIGNATURE
                                if newValue == -2 {

                                    selectedSignatureID = ""

                                    // 1️⃣ Draft-ID einmalig erzeugen
                                    if draftCustomID == nil {
                                        draftCustomID = UUID().uuidString
                                    }

                                    let draftURL = cacheFileURLForDraft(id: draftCustomID!)

                                    // 2️⃣ Leere Draft-Datei anlegen
                                    if !FileManager.default.fileExists(atPath: draftURL.path) {
                                        let emptyHTML = """
                                        <custom>
                                            <p></p>
                                        </custom>
                                        """
                                        try? emptyHTML.write(to: draftURL, atomically: true, encoding: .utf8)
                                    }

                                    // 3️⃣ Draft laden
                                    selectedHTMLFile = draftURL
                                    loadEditableFromHTML(at: draftURL, forceNoCache: true)

                                    // 🔥 4️⃣ WENN ein Standard selektiert ist → direkt einbauen
                                    if m365Files.indices.contains(selectedStandardIndex),
                                       m365Files[selectedStandardIndex].name.lowercased().contains("standard") {

                                        let standardURL = m365Files[selectedStandardIndex].url

                                        if let html = try? String(contentsOf: standardURL, encoding: .utf8) {

                                            let fileName = m365Files[selectedStandardIndex].name
                                                .replacingOccurrences(of: "standard / ", with: "")

                                            let tagName = standardTagName(from: fileName)

                                            let extracted = extractStandardHTML(
                                                from: html,
                                                tagName: tagName
                                            )

                                            replaceStandardSignature(with: extracted)
                                        }
                                    }

                                    return
                                }

                                // 🔁 Normale Auswahl (STANDARD / CUSTOM)
                                guard m365Files.indices.contains(newValue) else { return }

                                let originalURL = m365Files[newValue].url

                                if m365Files[newValue].name.lowercased().contains("custom") {
                                    let cachedURL = cachedURLForExistingCustom(originalURL: originalURL)
                                    selectedHTMLFile = cachedURL
                                    loadEditableFromHTML(at: cachedURL)
                                } else {
                                    // STANDARD
                                    selectedHTMLFile = originalURL
                                    loadEditableFromHTML(at: originalURL, forceNoCache: true)
                                }

                                let itemName = m365Files[newValue].name
                                if itemName.lowercased().contains("custom") {
                                    let cleanName = itemName
                                        .replacingOccurrences(of: "custom / ", with: "")
                                        .replacingOccurrences(of: ".html", with: "")
                                        .replacingOccurrences(of: ".txt", with: "")

                                    customSignatureName = cleanName
                                    originalCustomName = cleanName
                                }
                            }
                        } else {
                            HStack(alignment: .center, spacing: 8) {
                                if let url = selectedHTMLFile {
                                    Text(url.deletingPathExtension().lastPathComponent)
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
                                    htmlAfterCustom = ""
                                }
                            }
                        }
                    }
                }
                .padding(4)
            }
            .cardStyle()

            
            if signatureStorageSelection == 0 || (signatureStorageSelection == 1 && (m365Files.indices.contains(selectedM365Index) || selectedM365Index == -2) && (selectedM365Index == -2 || m365Files[selectedM365Index].name.lowercased().contains("custom"))) {
                GroupBox {
                    VStack(alignment: .leading) {
                        /*HStack {
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
                        .padding(.bottom, 4)*/

                        TextEditor(text: Binding(
                            get: { String(richText.characters) },
                            set: {
                                richText = AttributedString($0)
                                autosaveToCache()
                            }
                        ))
                        .font(.system(size: selectedFontSize))
                        .foregroundColor(selectedColor)
                        .frame(height: 350)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2)))
                        
                        if signatureStorageSelection == 1 {
                            Text("AFTER_SIGNATURE_PLACEHOLDER")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(4)

                }
                .cardStyle()
            }
        }
        .navigationTitle(
            signature == nil ? "NEW_SIGNATURE" : "EDIT_SIGNATURE"
        )
        .toolbar {
            if !isProcessing {
                Button {
                    saveSignature()
                    isProcessing = true
                } label: {
                    Label(
                        signature == nil ? "SAVE" : "UPDATE",
                        systemImage: "checkmark"
                    )
                }
                .disabled(saveDisabled)

                // ❗ NUR IM EDIT-MODUS
                if let sig = signature {
                    Button(role: .destructive) {
                        context.delete(sig)
                        dismiss()
                    } label: {
                        Label("DELETE", systemImage: "trash")
                    }
                }
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .onAppear {
            loadSignaturesFromPlist()

            // ➕ ADD MODE
            guard let sig = signature else {
                if signatureStorageSelection == 1 {
                    loadM365Files()
                }
                return
            }

            // ✏️ EDIT MODE (Preload)
            signatureStorageSelection = sig.storageType == .local ? 0 : 1

            if let idx = signatures.firstIndex(where: { $0.id == sig.mailSignatureId }) {
                selectedSignatureIndex = idx
                selectedSignatureID = sig.mailSignatureId
            }

            if !sig.htmlPath.isEmpty {
                let url = URL(fileURLWithPath: sig.htmlPath)
                selectedHTMLFile = url
                loadEditableFromHTML(at: url)
            }

            if sig.storageType == .cloudM365 {
                loadM365Files(preselect: sig)
            } else {
                if !sig.htmlPath.isEmpty {
                    let url = URL(fileURLWithPath: sig.htmlPath)
                    selectedHTMLFile = url
                    loadEditableFromHTML(at: url)
                }
            }
        }
    }

    private var saveDisabled: Bool {
        if signatureStorageSelection == 1 {
            return m365Files.isEmpty
                || selectedHTMLFile == nil
                || signatures.isEmpty
                || customSignatureName.trimmingCharacters(in: .whitespaces).isEmpty
        } else {
            return signatures.isEmpty
        }
    }

    private func saveSignature() {
        // 🔥 FINALEN NAMEN FESTLEGEN
        guard signatures.indices.contains(selectedSignatureIndex) else { return }
        let selectedMailSig = signatures[selectedSignatureIndex]
        
        // 🔹 Name für SwiftData (Apple Mail)
        let mailSignatureName = selectedMailSig.name

        // 🔹 Name für Cache / M365
        let customName = normalizeSignatureName(customSignatureName)
        let finalCacheURL = cacheFileURLForCustom(name: customName)

        // 🔁 LOKAL UMBENENNEN (Draft ODER bestehende Custom)
        if let currentURL = selectedHTMLFile,
           currentURL != finalCacheURL {

            try? FileManager.default.moveItem(
                at: currentURL,
                to: finalCacheURL
            )

            selectedHTMLFile = finalCacheURL
        }

        // Draft ist jetzt final
        draftCustomID = nil
        originalCustomName = mailSignatureName
        
        
        if let fileURL = selectedHTMLFile {
            do {
                let original = (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
                let newParagraph = formattedHTMLFromEditor()
                let merged = buildHTMLWithEditedParagraph(
                    originalHTML: original,
                    editedCustomHTML: newParagraph
                )
                try merged.write(to: fileURL, atomically: true, encoding: .utf8)

                if signatureStorageSelection == 1 {
                    let graph = GraphService()

                    graph.fetchRemoteUser { user in
                        guard let user else { return }

                        graph.uploadCustomSignature(
                            userFolder: user,
                            localFileURL: selectedHTMLFile!,
                            desiredName: customSignatureName,
                            success: { finalFileName in
                                DispatchQueue.main.async {
                                    // 🔥 Cache-Datei ggf. anpassen
                                    let cleanName = finalFileName.replacingOccurrences(of: ".html", with: "")
                                    let finalCacheURL = cacheFileURLForCustom(name: cleanName)

                                    if fileURL != finalCacheURL {
                                        try? FileManager.default.moveItem(
                                            at: fileURL,
                                            to: finalCacheURL
                                        )
                                        selectedHTMLFile = finalCacheURL
                                    }
                                }
                            },
                            failure: {
                                Logger.shared.log(
                                    position: "AddSignatureView.saveSignature",
                                    type: "CRITICAL",
                                    content: "M365 custom signature upload failed"
                                )
                            }
                        )
                    }
                }
            } catch {
                Logger.shared.log(
                    position: "AddSignatureView.saveSignature",
                    type: "CRITICAL",
                    content: "Failed to write HTML: \(error.localizedDescription)"
                )
            }
        }

        if let existing = signature {
            // 🔁 UPDATE
            existing.mailSignatureId = selectedMailSig.id
            existing.name = mailSignatureName
            existing.htmlPath = selectedHTMLFile?.path ?? ""
            existing.storageType = signatureStorageSelection == 0 ? .local : .cloudM365
            existing.m365FileName = signatureStorageSelection == 1
                ? selectedHTMLFile?.lastPathComponent
                : nil
            existing.lastUpdated = .now

            dismiss()
            return
        }

        // ➕ CREATE
        let newSignature = Signature(
            mailSignatureId: selectedMailSig.id,
            name: mailSignatureName,
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

    private func loadEditableFromHTML(at url: URL, forceNoCache: Bool = false) {
        do {
            // 🧠 Entscheidung ist bereits VORHER gefallen
            // STANDARD → url = OnlineSignatures
            // CUSTOM / DRAFT → url = cache/custom/…
            let html = try String(contentsOf: url, encoding: .utf8)
            
            // Inserted new detection and setting for standard tag
            if signatureStorageSelection == 1 {
                if let detected = detectStandardTag(in: html) {
                    // find matching index in m365Files and set selectedStandardIndex
                    for (idx, file) in m365Files.enumerated() where file.name.lowercased().contains("standard") {
                        let clean = file.name.replacingOccurrences(of: "standard / ", with: "")
                        let tag = standardTagName(from: clean)
                        if tag == detected {
                            selectedStandardIndex = idx
                            break
                        }
                    }
                }
            }
            

            guard
                let start = html.range(of: "<custom>"),
                let end = html.range(of: "</custom>")
            else {
                Logger.shared.log(
                    position: "AddSignatureView.loadEditableFromHTML",
                    type: "WARNING",
                    content: "<custom> block not found"
                )
                richText = ""
                htmlBeforeCustom = html
                htmlAfterCustom = ""
                
                // 🔁 Standard-Signatur anhand Wrapper-Tag erkennen
                if signatureStorageSelection == 1 {
                    for (index, file) in m365Files.enumerated() {
                        guard file.name.lowercased().contains("standard") else { continue }

                        let cleanName = file.name
                            .replacingOccurrences(of: "standard / ", with: "")

                        let tag = standardTagName(from: cleanName)

                        if html.contains("<\(tag)>") {
                            selectedStandardIndex = index
                            break
                        }
                    }
                }
                return
            }

            htmlBeforeCustom = String(html[..<start.lowerBound])
            htmlAfterCustom = String(html[end.upperBound...])

            let innerHTML = String(html[start.upperBound..<end.lowerBound])

            let plain = innerHTML
                .replacingOccurrences(of: "<br>", with: "\n")
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "<p[^>]*>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "</p>", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            richText = AttributedString(plain)

        } catch {
            Logger.shared.log(
                position: "AddSignatureView.loadEditableFromHTML",
                type: "CRITICAL",
                content: error.localizedDescription
            )
            richText = ""
            htmlBeforeCustom = ""
            htmlAfterCustom = ""
        }
    }

    private func buildHTMLWithEditedParagraph(
        originalHTML: String,
        editedCustomHTML: String
    ) -> String {
        return htmlBeforeCustom + editedCustomHTML + htmlAfterCustom
    }

    private func formattedHTMLFromEditor() -> String {
        let text = String(richText.characters)
            .replacingOccurrences(of: "\n", with: "<br>")
            .replacingOccurrences(of: "  ", with: "&nbsp; ")

        return """
        <custom>
            <p style="font-size: \(Int(selectedFontSize))px;">\(text)</p>
        </custom>
        """
    }
    
    
    
    private func standardTagName(from fileName: String) -> String {
        let base = fileName
            .replacingOccurrences(of: ".html", with: "")
            .replacingOccurrences(of: ".txt", with: "")
            .lowercased()

        let cleaned = base
            .replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
            .replacingOccurrences(of: " ", with: "_")

        return cleaned
    }
    
    private func detectStandardTag(in html: String) -> String? {
        // matches <tagname> where tagname can include a-z, 0-9 and underscores, and ignores common HTML tags
        // We will scan for tags that also exist in our standard list
        let pattern = "<([a-z0-9_]+)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(location: 0, length: (html as NSString).length)
        let matches = regex.matches(in: html, options: [], range: range)

        // Build a set of valid standard tags from m365Files
        let validTags: Set<String> = Set(
            m365Files
                .filter { $0.name.lowercased().contains("standard") }
                .map { file in
                    let name = file.name.replacingOccurrences(of: "standard / ", with: "")
                    return standardTagName(from: name)
                }
        )

        for m in matches {
            if m.numberOfRanges >= 2, let r = Range(m.range(at: 1), in: html) {
                let candidate = String(html[r]).lowercased()
                if validTags.contains(candidate) {
                    return candidate
                }
            }
        }
        return nil
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


    private func iso8601Now() -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.string(from: Date())
    }


    private func loadM365Files(preselect signature: Signature? = nil) {
        isLoadingM365 = true
        m365Error = nil
        m365Files = []
        selectedHTMLFile = nil
        selectedM365Index = 0
        richText = ""
        htmlAfterCustom = ""

        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let targetDir = appSupport.appendingPathComponent("com.mbuettner.SignatureManager/onlineSignatures", isDirectory: true)
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
                    let standardDir = targetDir.appendingPathComponent("standard", isDirectory: true)
                    let customDir = targetDir.appendingPathComponent("custom", isDirectory: true)

                    var collectedFiles: [M365File] = []

                    if let standardFiles = try? fm.contentsOfDirectory(at: standardDir, includingPropertiesForKeys: nil) {
                        let htmls = standardFiles.filter { ["html", "txt"].contains($0.pathExtension.lowercased()) }
                        collectedFiles.append(contentsOf: htmls.map {
                            M365File(id: $0.path, name: "standard / \($0.lastPathComponent)")
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
                        if let sig = signature,
                           sig.storageType == .cloudM365,
                           let usedFileName = sig.m365FileName {

                            // 1️⃣ CUSTOM-Datei selektieren
                            if let customIndex = files.firstIndex(where: {
                                $0.name.lowercased().contains("custom") &&
                                $0.name.lowercased().contains(usedFileName.lowercased())
                            }) {

                                self.selectedM365Index = customIndex

                                let originalURL = files[customIndex].url
                                let cachedURL = cachedURLForExistingCustom(originalURL: originalURL)
                                self.selectedHTMLFile = cachedURL
                                self.loadEditableFromHTML(at: cachedURL)

                                let cleanName = usedFileName
                                    .replacingOccurrences(of: ".html", with: "")
                                    .replacingOccurrences(of: ".txt", with: "")

                                self.customSignatureName = cleanName
                                self.originalCustomName = cleanName

                            } else {
                                // 2️⃣ FALLBACK: Nur STANDARD vorhanden
                                self.selectedM365Index = 0
                                self.selectedHTMLFile = files[0].url
                                self.loadEditableFromHTML(at: files[0].url, forceNoCache: true)
                            }
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
    
    private func autosaveToCache() {
        guard let url = selectedHTMLFile else { return }

        let html = htmlBeforeCustom
            + formattedHTMLFromEditor()
            + htmlAfterCustom

        try? html.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func shouldUseCache(for index: Int) -> Bool {
        guard signatureStorageSelection == 1 else { return false }
        guard m365Files.indices.contains(index) else { return false }
        return m365Files[index].name.lowercased().contains("custom")
    }
    
    
    //MARK: TEMP HERE - CHECK LATER
    private func cacheDirectory() -> URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let dir = base
            .appendingPathComponent("com.mbuettner.SignatureManager")
            .appendingPathComponent("cache")
            .appendingPathComponent("custom")

        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )

        return dir
    }
    
    private func cacheFileURLForDraft(id: String) -> URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let dir = base
            .appendingPathComponent("com.mbuettner.SignatureManager")
            .appendingPathComponent("cache")
            .appendingPathComponent("custom")
            .appendingPathComponent("drafts", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )

        return dir.appendingPathComponent("\(id).html")
    }
    
    private func cacheFileURLForCustom(name: String) -> URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let dir = base
            .appendingPathComponent("com.mbuettner.SignatureManager")
            .appendingPathComponent("cache")
            .appendingPathComponent("custom", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )

        return dir.appendingPathComponent("\(name).html")
    }
    
    private func renameDraftIfNeeded(newName: String) {
        guard
            selectedM365Index == -2,
            let draftID = draftCustomID
        else { return }

        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else { return } // optional Sicherheit

        let oldURL = cacheFileURLForDraft(id: draftID)
        let newURL = cacheFileURLForCustom(name: trimmed)

        guard
            FileManager.default.fileExists(atPath: oldURL.path),
            !FileManager.default.fileExists(atPath: newURL.path)
        else { return }

        do {
            try FileManager.default.moveItem(at: oldURL, to: newURL)
            selectedHTMLFile = newURL

            // 🔥 WICHTIG: Draft ist jetzt FINAL
            draftCustomID = nil
        } catch {
            Logger.shared.log(
                position: "AddSignatureView.renameDraftIfNeeded",
                type: "CRITICAL",
                content: error.localizedDescription
            )
        }
    }
    
    private func cachedURLForExistingCustom(originalURL: URL) -> URL {
        let cacheURL = cacheFileURLForCustom(
            name: originalURL.deletingPathExtension().lastPathComponent
        )

        if !FileManager.default.fileExists(atPath: cacheURL.path) {
            try? FileManager.default.copyItem(at: originalURL, to: cacheURL)
        }

        return cacheURL
    }
    
    
    
    private func extractStandardHTML(from html: String, tagName: String) -> String {
        let content: String

        if let range = html.range(of: "<p><br></p>") {
            content = String(html[range.lowerBound...])
        } else if let range = html.range(of: "<table") {
            content = "<p><br></p>\n" + String(html[range.lowerBound...])
        } else {
            content = html
        }

        return """
        <\(tagName)>
        \(content)
        </\(tagName)>
        """
    }
    
    private func replaceStandardSignature(with standardHTML: String) {
        htmlAfterCustom = standardHTML

        autosaveToCache()
    }
    
    private func normalizeSignatureName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
    }
}


private extension Optional where Wrapped == String {
    var isNil: Bool { self == nil }
}

private struct MailSignature: Identifiable {
    let id: String
    let name: String
}


private struct M365File: Identifiable, Hashable {
    let id: String
    let name: String
    var url: URL { URL(fileURLWithPath: id) }
}

private extension View {
    func cardStyle() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

#Preview {
    /*let sig = Signature(
        mailSignatureId: "preview",
        name: "Preview",
        htmlPath: "/tmp/test.html",
        storageType: .local
    )*/
    SignatureEditorView(signature: nil)
}

