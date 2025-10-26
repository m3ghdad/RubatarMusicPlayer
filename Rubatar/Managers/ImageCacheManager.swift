//
//  ImageCacheManager.swift
//  Rubatar
//
//  Created for performance optimization
//

import UIKit
import SwiftUI

class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    // Memory cache using NSCache
    private let memoryCache = NSCache<NSString, UIImage>()
    
    // Disk cache directory
    private let diskCacheDirectory: URL
    
    // Cache size limits
    private let maxMemoryCacheSize = 100 * 1024 * 1024 // 100 MB
    private let maxDiskCacheSize = 500 * 1024 * 1024   // 500 MB
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    private init() {
        // Configure memory cache
        memoryCache.totalCostLimit = maxMemoryCacheSize
        memoryCache.countLimit = 200 // Max 200 images in memory
        
        // Setup disk cache directory
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheDirectory = cacheDir.appendingPathComponent("ImageCache", isDirectory: true)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        
        // Clean old cache on init
        Task {
            await cleanOldCache()
        }
    }
    
    // MARK: - Public Methods
    
    func loadImage(from url: URL) async -> UIImage? {
        let cacheKey = url.absoluteString as NSString
        
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Check disk cache
        if let diskImage = loadFromDisk(url: url) {
            // Store in memory cache for faster access
            let cost = Int(diskImage.size.width * diskImage.size.height * 4) // Rough estimate
            memoryCache.setObject(diskImage, forKey: cacheKey, cost: cost)
            return diskImage
        }
        
        // Download image
        return await downloadImage(from: url)
    }
    
    func preloadImages(urls: [URL]) {
        Task {
            for url in urls {
                _ = await loadImage(from: url)
            }
        }
    }
    
    func clearCache() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(at: diskCacheDirectory)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Private Methods
    
    private func loadFromDisk(url: URL) -> UIImage? {
        let fileURL = diskCacheURL(for: url)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        // Check if file is still valid (not too old)
        if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let modificationDate = attributes[.modificationDate] as? Date {
            let age = Date().timeIntervalSince(modificationDate)
            if age > maxCacheAge {
                try? FileManager.default.removeItem(at: fileURL)
                return nil
            }
        }
        
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    private func downloadImage(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let image = UIImage(data: data) else {
                return nil
            }
            
            // Cache in memory
            let cacheKey = url.absoluteString as NSString
            let cost = Int(image.size.width * image.size.height * 4)
            memoryCache.setObject(image, forKey: cacheKey, cost: cost)
            
            // Cache on disk
            saveToDisk(image: image, url: url)
            
            return image
        } catch {
            print("❌ Failed to download image: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func saveToDisk(image: UIImage, url: URL) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileURL = diskCacheURL(for: url)
        try? data.write(to: fileURL)
    }
    
    private func diskCacheURL(for url: URL) -> URL {
        let filename = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        return diskCacheDirectory.appendingPathComponent(filename)
    }
    
    private func cleanOldCache() async {
        let fileManager = FileManager.default
        
        guard let files = try? fileManager.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) else {
            return
        }
        
        var totalSize: Int64 = 0
        var fileInfos: [(url: URL, date: Date, size: Int64)] = []
        
        for fileURL in files {
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let modificationDate = attributes[.modificationDate] as? Date,
               let size = attributes[.size] as? Int64 {
                
                // Remove files older than maxCacheAge
                let age = Date().timeIntervalSince(modificationDate)
                if age > maxCacheAge {
                    try? fileManager.removeItem(at: fileURL)
                    continue
                }
                
                totalSize += size
                fileInfos.append((url: fileURL, date: modificationDate, size: size))
            }
        }
        
        // If total size exceeds limit, remove oldest files
        if totalSize > maxDiskCacheSize {
            fileInfos.sort { $0.date < $1.date } // Oldest first
            
            var currentSize = totalSize
            for fileInfo in fileInfos {
                if currentSize <= maxDiskCacheSize {
                    break
                }
                
                try? fileManager.removeItem(at: fileInfo.url)
                currentSize -= fileInfo.size
            }
        }
    }
}

// MARK: - Cached AsyncImage View
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = loadedImage {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .task {
            guard let url = url, loadedImage == nil else { return }
            isLoading = true
            loadedImage = await ImageCacheManager.shared.loadImage(from: url)
            isLoading = false
        }
    }
}

extension CachedAsyncImage where Placeholder == Color {
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content) {
        self.url = url
        self.content = content
        self.placeholder = { Color.gray.opacity(0.2) }
    }
}

