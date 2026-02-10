//
//  MenuBarStatus.swift
//  Signature Manager
//
//  Created by Marc Büttner on 08.09.25.
//


public enum MenuBarStatus: Equatable {
    case ok
    case updating
    case error

    var iconName: String {
        switch self {
        case .ok:       return "custom.signature.badge.checkmark"
        case .updating: return "custom.signature.badge.arrow.down"
        case .error:    return "custom.signature.trianglebadge.exclamationmark"
        }
    }
    var tooltip: String {
        switch self {
        case .ok:       return String(localized: "SIGNATURE_MANAGER_UP_TO_DATE_TT")
        case .updating: return String(localized: "SIGNATURE_MANAGER_UPDATING_TT")
        case .error:    return String(localized: "SIGNATURE_MANAGER_UPDATE_ABORTED_TT") 
        }
    }
    var isTemplate: Bool {
        switch self {
        case .ok:       return true
        case .updating: return true
        case .error:    return true
        }
    }
}


