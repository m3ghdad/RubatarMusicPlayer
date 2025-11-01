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
            VStack(alignment: selectedLanguage.horizontalAlignment, spacing: 20) {
                // Classification section (Form and Book metadata)
                let hasForm = (selectedLanguage == .farsi ? (poem.formFa != nil && !poem.formFa!.isEmpty) : (poem.formEn != nil && !poem.formEn!.isEmpty))
                let hasBook = (selectedLanguage == .farsi ? (poem.bookNameFa != nil && !poem.bookNameFa!.isEmpty) : (poem.bookNameEn != nil && !poem.bookNameEn!.isEmpty))
                
                if hasForm || hasBook {
                    // Section title
                    Text(selectedLanguage == .farsi ? "طبقه‌بندی" : "Classification")
                        .font(.custom("Palatino", size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: selectedLanguage.frameAlignment)
                        .padding(.bottom, 0)
                    
                    // Form and Book metadata in horizontal scrollable format
                    HStack(alignment: .top, spacing: 0) {
                        if selectedLanguage == .farsi {
                            Spacer()
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 8) {
                                if selectedLanguage == .farsi {
                                    // Farsi: Content order Form | Book (reversed for RTL)
                                    // Form
                                    if hasForm {
                                        MetadataRow(
                                            icon: "textformat",
                                            tagHeader: "قالب",
                                            tagDetail: poem.formFa!,
                                            alignment: .trailing,
                                            showDivider: true
                                        )
                                    }
                                    
                                    // Book
                                    if hasBook {
                                        MetadataRow(
                                            icon: "book.closed.fill",
                                            tagHeader: "کتاب",
                                            tagDetail: poem.bookNameFa!,
                                            alignment: .trailing,
                                            showDivider: true
                                        )
                                    }
                                } else {
                                    // English: Content starts from leading edge
                                    // Book
                                    if hasBook {
                                        MetadataRow(
                                            icon: "book.closed.fill",
                                            tagHeader: "Book",
                                            tagDetail: poem.bookNameEn!,
                                            alignment: .leading,
                                            showDivider: true
                                        )
                                    }
                                    
                                    // Form
                                    if hasForm {
                                        MetadataRow(
                                            icon: "textformat",
                                            tagHeader: "Form",
                                            tagDetail: poem.formEn!,
                                            alignment: .leading,
                                            showDivider: true
                                        )
                                    }
                                }
                            }
                        }
                        .environment(\.layoutDirection, selectedLanguage == .farsi ? .rightToLeft : .leftToRight)
                        if selectedLanguage == .english {
                            Spacer()
                        }
                    }
                    .padding(.bottom, 12)
                }
                
                Divider()
                    .background(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
                
                // Title
                Text(selectedLanguage == .farsi ? "معنای کلی" : "Overall Meaning")
                    .font(.custom("Palatino", size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
                    .padding(.bottom, 0)
                
                // Topic and Mood tags
                let hasTopic = poem.topic != nil && !poem.topic!.isEmpty
                let hasMood = poem.mood != nil && !poem.mood!.isEmpty
                
                if hasTopic || hasMood {
                    HStack(alignment: .top, spacing: 0) {
                        if selectedLanguage == .farsi {
                            Spacer()
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 8) {
                                if selectedLanguage == .farsi {
                                    // Topic
                                    if hasTopic {
                                        MetadataRow(
                                            icon: "tag.fill",
                                            tagHeader: "موضوع",
                                            tagDetail: poem.topic!,
                                            alignment: .trailing,
                                            showDivider: true
                                        )
                                    }
                                    
                                    // Mood
                                    if hasMood {
                                        MetadataRow(
                                            icon: "leaf.fill",
                                            tagHeader: "حال",
                                            tagDetail: poem.mood!,
                                            alignment: .trailing,
                                            showDivider: true
                                        )
                                    }
                                } else {
                                    // English: Content starts from leading edge
                                    // Topic
                                    if hasTopic {
                                        MetadataRow(
                                            icon: "tag.fill",
                                            tagHeader: "Topic",
                                            tagDetail: poem.topic!,
                                            alignment: .leading,
                                            showDivider: true
                                        )
                                    }
                                    
                                    // Mood
                                    if hasMood {
                                        MetadataRow(
                                            icon: "leaf.fill",
                                            tagHeader: "Mood",
                                            tagDetail: poem.mood!,
                                            alignment: .leading,
                                            showDivider: true
                                        )
                                    }
                                }
                            }
                        }
                        .environment(\.layoutDirection, selectedLanguage == .farsi ? .rightToLeft : .leftToRight)
                        if selectedLanguage == .english {
                            Spacer()
                        }
                    }
                    .padding(.bottom, 12)
                }
                
                // Tafseer text
                if !tafseerText.isEmpty {
                    Text(formattedTafseerText)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .lineSpacing(8)
                        .multilineTextAlignment(selectedLanguage.textAlignment)
                        .frame(maxWidth: .infinity, alignment: selectedLanguage.frameAlignment)
                } else {
                    Text(selectedLanguage == .farsi ? "معنی در دسترس نیست" : "No meaning available")
                        .font(.custom("Palatino", size: 15))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                        .italic()
                        .frame(maxWidth: .infinity, alignment: selectedLanguage.frameAlignment)
                }
                
                // About the Poet section (show if era OR biography is available)
                let biography = selectedLanguage == .farsi ? poem.poet.biographyFa : poem.poet.biographyEn
                let hasBiography = biography != nil && !biography!.isEmpty
                let hasEra = poem.poet.era != nil && !poem.poet.era!.isEmpty
                
                if hasEra || hasBiography {
                    Divider()
                        .background(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
                        .padding(.top, 20)
                    
                    // Section title
                    Text(selectedLanguage == .farsi ? "درباره شاعر" : "About the Poet")
                        .font(.custom("Palatino", size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: selectedLanguage.frameAlignment)
                        .padding(.bottom, 0)
                    
                    // Poet name and era tags
                    HStack(alignment: .top, spacing: 0) {
                        if selectedLanguage == .farsi {
                            Spacer()
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 8) {
                                if selectedLanguage == .farsi {
                                    // Poet name
                                    MetadataRow(
                                        icon: "graduationcap.fill",
                                        tagHeader: selectedLanguage == .farsi ? "شاعر" : "Poet",
                                        tagDetail: poem.poet.fullName,
                                        alignment: .trailing,
                                        showDivider: false
                                    )
                                    
                                    // Era
                                    if hasEra {
                                        MetadataRow(
                                            icon: "clock.fill",
                                            tagHeader: selectedLanguage == .farsi ? "دوره" : "Era",
                                            tagDetail: poem.poet.era!,
                                            alignment: .trailing,
                                            showDivider: true
                                        )
                                    }
                                } else {
                                    // English: Content starts from leading edge
                                    // Poet name
                                    MetadataRow(
                                        icon: "graduationcap.fill",
                                        tagHeader: selectedLanguage == .farsi ? "شاعر" : "Poet",
                                        tagDetail: poem.poet.fullName,
                                        alignment: .leading,
                                        showDivider: true
                                    )
                                    
                                    // Era
                                    if hasEra {
                                        MetadataRow(
                                            icon: "clock.fill",
                                            tagHeader: selectedLanguage == .farsi ? "دوره" : "Era",
                                            tagDetail: poem.poet.era!,
                                            alignment: .leading,
                                            showDivider: false
                                        )
                                    }
                                }
                            }
                        }
                        .environment(\.layoutDirection, selectedLanguage == .farsi ? .rightToLeft : .leftToRight)
                        if selectedLanguage == .english {
                            Spacer()
                        }
                    }
                    .padding(.bottom, 12)
                    
                    // Biography text if available
                    if hasBiography {
                        Text(biography!)
                            .font(.custom("Palatino", size: 16))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .lineSpacing(8)
                            .multilineTextAlignment(selectedLanguage.textAlignment)
                            .frame(maxWidth: .infinity, alignment: selectedLanguage.frameAlignment)
                    }
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
                    // Farsi: Text on left, icon on right
                    Text(tagDetail)
                        .font(.custom("Palatino", size: 14))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Spacer(minLength: 0)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                } else {
                    // English: Icon on left, text on right
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                    Text(tagDetail)
                        .font(.custom("Palatino", size: 14))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
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
    
    // Replace \n\n with paragraph breaks (two newlines) and ensure \n works properly
    // Convert \n\n to \n\n (keep as is, AttributedString handles it)
    // The issue is likely that the backend sends literal "\n\n" string, so we need to handle it
    var processedText = text
    // If the text contains literal "\n\n" (backslash n), replace it with actual newline
    processedText = processedText.replacingOccurrences(of: "\\n\\n", with: "\n\n")
    processedText = processedText.replacingOccurrences(of: "\\n", with: "\n")
    
    // Use NSMutableAttributedString for better control
    let mutableString = NSMutableAttributedString(string: processedText)
    
    // Set base font to Palatino
    let baseFont = UIFont(name: "Palatino", size: 16) ?? UIFont.systemFont(ofSize: 16)
    mutableString.addAttribute(.font, value: baseFont, range: NSRange(location: 0, length: processedText.count))
    
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
    let text = mutableString.string // Use the actual string from mutableString
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
                let boldFont = UIFont(name: "Palatino-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
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
