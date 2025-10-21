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
    @EnvironmentObject var contentManager: ContentManager
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
                // Show loading state for ContentManager
                switch contentManager.loadingState {
                case .loading:
                    ContentSkeletonView()
                    
                case .loaded(_), .offline(_):
                    // Dynamic sections based on database configuration
                    ForEach(contentManager.sections.sorted(by: { $0.displayOrder < $1.displayOrder })) { section in
                        DynamicSectionView(
                            section: section,
                            contentManager: contentManager,
                            onMusicSelected: onMusicSelected,
                            onPlaylistSelected: onPlaylistSelected
                        )
                    }
                
                case .error(let errorMessage):
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 30))
                            .foregroundColor(.orange)
                        Text("Content Error")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
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

// MARK: - Dynamic Section View
struct DynamicSectionView: View {
    let section: ContentSection
    let contentManager: ContentManager
    let onMusicSelected: (String, String, URL) -> Void
    let onPlaylistSelected: (String, String, String, URL?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.custom("Palatino", size: section.type == "albums" ? 17 : 16))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
            
            if section.layoutType == "horizontal" {
                // Horizontal layout (ScrollView) - for albums or playlists
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        if section.type == "albums" {
                            // Albums in horizontal layout
                            ForEach(getAlbumsForSection()) { featuredAlbum in
                                AppleMusicAlbumCardView(
                                    albumId: featuredAlbum.appleAlbumId ?? "",
                                    customTitle: featuredAlbum.customTitle ?? "Featured Album",
                                    customArtist: featuredAlbum.customArtist ?? "Featured Artist",
                                    onTap: {
                                        if let url = URL(string: featuredAlbum.appleAlbumUrl) {
                                            onMusicSelected(
                                                featuredAlbum.customTitle ?? "Featured Album",
                                                featuredAlbum.customArtist ?? "Featured Artist",
                                                url
                                            )
                                            print("🎶 Tapped backend album: \(featuredAlbum.customTitle ?? "Unknown")")
                                        }
                                    }
                                )
                            }
                        } else {
                            // Playlists in horizontal layout - compact style like albums
                            ForEach(getPlaylistsForSection()) { featuredPlaylist in
                                CompactPlaylistCardView(
                                    title: featuredPlaylist.customTitle ?? "Featured Playlist",
                                    curator: featuredPlaylist.customCurator ?? "Featured Curator",
                                    coverImageUrl: featuredPlaylist.coverImageUrl,
                                    onTap: {
                                        onPlaylistSelected(
                                            featuredPlaylist.applePlaylistId,
                                            featuredPlaylist.customTitle ?? "Featured Playlist",
                                            featuredPlaylist.customCurator ?? "Featured Curator",
                                            nil
                                        )
                                        print("🎶 Tapped backend playlist: \(featuredPlaylist.customTitle ?? "Unknown") with ID: \(featuredPlaylist.applePlaylistId)")
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else {
                // Vertical layout (VStack) - for playlists
                VStack(spacing: 12) {
                    ForEach(getPlaylistsForSection()) { featuredPlaylist in
                        let mockPlaylist = Playlist(
                            id: featuredPlaylist.id.uuidString,
                            title: featuredPlaylist.customTitle ?? "Featured Playlist",
                            curatorName: featuredPlaylist.customCurator ?? "Featured Curator",
                            artwork: nil,
                            trackCount: 0,
                            description: featuredPlaylist.customDescription ?? "Featured playlist description"
                        )
                        
                        PlaylistCardView(
                            playlist: mockPlaylist,
                            onTap: {
                                onPlaylistSelected(
                                    featuredPlaylist.applePlaylistId,
                                    featuredPlaylist.customTitle ?? "Featured Playlist",
                                    featuredPlaylist.customCurator ?? "Featured Curator",
                                    nil
                                )
                                print("🎶 Tapped backend playlist: \(featuredPlaylist.customTitle ?? "Unknown") with ID: \(featuredPlaylist.applePlaylistId)")
                            },
                            customImageName: featuredPlaylist.coverImageUrl,
                            customInstrumentImageName: featuredPlaylist.instrumentImageUrl ?? "SetaarInstrument",
                            customTitle: featuredPlaylist.customTitle,
                            customCuratorName: featuredPlaylist.customCurator,
                            customDescription: featuredPlaylist.customDescription
                        )
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }
    
    private func getAlbumsForSection() -> [FeaturedAlbum] {
        return contentManager.albums.filter { $0.sectionId == section.id }
    }
    
    private func getPlaylistsForSection() -> [FeaturedPlaylist] {
        return contentManager.playlists.filter { $0.sectionId == section.id }
    }
}

// MARK: - Compact Playlist Card View
struct CompactPlaylistCardView: View {
    let title: String
    let curator: String
    let coverImageUrl: String?
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image - same size as album cards
            Group {
                if let coverImageUrl = coverImageUrl, !coverImageUrl.isEmpty {
                    AsyncImage(url: URL(string: coverImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.gray.opacity(0.3), .gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    }
                } else {
                    // Fallback to local instrument image
                    Image("Setaar")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 160, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .onTapGesture {
                onTap()
            }
            
            // Playlist info - same style as album cards
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Palatino", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .truncationMode(.tail)
                    .frame(maxWidth: 160, alignment: .leading)
                
                Text(curator)
                    .font(.custom("Palatino", size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 160, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Content Skeleton Loading View
struct ContentSkeletonView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            // Skeleton for 3 sections
            ForEach(0..<3, id: \.self) { sectionIndex in
                VStack(alignment: .leading, spacing: 12) {
                    // Section title skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(skeletonColor)
                        .frame(width: 120, height: 20)
                        .padding(.horizontal, 16)
                    
                    if sectionIndex == 0 {
                        // Vertical layout skeleton (playlists)
                        VStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { _ in
                                PlaylistCardSkeleton()
                            }
                        }
                    } else {
                        // Horizontal layout skeleton (albums)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(0..<4, id: \.self) { _ in
                                    AlbumCardSkeleton()
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 20)
    }
    
    private var skeletonColor: Color {
        colorScheme == .dark ? 
            Color(red: 0.2, green: 0.2, blue: 0.2) : 
            Color(red: 0.9, green: 0.9, blue: 0.9)
    }
}

// MARK: - Playlist Card Skeleton
struct PlaylistCardSkeleton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Cover skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(skeletonColor)
                .frame(height: 200)
                .padding(.horizontal, 16)
            
            // Footer skeleton
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(skeletonColor)
                    .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(skeletonColor)
                        .frame(width: 120, height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(skeletonColor)
                        .frame(width: 80, height: 14)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(skeletonColor)
                        .frame(width: 100, height: 12)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private var skeletonColor: Color {
        colorScheme == .dark ? 
            Color(red: 0.2, green: 0.2, blue: 0.2) : 
            Color(red: 0.9, green: 0.9, blue: 0.9)
    }
}

// MARK: - Album Card Skeleton
struct AlbumCardSkeleton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Album artwork skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(skeletonColor)
                .frame(width: 160, height: 160)
            
            // Album info skeleton
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonColor)
                    .frame(width: 120, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonColor)
                    .frame(width: 100, height: 14)
            }
        }
    }
    
    private var skeletonColor: Color {
        colorScheme == .dark ? 
            Color(red: 0.2, green: 0.2, blue: 0.2) : 
            Color(red: 0.9, green: 0.9, blue: 0.9)
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
