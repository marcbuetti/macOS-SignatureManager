//
//  GraphService.swift
//  Signature Manager
//
//  Created by Marc Büttner on 06.01.25.
//

import SwiftUI


class GraphService {
    
    @AppStorage("graph.clientId") private var clientId: String = "0c53ffb4-5fd7-49ee-84f4-35a850232d54"
    @AppStorage("graph.tenantId") private var tenantId: String = "ca15dbb3-3e88-4d75-b548-5f8b50df897e"
    @AppStorage("graph.clientSecret") private var clientSecret: String = "ZUx8Q~8NiF-tLByyRiIUInnWWDta6-e.phrLGdlZ"
    @AppStorage("graph.sharepointDomain") private var sharepointDomain: String = "vegilifeag966.sharepoint.com"
    @AppStorage("graph.siteId") private var siteId: String = "IT9"
    @AppStorage("graph.baseFolderName") private var baseFolderName: String = "General"
    @AppStorage("graph.AppDataFolder") private var AppDataFolder: String = "SignatureManager"
    @AppStorage("graph.CachededAccessToken") private var cachedAccessToken: String = ""
    @AppStorage("graph.CacheddAccessTokenExpiration") private var cachedAccessTokenExpiration: String = ""
    @AppStorage("app.lastUpdate") private var lastUpdateTimestamp: String = ""
    
    private var driveName: String = "Shared Documents"
    private var smaSyncList: String = "Devices"
    private var isRunning = false
    private let updateInterval: TimeInterval = 60 ///Seconds
    
    //MARK: ACCESS TOKEN
    
