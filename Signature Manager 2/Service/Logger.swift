//
//  Logger.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 18.09.24.
//

import SwiftUI


class Logger {
    
    static let shared = Logger()
    
    public var logFileURLForSharing: URL? {
        return self.logFileURL
    }
    
    private var logFileURL: URL? {
        guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let logDirectory = appSupportDir.appendingPathComponent("com.mbuettner.SignatureManager")
        
        if !FileManager.default.fileExists(atPath: logDirectory.path) {
            try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        return logDirectory.appendingPathComponent("app.log")
    }
    
    private let maxLogFileSize: Int = 1024 * 1024 // Max size 1MB
    
    private init() {}
    
    func log(position: String, type: String, content: String) {
        let timestamp = getCurrentTimestamp()
        let message = "\(timestamp).\(position).\(type) |-| \(content)\n"
        
        do {
            try appendToLogFile(message: message)
        } catch {
            print("[LOGGER]]: \(error)")
        }
    }
    
    private func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd/HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    private func appendToLogFile(message: String) throws {
        guard let logFileURL = logFileURL else { return }
        
        if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
            fileHandle.seekToEndOfFile()
            if let data = message.data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        } else {
            try message.write(to: logFileURL, atomically: true, encoding: .utf8)
        }
    }
    
    func rotateLogFileIfNeeded() throws {
        guard let logFileURL = logFileURL else { return }
        
        let attributes = try FileManager.default.attributesOfItem(atPath: logFileURL.path)
        if let fileSize = attributes[FileAttributeKey.size] as? NSNumber {
            if fileSize.intValue > maxLogFileSize {
                try FileManager.default.removeItem(at: logFileURL)
            }
        }
    }
    
    func getLog() -> String {
        guard let logFileURL = logFileURL else { return "" }
        
        if let logContents = try? String(contentsOf: logFileURL, encoding: .utf8) {
            return logContents
        } else {
            return ""
        }
    }
    
    func clearLog() throws {
        guard let logFileURL = logFileURLForSharing else { return }
        if FileManager.default.fileExists(atPath: logFileURL.path) {
            try FileManager.default.removeItem(at: logFileURL)
        }
    }
}
