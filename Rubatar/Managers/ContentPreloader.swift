//
//  ContentPreloader.swift
//  Rubatar
//
//  Preloads app content for smooth user experience
//

import Foundation
import MusicKit
import SwiftUI
import Combine

@MainActor
class ContentPreloader: ObservableObject {
    @Published var isLoading = true
    @Published var loadingProgress: Double = 0.0
    @Published var loadingMessage: String = "Loading..."
    
    private let maxLoadingTime: TimeInterval = 4.0 // Max 4 seconds
    private let minLoadingTime: TimeInterval = 3.0 // Min 3 seconds for smooth experience
    
    // Preloaded data
    @Published var preloadedPoems: [PoemData] = []
    @Published var preloadedPlaylists: [MusicKit.Playlist] = []
    @Published var preloadedAlbums: [MusicKit.Album] = []
    
    func preloadContent() async {
        let startTime = Date()
        
        // Run all tasks in parallel with timeout
        await withTaskGroup(of: Void.self) { group in
            // Task 1: Preload poems (25% of progress)
            group.addTask {
                await self.preloadPoems()
            }
            
            // Task 2: Preload playlists (25% of progress)
            group.addTask {
                await self.preloadPlaylists()
            }
            
            // Task 3: Preload albums (25% of progress)
            group.addTask {
                await self.preloadAlbums()
            }
            
            // Task 4: Preload additional content (25% of progress)
            group.addTask {
                await self.preloadAdditionalContent()
            }
            
            // Wait for all tasks with timeout
            let timeout = Task {
                try? await Task.sleep(nanoseconds: UInt64(self.maxLoadingTime * 1_000_000_000))
            }
            
            for await _ in group {
                // Tasks complete
            }
            
            timeout.cancel()
        }
        
        // Ensure minimum loading time for smooth transition (3 seconds)
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < minLoadingTime {
            try? await Task.sleep(nanoseconds: UInt64((minLoadingTime - elapsed) * 1_000_000_000))
        }
        
        isLoading = false
        loadingProgress = 1.0
        print("✅ Content preloading completed in \(Date().timeIntervalSince(startTime))s")
    }
    
    // MARK: - Preload Poems
    private func preloadPoems() async {
        loadingMessage = "Loading poems..."
        
        let poetryService = PoetryService()
        let poems = await poetryService.fetchPoems(limit: 100, offset: 0, useCache: true)
        
        preloadedPoems = poems
        loadingProgress += 0.25
        
        // Preload more poem artworks (first 30 instead of 20)
        let artworkURLs = poems.prefix(30).compactMap { poem -> URL? in
            guard let urlString = poem.artwork_url else { return nil }
            return URL(string: urlString)
        }
        
        if !artworkURLs.isEmpty {
            ImageCacheManager.shared.preloadImages(urls: artworkURLs, priority: .userInitiated)
        }
        
        print("✅ Preloaded \(poems.count) poems and \(artworkURLs.count) artworks")
    }
    
    // MARK: - Preload Playlists
    private func preloadPlaylists() async {
        loadingMessage = "Loading playlists..."
        
        // Check if authorized
        guard MusicAuthorization.currentStatus == .authorized else {
            loadingProgress += 0.25
            print("⚠️ Not authorized for Apple Music, skipping playlist preload")
            return
        }
        
        do {
            // Fetch multiple playlist searches in parallel for better coverage
            async let persianClassical = fetchPlaylists(term: "persian classical", limit: 15)
            async let iranianTraditional = fetchPlaylists(term: "iranian traditional music", limit: 10)
            async let persianMusic = fetchPlaylists(term: "persian music", limit: 10)
            
            let allPlaylists = await [persianClassical, iranianTraditional, persianMusic].flatMap { $0 }
            
            // Remove duplicates by ID
            var seenIds = Set<String>()
            let uniquePlaylists = allPlaylists.filter { playlist in
                let id = playlist.id.rawValue
                if seenIds.contains(id) {
                    return false
                }
                seenIds.insert(id)
                return true
            }
            
            preloadedPlaylists = Array(uniquePlaylists.prefix(25))
            loadingProgress += 0.25
            
            // Preload ALL playlist artworks with high priority
            let artworkURLs = uniquePlaylists.compactMap { playlist -> URL? in
                playlist.artwork?.url(width: 300, height: 300)
            }
            
            if !artworkURLs.isEmpty {
                ImageCacheManager.shared.preloadImages(urls: artworkURLs, priority: .userInitiated)
                print("🖼️ Preloading \(artworkURLs.count) playlist artworks")
            }
            
            // Cache all playlist metadata
            for playlist in uniquePlaylists {
                CoreDataManager.shared.cachePlaylist(
                    id: playlist.id.rawValue,
                    name: playlist.name,
                    curator: playlist.curatorName,
                    artworkUrl: playlist.artwork?.url(width: 300, height: 300)?.absoluteString
                )
            }
            
            print("✅ Preloaded \(uniquePlaylists.count) unique playlists with \(artworkURLs.count) artworks")
        } catch {
            loadingProgress += 0.25
            print("❌ Failed to preload playlists: \(error.localizedDescription)")
        }
    }
    
