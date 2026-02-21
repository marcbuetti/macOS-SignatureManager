//
//  RemoteConfigSheetView.swift
//  Signature Manager
//
//  Created by Marc Büttner on 17.09.25.
//

import SwiftUI


private struct RemoteConfig: Decodable {
    let clientId: String
    let tenantId: String
    let clientSecret: String
    let sharepointDomain: String
    let siteId: String
    let baseFolderName: String
    let AppDataFolder: String
    let profileVersion: String
    let managementName: String
    
    
    private enum CodingKeys: String, CodingKey {
        case clientId, tenantId, clientSecret, sharepointDomain, siteId, baseFolderName, AppDataFolder, profileVersion, managementName
    }
}


private enum AutoPhase: Equatable {
    case idle
    case waitingForServer
    case downloading
    case installing
    case verifying
    case completed
    case failed(String)
}


struct RemoteConfigSheetView: View {
    var onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("graph.clientId") private var clientId: String = ""
    @AppStorage("graph.tenantId") private var tenantId: String = ""
    @AppStorage("graph.clientSecret") private var clientSecret: String = ""
    @AppStorage("graph.sharepointDomain") private var sharepointDomain: String = ""
    @AppStorage("graph.siteId") private var siteId: String = ""
    @AppStorage("graph.baseFolderName") private var baseFolderName: String = ""
    @AppStorage("graph.AppDataFolder") private var AppDataFolder: String = ""
    @AppStorage("remote.profileVersion") private var profileVersion: String = ""
    @AppStorage("remote.managementName") private var managementName: String = ""
    @AppStorage("app.remoteAddress") private var remoteAddress: String = ""
    @AppStorage("app.remoteApiKey") private var remoteApiKey: String = ""
    
    @State private var phase: AutoPhase = .idle
    
    var body: some View {
        VStack(spacing: 18) {
            Image("custom.gearshape.arrow.trianglehead.2.clockwise.rotate.90.badge.arrow.down")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90)
            
            Text("REMOTE_MANAGEMENT")
                .font(.title2.weight(.semibold))
            
            Text(statusText)
                .foregroundStyle(phaseIsError ? .red : .secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            
            if phase != .completed {
                ProgressView().scaleEffect(0.5)
            }
            
            HStack(spacing: 10) {
                if case .failed = phase {
                    Button("CLOSE") {
                        dismiss()
                    }
                    Button("RETRY") {
                        startRemoteConfiguration()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(.top, 6)
        }
        .frame(minWidth: 420, minHeight: 240)
        .padding()
        .onChange(of: phase) { oldValue, newValue in
            if case .completed = newValue {
                onComplete()
            }
        }
        .onAppear { startRemoteConfiguration() }
    }
    
    private var phaseIsError: Bool {
        if case .failed = phase { return true }
        return false
    }
    
    private var statusText: String {
        switch phase {
        case .idle:
            return String(localized: "PREPARING")
        case .waitingForServer:
            return String(localized: "WAITING_FOR_LICENSE_SERVER")
        case .downloading:
            return String(localized: "DOWNLOADING_CONFIGURATION_PROFILE") 
        case .installing:
            return String(localized: "INSTALLING_CONFIGURATION_PROFILE (\(profileVersion)…")
        case .verifying:
            return String(localized: "VERIFYING")
        case .completed:
            return String(localized: "COMPLETED") 
        case .failed(let message):
            return String(localized: "ERROR_OCCURRED \(message)")
        }
    }
    
    private func startRemoteConfiguration() {
        phase = .waitingForServer
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
            let urlString = "https://\(remoteAddress)?apiKey=\(remoteApiKey)"
            guard let url = URL(string: urlString) else {
                LogManager.shared.log(.critical, "Invalid URL for remote config", fileID: #fileID, function: #function, line: #line)
                phase = .failed("Invalid URL")
                return
            }
            
            phase = .downloading
            
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    LogManager.shared.log(.critical, "Remote config HTTP status: \(http.statusCode)", fileID: #fileID, function: #function, line: #line)
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
                sharepointDomain = config.sharepointDomain
                siteId = config.siteId
                baseFolderName = config.baseFolderName
                AppDataFolder = config.AppDataFolder
                profileVersion = config.profileVersion
                managementName = config.managementName
                
                
                phase = .installing
                try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s
                
                phase = .verifying
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s
                
                phase = .completed
                
            } catch {
                LogManager.shared.log(.critical, "Remote config error: \(error.localizedDescription)", fileID: #fileID, function: #function, line: #line)
                phase = .failed(error.localizedDescription)
            }
        }
    }
}

#Preview {
    RemoteConfigSheetView(onComplete: {})
}
