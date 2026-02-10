//
//  AboutView.swift
//  Signature Manager
//
//  Created by Marc Büttner on 19.08.25.
//

import SwiftUI
import Sparkle


struct AboutView: View {
    private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    @State private var autoCheck = true
    @State private var autoDownload = false
    @State private var lastChecked: Date? = .now.addingTimeInterval(TimeInterval(-60 * 60 * 24))
    @State private var showLegal = false
    @State private var showWhatsNewSheet = false

    private var versionString: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "Version \(v) (\(b))"
    }
    private var copyrightString: String {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
        ?? "Copyright © \(Calendar.current.component(.year, from: .now)) MIBUE.NET · Marc Büttner"
    }

    private let hPad: CGFloat = 16
    private let corner: CGFloat = 20
    
    
    var body: some View {
        VStack(spacing: 0) {

            ScrollView {
                VStack(spacing: 16) {
                    topCard
                }
                .padding(.top, 24)
                .padding(.horizontal, 16)
            }

            bottomBar
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
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
        .sheet(isPresented: $showWhatsNewSheet)
        {
            WhatsNewSheet(onComplete: {})
                .frame(minWidth: 300, minHeight: 600)
        }
    }
    
    private var topCard: some View {
        GroupBox {
            VStack(spacing: 14) {

                // 🔝 Header bleibt frei
                HStack(alignment: .center, spacing: 12) {
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
                    .padding(8)

                    Spacer()
                }

                VStack(spacing: 2) {

                    HStack {
                        Text("AUTOMATIC_CHECK_FOR_SOFTWAREUPDATES")
                        Spacer()
                        Toggle("", isOn: $autoCheck)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                    .controlSize(.regular)
                    .padding(.vertical, 4)

                    HStack {
                        Text("AUTOMATIC_DOWNLOAD_SOFTWAREUPDATES")
                        Spacer()
                        Toggle("", isOn: $autoDownload)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                    .controlSize(.regular)
                    .padding(.vertical, 4)

                    // ⬇️ VISUELLE TRENNUNG
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
                    .padding(.top, 18)
                    .padding(.vertical, 6)
                    
                    HStack {
                        Button("WHATS_IS_NEW") {
                            showWhatsNewSheet.toggle()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                        Spacer()
                    }
                }
                .padding(.horizontal, 5)
                .padding(.top, 4)

                Spacer(minLength: 0)
            }
            
            Spacer(minLength: 70)
        }
        .cardStyle()
    }
    

    
    private var bottomBar: some View {
        GroupBox {
            HStack {
                Button("QUIT_SIGNATURE_MANAGER") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)

                Spacer()

                Button("LEGAL") { showLegal = true }
                    .buttonStyle(.plain)

                Button("SUPPORT") {
                    open("https://support.mibue.net/signature-manager")
                }
                .buttonStyle(.plain)
            }
            .padding(8)
        }
        .cardStyle()
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


private extension View {
    func cardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
            )
    }
}


#Preview {
    AboutView()
        //.frame(minWidth: 1200, minHeight: 665)
}

