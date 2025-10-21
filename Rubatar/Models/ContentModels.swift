//
//  ContentModels.swift
//  Rubatar
//
//  Created by AI Assistant on 01/21/25.
//

import Foundation

// MARK: - Content Section Models

struct ContentSection: Codable, Identifiable {
    let id: UUID
    let type: String // "playlists" or "albums"
    let title: String
    let displayOrder: Int
    let isVisible: Bool
    let layoutType: String // "vertical" or "horizontal"
    let createdAt: String
    let updatedAt: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        displayOrder = try container.decode(Int.self, forKey: .displayOrder)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        layoutType = try container.decode(String.self, forKey: .layoutType)
        
        // Handle timestamp format with timezone
        let createdAtRaw = try container.decode(String.self, forKey: .createdAt)
        let updatedAtRaw = try container.decode(String.self, forKey: .updatedAt)
        
        // Remove timezone info if present
        createdAt = createdAtRaw.replacingOccurrences(of: "+00:00", with: "Z")
        updatedAt = updatedAtRaw.replacingOccurrences(of: "+00:00", with: "Z")
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case displayOrder = "display_order"
        case isVisible = "is_visible"
        case layoutType = "layout_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Featured Playlist Model

struct FeaturedPlaylist: Codable, Identifiable {
    let id: UUID
    let sectionId: UUID?
    let applePlaylistId: String
    let coverImageUrl: String
    let instrumentImageUrl: String? // Optional since not used currently
    let footerText: String
    let customTitle: String?
    let customCurator: String?
    let customDescription: String?
    let displayOrder: Int
    let isVisible: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case sectionId = "section_id"
        case applePlaylistId = "apple_playlist_id"
        case coverImageUrl = "cover_image_url"
        case instrumentImageUrl = "instrument_image_url"
        case footerText = "footer_text"
        case customTitle = "custom_title"
        case customCurator = "custom_curator"
        case customDescription = "custom_description"
        case displayOrder = "display_order"
        case isVisible = "is_visible"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Computed properties for easy access
    var title: String {
        return customTitle ?? "Playlist"
    }
    
    var curator: String {
        return customCurator ?? "Curator"
    }
    
    var description: String {
        return customDescription ?? "Description"
    }
}

// MARK: - Featured Album Model

struct FeaturedAlbum: Codable, Identifiable {
    let id: UUID
    let sectionId: UUID?
    let appleAlbumUrl: String
    let appleAlbumId: String?
    let customTitle: String?
    let customArtist: String?
    let customImageUrl: String?
    let displayOrder: Int
    let isVisible: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case sectionId = "section_id"
        case appleAlbumUrl = "apple_album_url"
        case appleAlbumId = "apple_album_id"
        case customTitle = "custom_title"
        case customArtist = "custom_artist"
        case customImageUrl = "custom_image_url"
        case displayOrder = "display_order"
        case isVisible = "is_visible"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Computed properties for easy access
    var title: String {
        return customTitle ?? "Album"
    }
    
    var artist: String {
        return customArtist ?? "Artist"
    }
}

// MARK: - Content Response Models

struct ContentResponse: Codable {
    let sections: [ContentSection]
    let playlists: [FeaturedPlaylist]
    let albums: [FeaturedAlbum]
    let lastUpdated: String
    
    enum CodingKeys: String, CodingKey {
        case sections
        case playlists
        case albums
        case lastUpdated = "last_updated"
    }
}

// MARK: - Content Manager State

enum ContentLoadingState {
    case loading
    case loaded(ContentResponse)
    case error(String)
    case offline(ContentResponse) // Cached content when offline
}

// MARK: - Content Manager Protocol

protocol ContentManagerProtocol: ObservableObject {
    var loadingState: ContentLoadingState { get }
    var playlists: [FeaturedPlaylist] { get }
    var albums: [FeaturedAlbum] { get }
    var sections: [ContentSection] { get }
    
    func fetchContent() async
    func refreshContent() async
}

// MARK: - Extensions for Easy Access

// Note: Extension methods temporarily removed due to UUID comparison issues
// TODO: Fix UUID optional comparison in the future
