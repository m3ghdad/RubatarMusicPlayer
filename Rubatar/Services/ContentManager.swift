//
//  ContentManager.swift
//  Rubatar
//
//  Created by AI Assistant on 01/21/25.
//

import Foundation
import Combine

@MainActor
class ContentManager: ObservableObject, ContentManagerProtocol {
    
    // MARK: - Published Properties
    
    @Published var loadingState: ContentLoadingState = .loading
    @Published var playlists: [FeaturedPlaylist] = []
    @Published var albums: [FeaturedAlbum] = []
    @Published var sections: [ContentSection] = []
    
    // MARK: - Private Properties
    
    private let baseURL: String
    private let apiKey: String
    private let cacheKey = "rubatar_content_cache"
    private let cacheExpiryKey = "rubatar_content_cache_expiry"
    private let cacheExpiryHours: TimeInterval = 24 // Cache for 24 hours
    
    // MARK: - Initialization
    
    init() {
        // Use your Supabase project credentials
        self.baseURL = Config.supabaseURL
        self.apiKey = Config.supabaseAnonKey
        
        // Load cached content immediately
        loadCachedContent()
        
        // Fetch fresh content in background
        Task {
            await fetchContent()
        }
    }
    
    // MARK: - Public Methods
    
    func fetchContent() async {
        do {
            print("🔄 ContentManager: Fetching content from Supabase...")
            
            // Fetch sections
            let sectionsResponse: [ContentSection] = try await fetchFromSupabase(
                table: "content_sections",
                query: "is_visible=eq.true&order=display_order"
            )
            
            // Fetch playlists
            let playlistsResponse: [FeaturedPlaylist] = try await fetchFromSupabase(
                table: "featured_playlists",
                query: "is_visible=eq.true&order=display_order"
            )
            
            // Fetch albums
            let albumsResponse: [FeaturedAlbum] = try await fetchFromSupabase(
                table: "featured_albums",
                query: "is_visible=eq.true&order=display_order"
            )
            
            // Create content response
            let contentResponse = ContentResponse(
                sections: sectionsResponse,
                playlists: playlistsResponse,
                albums: albumsResponse,
                lastUpdated: ISO8601DateFormatter().string(from: Date())
            )
            
            // Update published properties
            self.sections = sectionsResponse
            self.playlists = playlistsResponse
            self.albums = albumsResponse
            self.loadingState = .loaded(contentResponse)
            
            // Cache the content
            cacheContent(contentResponse)
            
            print("✅ ContentManager: Successfully loaded \(sectionsResponse.count) sections, \(playlistsResponse.count) playlists, \(albumsResponse.count) albums")
            
        } catch {
            print("❌ ContentManager: Failed to fetch content - \(error)")
            
            // If we have cached content, use it
            if case .loaded(let cachedContent) = loadingState {
                self.loadingState = .offline(cachedContent)
                print("📱 ContentManager: Using cached content (offline mode)")
            } else {
                self.loadingState = .error("Failed to load content: \(error.localizedDescription)")
            }
        }
    }
    
    func refreshContent() async {
        print("🔄 ContentManager: Refreshing content...")
        await fetchContent()
    }
    
    // MARK: - Private Methods
    
    private func fetchFromSupabase<T: Codable>(table: String, query: String) async throws -> [T] {
        let urlString = "\(baseURL)/rest/v1/\(table)?\(query)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([T].self, from: data)
    }
    
    private func loadCachedContent() {
        guard let cachedData = UserDefaults.standard.data(forKey: cacheKey),
              let contentResponse = try? JSONDecoder().decode(ContentResponse.self, from: cachedData) else {
            print("📱 ContentManager: No cached content found")
            return
        }
        
        // Check if cache is still valid
        let cacheExpiry = UserDefaults.standard.double(forKey: cacheExpiryKey)
        let now = Date().timeIntervalSince1970
        
        if now < cacheExpiry {
            // Cache is still valid
            self.sections = contentResponse.sections
            self.playlists = contentResponse.playlists
            self.albums = contentResponse.albums
            self.loadingState = .loaded(contentResponse)
            print("📱 ContentManager: Loaded cached content (valid until \(Date(timeIntervalSince1970: cacheExpiry)))")
        } else {
            print("📱 ContentManager: Cached content expired")
        }
    }
    
    private func cacheContent(_ content: ContentResponse) {
        do {
            let data = try JSONEncoder().encode(content)
            UserDefaults.standard.set(data, forKey: cacheKey)
            
            // Set cache expiry
            let expiryTime = Date().timeIntervalSince1970 + (cacheExpiryHours * 3600)
            UserDefaults.standard.set(expiryTime, forKey: cacheExpiryKey)
            
            print("💾 ContentManager: Content cached successfully")
        } catch {
            print("❌ ContentManager: Failed to cache content - \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get playlists for a specific section
    func playlists(for section: ContentSection) -> [FeaturedPlaylist] {
        return playlists.filter { $0.sectionId == section.id }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    /// Get albums for a specific section
    func albums(for section: ContentSection) -> [FeaturedAlbum] {
        return albums.filter { $0.sectionId == section.id }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    /// Get all visible sections
    var visibleSections: [ContentSection] {
        return sections.filter { $0.isVisible }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    /// Check if content is currently loading
    var isLoading: Bool {
        if case .loading = loadingState {
            return true
        }
        return false
    }
    
    /// Check if content is in offline mode
    var isOffline: Bool {
        if case .offline = loadingState {
            return true
        }
        return false
    }
    
    /// Get error message if any
    var errorMessage: String? {
        if case .error(let message) = loadingState {
            return message
        }
        return nil
    }
}

// MARK: - Content Manager Extensions

extension ContentManager {
    
    /// Get playlist by Apple Music ID
    func playlist(with applePlaylistId: String) -> FeaturedPlaylist? {
        return playlists.first { $0.applePlaylistId == applePlaylistId }
    }
    
    /// Get section by type
    func section(ofType type: String) -> ContentSection? {
        return sections.first { $0.type == type && $0.isVisible }
    }
    
    /// Get playlists section
    var playlistsSection: ContentSection? {
        return section(ofType: "playlists")
    }
    
    /// Get albums section
    var albumsSection: ContentSection? {
        return section(ofType: "albums")
    }
}
