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

class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTrack: String = "No track selected"
    @Published var currentArtist: String = ""
    @Published var currentArtwork: URL? = nil
    
    private var usingMusicKit = false
    private var isLocallyPaused = false
    private var autoAdvanceEnabled = true
    private var isSkipping = false
    private var playbackSessionID = UUID()
    
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
    
    // Sample tracks with their audio data
    private let sampleTracks: [(title: String, artist: String, artwork: URL?, duration: TimeInterval)] = [
        ("The Dark Side of the Moon - Track 1", "Pink Floyd", URL(string: "https://upload.wikimedia.org/wikipedia/en/3/3b/Dark_Side_of_the_Moon.png"), 30.0),
        ("Classic Rock Essentials - First Track", "Your Music", URL(string: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300&h=300&fit=crop"), 25.0),
        ("Abbey Road - Track 1", "The Beatles", URL(string: "https://upload.wikimedia.org/wikipedia/en/4/42/Beatles_-_Abbey_Road.jpg"), 35.0),
        ("Thriller - Track 1", "Michael Jackson", URL(string: "https://upload.wikimedia.org/wikipedia/en/5/55/Michael_Jackson_-_Thriller.png"), 40.0),
        ("Hotel California - Track 1", "Eagles", URL(string: "https://upload.wikimedia.org/wikipedia/en/4/49/Hotelcalifornia.jpg"), 28.0)
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
                if let trackIndex = sampleTracks.firstIndex(where: { $0.title.contains(track.prefix(20)) }) {
                    currentTrackIndex = trackIndex
                } else {
                    currentTrackIndex = 0
                }
                playAudio()
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

        // Search Apple Music catalog for the song
        var request = MusicCatalogSearchRequest(term: "\(trackTitle) \(artist)", types: [Song.self])
        request.limit = 1
        let response = try await request.response()
        guard let song = response.songs.first else { throw PlaybackError.noResults }

        let player = ApplicationMusicPlayer.shared
        player.queue = .init(for: [song])
        try await player.play()
        usingMusicKit = true
        isPlaying = true
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
                    return
                } catch {
                    // Fallback to local sequence
                    usingMusicKit = false

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
    
    func stop() {
        autoAdvanceEnabled = false
        isLocallyPaused = false
        playbackSessionID = UUID()
        playerNode.stop()
        isPlaying = false
    }
}

