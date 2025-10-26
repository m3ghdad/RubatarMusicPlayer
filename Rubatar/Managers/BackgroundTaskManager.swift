//
//  BackgroundTaskManager.swift
//  Rubatar
//
//  Background task processing for data refresh
//

import Foundation
import BackgroundTasks

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
    private let refreshTaskIdentifier = "com.meghdad.Rubatar.refresh"
    
    private init() {}
    
    // Register background tasks
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: refreshTaskIdentifier,
            using: nil
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    // Schedule background refresh
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        
        // Fetch new content in 4 hours
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background refresh scheduled")
        } catch {
            print("❌ Failed to schedule background refresh: \(error.localizedDescription)")
        }
    }
    
    // Handle background refresh
    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule next refresh
        scheduleBackgroundRefresh()
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        let operation = BackgroundRefreshOperation()
        
        task.expirationHandler = {
            queue.cancelAllOperations()
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        queue.addOperation(operation)
    }
}

// MARK: - Background Refresh Operation
class BackgroundRefreshOperation: Operation {
    override func main() {
        guard !isCancelled else { return }
        
        print("🔄 Background refresh started")
        
        let semaphore = DispatchSemaphore(value: 0)
        
        // Refresh poems in background
        Task {
            let poetryService = PoetryService()
            let poems = await poetryService.fetchPoems(limit: 100, offset: 0, useCache: false)
            
            if !poems.isEmpty {
                CoreDataManager.shared.cachePoems(poems)
                print("✅ Background refresh: Cached \(poems.count) poems")
                
                // Preload first few artworks
                let artworkURLs = poems.prefix(10).compactMap { poem -> URL? in
                    guard let urlString = poem.artwork_url else { return nil }
                    return URL(string: urlString)
                }
                
                ImageCacheManager.shared.preloadImages(urls: artworkURLs)
                print("✅ Background refresh: Preloaded \(artworkURLs.count) artworks")
            }
            
            // Clean old cache
            CoreDataManager.shared.clearOldPoems(olderThan: 7)
            
            semaphore.signal()
        }
        
        // Wait for completion or timeout after 25 seconds (iOS bg tasks have ~30s limit)
        _ = semaphore.wait(timeout: .now() + 25)
        
        print("✅ Background refresh completed")
    }
}

