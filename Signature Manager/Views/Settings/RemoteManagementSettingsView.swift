//
//  SettingsView.swift
//  Signature Manager
//
//  Created by Marc Büttner on 21.08.25.
//

import SwiftUI


struct RemoteManagementSettingsView: View {
    @AppStorage("remote.profileVersion") private var profileVersion: String = ""
    @AppStorage("remote.managementName") private var managementName: String = ""
    @AppStorage("graph.clientId") private var clientId: String = ""
    @AppStorage("graph.tenantId") private var tenantId: String = ""
    @AppStorage("graph.clientSecret") private var clientSecret: String = ""
    @AppStorage("graph.sharepointDomain") private var sharepointDomain: String = ""
    @AppStorage("graph.siteId") private var siteId: String = ""
    @AppStorage("graph.baseFolderName") private var baseFolderName: String = ""
    @AppStorage("graph.AppDataFolder") private var AppDataFolder: String = ""
    @AppStorage("app.remoteAddress") private var remoteAddress: String = ""
    @AppStorage("app.remoteApiKey") private var remoteApiKey: String = ""
    @State private var showConnectSheet: Bool = false
    
    var body: some View {
        ScrollView {
            GroupBox {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "gear.badge")
                        .font(.system(size: 28, weight: .regular))
                        .frame(width: 36, height: 36)
                        .foregroundStyle(.secondary)
                        .alignmentGuide(.firstTextBaseline) { d in d[.bottom] }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("MANAGEMENT_PROFILE")
                                .font(.headline)
                            Spacer()
                            /*Button(action: { showConnectSheet = true }) {
                                Text("UPDATE")
                            }*/
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("VERSION: \(profileVersion)")
                            Text("MANAGEMENT: \(managementName)")
                            if (clientId != "" && clientSecret != "" && tenantId != "" && sharepointDomain != "" && siteId != "" && baseFolderName != "" && AppDataFolder != "") {
                                Text("ACTIVATED_CLOUD_SERVICES: MICROSOFT365")
                            }
                        }
                    }
                }
                .padding(8)
            }
            .cardStyle()

            Spacer(minLength: 15)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SERVER_ADDRESS")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("SERVER_ADDRESS_EXMAPLE", text: $remoteAddress)
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                        Text("SERVER_ADDRESS_HTTPS_DISCLAIMER")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer(minLength: 1)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("API_KEY")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        SecureField("API_KEY_EXAMPLE", text: $remoteApiKey)
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                    }
                    
                    Spacer(minLength: 1)
                    
                    HStack {
                        Spacer()
                        Button(action: { showConnectSheet = true }) {
                            Text("CHECK")
                        }
                    }
                }
                .padding(8)
            }
            .cardStyle()
            
            Spacer(minLength: 15)

        }
        .padding(.top)
        .sheet(isPresented: $showConnectSheet, onDismiss: {
            completeCheckout()
        }) {
            RemoteConfigSheetView {
                showConnectSheet = false
            }
        }
        .navigationTitle("REMOTE_MANAGEMENT")
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title).fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 20)
    }
    
    private func completeCheckout() {
        // TODO: Implement completion logic for remote config update
    }
}


private extension View {
    func cardStyle() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}


#Preview {
    RemoteManagementSettingsView()
}

