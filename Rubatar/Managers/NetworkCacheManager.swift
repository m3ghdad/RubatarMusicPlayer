//
//  NetworkCacheManager.swift
//  Rubatar
//
//  Network and URL caching configuration
//

import Foundation

class NetworkCacheManager {
    static let shared = NetworkCacheManager()
    
    private init() {
        configureURLCache()
    }
    
    private func configureURLCache() {
        // Configure URLCache with generous limits
        let memoryCapacity = 50 * 1024 * 1024  // 50 MB memory
        let diskCapacity = 200 * 1024 * 1024    // 200 MB disk
        
        let cache = URLCache(
            memoryCapacity: memoryCapacity,
            diskCapacity: diskCapacity,
            diskPath: "rubatar_url_cache"
        )
        
        URLCache.shared = cache
    }
    
    // Create optimized URLSession configuration
    func createOptimizedSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        
        // Enable HTTP/2
        configuration.httpShouldUsePipelining = true
        
        // Configure timeouts
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        // Connection pooling
        configuration.httpMaximumConnectionsPerHost = 6
        
        // Cache policy
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = URLCache.shared
        
        return URLSession(configuration: configuration)
    }
}

