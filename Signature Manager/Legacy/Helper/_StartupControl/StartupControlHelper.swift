//
//  Helper.swift
//  Signature Manager
//
//  Created by Marc Büttner on 10.09.24.
//

import Foundation

class LegacyStartupControlHelper {
    
    static func getAppStartupState() -> String? {
            let process = Process()
            let pipe = Pipe()
            let command = "osascript \"/Applications/Signature Manager.app/Contents/Resources/Helper/AppStartupCheckout.scpt\""
                    
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", command]
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                print("Helper: Checking App Startup State... (\(command))")
                process.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    print(output)
                    return output  // korrekter Rückgabewert
                } else {
                    //SMX.exception(location: "Helper - AppStartupState", title: "Internal error", body: "Error: the osascript could not be executed (UTF8CONVERTER).")
                }
            } catch {
                //SMX.exception(location: "Helper - AppStartupState", title: "Internal error", body: "Error: the osascript could not be executed.")
            }
            return nil
        }
    
    
    static func addAppToStartup() {
        let process = Process()
        let pipe = Pipe()
        let command = "osascript \"/Applications/Signature Manager.app/Contents/Resources/Helper/AddAppToStartup.scpt\""
        
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            print("Helper: Adding App to Startup... (\(command))")
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                if output == "true" {
                    //SMX.notification(title: "DevTools 2 added to login objects.", body: "DevTools 2 is now opened automatically at system startup.")
                } else {
                    //SMX.exception(location: "Helper", title: "Error by adding to logon objects.", body: "")
                }
            } else {
                //SMX.exception(location: "Helper - AddingAppToStartup", title: "Internal error", body: "Error: the osascript could not be executed (UTF8CONVERTER).")
            }
        } catch {
            //SMX.exception(location: "Helper - AddingAppToStartup", title: "Internal error", body: "Error: the osascript could not be executed.")
        }
    }
    
    
    static func removeAppFromStartup() {
        let process = Process()
        let pipe = Pipe()
        let command = "osascript \"/Applications/Signature Manager.app/Contents/Resources/Helper/RemoveAppFromStartup.scpt\""
        
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            print("Helper: Removing App from Startup... (\(command))")
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                if output == "false" {
                    //SMX.exception(location: "Helper", title: "Error by removing from logon objects.", body: "")
                }
            } else {
               // SMX.exception(location: "Helper - AddingAppToStartup", title: "Internal error", body: "Error: the osascript could not be executed (UTF8CONVERTER).")
            }
        } catch {
            //SMX.exception(location: "Helper - AddingAppToStartup", title: "Internal error", body: "Error: the osascript could not be executed.")
        }
    }
}
