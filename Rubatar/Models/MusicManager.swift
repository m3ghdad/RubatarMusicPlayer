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
        // Temporarily use sample data to avoid relying on MusicKit library requests
        // with custom model types. You can re-enable MusicKit fetching by mapping
        // MusicKit.Album/Playlist into these app models.
        if authorizationStatus != .authorized {
            await requestAuthorization()
        }
        // If still not authorized, just load samples for a graceful UI.
        guard authorizationStatus == .authorized else {
            loadSampleMusic()
            return
        }
        isLoading = true
        error = nil
        // TODO: Implement real MusicKit fetching and map results to Album/Playlist app models.
        // For now, load sample data to keep the app building and running.
        loadSampleMusic()
        isLoading = false
    }
    
    func loadSampleMusic() {
        // Load your curated Persian music albums and playlists
        albums = [
            Album(
                id: "1",
                title: "Gypsy Wind",
                artist: "Sohrab Pournazeri",
                artwork: CustomArtwork(url: URL(string: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop")!),
                trackCount: 12,
                releaseDate: Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 1)) ?? Date()
            ),
            Album(
                id: "2",
                title: "Voices of the Shades (Saamaan-e-saayeh'haa)",
                artist: "Kayhan Kalhor & Madjid Khaladj",
                artwork: CustomArtwork(url: URL(string: "https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400&h=400&fit=crop")!),
                trackCount: 8,
                releaseDate: Calendar.current.date(from: DateComponents(year: 2019, month: 6, day: 15)) ?? Date()
            ),
            Album(
                id: "3",
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