    private func fetchPlaylists(term: String, limit: Int) async -> [MusicKit.Playlist] {
        do {
            var request = MusicCatalogSearchRequest(term: term, types: [MusicKit.Playlist.self])
            request.limit = limit
            let response = try await request.response()
            return Array(response.playlists)
        } catch {
            print("❌ Failed to fetch playlists for '\(term)': \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Preload Albums
    private func preloadAlbums() async {
        loadingMessage = "Loading albums..."
        
        // Check if authorized
        guard MusicAuthorization.currentStatus == .authorized else {
            loadingProgress += 0.25
            print("⚠️ Not authorized for Apple Music, skipping album preload")
            return
        }
        
        do {
            // Fetch multiple album searches in parallel for better coverage
            async let persianTraditional = fetchAlbums(term: "persian traditional", limit: 15)
            async let iranianMusic = fetchAlbums(term: "iranian music", limit: 10)
            async let santoorMusic = fetchAlbums(term: "santoor", limit: 8)
            async let tarMusic = fetchAlbums(term: "tar persian", limit: 8)
            
            let allAlbums = await [persianTraditional, iranianMusic, santoorMusic, tarMusic].flatMap { $0 }
            
            // Remove duplicates by ID
            var seenIds = Set<String>()
            let uniqueAlbums = allAlbums.filter { album in
                let id = album.id.rawValue
                if seenIds.contains(id) {
                    return false
                }
                seenIds.insert(id)
                return true
            }
            
            preloadedAlbums = Array(uniqueAlbums.prefix(25))
            loadingProgress += 0.25
            
            // Preload ALL album artworks with high priority
            let artworkURLs = uniqueAlbums.compactMap { album -> URL? in
                album.artwork?.url(width: 300, height: 300)
            }
            
            if !artworkURLs.isEmpty {
                ImageCacheManager.shared.preloadImages(urls: artworkURLs, priority: .userInitiated)
                print("🖼️ Preloading \(artworkURLs.count) album artworks")
            }
            
            // Cache all album metadata
            for album in uniqueAlbums {
                CoreDataManager.shared.cacheAlbum(
                    id: album.id.rawValue,
                    name: album.title,
                    artist: album.artistName,
                    artworkUrl: album.artwork?.url(width: 300, height: 300)?.absoluteString
                )
            }
            
            print("✅ Preloaded \(uniqueAlbums.count) unique albums with \(artworkURLs.count) artworks")
        } catch {
            loadingProgress += 0.25
            print("❌ Failed to preload albums: \(error.localizedDescription)")
        }
    }
    
    private func fetchAlbums(term: String, limit: Int) async -> [MusicKit.Album] {
        do {
            var request = MusicCatalogSearchRequest(term: term, types: [MusicKit.Album.self])
            request.limit = limit
            let response = try await request.response()
            return Array(response.albums)
        } catch {
            print("❌ Failed to fetch albums for '\(term)': \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Preload Additional Content
    private func preloadAdditionalContent() async {
        loadingMessage = "Preparing content..."
        
        // Cache Apple Music authorization status
        let authStatus = await MusicAuthCacheManager.shared.getAuthStatus()
        print("🔐 Cached auth status: \(authStatus)")
        
        // Clean old cached data in background
        CoreDataManager.shared.clearOldPoems(olderThan: 7)
        
        // Preload recently played tracks for quick access
        let recentlyPlayed = CoreDataManager.shared.fetchRecentlyPlayed(limit: 20)
        print("🎵 Loaded \(recentlyPlayed.count) recently played tracks")
        
        // Preload recently played artworks
        let recentArtworkURLs = recentlyPlayed.compactMap { item -> URL? in
            guard let urlString = item.artworkUrl else { return nil }
            return URL(string: urlString)
        }
        
        if !recentArtworkURLs.isEmpty {
            ImageCacheManager.shared.preloadImages(urls: recentArtworkURLs)
            print("🎨 Preloaded \(recentArtworkURLs.count) recently played artworks")
        }
        
        loadingProgress += 0.25
        print("✅ Additional content preloaded")
    }
    
    // MARK: - Get Preloaded Data
    func getPreloadedPoems() -> [PoemData] {
        return preloadedPoems
    }
    
    func getPreloadedPlaylists() -> [MusicKit.Playlist] {
        return preloadedPlaylists
    }
    
    func getPreloadedAlbums() -> [MusicKit.Album] {
        return preloadedAlbums
    }
}



