//
//  MusicAuthCacheManager.swift
//  Rubatar
//
//  Caches Apple Music authorization status and metadata
//

import Foundation
import MusicKit

class MusicAuthCacheManager {
    static let shared = MusicAuthCacheManager()
    
    private let authStatusKey = "music_auth_status"
    private let authCheckDateKey = "music_auth_check_date"
    private let cacheValidityDuration: TimeInterval = 60 * 60 // 1 hour
    
    private init() {}
    
    // Get cached authorization status
    func getCachedAuthStatus() -> MusicAuthorization.Status? {
        // Check if cache is still valid
        if let lastCheckDate = UserDefaults.standard.object(forKey: authCheckDateKey) as? Date {
            let timeSinceCheck = Date().timeIntervalSince(lastCheckDate)
            if timeSinceCheck > cacheValidityDuration {
                print("🔐 Auth cache expired, will check fresh status")
                return nil
            }
        } else {
            return nil
        }
        
        // Return cached status
        if let statusRawValue = UserDefaults.standard.string(forKey: authStatusKey),
           let cachedStatus = MusicAuthorization.Status(rawValue: statusRawValue) {
            print("🔐 Using cached auth status: \(cachedStatus)")
            return cachedStatus
        }
        
        return nil
    }
    
    // Cache authorization status
    func cacheAuthStatus(_ status: MusicAuthorization.Status) {
        UserDefaults.standard.set(status.rawValue, forKey: authStatusKey)
        UserDefaults.standard.set(Date(), forKey: authCheckDateKey)
        print("🔐 Cached auth status: \(status)")
    }
    
    // Get authorization status with caching
    func getAuthStatus() async -> MusicAuthorization.Status {
        // Try cache first
        if let cachedStatus = getCachedAuthStatus() {
            return cachedStatus
        }
        
        // Check actual status
        let status = MusicAuthorization.currentStatus
        cacheAuthStatus(status)
        return status
    }
    
    // Request authorization with caching
    func requestAuthorization() async -> MusicAuthorization.Status {
        let status = await MusicAuthorization.request()
        cacheAuthStatus(status)
        return status
    }
    
    // Clear cache
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: authStatusKey)
        UserDefaults.standard.removeObject(forKey: authCheckDateKey)
        print("🔐 Auth cache cleared")
    }
}

// MARK: - MusicAuthorization.Status Extension
// Note: MusicAuthorization.Status already conforms to RawRepresentable in MusicKit

