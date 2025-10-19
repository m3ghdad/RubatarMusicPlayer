//
//  MusicManager.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import Foundation
import MusicKit
import SwiftUI
import Combine

@MainActor
class MusicManager: ObservableObject {
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var albums: [Album] = []
    @Published var playlists: [Playlist] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    init() {
        authorizationStatus = MusicAuthorization.currentStatus
    }
    
    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        authorizationStatus = status
    }
    
    func loadMusicLibrary() async {
        if authorizationStatus != .authorized {
            await requestAuthorization()
        }
        
        guard authorizationStatus == .authorized else {
            loadSampleMusic()
            return
        }
        
        isLoading = true
        error = nil
        
        // Search for the specific Persian albums by name and artist
        await loadPersianAlbums()
        await loadPersianPlaylists()
        
        // If no albums found, fallback to sample data
        if albums.isEmpty {
            loadSampleMusic()
        }
        
        isLoading = false
    }
    
    private func loadPersianAlbums() async {
        let albumSearches = [
            ("Gypsy Wind", "Sohrab Pournazeri"),
            ("Voices of the Shades", "Kayhan Kalhor"),
            ("Setar Improvisation", "Keivan Saket")
        ]
        
        var foundAlbums: [Album] = []
        
        for (albumName, artistName) in albumSearches {
            do {
                let searchRequest = MusicCatalogSearchRequest(
                    term: "\(albumName) \(artistName)",
                    types: [MusicKit.Album.self]
                )
                
                let searchResponse = try await searchRequest.response()
                
                if let musicKitAlbum = searchResponse.albums.first {
                    let album = Album(
                        id: musicKitAlbum.id.rawValue,
                        title: musicKitAlbum.title,
                        artist: musicKitAlbum.artistName,
                        artwork: CustomArtwork(url: musicKitAlbum.artwork?.url(width: 400, height: 400) ?? URL(string: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop")!),
                        trackCount: musicKitAlbum.trackCount,
                        releaseDate: musicKitAlbum.releaseDate ?? Date()
                    )
                    foundAlbums.append(album)
                }
            } catch {
                print("Error searching for album \(albumName): \(error)")
            }
        }
        
        self.albums = foundAlbums
    }
    
    private func loadPersianPlaylists() async {
        // Search for Persian music playlists
        let playlistSearches = [
            ("Setar", "Persian traditional music"),
            ("Santur", "Persian classical"),
            ("Kamancheh", "Persian instrumental")
        ]
        
        var foundPlaylists: [Playlist] = []
        
        for (instrument, searchTerm) in playlistSearches {
            do {
                var searchRequest = MusicCatalogSearchRequest(
                    term: "\(instrument) \(searchTerm)",
                    types: [MusicKit.Playlist.self]
                )
                searchRequest.limit = 5 // Get more results to find better matches
                
                let searchResponse = try await searchRequest.response()
                
                if let musicKitPlaylist = searchResponse.playlists.first {
                    let playlist = Playlist(
                        id: musicKitPlaylist.id.rawValue,
                        title: musicKitPlaylist.name,
                        curatorName: musicKitPlaylist.curatorName ?? "Apple Music",
                        artwork: CustomArtwork(url: musicKitPlaylist.artwork?.url(width: 400, height: 400) ?? URL(string: "https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=400&h=400&fit=crop")!),
                        trackCount: 15, // Default track count since MusicKit Playlist doesn't have trackCount
                        description: musicKitPlaylist.description
                    )
                    foundPlaylists.append(playlist)
                    print("✅ Found playlist: \(musicKitPlaylist.name) with artwork: \(musicKitPlaylist.artwork?.url(width: 400, height: 400)?.absoluteString ?? "none")")
                } else {
                    print("⚠️ No playlist found for \(instrument)")
                }
            } catch {
                print("Error searching for playlist \(instrument): \(error)")
            }
        }
        
        // If no playlists found, use sample data
        if foundPlaylists.isEmpty {
            loadSamplePlaylists()
        } else {
            self.playlists = foundPlaylists
        }
    }
    
    private func loadSamplePlaylists() {
        playlists = [
            Playlist(
                id: "1",
                title: "Setar سه تار",
                curatorName: "Matin Baghani",
                artwork: CustomArtwork(url: URL(string: "https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=400&h=400&fit=crop")!),
                trackCount: 15,
                description: "Beautiful Setar performances and traditional Persian music"
            ),
            Playlist(
                id: "2",
                title: "Kamkars Santur کامکارها / سنتور",
                curatorName: "Siavash Kamkar",
                artwork: CustomArtwork(url: URL(string: "https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=400&h=400&fit=crop")!),
                trackCount: 20,
                description: "Masterful Santur performances by the Kamkar family"
            ),
            Playlist(
                id: "3",
                title: "Kamancheh Instrumental | کمانچه",
                curatorName: "Mekuvenet",
                artwork: CustomArtwork(url: URL(string: "https://images.unsplash.com/photo-1520523839897-bd0b52f945a0?w=400&h=400&fit=crop")!),
                trackCount: 18,
                description: "Emotional Kamancheh instrumentals and Persian classical music"
            )
        ]
    }
    
    func loadSampleMusic() {
        // Load albums with real Apple Music IDs
        albums = [
            Album(
                id: "1791770486",
                title: "Gypsy Wind",
                artist: "Sohrab Pournazeri",
                artwork: CustomArtwork(url: URL(string: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop")!),
                trackCount: 12,
                releaseDate: Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 1)) ?? Date()
            ),
            Album(
                id: "441355991",
                title: "Voices of the Shades (Saamaan-e-saayeh'haa)",
                artist: "Kayhan Kalhor & Madjid Khaladj",
                artwork: CustomArtwork(url: URL(string: "https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400&h=400&fit=crop")!),
                trackCount: 8,
                releaseDate: Calendar.current.date(from: DateComponents(year: 2019, month: 6, day: 15)) ?? Date()
            ),
            Album(
                id: "1570201002",
                title: "Setar Improvisation",
                artist: "Keivan Saket",
                artwork: CustomArtwork(url: URL(string: "https://images.unsplash.com/photo-1571330735066-03aaa9429d89?w=400&h=400&fit=crop")!),
                trackCount: 10,
                releaseDate: Calendar.current.date(from: DateComponents(year: 2021, month: 3, day: 20)) ?? Date()
            )
        ]
        
        playlists = [
            Playlist(
                id: "1",
                title: "Setar سه تار",
                curatorName: "Matin Baghani",
                artwork: CustomArtwork(url: URL(string: "https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=400&h=400&fit=crop")!),
                trackCount: 15,
                description: "Beautiful Setar performances and traditional Persian music"
            ),
            Playlist(
                id: "2",
                title: "Kamkars Santur کامکارها / سنتور",
                curatorName: "Siavash Kamkar",
                artwork: CustomArtwork(url: URL(string: "https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=400&h=400&fit=crop")!),
                trackCount: 20,
                description: "Masterful Santur performances by the Kamkar family"
            ),
            Playlist(
                id: "3",
                title: "Kamancheh Instrumental | کمانچه",
                curatorName: "Mekuvenet",
                artwork: CustomArtwork(url: URL(string: "https://images.unsplash.com/photo-1520523839897-bd0b52f945a0?w=400&h=400&fit=crop")!),
                trackCount: 18,
                description: "Emotional Kamancheh instrumentals and Persian classical music"
            )
        ]
    }
}

