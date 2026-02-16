//
//  RemoteConfigSheetView.swift
//  Signature Manager
//
//  Created by Marc Büttner on 17.09.25.
//

//
//  MigrationSheetView.swift
//  Signature Manager
//
//  Created by Marc Büttner on 17.09.25.
//

import SwiftUI
import SwiftData

private enum AutoPhase: Equatable {
    case idle
    case migratingSettings
    case migratingCloudSettings
    case migratingSignatures
    case verifying
    case completed
    case failed(String)
}

struct MigrationSheetView: View {
    var onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var phase: AutoPhase = .idle

    var body: some View {
        VStack(spacing: 18) {
            Image("custom.app.shadow.circle.dotted")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90)

            Text("MIGRATION")
                .font(.title2.weight(.semibold))

            Text(statusText)
                .foregroundStyle(phaseIsError ? .red : .secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            ProgressView().scaleEffect(0.5)

            if case .failed = phase {
                HStack(spacing: 10) {
                    Button("CLOSE") { dismiss() }
                    Button("RETRY") { startMigration() }
                        .keyboardShortcut(.defaultAction)
                }
                .padding(.top, 6)
            }
        }
        .frame(minWidth: 420, minHeight: 240)
        .padding()
        .onChange(of: phase) { _, newValue in
            if case .completed = newValue {
                onComplete()
            }
        }
        .onAppear { startMigration() }
    }

    // MARK: - UI helpers

    private var phaseIsError: Bool {
        if case .failed = phase { return true }
        return false
    }

    private var statusText: String {
        switch phase {
        case .idle: return String(localized: "PREPARING")
        case .migratingSettings: return String(localized: "MIGRATING_SETTINGS")
        case .migratingCloudSettings: return String(localized: "MIGRATING_CLOUD_CONNECTIONS")
        case .migratingSignatures: return String(localized: "MIGRATING_SIGNATURES")
        case .verifying: return String(localized: "VERIFYING")
        case .completed: return String(localized: "COMPLETED")
        case .failed(let msg): return String(localized: "ERROR_OCCURRED \(msg)")
        }
    }

    // MARK: - Migration

    private func startMigration() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            migrateSettings()
            migrateSignatures()
        }
    }

    private func migrateSettings() {
        phase = .migratingSettings

        // Sparkle + LaunchAtLogin bleiben bewusst UserDefaults
        if let oldDefaults = UserDefaults(suiteName: "com.example.OldSignatureManager") {
            if let autoCheck = oldDefaults.object(forKey: "SUEnableAutomaticChecks") as? Bool {
                UserDefaults.standard.set(autoCheck, forKey: "app.sparkle.enableAutomaticChecks")
            }
            if let autoDownload = oldDefaults.object(forKey: "SUAutomaticallyUpdate") as? Bool {
                UserDefaults.standard.set(autoDownload, forKey: "app.sparkle.enableAutomaticDownloads")
            }
        }

        //let manager = LaunchAtLoginManager()
        /*manager.toggleLaunchAtLogin(
            LegacyStartupControlHelper.getAppStartupState() == "true"
        )*/
    }

    private func migrateSignatures() {
        phase = .migratingSignatures

        guard
            let total = MigrationService.getLegacyValue(forKey: "app.signatures.count") as? Int,
            total > 0
        else {
            Logger.shared.log(
                position: "MigrationSheetView.migrateSignatures",
                type: "WARNING",
                content: "No legacy signatures found"
            )
            finishMigration()
            return
        }

        let home = FileManager.default.homeDirectoryForCurrentUser
        let cloudBase = home
            .appendingPathComponent("Library/Application Support/Signature Manager/onlineSignatures")
            .path

        for i in 1...total {
            guard
                let id = MigrationService.getLegacyValue(forKey: "signature\(i)ID") as? String,
                let name = MigrationService.getLegacyValue(forKey: "signature\(i)Name") as? String
            else {
                Logger.shared.log(
                    position: "MigrationSheetView.migrateSignatures",
                    type: "WARNING",
                    content: "Skipping legacy signature #\(i) (missing id or name)"
                )
                continue
            }

            let htmlPath = MigrationService.getLegacyValue(forKey: "signature\(i)HTML") as? String ?? ""
            let m365File = MigrationService.getLegacyValue(forKey: "m365Signature\(i)FileName") as? String

            let lastUpdated: Date = {
                guard
                    let raw = MigrationService.getLegacyValue(forKey: "signature\(i)LastUpdated") as? String
                else { return .now }

                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return f.date(from: raw) ?? .now
            }()

            let storageType: StorageType =
                htmlPath.hasPrefix(cloudBase) ? .cloudM365 : .local

            let signature = Signature(
                mailSignatureId: id,
                name: name,
                htmlPath: htmlPath,
                storageType: storageType,
                m365FileName: m365File,
                lastUpdated: lastUpdated
            )

            context.insert(signature)
        }

        finishMigration()
    }

    private func finishMigration() {
        phase = .verifying

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            phase = .completed
        }
    }
}
