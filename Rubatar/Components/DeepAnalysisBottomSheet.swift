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
                // Metadata in horizontal scrollable format
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 4) {
                        if selectedLanguage == .farsi {
                            // Farsi order (RTL): Form | Book | Mood | Topic
                            // Form
                            if let form = poem.formFa, !form.isEmpty {
                                MetadataRow(
                                    icon: "textformat",
                                    tagHeader: "قالب",
                                    tagDetail: form,
                                    alignment: .trailing,
                                    showDivider: true
                                )
                            }
                            
                            // Book
                            if let bookName = poem.bookNameFa, !bookName.isEmpty {
                                MetadataRow(
                                    icon: "book.closed.fill",
                                    tagHeader: "کتاب",
                                    tagDetail: bookName,
                                    alignment: .trailing,
                                    showDivider: true
                                )
                            }
                            
                            // Mood
                            if let mood = poem.mood, !mood.isEmpty {
                                MetadataRow(
                                    icon: "leaf.fill",
                                    tagHeader: "حال",
                                    tagDetail: mood,
                                    alignment: .trailing,
                                    showDivider: true
                                )
                            }
                            
                            // Topic
                            if let topic = poem.topic, !topic.isEmpty {
                                MetadataRow(
                                    icon: "tag.fill",
                                    tagHeader: "موضوع",
                                    tagDetail: topic,
                                    alignment: .trailing,
                                    showDivider: false
                                )
                            }
                        } else {
                            // English order (LTR): Topic | Mood | Book | Form
                            // Topic
                            if let topic = poem.topic, !topic.isEmpty {
                                MetadataRow(
                                    icon: "tag.fill",
                                    tagHeader: "Topic",
                                    tagDetail: topic,
                                    alignment: .leading,
                                    showDivider: true
                                )
                            }
                            
                            // Mood
                            if let mood = poem.mood, !mood.isEmpty {
                                MetadataRow(
                                    icon: "leaf.fill",
                                    tagHeader: "Mood",
                                    tagDetail: mood,
                                    alignment: .leading,
                                    showDivider: true
                                )
                            }
                            
                            // Book
                            if let bookName = poem.bookNameEn, !bookName.isEmpty {
                                MetadataRow(
                                    icon: "book.closed.fill",
                                    tagHeader: "Book",
                                    tagDetail: bookName,
                                    alignment: .leading,
                                    showDivider: true
                                )
                            }
                            
                            // Form
                            if let form = poem.formEn, !form.isEmpty {
                                MetadataRow(
                                    icon: "textformat",
                                    tagHeader: "Form",
                                    tagDetail: form,
                                    alignment: .leading,
                                    showDivider: false
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
                }
                
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

// Metadata Row Component (vertical format)
struct MetadataRow: View {
    let icon: String
    let tagHeader: String
    let tagDetail: String
    let alignment: HorizontalAlignment
    let showDivider: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Metadata content
            VStack(alignment: alignment, spacing: 8) {
                // Tag-header
                Text(tagHeader)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                
                // Tag-detail with glass effect
                HStack(spacing: 10) {
                    if alignment == .trailing {
                        Text(tagDetail)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                        Text(tagDetail)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(in: RoundedRectangle(cornerRadius: 12))
            }
            .frame(maxWidth: .infinity, alignment: alignment == .trailing ? .trailing : .leading)
            
            // Vertical divider
            if showDivider {
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
        }
    }
}

// FlowLayout for wrapping tags (kept for potential future use)
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
