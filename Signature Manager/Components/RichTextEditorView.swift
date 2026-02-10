import SwiftUI

struct RichTextEditorView: View {

    @State private var text: AttributedString = {
        var s = AttributedString("Hallo Rich Text 👋\nMarkier mich!")
        s.font = .system(size: 16)
        return s
    }()

    @State private var selection = AttributedTextSelection()

    var body: some View {
        VStack(spacing: 0) {

            toolbar

            Divider()

            TextEditor(text: $text, selection: $selection)
                .padding()
        }
    }

    // MARK: Toolbar

    private var toolbar: some View {
        HStack(spacing: 16) {

            Button("B") {
                apply { $0.font = .system(size: 16, weight: .bold) }
            }
            .fontWeight(.bold)

            Button("I") {
                apply { $0.font = .system(size: 16).italic() }
            }
            .italic()

            Button("U") {
                apply { $0.underlineStyle = .single }
            }
            .underline()

            Button("A+") {
                apply {
                    let size = ($0.font?.pointSize ?? 16) + 2
                    $0.font = .system(size: size)
                }
            }

            Button("A-") {
                apply {
                    let size = max(8, ($0.font?.pointSize ?? 16) - 2)
                    $0.font = .system(size: size)
                }
            }

            ColorPicker("", selection: Binding(
                get: { .black },
                set: { color in
                    apply { $0.foregroundColor = color }
                }
            ))
            .labelsHidden()
        }
        .padding(8)
        .background(.secondary.opacity(0.15))
    }

    // MARK: Core Logic

    private func apply(
        _ change: (inout AttributeContainer) -> Void
    ) {
        // Resolve a concrete selected range from the current selection value
        // Prefer a collapsed caret (no selection) as a no-op
        // If there are multiple ranges, operate on the first one
        let selectedRange: Range<AttributedString.Index>?

        if let range = selection.range { // single range selection
            selectedRange = range
        } else if let first = selection.ranges.first { // multi-range selection, take first
            selectedRange = first
        } else {
            selectedRange = nil
        }

        guard let range = selectedRange, !range.isEmpty else { return }

        var container = AttributeContainer()
        change(&container)

        text[range].mergeAttributes(container)
    }
}

// MARK: Preview

#Preview {
    RichTextEditorView()
        .frame(height: 400)
}
