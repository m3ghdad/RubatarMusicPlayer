//
//  DeepAnalysisBottomSheet.swift
//  Rubatar
//
//  Created on 10/17/25.
//

import SwiftUI

struct DeepAnalysisBottomSheet: View {
    let poem: PoemData
    let selectedLanguage: AppLanguage
    @Environment(\.colorScheme) var colorScheme
    
    private var tafseerText: String {
        selectedLanguage == .farsi ? (poem.tafseerFa ?? "") : (poem.tafseerEn ?? "")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: selectedLanguage == .farsi ? .trailing : .leading, spacing: 20) {
                // Metadata Tags (Book, Mood, Topic, Form) - above interpretation
                FlowLayout(spacing: 8, alignment: selectedLanguage == .farsi ? .trailing : .leading) {
                    // Book
                    if let bookName = selectedLanguage == .farsi ? poem.bookNameFa : poem.bookNameEn,
                       !bookName.isEmpty {
                        MetadataTag(label: selectedLanguage == .farsi ? "کتاب" : "Book", value: bookName)
                    }
                    
                    // Mood
                    if let mood = poem.mood, !mood.isEmpty {
                        MetadataTag(label: selectedLanguage == .farsi ? "حال" : "Mood", value: mood)
                    }
                    
                    // Topic
                    if let topic = poem.topic, !topic.isEmpty {
                        MetadataTag(label: selectedLanguage == .farsi ? "موضوع" : "Topic", value: topic)
                    }
                    
                    // Form
                    if let form = selectedLanguage == .farsi ? poem.formFa : poem.formEn,
                       !form.isEmpty {
                        MetadataTag(label: selectedLanguage == .farsi ? "قالب" : "Form", value: form)
                    }
                }
                .frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
                
                Divider()
                    .background(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
                
                // Title
                Text(selectedLanguage == .farsi ? "تفسیر" : "Interpretation")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
                    .padding(.bottom, 8)
                
                // Tafseer text
                if !tafseerText.isEmpty {
                    Text(tafseerText)
                        .font(.system(size: 17))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .lineSpacing(8)
                        .multilineTextAlignment(selectedLanguage == .farsi ? .trailing : .leading)
                        .frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
                } else {
                    Text(selectedLanguage == .farsi ? "تفسیر در دسترس نیست" : "No interpretation available")
                        .font(.system(size: 15))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                        .italic()
                        .frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}

// Metadata Tag Component
struct MetadataTag: View {
    let label: String
    let value: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
            Text(value)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
        .cornerRadius(8)
    }
}

// FlowLayout for wrapping tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var alignment: HorizontalAlignment = .leading
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing,
            alignment: alignment
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing,
            alignment: alignment
        )
        for (index, subview) in subviews.enumerated() {
            let frame = result.frames[index]
            subview.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat, alignment: HorizontalAlignment) {
            if alignment == .trailing {
                // For RTL, build from right to left
                var currentX: CGFloat = maxWidth
                var currentY: CGFloat = 0
                var lineHeight: CGFloat = 0
                var frames: [CGRect] = []
                
                for subview in subviews {
                    let size = subview.sizeThatFits(.unspecified)
                    
                    if currentX - size.width < 0 {
                        currentX = maxWidth
                        currentY += lineHeight + spacing
                        lineHeight = 0
                    }
                    
                    currentX -= size.width
                    frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                    currentX -= spacing
                    lineHeight = max(lineHeight, size.height)
                }
                
                // Reverse to maintain original order
                self.frames = frames.reversed()
                self.size = CGSize(
                    width: maxWidth,
                    height: currentY + lineHeight
                )
            } else {
                // For LTR, build from left to right
                var currentX: CGFloat = 0
                var currentY: CGFloat = 0
                var lineHeight: CGFloat = 0
                var frames: [CGRect] = []
                
                for subview in subviews {
                    let size = subview.sizeThatFits(.unspecified)
                    
                    if currentX + size.width > maxWidth && currentX > 0 {
                        currentX = 0
                        currentY += lineHeight + spacing
                        lineHeight = 0
                    }
                    
                    frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                    currentX += size.width + spacing
                    lineHeight = max(lineHeight, size.height)
                }
                
                self.frames = frames
                self.size = CGSize(
                    width: maxWidth,
                    height: currentY + lineHeight
                )
            }
        }
    }
}
