//
//  TypewriterText.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/18/25.
//

import SwiftUI

struct TypewriterText: View {
    let text: String
    let font: Font
    let color: Color
    let lineSpacing: CGFloat
    let kerning: CGFloat
    let alignment: TextAlignment
    let delay: TimeInterval
    let isCompleted: Bool // Whether this page has already been typed
    let onComplete: () -> Void // Callback when typing finishes
    
    @State private var displayedText: String = ""
    @State private var currentIndex: Int = 0
    
    var body: some View {
        Text(displayedText)
            .font(font)
            .foregroundColor(color)
            .lineSpacing(lineSpacing)
            .kerning(kerning)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(alignment)
            .onAppear {
                if isCompleted {
                    // If already completed, show all text immediately
                    displayedText = text
                } else {
                    // Otherwise, start typewriter animation
                    startTypewriter()
                }
            }
    }
    
    private func startTypewriter() {
        displayedText = ""
        currentIndex = 0
        
        // Add initial delay before starting
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            typeNextCharacter()
        }
    }
    
    private func typeNextCharacter() {
        guard currentIndex < text.count else {
            // Typing complete, call completion handler
            onComplete()
            return
        }
        
        let index = text.index(text.startIndex, offsetBy: currentIndex)
        displayedText.append(text[index])
        currentIndex += 1
        
        // Vary the delay slightly for more natural typing
        let baseDelay: TimeInterval = 0.05 // Slowed down from 0.03 to 0.05 seconds per character
        let variance = Double.random(in: -0.015...0.015)
        let nextDelay = baseDelay + variance
        
        DispatchQueue.main.asyncAfter(deadline: .now() + nextDelay) {
            typeNextCharacter()
        }
    }
}

