//
//  GraphService.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 06.01.25.
//

import SwiftUI


class GraphService {
    
    @AppStorage("graph.clientId") private var clientId: String = ""
    @AppStorage("graph.tenantId") private var tenantId: String = ""
    @AppStorage("graph.clientSecret") private var clientSecret: String = ""
    @AppStorage("graph.sitePath") private var sitePath: String = ""
    @AppStorage("graph.sharepointDomain") private var sharepointDomain: String = ""
    @AppStorage("graph.smaSyncList") private var smaSyncList: String = ""
    @AppStorage("graph.AppDataId") private var AppDataId: String = ""
    @AppStorage("app.lastUpdate") private var lastUpdateTimestamp: String = ""
    
    private var isRunning = false
    private let updateInterval: TimeInterval = 60 ///Seconds
    
    func getAccessToken(completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://login.microsoftonline.com/\(tenantId)/oauth2/v2.0/token")!
        let parameters = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "scope": "https://graph.microsoft.com/.default",
            "grant_type": "client_credentials"
        ]
        let bodyData = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                Logger.shared.log(position: "GraphService.getAccessToken", type: "CRITICAL", content: "Error fetching Access Token: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let accessToken = json["access_token"] as? String {
                completion(accessToken)
            } else {
                Logger.shared.log(position: "GraphService.getAccessToken", type: "CRITICAL", content: "Error parsing Access Token response")
                completion(nil)
            }
        }
        task.resume()
    }
    
    func getSiteId(accessToken: String, sitePath: String, domain: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://graph.microsoft.com/v1.0/sites/\(domain):/\(sitePath)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                Logger.shared.log(position: "GraphService.getSiteId", type: "CRITICAL", content: "Error fetching Site ID: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let siteId = json["id"] as? String {
                    completion(siteId)
                } else {
                    Logger.shared.log(position: "GraphService.getSiteId", type: "CRITICAL", content: "Error parsing Site ID response.")
                    completion(nil)
                }
            } catch {
                Logger.shared.log(position: "GraphService.getSiteId", type: "CRITICAL", content: "JSON Parsing Error: \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }
    
    private func getDriveId(accessToken: String, siteId: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://graph.microsoft.com/v1.0/sites/\(siteId)/drive")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                Logger.shared.log(position: "GraphService.getDriveId", type: "CRITICAL", content: "Error fetching Drive ID: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let driveId = json["id"] as? String {
                completion(driveId)
            } else {
                Logger.shared.log(position: "GraphService.getDriveId", type: "CRITICAL", content: "Error parsing Drive ID response.")
                completion(nil)
            }
        }
        task.resume()
    }
    
    func checkConnection(debug: Bool = false, completion: @escaping (Bool, String?) -> Void = { _, _ in }) {
        getAccessToken { accessToken in
            guard let accessToken = accessToken else {
                if debug {
                    Logger.shared.log(position: "GraphService.checkConnection", type: "WARNING", content: "Unable to authenticate with Graph")
                }
                completion(false, nil)
                return
            }
            
            self.getSiteId(accessToken: accessToken, sitePath: self.sitePath, domain: self.sharepointDomain) { siteId in
                if siteId != nil {
                    // Removed info log for siteId availability
                    completion(true, accessToken)
                } else {
                    if debug {
                        Logger.shared.log(position: "GraphService.checkConnection", type: "WARNING", content: "Unable to fetch Site ID")
                    }
                    completion(false, nil)
                }
            }
        }
    }
    
    func reigsterRemoteDevice() {
        checkConnection { isAvailable, accessToken in
            guard isAvailable, let accessToken = accessToken else {
                DispatchQueue.main.async {
                    /*let alert = NSAlert()
                    alert.messageText = "Verbindung zu Microsoft365 konnte nicht hergestellt werden"
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "OK")
                    alert.addButton(withTitle: "Einstellungen öffnen")
                    
                    let response = alert.runModal()
                    if response == .alertSecondButtonReturn {
                        //let mainStoryboard = NSStoryboard(name: "Main", bundle: nil)
                        //let settingsWindowController = mainStoryboard.instantiateController(withIdentifier: "SettingsWindowController") as! NSWindowController
                        //settingsWindowController.window?.center()
                        //settingsWindowController.window?.makeKeyAndOrderFront(nil)
                        //NSApp.activate(ignoringOtherApps: true)
                    }*/
                }
                return
            }
            
            self.getSiteId(accessToken: accessToken, sitePath: self.sitePath, domain: self.sharepointDomain) { siteId in
                guard let siteId = siteId else {
                    Logger.shared.log(position: "GraphService.reigsterRemoteDevice", type: "CRITICAL", content: "Error: Unable to fetch Site ID.")
                    return
                }
                let deviceName = Host.current().localizedName ?? "Unknown Device"
                let listItemsUrl = URL(string: "https://graph.microsoft.com/v1.0/sites/\(siteId)/lists/\(self.smaSyncList)/items?$expand=fields")!
                var listRequest = URLRequest(url: listItemsUrl)
                listRequest.httpMethod = "GET"
                listRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                let task = URLSession.shared.dataTask(with: listRequest) { data, response, error in
                    guard let data = data, error == nil else {
                        Logger.shared.log(position: "GraphService.reigsterRemoteDevice", type: "CRITICAL", content: "Error fetching list entries: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let items = json["value"] as? [[String: Any]] {
                        
                        let existingItem = items.first { item in
                            if let fields = item["fields"] as? [String: Any],
                               let registeredDeviceName = fields["DeviceName"] as? String {
                                return registeredDeviceName.caseInsensitiveCompare(deviceName) == .orderedSame
                            }
                            return false
                        }
                        
                        if existingItem != nil {
                            return
                        }
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd.MM.yyyy - HH:mm"
                        let formattedDate = dateFormatter.string(from: Date())
                        
                        let newDeviceData: [String: Any] = [
                            "fields": [
                                "AppPlattform": "macOS",
                                "DeviceName": deviceName,
                                "AppVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                                "Status": "registered",
                                "LastUpdate": formattedDate,
                                "UpdateRequestor": "local"
                            ]
                        ]
                        
                        var addRequest = URLRequest(url: listItemsUrl)
                        addRequest.httpMethod = "POST"
                        addRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                        addRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        addRequest.httpBody = try? JSONSerialization.data(withJSONObject: newDeviceData, options: [])
                        
                        let addTask = URLSession.shared.dataTask(with: addRequest) { data, response, error in
                            if let error = error {
                                Logger.shared.log(position: "GraphService.reigsterRemoteDevice", type: "CRITICAL", content: "Error registering device: \(error.localizedDescription)")
                                return
                            }
                        }
                        addTask.resume()
                    } else {
                        Logger.shared.log(position: "GraphService.reigsterRemoteDevice", type: "CRITICAL", content: "Error parsing list entries.")
                    }
                }
                task.resume()
            }
        }
    }
    
    
    
    func fetchRemoteUser(completion: @escaping (String?) -> Void) {
        checkConnection { isAvailable, accessToken in
            guard isAvailable, let accessToken = accessToken else {
                Logger.shared.log(position: "GraphService.fetchRemoteUser", type: "CRITICAL", content: "Unable to connect to Microsoft365")
                return
            }
            
            self.getSiteId(accessToken: accessToken, sitePath: self.sitePath, domain: self.sharepointDomain) { siteId in
                guard let siteId = siteId else {
                    Logger.shared.log(position: "GraphService.fetchRemoteUser", type: "CRITICAL", content: "Unable to fetch Site ID.")
                    completion(nil)
                    return
                }
                
                let deviceName = Host.current().localizedName ?? "Unknown Device"
                let listItemsUrl = URL(string: "https://graph.microsoft.com/v1.0/sites/\(siteId)/lists/\(self.smaSyncList)/items?$expand=fields")!
                var listRequest = URLRequest(url: listItemsUrl)
                listRequest.httpMethod = "GET"
                listRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                let task = URLSession.shared.dataTask(with: listRequest) { data, response, error in
                    guard let data = data, error == nil else {
                        Logger.shared.log(position: "GraphService.fetchRemoteUser", type: "CRITICAL", content: "Error fetching SharePoint list items: \(error?.localizedDescription ?? "Unknown error")")
                        completion(nil)
                        return
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let items = json["value"] as? [[String: Any]] {
                        for item in items {
                            if let fields = item["fields"] as? [String: Any],
                               let deviceNameField = fields["DeviceName"] as? String,
                               deviceNameField.caseInsensitiveCompare(deviceName) == .orderedSame {
                                if let assignedUser = fields["User"] as? String {
                                    completion(assignedUser)
                                    return
                                } else {
                                    Logger.shared.log(position: "GraphService.fetchRemoteUser", type: "WARNING", content: "No 'User' field found for device '\(deviceName)'.")
                                }
                            }
                        }
                        Logger.shared.log(position: "GraphService.fetchRemoteUser", type: "WARNING", content: "Device '\(deviceName)' not found in SharePoint list.")
                        completion(nil)
                    } else {
                        Logger.shared.log(position: "GraphService.fetchRemoteUser", type: "CRITICAL", content: "Error parsing SharePoint list items.")
                        completion(nil)
                    }
                }
                task.resume()
            }
        }
    }
    
    func updateRemoteStatus(status: String, remote: Bool, completion: @escaping () -> Void = {}) {
        checkConnection { isAvailable, accessToken in
            guard isAvailable, let accessToken = accessToken else {
                Logger.shared.log(position: "GraphService.updateRemoteStatus", type: "CRITICAL", content: "Unable to connect to Microsoft365")
                completion()
                return
            }
            
            self.getSiteId(accessToken: accessToken, sitePath: self.sitePath, domain: self.sharepointDomain) { siteId in
                guard let siteId = siteId else {
                    Logger.shared.log(position: "GraphService.updateRemoteStatus", type: "CRITICAL", content: "Unable to fetch Site ID.")
                    completion()
                    return
                }
                
                let deviceName = Host.current().localizedName ?? "Unknown Device"
                let listItemsUrl = URL(string: "https://graph.microsoft.com/v1.0/sites/\(siteId)/lists/\(self.smaSyncList)/items?$expand=fields")!
                var listRequest = URLRequest(url: listItemsUrl)
                listRequest.httpMethod = "GET"
                listRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                let task = URLSession.shared.dataTask(with: listRequest) { data, response, error in
                    guard let data = data, error == nil else {
                        Logger.shared.log(position: "GraphService.updateRemoteStatus", type: "CRITICAL", content: "Error fetching list entries: \(error?.localizedDescription ?? "Unknown error")")
                        completion()
                        return
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let items = json["value"] as? [[String: Any]] {
                        
                        let existingItem = items.first { item in
                            if let fields = item["fields"] as? [String: Any],
                               let registeredDeviceName = fields["DeviceName"] as? String {
                                return registeredDeviceName.caseInsensitiveCompare(deviceName) == .orderedSame
                            }
                            return false
                        }
                        
                        if let existingItem = existingItem, let itemId = existingItem["id"] as? String {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "dd.MM.yyyy - HH:mm"
                            let formattedDate = dateFormatter.string(from: Date())
                            
                            let updatedFields: [String: Any] = [
                                "AppVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                                "Status": status,
                                "LastUpdate": formattedDate,
                                "UpdateRequestor": remote ? "remote" : "local"
                            ]
                            
                            let updateUrl = URL(string: "https://graph.microsoft.com/v1.0/sites/\(siteId)/lists/\(self.smaSyncList)/items/\(itemId)/fields")!
                            var updateRequest = URLRequest(url: updateUrl)
                            updateRequest.httpMethod = "PATCH"
                            updateRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                            updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                            updateRequest.httpBody = try? JSONSerialization.data(withJSONObject: updatedFields, options: [])
                            
                            let updateTask = URLSession.shared.dataTask(with: updateRequest) { data, response, error in
                                if let error = error {
                                    Logger.shared.log(position: "GraphService.updateRemoteStatus", type: "CRITICAL", content: "Error updating device: \(error.localizedDescription)")
                                } else {
                                    let tsFormatter = DateFormatter()
                                    tsFormatter.dateFormat = "dd.MM.yyyy - HH:mm"
                                    self.lastUpdateTimestamp = tsFormatter.string(from: Date())
                                }
                                completion()
                            }
                            updateTask.resume()
                        } else {
                            Logger.shared.log(position: "GraphService.updateRemoteStatus", type: "WARNING", content: "Device '\(deviceName)' not found in SharePoint list. No updates made.")
                            completion()
                        }
                    } else {
                        Logger.shared.log(position: "GraphService.updateRemoteStatus", type: "CRITICAL", content: "Error parsing list entries.")
                        completion()
                    }
                }
                task.resume()
            }
        }
    }
    
    func startRemoteUpdateChecker() {
        guard !isRunning else {
            Logger.shared.log(position: "GraphService.startRemoteUpdateChecker", type: "WARNING", content: "Cant start remoteChecking while already running.")
            return
        }
        
        isRunning = true
        // Removed info log "Started remoteChecking."
        
        DispatchQueue.global(qos: .background).async {
            while self.isRunning {
                self.remoteUpdateCheckerCheck()
                Thread.sleep(forTimeInterval: self.updateInterval)
            }
        }
    }
    
    func stopRemoteUpdateChecker() {
        isRunning = false
        // Removed info log "Stopped remoteChecker."
    }
    
    private func remoteUpdateCheckerCheck() {
        let currentDeviceName = Host.current().localizedName ?? "Unknown Device"
        
        checkConnection { isAvailable, accessToken in
            guard isAvailable, let accessToken = accessToken else {
                Logger.shared.log(position: "GraphService.remoteUpdateCheckerCheck", type: "CRITICAL", content: "Unable to connect to Microsoft365")
                return
            }
            
            self.getSiteId(accessToken: accessToken, sitePath: self.sitePath, domain: self.sharepointDomain) { siteId in
                guard let siteId = siteId else {
                    Logger.shared.log(position: "GraphService.remoteUpdateCheckerCheck", type: "CRITICAL", content: "Unable to fetch Site ID.")
                    return
                }
                
                let listItemsUrl = URL(string: "https://graph.microsoft.com/v1.0/sites/\(siteId)/lists/Devices/items?$expand=fields")!
                var listRequest = URLRequest(url: listItemsUrl)
                listRequest.httpMethod = "GET"
                listRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                let task = URLSession.shared.dataTask(with: listRequest) { data, response, error in
                    guard let data = data, error == nil else {
                        Logger.shared.log(position: "GraphService.remoteUpdateCheckerCheck", type: "CRITICAL", content: "Error fetching list entries: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let items = json["value"] as? [[String: Any]] {
                        
                        let matchingItems = items.filter { item in
                            if let fields = item["fields"] as? [String: Any],
                               let status = fields["Status"] as? String,
                               let updateRequestor = fields["UpdateRequestor"] as? String,
                               let deviceName = fields["DeviceName"] as? String {
                                return status.caseInsensitiveCompare("requested") == .orderedSame &&
                                updateRequestor.caseInsensitiveCompare("remote") == .orderedSame &&
                                deviceName.caseInsensitiveCompare(currentDeviceName) == .orderedSame
                            }
                            return false
                        }
                        
                        for matchingItem in matchingItems {
                            if let fields = matchingItem["fields"] as? [String: Any],
                               let deviceName = fields["DeviceName"] as? String {
                                Logger.shared.log(position: "GraphService.remoteUpdateCheckerCheck", type: "WARNING", content: "Processing remote update for device: \(deviceName)")
                                self.handleRemoteUpdate(for: deviceName)
                            }
                        }
                    } else {
                        Logger.shared.log(position: "GraphService.remoteUpdateCheckerCheck", type: "CRITICAL", content: "Error parsing list entries.")
                    }
                }
                task.resume()
            }
        }
    }
    
    private func handleRemoteUpdate(for deviceName: String) {
        Logger.shared.log(position: "GraphService.handleRemoteUpdate", type: "WARNING", content: "Handling remote update for device: \(deviceName)")
        stopRemoteUpdateChecker()
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: "isRemoteUpdate")
                UpdateManager.shared.start(remoteRequested: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                    let tsFormatter = DateFormatter()
                    tsFormatter.dateFormat = "dd.MM.yyyy - HH:mm"
                    self.lastUpdateTimestamp = tsFormatter.string(from: Date())
                    self.updateRemoteStatus(status: "idle", remote: false)
                    self.startRemoteUpdateChecker()
                }
            }
        }
    }
    
    func fetchSubfolderContentsAndDownload(fromMacOSFolder folderName: String, success: @escaping () -> Void, failure: @escaping () -> Void) {
        _ = FileManagerHelper().backupAllHTMLFiles()

        checkConnection { isAvailable, accessToken in
            guard isAvailable, let accessToken = accessToken else {
                Logger.shared.log(position: "GraphService.fetchSubfolderContentsAndDownload", type: "CRITICAL", content: "Unable to connect to Microsoft 365")
                failure()
                return
            }

            self.fetchRemoteUser { userFolder in
                guard let userFolder = userFolder else {
                    Logger.shared.log(position: "GraphService.fetchSubfolderContentsAndDownload", type: "CRITICAL", content: "No user folder assigned.")
                    failure()
                    return
                }

                let group = DispatchGroup()

                group.enter()
                self._downloadUserSubfolder(
                    userFolder: userFolder,
                    folderName: "base",
                    accessToken: accessToken,
                    success: { group.leave() },
                    failure: { group.leave() }
                )

                group.enter()
                self._downloadUserSubfolder(
                    userFolder: userFolder,
                    folderName: "custom",
                    accessToken: accessToken,
                    success: { group.leave() },
                    failure: { group.leave() }
                )

                group.notify(queue: .main) {
                    success()
                }
            }
        }
    }

    private func _downloadUserSubfolder(userFolder: String,
                                        folderName: String,
                                        accessToken: String,
                                        success: @escaping () -> Void,
                                        failure: @escaping () -> Void) {

        self.getSiteId(accessToken: accessToken, sitePath: self.sitePath, domain: self.sharepointDomain) { siteId in
            guard let siteId = siteId else {
                Logger.shared.log(position: "GraphService.fetchSubfolderContentsAndDownload", type: "CRITICAL", content: "Unable to fetch Site ID.")
                failure()
                return
            }

            self.getDriveId(accessToken: accessToken, siteId: siteId) { driveId in
                guard let driveId = driveId else {
                    Logger.shared.log(position: "GraphService.fetchSubfolderContentsAndDownload", type: "CRITICAL", content: "Unable to fetch Drive ID.")
                    failure()
                    return
                }

                let combinedPath = "\(userFolder)/\(folderName)"
                let urlString = "https://graph.microsoft.com/v1.0/sites/\(siteId)/drives/\(driveId)/items/\(self.AppDataId):/\(combinedPath):/children"
                var request = URLRequest(url: URL(string: urlString)!)
                request.httpMethod = "GET"
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

                URLSession.shared.dataTask(with: request) { data, response, error in
                    guard let data = data, error == nil else {
                        Logger.shared.log(position: "GraphService.fetchSubfolderContentsAndDownload", type: "CRITICAL", content: "Network error: \(error?.localizedDescription ?? "Unknown")")
                        failure()
                        return
                    }

                    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let items = json["value"] as? [[String: Any]] else {

                        let raw = String(data: data, encoding: .utf8) ?? "<no text>"
                        Logger.shared.log(position: "GraphService.fetchSubfolderContentsAndDownload", type: "CRITICAL", content: "Invalid response: \(raw)")
                        failure()
                        return
                    }

                    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                    let localDir = appSupport.appendingPathComponent("com.mbuettner.SignatureManager/OnlineSignatures/\(folderName)")
                    try? FileManager.default.createDirectory(at: localDir, withIntermediateDirectories: true)

                    let group = DispatchGroup()

                    for item in items {
                        guard let fileId = item["id"] as? String,
                              let fileName = item["name"] as? String else { continue }

                        let fileURL = "https://graph.microsoft.com/v1.0/sites/\(siteId)/drives/\(driveId)/items/\(fileId)/content"
                        var fileRequest = URLRequest(url: URL(string: fileURL)!)
                        fileRequest.httpMethod = "GET"
                        fileRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

                        group.enter()
                        URLSession.shared.dataTask(with: fileRequest) { fileData, _, _ in
                            defer { group.leave() }
                            guard let fileData = fileData else { return }

                            let localFile = localDir.appendingPathComponent(fileName)
                            try? fileData.write(to: localFile)

                        }.resume()
                    }

                    group.notify(queue: .main) {
                        success()
                    }
                }.resume()
            }
        }
    }
    
    func uploadContentsToRemote(remoteAppDataUserFolder: String, specificFile: URL, success: @escaping () -> Void, failure: @escaping () -> Void) {
        checkConnection { isAvailable, accessToken in
            guard isAvailable, let accessToken = accessToken else {
                Logger.shared.log(position: "GraphService.uploadContentsToRemote", type: "CRITICAL", content: "Unable to connect to Microsoft365")
                failure()
                return
            }
            
            self.getSiteId(accessToken: accessToken, sitePath: self.sitePath, domain: self.sharepointDomain) { siteId in
                guard let siteId = siteId else {
                    Logger.shared.log(position: "GraphService.uploadContentsToRemote", type: "CRITICAL", content: "Unable to fetch Site ID.")
                    failure()
                    return
                }
                
                self.getDriveId(accessToken: accessToken, siteId: siteId) { driveId in
                    guard let driveId = driveId else {
                        Logger.shared.log(position: "GraphService.uploadContentsToRemote", type: "CRITICAL", content: "Unable to fetch Drive ID.")
                        failure()
                        return
                    }
                    
                    let macOSFolderUrl = "https://graph.microsoft.com/v1.0/sites/\(siteId)/drives/\(driveId)/items/\(self.AppDataId)/children"
                    var request = URLRequest(url: URL(string: macOSFolderUrl)!)
                    request.httpMethod = "GET"
                    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    
                    let task = URLSession.shared.dataTask(with: request) { data, response, error in
                        guard let data = data, error == nil else {
                            Logger.shared.log(position: "GraphService.uploadContentsToRemote", type: "CRITICAL", content: "Error fetching items in 'macOS' folder: \(error?.localizedDescription ?? "Unknown error")")
                            failure()
                            return
                        }
                        
                        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let items = json["value"] as? [[String: Any]],
                           let targetFolder = items.first(where: { ($0["name"] as? String) == remoteAppDataUserFolder }),
                           let targetFolderId = targetFolder["id"] as? String {
                            
                            let localFiles = [specificFile]
                            let uploadGroup = DispatchGroup()
                            
                            for file in localFiles {
                                let fileName = file.lastPathComponent
                                let fileUrl = "https://graph.microsoft.com/v1.0/sites/\(siteId)/drives/\(driveId)/items/\(targetFolderId):/\(fileName):/content"
                                
                                var uploadRequest = URLRequest(url: URL(string: fileUrl)!)
                                uploadRequest.httpMethod = "PUT"
                                uploadRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                                
                                guard let fileData = try? Data(contentsOf: file) else {
                                    Logger.shared.log(position: "GraphService.uploadContentsToRemote", type: "CRITICAL", content: "Could not read file data for: \(fileName)")
                                    failure()
                                    continue
                                }
                                
                                uploadRequest.httpBody = fileData
                                uploadGroup.enter()
                                
                                let uploadTask = URLSession.shared.dataTask(with: uploadRequest) { data, response, error in
                                    defer { uploadGroup.leave() }
                                    
                                    if let error = error {
                                        Logger.shared.log(position: "GraphService.uploadContentsToRemote", type: "CRITICAL", content: "Error uploading \(fileName): \(error.localizedDescription)")
                                        failure()
                                    }
                                }
                                uploadTask.resume()
                            }
                            
                            uploadGroup.notify(queue: .main) {
                                let tsFormatter = DateFormatter()
                                tsFormatter.dateFormat = "dd.MM.yyyy - HH:mm"
                                self.lastUpdateTimestamp = tsFormatter.string(from: Date())
                                success()
                            }
                            
                        } else {
                            Logger.shared.log(position: "GraphService.uploadContentsToRemote", type: "WARNING", content: "'\(remoteAppDataUserFolder)' folder not found in 'macOS' folder.")
                            failure()
                        }
                    }
                    
                    task.resume()
                }
            }
        }
    }
}

