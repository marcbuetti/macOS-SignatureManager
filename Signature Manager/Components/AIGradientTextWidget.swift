//
//  AIGradientTextWidget.swift
//  Signature Manager
//
//  Created by Marc Büttner on 02.09.25.
//

import SwiftUI


struct AIGradientTextWidget: View {
    let animate: Bool
    let text: String
    let fontWeight: Font.Weight
    let fontSize: CGFloat
    let availableWidth: CGFloat
    @State private var internalAnimate = false
    let gradientColors: [Color] = [
        .yellow.opacity(0.1), .mint.opacity(0.2), .yellow.opacity(0.1),
        .purple, .orange, .pink, .purple, .cyan, .purple, .pink, .orange,
        .yellow.opacity(0.1), .mint.opacity(0.2), .yellow.opacity(0.1),
    ]
    var body: some View {
        if animate {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: availableWidth * 8.9, height: fontSize * 10)
                .offset(x: internalAnimate ? availableWidth * -3.4 : availableWidth * 4)
                .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: internalAnimate)
                .rotationEffect(.degrees(20)).rotationEffect(.degrees(180))
                .onAppear { internalAnimate = true }
                .mask {
                    VStack {
                        Text(text)
                            .font(.system(size: fontSize, weight: fontWeight))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: availableWidth, alignment: .center)
                }
            }
            .frame(maxWidth: availableWidth, alignment: .center)
            .frame(height: fontSize * 1.2)
        } else {
            Text(text)
                .font(.system(size: fontSize, weight: fontWeight))
        }
    }
}