    func getAccessToken(completion: @escaping (String?) -> Void) {
        
        Logger.shared.log(position: "GraphService.getAccessToken", type: "DEBUG", content: "Requesting access token for tenant: \(tenantId.prefix(6))... and client: \(clientId.prefix(6))...")
        
        //print(clientId, tenantId, clientSecret, sharepointDomain, siteId, driveName, baseFolderName)
        
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
        
        Logger.shared.log(position: "GraphService.getAccessToken", type: "DEBUG", content: "POST \(url.absoluteString)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            Logger.shared.log(position: "GraphService.getAccessToken", type: "DEBUG", content: "Received response: status=\((response as? HTTPURLResponse)?.statusCode ?? -1), bytes=\(data?.count ?? 0)")
            
            guard let data = data, error == nil else {
                Logger.shared.log(position: "GraphService.getAccessToken", type: "CRITICAL", content: "Error fetching Access Token: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let accessToken = json["access_token"] as? String {
                Logger.shared.log(position: "GraphService.getAccessToken", type: "DEBUG", content: "Access token received (length=\(accessToken.count))")
                completion(accessToken)
            } else {
                Logger.shared.log(position: "GraphService.getAccessToken", type: "CRITICAL", content: "Error parsing Access Token response")
                completion(nil)
            }
        }
        task.resume()
    }
    
    private func getValidAccessToken(completion: @escaping (String?) -> Void) {

        // 1️⃣ Prüfen ob Token + Expiration existieren
        if
            !cachedAccessToken.isEmpty,
            let exp = TimeInterval(cachedAccessTokenExpiration),
            Date().timeIntervalSince1970 < exp - 60 // 60s Sicherheit
        {
            Logger.shared.log(
                position: "GraphService.getValidAccessToken",
                type: "DEBUG",
                content: "Using cached access token"
            )
            completion(cachedAccessToken)
            return
        }

        // 2️⃣ Neu holen
        getAccessToken { token in
            guard let token else {
                completion(nil)
                return
            }

            // Expiration aus JWT lesen (exp Claim)
            let parts = token.split(separator: ".")
            if parts.count == 3,
               let data = Data(base64Encoded: String(parts[1]).base64URLDecoded()),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let exp = json["exp"] as? TimeInterval {

                self.cachedAccessToken = token
                self.cachedAccessTokenExpiration = String(exp)

                Logger.shared.log(
                    position: "GraphService.getValidAccessToken",
                    type: "DEBUG",
                    content: "Cached new access token (exp=\(exp))"
                )
            }

            completion(token)
        }
    }
    
    //MARK: SITE ID
    
    func getSiteId(accessToken: String, siteId: String, domain: String, completion: @escaping (String?) -> Void) {
        Logger.shared.log(position: "GraphService.getSiteId", type: "DEBUG", content: "Resolving siteId for sitePath=\(siteId) on domain=\(domain)")
        let url = URL(string: "https://graph.microsoft.com/v1.0/sites/\(domain):/sites/\(siteId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        Logger.shared.log(position: "GraphService.getSiteId", type: "DEBUG", content: "GET \(url.absoluteString)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            Logger.shared.log(position: "GraphService.getSiteId", type: "DEBUG", content: "Response status=\((response as? HTTPURLResponse)?.statusCode ?? -1), bytes=\(data?.count ?? 0)")
            
            guard let data = data, error == nil else {
                Logger.shared.log(position: "GraphService.getSiteId", type: "CRITICAL", content: "Error fetching Site ID: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let siteId = json["id"] as? String {
                    Logger.shared.log(position: "GraphService.getSiteId", type: "DEBUG", content: "Resolved site id: \(siteId)")
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
    
    //MARK: DRIVE ID
    
    private func getDriveId(accessToken: String, siteId: String, completion: @escaping (String?) -> Void) {
        Logger.shared.log(position: "GraphService.getDriveId", type: "DEBUG", content: "Fetching drive id for siteId=\(siteId)")
        let url = URL(string: "https://graph.microsoft.com/v1.0/sites/\(siteId)/drive")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        Logger.shared.log(position: "GraphService.getDriveId", type: "DEBUG", content: "GET \(url.absoluteString)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            Logger.shared.log(position: "GraphService.getDriveId", type: "DEBUG", content: "Response status=\((response as? HTTPURLResponse)?.statusCode ?? -1), bytes=\(data?.count ?? 0)")
            
            guard let data = data, error == nil else {
                Logger.shared.log(position: "GraphService.getDriveId", type: "CRITICAL", content: "Error fetching Drive ID: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let driveId = json["id"] as? String {
                Logger.shared.log(position: "GraphService.getDriveId", type: "DEBUG", content: "Resolved drive id: \(driveId)")
                completion(driveId)
            } else {
                Logger.shared.log(position: "GraphService.getDriveId", type: "CRITICAL", content: "Error parsing Drive ID response.")
                completion(nil)
            }
        }
        task.resume()
    }
    
    //MARK: REMOTE MANAGEMENT
    
    func checkConnection(debug: Bool = false, completion: @escaping (Bool, String?) -> Void = { _, _ in }) {
        Logger.shared.log(position: "GraphService.checkConnection", type: "DEBUG", content: "Checking Graph connectivity...")
        getValidAccessToken { accessToken in
            guard let accessToken = accessToken else {
                if debug {
                    Logger.shared.log(position: "GraphService.checkConnection", type: "WARNING", content: "Unable to authenticate with Graph")
                }
                completion(false, nil)
                return
            }
            
            Logger.shared.log(position: "GraphService.checkConnection", type: "DEBUG", content: "Access token acquired. Resolving site...")
            
            self.getSiteId(accessToken: accessToken, siteId: self.siteId, domain: self.sharepointDomain) { siteId in
                if siteId != nil {
                    // Removed info log for siteId availability
                    Logger.shared.log(position: "GraphService.checkConnection", type: "DEBUG", content: "Connection OK. Site resolved.")
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
        Logger.shared.log(position: "GraphService.reigsterRemoteDevice", type: "DEBUG", content: "Registering device if needed...")
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
            
            self.getSiteId(accessToken: accessToken, siteId: self.siteId, domain: self.sharepointDomain) { siteId in
                guard let siteId = siteId else {
                    Logger.shared.log(position: "GraphService.reigsterRemoteDevice", type: "CRITICAL", content: "Error: Unable to fetch Site ID.")
                    return
                }
                let deviceName = Host.current().localizedName ?? "Unknown Device"
                Logger.shared.log(position: "GraphService.reigsterRemoteDevice", type: "DEBUG", content: "Device name: \(deviceName)")
                let listItemsUrl = URL(string: "https://graph.microsoft.com/v1.0/sites/\(siteId)/lists/\(self.smaSyncList)/items?$expand=fields")!
                Logger.shared.log(position: "GraphService.reigsterRemoteDevice", type: "DEBUG", content: "GET \(listItemsUrl.absoluteString)")
                var listRequest = URLRequest(url: listItemsUrl)
                listRequest.httpMethod = "GET"
                listRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                let task = URLSession.shared.dataTask(with: listRequest) { data, response, error in
                    Logger.shared.log(position: "GraphService.reigsterRemoteDevice", type: "DEBUG", content: "List response status=\((response as? HTTPURLResponse)?.statusCode ?? -1), bytes=\(data?.count ?? 0)")
                    guard let data = data, error == nil else {
                        Logger.shared.log(position: "GraphService.reigsterRemoteDevice", type: "CRITICAL", content: "Error fetching list entries: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let items = json["value"] as? [[String: Any]] {
                        Logger.shared.log(position: "GraphService.reigsterRemoteDevice", type: "DEBUG", content: "Fetched \(items.count) list items")
                        
                        let existingItem = items.first { item in
                            if let fields = item["fields"] as? [String: Any],
                               let registeredDeviceName = fields["DeviceName"] as? String {
                                return registeredDeviceName.caseInsensitiveCompare(deviceName) == .orderedSame
                            }
                            return false
                        }
                        
                        if existingItem != nil {
                            Logger.shared.log(position: "GraphService.reigsterRemoteDevice", type: "DEBUG", content: "Device already registered. Skipping create.")
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
                        
                        Logger.shared.log(position: "GraphService.reigsterRemoteDevice", type: "DEBUG", content: "POST new device to list")
                        
                        let addTask = URLSession.shared.dataTask(with: addRequest) { data, response, error in
                            if let error = error {
                                Logger.shared.log(position: "GraphService.reigsterRemoteDevice", type: "CRITICAL", content: "Error registering device: \(error.localizedDescription)")
                                return
                            }
                            Logger.shared.log(position: "GraphService.reigsterRemoteDevice", type: "DEBUG", content: "Device registration request sent.")
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
        Logger.shared.log(position: "GraphService.fetchRemoteUser", type: "DEBUG", content: "Fetching assigned remote user for this device...")
        checkConnection { isAvailable, accessToken in
            guard isAvailable, let accessToken = accessToken else {
                Logger.shared.log(position: "GraphService.fetchRemoteUser", type: "CRITICAL", content: "Unable to connect to Microsoft365")
                return
            }
            
            self.getSiteId(accessToken: accessToken, siteId: self.siteId, domain: self.sharepointDomain) { siteId in
                guard let siteId = siteId else {
                    Logger.shared.log(position: "GraphService.fetchRemoteUser", type: "CRITICAL", content: "Unable to fetch Site ID.")
                    completion(nil)
                    return
                }
                
                let deviceName = Host.current().localizedName ?? "Unknown Device"
                Logger.shared.log(position: "GraphService.fetchRemoteUser", type: "DEBUG", content: "Device name: \(deviceName)")
                let listItemsUrl = URL(string: "https://graph.microsoft.com/v1.0/sites/\(siteId)/lists/\(self.smaSyncList)/items?$expand=fields")!
                Logger.shared.log(position: "GraphService.fetchRemoteUser", type: "DEBUG", content: "GET \(listItemsUrl.absoluteString)")
                var listRequest = URLRequest(url: listItemsUrl)
                listRequest.httpMethod = "GET"
                listRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                let task = URLSession.shared.dataTask(with: listRequest) { data, response, error in
                    Logger.shared.log(position: "GraphService.fetchRemoteUser", type: "DEBUG", content: "Response status=\((response as? HTTPURLResponse)?.statusCode ?? -1), bytes=\(data?.count ?? 0)")
                    guard let data = data, error == nil else {
                        Logger.shared.log(position: "GraphService.fetchRemoteUser", type: "CRITICAL", content: "Error fetching SharePoint list items: \(error?.localizedDescription ?? "Unknown error")")
                        completion(nil)
                        return
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let items = json["value"] as? [[String: Any]] {
                        Logger.shared.log(position: "GraphService.fetchRemoteUser", type: "DEBUG", content: "Scanned \(items.count) list items for device match")
                        for item in items {
                            if let fields = item["fields"] as? [String: Any],
                               let deviceNameField = fields["DeviceName"] as? String,
                               deviceNameField.caseInsensitiveCompare(deviceName) == .orderedSame {
                                if let assignedUser = fields["User"] as? String {
                                    Logger.shared.log(position: "GraphService.fetchRemoteUser", type: "DEBUG", content: "Assigned user found: \(assignedUser)")
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
        Logger.shared.log(position: "GraphService.updateRemoteStatus", type: "DEBUG", content: "Updating remote status to '\(status)' (requestor=\(remote ? "remote" : "local"))")
        checkConnection { isAvailable, accessToken in
            guard isAvailable, let accessToken = accessToken else {
                Logger.shared.log(position: "GraphService.updateRemoteStatus", type: "CRITICAL", content: "Unable to connect to Microsoft365")
                completion()
                return
            }
            
            self.getSiteId(accessToken: accessToken, siteId: self.siteId, domain: self.sharepointDomain) { siteId in
                guard let siteId = siteId else {
                    Logger.shared.log(position: "GraphService.updateRemoteStatus", type: "CRITICAL", content: "Unable to fetch Site ID.")
                    completion()
                    return
                }
                
                let deviceName = Host.current().localizedName ?? "Unknown Device"
                Logger.shared.log(position: "GraphService.updateRemoteStatus", type: "DEBUG", content: "Device name: \(deviceName)")
                let listItemsUrl = URL(string: "https://graph.microsoft.com/v1.0/sites/\(siteId)/lists/\(self.smaSyncList)/items?$expand=fields")!
                Logger.shared.log(position: "GraphService.updateRemoteStatus", type: "DEBUG", content: "GET \(listItemsUrl.absoluteString)")
                var listRequest = URLRequest(url: listItemsUrl)
                listRequest.httpMethod = "GET"
                listRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                let task = URLSession.shared.dataTask(with: listRequest) { data, response, error in
                    Logger.shared.log(position: "GraphService.updateRemoteStatus", type: "DEBUG", content: "Response status=\((response as? HTTPURLResponse)?.statusCode ?? -1), bytes=\(data?.count ?? 0)")
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
                        
                        Logger.shared.log(position: "GraphService.updateRemoteStatus", type: "DEBUG", content: existingItem != nil ? "Existing item found. Updating fields..." : "No existing item for device.")
                        
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
                            Logger.shared.log(position: "GraphService.updateRemoteStatus", type: "DEBUG", content: "PATCH \(updateUrl.absoluteString)")
                            var updateRequest = URLRequest(url: updateUrl)
                            updateRequest.httpMethod = "PATCH"
                            updateRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                            updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                            updateRequest.httpBody = try? JSONSerialization.data(withJSONObject: updatedFields, options: [])
                            
                            let updateTask = URLSession.shared.dataTask(with: updateRequest) { data, response, error in
                                if let error = error {
                                    Logger.shared.log(position: "GraphService.updateRemoteStatus", type: "CRITICAL", content: "Error updating device: \(error.localizedDescription)")
                                } else {
                                    Logger.shared.log(position: "GraphService.updateRemoteStatus", type: "DEBUG", content: "Update successful. Timestamp updated.")
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
        Logger.shared.log(position: "GraphService.startRemoteUpdateChecker", type: "DEBUG", content: "Starting remote update checker loop (interval=\(updateInterval)s)")
        guard !isRunning else {
            Logger.shared.log(position: "GraphService.startRemoteUpdateChecker", type: "WARNING", content: "Cant start remoteChecking while already running.")
            return
        }
        
        isRunning = true
        
        DispatchQueue.global(qos: .background).async {
            while self.isRunning {
                self.remoteUpdateCheckerCheck()
                Thread.sleep(forTimeInterval: self.updateInterval)
            }
        }
    }
    
    func stopRemoteUpdateChecker() {
        Logger.shared.log(position: "GraphService.stopRemoteUpdateChecker", type: "DEBUG", content: "Stopping remote update checker loop")
        isRunning = false
    }
    
    private func remoteUpdateCheckerCheck() {
        let currentDeviceName = Host.current().localizedName ?? "Unknown Device"
        Logger.shared.log(position: "GraphService.remoteUpdateCheckerCheck", type: "DEBUG", content: "Polling remote updates for device: \(currentDeviceName)")
        
        checkConnection { isAvailable, accessToken in
            guard isAvailable, let accessToken = accessToken else {
                Logger.shared.log(position: "GraphService.remoteUpdateCheckerCheck", type: "CRITICAL", content: "Unable to connect to Microsoft365")
                return
            }
            
            self.getSiteId(accessToken: accessToken, siteId: self.siteId, domain: self.sharepointDomain) { siteId in
                guard let siteId = siteId else {
                    Logger.shared.log(position: "GraphService.remoteUpdateCheckerCheck", type: "CRITICAL", content: "Unable to fetch Site ID.")
                    return
                }
                
                let listItemsUrl = URL(string: "https://graph.microsoft.com/v1.0/sites/\(siteId)/lists/Devices/items?$expand=fields")!
                Logger.shared.log(position: "GraphService.remoteUpdateCheckerCheck", type: "DEBUG", content: "GET \(listItemsUrl.absoluteString)")
                var listRequest = URLRequest(url: listItemsUrl)
                listRequest.httpMethod = "GET"
                listRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                let task = URLSession.shared.dataTask(with: listRequest) { data, response, error in
                    Logger.shared.log(position: "GraphService.remoteUpdateCheckerCheck", type: "DEBUG", content: "Response status=\((response as? HTTPURLResponse)?.statusCode ?? -1), bytes=\(data?.count ?? 0)")
                    guard let data = data, error == nil else {
                        Logger.shared.log(position: "GraphService.remoteUpdateCheckerCheck", type: "CRITICAL", content: "Error fetching list entries: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let items = json["value"] as? [[String: Any]] {
                        Logger.shared.log(position: "GraphService.remoteUpdateCheckerCheck", type: "DEBUG", content: "Fetched \(items.count) items. Filtering for remote requests...")
                        
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
                        
                        Logger.shared.log(position: "GraphService.remoteUpdateCheckerCheck", type: "DEBUG", content: "Found \(matchingItems.count) matching remote requests")
                        
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
        Logger.shared.log(position: "GraphService.handleRemoteUpdate", type: "DEBUG", content: "Paused checker. Scheduling update tasks...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: "isRemoteUpdate")
                Logger.shared.log(position: "GraphService.handleRemoteUpdate", type: "DEBUG", content: "Starting update manager (remoteRequested=true)")
                UpdateManager.shared.start(remoteRequested: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                    let tsFormatter = DateFormatter()
                    tsFormatter.dateFormat = "dd.MM.yyyy - HH:mm"
                    self.lastUpdateTimestamp = tsFormatter.string(from: Date())
                    Logger.shared.log(position: "GraphService.handleRemoteUpdate", type: "DEBUG", content: "Update finished. Marking status idle and resuming checker")
                    self.updateRemoteStatus(status: "idle", remote: false)
                    self.startRemoteUpdateChecker()
                }
            }
        }
    }
    
    //MARK: FILES PROCESS
    
    func fetchSubfolderContentsAndDownload(fromMacOSFolder folderName: String, success: @escaping () -> Void, failure: @escaping () -> Void) {
        
        Logger.shared.log(position: "GraphService.fetchSubfolderContentsAndDownload", type: "DEBUG", content: "Downloading remote subfolders for macOS folder: \(folderName)")
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
                    remoteFolder: "standard",
                    localFolder: "standard",
                    accessToken: accessToken,
                    success: { group.leave() },
                    failure: { group.leave() }
                )

                group.enter()
                self._downloadUserSubfolder(
                    userFolder: userFolder,
                    remoteFolder: "custom",
                    localFolder: "custom",
                    accessToken: accessToken,
                    success: { group.leave() },
                    failure: { group.leave() }
                )

                group.notify(queue: .main) {
                    Logger.shared.log(position: "GraphService.fetchSubfolderContentsAndDownload", type: "DEBUG", content: "Finished downloading both subfolders")
                    success()
                }
            }
        }
    }

    private func _downloadUserSubfolder(
        userFolder: String,
        remoteFolder: String,   // standard | custom
        localFolder: String,    // base | custom
        accessToken: String,
        success: @escaping () -> Void,
        failure: @escaping () -> Void
    ) {
        Logger.shared.log(
            position: "GraphService._downloadUserSubfolder",
            type: "DEBUG",
            content: "Downloading remoteFolder='\(remoteFolder)' for user='\(userFolder)'"
        )

        resolveUserMacOSFolderId(accessToken: accessToken, username: userFolder) { userFolderId in
            guard let userFolderId else {
                Logger.shared.log(
                    position: "GraphService._downloadUserSubfolder",
                    type: "CRITICAL",
                    content: "User folder ID not resolved"
                )
                failure()
                return
            }

            self.getSiteId(accessToken: accessToken, siteId: self.siteId, domain: self.sharepointDomain) { siteId in
                guard let siteId else { failure(); return }

                self.getDriveId(accessToken: accessToken, siteId: siteId) { driveId in
                    guard let driveId else { failure(); return }

                    // 1️⃣ children von Admin (→ standard / custom)
                    let userChildrenUrl =
                    "https://graph.microsoft.com/v1.0/sites/\(siteId)/drives/\(driveId)/items/\(userFolderId)/children"

                    Logger.shared.log(
                        position: "GraphService._downloadUserSubfolder",
                        type: "DEBUG",
                        content: "GET \(userChildrenUrl)"
                    )

                    var request = URLRequest(url: URL(string: userChildrenUrl)!)
                    request.httpMethod = "GET"
                    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

                    URLSession.shared.dataTask(with: request) { data, _, _ in
                        guard
                            let data,
                            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                            let folders = json["value"] as? [[String: Any]],
                            let remoteFolderEntry = folders.first(where: { ($0["name"] as? String) == remoteFolder }),
                            let remoteFolderId = remoteFolderEntry["id"] as? String
                        else {
                            Logger.shared.log(
                                position: "GraphService._downloadUserSubfolder",
                                type: "CRITICAL",
                                content: "Remote folder '\(remoteFolder)' not found"
                            )
                            failure()
                            return
                        }

                        // 2️⃣ children von standard | custom (→ DATEIEN!)
                        let filesUrl =
                        "https://graph.microsoft.com/v1.0/sites/\(siteId)/drives/\(driveId)/items/\(remoteFolderId)/children"

                        Logger.shared.log(
                            position: "GraphService._downloadUserSubfolder",
                            type: "DEBUG",
                            content: "GET \(filesUrl)"
                        )

                        var filesRequest = URLRequest(url: URL(string: filesUrl)!)
                        filesRequest.httpMethod = "GET"
                        filesRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

                        URLSession.shared.dataTask(with: filesRequest) { data2, _, _ in
                            guard
                                let data2,
                                let json2 = try? JSONSerialization.jsonObject(with: data2) as? [String: Any],
                                let files = json2["value"] as? [[String: Any]]
                            else {
                                failure()
                                return
                            }

                            Logger.shared.log(
                                position: "GraphService._downloadUserSubfolder",
                                type: "DEBUG",
                                content: "Found \(files.count) files in \(remoteFolder)"
                            )

                            let appSupport = FileManager.default.urls(
                                for: .applicationSupportDirectory,
                                in: .userDomainMask
                            ).first!

                            let localDir = appSupport
                                .appendingPathComponent("com.mbuettner.SignatureManager/onlineSignatures/\(localFolder)")

                            try? FileManager.default.createDirectory(
                                at: localDir,
                                withIntermediateDirectories: true
                            )

                            let group = DispatchGroup()

                            for file in files {
                                guard
                                    let fileId = file["id"] as? String,
                                    let fileName = file["name"] as? String
                                else { continue }

                                let fileUrl =
                                "https://graph.microsoft.com/v1.0/sites/\(siteId)/drives/\(driveId)/items/\(fileId)/content"

                                Logger.shared.log(
                                    position: "GraphService._downloadUserSubfolder",
                                    type: "DEBUG",
                                    content: "Downloading file: \(fileName)"
                                )

                                var fileRequest = URLRequest(url: URL(string: fileUrl)!)
                                fileRequest.httpMethod = "GET"
                                fileRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

                                group.enter()
                                URLSession.shared.dataTask(with: fileRequest) { fileData, _, _ in
                                    defer { group.leave() }
                                    guard let fileData else { return }
                                    try? fileData.write(to: localDir.appendingPathComponent(fileName))
                                }.resume()
                            }

                            group.notify(queue: .main) {
                                Logger.shared.log(
                                    position: "GraphService._downloadUserSubfolder",
                                    type: "DEBUG",
                                    content: "Finished downloading \(remoteFolder)"
                                )
                                success()
                            }
                        }.resume()
                    }.resume()
                }
            }
        }
    }
    
    func uploadContentsToRemote(
        remoteAppDataUserFolder: String,
        specificFile: URL,
        success: @escaping () -> Void,
        failure: @escaping () -> Void
    ) {
        Logger.shared.log(position: "GraphService.uploadContentsToRemote", type: "DEBUG", content: "Uploading file to remote: \(specificFile.lastPathComponent) for userFolder: \(remoteAppDataUserFolder)")
        checkConnection { isAvailable, accessToken in
            guard isAvailable, let accessToken else { failure(); return }

            self.resolveUserMacOSFolderId(accessToken: accessToken, username: remoteAppDataUserFolder) { userFolderId in
                guard let userFolderId else { failure(); return }

                self.getSiteId(accessToken: accessToken, siteId: self.siteId, domain: self.sharepointDomain) { siteId in
                    guard let siteId else { failure(); return }

                    self.getDriveId(accessToken: accessToken, siteId: siteId) { driveId in
                        guard let driveId else { failure(); return }

                        Logger.shared.log(position: "GraphService.uploadContentsToRemote", type: "DEBUG", content: "Preparing PUT upload URL")
                        let uploadUrl =
                        "https://graph.microsoft.com/v1.0/sites/\(siteId)/drives/\(driveId)/items/\(userFolderId):/\(specificFile.lastPathComponent):/content"
                        Logger.shared.log(position: "GraphService.uploadContentsToRemote", type: "DEBUG", content: "PUT \(uploadUrl)")
                        var request = URLRequest(url: URL(string: uploadUrl)!)
                        request.httpMethod = "PUT"
                        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                        request.httpBody = try? Data(contentsOf: specificFile)

                        URLSession.shared.dataTask(with: request) { data, response, error in
                            if let http = response as? HTTPURLResponse {
                                Logger.shared.log(position: "GraphService.uploadContentsToRemote", type: "DEBUG", content: "Upload response status=\(http.statusCode)")
                            }
                            if error != nil { failure() }
                            else {
                                Logger.shared.log(position: "GraphService.uploadContentsToRemote", type: "DEBUG", content: "Upload finished successfully")
                                success()
                            }
                        }.resume()
                    }
                }
            }
        }
    }
    
    func uploadCustomSignature(
        userFolder: String,
        localFileURL: URL,
        desiredName: String,
        success: @escaping (String) -> Void,
        failure: @escaping () -> Void
    ) {
        getValidAccessToken { accessToken in
            guard let accessToken else { failure(); return }

            let finalName = desiredName + ".html"

            self.resolveUserMacOSFolderId(
                accessToken: accessToken,
                username: userFolder
            ) { userFolderId in
                guard let userFolderId else { failure(); return }

                self.getSiteId(
                    accessToken: accessToken,
                    siteId: self.siteId,
                    domain: self.sharepointDomain
                ) { siteId in
                    guard let siteId else { failure(); return }

                    self.getDriveId(
                        accessToken: accessToken,
                        siteId: siteId
                    ) { driveId in
                        guard let driveId else { failure(); return }

                        let uploadPath =
                        "https://graph.microsoft.com/v1.0/sites/\(siteId)/drives/\(driveId)/items/\(userFolderId):/custom/\(finalName):/content"

                        var request = URLRequest(url: URL(string: uploadPath)!)
                        request.httpMethod = "PUT"
                        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                        request.httpBody = try? Data(contentsOf: localFileURL)

                        URLSession.shared.dataTask(with: request) { _, response, error in
                            if
                                error == nil,
                                let http = response as? HTTPURLResponse,
                                (200...299).contains(http.statusCode)
                            {
                                success(finalName)
                            } else {
                                failure()
                            }
                        }.resume()
                    }
                }
            }
        }
    }
    
    
    
    /*private func resolveAppDataFolderId(
        accessToken: String,
        completion: @escaping (String?) -> Void
    ) {
        getSiteId(accessToken: accessToken, sitePath: siteId, domain: sharepointDomain) { siteId in
            guard let siteId else { completion(nil); return }

            self.getDriveId(accessToken: accessToken, siteId: siteId) { driveId in
                guard let driveId else { completion(nil); return }

                let path = "\(self.baseFolderName)/\(self.AppDataFolder)"
                let url = URL(string:
                    "https://graph.microsoft.com/v1.0/sites/\(siteId)/drives/\(driveId)/root:/\(path)"
                )!

                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

                URLSession.shared.dataTask(with: request) { data, _, _ in
                    guard
                        let data,
                        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let id = json["id"] as? String
                    else {
                        completion(nil)
                        return
                    }

                    completion(id)
                }.resume()
            }
        }
    }*/
    
    //MARK: RESOLVE
    
    // Normalizes a username by removing spaces, e.g. "Anita Bourquin" -> "AnitaBourquin"
    private func normalizedUsername(_ raw: String) -> String {
        raw.replacingOccurrences(of: " ", with: "")
    }
    
    private func resolveUserMacOSFolderId(
        accessToken: String,
        username: String,
        completion: @escaping (String?) -> Void
    ) {
        Logger.shared.log(
            position: "GraphService.resolveUserMacOSFolderId",
            type: "DEBUG",
            content: "Resolving user macOS folder id for username: \(username)"
        )
        
        let username = self.normalizedUsername(username)
        Logger.shared.log(
            position: "GraphService.resolveUserMacOSFolderId",
            type: "DEBUG",
            content: "Using normalized username: \(username)"
        )

        getSiteId(accessToken: accessToken, siteId: siteId, domain: sharepointDomain) { siteId in
            guard let siteId else { completion(nil); return }

            self.getDriveId(accessToken: accessToken, siteId: siteId) { driveId in
                guard let driveId else { completion(nil); return }

                // 🔴 HIER WAR DER FEHLER → Documents fehlte
                let fullPath =
                    "\(self.baseFolderName)/" +        // General
                    "\(self.AppDataFolder)/" +         // SignatureManager
                    "RemoteData/macOS/" +
                    username

                Logger.shared.log(
                    position: "GraphService.resolveUserMacOSFolderId",
                    type: "DEBUG",
                    content: "Resolving path: \(fullPath)"
                )

                let url = URL(string:
                    "https://graph.microsoft.com/v1.0/sites/\(siteId)/drives/\(driveId)/root:/\(fullPath)"
                )!

                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

                URLSession.shared.dataTask(with: request) { data, response, _ in
                    Logger.shared.log(
                        position: "GraphService.resolveUserMacOSFolderId",
                        type: "DEBUG",
                        content: "Response status=\((response as? HTTPURLResponse)?.statusCode ?? -1), bytes=\(data?.count ?? 0)"
                    )

                    guard
                        let data,
                        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let id = json["id"] as? String
                    else {
                        completion(nil)
                        return
                    }

                    Logger.shared.log(
                        position: "GraphService.resolveUserMacOSFolderId",
                        type: "DEBUG",
                        content: "Resolved user folder id: \(id)"
                    )

                    completion(id)
                }.resume()
            }
        }
    }
}

private extension String {
    func base64URLDecoded() -> String {
        var s = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while s.count % 4 != 0 { s += "=" }
        return s
    }
}











