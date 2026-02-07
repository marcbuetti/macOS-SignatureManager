//
//  RemoteConfigSheetView.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 17.09.25.
//

import SwiftUI


private struct RemoteConfig: Decodable {
    let clientId: String
    let tenantId: String
    let clientSecret: String
    let sitePath: String
    let sharepointDomain: String
    let smaSyncList: String
    let AppDataId: String
    let profileVersion: String
    
    
    private enum CodingKeys: String, CodingKey {
        case clientId, tenantId, clientSecret, sitePath, sharepointDomain, smaSyncList, AppDataId, profileVersion
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
    @AppStorage("graph.sitePath") private var sitePath: String = ""
    @AppStorage("graph.sharepointDomain") private var sharepointDomain: String = ""
    @AppStorage("graph.smaSyncList") private var smaSyncList: String = ""
    @AppStorage("graph.AppDataId") private var AppDataId: String = ""
    @AppStorage("remote.profileVersion") private var profileVersion: String = ""
    
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
                        startAutodiscover()
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
        .onAppear { startAutodiscover() }
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
    
    private func startAutodiscover() {
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
