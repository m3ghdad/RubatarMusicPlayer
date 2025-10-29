//
//  ImagePreloaderModifier.swift
//  Rubatar
//
//  Created for performance optimization
//

import SwiftUI

struct ImagePreloaderModifier: ViewModifier {
    let urls: [URL]
    let priority: TaskPriority
    
    init(urls: [URL], priority: TaskPriority = .userInitiated) {
        self.urls = urls
        self.priority = priority
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !urls.isEmpty {
                    ImageCacheManager.shared.preloadImages(urls: urls, priority: priority)
                }
            }
    }
}

extension View {
    func preloadImages(urls: [URL], priority: TaskPriority = .userInitiated) -> some View {
        modifier(ImagePreloaderModifier(urls: urls, priority: priority))
    }
}
