//
//  MusicManager.swift
//  AppleLiquidGlassTapBar
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
        // Load your curated albums and playlists
        albums = [
            Album(
                id: "1",
                title: "The Dark Side of the Moon",
                artist: "Pink Floyd",
                artwork: CustomArtwork(url: URL(string: "https://upload.wikimedia.org/wikipedia/en/3/3b/Dark_Side_of_the_Moon.png")!),
                trackCount: 9,
                releaseDate: Calendar.current.date(from: DateComponents(year: 1973, month: 3, day: 1)) ?? Date()
            ),
            Album(
                id: "2",
                title: "Abbey Road",
                artist: "The Beatles",
                artwork: CustomArtwork(url: URL(string: "https://upload.wikimedia.org/wikipedia/en/4/42/Beatles_-_Abbey_Road.jpg")!),
                trackCount: 17,
                releaseDate: Calendar.current.date(from: DateComponents(year: 1969, month: 9, day: 26)) ?? Date()
            ),
            Album(
                id: "3",
                title: "Rumours",
                artist: "Fleetwood Mac",
                artwork: CustomArtwork(url: URL(string: "https://upload.wikimedia.org/wikipedia/en/f/fb/FMacRumours.PNG")!),
                trackCount: 11,
                releaseDate: Calendar.current.date(from: DateComponents(year: 1977, month: 2, day: 4)) ?? Date()
            ),
            Album(
                id: "4",
                title: "Hotel California",
                artist: "Eagles",
                artwork: CustomArtwork(url: URL(string: "https://upload.wikimedia.org/wikipedia/en/4/49/Hotelcalifornia.jpg")!),
                trackCount: 9,
                releaseDate: Calendar.current.date(from: DateComponents(year: 1976, month: 12, day: 8)) ?? Date()
            ),
            Album(
                id: "5",
                title: "Led Zeppelin IV",
                artist: "Led Zeppelin",
                artwork: CustomArtwork(url: URL(string: "https://upload.wikimedia.org/wikipedia/en/2/26/Led_Zeppelin_-_Led_Zeppelin_IV.jpg")!),
                trackCount: 8,
                releaseDate: Calendar.current.date(from: DateComponents(year: 1971, month: 11, day: 8)) ?? Date()
            ),
            Album(
                id: "6",
                title: "Thriller",
                artist: "Michael Jackson",
                artwork: CustomArtwork(url: URL(string: "https://upload.wikimedia.org/wikipedia/en/5/5d/Michael_Jackson_-_Thriller_25_Anniversary_Edition.jpg")!),
                trackCount: 9,
                releaseDate: Calendar.current.date(from: DateComponents(year: 1982, month: 11, day: 30)) ?? Date()
            )
        ]
        
        playlists = [
            Playlist(
                id: "1",
                title: "Classic Rock Essentials",
                curatorName: "Your Music",
                artwork: CustomArtwork(url: URL(string: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300&h=300&fit=crop")!),
                trackCount: 25,
                description: "The greatest rock anthems that defined generations"
            ),
            Playlist(
                id: "2",
                title: "Psychedelic Journey",
                curatorName: "Your Music",
                artwork: CustomArtwork(url: URL(string: "https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=300&h=300&fit=crop")!),
                trackCount: 20,
                description: "Mind-bending tracks from the golden age of psychedelia"
            ),
            Playlist(
                id: "3",
                title: "70s Soul & Funk",
                curatorName: "Your Music",
                artwork: CustomArtwork(url: URL(string: "https://images.unsplash.com/photo-1571330735066-03aaa9429d89?w=300&h=300&fit=crop")!),
                trackCount: 30,
                description: "Smooth grooves and funky beats from the 1970s"
            ),
            Playlist(
                id: "4",
                title: "Acoustic Sessions",
                curatorName: "Your Music",
                artwork: CustomArtwork(url: URL(string: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300&h=300&fit=crop")!),
                trackCount: 18,
                description: "Intimate acoustic performances and stripped-down classics"
            ),
            Playlist(
                id: "5",
                title: "Progressive Rock Masters",
                curatorName: "Your Music",
                artwork: CustomArtwork(url: URL(string: "https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=300&h=300&fit=crop")!),
                trackCount: 22,
                description: "Epic compositions from the masters of progressive rock"
            )
        ]
    }
}

