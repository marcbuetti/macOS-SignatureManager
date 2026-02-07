//
//  ReleaseNotesViewController.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 10.09.24.
//

/*import Cocoa

class ReleaseNotesViewController: NSViewController {
    
    
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var releaseNotesLabel: NSTextField!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var errorTriangle: NSImageView!
    @IBOutlet weak var errorTitleLabel: NSTextField!
    @IBOutlet weak var errorLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let _ = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            versionLabel.stringValue = "Neuerungen - Version: \(version)"
        }
        loader.startAnimation(self)
        fetchLatestReleaseNotes(username: "VegilifeAG", repository: "AppleSignatureManager")
    }
    
    func fetchLatestReleaseNotes(username: String, repository: String) {
        let url = URL(string: "https://api.github.com/repos/\(username)/\(repository)/releases/latest")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    self.errorTriangle.isHidden = false
                    self.errorTitleLabel.isHidden = false
                    self.errorLabel.isHidden = false
                    self.loader.isHidden = true
                    self.loader.stopAnimation(self)
                }
                print("Server error!")
                return
            }
            
            if let mimeType = httpResponse.mimeType, mimeType == "application/json",
               let data = data {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       var releaseNotes = jsonResponse["body"] as? String {
                        // Release Notes auf 10 Zeichen pro Zeile beschränken
                        releaseNotes = releaseNotes.enumerated().reduce("") { (result, next) -> String in
                            return result + String(next.element)
                        }
                        
                        DispatchQueue.main.async {
                            self.loader.stopAnimation(self)
                            self.loader.isHidden = true
                            self.releaseNotesLabel.stringValue = releaseNotes
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.errorTriangle.isHidden = false
                            self.errorTitleLabel.isHidden = false
                            self.errorLabel.isHidden = false
                            self.loader.isHidden = true
                            self.loader.stopAnimation(self)
                            print("No release notes found for the latest release.")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.errorTriangle.isHidden = false
                        self.errorTitleLabel.isHidden = false
                        self.errorLabel.isHidden = false
                        self.loader.isHidden = true
                        self.loader.stopAnimation(self)
                        print("Error parsing response: \(error)")
                    }
                }
            }
        }
        
        task.resume()
    }

    
    @IBAction func close(_ sender: Any) {
        self.view.window?.close()
    }
    
    
}

*/
