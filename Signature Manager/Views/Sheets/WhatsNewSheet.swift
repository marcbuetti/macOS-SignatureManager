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
                        /*WhatsNewRow(
                         icon: "ladybug.circle.fill",
                         title: "Hot fix",
                         subtitle: "In our last version appears a security issue that prevented some users from using the app."
                         )*/
                        
                        WhatsNewRow(
                         icon: "applewatch",
                         title: "Support for Apple Watch",
                         subtitle: "ParkCap has now a budy on Apple Watch! You can now also see your parking time and location and can control the ticket directly from your watch."
                         )
                        
                        WhatsNewRow(
                            icon: "bell.and.waves.left.and.right",
                            title: "Time sensitive notifications",
                            subtitle: "You will now receive a time sensitive push notification when your ticket is about to expire to never miss it."
                        )
                        
                        WhatsNewRow(
                         icon: "app.shadow",
                         title: "Shortcuts & control center",
                         subtitle: "You can now add control tickets over Shortcuts app and use the control center to start it."
                         )
                        
                        WhatsNewRow(
                         icon: "stop.circle",
                         title: "Stop active ticket",
                         subtitle: "You can now stop an active ticket without to delete it."
                         )
                        
                        WhatsNewRow(
                         icon: "iphone.gen2.sizes",
                         title: "Extended compatibility ",
                         subtitle: "ParkCap are now also available on iOS 18 and above, and on watchOS 10 and above."
                         )
                        
                        WhatsNewRow(
                            icon: "exclamationmark.bubble",
                            title: "BETA Softwareprogram",
                            subtitle: "We are constantly working to better accommodate the wishes of BETA softwareprogram users and have added further features in this version."
                        )
                        
                        WhatsNewRow(
                            icon: "apple.intelligence",
                            title: "Updated algorithms",
                            subtitle: "More parking tickets will be widely accepted, and those that are already accepted will be better recognized. "
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
