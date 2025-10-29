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
    
    // Cache size limits - Simplified for better performance
    private let maxMemoryCacheSize = 100 * 1024 * 1024 // 100 MB (reduced for stability)
    private let maxDiskCacheSize = 500 * 1024 * 1024   // 500 MB (reduced for stability)
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days (reduced for stability)
    
    // Simplified concurrency control
    private let maxConcurrentDownloads = 3 // Reduced from 6 to 3
    private let downloadQueue = DispatchQueue(label: "image.download", qos: .userInitiated, attributes: .concurrent)
    
    private init() {
        // Configure memory cache
        memoryCache.totalCostLimit = maxMemoryCacheSize
        memoryCache.countLimit = 100 // Reduced from 200 to 100
        
        // Setup disk cache directory
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheDirectory = cacheDir.appendingPathComponent("ImageCache", isDirectory: true)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        
        // Clean old cache on init (simplified)
        Task {
            await cleanOldCache()
        }
    }
    
    // MARK: - Public Methods
    
    func loadImage(from url: URL) async -> UIImage? {
        let cacheKey = url.absoluteString as NSString
        
        // Check memory cache first (fastest)
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Check disk cache (fast)
        if let diskImage = loadFromDisk(url: url) {
            // Store in memory cache for faster access
            let cost = Int(diskImage.size.width * diskImage.size.height * 4) // Rough estimate
            memoryCache.setObject(diskImage, forKey: cacheKey, cost: cost)
            return diskImage
        }
        
        // Download image (simplified)
        return await downloadImage(from: url)
    }
    
    func preloadImages(urls: [URL]) {
        Task {
            // Limit concurrent downloads to prevent overwhelming the system
            let semaphore = DispatchSemaphore(value: maxConcurrentDownloads)
            
            await withTaskGroup(of: UIImage?.self) { group in
                for url in urls {
                    group.addTask {
                        await withCheckedContinuation { continuation in
                            Task {
                                semaphore.wait()
                                let result = await self.downloadImage(from: url)
                                semaphore.signal()
                                continuation.resume(returning: result)
                            }
                        }
                    }
                }
                
                // Wait for all tasks to complete
                for await _ in group {}
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
            // Create URLRequest with timeout and caching policy
            var request = URLRequest(url: url)
            request.timeoutInterval = 15.0 // Reduced timeout
            request.cachePolicy = .returnCacheDataElseLoad
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Invalid response for image: \(url)")
                return nil
            }
            
            // Validate data size (prevent extremely large images)
            guard data.count < 5 * 1024 * 1024 else { // 5MB limit (reduced from 10MB)
                print("Image too large: \(data.count) bytes for \(url)")
                return nil
            }
            
            guard let image = UIImage(data: data) else {
                print("Failed to create UIImage from data for \(url)")
                return nil
            }
            
            // Simple image optimization (reduced complexity)
            let optimizedImage = optimizeImageSize(image, maxSize: CGSize(width: 400, height: 400))
            
            // Cache in memory
            let cacheKey = url.absoluteString as NSString
            let cost = Int(optimizedImage.size.width * optimizedImage.size.height * 4)
            memoryCache.setObject(optimizedImage, forKey: cacheKey, cost: cost)
            
            // Cache on disk asynchronously
            Task {
                saveToDisk(image: optimizedImage, url: url)
            }
            
            return optimizedImage
        } catch {
            print("❌ Failed to download image: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Simplified image optimization
    private func optimizeImageSize(_ image: UIImage, maxSize: CGSize) -> UIImage {
        let imageSize = image.size
        
        // If image is already smaller than max size, return as is
        guard imageSize.width > maxSize.width || imageSize.height > maxSize.height else {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = imageSize.width / imageSize.height
        var newSize = maxSize
        
        if aspectRatio > 1 {
            // Landscape
            newSize.height = maxSize.width / aspectRatio
        } else {
            // Portrait
            newSize.width = maxSize.height * aspectRatio
        }
        
        // Use UIGraphicsImageRenderer for better performance
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    private func saveToDisk(image: UIImage, url: URL) {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return } // Reduced quality for smaller files
        
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

// MARK: - Performance Optimization Extensions
extension ImageCacheManager {
    
    /// Preload images with intelligent prioritization (simplified)
    func preloadImagesIntelligently(urls: [URL], visibleRange: Range<Int>? = nil) {
        // Simplified - just preload all images with limited concurrency
        preloadImages(urls: urls)
    }
    
    /// Get cache statistics for debugging
    func getCacheStats() -> (memoryCount: Int, memorySize: Int, diskCount: Int, diskSize: Int) {
        let memoryCount = memoryCache.countLimit
        let memorySize = memoryCache.totalCostLimit
        
        var diskCount = 0
        var diskSize = 0
        
        if let files = try? FileManager.default.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            diskCount = files.count
            diskSize = files.compactMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize }.reduce(0, +)
        }
        
        return (memoryCount, memorySize, diskCount, diskSize)
    }
    
    /// Clear all caches (useful for memory pressure)
    func clearAllCaches() {
        memoryCache.removeAllObjects()
        
        if let files = try? FileManager.default.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}

