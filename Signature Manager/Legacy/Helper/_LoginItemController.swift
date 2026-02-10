//
//  LoginItemError.swift
//  Signature Manager
//
//  Created by Marc Büttner on 02.09.25.
//


// LoginItemController.swift (im Haupt-App-Target)
import Foundation
import ServiceManagement

enum LoginItemError: Error {
    case unsupported
}

final class LoginItemController {
    // Passe auf deinen Helper-Bundle-Identifier an!
    static let helperBundleID = "net.mkjc.SignatureManager2.LoginItem"

    static func isEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            let service = SMAppService.loginItem(identifier: helperBundleID)
            return service.status == .enabled
        } else {
            // Kein zuverlässiger Query auf alten Systemen – ggf. in UserDefaults spiegeln.
            return UserDefaults.standard.bool(forKey: "launchAtLoginCache")
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        if #available(macOS 13.0, *) {
            let service = SMAppService.loginItem(identifier: helperBundleID)
            if enabled {
                try service.register()     // zeigt ggf. System-Dialog
            } else {
                try service.unregister()
            }
        } else {
            // Fallback für macOS 12 und älter (deprecated API):
            // import ServiceManagement (alt) und:
            // SMLoginItemSetEnabled(helperBundleID as CFString, enabled)
            // Achtung: Erfordert ein altes Helper-Bundle-Setup.
            throw LoginItemError.unsupported
        }

        // Optional Cache (nur UI-Optimismus für <13 oder bis Status aktualisiert ist)
        UserDefaults.standard.set(enabled, forKey: "launchAtLoginCache")
    }
}
