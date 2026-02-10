//
//  SMApiService.swift
//  Signature Manager
//
//  Created by Marc Büttner on 07.02.26.
//

import SwiftUI

class SMApiService {
    private func getRemoteConfiguration() {
        phase = .waitingForServer
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
            let urlString = "https://sm2license.vegilife.ch?apiKey=LSDKJFGHSDLKJFGHLDSKFJGH09438UT2OREWHGJ"
            guard let url = URL(string: urlString) else {
                Logger.shared.log(position: "RemoteConfigSheetView.startAutodiscover", type: "WARNING", content: "Invalid URL for remote config")
                phase = .failed("Invalid URL")
                return
            }
            
            phase = .downloading
            
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    Logger.shared.log(position: "RemoteConfigSheetView.startAutodiscover", type: "WARNING", content: "Remote config HTTP status: \(http.statusCode)")
                    phase = .failed("HTTP \(http.statusCode)")
                    return
                }
                
                let decoder = JSONDecoder()
                let config = try decoder.decode(RemoteConfig.self, from: data)
                phase = .downloading
                try? await Task.sleep(nanoseconds: 300_000_000)
                
                clientId = config.clientId
                tenantId = config.tenantId
                clientSecret = config.clientSecret
                sitePath = config.sitePath
                sharepointDomain = config.sharepointDomain
                smaSyncList = config.smaSyncList
                AppDataId = config.AppDataId
                profileVersion = config.profileVersion
                
                phase = .installing
                try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s
                
                phase = .verifying
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s
                
                phase = .completed
                
            } catch {
                Logger.shared.log(position: "RemoteConfigSheetView.startAutodiscover", type: "CRITICAL", content: "Remote config error: \(error.localizedDescription)")
                phase = .failed(error.localizedDescription)
            }
        }
    }
}
