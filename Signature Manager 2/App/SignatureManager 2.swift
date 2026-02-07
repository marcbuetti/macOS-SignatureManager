//
//  Signature Manager 2.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 05.09.25.
//

import SwiftUI
import SwiftData
import LocalAuthentication
import Sparkle
import UserNotifications



@main
struct SignatureManager2: App {
    
    @StateObject private var menuBarLiveActivity = MenuBarLiveActivity()
    @StateObject private var menuBarController: MenuBarController
    
    @AppStorage("app.showHelloView") var showHelloView: Bool = false
    @AppStorage("app.updateSignaturesWithStart") var updateSignaturesWithStart: Bool = false
    @AppStorage("rights.fullDiskAccess") private var rightsFullDiskAccess: Bool = false
    @AppStorage("rights.showNotifications") private var rightsShowNotifications: Bool = false
    @AppStorage("graph.clientId") private var clientId: String = ""
    @AppStorage("graph.tenantId") private var tenantId: String = ""
    @AppStorage("graph.clientSecret") private var clientSecret: String = ""
    
    private var launchBehavior: SceneLaunchBehavior = .suppressed
    private let modelContainer: ModelContainer = {
            do {
                return try ModelContainer(for: Signature.self)
            } catch {
                fatalError("Failed to create SwiftData container: \(error)")
            }
        }()
    
    init() {
        let state = MenuBarLiveActivity()
        _menuBarLiveActivity = StateObject(wrappedValue: state)
        _menuBarController = StateObject(wrappedValue: MenuBarController(menuBarLiveActivity: state))
        
        NotificationCenter.default.addObserver(forName: .ShowAppInDock, object: nil, queue: .main) { _ in
            NSApplication.shared.setActivationPolicy(.regular)
        }
        NotificationCenter.default.addObserver(forName: .HideAppFromDock, object: nil, queue: .main) { _ in
            NSApplication.shared.setActivationPolicy(.accessory)
        }
        NotificationCenter.default.addObserver(forName: .BringWindowToFront, object: nil, queue: .main) { _ in
            if let win = NSApplication.shared.windows.first(where: { $0.isVisible && ($0.title.contains("content") || $0.identifier?.rawValue == "content") }) {
                win.orderFrontRegardless()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        
        ///MAIN
        if rightsFullDiskAccess || !rightsShowNotifications || clientId.isEmpty || tenantId.isEmpty || clientSecret.isEmpty {
            showHelloView = true ///
            launchBehavior = .automatic
        } else {
            showHelloView = false
            let graphService = GraphService()
            graphService.checkConnection(debug: true)
            graphService.reigsterRemoteDevice()
            graphService.updateRemoteStatus(status: "idle", remote: false)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [self] in
                if updateSignaturesWithStart {
                    UpdateManager.shared.start(remoteRequested: false)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                graphService.startRemoteUpdateChecker()
            }
        }
        
        do { try Logger.shared.rotateLogFileIfNeeded()
        } catch {
            Logger.shared.log(position: "APP", type: "CRITICAL", content: "Could not rotate log file: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup(id: "content") {
            if (showHelloView) {
                HelloView()
                    .background(DockWatcher())
                    .frame(minWidth: 1200, minHeight: 900)
            } else {
                ContentView()
                    .background(DockWatcher())
                    .environmentObject(menuBarLiveActivity)
                    .frame(minWidth: 1200, minHeight: 650)
            }
        }
        .modelContainer(modelContainer)
        .defaultLaunchBehavior(launchBehavior)
        .onChange(of: showHelloView) { oldValue, newValue in
            if newValue == false {
                NotificationCenter.default.post(name: .HelloViewDidContinue, object: nil)
            }
        }
     }
 }


extension Notification.Name {
    static let ShowAppInDock = Notification.Name("ShowAppInDockNotification")
    static let HideAppFromDock = Notification.Name("HideAppFromDockNotification")
    static let BringWindowToFront = Notification.Name("BringWindowToFrontNotification")
}

