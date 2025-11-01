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
    
    private var formattedTafseerText: AttributedString {
        formatTafseerText(tafseerText, isEnglish: selectedLanguage == .english)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: selectedLanguage == .farsi ? .trailing : .leading, spacing: 20) {
                // Metadata in horizontal scrollable format
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 8) {
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
                                    showDivider: true
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
                                    showDivider: true
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
                }
                
                Divider()
                    .background(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
                
                // Title
                Text(selectedLanguage == .farsi ? "معنای کلی" : "Overall Meaning")
                    .font(.custom("Palatino", size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
                    .padding(.bottom, 8)
                
                // Tafseer text
                if !tafseerText.isEmpty {
                    Text(formattedTafseerText)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .lineSpacing(8)
                        .multilineTextAlignment(selectedLanguage == .farsi ? .trailing : .leading)
                        .frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
                } else {
                    Text(selectedLanguage == .farsi ? "معنی در دسترس نیست" : "No meaning available")
                        .font(.custom("Palatino", size: 15))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                        .italic()
                        .frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // .glassEffect(in: .rect(cornerRadius: 12))
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
        // Metadata content
        VStack(alignment: alignment, spacing: 8) {
            // Tag-header (commented out)
            /*
            Text(tagHeader)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
            */
            
            // Tag-detail with glass effect
            HStack(spacing: 10) {
                if alignment == .trailing {
                    Text(tagDetail)
                        .font(.custom("Palatino", size: 16))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                    Text(tagDetail)
                        .font(.custom("Palatino", size: 16))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
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

// Format tafseer text with special styling
private func formatTafseerText(_ text: String, isEnglish: Bool) -> AttributedString {
    guard !text.isEmpty else { return AttributedString(text) }
    
    // Use NSMutableAttributedString for better control
    let mutableString = NSMutableAttributedString(string: text)
    
    // Set base font to Palatino
    let baseFont = UIFont(name: "Palatino", size: 17) ?? UIFont.systemFont(ofSize: 17)
    mutableString.addAttribute(.font, value: baseFont, range: NSRange(location: 0, length: text.count))
    
    // Process bold markers (**text**)
    processBoldMarkers(in: mutableString, text: text)
    
    // Process first character styling for English
    if isEnglish {
        processFirstChar(in: mutableString, text: text)
    }
    
    // Convert to AttributedString for SwiftUI
    if let attributedString = try? AttributedString(mutableString, including: AttributeScopes.UIKitAttributes.self) {
        return attributedString
    } else {
        return AttributedString(text)
    }
}

// Process bold markers (**text**)
private func processBoldMarkers(in mutableString: NSMutableAttributedString, text: String) {
    var searchRange = NSRange(location: 0, length: text.count)
    var offset = 0 // Track cumulative offset from deletions
    
    while searchRange.location < text.count {
        // Find opening **
        let openingRange = (text as NSString).range(of: "**", range: searchRange)
        if openingRange.location != NSNotFound {
            // Find closing **
            let afterOpening = NSRange(location: openingRange.location + openingRange.length, length: text.count - (openingRange.location + openingRange.length))
            let closingRange = (text as NSString).range(of: "**", range: afterOpening)
            if closingRange.location != NSNotFound {
                // Found a bold section
                let boldContentRange = NSRange(location: openingRange.location + openingRange.length, length: closingRange.location - (openingRange.location + openingRange.length))
                
                // Remove ** markers (need to adjust for previous deletions)
                let adjustedClosingRange = NSRange(location: closingRange.location - offset, length: 2)
                let adjustedOpeningRange = NSRange(location: openingRange.location - offset, length: 2)
                
                mutableString.deleteCharacters(in: adjustedClosingRange)
                mutableString.deleteCharacters(in: adjustedOpeningRange)
                
                // Apply bold to the content
                let adjustedBoldRange = NSRange(location: boldContentRange.location - offset - 2, length: boldContentRange.length)
                let boldFont = UIFont(name: "Palatino-Bold", size: 17) ?? UIFont.boldSystemFont(ofSize: 17)
                mutableString.addAttribute(.font, value: boldFont, range: adjustedBoldRange)
                
                // Update offset and search range
                offset += 4 // Removed 2 markers of 2 chars each
                searchRange = NSRange(location: closingRange.location + closingRange.length, length: text.count - (closingRange.location + closingRange.length))
            } else {
                break
            }
        } else {
            break
        }
    }
}

// Process first character for English
private func processFirstChar(in mutableString: NSMutableAttributedString, text: String) {
    for (index, char) in text.enumerated() {
        if char.isLetter {
            // Style first character to 32px for English
            let largeFont = UIFont(name: "Palatino", size: 32) ?? UIFont.systemFont(ofSize: 32)
            mutableString.addAttribute(.font, value: largeFont, range: NSRange(location: index, length: 1))
            break
        }
    }
}
