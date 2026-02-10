//
//  MigrationService.swift
//  Signature Manager
//
//  Created by Marc Büttner on 19.09.25.
//

//
//  MigrationService.swift
//  Signature Manager
//
//  Created by Marc Büttner on 19.09.25.
//

import SwiftUI

class MigrationService {

    static let legacySuite = "marcbuetti.Signature-Manager-2"

    static var hasLegacyVersion: Bool {
        guard let defaults = UserDefaults(suiteName: legacySuite) else {
            Logger.shared.log(
                position: "MigrationService.hasLegacyVersion",
                type: "CRITICAL",
                content: "Legacy UserDefaults suite not found: \(legacySuite)"
            )
            return false
        }
        return defaults.object(forKey: "app.signatures.count") != nil
    }

    static func getLegacyValue(forKey key: String) -> Any? {
        guard let legacyDefaults = UserDefaults(suiteName: legacySuite) else {
            Logger.shared.log(
                position: "MigrationService.getLegacyValue",
                type: "CRITICAL",
                content: "Legacy UserDefaults suite not found: \(legacySuite)"
            )
            return nil
        }

        let value = legacyDefaults.object(forKey: key)
        if value == nil {
            Logger.shared.log(
                position: "MigrationService.getLegacyValue",
                type: "WARNING",
                content: "No legacy value for key: \(key)"
            )
        }
        return value
    }
}

