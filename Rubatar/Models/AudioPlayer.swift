//
//  AudioPlayer.swift
//  Rubatar
//
//  Created by AI Assistant on 10/15/25.
//

import Foundation
import AVFoundation
import Combine
import MusicKit

@MainActor
class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTrack: String = "No track selected"
    @Published var currentArtist: String = ""
    @Published var currentArtwork: URL? = nil
    @Published var hasPlayedTrack = false // Track if user has ever played something
    
    @Published var usingMusicKit = false
    
    private var autoAdvanceEnabled = true
    private var isSkipping = false
    
    private var playbackSessionID = UUID()
    
    // Store the queue of songs for MusicKit
    private var musicKitQueue: [Song] = []
    private var currentQueueIndex = 0
    
    // Persisted playback state
    private var lastPlaybackTime: TimeInterval = 0
    private var lastUsingMusicKit: Bool = false
    private var lastQueueSongIDs: [String] = []
    private var lastCurrentSongID: String? = nil
    
    enum PlaybackError: Error {
        case notAuthorized
        case noResults
    }
    
    init() {
        setupAudioSession()
        loadLastPlayedTrack()
        loadPlaybackState()
        
        // Load persisted playback state and restore if possible
        Task { @MainActor in
            await checkMusicKitPlaybackState()
        }
    }
    
    private func checkMusicKitPlaybackState() async {
        let player = ApplicationMusicPlayer.shared
        
        // Check if MusicKit has an active queue
        if player.queue.entries.count > 0 {
            print("✅ MusicKit has active queue, restoring playback state")
            usingMusicKit = true
            
            // Get current entry info
            if let currentEntry = player.queue.currentEntry {
                if let song = currentEntry.item as? Song {
                    currentTrack = song.title
                    currentArtist = song.artistName
                    currentArtwork = song.artwork?.url(width: 400, height: 400)
                    hasPlayedTrack = true
                    saveLastPlayedTrack()
                }
            }
            
            // Update isPlaying based on player state
            isPlaying = player.state.playbackStatus == .playing
            lastPlaybackTime = player.playbackTime
            savePlaybackState()
            
            if !isPlaying {
                print("ℹ️ Player was paused. Ready to resume.")
            }
        } else {
            print("ℹ️ No active MusicKit queue")
            usingMusicKit = false
            isPlaying = false
            savePlaybackState()
        }
    }
    
    private func loadLastPlayedTrack() {
        if let savedTrack = UserDefaults.standard.string(forKey: "lastPlayedTrack"),
           let savedArtist = UserDefaults.standard.string(forKey: "lastPlayedArtist") {
            currentTrack = savedTrack
            currentArtist = savedArtist
            hasPlayedTrack = true
            
            if let artworkURLString = UserDefaults.standard.string(forKey: "lastPlayedArtwork") {
                currentArtwork = URL(string: artworkURLString)
            }
            print("✅ Loaded last played track: \(savedTrack) by \(savedArtist)")
        }
    }
    
    private func saveLastPlayedTrack() {
        UserDefaults.standard.set(currentTrack, forKey: "lastPlayedTrack")
        UserDefaults.standard.set(currentArtist, forKey: "lastPlayedArtist")
        if let artworkURL = currentArtwork {
            UserDefaults.standard.set(artworkURL.absoluteString, forKey: "lastPlayedArtwork")
        }
        hasPlayedTrack = true
    }
    
    private func savePlaybackState() {
        let player = ApplicationMusicPlayer.shared
        // Persist whether we were using MusicKit
        UserDefaults.standard.set(usingMusicKit, forKey: "ap_lastUsingMusicKit")

        // Persist playback time from MusicKit
        let time = player.playbackTime
        UserDefaults.standard.set(time, forKey: "ap_lastPlaybackTime")
        lastPlaybackTime = time

        // Persist queue IDs and current song ID if available
        let ids = musicKitQueue.map { $0.id.rawValue }
        UserDefaults.standard.set(ids, forKey: "ap_lastQueueSongIDs")
        lastQueueSongIDs = ids

        if currentQueueIndex < musicKitQueue.count {
            let currentId = musicKitQueue[currentQueueIndex].id.rawValue
            UserDefaults.standard.set(currentId, forKey: "ap_lastCurrentSongID")
            lastCurrentSongID = currentId
        }

        print("💾 Saved playback state: usingMusicKit=\(usingMusicKit), time=\(time), currentId=\(lastCurrentSongID ?? "nil")")
    }

    private func loadPlaybackState() {
        lastUsingMusicKit = UserDefaults.standard.bool(forKey: "ap_lastUsingMusicKit")
        lastPlaybackTime = UserDefaults.standard.double(forKey: "ap_lastPlaybackTime")
        lastQueueSongIDs = UserDefaults.standard.stringArray(forKey: "ap_lastQueueSongIDs") ?? []
        lastCurrentSongID = UserDefaults.standard.string(forKey: "ap_lastCurrentSongID")

        print("📥 Loaded playback state: lastUsingMusicKit=\(lastUsingMusicKit), time=\(lastPlaybackTime), currentId=\(lastCurrentSongID ?? "nil"), queueCount=\(lastQueueSongIDs.count)")

        guard lastUsingMusicKit, !lastQueueSongIDs.isEmpty else { return }

        Task { @MainActor in
            await rebuildQueueFromSavedIDs()
        }
    }

    private func idsToSongs(_ ids: [String]) async -> [Song] {
        var songs: [Song] = []
        for id in ids {
            do {
                let req = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(id))
                let resp = try await req.response()
                if let song = resp.items.first { songs.append(song) }
            } catch {
                print("⚠️ Failed to fetch song id=\(id): \(error)")
            }
        }
        return songs
    }

    @MainActor
    private func rebuildQueueFromSavedIDs() async {
        let player = ApplicationMusicPlayer.shared

        // Fetch songs for saved IDs
        let songs = await idsToSongs(lastQueueSongIDs)
        guard !songs.isEmpty else {
            print("❌ No songs resolved from saved IDs; cannot rebuild queue")
            usingMusicKit = false
            return
        }

        // Resolve current index using saved current song ID
        var startIndex = 0
        if let savedId = lastCurrentSongID, let idx = songs.firstIndex(where: { $0.id.rawValue == savedId }) {
            startIndex = idx
        } else {
            print("⚠️ Saved current song ID not found in rebuilt queue; defaulting to index 0")
        }

        // Assign queue starting at the saved current song
        musicKitQueue = songs
        currentQueueIndex = startIndex
        player.queue = .init(for: songs, startingAt: songs[startIndex])

        // Update current track metadata
        updateCurrentTrackInfo()

        // Seek to saved time and remain paused
        player.playbackTime = lastPlaybackTime
        isPlaying = false
        usingMusicKit = true

        print("✅ Rebuilt queue at index=\(startIndex), time=\(lastPlaybackTime), paused")
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session setup successful")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    func playSelectedTrack(track: String, artist: String, artwork: URL?) {
        print("🎵 playSelectedTrack called with: \(track) by \(artist)")

        currentTrack = track
        currentArtist = artist
        currentArtwork = artwork
        saveLastPlayedTrack() // Save immediately when track is selected

        // Try MusicKit playback first
        Task { @MainActor in
            do {
                // Check if the track string contains an album ID (format: "albumId:albumTitle")
                if track.contains(":"), let albumId = track.split(separator: ":").first {
                    try await playAlbumByID(albumID: String(albumId), albumTitle: artist)
                } else {
                    try await playWithMusicKit(trackTitle: track, artist: artist)
                }
                usingMusicKit = true
                isPlaying = true
                savePlaybackState()
                print("✅ MusicKit playback started")
            } catch {
                print("⚠️ MusicKit playback failed (\(error)). No fallback available.")
                usingMusicKit = false
                isPlaying = false
                savePlaybackState()
            }
        }
    }
    
    @MainActor
    private func playAlbumByID(albumID: String, albumTitle: String) async throws {
        print("🎵 Playing album by ID: \(albumID)")
        
        // Ensure authorization
        if MusicAuthorization.currentStatus != .authorized {
            let status = await MusicAuthorization.request()
            guard status == .authorized else { throw PlaybackError.notAuthorized }
        }
        
        let player = ApplicationMusicPlayer.shared
        
        // Fetch the album by ID
        let albumRequest = MusicCatalogResourceRequest<MusicKit.Album>(matching: \.id, equalTo: MusicItemID(albumID))
        let albumResponse = try await albumRequest.response()
        
        guard let album = albumResponse.items.first else {
            print("❌ Album not found with ID: \(albumID)")
            throw PlaybackError.noResults
        }
        
        print("✅ Found album: \(album.title) by \(album.artistName)")
        
        // Fetch the album's tracks
        let detailedAlbum = try await album.with([.tracks])
        guard let tracks = detailedAlbum.tracks, !tracks.isEmpty else {
            print("❌ No tracks found in album")
            throw PlaybackError.noResults
        }
        
        // Convert tracks to songs for playback
        var songsToQueue: [Song] = []
        for track in tracks {
            // Search for each track as a song
            var songRequest = MusicCatalogSearchRequest(term: "\(track.title) \(album.artistName)", types: [Song.self])
            songRequest.limit = 1
            let songResponse = try await songRequest.response()
            if let song = songResponse.songs.first {
                songsToQueue.append(song)
            }
        }
        
        guard !songsToQueue.isEmpty else {
            print("❌ No songs found for album tracks")
            throw PlaybackError.noResults
        }
        
        // Store the queue and reset index
        musicKitQueue = songsToQueue
        currentQueueIndex = 0
        
        // Update current track info with the first song
        updateCurrentTrackInfo()
        
        // Start playing the first song
        player.queue = .init(for: songsToQueue, startingAt: songsToQueue[0])
        try await player.play()
        usingMusicKit = true
        isPlaying = true
        
        savePlaybackState()
    }
    
    func playSelectedPlaylist(playlistId: String, playlistTitle: String, curatorName: String, artwork: URL?) {
        print("🎶 playSelectedPlaylist called with: \(playlistTitle) by \(curatorName), ID: \(playlistId)")

        currentTrack = playlistTitle
        currentArtist = curatorName
        currentArtwork = artwork
        saveLastPlayedTrack() // Save immediately when playlist is selected

        // Try MusicKit playlist playback by ID
        Task { @MainActor in
            do {
                try await playPlaylistByID(playlistID: playlistId, playlistTitle: playlistTitle, curatorName: curatorName)
                usingMusicKit = true
                isPlaying = true
                savePlaybackState()
                print("✅ MusicKit playlist playback started")
            } catch {
                print("⚠️ MusicKit playlist playback failed (\(error)). No fallback - playlist playback requires MusicKit.")
                usingMusicKit = false
                isPlaying = false
                
                // Reset to default state
                currentTrack = "Playlist playback unavailable"
                currentArtist = "MusicKit required"
                currentArtwork = nil
                savePlaybackState()
            }
        }
    }
    
    @MainActor
    private func playPlaylistByID(playlistID: String, playlistTitle: String, curatorName: String) async throws {
        print("🎵 Playing playlist by ID: \(playlistID)")
        
        // Ensure authorization
        if MusicAuthorization.currentStatus != .authorized {
            let status = await MusicAuthorization.request()
            guard status == .authorized else { throw PlaybackError.notAuthorized }
        }
        
        let player = ApplicationMusicPlayer.shared
        
        // Fetch the playlist by ID
        let playlistRequest = MusicCatalogResourceRequest<MusicKit.Playlist>(matching: \.id, equalTo: MusicItemID(playlistID))
        let playlistResponse = try await playlistRequest.response()
        
        guard let playlist = playlistResponse.items.first else {
            print("❌ Playlist not found with ID: \(playlistID)")
            throw PlaybackError.noResults
        }
        
        print("✅ Found playlist: \(playlist.name)")
        
        // Fetch the playlist's tracks
        let detailedPlaylist = try await playlist.with([.tracks])
        guard let tracks = detailedPlaylist.tracks, !tracks.isEmpty else {
            print("❌ No tracks found in playlist")
            throw PlaybackError.noResults
        }
        
        // Convert tracks to songs for playback
        var songsToQueue: [Song] = []
        for track in tracks {
            // Search for each track as a song
            var songRequest = MusicCatalogSearchRequest(term: "\(track.title) \(track.artistName)", types: [Song.self])
            songRequest.limit = 1
            let songResponse = try await songRequest.response()
            if let song = songResponse.songs.first {
                songsToQueue.append(song)
            }
        }
        
        guard !songsToQueue.isEmpty else {
            print("❌ No songs found for playlist tracks")
            throw PlaybackError.noResults
        }
        
        // Store the queue and reset index
        musicKitQueue = songsToQueue
        currentQueueIndex = 0
        
        // Update current track info with the first song
        updateCurrentTrackInfo()
        
        // Start playing the first song
        player.queue = .init(for: songsToQueue, startingAt: songsToQueue[0])
        try await player.play()
        
        usingMusicKit = true
        isPlaying = true
        savePlaybackState()
    }
    
    @MainActor
    private func playWithMusicKit(trackTitle: String, artist: String) async throws {
        // NOTE: Requires MusicKit capability, active Apple Music subscription, and a valid developer token configured for catalog playback.
        // Ensure authorization
        if MusicAuthorization.currentStatus != .authorized {
            let status = await MusicAuthorization.request()
            guard status == .authorized else { throw PlaybackError.notAuthorized }
        }

        let player = ApplicationMusicPlayer.shared
        var songsToQueue: [Song] = []
        
        // Map the album titles to search for the actual albums from Apple Music
        let albumMappings = [
            "Gypsy Wind": "Sohrab Pournazeri Gypsy Wind",
            "Voices of the Shades": "Kayhan Kalhor Madjid Khaladj Voices of the Shades",
            "Setar Improvisation": "Keivan Saket Setar Improvisation"
        ]
        
        // First, try to find the specific album
        var searchTerm = trackTitle
        if let mappedSearch = albumMappings[trackTitle] {
            searchTerm = mappedSearch
        }
        
        print("🔍 Searching for album: \(searchTerm)")
        
        // Search for the album first
        var albumRequest = MusicCatalogSearchRequest(term: searchTerm, types: [MusicKit.Album.self])
        albumRequest.limit = 5
        let albumResponse = try await albumRequest.response()
        
        if let album = albumResponse.albums.first {
            print("✅ Found album: \(album.title) by \(album.artistName)")
            
            // Load the album's tracks - albums contain Track objects, not Song objects
            // We need to search for the individual songs instead
            if let albumTracks = album.tracks, !albumTracks.isEmpty {
                // For now, we'll search for songs by the album title since we can't directly cast Track to Song
                var songRequest = MusicCatalogSearchRequest(term: "\(album.title) \(album.artistName)", types: [Song.self])
                songRequest.limit = 15
                let songResponse = try await songRequest.response()
                if !songResponse.songs.isEmpty {
                    songsToQueue = Array(songResponse.songs.prefix(15))
                    print("✅ Loaded \(songsToQueue.count) songs for album: \(album.title)")
                }
            }
        }
        
        // If no album tracks found, fall back to searching for individual songs
        if songsToQueue.isEmpty {
            print("⚠️ No album tracks found, searching for individual songs...")
            var songRequest = MusicCatalogSearchRequest(term: "\(trackTitle) \(artist)", types: [Song.self])
            songRequest.limit = 10
            let songResponse = try await songRequest.response()
            
            if !songResponse.songs.isEmpty {
                songsToQueue = Array(songResponse.songs.prefix(10))
                print("✅ Found \(songsToQueue.count) individual songs")
            }
        }
        
        guard !songsToQueue.isEmpty else {
            print("❌ No songs found for: \(trackTitle) by \(artist)")
            throw PlaybackError.noResults
        }
        
        // Store the queue and reset index
        musicKitQueue = songsToQueue
        currentQueueIndex = 0
        
        // Update current track info with the first song
        updateCurrentTrackInfo()
        
        // Start playing the first song
        player.queue = .init(for: songsToQueue, startingAt: songsToQueue[0])
        try await player.play()
        usingMusicKit = true
        isPlaying = true
        
        savePlaybackState()
    }
    
    private func updateCurrentTrackInfo() {
        guard currentQueueIndex < musicKitQueue.count else { return }
        let song = musicKitQueue[currentQueueIndex]
        currentTrack = song.title
        currentArtist = song.artistName
        currentArtwork = song.artwork?.url(width: 400, height: 400)
        saveLastPlayedTrack() // Save when track updates
        savePlaybackState()
    }
    
    func togglePlayPause() {
        Task { @MainActor in
            let player = ApplicationMusicPlayer.shared
            
            if player.queue.entries.count > 0 {
                if player.state.playbackStatus == .playing {
                    player.pause()
                    isPlaying = false
                    savePlaybackState()
                    return
                } else {
                    do {
                        try await player.play()
                        isPlaying = true
                        usingMusicKit = true
                        savePlaybackState()
                        return
                    } catch {
                        print("⚠️ MusicKit play failed: \(error)")
                        isPlaying = false
                        usingMusicKit = false
                        savePlaybackState()
                        return
                    }
                }
            }
            
            // If no active queue, attempt to rebuild queue from saved IDs and play
            if !lastQueueSongIDs.isEmpty {
                do {
                    await rebuildQueueFromSavedIDs()
                    try await player.play()
                    isPlaying = true
                    usingMusicKit = true
                    savePlaybackState()
                } catch {
                    print("⚠️ Failed to rebuild queue and play: \(error)")
                    isPlaying = false
                    usingMusicKit = false
                    savePlaybackState()
                }
            } else {
                print("ℹ️ No queue to play or resume.")
                isPlaying = false
                usingMusicKit = false
                savePlaybackState()
            }
        }
    }
    
    func playNextTrack() {
        Task { @MainActor in
            if isSkipping { return }
            isSkipping = true
            defer { isSkipping = false }
            
            guard usingMusicKit else {
                print("❌ No MusicKit playback active; cannot play next track.")
                isPlaying = false
                savePlaybackState()
                return
            }
            
            let player = ApplicationMusicPlayer.shared
            do {
                try await player.skipToNextEntry()
                isPlaying = true
                
                // Update our queue index and track info
                currentQueueIndex = (currentQueueIndex + 1) % musicKitQueue.count
                updateCurrentTrackInfo()
                savePlaybackState()
            } catch {
                print("❌ Failed to skip to next entry: \(error)")
                isPlaying = false
                savePlaybackState()
            }
        }
    }
    
    func playPreviousTrack() {
        Task { @MainActor in
            if isSkipping { return }
            isSkipping = true
            defer { isSkipping = false }
            
            guard usingMusicKit else {
                print("❌ No MusicKit playback active; cannot play previous track.")
                isPlaying = false
                savePlaybackState()
                return
            }
            
            let player = ApplicationMusicPlayer.shared
            do {
                try await player.skipToPreviousEntry()
                isPlaying = true
                
                // Update our queue index and track info
                currentQueueIndex = max(currentQueueIndex - 1, 0)
                updateCurrentTrackInfo()
                savePlaybackState()
            } catch {
                print("❌ Failed to skip to previous entry: \(error)")
                isPlaying = false
                savePlaybackState()
            }
        }
    }
    
    func setVolume(_ volume: Float) {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP])
        } catch {
            print("❌ Failed to set audio session active for volume: \(error)")
        }
        // No internal mixer here; volume control should be handled externally or via system volume
        print("🔊 Volume control not implemented internally for MusicKit playback. Requested volume: \(volume)")
    }
    
    func seekTo(_ time: TimeInterval) {
        Task { @MainActor in
            if usingMusicKit {
                let player = ApplicationMusicPlayer.shared
                player.playbackTime = time
                lastPlaybackTime = time
                print("🎯 Seeked to time: \(time)")
                savePlaybackState()
            } else {
                print("🎯 Seek called but no MusicKit playback active.")
            }
        }
    }
    
    func stop() {
        Task { @MainActor in
            let player = ApplicationMusicPlayer.shared
            do {
                try await player.stop()
            } catch {
                print("❌ Failed to stop player: \(error)")
            }
            isPlaying = false
            usingMusicKit = false
            savePlaybackState()
        }
    }
}
