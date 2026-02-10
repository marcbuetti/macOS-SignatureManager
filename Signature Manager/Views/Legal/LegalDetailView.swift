//
//  LegalDetailView.swift
//  Signature Manager
//
//  Created by Marc Büttner on 17.09.25.
//

import SwiftUI
import WebKit


struct LegalDetailView: View {
    let name: String
    let file: String
    let webKit: Bool
    let url: URL?
    
    var body: some View {
        Group {
            if webKit, let url {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("apple.com")
                            .font(.caption)
                    }
                    if #available(macOS 26.0, *) {
                        WebView(url: url)
                            .navigationTitle(name)
                    } else {
                        // Fallback on earlier versions
                    }
                }
            } else {
                ScrollView {
                    Text(loadFile())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .navigationTitle(name)
            }
        }
    }
    
    private func loadFile() -> String {
        if let url = Bundle.main.url(forResource: file, withExtension: "txt"),
           let content = try? String(contentsOf: url, encoding: .utf8) {
            return content
        } else {
            return String(localized: "ERROR_BY_LOADING_FILE")
        }
    }
}


#Preview {
    LegalDetailView(name: "Privacy Policy", file: "Deine Datenschutzerklärung…", webKit: true, url: URL(string: "https://apple.com"))
}
