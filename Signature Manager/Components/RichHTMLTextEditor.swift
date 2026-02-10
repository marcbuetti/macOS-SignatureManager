//
//  RichHTMLTextEditor.swift
//  Signature Manager
//
//  Created by Marc Büttner on 08.02.26.
//

import SwiftUI
import AppKit

extension Notification.Name {
    static let RichTextSetTypingTrait = Notification.Name("RichTextSetTypingTrait")
}

struct SignatureRichTextEditorView: View {

    // MARK: - Bindings aus Parent
    @Binding var attributedText: NSAttributedString?
    @Binding var selectedHTMLFile: URL?
    @Binding var htmlBeforeCustom: String
    @Binding var htmlAfterCustom: String

    let signatureStorageSelection: Int

    // MARK: - Editor State
    @State private var selectedRange = NSRange(location: 0, length: 0)
    @State private var selectedColor: Color = .primary
    @State private var selectedFontSize: CGFloat = 14

    @State private var isBoldActive = false
    @State private var isItalicActive = false
    @State private var isUnderlineActive = false

    var body: some View {
            VStack(alignment: .leading) {
                // MARK: Toolbar
                HStack(spacing: 8) {
                    toolbarButton(
                        systemImage: "bold",
                        isActive: isBoldActive,
                        action: toggleBold
                    )

                    toolbarButton(
                        systemImage: "italic",
                        isActive: isItalicActive,
                        action: toggleItalic
                    )

                    toolbarButton(
                        systemImage: "underline",
                        isActive: isUnderlineActive,
                        action: toggleUnderline
                    )
                    
                    ColorPicker("", selection: $selectedColor)
                        .labelsHidden()
                        .frame(width: 50)

                    Picker("", selection: $selectedFontSize) {
                        Text("12").tag(CGFloat(12))
                        Text("14").tag(CGFloat(14))
                        Text("18").tag(CGFloat(18))
                        Text("24").tag(CGFloat(24))
                        Text("36").tag(CGFloat(36))
                    }
                    .frame(width: 60)
                    .labelsHidden()
                }
                .padding(.bottom, 6)

                // MARK: Rich Text Editor
                RichTextView(
                    attributedText: Binding<NSAttributedString>(
                        get: { attributedText ?? NSAttributedString() },
                        set: { newValue in attributedText = newValue }
                    ),
                    selectedRange: $selectedRange
                )
                .frame(height: 350)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.2))
                )
                .onChange(of: selectedRange) { _, _ in
                    updateToolbarStateFromSelection()
                }
                .onChange(of: attributedText) { _, _ in
                    autosaveToCache()
                }
            }
    }

    // MARK: - Toolbar Button
    private func toolbarButton(
        systemImage: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(height: 15)
        }
        .foregroundColor(isActive ? Color.accentColor : Color.primary)
    }

    // MARK: - Toolbar State Sync
    private func updateToolbarStateFromSelection() {
        let current = attributedText ?? NSAttributedString()
        let length = current.length
        let range = effectiveRange()
        let location = min(max(0, range.location - (range.length == 0 && range.location > 0 ? 1 : 0)), max(0, length - 1))
        var attrs: [NSAttributedString.Key: Any] = [:]
        if length > 0 {
            attrs = current.attributes(at: location, effectiveRange: nil)
        } else {
            attrs = [:]
        }

        if let font = attrs[.font] as? NSFont {
            isBoldActive = font.fontDescriptor.symbolicTraits.contains(.bold)
            isItalicActive = font.fontDescriptor.symbolicTraits.contains(.italic)
            selectedFontSize = font.pointSize
        } else {
            isBoldActive = false
            isItalicActive = false
        }

        if let underline = attrs[.underlineStyle] as? Int {
            isUnderlineActive = underline != 0
        } else {
            isUnderlineActive = false
        }

        if let color = attrs[.foregroundColor] as? NSColor {
            selectedColor = Color(color)
        }
    }

    // MARK: - Toggle Actions
    private func toggleBold() {
        let current = attributedText ?? NSAttributedString()
        let range = effectiveRange()
        if range.length == 0 {
            let makeBold: Bool
            do {
                let loc = max(0, min(current.length - 1, range.location == 0 ? 0 : range.location - 1))
                let attrs = current.length > 0 ? current.attributes(at: loc, effectiveRange: nil) : [:]
                let baseFont = (attrs[.font] as? NSFont) ?? NSFont.systemFont(ofSize: selectedFontSize)
                makeBold = !baseFont.fontDescriptor.symbolicTraits.contains(.bold)
            }
            NotificationCenter.default.post(name: .RichTextSetTypingTrait, object: nil, userInfo: [
                "trait": NSFontTraitMask.boldFontMask.rawValue,
                "toggle": true,
                "size": selectedFontSize
            ])
            isBoldActive = makeBold
            updateToolbarStateFromSelection()
            return
        }

        let mutable = NSMutableAttributedString(attributedString: current)
        mutable.enumerateAttribute(.font, in: range) { value, subRange, _ in
            let currentFont = value as? NSFont ?? NSFont.systemFont(ofSize: selectedFontSize)
            let manager = NSFontManager.shared
            let hasBold = currentFont.fontDescriptor.symbolicTraits.contains(.bold)
            let newFont = hasBold ? manager.convert(currentFont, toNotHaveTrait: .boldFontMask) : manager.convert(currentFont, toHaveTrait: .boldFontMask)
            mutable.addAttribute(.font, value: newFont, range: subRange)
        }
        attributedText = mutable
        updateToolbarStateFromSelection()
    }

    private func toggleItalic() {
        let current = attributedText ?? NSAttributedString()
        let range = effectiveRange()
        if range.length == 0 {
            let makeItalic: Bool
            do {
                let loc = max(0, min(current.length - 1, range.location == 0 ? 0 : range.location - 1))
                let attrs = current.length > 0 ? current.attributes(at: loc, effectiveRange: nil) : [:]
                let baseFont = (attrs[.font] as? NSFont) ?? NSFont.systemFont(ofSize: selectedFontSize)
                makeItalic = !baseFont.fontDescriptor.symbolicTraits.contains(.italic)
            }
            NotificationCenter.default.post(name: .RichTextSetTypingTrait, object: nil, userInfo: [
                "trait": NSFontTraitMask.italicFontMask.rawValue,
                "toggle": true,
                "size": selectedFontSize
            ])
            isItalicActive = makeItalic
            updateToolbarStateFromSelection()
            return
        }

        let mutable = NSMutableAttributedString(attributedString: current)
        mutable.enumerateAttribute(.font, in: range) { value, subRange, _ in
            let currentFont = value as? NSFont ?? NSFont.systemFont(ofSize: selectedFontSize)
            let manager = NSFontManager.shared
            let hasItalic = currentFont.fontDescriptor.symbolicTraits.contains(.italic)
            let newFont = hasItalic ? manager.convert(currentFont, toNotHaveTrait: .italicFontMask) : manager.convert(currentFont, toHaveTrait: .italicFontMask)
            mutable.addAttribute(.font, value: newFont, range: subRange)
        }
        attributedText = mutable
        updateToolbarStateFromSelection()
    }

    private func toggleUnderline() {
        let current = attributedText ?? NSAttributedString()
        let range = effectiveRange()
        if range.length == 0 {
            let idx = max(0, min(max(0, current.length - 1), range.location == 0 ? 0 : range.location - 1))
            let underline = (current.length > 0 ? current.attribute(.underlineStyle, at: idx, effectiveRange: nil) as? Int : nil) ?? 0
            let willUnderline = underline == 0
            NotificationCenter.default.post(name: .RichTextSetTypingTrait, object: nil, userInfo: [
                "underline": willUnderline
            ])
            isUnderlineActive = willUnderline
            updateToolbarStateFromSelection()
            return
        }

        let mutable = NSMutableAttributedString(attributedString: current)
        let idx = max(0, min(max(0, mutable.length - 1), range.location))
        let currentUnderline = (mutable.attribute(.underlineStyle, at: idx, effectiveRange: nil) as? Int) ?? 0

        if currentUnderline == 0 {
            mutable.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        } else {
            mutable.removeAttribute(.underlineStyle, range: range)
        }

        attributedText = mutable
        updateToolbarStateFromSelection()
    }
    
    private func toggleFontTrait(_ trait: NSFontTraitMask) {
        let range = effectiveRange()
        let current = attributedText ?? NSAttributedString()
        let mutable = NSMutableAttributedString(attributedString: current)

        mutable.enumerateAttribute(.font, in: range) { value, subRange, _ in
            let font = value as? NSFont ?? NSFont.systemFont(ofSize: selectedFontSize)

            let newFont: NSFont
            if font.fontDescriptor.symbolicTraits.contains(trait == .boldFontMask ? .bold : .italic) {
                newFont = NSFontManager.shared.convert(font, toNotHaveTrait: trait)
            } else {
                newFont = NSFontManager.shared.convert(font, toHaveTrait: trait)
            }

            mutable.addAttribute(.font, value: newFont, range: subRange)
        }

        attributedText = mutable
        updateToolbarStateFromSelection()
    }

    // MARK: - Helpers
    private func effectiveRange() -> NSRange {
        let length = (attributedText ?? NSAttributedString()).length
        var range = selectedRange
        if range.location > length { range.location = length }
        if range.location + range.length > length { range.length = max(0, length - range.location) }
        return range
    }

    private func autosaveToCache() {
        guard let url = selectedHTMLFile else { return }

        let html = htmlBeforeCustom
            + formattedHTMLFromEditor()
            + htmlAfterCustom

        try? html.write(to: url, atomically: true, encoding: .utf8)
    }

    private func formattedHTMLFromEditor() -> String {
        let current = attributedText ?? NSAttributedString()
        let range = NSRange(location: 0, length: current.length)
        let options: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html
        ]

        if let data = try? current.data(from: range, documentAttributes: options),
           let html = String(data: data, encoding: .utf8) {
            return "<custom>\n\(html)\n</custom>"
        }

        return "<custom></custom>"
    }
}


