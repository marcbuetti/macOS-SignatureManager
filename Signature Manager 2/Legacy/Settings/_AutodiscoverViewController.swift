//
//  AutodiscoverViewController.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 06.01.25.
//

/*import Cocoa

class AutodiscoverViewController: NSViewController {
    
    var onComplete: (() -> Void)?
    
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var progressLabel: NSTextField!
    @IBOutlet weak var button: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        autodiscover()
    }
    
    func autodiscover() {
        DispatchQueue.main.async {
            self.progressBar.isIndeterminate = true
            self.progressBar.startAnimation(self)
            self.progressLabel.stringValue = "Warten auf Lizenzserver..."
        }
        
        let url = "https://sm2license.vegilife.ch?apiKey=LSDKJFGHSDLKJFGHLDSKFJGH09438UT2OREWHGJ"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchRemoteData(from: url) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        print("Client data saved successfully.")
                        // Access saved data
                        let clientId = UserDefaults.standard.string(forKey: "clientId")
                        let tenantId = UserDefaults.standard.string(forKey: "tenantId")
                        let clientSecret = UserDefaults.standard.string(forKey: "clientSecret")
                        let licensedOrganisationName = UserDefaults.standard.string(forKey: "licensedForName")
                        print("clientId: \(clientId ?? "")")
                        print("tenantId: \(tenantId ?? "")")
                        print("clientSecret: \(clientSecret ?? "")")
                        print("licensedForName: \(licensedOrganisationName ?? "")")
                        
                        self.progressLabel.stringValue = "Lizensieren..."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.progressLabel.stringValue = "Verifizieren..."
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.progressLabel.stringValue = "Abgeschlossen."
                                self.progressBar.stopAnimation(self)
                                self.progressBar.isIndeterminate = false
                                self.progressBar.doubleValue = 100
                                self.view.window?.close()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    self.onComplete?()
                                }
                            }
                        }
                    case .failure(let error):
                        print("Error fetching client data: \(error)")
                        self.progressLabel.stringValue = "Error occurred: \(error.localizedDescription)"
                        self.progressBar.stopAnimation(self)
                    }
                }
            }
        }
    }
    
    func fetchRemoteData(from url: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let requestURL = URL(string: url) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: requestURL) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                }
                return
            }
            
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                    DispatchQueue.main.async {
                        self.progressLabel.stringValue = "Downloading configuration..."
                        SMX.setAppStringVar(key: "clientId", value: jsonObject["clientId"])
                        SMX.setAppStringVar(key: "tenantId", value: jsonObject["tenantId"])
                        SMX.setAppStringVar(key: "clientSecret", value: jsonObject["clientSecret"])
                        SMX.setAppStringVar(key: "licensedForName", value: jsonObject["licensedOrganisationName"], forceSync: true)
                        
                        self.progressLabel.stringValue = "Installing configuration..."
                        completion(.success(()))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "Invalid JSON Format", code: 0, userInfo: nil)))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
    
    @IBAction func button(_ sender: Any) {
        DispatchQueue.main.async {
            self.view.window?.close()
        }
    }
}
*/
