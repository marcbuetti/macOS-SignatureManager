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
            Logger.shared.log(position: "AppManager.hasFullDiskAccess", type: "WARNING", content: "No read access to: \(testPath)")
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
                                Logger.shared.log(
                                    position: "AuthService.authenticateUser",
                                    type: "WARNING",
                                    content: authError.localizedDescription
                                )
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
                    Logger.shared.log(
                        position: "AuthService.authenticateUser",
                        type: "CRITICAL",
                        content: error.localizedDescription
                    )
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
            
            let rightName = kAuthorizationRightExecute
            var rights = AuthorizationRights(
                count: 1,
                items: UnsafeMutablePointer(
                    mutating: [
                        AuthorizationItem(
                            name: rightName,
                            valueLength: 0,
                            value: nil,
                            flags: 0
                        )
                    ]
                )
            )
            
            let flags: AuthorizationFlags = [
                .interactionAllowed,
                .extendRights,
                .preAuthorize
            ]
            
            let result = AuthorizationCopyRights(
                authRef,
                &rights,
                nil,
                flags,
                nil
            )
            
            DispatchQueue.main.async {
                if result != errAuthorizationSuccess {
                    Logger.shared.log(
                        position: "AuthService.authenticateAdmin",
                        type: "WARNING",
                        content: "Admin authorization failed (status=\(result))"
                    )
                    
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

        let rightName = kAuthorizationRightExecute
        var rights = AuthorizationRights(
            count: 1,
            items: UnsafeMutablePointer(
                mutating: [
                    AuthorizationItem(
                        name: rightName,
                        valueLength: 0,
                        value: nil,
                        flags: 0
                    )
                ]
            )
        )

        let flags: AuthorizationFlags = [
            .preAuthorize,
            .extendRights
            // 🚫 KEIN interactionAllowed → kein Dialog!
        ]

        let result = AuthorizationCopyRights(
            authRef,
            &rights,
            nil,
            flags,
            nil
        )

        return result == errAuthorizationSuccess
    }
    
    static func authenticateAdminAware(
        reason: String,
        completion: @escaping (Bool) -> Void
    ) {
        if isCurrentUserAdmin() {
            Logger.shared.log(
                position: "AuthService.authenticateAdminAware",
                type: "DEBUG",
                content: "User is admin → using user authentication"
            )
            
            authenticateUser(reason: reason, completion: completion)
        } else {
            Logger.shared.log(
                position: "AuthService.authenticateAdminAware",
                type: "DEBUG",
                content: "User is NOT admin → requesting admin authorization"
            )
            
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
