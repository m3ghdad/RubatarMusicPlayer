//
//  PagingScrollView.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/17/25.
//

import SwiftUI
import UIKit

struct PagingScrollView<Content: View>: View {
    let pageCount: Int
    let content: (Int) -> Content
    @Binding var currentPage: Int
    let onLoadMore: (() -> Void)? // Callback for loading more content
    
    @State private var dragOffset: CGFloat = 0
    @State private var lastPage: Int = 0
    
    init(pageCount: Int, content: @escaping (Int) -> Content, currentPage: Binding<Int>, onLoadMore: (() -> Void)? = nil) {
        self.pageCount = pageCount
        self.content = content
        self._currentPage = currentPage
        self.onLoadMore = onLoadMore
    }
    
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
                        
                        var newPage = currentPage
                        
                        if dragAmount > threshold && currentPage > 0 {
                            newPage = currentPage - 1
                        } else if dragAmount < -threshold && currentPage < pageCount - 1 {
                            newPage = currentPage + 1
                        }
                        
                        // Check if we need to load more content when reaching the end
                        if newPage == pageCount - 1 && onLoadMore != nil {
                            onLoadMore?()
                        }
                        
                        // Trigger haptic feedback if page changed
                        if newPage != currentPage {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            currentPage = newPage
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

