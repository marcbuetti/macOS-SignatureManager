//
//  SecurityManager.swift
//  Signature Manager
//
//  Created by Marc Büttner on 07.02.26.
//

import LocalAuthentication
import AppKit

class SecurityManager {
    
    static func hasFullDiskAccess() -> Bool {
        let fileManager = FileManager.default
        let userDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        let testPath = "\(userDirectory)/Library/Mail/V10/MailData/Signatures"
        let readable = fileManager.isReadableFile(atPath: testPath)
        if !readable {
            LogManager.shared.log(.warning, "No read access to: \(testPath)", fileID: #fileID, function: #function, line: #line)
        }
        return readable
    }
        
    static func authenticateUser(
            reason: String,
            completion: @escaping (Bool) -> Void
        ) {
            let context = LAContext()
            var error: NSError?

            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                context.evaluatePolicy(
                    .deviceOwnerAuthentication,
                    localizedReason: reason
                ) { success, authError in
                    DispatchQueue.main.async {
                        if !success {
                            if let authError {
                                LogManager.shared.log(.warning, authError.localizedDescription, fileID: #fileID, function: #function, line: #line)
                            }

                            showAlert(
                                titleKey: "AUTHENTICATION_FAILED",
                                messageKey: "AUTHENTICATION_FAILED_RETRY"
                            )
                        }

                        completion(success)
                    }
                }
            } else {
                if let error {
                    LogManager.shared.log(.critical, error.localizedDescription, fileID: #fileID, function: #function, line: #line)
                }

                DispatchQueue.main.async {
                    showAlert(
                        titleKey: "AUTHENTICATION_NOT_AVAILABLE",
                        messageKey: "TOUCH_ID_OR_PASSWORD_REQUIRED"
                    )
                    completion(false)
                }
            }
        }

        // MARK: - Admin Authentication (macOS Authorization Services)

        static func authenticateAdmin(
            reason: String,
            completion: @escaping (Bool) -> Void
        ) {
            var authRef: AuthorizationRef?
            
            let status = AuthorizationCreate(
                nil,
                nil,
                [.interactionAllowed, .extendRights],
                &authRef
            )
            
            guard status == errAuthorizationSuccess, let authRef else {
                DispatchQueue.main.async {
                    showAlert(
                        titleKey: "ADMIN_AUTH_FAILED",
                        messageKey: "ADMIN_RIGHTS_REQUIRED"
                    )
                    completion(false)
                }
                return
            }
            
            let result: OSStatus = {
                let rightName = kAuthorizationRightExecute

                return rightName.withCString { cString in
                    
                    var items = [AuthorizationItem(
                        name: cString,
                        valueLength: 0,
                        value: nil,
                        flags: 0
                    )]

                    return items.withUnsafeMutableBufferPointer { buffer in
                        var rights = AuthorizationRights(
                            count: UInt32(buffer.count),
                            items: buffer.baseAddress
                        )

                        let flags: AuthorizationFlags = [
                            .interactionAllowed,
                            .extendRights,
                            .preAuthorize
                        ]

                        return AuthorizationCopyRights(
                            authRef,
                            &rights,
                            nil,
                            flags,
                            nil
                        )
                    }
                }
            }()

            DispatchQueue.main.async {
                if result != errAuthorizationSuccess {
                    LogManager.shared.log(.warning, "Admin authorization failed", fileID: #fileID, function: #function, line: #line)
                    
                    showAlert(
                        titleKey: "ADMIN_AUTH_FAILED",
                        messageKey: "ADMIN_RIGHTS_REQUIRED"
                    )
                }
                
                completion(result == errAuthorizationSuccess)
            }
        }
    
    private static func isCurrentUserAdmin() -> Bool {
        var authRef: AuthorizationRef?

        let status = AuthorizationCreate(
            nil,
            nil,
            [],
            &authRef
        )

        guard status == errAuthorizationSuccess, let authRef else {
            return false
        }

        let result: OSStatus = {
            let rightName = kAuthorizationRightExecute

            return rightName.withCString { cString in
                
                var items = [AuthorizationItem(
                    name: cString,
                    valueLength: 0,
                    value: nil,
                    flags: 0
                )]

                return items.withUnsafeMutableBufferPointer { buffer in
                    var rights = AuthorizationRights(
                        count: UInt32(buffer.count),
                        items: buffer.baseAddress
                    )

                    let flags: AuthorizationFlags = [
                        .preAuthorize,
                        .extendRights
                    ]

                    return AuthorizationCopyRights(
                        authRef,
                        &rights,
                        nil,
                        flags,
                        nil
                    )
                }
            }
        }()

        return result == errAuthorizationSuccess
    }
    
    static func authenticateAdminAware(
        reason: String,
        completion: @escaping (Bool) -> Void
    ) {
        if isCurrentUserAdmin() {
            LogManager.shared.log(.info, "User is admin → using user authentication", fileID: #fileID, function: #function, line: #line)
            
            authenticateUser(reason: reason, completion: completion)
        } else {
            LogManager.shared.log(.info, "User is NOT admin → requesting admin authorization", fileID: #fileID, function: #function, line: #line)
            
            authenticateAdmin(reason: reason, completion: completion)
        }
    }

        // MARK: - Shared Alert Helper

        private static func showAlert(titleKey: String, messageKey: String) {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = localize(key: titleKey)
            alert.informativeText = localize(key: messageKey)
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    
    public static func localize(key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
}

