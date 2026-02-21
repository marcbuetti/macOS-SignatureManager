//
//  RemoteConfigSheetView.swift
//  Signature Manager
//
//  Created by Marc Büttner on 17.09.25.
//

import SwiftUI

struct WhatsNewSheet: View {
    var onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center, spacing: 12) {
                            Text("WHATS_NEW")
                                .font(.largeTitle.weight(.bold))
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 28))
                                .foregroundStyle(.tint)
                        }
                        
                        Text("WHATS_NEW_IN_THIS_VERSION")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 12)
                    
                    // Feature list
                    VStack(spacing: 16) {
                        WhatsNewRow(
                         icon: "ladybug.circle.fill",
                         title: "Hot fix",
                         subtitle: "In our last version appears a critical data save bug that prevented some users from using the app."
                         )
                        
                        WhatsNewRow(
                         icon: "app.specular",
                         title: "Updated UI",
                         subtitle: "We are permanently improving the UI, to create the beste experience for you."
                        )
                    }
                }
                .padding()
            }
            
            // Bottom button (sticky)
            Divider()
            
            Button {
                //onClose() // ✅ Bestätigung
                dismiss()
            } label: {
                Text("CONTINUE")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.tint, in: Capsule())
                    .foregroundStyle(.white)
                    .glassEffect()
            }
            .padding()
            .background(.ultraThinMaterial)
            .buttonStyle(.plain)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
            
struct WhatsNewRow: View {
    
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                //.glassEffect()
        )
    }
}

#Preview {
    WhatsNewSheet(onComplete: {})
        .frame(minWidth: 300, minHeight: 600)
}
