//
//  LegalView.swift
//  Signature Manager
//
//  Created by Marc Büttner on 19.08.25.
//

import SwiftUI


struct LegalItem: Identifiable {
    let id = UUID()
    let name: String
    let file: String
    let webKit: Bool
    let url: URL?
}


struct LegalView: View {
    let items = [
        LegalItem(name: String(localized: "PRIVACY_POLICY"), file: "PrivacyPolicy", webKit: false, url: nil),
        LegalItem(name: String(localized: "TERMS_OF_USE"), file: "TermsOfUse", webKit: false, url: nil),
        LegalItem(name: String(localized: "APPLE_LICENSE_AGREEMENT"), file: "", webKit: true, url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")),
    ]
    
    var body: some View {
        List(items) { item in
            NavigationLink(destination: LegalDetailView(name: item.name, file: item.file, webKit: item.webKit, url: item.url)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                }
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundColor(.secondary)
                
            }
            .padding(.vertical, 6)
        }
        .navigationTitle("LEGAL")
    }
}


#Preview {
    NavigationStack { LegalView() }
}
