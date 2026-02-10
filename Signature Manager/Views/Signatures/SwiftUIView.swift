//
//  SwiftUIView.swift
//  Signature Manager
//
//  Created by Marc Büttner on 08.02.26.
//

import SwiftUI

struct SwiftUIView: View {
    
    @State private var saveDisabled: Bool = true
    @State private var isProcessing: Bool = false
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    
                    if !isProcessing {
                        Button(action: { isProcessing.toggle() }) {
                            Label("SAVE", systemImage: "checkmark")
                            
                        }
                    } else {
                        
                        Button(action: { isProcessing.toggle() }) {
                            ProgressView().controlSize(.small)
                            
                        }
                        .disabled(true)
                    }
                }
            
            }
    }
}

#Preview {
    SwiftUIView()
}
