//
//  LaunchAtLoginManager.swift
//  Signature Manager
//
//  Created by Marc Büttner on 03.09.25.
//

import ServiceManagement


class LaunchAtLoginManager: ObservableObject {
    @Published var isEnabled = false
    
    init() {
        Task {
            await self.updateStatus()
        }
    }
    
    @MainActor
    func updateStatus() async {
        if SMAppService.mainApp.status == .enabled {
            isEnabled = true
        } else {
            isEnabled = false
        }
    }
    
    @MainActor
    func toggleLaunchAtLogin(_ newValue: Bool) {
        Task {
            if newValue {
                do {
                    try SMAppService.mainApp.register()
                } catch {
                    LogManager.shared.log(.critical, "Failed to register launch at login: \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
                }
            } else {
                do {
                    try await SMAppService.mainApp.unregister()
                } catch {
                    LogManager.shared.log(.critical, "Failed to unregister launch at login: \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
                }
            }
            await self.updateStatus()
        }
    }
}