struct RichTextView: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = true
        textView.isRichText = true
        textView.allowsUndo = true
        textView.delegate = context.coordinator
        textView.drawsBackground = true
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textStorage?.setAttributedString(attributedText)
        
        context.coordinator.textView = textView

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        // Avoid clobbering user edits while typing
        let current = textView.attributedString()
        if current != attributedText {
            // Only update if we're not the first responder (actively editing)
            if textView.window?.firstResponder !== textView {
                textView.textStorage?.setAttributedString(attributedText)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextView
        weak var textView: NSTextView?

        init(_ parent: RichTextView) {
            self.parent = parent
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(handleTypingTrait(_:)), name: .RichTextSetTypingTrait, object: nil)
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.attributedText = tv.attributedString()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.selectedRange = tv.selectedRange()
        }
        
        func setTypingFontTrait(_ trait: NSFontTraitMask, toggle: Bool, fallbackSize: CGFloat) {
            guard let tv = textView else { return }
            var attrs = tv.typingAttributes
            let baseFont = (attrs[.font] as? NSFont) ?? NSFont.systemFont(ofSize: fallbackSize)
            let manager = NSFontManager.shared
            let hasTrait: Bool
            switch trait {
            case .boldFontMask:
                hasTrait = baseFont.fontDescriptor.symbolicTraits.contains(.bold)
            case .italicFontMask:
                hasTrait = baseFont.fontDescriptor.symbolicTraits.contains(.italic)
            default:
                hasTrait = false
            }
            let newFont = (toggle ? !hasTrait : true) ? manager.convert(baseFont, toHaveTrait: trait) : manager.convert(baseFont, toNotHaveTrait: trait)
            attrs[.font] = newFont
            tv.typingAttributes = attrs
        }

        func setTypingUnderline(_ enabled: Bool) {
            guard let tv = textView else { return }
            var attrs = tv.typingAttributes
            if enabled {
                attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
            } else {
                attrs[.underlineStyle] = 0
            }
            tv.typingAttributes = attrs
        }
        
        @objc func handleTypingTrait(_ note: Notification) {
            guard let info = note.userInfo else { return }
            if let traitRaw = info["trait"] as? UInt,
               let toggle = info["toggle"] as? Bool,
               let size = info["size"] as? CGFloat {
                let trait = NSFontTraitMask(rawValue: traitRaw)
                setTypingFontTrait(trait, toggle: toggle, fallbackSize: size)
            }
            if let underline = info["underline"] as? Bool {
                setTypingUnderline(underline)
            }
        }
    }
}

#Preview {
    SignatureRichTextEditorView(
        attributedText: .constant(nil),
        selectedHTMLFile: .constant(nil),
        htmlBeforeCustom: .constant(""),
        htmlAfterCustom: .constant(""),
        signatureStorageSelection: 1
    )
}

