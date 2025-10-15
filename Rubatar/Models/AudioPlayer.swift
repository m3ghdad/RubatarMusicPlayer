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
    
    @Published var usingMusicKit = false
    private var isLocallyPaused = false
    private var autoAdvanceEnabled = true
    private var isSkipping = false
    private var playbackSessionID = UUID()
    
    // Store the queue of songs for MusicKit
    private var musicKitQueue: [Song] = []
    private var currentQueueIndex = 0
    private var trackUpdateTimer: Timer?
    
    enum PlaybackError: Error {
        case notAuthorized
        case noResults
    }
    
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let mixerNode: AVAudioMixerNode
    private let sampleRate: Double = 44100.0
    private lazy var audioFormat: AVAudioFormat = {
        AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    }()
    
    private var currentTrackIndex = 0
    
    // Sample tracks with their audio data - Updated with Persian music
    private let sampleTracks: [(title: String, artist: String, artwork: URL?, duration: TimeInterval)] = [
        ("Gypsy Wind - Track 1", "Sohrab Pournazeri", URL(string: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop"), 30.0),
        ("Voices of the Shades - Track 1", "Kayhan Kalhor & Madjid Khaladj", URL(string: "https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400&h=400&fit=crop"), 25.0),
        ("Setar Improvisation - Track 1", "Keivan Saket", URL(string: "https://images.unsplash.com/photo-1571330735066-03aaa9429d89?w=400&h=400&fit=crop"), 35.0),
        ("Setar سه تار - Track 1", "Matin Baghani", URL(string: "https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=400&h=400&fit=crop"), 28.0),
        ("Kamkars Santur - Track 1", "Siavash Kamkar", URL(string: "https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=400&h=400&fit=crop"), 32.0),
        ("Kamancheh Instrumental - Track 1", "Mekuvenet", URL(string: "https://images.unsplash.com/photo-1520523839897-bd0b52f945a0?w=400&h=400&fit=crop"), 40.0)
    ]
    
    init() {
        mixerNode = engine.mainMixerNode
        setupAudioSession()
        setupEngine()
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
    
    private func setupEngine() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: mixerNode, format: audioFormat)
        do {
            try engine.start()
            print("✅ AVAudioEngine started")
        } catch {
            print("❌ Failed to start AVAudioEngine: \(error)")
        }
    }
    
    func playSelectedTrack(track: String, artist: String, artwork: URL?) {
        print("🎵 playSelectedTrack called with: \(track) by \(artist)")

        currentTrack = track
        currentArtist = artist
        currentArtwork = artwork

        // Try MusicKit playback first
        Task { @MainActor in
            do {
                try await playWithMusicKit(trackTitle: track, artist: artist)
                usingMusicKit = true
                print("✅ MusicKit playback started")
            } catch {
                print("⚠️ MusicKit playback failed (\(error)). Falling back to tone generator.")
                usingMusicKit = false
                
                // Better matching for Persian music
                if let trackIndex = sampleTracks.firstIndex(where: { 
                    $0.title.lowercased().contains(track.lowercased().prefix(15)) || 
                    $0.artist.lowercased().contains(artist.lowercased().prefix(15))
                }) {
                    currentTrackIndex = trackIndex
                } else {
                    // If no match found, find a random track or cycle through
                    currentTrackIndex = (currentTrackIndex + 1) % sampleTracks.count
                }
                
                // Update current track info to match the sample track
                let selectedTrack = sampleTracks[currentTrackIndex]
                currentTrack = selectedTrack.title
                currentArtist = selectedTrack.artist
                currentArtwork = selectedTrack.artwork
                
                playAudio()
            }
        }
    }
    
    func playSelectedPlaylist(playlistId: String, playlistTitle: String, curatorName: String, artwork: URL?) {
        print("🎶 playSelectedPlaylist called with: \(playlistTitle) by \(curatorName)")

        currentTrack = playlistTitle
        currentArtist = curatorName
        currentArtwork = artwork

        // Try MusicKit playlist playback only - no fallback to tones
        Task { @MainActor in
            do {
                try await playPlaylistWithMusicKit(playlistId: playlistId, playlistTitle: playlistTitle, curatorName: curatorName)
                usingMusicKit = true
                print("✅ MusicKit playlist playback started")
            } catch {
                print("⚠️ MusicKit playlist playback failed (\(error)). No fallback - playlist playback requires MusicKit.")
                usingMusicKit = false
                isPlaying = false
                
                // Reset to default state
                currentTrack = "Playlist playback unavailable"
                currentArtist = "MusicKit required"
                currentArtwork = nil
            }
        }
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
        
        // Start tracking the current song
        startTrackUpdateTimer()
    }
    
    @MainActor
    private func playPlaylistWithMusicKit(playlistId: String, playlistTitle: String, curatorName: String) async throws {
        // Ensure authorization
        if MusicAuthorization.currentStatus != .authorized {
            let status = await MusicAuthorization.request()
            guard status == .authorized else { throw PlaybackError.notAuthorized }
        }

        let player = ApplicationMusicPlayer.shared
        var songsToQueue: [Song] = []
        
        // Map the playlist titles to search for the actual playlists from Apple Music
        let playlistMappings = [
            "Setar سه تار": "Matin Baghani Setar",
            "Kamkars Santur کامکارها / سنتور": "Siavash Kamkar Santur",
            "Kamancheh Instrumental | کمانچه": "Mekuvenet Kamancheh"
        ]
        
        // First, try to find the specific playlist
        var searchTerm = playlistTitle
        if let mappedSearch = playlistMappings[playlistTitle] {
            searchTerm = mappedSearch
        }
        
        print("🔍 Searching for playlist: \(searchTerm)")
        
        // Search for the playlist first
        var playlistRequest = MusicCatalogSearchRequest(term: searchTerm, types: [MusicKit.Playlist.self])
        playlistRequest.limit = 5
        let playlistResponse = try await playlistRequest.response()
        
        if let playlist = playlistResponse.playlists.first {
            print("✅ Found playlist: \(playlist.name) by \(playlist.curatorName ?? "Unknown")")
            
            // Load the playlist's tracks - playlists contain Track objects, not Song objects
            // We need to search for the individual songs instead
            if let playlistTracks = playlist.tracks, !playlistTracks.isEmpty {
                // For now, we'll search for songs by the playlist name since we can't directly cast Track to Song
                var songRequest = MusicCatalogSearchRequest(term: "\(playlist.name) \(playlist.curatorName ?? "")", types: [Song.self])
                songRequest.limit = 20
                let songResponse = try await songRequest.response()
                if !songResponse.songs.isEmpty {
                    songsToQueue = Array(songResponse.songs.prefix(20))
                    print("✅ Loaded \(songsToQueue.count) songs for playlist: \(playlist.name)")
                }
            }
        }
        
        // If no playlist tracks found, fall back to searching for related songs
        if songsToQueue.isEmpty {
            print("⚠️ No playlist tracks found, searching for related songs...")
            
            // Try different search terms for Persian music
            let searchTerms = [
                "Persian \(playlistTitle) instrumental",
                playlistTitle,
                "Persian traditional \(playlistTitle.replacingOccurrences(of: " سه تار", with: "").replacingOccurrences(of: " کامکارها / سنتور", with: "").replacingOccurrences(of: " | کمانچه", with: ""))"
            ]
            
            for term in searchTerms {
                var songRequest = MusicCatalogSearchRequest(term: term, types: [Song.self])
                songRequest.limit = 15
                let songResponse = try await songRequest.response()
                
                if !songResponse.songs.isEmpty {
                    songsToQueue = Array(songResponse.songs.prefix(15))
                    print("✅ Found \(songsToQueue.count) related songs with term: \(term)")
                    break
                }
            }
        }
        
        guard !songsToQueue.isEmpty else { 
            print("❌ No songs found for playlist: \(playlistTitle)")
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
        startTrackUpdateTimer()
    }
    
    private func updateCurrentTrackInfo() {
        guard currentQueueIndex < musicKitQueue.count else { return }
        let song = musicKitQueue[currentQueueIndex]
        currentTrack = song.title
        currentArtist = song.artistName
        currentArtwork = song.artwork?.url(width: 400, height: 400)
    }
    
    private func startTrackUpdateTimer() {
        stopTrackUpdateTimer()
        trackUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAndUpdateCurrentTrack()
            }
        }
    }
    
    private func stopTrackUpdateTimer() {
        trackUpdateTimer?.invalidate()
        trackUpdateTimer = nil
    }
    
    private func checkAndUpdateCurrentTrack() async {
        guard usingMusicKit else { return }
        let player = ApplicationMusicPlayer.shared
        
        // Try to determine which song is currently playing by checking playback position
        // This is a simplified approach - in a real app you might use MusicKit's state observation
        if player.state.playbackStatus == .playing {
            // For now, we'll rely on manual tracking via playNextTrack
            // In a production app, you'd want to use MusicKit's state observation
        }
    }
    
    private func playAudio() {
        autoAdvanceEnabled = true
        isLocallyPaused = false
        playbackSessionID = UUID()
        
        let index = currentTrackIndex
        let baseFrequency: Double = 440.0
        let frequency = baseFrequency + Double(index * 100)
        let duration = sampleTracks[index].duration
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            print("❌ Failed to create AVAudioPCMBuffer")
            return
        }
        buffer.frameLength = frameCount

        if let channelData = buffer.floatChannelData?[0] {
            for frame in 0..<Int(frameCount) {
                let time = Double(frame) / sampleRate
                let sample = Float(0.3 * sin(2.0 * Double.pi * frequency * time))
                channelData[frame] = sample
            }
        }

        if !engine.isRunning {
            do { try engine.start() } catch { print("❌ Engine failed to start: \(error)") }
        }

        playerNode.stop()
        playerNode.reset()

        let sessionID = playbackSessionID
        playerNode.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // Only auto-advance if this completion belongs to the current playback session
                if self.autoAdvanceEnabled && self.playbackSessionID == sessionID {
                    self.playNextTrack()
                }
            }
        }

        if !playerNode.isPlaying {
            playerNode.play()
        }

        isPlaying = true
        print("🎵 Engine playing: index \(index + 1), freq: \(frequency)Hz, duration: \(duration)s")
    }
    
    func togglePlayPause() {
        Task { @MainActor in
            let player = ApplicationMusicPlayer.shared

            // If local tone is currently playing, pause it and mark as locally paused
            if playerNode.isPlaying && !usingMusicKit {
                playerNode.pause()
                isLocallyPaused = true
                isPlaying = false
                return
            }

            // If MusicKit is playing, pause it
            if usingMusicKit && player.state.playbackStatus == .playing {
                player.pause()
                isPlaying = false
                return
            }

            // Resume the same source that was active before pausing
            if usingMusicKit {
                do {
                    try await player.play()
                    isPlaying = true
                    return
                } catch {
                    // Fallback to local tone if MusicKit can't resume
                    usingMusicKit = false
                }
            }

            // Resume local tone exactly where it was paused if possible
            if !usingMusicKit {
                if isLocallyPaused {
                    // Resume previously scheduled buffer from pause
                    autoAdvanceEnabled = true
                    playerNode.play()
                    isLocallyPaused = false
                    isPlaying = true
                } else {
                    // Not paused (either stopped or first play) — start fresh and allow auto-advance
                    playAudio()
                }
            }
        }
    }
    
    func playNextTrack() {
        Task { @MainActor in
            // Prevent re-entrant or duplicate next operations
            if isSkipping { return }
            isSkipping = true
            defer { isSkipping = false }

            if usingMusicKit {
                let player = ApplicationMusicPlayer.shared
                do {
                    try await player.skipToNextEntry()
                    isPlaying = true
                    
                    // Update our queue index and track info
                    currentQueueIndex = (currentQueueIndex + 1) % musicKitQueue.count
                    updateCurrentTrackInfo()
                    return
                } catch {
                    // Fallback to local sequence
                    usingMusicKit = false
                    stopTrackUpdateTimer()

                    // Disable auto-advance before stopping to avoid completion chaining
                    autoAdvanceEnabled = false
                    playbackSessionID = UUID()
                    playerNode.stop()
                    playerNode.reset()

                    currentTrackIndex = (currentTrackIndex + 1) % sampleTracks.count
                    let track = sampleTracks[currentTrackIndex]
                    currentTrack = track.title
                    currentArtist = track.artist
                    currentArtwork = track.artwork

                    playAudio()
                }
            } else {
                // Local tone path
                // Disable auto-advance before stopping to avoid completion chaining
                autoAdvanceEnabled = false
                playbackSessionID = UUID()
                playerNode.stop()
                playerNode.reset()

                currentTrackIndex = (currentTrackIndex + 1) % sampleTracks.count
                let track = sampleTracks[currentTrackIndex]
                currentTrack = track.title
                currentArtist = track.artist
                currentArtwork = track.artwork

                playAudio()
            }
        }
    }
    
    func setVolume(_ volume: Float) {
        mixerNode.outputVolume = volume
        print("🔊 Volume set to: \(volume)")
    }
    
    func seekTo(_ time: TimeInterval) {
        // For MusicKit
        if usingMusicKit {
            Task { @MainActor in
                let player = ApplicationMusicPlayer.shared
                player.playbackTime = time
                print("🎯 Seeked to time: \(time)")
            }
        } else {
            // For local playback, restart with offset
            print("🎯 Local seek to time: \(time) (simplified implementation)")
            // This is a simplified implementation - full seek would require more complex buffer management
        }
    }
    
    func playPreviousTrack() {
        Task { @MainActor in
            // Prevent re-entrant or duplicate previous operations
            if isSkipping { return }
            isSkipping = true
            defer { isSkipping = false }

            if usingMusicKit {
                let player = ApplicationMusicPlayer.shared
                do {
                    try await player.skipToPreviousEntry()
                    isPlaying = true
                    
                    // Update our queue index and track info
                    currentQueueIndex = max(currentQueueIndex - 1, 0)
                    updateCurrentTrackInfo()
                    return
                } catch {
                    // Fallback to local sequence
                    usingMusicKit = false
                    stopTrackUpdateTimer()

                    // Disable auto-advance before stopping to avoid completion chaining
                    autoAdvanceEnabled = false
                    playbackSessionID = UUID()
                    playerNode.stop()
                    playerNode.reset()

                    currentTrackIndex = currentTrackIndex > 0 ? currentTrackIndex - 1 : sampleTracks.count - 1
                    let track = sampleTracks[currentTrackIndex]
                    currentTrack = track.title
                    currentArtist = track.artist
                    currentArtwork = track.artwork

                    playAudio()
                }
            } else {
                // Local tone path
                // Disable auto-advance before stopping to avoid completion chaining
                autoAdvanceEnabled = false
                playbackSessionID = UUID()
                playerNode.stop()
                playerNode.reset()

                currentTrackIndex = currentTrackIndex > 0 ? currentTrackIndex - 1 : sampleTracks.count - 1
                let track = sampleTracks[currentTrackIndex]
                currentTrack = track.title
                currentArtist = track.artist
                currentArtwork = track.artwork

                playAudio()
            }
        }
    }
    
    func stop() {
        autoAdvanceEnabled = false
        isLocallyPaused = false
        playbackSessionID = UUID()
        playerNode.stop()
        isPlaying = false
        stopTrackUpdateTimer()
    }
    
    // MARK: - Volume Control
    var currentVolume: Float {
        return mixerNode.outputVolume
    }
}

