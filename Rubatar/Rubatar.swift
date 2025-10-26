//
//  RubatarApp.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import SwiftUI

@main
struct RubatarApp: App {
    init() {
        // Initialize performance managers
        setupPerformanceOptimizations()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Schedule background refresh on app launch
                    BackgroundTaskManager.shared.scheduleBackgroundRefresh()
                }
        }
    }
    
    private func setupPerformanceOptimizations() {
        // Configure URL caching
        _ = NetworkCacheManager.shared
        
        // Initialize Core Data
        _ = CoreDataManager.shared
        
        // Register background tasks
        BackgroundTaskManager.shared.registerBackgroundTasks()
        
        // Initialize image cache
        _ = ImageCacheManager.shared
        
        print("✅ Performance optimizations initialized")
    }
}
