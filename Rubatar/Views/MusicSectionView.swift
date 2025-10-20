//
//  MusicSectionView.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import SwiftUI
import MusicKit

struct MusicSectionView: View {
    @StateObject private var musicManager = MusicManager()
    @State private var showingAlbumAlert = false
    @State private var showingPlaylistAlert = false
    @State private var selectedAlbum: Album?
    @State private var selectedPlaylist: Playlist?
    
    // Callback for when music is selected
    let onMusicSelected: (String, String, URL?) -> Void
    let onPlaylistSelected: (String, String, String, URL?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header
            HStack {
                Text("Top picks")
                    .font(.custom("Palatino", size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if musicManager.authorizationStatus != .authorized {
                    Button("Connect Music") {
                        Task {
                            await musicManager.requestAuthorization()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 16)
            
            if musicManager.authorizationStatus == .authorized {
                // Playlists Section
                if !musicManager.playlists.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Playlists by instrument")
                            .font(.custom("Palatino", size: 16))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 12) {
                            let imageNames = ["Setaar", "Santoor", "Kamancheh"]
                            let instrumentImageNames = ["SetaarInstrument", "SantoorInstrument", "KamanchehInstrument"]
                            let playlistIds = ["pl.u-vEe5t44Rjbm", "pl.u-AqK9HDDXK5a", "pl.u-bvj8T00GXMg"] // Apple Music playlist IDs
                            
                            // Custom content for each playlist
                            let customTitles = [
                                "The Dance of Silence | رقص سکوت",
                                "Melody of Water | نغمه آب",
                                "The Shadow of Time | سایه زمان"
                            ]
                            let customCuratorNames = [
                                "Se Tār | سه تار",
                                "Santoor | سنتور",
                                "Kamancheh | کمانچه"
                            ]
                            let customDescriptions = [
                                "A meditative journey where the سه‌تار (Se Tār) weaves joy and silence into one graceful breath.",
                                "A tranquil reflection where the سنتور (Santoor) speaks in ripples of light, echoing thought and memory into still air.",
                                "A reflective journey where the کمانچه (Kamancheh) sings of seasons, distance, and the gentle passing of time."
                            ]
                            
                            ForEach(0..<musicManager.playlists.count, id: \.self) { index in
                                let playlist = musicManager.playlists[index]
                                let imageName = index < imageNames.count ? imageNames[index] : "Setaar"
                                let instrumentImageName = index < instrumentImageNames.count ? instrumentImageNames[index] : "SetaarInstrument"
                                let customPlaylistId = index < playlistIds.count ? playlistIds[index] : nil
                                let customTitle = index < customTitles.count ? customTitles[index] : nil
                                let customCuratorName = index < customCuratorNames.count ? customCuratorNames[index] : nil
                                let customDescription = index < customDescriptions.count ? customDescriptions[index] : nil
                                
                                PlaylistCardView(
                                    playlist: playlist,
                                    onTap: {
                                        // Handle playlist tap with custom ID if available
                                        if let customId = customPlaylistId {
                                            // Use the custom Apple Music playlist ID
                                            onPlaylistSelected(customId, playlist.title, playlist.curatorName, playlist.artworkURL)
                                            print("🎶 Tapped custom playlist: \(playlist.title) with ID: \(customId)")
                                        } else {
                                            // Use the default playlist handling
                                            handlePlaylistTap(playlist)
                                        }
                                    },
                                    customImageName: imageName,
                                    customInstrumentImageName: instrumentImageName,
                                    customTitle: customTitle,
                                    customCuratorName: customCuratorName,
                                    customDescription: customDescription
                                )
                                .padding(.horizontal, 16)
                                
                            }
                        }
                    }
                }
                
                // Albums Section
                if !musicManager.albums.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Featured Albums")
                            .font(.custom("Palatino", size: 17))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(musicManager.albums) { album in
                                    AlbumCardView(album: album) {
                                        // Handle album tap
                                        handleAlbumTap(album)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                
                if musicManager.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading music...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }
                
            } else if musicManager.authorizationStatus == .denied {
                // Permission denied state
                VStack(spacing: 12) {
                    Image(systemName: "music.note.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("Music Access Required")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("To display your music library, please grant access to Apple Music in Settings.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.separator, lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, 16)
                
            } else {
                // Not determined state
                VStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Connect Your Music")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Access your Apple Music library to see your albums and playlists right here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Button("Connect Apple Music") {
                        Task {
                            await musicManager.requestAuthorization()
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue)
                    )
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.separator, lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, 16)
            }
            
            // Demo button for testing
            if musicManager.authorizationStatus == .authorized && musicManager.albums.isEmpty {
                Button("Load Sample Music") {
                    musicManager.loadSampleMusic()
                }
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue.opacity(0.1))
                )
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            if musicManager.authorizationStatus == .authorized {
                Task {
                    await musicManager.loadMusicLibrary()
                }
            } else {
                // Load sample music for demo purposes
                musicManager.loadSampleMusic()
            }
        }
        .alert("Album Selected", isPresented: $showingAlbumAlert) {
            Button("OK") { }
        } message: {
            if let album = selectedAlbum {
                Text("You selected \(album.title) by \(album.artist)\nReleased: \(album.formattedReleaseDate)\nTracks: \(album.trackCount)")
            }
        }
        .alert("Playlist Selected", isPresented: $showingPlaylistAlert) {
            Button("OK") { }
        } message: {
            if let playlist = selectedPlaylist {
                Text("You selected \(playlist.title)\nCurated by: \(playlist.curatorName)\n\(playlist.trackCount) tracks\n\n\(playlist.description)")
            }
        }
    }
    
    // MARK: - Tap Handlers
    private func handleAlbumTap(_ album: Album) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Play the album using its ID - format: "albumId:albumTitle"
        let albumIdentifier = "\(album.id):\(album.title)"
        onMusicSelected(albumIdentifier, album.artist, album.artworkURL)
        
        // Show album alert
        selectedAlbum = album
        showingAlbumAlert = true
        
        // Also print to console
        print("🎵 Tapped album: \(album.title) by \(album.artist) (ID: \(album.id))")
        print("   📅 Released: \(album.formattedReleaseDate)")
        print("   🎶 Tracks: \(album.trackCount)")
    }
    
    private func handlePlaylistTap(_ playlist: Playlist) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Play the playlist using the actual playlist ID and info
        onPlaylistSelected(playlist.id, playlist.title, playlist.curatorName, playlist.artworkURL)
        
        // Show playlist alert
        selectedPlaylist = playlist
        showingPlaylistAlert = true
        
        // Also print to console
        print("🎶 Tapped playlist: \(playlist.title)")
        print("   👤 Curated by: \(playlist.curatorName)")
        print("   📝 \(playlist.description)")
        print("   🎵 \(playlist.trackCount) tracks")
    }
}

#Preview {
    MusicSectionView(
        onMusicSelected: { track, artist, artwork in
            print("Selected: \(track) by \(artist)")
        },
        onPlaylistSelected: { playlistId, playlistTitle, curatorName, artwork in
            print("Selected playlist: \(playlistTitle) by \(curatorName)")
        }
    )
    .padding()
}
