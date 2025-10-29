//
//  AlbumCardView.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import SwiftUI
import MusicKit

struct AlbumCardView: View {
    let album: Album
    let onTap: () -> Void
    var customImageName: String? = nil // Add support for local images
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Album artwork - support both URLs and local images
            if let imageName = customImageName, !imageName.hasPrefix("http") {
                // Use local asset image
                Image(imageName)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .onTapGesture {
                        onTap()
                    }
            } else if let imageURL = customImageName, imageURL.hasPrefix("http"), let url = URL(string: imageURL) {
                // Use URL-based image
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
                .frame(width: 160, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .onTapGesture {
                    onTap()
                }
            } else {
                // Fallback to album artwork URL
                CachedAsyncImage(url: album.artworkURL) { image in
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.7))
                        )
                }
                .frame(width: 160, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .onTapGesture {
                    onTap()
                }
            }
            
            // Album info
            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.custom("Palatino", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .truncationMode(.tail)
                    .frame(maxWidth: 160, alignment: .leading)
                
                Text(album.artist)
                    .font(.custom("Palatino", size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 160, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onTapGesture {
            onTap()
        }
    }
}

struct AlbumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PlaylistCardView: View {
    let playlist: Playlist
    let onTap: () -> Void
    let customImageName: String
    let customInstrumentImageName: String
    let customTitle: String?
    let customCuratorName: String?
    let customDescription: String?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover - Playlist artwork
            /*
            CachedAsyncImage(url: playlist.artworkURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.3), .blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "music.note.list")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: 400)
            .clipShape(
                .rect(
                    topLeadingRadius: 8,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 8
                )
            )
            */
            
            // Cover - Custom image for playlists
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let glarePosition = (sin(time * 0.3) + 1) / 2 // 0 to 1
                
                ZStack(alignment: .top) {
                    // Background gradient layer (bottom)
                    if colorScheme == .dark {
                        LinearGradient(
                            colors: [
                                Color(hex: "5D5858"),
                                Color(hex: "171312")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(0.9)
                    } else {
                        LinearGradient(
                            colors: [
                                Color(hex: "DDDDDD"),
                                Color(hex: "777777")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(0.1)
                    }
                    
                    // Paper texture layer (middle)
                    Image("paperTextureFolded")
                        .resizable()
                        .frame(maxWidth: .infinity, maxHeight: 400)
                        .clipped()
                        .opacity(colorScheme == .dark ? 0.2 : 0.5)
                    
                    // Main image layer (top) - Handle both URLs and local images
                    if customImageName.hasPrefix("http") {
                        CachedAsyncImage(url: URL(string: customImageName)) { image in
                            image
                                .resizable()
                                .frame(maxWidth: .infinity, maxHeight: 400)
                                .clipped()
                                .opacity(0.6)
                        } placeholder: {
                            Image("Setaar")
                                .resizable()
                                .frame(maxWidth: .infinity, maxHeight: 400)
                                .clipped()
                                .opacity(0.6)
                        }
                    } else {
                        Image(customImageName)
                            .resizable()
                            .frame(maxWidth: .infinity, maxHeight: 400)
                            .clipped()
                            .opacity(0.6)
                    }
                    
                    // Glare effect 1
                    let creamyWhite = Color(red: 0.98, green: 0.96, blue: 0.92)
                    let cyanTint = Color(red: 0.75, green: 0.92, blue: 0.95)
                    let darkCreamyWhite = Color(red: 0.85, green: 0.83, blue: 0.80)
                    let darkCyanTint = Color(red: 0.6, green: 0.75, blue: 0.8)
                    
                    RadialGradient(
                        colors: colorScheme == .dark ? [
                            darkCyanTint.opacity(0.3),
                            darkCreamyWhite.opacity(0.4),
                            darkCreamyWhite.opacity(0.2),
                            .clear
                        ] : [
                            cyanTint.opacity(0.4),
                            creamyWhite.opacity(0.5),
                            creamyWhite.opacity(0.3),
                            .clear
                        ],
                        center: UnitPoint(x: 0.3 + glarePosition * 0.4, y: 0.4 + sin(time * 0.15) * 0.2),
                        startRadius: 20,
                        endRadius: 150
                    )
                    .blur(radius: 30)
                    .blendMode(.overlay)
                    
                    // Glare effect 2 - More vibrant, parallel movement
                    let vibrantCreamyWhite = Color(red: 1.0, green: 0.98, blue: 0.95)
                    let vibrantCyanTint = Color(red: 0.8, green: 0.95, blue: 1.0)
                    let darkVibrantCreamyWhite = Color(red: 0.9, green: 0.87, blue: 0.85)
                    let darkVibrantCyanTint = Color(red: 0.7, green: 0.85, blue: 0.9)
                    
                    RadialGradient(
                        colors: colorScheme == .dark ? [
                            darkVibrantCyanTint.opacity(0.5),
                            darkVibrantCreamyWhite.opacity(0.6),
                            darkVibrantCreamyWhite.opacity(0.3),
                            .clear
                        ] : [
                            vibrantCyanTint.opacity(0.6),
                            vibrantCreamyWhite.opacity(0.7),
                            vibrantCreamyWhite.opacity(0.4),
                            .clear
                        ],
                        center: UnitPoint(x: 0.7 + glarePosition * 0.3, y: 0.6 + sin(time * 0.15) * 0.2),
                        startRadius: 15,
                        endRadius: 120
                    )
                    .blur(radius: 25)
                    .blendMode(.overlay)
                }
                .frame(maxWidth: .infinity, maxHeight: 400)
                .clipped()
                .clipShape(
                    .rect(
                        topLeadingRadius: 8,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 8
                    )
                )
            }
            
            // PlaylistFooter
            VStack(alignment: .leading, spacing: 4) {
                Text(customTitle ?? playlist.title)
                    .font(.custom("Palatino", size: 17))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(customCuratorName ?? playlist.curatorName)
                    .font(.custom("Palatino", size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(customDescription ?? playlist.description)
                    .font(.custom("Palatino", size: 12))
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Track count (commented out)
            /*
            Text("\(playlist.trackCount)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.quaternary)
                )
            */
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.separator, lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
}

struct PlaylistButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 20) {
        AlbumCardView(
            album: Album(
                id: "1",
                title: "Midnights",
                artist: "Taylor Swift",
                artwork: nil,
                trackCount: 13,
                releaseDate: Date()
            ),
            onTap: {}
        )
        
        PlaylistCardView(
            playlist: Playlist(
                id: "1",
                title: "Today's Hits",
                curatorName: "Apple Music",
                artwork: nil,
                trackCount: 50,
                description: "The biggest songs of the moment"
            ),
            onTap: {},
            customImageName: "Setaar",
            customInstrumentImageName: "SetaarInstrument",
            customTitle: nil,
            customCuratorName: nil,
            customDescription: nil
        )
    }
    .padding()
}

// MARK: - Apple Music Album Card View
struct AppleMusicAlbumCardView: View {
    let albumId: String
    let customTitle: String
    let customArtist: String
    let onTap: () -> Void
    
    @State private var album: MusicKit.Album?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Album artwork from Apple Music
            Group {
                if let album = album, let artwork = album.artwork {
                    CachedAsyncImage(url: artwork.url(width: 300, height: 300)) { image in
                        image
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    }
                } else if isLoading {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                } else {
                    // Fallback for error state
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.red.opacity(0.3), .orange.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.7))
                        )
                }
            }
            .frame(width: 160, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .onTapGesture {
                onTap()
            }
            
            // Album info
            VStack(alignment: .leading, spacing: 4) {
                Text(customTitle)
                    .font(.custom("Palatino", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .truncationMode(.tail)
                    .frame(maxWidth: 160, alignment: .leading)
                
                Text(customArtist)
                    .font(.custom("Palatino", size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 160, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onTapGesture {
            onTap()
        }
        .task {
            await fetchAlbum()
        }
    }
    
    @MainActor
    private func fetchAlbum() async {
        do {
            print("🎵 Fetching Apple Music album with ID: \(albumId)")
            
            // Request the album by ID
            let request = MusicCatalogResourceRequest<MusicKit.Album>(
                matching: \.id,
                equalTo: MusicItemID(albumId)
            )
            
            let response = try await request.response()
            
            if let fetchedAlbum = response.items.first {
                self.album = fetchedAlbum
                print("✅ Successfully fetched album: \(fetchedAlbum.title)")
            } else {
                print("⚠️ No album found with ID: \(albumId)")
                self.error = NSError(domain: "AlbumNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Album not found"])
            }
        } catch {
            print("❌ Failed to fetch album: \(error)")
            self.error = error
        }
        
        self.isLoading = false
    }
}
