//
//  ContentModels.swift
//  Rubatar
//
//  Created by AI Assistant on 01/21/25.
//

import Foundation

// MARK: - Content Section Models

struct ContentSection: Codable, Identifiable {
    let id: String
    let type: String // "playlists" or "albums"
    let title: String
    let displayOrder: Int
    let isVisible: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case displayOrder = "display_order"
        case isVisible = "is_visible"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Featured Playlist Model

struct FeaturedPlaylist: Codable, Identifiable {
    let id: String
    let sectionId: String
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
    let id: String
    let sectionId: String
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

extension ContentResponse {
    /// Get playlists for a specific section
    func playlists(for section: ContentSection) -> [FeaturedPlaylist] {
        return playlists.filter { $0.sectionId == section.id && $0.isVisible }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    /// Get albums for a specific section
    func albums(for section: ContentSection) -> [FeaturedAlbum] {
        return albums.filter { $0.sectionId == section.id && $0.isVisible }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    /// Get all visible sections
    var visibleSections: [ContentSection] {
        return sections.filter { $0.isVisible }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
}
