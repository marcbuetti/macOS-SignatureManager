//
//  SignaturesView.swift
//  Signature Manager 2
//
//  Created by Marc Büttner on 21.08.25.
//

import SwiftUI
import SwiftData

struct SignaturesView: View {

    @Query(sort: \Signature.lastUpdated, order: .reverse)
    private var signatures: [Signature]

    @State private var navigateToAddSignature = false

    var body: some View {
        NavigationStack {
            List(signatures) { signature in
                NavigationLink(
                    destination: SignatureDetailsView(signature: signature)
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(signature.name)
                            .font(.headline)

                        Text(storageText(signature.storageType))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("LAST_UPDATED: \(formatPretty(signature.lastUpdated))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.forward")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            }
            .overlay {
                if signatures.isEmpty {
                    ContentUnavailableView(
                        "NO_SIGNATURES_YET",
                        systemImage: "signature",
                        description: Text("ADD_SIGNATURE_DESCRIPTION")
                    )
                    .padding(.top, 40)
                }
            }
            .navigationDestination(isPresented: $navigateToAddSignature) {
                AddSignatureView(signature: nil)
            }
            .navigationTitle("SIGNATURES")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { navigateToAddSignature = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    // MARK: - exakt gleiche Anzeige-Logik

    private func storageText(_ type: StorageType) -> String {
        type == .local
            ? String(localized: "LOCAL_STORAGE")
            : String(localized: "CLOUD_M365")
    }

    private func formatPretty(_ d: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: d)
    }
}

#Preview {
    SignaturesView()
}

