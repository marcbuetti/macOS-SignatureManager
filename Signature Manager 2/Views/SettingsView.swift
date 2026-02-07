//
//  SettingsView.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 21.08.25.
//

import SwiftUI


struct SettingsView: View {
    @StateObject var launchAtLogin = LaunchAtLoginManager()
    @AppStorage("app.updateSignaturesWithStart") private var updateSignaturesWithStart: Bool = false
    @AppStorage("app.showProcessByUpdatingSignatures") private var showProcessDuringUpdate: Bool = false
    @AppStorage("app.showProcessMenuBarLiveActivity") private var showProcessMenuBarLiveActivity: Bool = false
    @AppStorage("remote.profileVersion") private var profileVersion: String = ""
    
    @State private var selectedOption: Int = 0
    @State private var showConnectSheet: Bool = false
    
    init() {
        if let saved = UserDefaults.standard.value(forKey: "selectedOption") as? Int {
            _selectedOption = State(initialValue: saved)
        }
    }
    
    @EnvironmentObject var menuBarLiveActivity: MenuBarLiveActivity

    var body: some View {
        ScrollView {
            sectionHeader(icon: "gear", title: String(localized: "GENERAL"))
            
            GroupBox {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Text("LAUNCH_AT_LOGIN")
                        Spacer()
                        Toggle("", isOn: $launchAtLogin.isEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: launchAtLogin.isEnabled) { oldValue, newValue in
                            launchAtLogin.toggleLaunchAtLogin(newValue)
                        }
                    }
                    .padding(8)

                    Divider()

                    HStack(spacing: 12) {
                        Text("UPDATE_SIGNATURES_ON_APP_LAUNCH")
                        Spacer()
                        Toggle("", isOn: $updateSignaturesWithStart)
                            .toggleStyle(.switch)
                            .accessibilityLabel(String(localized: "UPDATE_SIGNATURES_ON_APP_LAUNCH"))
                    }
                    .padding(8)
                }
            }
            .cardStyle()

            Spacer(minLength: 30)

            sectionHeader(icon: "swatchpalette", title: String(localized: "APPEARANCE"))

            GroupBox {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Text("SHOW_PROCESS_DURING_UPDATE")
                        Spacer()
                        Toggle("", isOn: $showProcessDuringUpdate)
                            .toggleStyle(.switch)
                            .accessibilityLabel(String(localized: "SHOW_PROCESS_DURING_UPDATE"))
                    }
                    .padding(8)

                    Divider().padding(.vertical, 4)

                    VStack(spacing: 16) {
                        HStack(spacing: 40) {
                            optionCard(index: 0, selected: $selectedOption)
                            optionCard(index: 1, selected: $selectedOption)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .cardStyle()

            Spacer(minLength: 30)

            sectionHeader(icon: "icloud", title: String(localized: "CLOUD"))

            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("M365")
                        Spacer()
                        Text("CONTROLLED_BY_REMOTE_MANAGEMENT")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(8)
            }
            .cardStyle()
            
            Spacer(minLength: 30)

            sectionHeader(icon: "gear.badge", title: "Remote Management")

            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("MANAGEMENT_PROFILE (\(profileVersion))")
                        Spacer()
                        Button(action: { showConnectSheet = true }) {
                            Text("UPDATE")
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
        .onChange(of: selectedOption) { oldValue, newValue in
            UserDefaults.standard.setValue(newValue, forKey: "selectedOption")
            showProcessMenuBarLiveActivity = (newValue == 0)
        }
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title).fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 20)
    }

    private func optionCard(index: Int, selected: Binding<Int>) -> some View {
        VStack {
            Button(action: { selected.wrappedValue = index }) {
                let cornerRadius: CGFloat = 12
                let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

                Group {
                    if index == 0 {
                        Image("example.menubar.pill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image("example.menubar.icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .frame(width: 350, height: 250)
                .clipShape(shape)
                .overlay(
                    shape
                        .stroke(selected.wrappedValue == index ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: selected.wrappedValue == index ? 4 : 1)
                )
            }
            .buttonStyle(.plain)
            HStack(spacing: 8) {
                Text("OPTION \(index + 1)").font(.caption).padding(.top, 4)
                if index == 0 {
                    Text("NEW")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Color.pink.opacity(0.15))
                        )
                        .overlay(
                            Capsule().stroke(Color.pink.opacity(0.6), lineWidth: 1)
                        )
                        .foregroundStyle(Color.pink)
                        .padding(.top, 6)
                }
            }
        }
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
    SettingsView()
}

