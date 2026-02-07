//
//  AnimatedAppIcon.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 24.08.25.
//

import SwiftUI


struct AnimatedAppIcon: View {
    
    @State private var float = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 170, height: 170)
                .scaleEffect(x: 1, y: -1)
                .opacity(0.24)
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .black.opacity(0.7), location: 0.0),
                            .init(color: .black.opacity(0.01), location: 0.5),
                            .init(color: .clear, location: 1.0)
                        ]),
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .offset(y: (float ? 7 : -6) + 130)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: float
                )
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 170, height: 170)
                .shadow(radius: 18, y: 10)
                .offset(y: float ? -7 : 6)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: float
                )
        }
        .frame(height: 300)
        .onAppear { float = true }
    }
}

#Preview {
    AnimatedAppIcon()
}
