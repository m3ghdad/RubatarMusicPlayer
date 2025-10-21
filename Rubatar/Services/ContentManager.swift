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
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheExpiryKey)
        print("🗑️ ContentManager: Cache cleared")
    }
    
    func fetchContent() async {
        // TEMPORARY: Add delay to see skeleton view (REMOVE AFTER TESTING)
        // try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds delay
        
        // Clear cache to force fresh fetch
        clearCache()
        
        do {
            print("🔄 ContentManager: Fetching content from Supabase...")
            print("🌐 ContentManager: Base URL: \(baseURL)")
            print("🌐 ContentManager: API Key: \(apiKey.prefix(20))...")
            
            // Fetch sections
            let sectionsResponse: [ContentSection] = try await fetchFromSupabase(
                table: "content_sections",
                query: "is_visible=eq.true&order=display_order.asc&select=id,type,title,display_order,is_visible,layout_type,created_at,updated_at"
            )
            
            // Fetch playlists
            let playlistsResponse: [FeaturedPlaylist] = try await fetchFromSupabase(
                table: "featured_playlists",
                query: "is_visible=eq.true&order=display_order.asc&select=*"
            )
            
            // Fetch albums
            let albumsResponse: [FeaturedAlbum] = try await fetchFromSupabase(
                table: "featured_albums",
                query: "is_visible=eq.true&order=display_order.asc&select=*"
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
            
            // Try to use cached content first
            if case .loaded(let cachedContent) = loadingState {
                self.loadingState = .offline(cachedContent)
                print("📱 ContentManager: Using cached content (offline mode)")
            } else {
                // Fallback to hardcoded data if no cache
                print("📱 ContentManager: No cached content, using fallback data")
                self.loadFallbackData()
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
        print("🌐 ContentManager: Fetching from URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ ContentManager: Invalid URL: \(urlString)")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("🌐 ContentManager: Making request to \(urlString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 ContentManager: Response status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("❌ ContentManager: HTTP Error \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("🌐 ContentManager: Response body: \(responseString)")
                    }
                    throw URLError(.badServerResponse)
                } else {
                    // Debug: Print the actual response for successful requests
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("🌐 ContentManager: Response body: \(responseString)")
                    }
                }
            }
            
            let decoder = JSONDecoder()
            // Don't use convertFromSnakeCase since we have custom CodingKeys
            let result = try decoder.decode([T].self, from: data)
            print("✅ ContentManager: Successfully decoded \(result.count) items from \(table)")
            return result
        } catch {
            print("❌ ContentManager: Network error: \(error)")
            throw error
        }
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
    
    // Note: Extension methods temporarily removed due to UUID comparison issues
    // TODO: Fix UUID optional comparison in the future
    
    /// Load fallback data when network fails
    private func loadFallbackData() {
        print("📱 ContentManager: Loading fallback data...")
        
        // Create fallback playlists
        let fallbackPlaylists = [
            FeaturedPlaylist(
                id: UUID(),
                sectionId: nil,
                applePlaylistId: "pl.u-vEe5t44Rjbm",
                coverImageUrl: "Setaar",
                instrumentImageUrl: nil,
                footerText: "Se Tār | سه تار",
                customTitle: "The Dance of Silence | رقص سکوت",
                customCurator: "Se Tār | سه تار",
                customDescription: "A meditative journey where the سه‌تار (Se Tār) weaves joy and silence into one graceful breath.",
                displayOrder: 1,
                isVisible: true,
                createdAt: "2025-01-21T00:00:00Z",
                updatedAt: "2025-01-21T00:00:00Z"
            ),
            FeaturedPlaylist(
                id: UUID(),
                sectionId: nil,
                applePlaylistId: "pl.u-AqK9HDDXK5a",
                coverImageUrl: "Santoor",
                instrumentImageUrl: nil,
                footerText: "Santoor | سنتور",
                customTitle: "Melody of Water | نغمه آب",
                customCurator: "Santoor | سنتور",
                customDescription: "A tranquil reflection where the سنتور (Santoor) speaks in ripples of light, echoing thought and memory into still air.",
                displayOrder: 2,
                isVisible: true,
                createdAt: "2025-01-21T00:00:00Z",
                updatedAt: "2025-01-21T00:00:00Z"
            ),
            FeaturedPlaylist(
                id: UUID(),
                sectionId: nil,
                applePlaylistId: "pl.u-bvj8T00GXMg",
                coverImageUrl: "Kamancheh",
                instrumentImageUrl: nil,
                footerText: "Kamancheh | کمانچه",
                customTitle: "The Shadow of Time | سایه زمان",
                customCurator: "Kamancheh | کمانچه",
                customDescription: "A reflective journey where the کمانچه (Kamancheh) sings of seasons, distance, and the gentle passing of time.",
                displayOrder: 3,
                isVisible: true,
                createdAt: "2025-01-21T00:00:00Z",
                updatedAt: "2025-01-21T00:00:00Z"
            ),
            // Add mood playlists to fallback data
            FeaturedPlaylist(
                id: UUID(),
                sectionId: UUID(uuidString: "4f9e5f5f-3a27-4932-81f0-6881ce4d76ef"),
                applePlaylistId: "pl.u-vEe5t44Rjbm",
                coverImageUrl: "Setaar",
                instrumentImageUrl: nil,
                footerText: "گلچین تار و سه‌تار ایران",
                customTitle: "گلچین تار و سه‌تار ایران",
                customCurator: "Persian Classical",
                customDescription: "A curated collection of Persian classical music featuring Tar and Setar",
                displayOrder: 1,
                isVisible: true,
                createdAt: "2025-01-21T00:00:00Z",
                updatedAt: "2025-01-21T00:00:00Z"
            ),
            FeaturedPlaylist(
                id: UUID(),
                sectionId: UUID(uuidString: "4f9e5f5f-3a27-4932-81f0-6881ce4d76ef"),
                applePlaylistId: "pl.u-AqK9HDDXK5a",
                coverImageUrl: "Santoor",
                instrumentImageUrl: nil,
                footerText: "سه‌تار (Setar)",
                customTitle: "سه‌تار (Setar)",
                customCurator: "Persian Classical",
                customDescription: "Traditional Persian Setar music",
                displayOrder: 2,
                isVisible: true,
                createdAt: "2025-01-21T00:00:00Z",
                updatedAt: "2025-01-21T00:00:00Z"
            ),
            FeaturedPlaylist(
                id: UUID(),
                sectionId: UUID(uuidString: "4f9e5f5f-3a27-4932-81f0-6881ce4d76ef"),
                applePlaylistId: "pl.u-bvj8T00GXMg",
                coverImageUrl: "Kamancheh",
                instrumentImageUrl: nil,
                footerText: "Kamkars Santur",
                customTitle: "Kamkars Santur",
                customCurator: "Persian Classical",
                customDescription: "Traditional Persian Santur music",
                displayOrder: 3,
                isVisible: true,
                createdAt: "2025-01-21T00:00:00Z",
                updatedAt: "2025-01-21T00:00:00Z"
            ),
            FeaturedPlaylist(
                id: UUID(),
                sectionId: UUID(uuidString: "4f9e5f5f-3a27-4932-81f0-6881ce4d76ef"),
                applePlaylistId: "pl.u-vEe5t44Rjbm",
                coverImageUrl: "Setaar",
                instrumentImageUrl: nil,
                footerText: "Santur Solo in Abuata",
                customTitle: "Santur Solo in Abuata",
                customCurator: "Persian Classical",
                customDescription: "Traditional Persian Santur solo performance",
                displayOrder: 4,
                isVisible: true,
                createdAt: "2025-01-21T00:00:00Z",
                updatedAt: "2025-01-21T00:00:00Z"
            )
        ]
        
        // Create fallback albums with real Apple Music albums
        let fallbackAlbums = [
            FeaturedAlbum(
                id: UUID(),
                sectionId: nil,
                appleAlbumUrl: "https://music.apple.com/us/album/gypsy-wind/1791770486",
                appleAlbumId: "1791770486",
                customTitle: "Gypsy Wind",
                customArtist: "Sohrab Pournazeri",
                customImageUrl: "Setaar",
                displayOrder: 1,
                isVisible: true,
                createdAt: "2025-01-21T00:00:00Z",
                updatedAt: "2025-01-21T00:00:00Z"
            ),
            FeaturedAlbum(
                id: UUID(),
                sectionId: nil,
                appleAlbumUrl: "https://music.apple.com/us/album/setar-improvisation/1570201002",
                appleAlbumId: "1570201002",
                customTitle: "Setar Improvisation",
                customArtist: "Keivan Saket",
                customImageUrl: "Santoor",
                displayOrder: 2,
                isVisible: true,
                createdAt: "2025-01-21T00:00:00Z",
                updatedAt: "2025-01-21T00:00:00Z"
            ),
            FeaturedAlbum(
                id: UUID(),
                sectionId: nil,
                appleAlbumUrl: "https://music.apple.com/us/album/voices-of-the-shades-saamaan-e-saayehhaa/441355991",
                appleAlbumId: "441355991",
                customTitle: "Voices of the Shades (Saamaan-e saayeh'haa)",
                customArtist: "Kayhan Kalhor & Madjid Khaladj",
                customImageUrl: "Kamancheh",
                displayOrder: 3,
                isVisible: true,
                createdAt: "2025-01-21T00:00:00Z",
                updatedAt: "2025-01-21T00:00:00Z"
            ),
            FeaturedAlbum(
                id: UUID(),
                sectionId: nil,
                appleAlbumUrl: "https://music.apple.com/us/album/grind-fine-diamonds-riz-danehaye-almas-contemporary/828182055",
                appleAlbumId: "828182055",
                customTitle: "Grind Fine Diamonds (Riz Danehaye Almas) - Contemporary",
                customArtist: "Ardavan Kamkar",
                customImageUrl: "Setaar",
                displayOrder: 4,
                isVisible: true,
                createdAt: "2025-01-21T00:00:00Z",
                updatedAt: "2025-01-21T00:00:00Z"
            )
        ]
        
        self.playlists = fallbackPlaylists
        self.albums = fallbackAlbums
        self.sections = []
        self.loadingState = .loaded(ContentResponse(
            sections: [],
            playlists: fallbackPlaylists,
            albums: fallbackAlbums,
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        ))
        
        print("✅ ContentManager: Loaded \(fallbackPlaylists.count) fallback playlists and \(fallbackAlbums.count) fallback albums")
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
