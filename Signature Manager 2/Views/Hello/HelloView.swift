//
//  HelloView.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 23.08.25.
//

import SwiftUI
import UserNotifications


fileprivate enum PermissionState: Equatable {
    case idle, working, granted, denied
}

struct HelloView: View {
    @State private var step: Int = 0
    
    @State private var diskState: PermissionState = .idle
    @State private var notifState: PermissionState = .idle
    
    @State private var showConnectSheet = false
    @State private var showMigrationSheet = false
    @State private var settingsWaitTask: Task<Void, Never>?
    
    @AppStorage("rights.fullDiskAccess") private var rightsFullDiskAccess: Bool = false
    @AppStorage("rights.showNotifications") private var rightsShowNotifications: Bool = false
    @AppStorage("graph.clientId") private var clientId: String = ""
    @AppStorage("graph.tenantId") private var tenantId: String = ""
    @AppStorage("graph.clientSecret") private var clientSecret: String = ""
    @AppStorage("graph.licensedForName") private var licensedForName: String = ""
    @AppStorage("app.showProcessMenuBarLiveActivity") private var showLiveActivity: Bool = false
    @AppStorage("app.showProcessByUpdatingSignatures") private var showprocess: Bool = false
    @AppStorage("app.showHelloView") private var showHelloView: Bool = false
    @AppStorage("app.selectedOption") private var selectedOption: Int = 0
        
    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "App"
    }
    
    private var canFinish: Bool {
        rightsFullDiskAccess && rightsShowNotifications
        && !clientId.isEmpty && !tenantId.isEmpty && !clientSecret.isEmpty && !licensedForName.isEmpty
    }
    
    var body: some View {
        ZStack {
            switch step {
            case 0: welcomeView.id(0)
            case 1: permissionsView.id(1)
            case 2: appearanceView.id(2)
            case 3: almostDoneView.id(3)
            default: almostDoneView.id(4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onDisappear {
            settingsWaitTask?.cancel()
        }
        .sheet(isPresented: $showConnectSheet) {
            RemoteConfigSheetView {
                // Parent controls: close sheet and conditionally show migration
                showConnectSheet = false
                if MigrationService.hasLegacyVersion {
                    showMigrationSheet = true
                } else {
                    completeCheckout()
                }
            }
        }
        .sheet(isPresented: $showMigrationSheet, onDismiss: {
            // Continue normal flow after migration sheet is dismissed
            completeCheckout()
        }) {
            MigrationSheetView {
                // When migration completes, dismiss the sheet
                showMigrationSheet = false
            }
        }
    }
    
    // MARK: - Welcome View
    private var welcomeView: some View {
        VStack(spacing: 34) {
            Spacer(minLength: 30)
            Text("SIGNATURE_MANAGER")
                .font(.system(size: 48, weight: .semibold))
                .padding(.top, 14)
            
            HStack {
                Image(systemName: "sparkles.2")
                    .imageScale(.large)
                (
                    Text(MigrationService.hasLegacyVersion ? "UPDATE_COMPLETED" : "WELCOME")
                    + Text(" - ")
                    + Text("LETS_GET_STARTED")
                )
                .font(.title2)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            }
            
            AnimatedAppIcon()
            
            Button(action: { step = 1 }) {
                if #available(macOS 26.0, *) {
                    Text("GET_STARTED")
                        .font(.title3.bold())
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.accentColor.opacity(0.95)))
                        .foregroundStyle(.white)
                        .shadow(radius: 8, y: 4)
                        .glassEffect()
                } else {
                    Text("GET_STARTED")
                        .font(.title3.bold())
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.accentColor.opacity(0.95)))
                        .foregroundStyle(.white)
                        .shadow(radius: 8, y: 4)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            Spacer(minLength: 30)
        }
        .padding()
    }
    
    // MARK: - Permissions View
    private var permissionsView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 22)
            
            Image(systemName: "shield.righthalf.filled")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
            
            Text("PERMISSION_REQUEST")
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
            
            VStack(spacing: 14) {
                permissionRow(
                    icon: "lock.shield",
                    title: String(localized: "FULL_DISK_ACCESS"),
                    subtitle: String(localized: "FULL_DISK_ACCESS_DESCRIPTION"),
                    state: diskState
                )
                permissionRow(
                    icon: "bell.badge.fill",
                    title: String(localized: "NOTIFICATIONS"),
                    subtitle: String(localized: "NOTIFICATIONS_DESCRIPTION"),
                    state: notifState
                )
            }
            .frame(maxWidth: 520)
            
            Spacer(minLength: 10)
            
            HStack(spacing: 12) {
                Button {
                    startPermissionsFlow()
                } label: {
                    if #available(macOS 26.0, *) {
                        Text("ASK_ME")
                            .font(.title3.bold())
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.accentColor.opacity(0.95)))
                            .foregroundStyle(.white)
                            .shadow(radius: 8, y: 4)
                            .glassEffect()
                    } else {
                        Text("ASK_ME")
                            .font(.title3.bold())
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.accentColor.opacity(0.95)))
                            .foregroundStyle(.white)
                            .shadow(radius: 8, y: 4)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
            
            Spacer(minLength: 24)
        }
        .padding()
    }
    
    private var didStartFlow: Bool {
        diskState != .idle || notifState != .idle
    }
    
    // MARK: - Appearance (placeholder)
    private var appearanceView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 22)
            Image(systemName: "swatchpalette")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
            Text("LETS_CUSTOMIZE_OUR_EXPERIENCE")
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            GroupBox {
                VStack(spacing: 16) {
                    HStack(spacing: 40) {
                        optionCard(index: 0)
                        optionCard(index: 1)
                    }
                }
                .padding()
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.bottom)
            
            HStack(spacing: 12) {
                Button {
                    let willSetShowLiveActivity = (selectedOption == 0)
                    
                    // Persist
                    showLiveActivity = willSetShowLiveActivity
                    showprocess = true
                    step = 3
                } label: {
                    if #available(macOS 26.0, *) {
                        Text("CONTINUE")
                            .font(.title3.bold())
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.accentColor.opacity(0.95)))
                            .foregroundStyle(.white)
                            .shadow(radius: 8, y: 4)
                            .glassEffect()
                    } else {
                        Text("CONTINUE")
                            .font(.title3.bold())
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.accentColor.opacity(0.95)))
                            .foregroundStyle(.white)
                            .shadow(radius: 8, y: 4)
                    }
                }
                .buttonStyle(.plain)
            }
            
            Spacer(minLength: 22)
        }
        .padding()
    }
    
    // MARK: - Almost Done View
    private var almostDoneView: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                AIGradientTextWidget(
                    animate: true,
                    text: String(localized: "ALMOST_DONE"),
                    fontWeight: .bold,
                    fontSize: 70,
                    availableWidth: geometry.size.width * 0.8
                )
                .frame(maxWidth: .infinity)
                Spacer()
                Button(action: {
                    showHelloView = false
                    closeKeyWindow()
                }) {
                    if #available(macOS 26.0, *) {
                        Text("FINISH")
                            .font(.title3.bold())
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.accentColor.opacity(0.95)))
                            .foregroundStyle(.white)
                            .shadow(radius: 8, y: 4)
                            .glassEffect()
                    } else {
                        Text("FINISH")
                            .font(.title3.bold())
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.accentColor.opacity(0.95)))
                            .foregroundStyle(.white)
                            .shadow(radius: 8, y: 4)
                    }
                }
                .buttonStyle(.plain)
                .padding(.bottom, 70)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private func optionCard(index: Int) -> some View {
        VStack {
            Button(action: {
                selectedOption = index
                showLiveActivity = (index == 0)
            }) {
                let cornerRadius: CGFloat = 12
                let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                
                Group {
                    if index == 0 {
                        Image("example.menubar.pill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image("example.menubar.icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .frame(width: 350, height: 250)
                .clipShape(shape)
                .overlay(
                    shape
                        .stroke(selectedOption == index ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: selectedOption == index ? 4 : 1)
                )
            }
            .buttonStyle(.plain)
            HStack(spacing: 8) {
                Text("OPTION \(index + 1)")
                    .font(.caption)
                if index == 0 {
                    Text("NEW")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Color.pink.opacity(0.15))
                        )
                        .overlay(
                            Capsule().stroke(Color.pink.opacity(0.6), lineWidth: 1)
                        )
                        .foregroundStyle(Color.pink)
                }
            }
            .padding(.top, 4)
        }
    }
    
    private func permissionRow(icon: String, title: String, subtitle: String, state: PermissionState) -> some View {
        let base = HStack(spacing: 16) {
            Image(systemName: icon)
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            trailingFor(state)
        }
        .padding(20)

        if #available(macOS 26.0, *) {
            return AnyView(
                base
                    .glassEffect()
                    .frame(maxWidth: 520)
            )
        } else {
            return AnyView(
                base
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .frame(maxWidth: 520)
            )
        }
    }
    
    private func trailingFor(_ state: PermissionState) -> some View {
        switch state {
        case .idle:
            return AnyView(Image(systemName: "circle").imageScale(.large).foregroundStyle(.tertiary))
        case .working:
            return AnyView(ProgressView().scaleEffect(0.5))
        case .granted:
            return AnyView(Image(systemName: "checkmark.circle.fill").imageScale(.large).foregroundStyle(.green))
        case .denied:
            return AnyView(Image(systemName: "xmark.octagon.fill").imageScale(.large).foregroundStyle(.red))
        }
    }
    
    private func startPermissionsFlow() {
        if diskState == .idle || diskState == .denied {
            askFullDiskAccess()
            return
        }
        if notifState == .idle || notifState == .denied {
            askNotifications()
            return
        }
        if !showConnectSheet {
            connectToServer()
        }
    }
    
    private func hasFullDiskAccess() -> Bool {
        let fm = FileManager.default
        let base = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Mail").path
        do {
            _ = try fm.contentsOfDirectory(atPath: base)
            return true
        } catch { return false }
    }
    
    private func askFullDiskAccess() {
        diskState = .working
        NSApp.activate(ignoringOtherApps: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if self.hasFullDiskAccess() {
                self.rightsFullDiskAccess = true
                self.diskState = .granted
                self.askNotifications()
            } else {
                self.openFullDiskAccessSettingsAndWait()
            }
        }
    }
    
    private func openFullDiskAccessSettingsAndWait(timeoutSeconds: Int = 120) {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        let opened = NSWorkspace.shared.open(url)
        if !opened {
            Logger.shared.log(position: "HelloView.openFullDiskAccessSettingsAndWait", type: "CRITICAL", content: "Failed to open Full Disk Access settings URL")
        }
        NSApp.activate(ignoringOtherApps: true)
        
        settingsWaitTask?.cancel()
        settingsWaitTask = Task { [timeoutSeconds] in
            let start = Date()
            while !Task.isCancelled {
                if hasFullDiskAccess() {
                    await MainActor.run {
                        rightsFullDiskAccess = true
                        diskState = .granted
                        askNotifications()
                    }
                    return
                }
                if Date().timeIntervalSince(start) > Double(timeoutSeconds) {
                    Logger.shared.log(position: "HelloView.openFullDiskAccessSettingsAndWait", type: "WARNING", content: "Full Disk Access not granted within timeout (\(timeoutSeconds)s)")
                    await MainActor.run {
                        rightsFullDiskAccess = false
                        diskState = .denied
                    }
                    return
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
    
    private func askNotifications() {
        notifState = .working
        NSApp.activate(ignoringOtherApps: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async {
                    if !granted {
                        Logger.shared.log(position: "HelloView.askNotifications", type: "WARNING", content: "Notification permission denied by user")
                    }
                    rightsShowNotifications = granted
                    notifState = granted ? .granted : .denied
                    if granted { connectToServer() }
                }
            }
        }
    }
    
    private func connectToServer() {
        showConnectSheet = true
    }
    
    private func completeCheckout() {
        if step < 2 {
            step = 2
        }
    }
    
    private func closeKeyWindow() {
        NSApp.keyWindow?.close()
    }
}


#Preview {
    HelloView()
}

