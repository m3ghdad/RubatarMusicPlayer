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
    
    private let maxLoadingTime: TimeInterval = 2.0 // Max 2 seconds
    
    // Preloaded data
    @Published var preloadedPoems: [PoemData] = []
    @Published var preloadedPlaylists: [MusicKit.Playlist] = []
    @Published var preloadedAlbums: [MusicKit.Album] = []
    
    func preloadContent() async {
        let startTime = Date()
        
        // Run all tasks in parallel with timeout
        await withTaskGroup(of: Void.self) { group in
            // Task 1: Preload poems (30% of progress)
            group.addTask {
                await self.preloadPoems()
            }
            
            // Task 2: Preload playlists (35% of progress)
            group.addTask {
                await self.preloadPlaylists()
            }
            
            // Task 3: Preload albums (35% of progress)
            group.addTask {
                await self.preloadAlbums()
            }
            
            // Wait for all tasks or timeout
            for await _ in group {
                // Tasks complete
            }
        }
        
        // Ensure minimum loading time for smooth transition
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < 0.5 {
            try? await Task.sleep(nanoseconds: UInt64((0.5 - elapsed) * 1_000_000_000))
        }
        
        isLoading = false
        print("✅ Content preloading completed in \(Date().timeIntervalSince(startTime))s")
    }
    
    // MARK: - Preload Poems
    private func preloadPoems() async {
        loadingMessage = "Loading poems..."
        
        let poetryService = PoetryService()
        let poems = await poetryService.fetchPoems(limit: 100, offset: 0, useCache: true)
        
        preloadedPoems = poems
        loadingProgress += 0.3
        
        // Preload first few poem artworks
        let artworkURLs = poems.prefix(5).compactMap { poem -> URL? in
            guard let urlString = poem.artwork_url else { return nil }
            return URL(string: urlString)
        }
        
        if !artworkURLs.isEmpty {
            ImageCacheManager.shared.preloadImages(urls: artworkURLs)
        }
        
        print("✅ Preloaded \(poems.count) poems")
    }
    
    // MARK: - Preload Playlists
    private func preloadPlaylists() async {
        loadingMessage = "Loading playlists..."
        
        // Check if authorized
        guard MusicAuthorization.currentStatus == .authorized else {
            loadingProgress += 0.35
            print("⚠️ Not authorized for Apple Music, skipping playlist preload")
            return
        }
        
        do {
            // Fetch curated playlists (similar to what's shown in HomeView)
            var request = MusicCatalogSearchRequest(term: "persian classical", types: [MusicKit.Playlist.self])
            request.limit = 10
            
            let response = try await request.response()
            let playlists = Array(response.playlists.prefix(10))
            
            preloadedPlaylists = playlists
            loadingProgress += 0.35
            
            // Preload playlist artworks
            let artworkURLs = playlists.compactMap { playlist -> URL? in
                playlist.artwork?.url(width: 300, height: 300)
            }
            
            if !artworkURLs.isEmpty {
                ImageCacheManager.shared.preloadImages(urls: artworkURLs)
            }
            
            // Cache playlist metadata
            for playlist in playlists {
                CoreDataManager.shared.cachePlaylist(
                    id: playlist.id.rawValue,
                    name: playlist.name,
                    curator: playlist.curatorName,
                    artworkUrl: playlist.artwork?.url(width: 300, height: 300)?.absoluteString
                )
            }
            
            print("✅ Preloaded \(playlists.count) playlists")
        } catch {
            loadingProgress += 0.35
            print("❌ Failed to preload playlists: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Preload Albums
    private func preloadAlbums() async {
        loadingMessage = "Loading albums..."
        
        // Check if authorized
        guard MusicAuthorization.currentStatus == .authorized else {
            loadingProgress += 0.35
            print("⚠️ Not authorized for Apple Music, skipping album preload")
            return
        }
        
        do {
            // Fetch albums (similar to what's shown in HomeView)
            var request = MusicCatalogSearchRequest(term: "persian traditional", types: [MusicKit.Album.self])
            request.limit = 10
            
            let response = try await request.response()
            let albums = Array(response.albums.prefix(10))
            
            preloadedAlbums = albums
            loadingProgress += 0.35
            
            // Preload album artworks
            let artworkURLs = albums.compactMap { album -> URL? in
                album.artwork?.url(width: 300, height: 300)
            }
            
            if !artworkURLs.isEmpty {
                ImageCacheManager.shared.preloadImages(urls: artworkURLs)
            }
            
            // Cache album metadata
            for album in albums {
                CoreDataManager.shared.cacheAlbum(
                    id: album.id.rawValue,
                    name: album.title,
                    artist: album.artistName,
                    artworkUrl: album.artwork?.url(width: 300, height: 300)?.absoluteString
                )
            }
            
            print("✅ Preloaded \(albums.count) albums")
        } catch {
            loadingProgress += 0.35
            print("❌ Failed to preload albums: \(error.localizedDescription)")
        }
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

