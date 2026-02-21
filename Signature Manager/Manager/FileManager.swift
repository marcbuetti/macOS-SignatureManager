//
//  FileManager.swift
//  Signature Manager
//
//  Created by Marc Büttner on 06.01.25.
//

import SwiftUI


class FileManagerHelper {
    func getAppSupportDirectory() -> URL {
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupportDir.appendingPathComponent("com.mbuettner.SignatureManager", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: appDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                LogManager.shared.log(.critical, "Failed to create app support directory: \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
            }
        }
        
        return appDirectory
    }
    
    func getBackupDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let backupDirectory = tempDir.appendingPathComponent("com.mbuettner.SignatureManager", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: backupDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                LogManager.shared.log(.critical, "Failed to create backup directory: \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
            }
        }
        
        return backupDirectory
    }
    
    
    func backupAllHTMLFiles() -> Bool {
        let appSupportDirectory = getAppSupportDirectory()
        let backupDirectory = getBackupDirectory()
        let fileManager = FileManager.default
        var success = true
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: appSupportDirectory, includingPropertiesForKeys: nil)
            let htmlFiles = fileURLs.filter { $0.pathExtension == "html" }
            
            for file in htmlFiles {
                let destinationURL = backupDirectory.appendingPathComponent(file.lastPathComponent)
                do {
                    try fileManager.moveItem(at: file, to: destinationURL)
                } catch {
                    LogManager.shared.log(.critical, "Error moving file \(file.lastPathComponent): \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
                    success = false
                }
            }
            
        } catch {
            LogManager.shared.log(.critical, "Error listing contents of Application Support Directory: \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
            success = false
        }
        
        return success
    }
    
    func restoreHTMLFilesFromBackup() -> Bool {
        let appSupportDirectory = getAppSupportDirectory()
        let backupDirectory = getBackupDirectory()
        let fileManager = FileManager.default
        var success = true
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil)
            let htmlFiles = fileURLs.filter { $0.pathExtension == "html" }
            
            for file in htmlFiles {
                let destinationURL = appSupportDirectory.appendingPathComponent(file.lastPathComponent)
                do {
                    try fileManager.moveItem(at: file, to: destinationURL)
                } catch {
                    LogManager.shared.log(.critical, "Error restoring file \(file.lastPathComponent): \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
                    success = false
                }
            }
            
        } catch {
            LogManager.shared.log(.critical, "Error listing contents of Backup Directory: \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
            success = false
        }
        
        return success
    }
    
    func saveDataToFile(fileName: String, data: Data) -> Bool {
        let fileURL = getAppSupportDirectory().appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
            return true
        } catch {
            LogManager.shared.log(.critical, "Error saving data: \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
            return false
        }
    }
    
    func loadDataFromFile(fileName: String) -> Data? {
        let fileURL = getAppSupportDirectory().appendingPathComponent(fileName)
        do {
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            LogManager.shared.log(.critical, "Error loading data: \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
            return nil
        }
    }
    
    func deleteFile(fileName: String) -> Bool {
        let fileURL = getAppSupportDirectory().appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                return true
            } catch {
                LogManager.shared.log(.critical, "Error deleting file: \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
                return false
            }
        } else {
            LogManager.shared.log(.warning, "File does not exist: \(fileURL.path)", fileID: #fileID, function: #function, line: #line)
            return false
        }
    }
    
    //TODO: GET SUCCESS STATE
    public func deleteAllHTMLFiles() {
        let fileManager = FileManager.default
        let directory = getAppSupportDirectory()
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            let htmlFiles = fileURLs.filter { $0.pathExtension == "html" }
            
            for file in htmlFiles {
                do {
                    try fileManager.removeItem(at: file)
                } catch {
                    LogManager.shared.log(.critical, "Error deleting file: \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
                }
            }
            
        } catch {
            LogManager.shared.log(.critical, "Error listing contents of directory: \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
        }
    }
}

