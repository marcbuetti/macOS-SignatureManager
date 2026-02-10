//
//  NotificationProcessView.swift
//  Signature Manager
//
//  Created by Marc Büttner on 05.09.25.
//

import SwiftUI


struct NotificationProcessView: View {
    @State private var progress: Double = 0.72
    
    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "App"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .cornerRadius(12)
                VStack(alignment: .leading, spacing: 2) {
                    Text(appName)
                        .font(.headline)
                    Text("Udating: \("item1000000000000")")
                        .font(.callout)
                }
                .padding(.leading, -8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 15)
            Divider()
                .padding(.horizontal, 6)
                .padding(.top, 10)
            HStack() {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)
                    //.offset(y: -4)
                Button("", systemImage: "x.circle.fill") {
                    
                }
                .buttonStyle(.plain)
                .offset(y: -2)
            }
            .padding(.leading, 7)
            .padding(.top, 15)
            .padding(.bottom, 15)
        }
        .frame(maxWidth: 400)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    NotificationProcessView()
}
