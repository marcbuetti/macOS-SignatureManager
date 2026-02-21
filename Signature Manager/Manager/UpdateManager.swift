//
//  UpdateManager.swift
//  Signature Manager
//
//  Created by Marc Büttner on 08.09.25.
//

import Combine
import SwiftUI
import SwiftData
import UserNotifications


public final class UpdateManager: ObservableObject {

    public static let shared = UpdateManager()

    @AppStorage("app.showProcessMenuBarLiveActivity") private var showProcessMenuBarLiveActivity: Bool = false
    @AppStorage("app.lastUpdate") private var lastUpdateTimestamp: String = ""

    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var statusText: String = "Idle"
    @Published public private(set) var progress: Double = 0.0  // 0...1
    @Published public private(set) var lastResultOK: Bool? = nil

    weak var liveActivity: MenuBarLiveActivity?
    public weak var menuBarPresenter: MenuBarPresenting?
    public weak var delegate: UpdateManagerDelegate?
    var graphService: GraphService = GraphService()
    private let workQueue = DispatchQueue(label: "com.marcbuetti.signaturemanager2.updatemanager", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()

    // Shared SwiftData context injected from App
    private var sharedContext: ModelContext?
    public func setModelContext(_ context: ModelContext) {
        self.sharedContext = context
    }

    public func start(remoteRequested: Bool) {
        guard isRunning == false else {
            LogManager.shared.log(.warning, "Start ignored: update already running", fileID: #fileID, function: #function, line: #line)
            return
        }

        isRunning = true
        lastResultOK = nil
        progress = 0
        statusText = remoteRequested ? "Preparing… (requested by your organization)" : "Preparing…"
        updateMenuBarForStart()

        if showProcessMenuBarLiveActivity {
            liveActivity?.showLiveActivity = true
            liveActivity?.progress = 0
            menuBarPresenter?.showLiveActivity(true)
            menuBarPresenter?.setLiveActivityProgress(0)
        }

        workQueue.async { [weak self] in
            guard let self else { return }
            self.run(remoteRequested: remoteRequested)
        }
    }

    public func resetUI() {
        DispatchQueue.main.async {
            self.isRunning = false
            self.statusText = "Idle"
            self.progress = 0
            self.lastResultOK = nil

            self.liveActivity?.showLiveActivity = false
            self.liveActivity?.progress = 0
            self.menuBarPresenter?.showLiveActivity(false)
            self.menuBarPresenter?.setLiveActivityProgress(0)
            self.menuBarPresenter?.setIcon(state: MenuBarIconState.ok, toolTip: String(localized: "SIGNATURE_MANAGER_UP_TO_DATE_TT"))
        }
    }
}


public protocol UpdateManagerDelegate: AnyObject {
    func updateManagerRequestsClosingMail(_ manager: UpdateManager,
                                          message: String,
                                          completion: @escaping (Bool) -> Void)
    func updateManager(_ manager: UpdateManager, showInfo title: String, message: String)
}


private extension UpdateManager {

    struct SignatureJob {
        let id: String
        let htmlPath: String
        let name: String
    }

    func run(remoteRequested: Bool) {
        let wasMailRunning = Self.isMailRunning()
        if remoteRequested {
            graphService.stopRemoteUpdateChecker()
        }
        graphService.updateRemoteStatus(status: "updating", remote: false)

        let context: ModelContext
        if let injected = sharedContext {
            context = injected
        } else {
            // Fallback: try to use a default container if available
            do {
                let container = try ModelContainer(for: Signature.self)
                context = ModelContext(container)
            } catch {
                LogManager.shared.log(.critical, "No shared ModelContext set and failed to create fallback container: \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
                finish(success: false, wasMailRunning: wasMailRunning, remoteRequested: remoteRequested)
                return
            }
        }

        let jobs = loadJobs(using: context)
        
        if jobs.isEmpty {
            NotificationManager.notification(title: "No Signatures to update", body: "There are no Signatures available to update.")
            LogManager.shared.log(.info, "No Signatures to update: \(jobs)", fileID: #fileID, function: #function, line: #line)
            finish(success: true, wasMailRunning: wasMailRunning, remoteRequested: remoteRequested)
            return
        }

        if wasMailRunning {
            let msg = remoteRequested
                ? String(localized: "MAIL_CLOSE_REQUIRED_FOR_UPDATE_BY_ORGANISATION")
                : String(localized: "MAIL_CLOSE_REQUIRED_FOR_UPDATE")
            dispatchAskCloseMail(message: msg) { [weak self] allow in
                guard let self else { return }
                if allow {
                    self.processJobs(jobs, wasMailRunning: wasMailRunning, remoteRequested: remoteRequested)
                } else {
                    self.finish(success: false, wasMailRunning: wasMailRunning, remoteRequested: remoteRequested)
                }
            }
        } else {
            processJobs(jobs, wasMailRunning: wasMailRunning, remoteRequested: remoteRequested)
        }
    }

    func processJobs(_ jobs: [SignatureJob],
                     wasMailRunning: Bool,
                     remoteRequested: Bool) {
        var ok = true
        for (index, job) in jobs.enumerated() {
            //updateStatus("Updating: \(job.name)" + (remoteRequested ? " (requested by your organization)" : ""))
            if updateMailSignature(signatureId: job.id, htmlPath: job.htmlPath) == false {
                LogManager.shared.log(.critical, "Job failed for id=\(job.id), name=\"\(job.name)\"", fileID: #fileID, function: #function, line: #line)
                //self.notifyUpdateFailure(body: "Updating signature \(job.name) failed. The last changes were not applied.")
                ok = false
                break
            }
            
            let p = Double(index + 1) / Double(jobs.count)
            setProgress(p)
        }
        
        finish(success: ok, wasMailRunning: wasMailRunning, remoteRequested: remoteRequested)
    }

    func finish(success: Bool, wasMailRunning: Bool, remoteRequested: Bool) {
        graphService.updateRemoteStatus(status: "idle", remote: false)
        if remoteRequested {
            graphService.startRemoteUpdateChecker()
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isRunning = false
            self.lastResultOK = success
            if success {
                let tsFormatter = DateFormatter()
                tsFormatter.dateFormat = "dd.MM.yyyy - HH:mm"
                self.lastUpdateTimestamp = tsFormatter.string(from: Date())
            }
            if !success {
                //self.notifyUpdateFailure(body: remoteRequested ? "Update aborted (requested by your organization)." : "Update aborted.")
            }
            //self.statusText = success
            //    ? (remoteRequested ? "Finished. (requested by your organization)" : "Finished.")
            //    : (remoteRequested ? "Aborted. (requested by your organization)" : "Aborted.")
            self.setProgress(1.0)
            self.updateMenuBarForFinish(success: success)

            if self.showProcessMenuBarLiveActivity {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.liveActivity?.showLiveActivity = false
                    self.menuBarPresenter?.showLiveActivity(false)
                }
            }

            if wasMailRunning {
                Self.reopenMail()
            }
            UserDefaults.standard.set(false, forKey: "app.isRemoteUpdate")
        }
    }
}


private extension UpdateManager {

    func loadJobs(using context: ModelContext) -> [SignatureJob] {
        var list: [SignatureJob] = []
        var missingHTMLNames: [String] = []
        var missingSignatureFiles: [String] = []

        let descriptor = FetchDescriptor<Signature>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )

        let signatures: [Signature]
        do {
            signatures = try context.fetch(descriptor)
        } catch {
            LogManager.shared.log(.critical, "SwiftData fetch failed: \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
            return []
        }

        print("\n========== LOADJOBS START ==========")
        print("SwiftData returned \(signatures.count) signatures\n")

        for sig in signatures {

            print("---- CHECKING SIGNATURE ----")
            print("Name: \(sig.name)")
            print("ID: \(sig.mailSignatureId)")
            print("HTML Path: \(sig.htmlPath)")
            print("StorageType: \(sig.storageType)")
            print("-----------------------------")

            let id = sig.mailSignatureId
            let name = sig.name
            let htmlPath = (sig.htmlPath as NSString).expandingTildeInPath

            guard !id.isEmpty, !name.isEmpty, !htmlPath.isEmpty else {
                print("❌ Skipped: Missing basic data\n")
                continue
            }

            // 🔎 Check HTML
            let htmlExists = FileManager.default.fileExists(atPath: htmlPath)
            print("HTML exists: \(htmlExists)")

            if htmlExists == false {
                missingHTMLNames.append(name)
                print("❌ Missing HTML file -> filtered\n")
                continue
            }

            // 🔎 Check Mail Signature File
            let signaturePath = Self.signatureFilePath(for: id)
            let mailFileExists = FileManager.default.fileExists(atPath: signaturePath)

            print("Mail file path: \(signaturePath)")
            print("Mail file exists: \(mailFileExists)")

            if mailFileExists == false {
                missingSignatureFiles.append(name)
                print("❌ Missing .mailsignature file -> filtered\n")
                continue
            }

            print("✅ Signature added to jobs\n")

            list.append(
                SignatureJob(
                    id: id,
                    htmlPath: htmlPath,
                    name: name
                )
            )
        }

        print("FINAL JOB COUNT: \(list.count)")
        print("====================================\n")

        if !missingHTMLNames.isEmpty {
            print("⚠️ Missing HTML for: \(missingHTMLNames)")
        }

        if !missingSignatureFiles.isEmpty {
            print("⚠️ Missing MAIL FILE for: \(missingSignatureFiles)")
        }

        return list
    }
}


private extension UpdateManager {

    func updateMailSignature(signatureId: String, htmlPath: String) -> Bool {
        _ = Self.runShell("pkill Mail")
        let sigPath = Self.signatureFilePath(for: signatureId)
        _ = Self.runShell("chflags nouchg \(Self.esc(sigPath))")

        let tempPath = "/tmp/\(signatureId).mailsignature"

        do {
            let fm = FileManager.default
            if fm.fileExists(atPath: tempPath) { try fm.removeItem(atPath: tempPath) }
            try fm.copyItem(atPath: sigPath, toPath: tempPath)

            let original = try String(contentsOfFile: tempPath, encoding: .utf8)
            let header = original.components(separatedBy: "\n").prefix(6).joined(separator: "\n")
            let html   = try String(contentsOfFile: htmlPath, encoding: .utf8)
            let final  = "\(header)\n\n\(html)"

            try final.write(toFile: tempPath, atomically: true, encoding: .utf8)

            _ = Self.runShell("chflags nouchg \(Self.esc(tempPath))")
            if fm.fileExists(atPath: sigPath) { try fm.removeItem(atPath: sigPath) }
            try fm.copyItem(atPath: tempPath, toPath: sigPath)
            _ = Self.runShell("chflags uchg \(Self.esc(sigPath))")
            return true
        } catch {
            LogManager.shared.log(.critical, "Update failed for id=\(signatureId): \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
            return false
        }
    }
}


private extension UpdateManager {
    func updateMenuBarForStart() {
        if showProcessMenuBarLiveActivity {
            menuBarPresenter?.showLiveActivity(true)
            menuBarPresenter?.setLiveActivityProgress(0)
            menuBarPresenter?.setIcon(state: MenuBarIconState.updating, toolTip: String(localized: "SIGNATURE_MANAGER_UPDATING_TT"))
        } else {
            menuBarPresenter?.showLiveActivity(false)
            menuBarPresenter?.setIcon(state: MenuBarIconState.updating, toolTip: String(localized: "SIGNATURE_MANAGER_UPDATING_TT"))
        }
    }

    func updateMenuBarForProgress(_ p: Double) {
        if showProcessMenuBarLiveActivity {
            menuBarPresenter?.setLiveActivityProgress(p)
        }
    }

    func updateMenuBarForFinish(success: Bool) {
        if showProcessMenuBarLiveActivity {
            menuBarPresenter?.setLiveActivityProgress(1.0)
        }
        let tooltip = success
            ? (lastUpdateTimestamp.isEmpty ? "Signature Manager: Up to date" : "Signature Manager: Up to date (" + lastUpdateTimestamp + ")")
            : "Signature Manager: Update aborted"
        menuBarPresenter?.setIcon(state: success ? MenuBarIconState.ok : MenuBarIconState.error, toolTip: tooltip)
    }
}


private extension UpdateManager {

    /*func updateStatus(_ text: String) {
        DispatchQueue.main.async {
            self.statusText = text
            //Logger.shared.log(position: "UPDATE", type: "INFO", content: "Status: \(text)")
        }
    }*/

    func setProgress(_ p: Double) {
        let clamped = max(0, min(1, p))
        DispatchQueue.main.async {
            self.progress = clamped
            self.liveActivity?.progress = clamped
            self.updateMenuBarForProgress(clamped)
        }
    }
}


private extension UpdateManager {
    
    static func signatureFilePath(for id: String) -> String {
        let path = "~/Library/Mail/V10/MailData/Signatures/\(id).mailsignature"
        return (path as NSString).expandingTildeInPath
    }
    
    static func isMailRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.apple.mail" }
    }
    
    static func reopenMail() {
        let script = """
        tell application "Mail"
            activate
        end tell
        """
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }
    
    static func esc(_ path: String) -> String {
        "\"\(path.replacingOccurrences(of: "\"", with: "\\\""))\""
    }
    
    @discardableResult
    static func runShell(_ command: String) -> Bool {
        let p = Process()
        p.launchPath = "/bin/zsh"
        p.arguments = ["-c", command]
        
        let out = Pipe(); let err = Pipe()
        p.standardOutput = out; p.standardError = err
        p.launch(); p.waitUntilExit()
        
        let errData = err.fileHandleForReading.readDataToEndOfFile()
        let errStr = String(data: errData, encoding: .utf8) ?? ""
        _ = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    
        if !errStr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            LogManager.shared.log(.critical, "stderr: \(errStr)", fileID: #fileID, function: #function, line: #line)
            return false
        }
        return true
    }
    
    func dispatchAskCloseMail(message: String, completion: @escaping (Bool)->Void) {
        DispatchQueue.main.async {
            if let delegate = self.delegate {
                delegate.updateManagerRequestsClosingMail(self, message: message, completion: completion)
            } else {
                let alert = NSAlert()
                alert.messageText = "Update Signatures"
                alert.informativeText = message
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Continue")
                alert.addButton(withTitle: "Cancel")
                let allow = (alert.runModal() == .alertFirstButtonReturn)
                completion(allow)
            }
        }
    }

    func notifyUpdateFailure(title: String = "Signature Manager", body: String) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                LogManager.shared.log(.warning, "Notification not authorized; skipping failure notification", fileID: #fileID, function: #function, line: #line)
                return
            }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    LogManager.shared.log(.critical, "Failed to schedule failure notification: \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
                }
            }
        }
    }
}

