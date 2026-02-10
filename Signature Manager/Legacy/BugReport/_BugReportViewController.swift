//
//  RBViewController.swift
//  DevTools 2
//
//  Created by Marc Büttner on 28.02.24.
//

/*import Cocoa
import Foundation

class BugReportViewController: NSViewController {
    
    @IBOutlet weak var devToolsVersionTexField: NSTextField!
    @IBOutlet weak var macOSVersionTextField: NSTextField!
    @IBOutlet weak var exceptionPointTextField: NSTextField!
    @IBOutlet weak var messageTextField: NSScrollView!
    @IBOutlet weak var includeSystemLogsCheckBox: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
          let _ = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            devToolsVersionTexField.stringValue = version
        }
        
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        macOSVersionTextField.stringValue = versionString
        
        if let exceptionPoint = UserDefaults.standard.string(forKey: "exceptionPoint") {
            exceptionPointTextField.stringValue = exceptionPoint
        }
    }
    
    @IBAction func submit(_ sender: Any) {
        if let textView = messageTextField.documentView as? NSTextView {
            createGitHubAPIIssue(devToolsVersion: devToolsVersionTexField.stringValue,
                                 macOSVersion: macOSVersionTextField.stringValue,
                                 exception: exceptionPointTextField.stringValue,
                                 bugDescription: textView.string)
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 11) {
            self.view.window?.close()
        }
    }
    
    func createGitHubAPIIssue(devToolsVersion: String, macOSVersion: String, exception: String, bugDescription: String) {
        guard let ghToken = Bundle.main.infoDictionary?["GHApiToken"] as? String else {
            print("GitHub API token not found in info.plist")
            Logger.shared.log(position: "REPORT.ISSUE", type:"CRITICAL", content: "Cant acess to GitHub API token via plist!")
            return
        }
        
        let token = ghToken
        let username = "VegilifeAG"
        let repository = "AppleSignatureManager"
        let title = "SMX Error: \(exception)"
        
        var body = """
        <b>DevTools2 Version:</b> \(devToolsVersion)
        <b>macOS Version:</b> \(macOSVersion)
        
        <b>Exception:</b> \(exception)
        
        <b>Advanced Error Details:</b> \(bugDescription)
        """
        
        let labels = ["bug"]
        let url = URL(string: "https://api.github.com/repos/\(username)/\(repository)/issues")!
        
        if includeSystemLogsCheckBox.state == .on {
            uploadLogFile(token: token) { [weak self] logFileUrl in
                if let logFileUrl = logFileUrl {
                    body += "\n\n[Log file](" + logFileUrl + ")"
                    self?.postIssueRequest(url: url, token: token, title: title, body: body, labels: labels)
                } else {
                    DispatchQueue.main.async {
                        self?.showErrorSheet()
                    }
                }
            }
        } else {
            postIssueRequest(url: url, token: token, title: title, body: body, labels: labels)
        }
    }
    
    func getLogFilePath() -> String? {
        let fileManager = FileManager.default
        if let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let logFilePath = appSupportDir.appendingPathComponent("Signature Manager/app.log").path
            return logFilePath
        }
        return nil
    }
    
    func uploadLogFile(token: String, completion: @escaping (String?) -> Void) {
        guard let filePath = getLogFilePath() else {
            print("Log file path not found.")
            Logger.shared.log(position: "REPORT.ISSUE", type:"CRITICAL", content: "Log file path not found.")
            completion(nil)
            return
        }
        
        if !FileManager.default.fileExists(atPath: filePath) {
            print("Log file does not exist at path: \(filePath)")
            Logger.shared.log(position: "REPORT.ISSUE", type:"CRITICAL", content: "Log flie does not exist at path: \(filePath)!")
            completion(nil)
            return
        }
        
        do {
            let fileContent = try String(contentsOfFile: filePath, encoding: .utf8)
            
            let gistUrl = URL(string: "https://api.github.com/gists")!
            var request = URLRequest(url: gistUrl)
            request.httpMethod = "POST"
            request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            
            let json: [String: Any] = [
                "description": "App log file",
                "public": false,
                "files": [
                    "app.log": ["content": fileContent]
                ]
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("File upload failed: \(error.localizedDescription)")
                    Logger.shared.log(position: "REPORT.ISSUE", type:"CRITICAL", content: "File upload failed: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                if let data = data, let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let gistUrl = jsonResponse["html_url"] as? String {
                        completion(gistUrl)
                    } else {
                        print("Failed to find 'html_url' in response.")
                        Logger.shared.log(position: "REPORT.ISSUE", type:"CRITICAL", content: "Failed to find 'html_url' in response.")
                        completion(nil)
                    }
                } else {
                    print("Failed to parse response from Gist API.")
                    Logger.shared.log(position: "REPORT.ISSUE", type:"CRITICAL", content: "Failled to parse response from Gist API.")
                    completion(nil)
                }
            }
            
            task.resume()
        } catch {
            print("Failed to read the log file: \(error.localizedDescription)")
            Logger.shared.log(position: "REPORT.ISSUE", type:"CRITICAL", content: "Failed to read the log file: \(error.localizedDescription).")
            completion(nil)
        }
    }
    
    
    func postIssueRequest(url: URL, token: String, title: String, body: String, labels: [String]) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        
        let json: [String: Any] = ["title": title, "body": body, "labels": labels]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            request.httpBody = jsonData
        } catch {
            print("Failed to serialize JSON: \(error.localizedDescription)")
            Logger.shared.log(position: "REPORT.ISSUE", type:"CRITICAL", content: "Failed to serialize JSON: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.showErrorSheet()
            }
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request failed with error: \(error.localizedDescription)")
                Logger.shared.log(position: "REPORT.ISSUE", type:"CRITICAL", content: "Request failed with error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showErrorSheet()
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Code: \(httpResponse.statusCode)")
                
                if !(200...299).contains(httpResponse.statusCode) {
                    print("GitHub API returned error status: \(httpResponse.statusCode)")
                    Logger.shared.log(position: "REPORT.ISSUE.GITHUB.API", type:"CRITICAL", content: "GiHub API returned error status: \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        self.showErrorSheet()
                    }
                    return
                }
            }
            
            guard let data = data else {
                print("No data received from GitHub.")
                Logger.shared.log(position: "REPORT.ISSUE", type:"CRITICAL", content: "No data received from GitHub.")
                return
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let issueUrl = jsonResponse?["html_url"] as? String {
                    UserDefaults.standard.set(issueUrl, forKey: "issueUrl")
                    DispatchQueue.main.async {
                        self.showSuccessSheet()
                    }
                } else {
                    print("Failed to get issue URL from response.")
                    Logger.shared.log(position: "REPORT.ISSUE.PARSER", type:"CRITICAL", content: "Fairly sure this is a bug, but I'm not sure how to fix it.")
                    DispatchQueue.main.async {
                        self.showErrorSheet()
                    }
                }
            } catch {
                print("Failed to parse JSON response: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    func showSuccessSheet() {
        let mainStoryboard = NSStoryboard(name: "Main", bundle: nil)
        if let settingsViewController = mainStoryboard.instantiateController(withIdentifier: "ThankYouSheet") as? NSViewController {
            if let currentWindow = NSApp.mainWindow {
                let sheetWindow = NSWindow(contentViewController: settingsViewController)
                currentWindow.beginSheet(sheetWindow) { response in
                }
            }
        }
    }
    
    func showErrorSheet() {
        let mainStoryboard = NSStoryboard(name: "Main", bundle: nil)
        if let settingsViewController = mainStoryboard.instantiateController(withIdentifier: "ThankYouSheetError") as? NSViewController {
            if let currentWindow = NSApp.mainWindow {
                let sheetWindow = NSWindow(contentViewController: settingsViewController)
                currentWindow.beginSheet(sheetWindow) { response in
                }
            }
        }
    }
}
*/
