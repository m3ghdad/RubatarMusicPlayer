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
    
    // Performance optimizations
    private let targetSize: CGSize
    private let compressionQuality: CGFloat
    
    init(
        url: URL?,
        targetSize: CGSize = CGSize(width: 300, height: 300),
        compressionQuality: CGFloat = 0.8,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.targetSize = targetSize
        self.compressionQuality = compressionQuality
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
        
        // Use ImageCacheManager for optimal performance
        if let image = await ImageCacheManager.shared.loadImage(from: url) {
            // Optimize image for display
            let optimizedImage = await optimizeImage(image)
            loadedImage = optimizedImage
        } else {
            loadError = true
        }
        
        isLoading = false
    }
    
    private func optimizeImage(_ image: UIImage) async -> UIImage {
        return await Task.detached(priority: .userInitiated) {
            // Resize if needed
            let size = image.size
            let aspectRatio = size.width / size.height
            let targetAspectRatio = targetSize.width / targetSize.height
            
            var newSize = targetSize
            
            // Maintain aspect ratio
            if aspectRatio > targetAspectRatio {
                newSize.height = targetSize.width / aspectRatio
            } else {
                newSize.width = targetSize.height * aspectRatio
            }
            
            // Only resize if significantly different
            if abs(size.width - newSize.width) > 50 || abs(size.height - newSize.height) > 50 {
                return image.resized(to: newSize, quality: compressionQuality)
            }
            
            return image
        }.value
    }
}

// MARK: - Convenience Initializers
extension OptimizedAsyncImage where Placeholder == Color {
    init(
        url: URL?,
        targetSize: CGSize = CGSize(width: 300, height: 300),
        compressionQuality: CGFloat = 0.8,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            url: url,
            targetSize: targetSize,
            compressionQuality: compressionQuality,
            content: content,
            placeholder: { Color.gray.opacity(0.2) }
        )
    }
}

// MARK: - UIImage Extension for Optimization
extension UIImage {
    func resized(to size: CGSize, quality: CGFloat = 0.8) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Shimmer Effect for Loading
struct ShimmerEffect: View {
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
