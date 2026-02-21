//
//  LogView.swift
//  Signature Manager
//
//  Created by Marc Büttner on 21.08.25.
//

import Foundation
import SwiftUI
import AppKit

private func getSystemLogHeader() -> String {
    let model: String = {
        var size: size_t = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        return String(cString: machine)
    }()
    let arch: String = {
        var isTranslated = false
        if #available(macOS 11.0, *) {
            var ret: Int32 = 0
            var size = MemoryLayout<Int32>.size
            let result = sysctlbyname("sysctl.proc_translated", &ret, &size, nil, 0)
            if result == 0 {
                isTranslated = (ret == 1)
            }
        }
        #if arch(x86_64)
        return isTranslated ? "Rosetta (Intel emuliert)" : "Intel"
        #elseif arch(arm64)
        return isTranslated ? "Rosetta (Intel emuliert)" : "ARM"
        #else
        return "Unbekannt"
        #endif
    }()
    let os = ProcessInfo.processInfo.operatingSystemVersion
    let osVersion = "macOS \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    return "--- SYSTEMINFO ---\nDevice: \(model)\nArch: \(arch)\nOS: \(osVersion)\nApp: \(appVersion) (Build \(build))\n--- END OF SYSTEMINFO ---\n\n"
}


struct ShareFileButton: View {
    @State private var buttonView: NSView? = nil
    
    var body: some View {
        Button(action: {
            let logContent = LogManager.shared.getLog()
            let header = getSystemLogHeader()
            let combinedContent = header + logContent
            
            let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            let tempFileURL = tempDir.appendingPathComponent("signatureManager_app.log")
            
            do {
                try combinedContent.write(to: tempFileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Fehler beim Schreiben der temporären Log-Datei: \(error)")
                return
            }
            
            if let buttonView = buttonView {
                let picker = NSSharingServicePicker(items: [tempFileURL])
                picker.show(relativeTo: .zero, of: buttonView, preferredEdge: .maxY)
            }
        }) {
            Label("EXPORT", systemImage: "square.and.arrow.up")
        }
        .background(AnchorRepresentable(view: $buttonView))
    }
}


private struct AnchorRepresentable: NSViewRepresentable {
    @Binding var view: NSView?
    func makeNSView(context: Context) -> NSView {
        let nsView = NSView()
        DispatchQueue.main.async { self.view = nsView }
        return nsView
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

private struct ReadOnlyTextView: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.backgroundColor = .clear

        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        textView.string = text
        textView.scrollToEndOfDocument(nil)
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
            textView.scrollToEndOfDocument(nil)
        }
    }
}

struct LogView: View {
    @State private var showShareSheet = false
    @State private var logText: String = ""
    @State private var isLoading = false
    @State private var showDeleteConfirm = false
    @State private var deleteError: String? = nil

    var body: some View {
        ZStack {
            ReadOnlyTextView(text: $logText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        ShareFileButton()
                    }
                    ToolbarItem(placement: .automatic) {
                        Button {
                            isLoading = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                logText = LogManager.shared.getLog()
                                isLoading = false
                            }
                        } label: {
                            Label("RELOAD", systemImage: "arrow.clockwise")
                        }
                    }
                    ToolbarItem(placement: .automatic) {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("DELETE", systemImage: "trash")
                        }
                    }
                }

            if isLoading {
                Color.black.opacity(0.6).edgesIgnoringSafeArea(.all)
                ProgressView().scaleEffect(1.5)
            }
        }
        .onAppear {
            logText = LogManager.shared.getLog()
        }
        .overlay {
            if LogManager.shared.getLog().isEmpty{
                ContentUnavailableView("NO_LOGS_YET",
                                       systemImage: "doc.text.magnifyingglass")
                .padding(.top, 40)
            }
        }
        .confirmationDialog(
            String(localized: "DELETE_LOG_CONFIRMATION"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("DELETE", role: .destructive) {
                do {
                    try LogManager.shared.clearLog()
                    logText = ""
                } catch {
                    deleteError = error.localizedDescription
                }
            }
            Button("CANCEL", role: .cancel) {}
        }
        .alert("DELETE_FAILED", isPresented: .constant(deleteError != nil)) {
            Button("OK") { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
    }
}


#Preview {
    LogView()
}

