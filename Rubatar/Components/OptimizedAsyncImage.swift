//
//  OptimizedAsyncImage.swift
//  Rubatar
//
//  Created for super fast image loading performance
//

import SwiftUI

/// Ultra-optimized AsyncImage with progressive loading and smart caching
struct OptimizedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var loadError = false
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                content(Image(uiImage: image))
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if loadError {
                placeholder()
            } else {
                placeholder()
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                        }
                    )
            }
        }
        .task(id: url?.absoluteString) {
            await loadImage()
        }
        .animation(.easeInOut(duration: 0.3), value: loadedImage)
    }
    
    @MainActor
    private func loadImage() async {
        guard let url = url, loadedImage == nil, !loadError else { return }
        
        isLoading = true
        loadError = false
        
        // Use ImageCacheManager for optimal performance (simplified)
        if let image = await ImageCacheManager.shared.loadImage(from: url) {
            loadedImage = image
        } else {
            loadError = true
        }
        
        isLoading = false
    }
}

// MARK: - Convenience Initializers
extension OptimizedAsyncImage where Placeholder == Color {
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            url: url,
            content: content,
            placeholder: { Color.gray.opacity(0.2) }
        )
    }
}


// MARK: - Shimmer Effect for Loading
struct ImageShimmerEffect: View {
    @State private var isAnimating = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.1),
                Color.gray.opacity(0.3)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white,
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .rotationEffect(.degrees(30))
                .offset(x: isAnimating ? 200 : -200)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}
