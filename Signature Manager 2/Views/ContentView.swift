//
//  ContentView.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 19.08.25.
//

import SwiftUI


enum Page: String, CaseIterable, Identifiable {
    case settings, signatures, logs, about
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .settings:  return String(localized: "GENERAL")
        case .signatures: return String(localized: "SIGNATURES")
        case .logs: return String(localized: "LOGS")
        case .about:    return String(localized: "ABOUT")
        }
    }
    var systemImage: String {
        switch self {
        case .settings:   return "gearshape"
        case .signatures: return "signature"
        case .logs:       return "doc.text.magnifyingglass"
        case .about:      return "info.circle"
        }
    }
}


struct ContentView: View {
    @State private var selection: Page? = .settings
    
    var body: some View {
        NavigationSplitView {
            List(Page.allCases, selection: $selection) { page in
                NavigationLink(value: page) {
                    Label(page.title, systemImage: page.systemImage)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("SIGNATURE_MANAGER")
            .navigationSplitViewColumnWidth(min: 170, ideal: 170, max: 170)
        } detail: {
            NavigationStack {
                switch selection ?? .settings {
                case .settings:   SettingsView()
                case .signatures: SignaturesView()
                case .logs:       LogView()
                case .about:      AboutView()
                }
            }
            // Der Titel oben spiegelt IMMER die aktuelle Seite
            .navigationTitle((selection ?? .settings).title)
            .toolbarTitleMenu { // optionales Title-Menü wie in macOS 14+
                ForEach(Page.allCases) { page in
                    Button(page.title) { selection = page }
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
