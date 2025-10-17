//
//  PagingScrollView.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/17/25.
//

import SwiftUI

struct PagingScrollView<Content: View>: View {
    let pageCount: Int
    let content: (Int) -> Content
    @Binding var currentPage: Int
    
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width - 64 // Leave 32px on each side for peek
            let spacing: CGFloat = 16
            let totalWidth = cardWidth + spacing
            
            HStack(spacing: spacing) {
                ForEach(0..<pageCount, id: \.self) { index in
                    content(index)
                        .frame(width: cardWidth)
                }
            }
            .padding(.horizontal, 32) // 32px padding to show peeks
            .offset(x: -CGFloat(currentPage) * totalWidth + dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = cardWidth / 3
                        let dragAmount = value.translation.width
                        
                        if dragAmount > threshold && currentPage > 0 {
                            currentPage -= 1
                        } else if dragAmount < -threshold && currentPage < pageCount - 1 {
                            currentPage += 1
                        }
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentPage)
        }
    }
}

