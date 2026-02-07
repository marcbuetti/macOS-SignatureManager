//
//  SettingsView.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 19.08.25.
//

import SwiftUI
import Sparkle


private struct Surface<Content: View>: View {
    let corner: CGFloat
    @ViewBuilder let content: Content

    init(corner: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.corner = corner
        self.content = content()
    }

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(.thickMaterial) // wirkt im Dark Mode wie im Screenshot
            .overlay(content.padding(14))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(.quaternary, lineWidth: 1)
            )
            .shadow(radius: 1, y: 1)
    }
}


struct AboutView: View {
    private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    @State private var autoCheck = true
    @State private var autoDownload = false
    @State private var lastChecked: Date? = .now.addingTimeInterval(TimeInterval(-60 * 60 * 24))
    @State private var showLegal = false

    private var versionString: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "Version \(v) (\(b))"
    }
    private var copyrightString: String {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
        ?? "Copyright © \(Calendar.current.component(.year, from: .now)) Marc Büttner"
    }

    private let hPad: CGFloat = 16
    private let corner: CGFloat = 20
    var body: some View {
        VStack(spacing: 14) {
            Surface(corner: corner) {
                VStack(spacing: 20) {
                    header
                    toggles
                    footer
                }
            }
            .padding(.horizontal, hPad)
            .padding(.top, 25)

            Surface(corner: corner) {
                bottomBar
                    .font(.callout)
            }
            .frame(height: 46)
            .padding(.horizontal, hPad)
            .padding(.bottom, 12)

            Spacer(minLength: 0)
        }
        .navigationDestination(isPresented: $showLegal) {
            LegalView()
        }
        .navigationTitle("ABOUT")
        .onAppear {
            let updater = updaterController.updater
            autoCheck = updater.automaticallyChecksForUpdates
            autoDownload = updater.automaticallyDownloadsUpdates
        }
        .onChange(of: autoCheck) { _, newValue in
            updaterController.updater.automaticallyChecksForUpdates = newValue
        }
        .onChange(of: autoDownload) { _, newValue in
            updaterController.updater.automaticallyDownloadsUpdates = newValue
        }
    }

    private var header: some View {
        HStack(spacing: 20) {
            AnimatedAppIcon()

            VStack(alignment: .leading, spacing: 4) {
                Text("SIGNATURE_MANAGER")
                    .font(.system(size: 48, weight: .semibold))
                Text(versionString)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(copyrightString)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            Spacer()
        }
    }

    private var toggles: some View {
        VStack(spacing: 0) {
            toggleRow(String(localized: "AUTOMATIC_CHECK_FOR_SOFTWAREUPDATES"), binding: $autoCheck)
            toggleRow(String(localized: "AUTOMATIC_DOWNLOAD_SOFTWAREUPDATES"), binding: $autoDownload)
        }
        .toggleStyle(.switch)
        .tint(.accentColor)
    }

    private func toggleRow(_ title: String, binding: Binding<Bool>) -> some View {
        HStack {
            Text(title)
            Spacer()
            Toggle("", isOn: binding).labelsHidden()
        }
        .controlSize(.regular)
        .padding(.vertical, 6)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button("CHECK_FOR_SOFTWAREUPDATES") {
                updaterController.updater.checkForUpdates()
                lastChecked = .now
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Spacer()

            HStack(spacing: 6) {
                Text("LAST_CHECKED:")
                    .foregroundStyle(.secondary)
                Text(lastChecked.map(formatDate) ?? "—")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.callout)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 28) {
            pill(String(localized: "QUIT_SIGNATURE_MANAGER")) { NSApp.terminate(nil) }
            Spacer(minLength: 0)

            pill(String(localized: "LEGAL")) { showLegal = true }

            pill(String(localized: "SUPPORT")) { open("https://support.mibue.net/signature-manager-2") }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
    }

    private func pill(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .padding(.vertical, 6)
    }

    private func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = .current
        df.dateStyle = .medium
        df.timeStyle = .medium
        return df.string(from: date)
    }
}


#Preview {
    AboutView()
        .frame(width: 820, height: 600)
}
